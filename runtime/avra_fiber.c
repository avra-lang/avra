// ── Fibers: tasks on one OS thread ──────────────────────────────
//
// A task runs on a FIBER: its own stack, switched in and out only
// where it waits (a join, a park, a sleep, a yield). Cooperative and
// single-threaded, so the runtime's plain reference counts stay
// sound. `main` is a fiber too — the OS stack, never replaced.
//
// NOTHING HERE RUNS UNTIL IT IS ASKED FOR: no stack, no poller, no
// signal handler exists before the first spawn, park or sleep, and a
// program that never calls one does not link this object at all.
//
// A task WAITS ON A SET: a descriptor's direction, a time, a gate —
// any number at once — and is woken by exactly one of them.

#include <errno.h>
#include <stdbool.h>
#include <fcntl.h>
#include <signal.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "avra_box.h"
#include "avra_door.h"
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#endif
#include "avra_fiber.h"
#include "avra_runtime.h"

#if defined(__APPLE__) || defined(__FreeBSD__)
#include <sys/event.h>
#define AVRA_KQUEUE 1
#elif defined(__linux__)
#include <sys/epoll.h>
#define AVRA_EPOLL 1
#else
#error "the scheduler has no poller for this platform"
#endif

// ── The switch ──────────────────────────────────────────────────
//
// `avra_fiber_switch(&from->sp, to->sp)` saves the callee-saved
// registers on the running stack, records its top in `*from`, loads
// `to`'s and restores its registers. A new fiber's stack is laid out
// as if it had switched away at the first instruction of
// `fiber_start` (see `fiber_bound`).
//
// EVERY SWITCH-OUT IS WHERE AN OVERFLOW IS CAUGHT (the guard policy,
// below): `from` is the fiber's record, and its next two words are the
// floor its saved stack top must stand on and the address of a word
// that must still read zero. Either broken, the fiber never switches.

void avra_fiber_switch(void** from, void* to);

#if defined(__APPLE__)
#define AVRA_SYM(name) "_" #name
#else
#define AVRA_SYM(name) #name
#endif

// FIBER_FRAME is the bytes a switched-out stack holds, and FIBER_RETURN
// the word among them the switch returns through.
#if defined(__aarch64__)
// x19–x28, the frame pair x29/x30, and d8–d15: 160 bytes, in a
// 176-byte frame so sp stays 16-aligned. x30 is the return.
#define FIBER_FRAME 176
#define FIBER_RETURN 11
__asm__(
    ".text\n"
    ".p2align 2\n"
    ".globl " AVRA_SYM(avra_fiber_switch) "\n"
    AVRA_SYM(avra_fiber_switch) ":\n"
    "    sub sp, sp, #176\n"
    "    stp x19, x20, [sp, #0]\n"
    "    stp x21, x22, [sp, #16]\n"
    "    stp x23, x24, [sp, #32]\n"
    "    stp x25, x26, [sp, #48]\n"
    "    stp x27, x28, [sp, #64]\n"
    "    stp x29, x30, [sp, #80]\n"
    "    stp d8, d9, [sp, #96]\n"
    "    stp d10, d11, [sp, #112]\n"
    "    stp d12, d13, [sp, #128]\n"
    "    stp d14, d15, [sp, #144]\n"
    "    mov x9, sp\n"
    "    ldr x10, [x0, #8]\n"
    "    cmp x9, x10\n"
    "    b.lo 1f\n"
    "    ldr x10, [x0, #16]\n"
    "    ldr x10, [x10]\n"
    "    cbnz x10, 1f\n"
    "    str x9, [x0]\n"
    "    mov sp, x1\n"
    "    ldp x19, x20, [sp, #0]\n"
    "    ldp x21, x22, [sp, #16]\n"
    "    ldp x23, x24, [sp, #32]\n"
    "    ldp x25, x26, [sp, #48]\n"
    "    ldp x27, x28, [sp, #64]\n"
    "    ldp x29, x30, [sp, #80]\n"
    "    ldp d8, d9, [sp, #96]\n"
    "    ldp d10, d11, [sp, #112]\n"
    "    ldp d12, d13, [sp, #128]\n"
    "    ldp d14, d15, [sp, #144]\n"
    "    add sp, sp, #176\n"
    "    ret\n"
    "1:  bl " AVRA_SYM(avra_fiber_overflowed) "\n");
#elif defined(__x86_64__)
// r15–r12, rbx and rbp popped, then the return address; one word more
// stands above it, so `fiber_start` begins with rsp ≡ 8 (mod 16) as a
// call would leave it.
#define FIBER_FRAME 64
#define FIBER_RETURN 6
__asm__(
    ".text\n"
    ".p2align 4\n"
    ".globl " AVRA_SYM(avra_fiber_switch) "\n"
    AVRA_SYM(avra_fiber_switch) ":\n"
    "    pushq %rbp\n"
    "    pushq %rbx\n"
    "    pushq %r12\n"
    "    pushq %r13\n"
    "    pushq %r14\n"
    "    pushq %r15\n"
    "    cmpq 8(%rdi), %rsp\n"
    "    jb 1f\n"
    "    movq 16(%rdi), %rax\n"
    "    cmpq $0, (%rax)\n"
    "    jne 1f\n"
    "    movq %rsp, (%rdi)\n"
    "    movq %rsi, %rsp\n"
    "    popq %r15\n"
    "    popq %r14\n"
    "    popq %r13\n"
    "    popq %r12\n"
    "    popq %rbx\n"
    "    popq %rbp\n"
    "    ret\n"
    "1:  subq $8, %rsp\n"
    "    call " AVRA_SYM(avra_fiber_overflowed) "\n");
#else
#error "the scheduler has no context switch for this architecture"
#endif

// ── Fibers, waiters and tasks ───────────────────────────────────

enum { FIBER_RUNNING, FIBER_READY, FIBER_PARKED, FIBER_DONE };

typedef struct Fiber Fiber;

// A WAITER is one thing a parked task waits on, filed with its source:
// a descriptor's direction, the timer heap, or a gate. `arm` and
// `member` are what the task is told when this one wakes it.
enum { W_FD_READ, W_FD_WRITE, W_AT, W_GATE, W_DEADLINE };
typedef struct Waiter Waiter;
struct Waiter {
    Waiter* next;
    Waiter* prev;
    Fiber* fiber;
    int32_t arm, member;
    uint32_t kind;
    uint32_t filed;
    union { int fd; size_t timer; void* gate; } on;   // timer: 1 + its index in the heap
};

// A waiter past the ones a fiber holds inline.
typedef struct Over Over;
struct Over { Waiter w; Over* next; };

// A `within`'s scope on its task: its id and its limit, in ns.
typedef struct { int64_t id, at; } Scope;
enum { SCOPES = 4 };

enum { HELD = 4 };

// A fiber's record is the task's place in the scheduler, apart from
// its stack: a task that has not yet run holds no stack at all. `main`
// is static and runs on the OS stack.
//
// THE WAIT SET IS THE FIBER'S: a task is parked in one place, so the
// set its waiters belong to is its own — `claimed`, `arm`, `member`.
// TO WAKE IS TO CLAIM: the first source to claim the set writes its arm
// and readies the task; every later one finds it claimed and moves on.
struct Fiber {
    void* sp;               // the saved stack top while switched out; NULL until first run
    uintptr_t floor;        // a saved stack top below this has left the stack; 0 for main
    const uint64_t* canary; // the word under the floor; non-zero when a neighbour was written
    AvraTaskLocal* local;   // the slots and id a program reads: main's are the core's
    union {
        void* task;         // the task this fiber answers; NULL for main
        const char* site;   // a virtual task's: where its body was written, or NULL
    };
    Fiber* next;            // the run queue
    void* joining;          // the task this fiber waits to join, else NULL
    int state;
    int virtual;            // the evaluator's: filed here, switched by the evaluator
    uint8_t claimed;        // the set has been claimed
    uint8_t parked;         // switched out on an unclaimed set
    uint8_t legacy;         // parked by a sleep, a join or a descriptor park: cleared at its claim
    uint8_t deaf;           // a scope's end joining what it owns: no cancel cuts the join
    uint8_t heeds;          // the task's deadline may claim this set
    uint8_t timed_out;      // whether the last legacy park ended by time
    uint8_t unwinding;      // the unwind bit while switched out (`avra_unwinding` while running)
    uint8_t wide;           // a case's own task: it runs on the wide stack
    int32_t arm, member;    // the claim
    uint32_t held_n;
    int64_t cancel_by;      // 1 + the id of the task that asked, else 0
    int64_t scope_by;       // the scope whose limit passed and whose request stands, else 0
    int64_t deadline;       // the owner's limit, in ns; 0 when no scope may still ask
    int64_t due_at;         // the deadline `due` is filed under
    uint32_t scopes_n;      // the scopes open, outermost first
    uint32_t armed;         // the scopes below this depth may still ask
    uint32_t owner;         // the armed scope whose limit is `deadline`
    uint32_t deeper_cap;
    Scope scope[SCOPES];
    Scope* deeper;          // the scopes past the inline ones
    Waiter held[HELD];
    Waiter due;             // the deadline's own waiter
    Over* more;
    Fiber* all_next;        // every live fiber, for a fork and for a dump
    Fiber* all_prev;
    char* base;             // the stack's lowest byte; NULL for main, a virtual task, or one not yet run
    char* guard;            // the page whose fault is this stack's overflow
    AvraTaskLocal own;
};

// A GATE IS A RECORD, and a task record begins as one: a queue of
// waiters and whether it stands open. An open gate claims whoever
// waits on it at once — a task's gate opens when the task ends. The
// core reclaims the record like any other, releasing the body and the
// answer it owns; the list and the fiber are C pointers in unowned
// cells.
enum { GATE_HEAD, GATE_TAIL, GATE_OPEN, GATE_CELLS };
enum { TASK_FIBER = GATE_CELLS, TASK_BODY, TASK_ANSWER, TASK_AT, TASK_END, TASK_CELLS };
enum { END_LIVE, END_ANSWERED, END_CANCELLED };

static int64_t* task_cells(void* task) { return ((AvraArray*)task)->data; }

// The switch reads these three by their place.
_Static_assert(offsetof(Fiber, sp) == 0 && offsetof(Fiber, floor) == 8 && offsetof(Fiber, canary) == 16, "the switch reads a fiber's first three words");

static const uint64_t g_untouched = 0;
static Fiber g_main = { .state = FIBER_RUNNING, .canary = &g_untouched, .local = &avra_main_local };
static Fiber* g_current = &g_main;
static Fiber* g_ready_head = NULL;
static Fiber* g_ready_tail = NULL;
static Fiber* g_all = NULL;
static uint64_t g_fiber_seq = 0;
// A finished fiber cannot give back the stack it stands on; the next
// fiber to run does.
static Fiber* g_finished = NULL;

static void ready_push(Fiber* f) {
    f->state = FIBER_READY;
    f->next = NULL;
    if (g_ready_tail) g_ready_tail->next = f; else g_ready_head = f;
    g_ready_tail = f;
}

static Fiber* ready_pop(void) {
    Fiber* f = g_ready_head;
    if (!f) return NULL;
    g_ready_head = f->next;
    if (!g_ready_head) g_ready_tail = NULL;
    f->next = NULL;
    return f;
}

// Records are pooled: a spawn takes one and a finished task gives it
// back, so a task costs no allocation once the pool is warm.
static Fiber* g_fiber_pool = NULL;

static Fiber* fiber_new(void* task, int virtual) {
    Fiber* f = g_fiber_pool;
    if (f) g_fiber_pool = f->next;
    else if (!(f = malloc(sizeof(Fiber)))) avra_trap("the scheduler ran out of memory for a task");
    memset(f, 0, sizeof(Fiber));
    f->task = task;
    f->virtual = virtual;
    f->canary = &g_untouched;
    f->local = &f->own;
    f->own.id = (int64_t)++g_fiber_seq;
    f->all_next = g_all;
    if (g_all) g_all->all_prev = f;
    g_all = f;
    return f;
}

static void fiber_unlisted(Fiber* f) {
    if (f->all_prev) f->all_prev->all_next = f->all_next; else g_all = f->all_next;
    if (f->all_next) f->all_next->all_prev = f->all_prev;
    f->all_next = f->all_prev = NULL;
}

static void fiber_freed(Fiber* f) {
    fiber_unlisted(f);
    free(f->deeper);
    f->next = g_fiber_pool;
    g_fiber_pool = f;
}

static int64_t id_of(const Fiber* f) { return f->local->id; }

uint8_t avra_unwinding = 0;

// ── The trace ───────────────────────────────────────────────────
//
// `AVRA_FLOW_TRACE=1` writes one line per event to stderr, any other
// value names a file: spawn, park with its sources, claim with who
// claimed, retract, a deadline set and fired, cancel, end. Off, it
// costs a test of one flag at each site and nothing on a switch.

static int g_flow_trace = 0;
static int g_trace_fd = 2;
static int64_t g_trace_left = 0;

static int64_t now_ns(void);

static void clock_turned(void);

__attribute__((constructor))
static void trace_settle(void) {
    avra_clock_turned_hook = clock_turned;
    const char* env = getenv("AVRA_FLOW_TRACE");
    if (!env || !*env) return;
    if (strcmp(env, "1") != 0) {
        g_trace_fd = open(env, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
        if (g_trace_fd < 0) g_trace_fd = 2;
    }
    const char* cap = getenv("AVRA_FLOW_TRACE_CAP");
    g_trace_left = cap ? (int64_t)avra_number(cap, 0) : (int64_t)256 << 20;
    g_flow_trace = 1;
}

#define TRACING __builtin_expect(g_flow_trace, 0)

// A LOG HAS A CEILING: past it one line says so and the trace is over.
__attribute__((noinline, cold))
static void traced(const char* line) {
    char out[512];
    avra_fmt(out, sizeof out, "ts=%lld %s\n", (long long)now_ns(), line);
    size_t n = strlen(out);
    if ((g_trace_left -= (int64_t)n) < 0) {
        static const char over[] = "flow trace: capped\n";
        ssize_t w = write(g_trace_fd, over, sizeof over - 1);
        (void)w;
        g_flow_trace = 0;
        return;
    }
    ssize_t w = write(g_trace_fd, out, n);
    (void)w;
}

// Who claimed: a task by its id, or one of the scheduler's own hands.
enum { BY_TIMER = -1, BY_POLLER = -2, BY_DEADLINE = -3, BY_CLOSE = -4 };

__attribute__((noinline, cold))
static void traced_claim(const Fiber* f, int64_t by) {
    char line[160];
    static const char* const hands[] = { "", "timer", "poller", "deadline", "closing" };
    if (by >= 0) avra_fmt(line, sizeof line, "claim id=%lld by=%lld arm=%d:%d", (long long)id_of(f), (long long)by, f->arm, f->member);
    else avra_fmt(line, sizeof line, "claim id=%lld by=%s arm=%d:%d", (long long)id_of(f), hands[-by], f->arm, f->member);
    traced(line);
}

__attribute__((noinline, cold))
static void traced_waiter(const Fiber* f, const Waiter* w) {
    char line[160];
    switch (w->kind) {
        case W_FD_READ: avra_fmt(line, sizeof line, "park id=%lld src=fd:r:%d arm=%d:%d", (long long)id_of(f), w->on.fd, w->arm, w->member); break;
        case W_FD_WRITE: avra_fmt(line, sizeof line, "park id=%lld src=fd:w:%d arm=%d:%d", (long long)id_of(f), w->on.fd, w->arm, w->member); break;
        case W_GATE: avra_fmt(line, sizeof line, "park id=%lld src=gate:%p arm=%d:%d", (long long)id_of(f), w->on.gate, w->arm, w->member); break;
        default: avra_fmt(line, sizeof line, "park id=%lld src=at arm=%d:%d", (long long)id_of(f), w->arm, w->member); break;
    }
    traced(line);
}

__attribute__((noinline, cold))
static void traced_fiber(const char* what, const Fiber* f, long long n) {
    char line[160];
    avra_fmt(line, sizeof line, "%s id=%lld %lld", what, (long long)id_of(f), n);
    traced(line);
}

// A join, about to wait: who the joiner waits for. A task nothing runs
// has no id, and is named as that.
__attribute__((noinline, cold))
static void traced_join(const Fiber* f, int64_t on) {
    char line[160];
    if (on < 0) avra_fmt(line, sizeof line, "join id=%lld on=unrun", (long long)id_of(f));
    else avra_fmt(line, sizeof line, "join id=%lld on=%lld", (long long)id_of(f), (long long)on);
    traced(line);
}

// A joiner readied by the end of the task it waited for.
__attribute__((noinline, cold))
static void traced_joined(const Fiber* f, int64_t by) {
    char line[160];
    if (by < 0) avra_fmt(line, sizeof line, "claim id=%lld by=unrun arm=0:0", (long long)id_of(f));
    else avra_fmt(line, sizeof line, "claim id=%lld by=%lld arm=0:0", (long long)id_of(f), (long long)by);
    traced(line);
}

// The program's site table (avra_box.h): its rows and their count.
#if defined(__APPLE__)
static const AvraSiteRow* site_rows(size_t* n) {
    unsigned long bytes = 0;
    const struct mach_header_64* image = (const struct mach_header_64*)_dyld_get_image_header(0);
    const uint8_t* at = getsectiondata(image, AVRA_SITES_MACHO_SEGMENT, AVRA_SITES_MACHO_SECTION, &bytes);
    *n = at ? bytes / sizeof(AvraSiteRow) : 0;
    return (const AvraSiteRow*)at;
}
#else
extern const AvraSiteRow __start_avra_sites[] __attribute__((weak));
extern const AvraSiteRow __stop_avra_sites[] __attribute__((weak));
static const AvraSiteRow* site_rows(size_t* n) {
    *n = __start_avra_sites ? (size_t)(__stop_avra_sites - __start_avra_sites) : 0;
    return __start_avra_sites;
}
#endif

// Where a task's body was written — the row that names its entry — or
// NULL for code no row names.
static const char* site_of(void* body) {
    const void* code = (const void*)(uintptr_t)((AvraArray*)body)->data[0];
    size_t n = 0;
    const AvraSiteRow* rows = site_rows(&n);
    for (size_t i = 0; i < n; i++) {
        if (rows[i].code == code) return rows[i].site;
    }
    return NULL;
}

// A spawn, and where its body was written.
static void traced_site(const Fiber* f, const char* site, const void* code);
__attribute__((noinline, cold))
static void traced_spawn(const Fiber* f, void* body) {
    traced_fiber("spawn", f, (long long)id_of(g_current));
    traced_site(f, site_of(body), (const void*)(uintptr_t)((AvraArray*)body)->data[0]);
}

// A task's site, said once: its source line, or — for code that
// carries none — its address.
__attribute__((noinline, cold))
static void traced_site(const Fiber* f, const char* site, const void* code) {
    char line[400];
    if (site) avra_fmt(line, sizeof line, "site id=%lld %s", (long long)id_of(f), site);
    else avra_fmt(line, sizeof line, "site id=%lld %p", (long long)id_of(f), code);
    traced(line);
}

// ── Time ────────────────────────────────────────────────────────

// The process's one clock, read as the scheduler's own.
static inline int64_t now_ns(void) { return avra_clock_read(); }

// `ms` from now, saturating: a wait too long to spell in nanoseconds
// is a wait for ever, never one already due.
static int64_t deadline_after(int64_t ms) {
    int64_t now = now_ns();
    if (ms > (INT64_MAX - now) / 1000000) return INT64_MAX;
    return now + ms * 1000000;
}

// A min-heap of times. An entry is a waiter's or a fiberless task's,
// and each knows its place, so whoever leaves early takes its entry
// out and no timer is ever stale. Ties break by insertion order: two
// sleeps of one length wake in the order they were asked.
enum { T_WAITER, T_TASK };
typedef struct { int64_t at; uint64_t seq; uint32_t kind; void* who; } Timer;
static Timer* g_timers = NULL;
static size_t g_timers_len = 0;
static size_t g_timers_cap = 0;
static uint64_t g_timer_seq = 0;

static void timer_placed(size_t i) {
    Timer* t = &g_timers[i];
    if (t->kind == T_WAITER) ((Waiter*)t->who)->on.timer = i + 1;
    else task_cells(t->who)[TASK_AT] = (int64_t)(i + 1);
}

static int timer_before(size_t a, size_t b) {
    const Timer* x = &g_timers[a];
    const Timer* y = &g_timers[b];
    return x->at < y->at || (x->at == y->at && x->seq < y->seq);
}

static void timer_swap(size_t a, size_t b) {
    Timer t = g_timers[a];
    g_timers[a] = g_timers[b];
    g_timers[b] = t;
    timer_placed(a);
    timer_placed(b);
}

static size_t timer_up(size_t i) {
    while (i > 0 && timer_before(i, (i - 1) / 2)) {
        timer_swap(i, (i - 1) / 2);
        i = (i - 1) / 2;
    }
    return i;
}

static void timer_down(size_t i) {
    for (;;) {
        size_t l = 2 * i + 1, r = l + 1, least = i;
        if (l < g_timers_len && timer_before(l, least)) least = l;
        if (r < g_timers_len && timer_before(r, least)) least = r;
        if (least == i) return;
        timer_swap(i, least);
        i = least;
    }
}

// THE WORLD, AND WHEN IT IS ASKED.
//
// TIMERS: A DUE TIMER FIRES AT THE FIRST SWITCH AFTER IT IS DUE. While
// the heap holds anything, every switch reads the clock against its
// earliest time; while it is empty, no switch reads a clock.
//
// DESCRIPTORS: THE POLLER IS ASKED EVERY FAIR_TURNS SWITCHES while a
// waiter is filed on one and tasks are ready — a crowd of yielding
// tasks cannot starve a reader — and at once when nobody is ready.
// `g_until_poll` counts the switches left; with no waiter filed it is
// out of reach.
#define FAIR_TURNS 64
#define POLL_IDLE ((int64_t)1 << 62)
static int64_t g_until_poll = POLL_IDLE;

// THE LISTING'S DOOR (at the end of this file): asks a signal has
// counted and the world has not answered; whether the scheduler stands
// in the world's path; whether the door is open; whether this process
// evaluates.
static volatile sig_atomic_t g_asked;
static volatile sig_atomic_t g_in_world;
static int g_door_open = 0;
static volatile sig_atomic_t g_evaluated;

// SEEDED, THE QUEUE ALONE NEVER DECIDES: `g_until_poll` is held at zero,
// so every switch fails the fast path's own test and reaches the pick —
// and an unseeded switch carries nothing for it. The poller's turn is
// then counted here, by the same law. A VIRTUAL CLOCK PINS THE SWITCH
// the same way: the slow half is where a task that parks is seen to.
static int g_seeded = 0;
static int64_t g_schedule = 0;
static uint64_t g_seed_state = 0;
static int64_t g_choices = 0;
static int64_t g_pick_links = 0;
static int64_t g_world_visits = 0;
static int64_t g_pinned_until_poll = 0;

static int64_t g_polls = 0;

static void timer_set(uint32_t kind, void* who, int64_t at) {
    if (g_timers_len == g_timers_cap) {
        g_timers_cap = g_timers_cap ? g_timers_cap * 2 : 64;
        g_timers = realloc(g_timers, g_timers_cap * sizeof(Timer));
        if (!g_timers) avra_trap("the scheduler ran out of memory for timers");
    }
    size_t i = g_timers_len++;
    g_timers[i] = (Timer){ at, g_timer_seq++, kind, who };
    timer_placed(i);
    timer_up(i);
}

// The entry at `i` leaves the heap; its owner's place is its to clear.
static void timer_out(size_t i) {
    size_t last = --g_timers_len;
    if (i == last) return;
    g_timers[i] = g_timers[last];
    timer_placed(i);
    timer_down(timer_up(i));
}

// ── The poller ──────────────────────────────────────────────────
//
// WAITERS ARE FILED BY DESCRIPTOR AND DIRECTION, never by fiber: two
// tasks may wait to read one socket, and a reader and a writer always
// share one. Readiness claims every waiter in its direction, since an
// edge comes once; each task retries, and one that finds nothing waits
// again at no cost.

// A descriptor's waiters, the directions registered with the poller,
// and the directions that MAY be ready: set by an edge, cleared when a
// read finds the socket drained or a task parks after finding nothing.
typedef struct { Waiter* head[2]; Waiter* tail[2]; int armed; int ready; } FdWaits;

static int g_poller = -1;
static void fd_drained(int64_t fd);
static int64_t g_parked_fds = 0;
static FdWaits* g_fds = NULL;
static size_t g_fds_cap = 0;

static int pinned(void) { return g_seeded || avra_clock.virtual; }

// The poller has been asked, or its count begins: when it is next due.
static void poll_counted(void) {
    if (pinned()) {
        g_until_poll = 0;
        g_pinned_until_poll = FAIR_TURNS;
        return;
    }
    g_until_poll = g_parked_fds > 0 ? FAIR_TURNS : POLL_IDLE;
}

static void poller_open(void) {
    if (g_poller >= 0) return;
#if AVRA_KQUEUE
    g_poller = kqueue();
#else
    g_poller = epoll_create1(EPOLL_CLOEXEC);
#endif
    if (g_poller < 0) avra_trap("the scheduler could not open its poller");
    avra_fd_drained_hook = fd_drained;
}

static FdWaits* fd_waits(int fd) {
    if ((size_t)fd >= g_fds_cap) {
        size_t cap = g_fds_cap ? g_fds_cap : 64;
        while (cap <= (size_t)fd) cap *= 2;
        g_fds = realloc(g_fds, cap * sizeof(FdWaits));
        if (!g_fds) avra_trap("the scheduler ran out of memory for its descriptor table");
        memset(g_fds + g_fds_cap, 0, (cap - g_fds_cap) * sizeof(FdWaits));
        g_fds_cap = cap;
    }
    return &g_fds[fd];
}

enum { ARMED_READ = 1, ARMED_WRITE = 2 };

// A peer's end is STICKY readiness: a short read drains the bytes, not
// the close behind them, so a socket whose peer has finished stays
// ready to read until its read says so.
enum { READ_CLOSED = 4 };

// THE WATCH IS REGISTERED ONCE, EDGE-TRIGGERED: a direction is added
// the first time a task waits on it and stays until the descriptor
// closes, so a park costs no syscall. An edge nobody waits for is
// dropped — a task parks only after its read or write found nothing,
// so the next edge is still to come. 0 when the descriptor cannot be
// watched — closed, or not a descriptor at all.
//
// It holds while EVERY CLOSE of a descriptor a task may park on goes
// through `avra_fiber_fd_closing`, which forgets the registration: the
// kernel drops the watch at the close, and a number reused after a
// close nobody reported would be taken for registered and never woken.
static int fd_arm(int fd) {
    FdWaits* w = fd_waits(fd);
    int want = (w->head[0] ? ARMED_READ : 0) | (w->head[1] ? ARMED_WRITE : 0);
    int missing = want & ~w->armed;
    if (!missing) return 1;
#if AVRA_KQUEUE
    struct kevent evs[2];
    int n = 0;
    if (missing & ARMED_READ) { EV_SET(&evs[n], fd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, NULL); n++; }
    if (missing & ARMED_WRITE) { EV_SET(&evs[n], fd, EVFILT_WRITE, EV_ADD | EV_CLEAR, 0, 0, NULL); n++; }
    // the clock: not a wait on time — a change list, no event asked for
    int ok = kevent(g_poller, evs, n, NULL, 0, NULL) == 0;
    if (ok) { w->armed |= missing; w->ready |= missing; }
#else
    struct epoll_event ev = { .events = EPOLLIN | EPOLLOUT | EPOLLRDHUP | EPOLLET, .data.fd = fd };
    int ok = w->armed != 0 || epoll_ctl(g_poller, EPOLL_CTL_ADD, fd, &ev) == 0;
    if (ok && !w->armed) { w->armed = ARMED_READ | ARMED_WRITE; w->ready = ARMED_READ | ARMED_WRITE; }
#endif
    return ok;
}

// ── Filing, claiming, retracting ────────────────────────────────

// The two ends of the list a waiter is filed in.
static void list_of(Waiter* w, Waiter*** head, Waiter*** tail) {
    if (w->kind == W_GATE) {
        int64_t* cells = task_cells(w->on.gate);
        *head = (Waiter**)&cells[GATE_HEAD];
        *tail = (Waiter**)&cells[GATE_TAIL];
    } else {
        FdWaits* f = fd_waits(w->on.fd);
        int d = w->kind == W_FD_WRITE;
        *head = &f->head[d];
        *tail = &f->tail[d];
    }
}

static void waiter_filed(Waiter* w) {
    Waiter** head;
    Waiter** tail;
    list_of(w, &head, &tail);
    w->next = NULL;
    w->prev = *tail;
    if (*tail) (*tail)->next = w; else *head = w;
    *tail = w;
    w->filed = 1;
    if (w->kind != W_GATE) {
        g_parked_fds++;
        if (g_until_poll > FAIR_TURNS) g_until_poll = FAIR_TURNS;
    }
}

// A waiter leaves whatever holds it: its list, the heap, the count the
// fast path reads — and its gate is let go, kept only while filed.
static void waiter_out(Waiter* w) {
    if (!w->filed) return;
    w->filed = 0;
    if (w->kind == W_AT || w->kind == W_DEADLINE) {
        timer_out(w->on.timer - 1);
        w->on.timer = 0;
        return;
    }
    Waiter** head;
    Waiter** tail;
    list_of(w, &head, &tail);
    if (w->prev) w->prev->next = w->next; else *head = w->next;
    if (w->next) w->next->prev = w->prev; else *tail = w->prev;
    w->next = w->prev = NULL;
    if (w->kind == W_GATE) avra_rc_release(w->on.gate);
    else g_parked_fds--;
}

// THE LOSERS LEAVE AT THE RESUME: every waiter of the set still filed
// is taken out, and the set is empty again.
static void retract(Fiber* f) {
    uint32_t n = 0;
    for (uint32_t i = 0; i < f->held_n; i++) { n += f->held[i].filed; waiter_out(&f->held[i]); }
    for (Over* o = f->more; o;) {
        Over* after = o->next;
        n += o->w.filed;
        waiter_out(&o->w);
        free(o);
        o = after;
    }
    f->held_n = 0;
    f->more = NULL;
    if (TRACING && n) traced_fiber("retract", f, n);
}

// The set is claimed for `(arm, member)` — 1, and the task is ready —
// or it already was: 0, and the claimant moves on. A CLAIM IS NEVER
// DISPLACED, so a value promised to a task is taken by that task. A
// legacy park has no one to read its claim: its set is cleared here.
static int set_claimed(Fiber* f, int32_t arm, int32_t member, int64_t by) {
    if (f->claimed) return 0;
    f->claimed = 1;
    f->arm = arm;
    f->member = member;
    if (TRACING) traced_claim(f, by);
    if (f->legacy) {
        f->timed_out = arm != 0;
        f->legacy = 0;
        f->heeds = 0;
        f->claimed = 0;
        retract(f);
    }
    if (f->parked) {
        f->parked = 0;
        ready_push(f);
    }
    return 1;
}

// THE CLAIMANT TAKES THE WINNER OUT FIRST: the waiter leaves its list
// or the heap before its set is asked, so a source never meets the same
// waiter twice and the counts the fast path reads fall at once.
static int waiter_claims(Waiter* w, int64_t by) {
    waiter_out(w);
    return set_claimed(w->fiber, w->arm, w->member, by);
}

static Waiter* waiter_new(Fiber* f, uint32_t kind, int64_t arm, int64_t member) {
    Waiter* w;
    if (f->held_n < HELD) w = &f->held[f->held_n++];
    else {
        Over* o = malloc(sizeof(Over));
        if (!o) avra_trap("the scheduler ran out of memory for a waiter");
        o->next = f->more;
        f->more = o;
        w = &o->w;
    }
    *w = (Waiter){ .fiber = f, .arm = (int32_t)arm, .member = (int32_t)member, .kind = kind };
    return w;
}

// ONE SET AT A TIME: a sleep, a join or a descriptor park inside a set
// another row is still arming would leave that set with no one to wake.
static void alone(const Fiber* f) {
    if (f->held_n != 0 || f->claimed) avra_trap("a task waited inside a wait it had not parked");
}

// A gate opens for ever: every waiter is claimed, and whoever waits on
// it after is claimed at once.
static void gate_opened(void* gate, int64_t by) {
    int64_t* cells = task_cells(gate);
    cells[GATE_OPEN] = 1;
    while (cells[GATE_HEAD]) waiter_claims((Waiter*)(uintptr_t)cells[GATE_HEAD], by);
}

// A direction of `fd` is ready (or the descriptor failed): every
// waiter in that direction is claimed.
static void fd_ready(int fd, int writing) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    g_fds[fd].ready |= writing ? ARMED_WRITE : ARMED_READ;
    while (g_fds[fd].head[writing]) waiter_claims(g_fds[fd].head[writing], BY_POLLER);
}

// A read found `fd` drained: no data waits until the next edge — unless
// the peer has finished, whose end a read still has to find.
static void fd_drained(int64_t fd) {
    if (fd < 0 || (size_t)fd >= g_fds_cap || (g_fds[fd].ready & READ_CLOSED)) return;
    g_fds[fd].ready &= ~ARMED_READ;
}

// A task parks on `fd` having found nothing that way: that direction is
// not ready until the next edge — a finished peer's read excepted.
static void parked_unready(int fd, int64_t writable) {
    FdWaits* w = fd_waits(fd);
    if (writable) w->ready &= ~ARMED_WRITE;
    else if (!(w->ready & READ_CLOSED)) w->ready &= ~ARMED_READ;
}

// The peer has finished writing: a read of `fd` is ready from now on.
static void fd_closed(int fd) {
    if (fd >= 0 && (size_t)fd < g_fds_cap) g_fds[fd].ready |= READ_CLOSED | ARMED_READ;
}

int64_t avra_fiber_fd_ready(int64_t fd, int64_t writing) {
    int bit = writing ? ARMED_WRITE : ARMED_READ;
    if (fd < 0 || (size_t)fd >= g_fds_cap || !(g_fds[fd].armed & bit)) return 1;
    return (g_fds[fd].ready & bit) != 0;
}

// Waits for the poller up to `timeout_ns` (below zero: forever) and
// claims whoever it names.
static void poller_wait(int64_t timeout_ns) {
    poller_open();
    g_polls++;
    poll_counted();
    // an ask that came since the world last looked is answered before a sleep
    if (__builtin_expect(g_asked, 0)) timeout_ns = 0;
    enum { BATCH = 256 };
#if AVRA_KQUEUE
    struct kevent evs[BATCH];
    struct timespec ts = { (time_t)(timeout_ns / 1000000000), (long)(timeout_ns % 1000000000) };
    // the clock: held by the caller whenever this waits (`next_with_world`)
    int n = kevent(g_poller, NULL, 0, evs, BATCH, timeout_ns < 0 ? NULL : &ts);
    for (int i = 0; i < n; i++) {
        if (evs[i].filter == EVFILT_READ && (evs[i].flags & EV_EOF)) fd_closed((int)evs[i].ident);
        fd_ready((int)evs[i].ident, evs[i].filter == EVFILT_WRITE);
    }
#else
    struct epoll_event evs[BATCH];
    int ms = timeout_ns < 0 ? -1 : (int)((timeout_ns + 999999) / 1000000);
    // the clock: held by the caller whenever this waits (`next_with_world`)
    int n = epoll_wait(g_poller, evs, BATCH, ms);
    for (int i = 0; i < n; i++) {
        int fd = evs[i].data.fd;
        uint32_t e = evs[i].events;
        int failed = (e & (EPOLLERR | EPOLLHUP)) != 0;
        if ((e & EPOLLRDHUP) || failed) fd_closed(fd);
        if ((e & (EPOLLIN | EPOLLRDHUP)) || failed) fd_ready(fd, 0);
        if ((e & EPOLLOUT) || failed) fd_ready(fd, 1);
    }
#endif
    if (n < 0 && errno != EINTR) avra_trap("the scheduler's poller failed");
}

// ── The deadline ────────────────────────────────────────────────

// EVERY SCOPE KEEPS ITS OWN LIMIT. The task's deadline is the earliest
// limit of the scopes that may still ask; the scope holding it OWNS it,
// the outer one on a tie, and the heap holds that one limit.
#define SCOPE_IDS ((int64_t)1 << 62)
static int64_t g_scope_seq = 0;

static Scope* scope_at(const Fiber* f, uint32_t i) {
    return i < SCOPES ? (Scope*)&f->scope[i] : &f->deeper[i - SCOPES];
}

static void owner_found(Fiber* f) {
    f->deadline = 0;
    for (uint32_t i = 0; i < f->armed; i++) {
        int64_t at = scope_at(f, i)->at;
        if (f->deadline != 0 && at >= f->deadline) continue;
        f->owner = i;
        f->deadline = at;
    }
}

__attribute__((noinline, cold))
static void scopes_deepened(Fiber* f) {
    uint32_t cap = f->deeper_cap ? f->deeper_cap * 2 : SCOPES;
    Scope* more = realloc(f->deeper, cap * sizeof(Scope));
    if (!more) avra_trap("the scheduler ran out of memory for a `within`");
    f->deeper = more;
    f->deeper_cap = cap;
}

// Answers the scope's id. A scope opened under a standing request is
// inside the scope that asked, so it may never ask.
static int64_t within_opened(Fiber* f, int64_t ms) {
    uint32_t i = f->scopes_n;
    if (i >= SCOPES && i - SCOPES >= f->deeper_cap) scopes_deepened(f);
    int64_t at = deadline_after(ms < 0 ? 0 : ms);
    int64_t id = SCOPE_IDS | ++g_scope_seq;
    *scope_at(f, i) = (Scope){ id, at };
    f->scopes_n = i + 1;
    if (f->armed != i) return id;
    f->armed = i + 1;
    if (f->deadline == 0 || at < f->deadline) {
        f->owner = i;
        f->deadline = at;
    }
    return id;
}

__attribute__((noinline, cold, noreturn))
static void scope_out_of_order(Fiber* f, int64_t id) {
    for (uint32_t i = 0; i < f->scopes_n; i++)
        if (scope_at(f, i)->id == id) avra_trap("a `within` ended while one inside it stands");
    avra_trap("a `within` ended that its task never opened");
}

// The innermost scope ends: 1 when the request that stands was its own.
static int64_t scope_ended(Fiber* f, int64_t id) {
    uint32_t n = f->scopes_n;
    if (n == 0 || scope_at(f, n - 1)->id != id) scope_out_of_order(f, id);
    f->scopes_n = --n;
    int64_t landed = f->scope_by == id;
    if (landed) f->scope_by = 0;
    if (f->armed > n) {
        f->armed = n;
        owner_found(f);
    }
    if (f->due.filed && f->due_at != f->deadline) waiter_out(&f->due);
    return landed;
}

static void due_filed(Fiber* f) {
    f->due = (Waiter){ .fiber = f, .arm = -1, .member = 1, .kind = W_DEADLINE, .filed = 1 };
    f->due_at = f->deadline;
    timer_set(T_WAITER, &f->due, f->deadline);
    if (TRACING) traced_fiber("deadline-set", f, (long long)f->deadline);
}

// A request a standing one outranks: the scope that asked, and the
// request that stands — a scope's id, or 1 + the asking task's.
__attribute__((noinline, cold))
static void traced_dropped(const Fiber* f, int64_t scope, int64_t standing) {
    char line[160];
    if (standing & SCOPE_IDS) avra_fmt(line, sizeof line, "request-dropped id=%lld by=scope:%lld for=scope:%lld", (long long)id_of(f), (long long)scope, (long long)standing);
    else avra_fmt(line, sizeof line, "request-dropped id=%lld by=scope:%lld for=task:%lld", (long long)id_of(f), (long long)scope, (long long)(standing - 1));
    traced(line);
}

// THE OWNER'S LIMIT HAS PASSED, AND ITS SCOPE ASKS. A task's cancel
// outranks it, and then no scope of the task asks again; otherwise it
// stands, displacing an inner scope's request, and only the scopes
// outside it may still ask — the next of them is filed at once.
static void deadline_reached(Fiber* f) {
    int64_t id = scope_at(f, f->owner)->id;
    if (f->cancel_by != 0) {
        if (TRACING) traced_dropped(f, id, f->cancel_by);
        f->armed = 0;
        f->deadline = 0;
        return;
    }
    if (TRACING && f->scope_by != 0) traced_dropped(f, f->scope_by, id);
    f->scope_by = id;
    f->armed = f->owner;
    owner_found(f);
    if (f->deadline != 0) due_filed(f);
}

// IT IS ARMED AT THE FIRST WAIT UNDER IT, ONCE: that wait reads the
// clock and files the deadline's waiter, which stays until its owner
// changes — so a `within` nothing waits under does no heap work, and a
// second wait under one reads no clock. Whether a scope's request stands.
static int deadline_passed(Fiber* f) {
    if (f->scope_by != 0) return 1;
    if (f->deadline == 0) return 0;
    if (f->due.filed && f->due_at == f->deadline) return 0;
    waiter_out(&f->due);
    if (now_ns() >= f->deadline) {
        deadline_reached(f);
        return f->scope_by != 0;
    }
    due_filed(f);
    return 0;
}

static void deadline_fired(Fiber* f) {
    if (TRACING) traced_fiber("deadline-fired", f, (long long)f->deadline);
    deadline_reached(f);
    if (f->parked && f->heeds) set_claimed(f, -1, 1, BY_DEADLINE);
}

// A TASK STARTS UNDER ITS SPAWNER'S LIMIT: one record, the scope whose
// request stands or else the owner, copied whole — its id is the
// spawner's scope's, so no scope of the child's own lands it.
static void scope_inherited(Fiber* child, const Fiber* from) {
    const Scope* s = from->scope_by != 0 ? scope_at(from, from->armed) : from->deadline != 0 ? scope_at(from, from->owner) : NULL;
    if (!s) return;
    child->scope[0] = *s;
    child->scopes_n = child->armed = 1;
    child->owner = 0;
    child->deadline = s->at;
}

// ── Stacks ──────────────────────────────────────────────────────

// Each stack is a RESERVATION: pages commit when touched, so a fiber
// costs what it used. A stack is bound to a task at its FIRST RUN, so a
// task spawned and not yet run holds none, and tasks that run one after
// another share the stack the last one left warm.
#define STACK_DEFAULT ((size_t)256 << 10)

// A stack and the page whose fault is its overflow: its own, directly
// under it, or the one at the foot of its slab.
typedef struct { char* base; char* guard; } Stack;

static size_t g_page = 0;
static size_t g_stack_bytes = 0;

// FINISHED STACKS ARE KEPT, WARM, AND NEVER UNMAPPED. Handing a stack
// back costs a syscall and taking a fresh one a page fault —
// microseconds against a spawn of about a hundred nanoseconds — so a
// stack goes to its pool with its pages. A pool's oldest members, past
// the POOL_HOT most recent, give their pages back when the scheduler
// has nothing to run (`pool_trim`), which is time nobody is waiting on.
//
// TWO POOLS, BY WHAT GUARDS THE STACK: those with a guard of their own
// directly under them, and those that share their slab's. A task takes
// a stack of the first kind whenever one is free, so a guard page each
// is what tasks have until more of them hold a stack at once than there
// are such stacks.
#define POOL_HOT 256
typedef struct { Stack* at; size_t len; size_t cap; size_t clean; } Pool;   // members below `clean` have given their pages back
static Pool g_guarded = {0};
static Pool g_shared = {0};

static void guard_handler_install(void);
static void tasks_door_opened(void);
static void tasks_door_named(void);

#ifndef MADV_GUARD_INSTALL
#define MADV_GUARD_INSTALL 102
#endif

// Whether the kernel has guard regions, whether every stack gets a guard
// of its own, and how many more do while not every one does.
static int g_guard_regions = 0;
static int g_guards_all = 0;
static size_t g_each_left = 0;

__attribute__((noinline, cold, noreturn))
static void guards_misspelled(const char* value) {
    char words[200];
    avra_fmt(words, sizeof words, "AVRA_FIBER_GUARDS is `%s` — it is `all`, or a whole number of stacks that get a guard page each", value);
    avra_trap(words);
}

// STACK GUARD POLICY. KEEP THIS COMMENT: it is the only record of a
// safety trade the code cannot show. Do not remove or shorten it.
//   guard regions (Linux >= 6.13): every stack guarded; an overflow traps at the write.
//   else, the first K tasks:        a guard page each; an overflow traps at the write.
//   else, beyond K:                 one guard per slab, a canary at each stack's floor,
//                                   checked at every switch-out. An overflow traps at
//                                   the task's NEXT SWITCH, and may have written into
//                                   the neighbouring stack before then.
//   AVRA_FIBER_GUARDS=all:          a guard page each, always; tasks are then capped
//                                   at half the kernel's mapping limit.
// K exists because a guard page costs two mappings and the kernel caps them
// (vm.max_map_count). A limit check in every fn prologue closes the gap at a
// per-call cost; it is the compiler's to add, not this file's.
//
// K is `g_each_left`: an eighth of the mapping limit, so guarded stacks
// take a quarter of the process's mappings; `AVRA_FIBER_GUARDS=<n>` sets
// it; a value, `all` or a count, is given pages whatever the kernel has,
// and any other spelling is refused. "The first K
// tasks" are whoever holds a stack while at most K do: a task takes a
// page-guarded stack whenever one is free. The canary is the top word of
// the stack below, which nothing writes, so it costs no page. Past K a
// runaway recursion still reaches the slab's guard; a bounded overrun
// that returns before the next switch and never wrote that one word is
// not caught.
static void guards_settle(void) {
    const char* env = getenv("AVRA_FIBER_GUARDS");
    // A VALUE ASKS FOR PAGES BY NAME, so it is given them whatever the
    // kernel has: `all` is a page under every stack and the ceiling that
    // comes with it, and a count is how the policy past K is run and
    // tested on a kernel with guard regions.
    if (env && strcmp(env, "all") == 0) { g_guards_all = 1; return; }
    if (env && *env) {
        // A COUNT IS READ WHOLE OR REFUSED: a word misread as 0 would
        // quietly choose the weakest guard there is.
        char* end = NULL;
        errno = 0;
        unsigned long long n = *env >= '0' && *env <= '9' ? strtoull(env, &end, 10) : 0;
        if (!end || *end != 0 || errno != 0) guards_misspelled(env);
        g_each_left = (size_t)n;
        return;
    }
#if AVRA_EPOLL
    void* probe = mmap(NULL, g_page, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (probe != MAP_FAILED) {
        g_guard_regions = madvise(probe, g_page, MADV_GUARD_INSTALL) == 0;
        munmap(probe, g_page);
    }
    if (g_guard_regions) { g_guards_all = 1; return; }
    // A QUARTER OF THE PROCESS'S MAPPINGS GO TO GUARDED STACKS, two
    // apiece; the rest are the program's, and the slabs' after them.
    FILE* f = fopen("/proc/sys/vm/max_map_count", "r");
    long limit = 0;
    if (f) {
        if (fscanf(f, "%ld", &limit) != 1) limit = 0;
        fclose(f);
    }
    if (limit > 0) { g_each_left = (size_t)limit / 8; return; }
#endif
    g_guards_all = 1;
}

static void stacks_settle(void) {
    if (g_page) return;
    g_page = (size_t)sysconf(_SC_PAGESIZE);
    size_t want = STACK_DEFAULT;
    const char* env = getenv("AVRA_FIBER_STACK");
    if (env) {
        long long v = atoll(env);
        if (v > 0) want = (size_t)v;
    }
    g_stack_bytes = (want + g_page - 1) / g_page * g_page;
    guards_settle();
    guard_handler_install();
    tasks_door_opened();
}

static int own_guard(Stack s) { return s.guard == s.base - g_page; }

static void stack_give(Stack s) {
    Pool* p = own_guard(s) ? &g_guarded : &g_shared;
    if (p->len == p->cap) {
        p->cap = p->cap ? p->cap * 2 : 64;
        p->at = realloc(p->at, p->cap * sizeof(Stack));
        if (!p->at) avra_trap("the scheduler ran out of memory for its stack pool");
    }
    p->at[p->len++] = s;
}

// Whether `page` now faults when touched.
static int guard_set(char* page) {
    if (g_guard_regions) return madvise(page, g_page, MADV_GUARD_INSTALL) == 0;
    return mprotect(page, g_page, PROT_NONE) == 0;
}

__attribute__((noinline, cold, noreturn))
static void guard_refused(void) {
    if (g_guard_regions) avra_trap("the scheduler could not guard a task's stack: the kernel refused a guard region");
    avra_trap("the scheduler could not guard a task's stack: a guarded stack takes two of the process's mappings and the kernel holds no more — raise vm.max_map_count, run a kernel with guard regions (Linux 6.13 or later), or unset AVRA_FIBER_GUARDS");
}

// A mapping of `bytes` that never becomes a huge page: a stack's top
// page touched must stay one page resident.
static char* reserved(size_t bytes) {
    char* s = mmap(NULL, bytes, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (s == MAP_FAILED) avra_trap("the scheduler could not reserve task stacks");
#ifdef MADV_NOHUGEPAGE
    madvise(s, bytes, MADV_NOHUGEPAGE);
#endif
    return s;
}

// Fresh stacks come a SLAB at a time: one reservation carved into
// SLAB stacks, all filed in the pool. One map call where there were
// SLAB.
#define SLAB 64

// SLAB stacks, each over a guard of its own. 0 when the kernel refused
// one: the slab is given back whole.
static int slab_guarded_each(size_t n) {
    size_t each = g_page + g_stack_bytes;
    char* s = reserved(each * n);
    for (size_t i = 0; i < n; i++) {
        if (guard_set(s + i * each)) continue;
        munmap(s, each * n);
        return 0;
    }
    for (size_t i = n; i-- > 0;) stack_give((Stack){ s + i * each + g_page, s + i * each });
    return 1;
}

// SLAB stacks side by side over one guard at the slab's foot.
static void slab_guarded_once(void) {
    char* s = reserved(g_page + g_stack_bytes * SLAB);
    if (!guard_set(s)) guard_refused();
    for (size_t i = SLAB; i-- > 0;) stack_give((Stack){ s + g_page + i * g_stack_bytes, s });
}

static void slab_made(void) {
    size_t n = g_guards_all || g_each_left >= SLAB ? SLAB : g_each_left;
    if (n > 0) {
        if (slab_guarded_each(n)) {
            if (!g_guards_all) g_each_left -= n;
            return;
        }
        if (g_guards_all) guard_refused();
        g_each_left = 0;
    }
    slab_guarded_once();
}

static Stack pool_taken(Pool* p) {
    Stack s = p->at[--p->len];
    if (p->clean > p->len) p->clean = p->len;
    return s;
}

// A stack with a guard of its own while one is free or one more may be
// made; else one that shares its slab's. A shared slab is only ever
// made once no more guarded ones may be, so both pools empty is the one
// time a slab is owed.
static Stack stack_take(void) {
    if (g_guarded.len == 0 && g_shared.len == 0) slab_made();
    return pool_taken(g_guarded.len > 0 ? &g_guarded : &g_shared);
}

static void pool_trimmed(Pool* p) {
    while (p->len > POOL_HOT && p->clean < p->len - POOL_HOT) {
        madvise(p->at[p->clean].base, g_stack_bytes, MADV_FREE);
        p->clean++;
    }
}

static void pool_trim(void) {
    pool_trimmed(&g_guarded);
    pool_trimmed(&g_shared);
}

__attribute__((noinline, cold))
static void bury(void) {
    Fiber* f = g_finished;
    g_finished = NULL;
    if (f->base) stack_give((Stack){ f->base, f->guard });
    fiber_freed(f);
}

static inline void bury_finished(void) {
    if (__builtin_expect(g_finished != NULL, 0) && g_finished != g_current) bury();
}

// ── Choosing who runs ───────────────────────────────────────────

static void task_fired(void* task);

static void fire_due_timers(int64_t now) {
    while (g_timers_len > 0 && g_timers[0].at <= now) {
        Timer t = g_timers[0];
        timer_out(0);
        if (t.kind == T_TASK) { task_fired(t.who); continue; }
        Waiter* w = t.who;
        w->filed = 0;
        w->on.timer = 0;
        if (w->kind == W_DEADLINE) deadline_fired(w->fiber);
        else set_claimed(w->fiber, w->arm, w->member, BY_TIMER);
    }
}

// EVERY TASK WAITS, ON TIME ALONE: a frozen clock jumps to the earliest
// timer and nothing is waited for. With a descriptor waiter filed the
// world is waited on in real time instead, and the clock is HELD across
// that wait — it flows by the wall time the wait took, so a deadline
// around a real descriptor means what it says.
static int world_waited_virtually(void) {
    return g_parked_fds == 0 && g_timers_len > 0 && avra_clock_jumped(g_timers[0].at);
}

static void fiber_start(void);
static int case_deadlocked(void);
static void tasks_answered(void);
typedef struct DoorNames DoorNames;
static void listing_written(int dfd, const DoorNames* names);
static void ages_noted(int64_t now);

// A fiber's first run: a stack from the pool, and at its top a frame
// `avra_fiber_switch` will restore — zeroed callee-saved registers and
// `fiber_start` where the return goes. The top word stays untouched:
// it is the word the stack above reads as its canary.
static void fiber_framed(Fiber* f, Stack s, size_t bytes) {
    f->guard = s.guard;
    f->floor = (uintptr_t)s.base;
    f->canary = own_guard(s) ? &g_untouched : (const uint64_t*)(s.base - sizeof(uint64_t));
    uint64_t* frame = (uint64_t*)((((uintptr_t)s.base + bytes - 16) & ~(uintptr_t)15) - FIBER_FRAME);
    memset(frame, 0, FIBER_FRAME);
    frame[FIBER_RETURN] = (uint64_t)(uintptr_t)fiber_start;
    f->sp = frame;
}

// THE WIDE STACK: one reservation the size of the main thread's stack,
// its own guard page under it, for the one task at a time that runs a
// case's body — which recurses as far as `main` would let it. It is
// never pooled: a fiber on it keeps no `base`, so nothing gives it back.
#define WIDE_STACK_LEAST ((size_t)8 << 20)
static Stack g_wide = { NULL, NULL };
static size_t g_wide_bytes = 0;

static Stack wide_stack(void) {
    if (g_wide.base) return g_wide;
    struct rlimit main_stack;
    g_wide_bytes = WIDE_STACK_LEAST;
    if (getrlimit(RLIMIT_STACK, &main_stack) == 0 && main_stack.rlim_cur != RLIM_INFINITY && main_stack.rlim_cur > g_wide_bytes) g_wide_bytes = (size_t)main_stack.rlim_cur;
    g_wide_bytes &= ~(g_page - 1);
    char* low = reserved(g_wide_bytes + g_page);
    if (mprotect(low, g_page, PROT_NONE) != 0) avra_trap("the scheduler could not guard a case's stack");
    g_wide = (Stack){ low + g_page, low };
    return g_wide;
}

static void fiber_bound(Fiber* f) {
    if (f->wide) { fiber_framed(f, wide_stack(), g_wide_bytes); return; }
    Stack s = stack_take();
    f->base = s.base;
    fiber_framed(f, s, g_stack_bytes);
}

// Where the switch goes when it finds a fiber under its floor or its
// canary written.
__attribute__((noinline, cold, noreturn, visibility("hidden"), used))
void avra_fiber_overflowed(const Fiber* f) {
    char words[160];
    void* body = f->task ? (void*)(uintptr_t)task_cells(f->task)[TASK_BODY] : NULL;
    void* site = body ? (void*)(uintptr_t)((AvraArray*)body)->data[0] : NULL;
    avra_fmt(words, sizeof words, "a task's stack overflowed into its neighbour — caught at a switch (task %lld, spawned at %p)", (long long)id_of(f), site);
    avra_trap(words);
}

// The switch to a fiber that has never run, whole and out of line: a
// call that came back into the switch would cost every switch the
// registers it saves across it.
__attribute__((noinline, cold))
static void switched_to_fresh(Fiber* self, Fiber* next) {
    fiber_bound(next);
    g_current = next;
    avra_task_local = next->local;
    self->unwinding = avra_unwinding;
    avra_unwinding = next->unwinding;
    avra_fiber_switch(&self->sp, next->sp);
    bury_finished();
}

// INLINED INTO EVERY PARK AND YIELD: the switch is the leaf everything
// else here is measured against.
__attribute__((always_inline))
static inline void switch_to(Fiber* next) {
    Fiber* self = g_current;
    next->state = FIBER_RUNNING;
    if (next == self) return;
    if (__builtin_expect(!next->sp, 0)) { switched_to_fresh(self, next); return; }
    g_current = next;
    avra_task_local = next->local;
    self->unwinding = avra_unwinding;
    avra_unwinding = next->unwinding;
    avra_fiber_switch(&self->sp, next->sp);
    bury_finished();
}

// The caller has already filed itself (ready, parked, waiting or
// done); who runs next, the world asked first, and waited on when
// nobody is ready. A world with nothing to wait on and nobody ready is
// a deadlock, and a deadlock is never a hang.
// The poller's turn among ready tasks: every FAIR_TURNS switches while a
// descriptor waiter is filed, seeded or not.
static void poller_turn(void) {
    if (pinned()) {
        if (g_parked_fds > 0 && --g_pinned_until_poll <= 0) poller_wait(0);
        return;
    }
    if (g_until_poll > 0) return;
    if (g_parked_fds > 0) poller_wait(0);
    else g_until_poll = POLL_IDLE;
}

// A schedule's own number, drawn on: splitmix64.
static uint64_t seed_drawn(void) {
    uint64_t z = (g_seed_state += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

// Which of `n` runs: schedule 0 takes the first, any other draws.
static uint64_t chosen(uint64_t n) {
    g_choices++;
    if (g_schedule == 0) return 0;
    return (uint64_t)(((__uint128_t)seed_drawn() * n) >> 64);
}

// THE SEEDED PICK: one of the first PICK_WINDOW ready tasks, by the
// schedule's choice. A PICK AMONG ONE IS NO CHOICE — nothing is counted
// and nothing drawn, so a switch one engine makes and the other skips
// costs the schedule nothing. The window bounds the walk whatever is
// ready; a task behind it moves up as the queue does.
enum { PICK_WINDOW = 16 };
static Fiber* ready_picked(void) {
    Fiber* before[PICK_WINDOW];
    uint64_t n = 0;
    Fiber* prev = NULL;
    for (Fiber* q = g_ready_head; q && n < PICK_WINDOW; prev = q, q = q->next) before[n++] = prev;
    g_pick_links += (int64_t)n;
    if (n < 2) return ready_pop();
    uint64_t k = chosen(n);
    Fiber* f = before[k] ? before[k]->next : g_ready_head;
    if (before[k]) before[k]->next = f->next; else g_ready_head = f->next;
    if (g_ready_tail == f) g_ready_tail = before[k];
    f->next = NULL;
    return f;
}

__attribute__((noinline))
static Fiber* next_with_world(void) {
    g_world_visits++;
    // A TASK THAT PARKS HAS WAITED: its count of reads of a frozen clock
    // begins again.
    if (avra_clock.virtual && g_current->state == FIBER_PARKED) g_current->local->clock_asks = 0;
    g_in_world = 1;
    for (;;) {
        if (__builtin_expect(g_asked, 0)) tasks_answered();
        if (g_timers_len > 0) {
            int64_t now = now_ns();
            ages_noted(now);
            fire_due_timers(now);
        }
        poller_turn();
        Fiber* next = g_seeded ? ready_picked() : ready_pop();
        if (next) {
            // an ask counted during this pass, after its count was reset,
            // brings the next switch back here
            if (__builtin_expect(g_asked, 0)) g_until_poll = 0;
            g_in_world = 0;
            return next;
        }
        if (g_timers_len == 0 && g_parked_fds == 0) {
            if (case_deadlocked()) continue;
            avra_trap("every task is waiting — deadlock");
        }
        pool_trim();
        if (world_waited_virtually()) continue;
        int64_t wait = g_timers_len > 0 ? g_timers[0].at - now_ns() : -1;
        int held = g_parked_fds > 0;
        if (held) avra_clock_hold(1);
        poller_wait(g_timers_len > 0 && wait < 0 ? 0 : wait);
        if (held) avra_clock_hold(-1);
        // a wait that blocked may have lasted: the clock is asked again
        if (wait != 0) ages_noted(now_ns());
    }
}

// Whether the queue alone decides this switch: no timer is filed, and
// the poller's turn has not come.
__attribute__((always_inline))
static inline int queue_alone(void) {
    int64_t left = --g_until_poll;
    return __builtin_expect(g_timers_len == 0 && left > 0, 1);
}

// THE POLICY, ONE FOR BOTH ENGINES: who runs next. A compiled program
// switches to the fiber it answers; the evaluator is handed it and
// switches call stacks itself — so both interleave tasks alike, and
// both ask the world by the same law. The world's machinery stays out
// of line: A COLD PATH IN A HOT LEAF COSTS EVERY SWITCH A FRAME.
__attribute__((always_inline))
static inline Fiber* next_ready(void) {
    if (queue_alone()) {
        Fiber* next = ready_pop();
        if (next) return next;
    }
    return next_with_world();
}

__attribute__((noinline))
static void run_next_with_world(void) {
    Fiber* next = next_with_world();
    if (next->virtual) avra_trap("defect: a compiled task's scheduler met one of the evaluator's");
    switch_to(next);
}

__attribute__((always_inline))
static inline void run_next(void) {
    if (queue_alone()) {
        Fiber* next = ready_pop();
        if (next) { switch_to(next); return; }
    }
    run_next_with_world();
}

// ── The guard ───────────────────────────────────────────────────

static char g_signal_stack[64 * 1024] __attribute__((aligned(16)));
static struct sigaction g_prior_segv;
static struct sigaction g_prior_bus;

static int in_guard(const Fiber* f, uintptr_t a) {
    return f->guard && a >= (uintptr_t)f->guard && a < (uintptr_t)f->guard + g_page;
}

static void guard_fault(int sig, siginfo_t* info, void* ctx) {
    (void)ctx;
    if (in_guard(g_current, (uintptr_t)info->si_addr)) {
        // avra_trap's words, written as a signal handler may: no stdio
        const char* in_case = avra_case_now();
        if (in_case) {
            static const char running[] = "avra: while running ";
            ssize_t w = write(2, running, sizeof running - 1);
            w = write(2, in_case, strlen(in_case));
            w = write(2, "\n", 1);
            (void)w;
        }
        static const char words[] = "avra: a task's stack overflowed\n";
        ssize_t w = write(2, words, sizeof words - 1);
        (void)w;
        _exit(2);
    }
    // Not ours: the prior disposition takes the fault as it would have.
    sigaction(sig, sig == SIGSEGV ? &g_prior_segv : &g_prior_bus, NULL);
}

static void guard_handler_install(void) {
    stack_t alt = { .ss_sp = g_signal_stack, .ss_size = sizeof g_signal_stack, .ss_flags = 0 };
    if (sigaltstack(&alt, NULL) != 0) avra_trap("the scheduler could not set its signal stack");
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_sigaction = guard_fault;
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, &g_prior_segv);
    sigaction(SIGBUS, &sa, &g_prior_bus);
}

// ── Waiting ─────────────────────────────────────────────────────

static void waits_fd(Fiber* f, int64_t fd, int64_t writable, int64_t arm, int64_t member) {
    if (f->claimed) return;
    if (fd < 0 || fd > INT32_MAX) { set_claimed(f, (int32_t)arm, (int32_t)member, BY_POLLER); return; }
    poller_open();
    // AN EDGE BELONGS TO WHOEVER WAITED WHEN IT CAME: one the poller has
    // not yet reported is theirs, so they are told before a later task
    // joins them — or it would wake on news that was never its own.
    if ((size_t)fd < g_fds_cap && g_fds[fd].head[writable != 0]) poller_wait(0);
    Waiter* w = waiter_new(f, writable ? W_FD_WRITE : W_FD_READ, arm, member);
    w->on.fd = (int)fd;
    waiter_filed(w);
    parked_unready((int)fd, writable);
    // A descriptor the poller refuses is ready now: the read or write
    // the caller retries reports its own error.
    if (!fd_arm((int)fd)) waiter_claims(w, BY_POLLER);
    else if (TRACING) traced_waiter(f, w);
}

static void waits_until(Fiber* f, int64_t at_ns, int64_t arm, int64_t member) {
    if (f->claimed) return;
    Waiter* w = waiter_new(f, W_AT, arm, member);
    w->filed = 1;
    timer_set(T_WAITER, w, at_ns);
    if (TRACING) traced_waiter(f, w);
}

static void waits_gate(Fiber* f, void* gate, int64_t arm, int64_t member) {
    if (f->claimed) return;
    if (task_cells(gate)[GATE_OPEN]) { set_claimed(f, (int32_t)arm, (int32_t)member, id_of(f)); return; }
    Waiter* w = waiter_new(f, W_GATE, arm, member);
    w->on.gate = gate;
    avra_rc_retain(gate);
    waiter_filed(w);
    if (TRACING) traced_waiter(f, w);
}

// A CANCEL MEETS A CANCEL POINT: the running task's unwind bit is set.
static void cancel_met(void) { avra_unwinding = 1; }

// Whether the claim a task resumed on was a cancel's: `-1:0`.
static int claimed_by_cancel(const Fiber* f) { return f->arm == -1 && f->member == 0; }

// A row that predates the wait set, about to park: under a standing
// cancel it parks nothing and the cancel is met at once.
static int cancel_stands(const Fiber* f) {
    if (__builtin_expect(f->cancel_by == 0, 1)) return 0;
    cancel_met();
    return 1;
}

// The set is about to be waited on: whether the task must switch out.
// A CLAIM COMES FIRST — a value handed while the set was arming is
// taken before anything else is heard — then a cancel that stands, then
// a deadline that has passed.
static int park_begun(Fiber* f) {
    f->heeds = 1;
    if (f->claimed) return 0;
    if (f->cancel_by != 0) { set_claimed(f, -1, 0, f->cancel_by - 1); return 0; }
    if (deadline_passed(f)) { set_claimed(f, -1, 1, BY_DEADLINE); return 0; }
    f->parked = 1;
    f->state = FIBER_PARKED;
    return 1;
}

// The claim, read by its task: `arm << 32 | member`, the set empty after.
static int64_t claim_taken(Fiber* f) {
    int64_t claim = (int64_t)(((uint64_t)(uint32_t)f->arm << 32) | (uint32_t)f->member);
    f->claimed = 0;
    f->heeds = 0;
    retract(f);
    return claim;
}

void avra_wait_fd(int64_t fd, int64_t writable, int64_t arm, int64_t member) { waits_fd(g_current, fd, writable, arm, member); }

void avra_wait_until(int64_t at_ns, int64_t arm, int64_t member) { waits_until(g_current, at_ns, arm, member); }

void avra_wait_gate(void* gate, int64_t arm, int64_t member) { waits_gate(g_current, gate, arm, member); }

void avra_wait_task(void* task, int64_t arm, int64_t member) { waits_gate(g_current, task, arm, member); }

int64_t avra_wait_park(void) {
    Fiber* self = g_current;
    if (park_begun(self)) run_next();
    if (claimed_by_cancel(self)) cancel_met();
    return claim_taken(self);
}

void* avra_gate_new(void) {
    void* gate = avra_array_sized(GATE_CELLS);
    for (int i = 0; i < GATE_CELLS; i++) avra_array_push(gate, 0);
    return gate;
}

__attribute__((noinline))
static int64_t gate_claimed(void* gate, int64_t by) {
    int64_t* cells = task_cells(gate);
    while (cells[GATE_HEAD]) {
        Waiter* w = (Waiter*)(uintptr_t)cells[GATE_HEAD];
        int32_t member = w->member;
        if (waiter_claims(w, by)) return member;
    }
    return -1;
}

// A gate nobody waits on is asked often — a ring with no one parked —
// and answers from a load and a test.
int64_t avra_gate_claim(void* gate) {
    if (!task_cells(gate)[GATE_HEAD]) return -1;
    return gate_claimed(gate, id_of(g_current));
}

// ── A task's life ───────────────────────────────────────────────

// A task's body answers ONE box — its value in a one-cell list, made
// by the compiler's task lift — so one call serves every answer.
typedef void* (*TaskCode)(void*);

// A task's record: a closed gate, then its fiber, its body, its answer,
// its place in the timer heap and how it ended.
static void* task_made(Fiber* f, void* body) {
    void* task = avra_array_sized(TASK_CELLS);
    for (int i = 0; i < GATE_CELLS; i++) avra_array_push(task, 0);
    avra_array_push(task, (int64_t)(uintptr_t)f);
    avra_array_push_owned(task, body);
    avra_array_push_owned(task, NULL);
    avra_array_push(task, 0);
    avra_array_push(task, END_LIVE);
    return task;
}

// Where every new fiber begins: run the body, keep its answer, wake
// whoever waits on it, and hand the thread on for good.
__attribute__((noreturn))
static void fiber_start(void) {
    bury_finished();
    Fiber* self = g_current;
    void* task = self->task;
    void* body = (void*)(uintptr_t)task_cells(task)[TASK_BODY];
    TaskCode code = (TaskCode)(uintptr_t)((AvraArray*)body)->data[0];
    void* answer = code(body);
    int64_t* cells = task_cells(task);
    cells[TASK_ANSWER] = (int64_t)(uintptr_t)answer;
    cells[TASK_FIBER] = 0;
    // A BODY THAT COMES BACK UNWINDING LEFT AT A CANCEL POINT: it ended
    // cancelled, and a join refuses what it answered.
    cells[TASK_END] = avra_unwinding ? END_CANCELLED : END_ANSWERED;
    gate_opened(task, id_of(self));
    // A TASK THAT ENDS WAITS ON NOTHING: what it registered and never
    // parked on leaves with it, before its record is anyone else's.
    retract(self);
    self->claimed = 0;
    waiter_out(&self->due);
    for (int i = 0; i < AVRA_TASK_SLOTS; i++) {
        void* held = self->own.slot[i];
        if (!held) continue;
        self->own.slot[i] = NULL;
        avra_rc_release(held);
    }
    if (TRACING) traced_fiber("end", self, 0);
    self->state = FIBER_DONE;
    g_finished = self;
    avra_rc_release(task);
    run_next();
    __builtin_unreachable();
}

void* avra_task_spawn(void* body) {
    stacks_settle();
    Fiber* f = fiber_new(NULL, 0);
    void* task = task_made(f, body);
    f->task = task;
    scope_inherited(f, g_current);
    avra_rc_retain(task);                       // the running fiber's own reference
    if (TRACING) traced_spawn(f, body);
    ready_push(f);
    return task;
}

// A join that would close a ring of joins can never return: the task
// it waits on waits, through its own join, on the caller. Walked at
// every join, so a ring is caught at the join that closes it, whatever
// else the world is waiting on.
static void refuse_join_ring(void* task, Fiber* self) {
    for (void* t = task; t;) {
        Fiber* f = (Fiber*)(uintptr_t)task_cells(t)[TASK_FIBER];
        if (f == self) {
            avra_trap(t == task ? "a task joined itself — deadlock" : "tasks join each other in a ring — deadlock");
        }
        t = f && f->state == FIBER_PARKED ? f->joining : NULL;
    }
}

// The caller parks by one of the rows that predate the wait set: its
// waiters are filed, no cancel reaches it, and its claim clears itself.
static void legacy_parked(Fiber* self) {
    self->legacy = 1;
    self->parked = 1;
    self->state = FIBER_PARKED;
}

// The id of the fiber that runs `task`, or -1 when nothing runs it.
static int64_t task_id(void* task) {
    Fiber* f = (Fiber*)(uintptr_t)task_cells(task)[TASK_FIBER];
    return f ? id_of(f) : -1;
}

static void task_cancelled(void* task, int64_t by);

// The calling task parked until `task` has ended; its cells, read after.
// A JOIN IS A CANCEL POINT and a scope's end joining what it owns is NOT
// (`deaf`): the owner leaving cancels the task, then waits it out.
static int64_t* task_awaited(void* task, int deaf) {
    int64_t* cells = task_cells(task);
    if (cells[GATE_OPEN]) return cells;
    Fiber* self = g_current;
    if (!deaf && cancel_stands(self)) return cells;
    refuse_join_ring(task, self);
    alone(self);
    if (TRACING) traced_join(self, task_id(task));
    self->joining = task;
    self->deaf = (uint8_t)deaf;
    waits_gate(self, task, 0, 0);
    legacy_parked(self);
    run_next();
    self->joining = NULL;
    self->deaf = 0;
    return task_cells(task);
}

__attribute__((noinline, cold, noreturn))
static void join_refused(void) { avra_trap("a join takes a task that answers, and this one was cancelled"); }

__attribute__((noinline, cold, noreturn))
static void join_cut(void) { avra_trap("a join was cut by a cancel, and its task has not answered"); }

// A JOIN TAKES A TASK THAT ANSWERS: a cancelled one has no answer, and
// none is made up for it. A join a cancel cut has none either — until
// the code after it tests the unwind bit, it traps.
void* avra_task_join(void* task) {
    int64_t* cells = task_awaited(task, 0);
    if (!cells[GATE_OPEN]) join_cut();
    if (cells[TASK_END] == END_CANCELLED) join_refused();
    void* answer = (void*)(uintptr_t)cells[TASK_ANSWER];
    avra_rc_retain(answer);
    return answer;
}

// An owner's scope ends: the task is joined, its answer left to its
// other holders. Joining a done task is free, so a copy's second
// settle costs nothing.
void avra_task_settle(void* task) {
    if (!task) return;
    if (g_current->cancel_by != 0) task_cancelled(task, id_of(g_current));
    task_awaited(task, 1);
}

// A FULL OWNER SHEDS ITS FINISHED TASKS before it grows: each is
// joined (its answer released) and dropped, the live ones keep their
// order, and the owner is left at least half empty — so a push costs
// O(1) amortized however long the owner lives.
static void tasks_shed(AvraArray* a) {
    int64_t kept = 0;
    for (int64_t i = 0; i < a->len; i++) {
        void* t = (void*)(uintptr_t)a->data[i];
        if (task_cells(t)[GATE_OPEN]) {
            avra_task_settle(t);
            avra_rc_release(t);
            continue;
        }
        a->data[kept] = a->data[i];
        a->marks[kept] = a->marks[i];
        kept++;
    }
    a->len = kept;
    avra_array_reserve(a, kept < 4 ? 4 : kept);
}

void avra_tasks_push(void* owner, void* task) {
    AvraArray* a = (AvraArray*)owner;
    if (a->len == a->cap) tasks_shed(a);
    avra_array_push_owned(owner, task);
}

void avra_task_settle_all(void* list) {
    AvraArray* a = (AvraArray*)list;
    for (int64_t i = 0; i < a->len; i++) avra_task_settle((void*)(uintptr_t)a->data[i]);
}

int64_t avra_task_done(void* task) {
    return task_cells(task)[GATE_OPEN];
}

int64_t avra_task_ended(void* task) {
    return task_cells(task)[TASK_END];
}

// ── Tasks nothing runs ──────────────────────────────────────────
//
// A FIBERLESS task is a gate with an answer: whoever holds it answers
// it, or the timer heap does at its time. A TASK ANSWERS ONCE.

void* avra_task_pending(void) { return task_made(NULL, NULL); }

// The task ends: its place in the heap given up with the reference the
// heap held, its gate opened.
static void task_ended(void* task, int64_t how, int64_t by) {
    int64_t* cells = task_cells(task);
    cells[TASK_END] = how;
    int64_t at = cells[TASK_AT];
    if (at) {
        cells[TASK_AT] = 0;
        timer_out((size_t)at - 1);
    }
    gate_opened(task, by);
    if (at) avra_rc_release(task);
}

void avra_task_answer(void* task, void* v) {
    int64_t* cells = task_cells(task);
    if (cells[TASK_END] != END_LIVE) avra_trap("a task answered twice");
    if (cells[TASK_FIBER]) avra_trap("a running task answers for itself");
    avra_rc_retain(v);
    cells[TASK_ANSWER] = (int64_t)(uintptr_t)v;
    task_ended(task, END_ANSWERED, id_of(g_current));
}

// THE HEAP HOLDS A REFERENCE until the task's time comes or it is
// cancelled, so one nobody else holds still fires, and then is gone.
void* avra_task_at(int64_t at_ns) {
    void* task = task_made(NULL, NULL);
    avra_rc_retain(task);
    timer_set(T_TASK, task, at_ns);
    return task;
}

// The heap's entry is already out.
static void task_fired(void* task) {
    int64_t* cells = task_cells(task);
    void* unit = avra_array_sized(1);
    avra_array_push(unit, 0);
    cells[TASK_ANSWER] = (int64_t)(uintptr_t)unit;
    cells[TASK_AT] = 0;
    cells[TASK_END] = END_ANSWERED;
    gate_opened(task, BY_TIMER);
    avra_rc_release(task);
}

// A CANCEL IS A CLAIMANT THAT NEVER DISPLACES A CLAIM. It is recorded
// on the task, and claims the task's set only when nothing has: a task
// already claimed resumes on its arm, and meets the cancel at its next
// cancel point. A sleep, a join and a descriptor park are cut by it; a
// scope's end joining what it owns is not, and passes the cancel down
// to the task it waits on. An evaluated task's old rows hear it once
// the evaluator's arms read the unwind bit. A fiberless task simply
// ends.
static void fiber_cancelled(Fiber* f, int64_t by) {
    f->cancel_by = by + 1;
    if (TRACING) traced_fiber("cancel", f, (long long)by);
    if (f->scope_by != 0) {
        if (TRACING) traced_dropped(f, f->scope_by, by + 1);
        f->scope_by = 0;
    }
    if (f->deaf && f->joining) { task_cancelled(f->joining, by); return; }
    if (f->parked && !(f->legacy && f->virtual)) set_claimed(f, -1, 0, by);
}

static void task_cancelled(void* task, int64_t by) {
    int64_t* cells = task_cells(task);
    Fiber* f = (Fiber*)(uintptr_t)cells[TASK_FIBER];
    if (f) { fiber_cancelled(f, by); return; }
    if (cells[TASK_END] == END_LIVE) task_ended(task, END_CANCELLED, by);
}

void avra_task_cancel(void* task) { task_cancelled(task, id_of(g_current)); }

// ── The rows that predate the wait set ──────────────────────────

// A YIELD WAITS FOR NOTHING, SO A CANCEL CUTS NOTHING: it is met here
// and the task still lets the others run.
void avra_fiber_yield(void) {
    if (__builtin_expect(g_current->cancel_by != 0, 0)) cancel_met();
    if (!g_ready_head && g_timers_len == 0 && g_parked_fds == 0) return;
    ready_push(g_current);
    run_next();
}

__attribute__((noinline))
static void slept(int64_t ms) {
    Fiber* self = g_current;
    if (cancel_stands(self)) return;
    alone(self);
    waits_until(self, deadline_after(ms), 0, 0);
    legacy_parked(self);
    run_next();
    if (claimed_by_cancel(self)) cancel_met();
}

// A sleep of no time is a yield, and costs what a yield costs.
void avra_fiber_sleep(int64_t ms) {
    if (ms < 1) { avra_fiber_yield(); return; }
    slept(ms);
}

void avra_fiber_fd_closing(int64_t fd) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    FdWaits* w = &g_fds[fd];
    for (int d = 0; d < 2; d++) while (w->head[d]) waiter_claims(w->head[d], BY_CLOSE);
    w->armed = 0;
    w->ready = 0;
}

void avra_fiber_fd_interrupt(int64_t fd) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    FdWaits* w = &g_fds[fd];
    while (w->head[0]) {
        Fiber* f = w->head[0]->fiber;
        waiter_out(w->head[0]);
        set_claimed(f, -1, 1, BY_CLOSE);
    }
}

// The descriptor park, filed for `f`: 1 when it must wait, 0 when it
// need not — the descriptor cannot be watched, or the time has run out
// already (`timed_out` says which).
static int park_fd_filed(Fiber* f, int64_t fd, int64_t writable, int64_t timeout_ms) {
    f->timed_out = 0;
    if (fd < 0 || fd > INT32_MAX) return 0;
    if (!f->virtual && cancel_stands(f)) { f->timed_out = 1; return 0; }
    alone(f);
    if (deadline_passed(f)) { f->timed_out = 1; return 0; }
    f->legacy = 1;
    f->heeds = 1;
    waits_fd(f, fd, writable, 0, 0);
    if (!f->legacy) return 0;
    if (timeout_ms >= 0) waits_until(f, deadline_after(timeout_ms), 1, 0);
    f->parked = 1;
    f->state = FIBER_PARKED;
    return 1;
}

int64_t avra_fiber_park_fd(int64_t fd, int64_t writable, int64_t timeout_ms) {
    Fiber* self = g_current;
    if (park_fd_filed(self, fd, writable, timeout_ms)) {
        run_next();
        if (claimed_by_cancel(self)) cancel_met();
    }
    return self->timed_out ? 0 : 1;
}

int64_t avra_fiber_within(int64_t ms) { return within_opened(g_current, ms); }

int64_t avra_scope_end(int64_t id) { return scope_ended(g_current, id); }

void avra_fiber_within_end(int64_t id) { scope_ended(g_current, id); }

int64_t avra_task_request(void* task) {
    const Fiber* f = (const Fiber*)(uintptr_t)task_cells(task)[TASK_FIBER];
    return !f ? 0 : f->cancel_by ? f->cancel_by : f->scope_by;
}

// A FORKED CHILD KEEPS THE CALLING TASK ALONE: every other fiber leaves
// every list it is filed in — a gate lives in memory the child copied,
// and a waiter left on one would be a task of the parent's the child
// could ready. What the heap keeps is the caller's own deadline and the
// tasks the timer ends: those are the child's memory too, and whoever
// waits on one in the child is still owed its time.
void avra_fiber_forked(void) {
#if AVRA_EPOLL
    if (g_poller >= 0) close(g_poller);
#endif
    g_poller = -1;
    for (Fiber* f = g_all; f;) {
        Fiber* after = f->all_next;
        f->legacy = 0;
        f->claimed = 0;
        f->parked = 0;
        retract(f);
        if (f != g_current) waiter_out(&f->due);
        if (f != g_current && !f->virtual) fiber_unlisted(f);
        f = after;
    }
    if (g_current != &g_main) {
        g_main.legacy = g_main.claimed = g_main.parked = 0;
        retract(&g_main);
        waiter_out(&g_main.due);
    }
    g_ready_head = g_ready_tail = NULL;
    g_parked_fds = 0;
    if (g_fds) memset(g_fds, 0, g_fds_cap * sizeof(FdWaits));
    // the child is asked under its own id, and owes no ask its parent had
    g_asked = 0;
    tasks_door_named();
    // a schedule is its run's: the child's order is the queue's own
    g_seeded = 0;
}

// A task leaves every place the policy files it — its waiters and the
// gates they keep, its deadline, the ready queue — and its record goes
// back to the pool.
static void gone(Fiber* f) {
    retract(f);
    waiter_out(&f->due);
    if (f->state == FIBER_READY) {
        Fiber* prev = NULL;
        for (Fiber* q = g_ready_head; q; prev = q, q = q->next) {
            if (q != f) continue;
            if (prev) prev->next = q->next; else g_ready_head = q->next;
            if (g_ready_tail == q) g_ready_tail = prev;
            break;
        }
    }
    f->state = FIBER_DONE;
    fiber_freed(f);
}

// ── The evaluator's tasks ───────────────────────────────────────
//
// A VIRTUAL task has no stack: the evaluator runs every interpreted
// task on its own machine and asks the policy above which one is next.
// Its id is its record's address. Its slots are the evaluator's to
// keep: the host's own are never repointed for it.

static Fiber* virtual_at(int64_t t) { return (Fiber*)(uintptr_t)t; }

int64_t avra_vtask_new(void) {
    if (!g_door_open) tasks_door_opened();
    g_evaluated = 1;
    Fiber* f = fiber_new(NULL, 1);
    f->state = FIBER_PARKED;
    return (int64_t)(uintptr_t)f;
}

// A virtual task under the id its machine counts it by — the one the
// program reads, so a trace names the same task the program does.
int64_t avra_vtask_new_at(int64_t site, int64_t id) {
    int64_t t = avra_vtask_new();
    virtual_at(t)->own.id = id;
    if (TRACING) traced_fiber("spawn-at", virtual_at(t), (long long)site);
    return t;
}

// A task leaves every place the policy files it before it goes: its
// waiters and the gates they keep, its deadline, the ready queue.
void avra_vtask_free(int64_t t) { gone(virtual_at(t)); }

// A virtual task whose body answered: said, then gone.
void avra_vtask_end(int64_t t) {
    if (TRACING) traced_fiber("end", virtual_at(t), 0);
    avra_vtask_free(t);
}

void avra_vtask_sited(int64_t t, const char* site) {
    virtual_at(t)->site = site;
    if (TRACING) traced_site(virtual_at(t), site, NULL);
}

void avra_vtask_ready(int64_t t) { ready_push(virtual_at(t)); }

void avra_vtask_joins(int64_t t, int64_t on) {
    if (TRACING) traced_join(virtual_at(t), on);
}

__attribute__((noinline, cold))
static void joined_traced(Fiber* f, int64_t by) {
    traced_joined(f, by);
    ready_push(f);
}

void avra_vtask_joined(int64_t t, int64_t by) {
    if (TRACING) { joined_traced(virtual_at(t), by); return; }
    ready_push(virtual_at(t));
}

// The evaluator's reads of the clock are its host's: when one of its
// tasks parks, that count begins again.
static int64_t host_waited(int64_t parked) {
    if (parked) avra_task_local->clock_asks = 0;
    return parked;
}

void avra_vtask_sleep(int64_t t, int64_t ms) {
    Fiber* f = virtual_at(t);
    if (ms < 1) { ready_push(f); return; }
    alone(f);
    waits_until(f, deadline_after(ms), 0, 0);
    legacy_parked(f);
    host_waited(1);
}

int64_t avra_vtask_park_fd(int64_t t, int64_t fd, int64_t writable, int64_t timeout_ms) {
    Fiber* f = virtual_at(t);
    if (park_fd_filed(f, fd, writable, timeout_ms)) return host_waited(1);
    if (!f->timed_out) ready_push(f);
    return 0;
}

int64_t avra_vtask_timed_out(int64_t t) { return virtual_at(t)->timed_out; }

int64_t avra_vtask_within(int64_t t, int64_t ms) { return within_opened(virtual_at(t), ms); }

void avra_vtask_within_end(int64_t t, int64_t id) { scope_ended(virtual_at(t), id); }

int64_t avra_vtask_deadline(int64_t t) { return virtual_at(t)->deadline; }

void avra_vtask_inherits(int64_t t, int64_t from) { scope_inherited(virtual_at(t), virtual_at(from)); }

void avra_vtask_wait_fd(int64_t t, int64_t fd, int64_t writable, int64_t arm, int64_t member) { waits_fd(virtual_at(t), fd, writable, arm, member); }

void avra_vtask_wait_until(int64_t t, int64_t at_ns, int64_t arm, int64_t member) { waits_until(virtual_at(t), at_ns, arm, member); }

void avra_vtask_wait_gate(int64_t t, void* gate, int64_t arm, int64_t member) { waits_gate(virtual_at(t), gate, arm, member); }

int64_t avra_vtask_join(int64_t t, void* task) {
    Fiber* f = virtual_at(t);
    if (task_cells(task)[GATE_OPEN]) return 0;
    alone(f);
    waits_gate(f, task, 0, 0);
    legacy_parked(f);
    return host_waited(1);
}

int64_t avra_vtask_park(int64_t t) { return host_waited(park_begun(virtual_at(t))); }

int64_t avra_vtask_claim(int64_t t) { return claim_taken(virtual_at(t)); }

void avra_vtask_cancel(int64_t t, int64_t by) { fiber_cancelled(virtual_at(t), by); }

void avra_vgate_open(void* gate) { gate_opened(gate, BY_CLOSE); }

// A claim made by a virtual task: the claimant is that task, never
// whoever the host happens to be running.
int64_t avra_vgate_claim(int64_t t, void* gate) {
    if (!task_cells(gate)[GATE_HEAD]) return -1;
    return gate_claimed(gate, id_of(virtual_at(t)));
}

int64_t avra_vtask_next(void) {
    Fiber* next = next_ready();
    if (!next->virtual) avra_trap("defect: the evaluator's scheduler met a compiled task");
    next->state = FIBER_RUNNING;
    return (int64_t)(uintptr_t)next;
}

// The clock became virtual, or real again: the switch is pinned to the
// slow half, or let go.
static void clock_turned(void) { poll_counted(); }

// ── The seeded order ────────────────────────────────────────────

void avra_sched_seed(int64_t schedule) {
    g_seeded = 1;
    g_schedule = schedule;
    g_seed_state = (uint64_t)schedule;
    g_choices = 0;
    poll_counted();
}

// The first unseeded switch after it finds the poller's count spent and
// sets it again.
int64_t avra_sched_settle(void) {
    g_seeded = 0;
    return g_choices;
}

// A run inside a run keeps the outer schedule whole, to put it back.
typedef struct { int seeded; int64_t schedule; uint64_t state; int64_t choices; } Schedule;
static Schedule* g_outer_schedules = NULL;
static size_t g_runs = 0;
static size_t g_runs_cap = 0;

void avra_sched_run_begins(void) {
    if (g_runs == g_runs_cap) {
        g_runs_cap = g_runs_cap ? g_runs_cap * 2 : 8;
        g_outer_schedules = realloc(g_outer_schedules, g_runs_cap * sizeof(Schedule));
        if (!g_outer_schedules) avra_trap("the scheduler ran out of memory for a run's schedule");
    }
    g_outer_schedules[g_runs++] = (Schedule){ g_seeded, g_schedule, g_seed_state, g_choices };
    g_seeded = 0;
    avra_clock_run_begins();
}

void avra_sched_run_ends(void) {
    if (g_runs == 0) avra_trap("defect: a run's schedule ended that never began");
    Schedule outer = g_outer_schedules[--g_runs];
    g_seeded = outer.seeded;
    g_schedule = outer.schedule;
    g_seed_state = outer.state;
    g_choices = outer.choices;
    // THE SCHEDULE IS PUT BACK BEFORE THE CLOCK: ending the clock's run
    // asks the switch whether it is pinned, which reads the schedule —
    // the outer one, or the next switches run on the inner run's pin.
    avra_clock_run_ends();
}

// THE TRIPWIRE: a run evaluated inside its host shares the host's one
// scheduler — its timer heap, its poller. Its first task row asks here:
// a host timer or descriptor waiter filed beside a run that will wait
// would be fired by the run's clock, or would hide the run's deadlock.
void avra_sched_guest_waits(void) {
    if (g_runs == 0 || (g_timers_len == 0 && g_parked_fds == 0)) return;
    char words[200];
    avra_fmt(words, sizeof words, "a program waits inside a host that is itself waiting (%lld timer(s), %lld descriptor waiter(s) filed) — the two share one scheduler, so its clock would fire the host's timers", (long long)g_timers_len, (long long)g_parked_fds);
    avra_trap(words);
}

// ── A case in its own task ──────────────────────────────────────

// THE RUNNER WAITS ON TWO THINGS: its case's end, and an ALARM gate the
// scheduler claims when every task waits and nothing can wake one.
static void* g_case_alarm = NULL;
static int g_case_waited = 0;
static uint64_t g_case_first = 0;       // every task with a later id is the case's
static int64_t g_case_answer = 0;

// Every task waits and nothing can wake one, while a runner waits on a
// case: the runner is woken to say so. 0 when no case is running.
static int case_deadlocked(void) {
    return g_case_waited && avra_gate_claim(g_case_alarm) >= 0;
}

typedef long long (*Numbered)(const Fiber*);

// A task's number in its case: 0 the case's own, then in spawn order.
static long long case_id(const Fiber* f) { return (long long)((uint64_t)id_of(f) - g_case_first - 1); }

// What a waiter waits on, in words, its task numbered by `no`.
static void waiter_said(FILE* out, Numbered no, const Fiber* f, const Waiter* w) {
    if (!w->filed) return;
    if (w->kind == W_AT) { fputs(" waits on a time", out); return; }
    if (w->kind == W_DEADLINE) return;
    if (w->kind != W_GATE) { fprintf(out, " waits on descriptor %d", w->on.fd); return; }
    if (w->on.gate == f->joining) return;
    if (((AvraArray*)w->on.gate)->len != TASK_CELLS) { fprintf(out, " waits on gate %p", w->on.gate); return; }
    const Fiber* on = (const Fiber*)(uintptr_t)task_cells(w->on.gate)[TASK_FIBER];
    if (on) fprintf(out, " waits on task %lld's end", no(on));
    else fputs(" waits on a task nothing runs", out);
}

// One task: who it is — the program's own run, a case, or where its
// body was written.
static void task_said(FILE* out, Numbered no, const Fiber* f) {
    fprintf(out, "task %lld,", no(f));
    if (f == &g_main) { fputs(" the program's own run,", out); return; }
    if (f->wide) { fputs(" the case,", out); return; }
    if (f->virtual) {
        if (f->site) fprintf(out, " spawned at %s,", f->site);
        else fputs(" the evaluated program's own run,", out);
        return;
    }
    void* body = (void*)(uintptr_t)task_cells(f->task)[TASK_BODY];
    const char* site = site_of(body);
    if (site) fprintf(out, " spawned at %s,", site);
    else fprintf(out, " spawned at %p,", (void*)(uintptr_t)((AvraArray*)body)->data[0]);
}

// What a task is doing: ready, or each thing it waits on.
static void waits_said(FILE* out, Numbered no, const Fiber* f) {
    if (f->state == FIBER_READY) { fputs(" ready to run", out); return; }
    if (f->joining) {
        const Fiber* on = (const Fiber*)(uintptr_t)task_cells(f->joining)[TASK_FIBER];
        if (on) fprintf(out, " joins task %lld", no(on));
        else fputs(" joins a task nothing runs", out);
    }
    for (uint32_t i = 0; i < f->held_n; i++) waiter_said(out, no, f, &f->held[i]);
    for (const Over* o = f->more; o; o = o->next) waiter_said(out, no, f, &o->w);
}

// A TASK ABANDONED LEAVES EVERY PLACE IT IS FILED and never runs again:
// no `defer` of its runs, and what its frames held is not released.
// Whoever waited on its end is woken; its task reads as cancelled.
static void abandoned(Fiber* f) {
    for (int i = 0; i < AVRA_TASK_SLOTS; i++) {
        avra_rc_release(f->own.slot[i]);
        f->own.slot[i] = NULL;
    }
    void* task = f->task;
    Stack own = { f->base, f->guard };
    if (own.base) stack_give(own);
    int64_t* cells = task_cells(task);
    cells[TASK_FIBER] = 0;
    cells[TASK_END] = END_CANCELLED;
    gone(f);
    avra_vgate_open(task);
    avra_rc_release(task);
}

// A TIMER'S TASK LEFT FILED outlives the case as surely as a task it
// spawned: the next case would run beside it. A case begins with no
// timer filed, so every one in the heap now is the case's. Each is
// named and ended, cancelled, through the row a program would use.
// How many.
static int g_case_spoiled = 0;
static int64_t case_timers_cleared(void) {
    int64_t n = 0;
    for (size_t i = 0; i < g_timers_len; i++) n += g_timers[i].kind == T_TASK;
    if (n == 0) return 0;
    void** made = malloc((size_t)n * sizeof(void*));
    if (!made) avra_trap("the scheduler ran out of memory naming a case's timers");
    int64_t at = 0;
    int64_t now = now_ns();
    for (size_t i = 0; i < g_timers_len; i++) {
        if (g_timers[i].kind != T_TASK) continue;
        made[at++] = g_timers[i].who;
        fprintf(stderr, "avra: a task the timer ends, made by the case, outlived it — due in %lld ms\n", (long long)((g_timers[i].at - now) / 1000000));
    }
    for (int64_t i = 0; i < n; i++) avra_task_cancel(made[i]);
    free(made);
    return n;
}

// A CASE THAT ENDS HOLDING THE WORLD has leaked the hold: it is let go,
// said, and the case fails. 1 when it held one.
static int64_t case_holds_cleared(void) {
    int64_t held = g_current->own.clock_holds;
    if (held <= 0) return 0;
    g_current->own.clock_holds = 0;
    avra_clock_holds_let_go(held);
    fprintf(stderr, "avra: the case ended holding the clock %lld time(s); let go\n", (long long)held);
    return 1;
}

static int of_the_case(const Fiber* f) { return f != g_current && !f->virtual && (uint64_t)id_of(f) > g_case_first && f->state != FIBER_DONE; }

// The two settings a schedule is named by.
#define SCHED_RUNS_SETTING "AVRA_SCHED_RUNS"
#define SCHED_SEED_SETTING "AVRA_SCHED_SEED"

// Every task of the case still alive, named oldest first — as a
// deadlock's, or as outliving the case — and then abandoned. How many.
static int64_t case_cleared(int dead) {
    int64_t n = 0;
    for (const Fiber* f = g_all; f; f = f->all_next) n += of_the_case(f);
    if (n == 0) return 0;
    Fiber** alive = malloc((size_t)n * sizeof(Fiber*));
    if (!alive) avra_trap("the scheduler ran out of memory naming a case's tasks");
    // the list holds the newest first
    int64_t at = n;
    for (Fiber* f = g_all; f; f = f->all_next) if (of_the_case(f)) alive[--at] = f;
    if (dead) fputs("avra: every task is waiting, and nothing can wake one:\n", stderr);
    for (int64_t i = 0; i < n; i++) {
        fputs(dead ? "  " : "avra: ", stderr);
        task_said(stderr, case_id, alive[i]);
        if (!dead) fputs(" outlived the case —", stderr);
        waits_said(stderr, case_id, alive[i]);
        fputc('\n', stderr);
    }
    if (g_seeded) fprintf(stderr, "avra: under schedule %lld — " SCHED_SEED_SETTING "=%lld replays it\n", (long long)g_schedule, (long long)g_schedule);
    // What abandoned tasks held of the world is let go, or every later
    // case's clock would flow at wall rate — and only that share: a live
    // task's holds stand. A task that ENDED holding is not charged back
    // here; no hold can outlive the C call that took it today.
    int64_t held = 0;
    for (int64_t i = 0; i < n; i++) held += alive[i]->own.clock_holds;
    for (int64_t i = 0; i < n; i++) abandoned(alive[i]);
    free(alive);
    avra_clock_holds_let_go(held);
    if (held > 0) fprintf(stderr, "avra: they held the clock %lld time(s); let go\n", (long long)held);
    return n;
}

// The case's own task: its body, and then — before any other task can
// run — whoever it made that is still alive, named as outliving it.
static void* case_ran(void* self) {
    int64_t (*body)(void) = (int64_t (*)(void))(uintptr_t)((AvraArray*)self)->data[1];
    int64_t answer = body();
    int64_t left = case_cleared(0) + case_timers_cleared() + case_holds_cleared();
    g_case_answer = left == 0 && !g_case_spoiled ? answer : 0;
    return NULL;
}

enum { CASE_ENDED, CASE_ALARMED };

// The wide stack's pages back to the kernel: a deep case leaves none
// resident for the cases after it.
static void wide_given_back(void) {
    if (!g_wide.base) return;
#ifdef __linux__
    madvise(g_wide.base, g_wide_bytes, MADV_DONTNEED);
#else
    madvise(g_wide.base, g_wide_bytes, MADV_FREE);
#endif
}

// A CASE RUNS WHERE NOTHING ELSE WAITS: a timer or a descriptor filed
// beside it would keep the scheduler waiting on the world, and the
// case's deadlock would never be seen. And a case runs inside no case:
// a case's tasks are told apart from its runner's by when they were
// made. Either FAILS THE CASE with its words — never the process, which
// would hide every later verdict.
__attribute__((noinline, cold))
static int64_t case_refused(void) {
    if (g_case_waited) {
        fputs("avra: a case ran inside a case — a case's tasks are told apart from its runner's by when they were made\n", stderr);
        g_case_spoiled = 1;
        return 0;
    }
    fprintf(stderr, "avra: a case runs where nothing else waits — %lld timer(s) and %lld descriptor waiter(s) are filed beside it, and would hide its deadlock\n", (long long)g_timers_len, (long long)g_parked_fds);
    return 0;
}

int64_t avra_case_run(int64_t (*body)(void)) {
    if (g_case_waited || g_timers_len > 0 || g_parked_fds > 0) return case_refused();
    if (!g_case_alarm) g_case_alarm = avra_gate_new();
    g_case_first = g_fiber_seq;
    g_case_spoiled = 0;
    g_case_answer = 0;
    void* box = avra_array_sized(2);
    avra_array_push(box, (int64_t)(uintptr_t)case_ran);
    avra_array_push(box, (int64_t)(uintptr_t)body);
    void* task = avra_task_spawn(box);
    avra_rc_release(box);
    ((Fiber*)(uintptr_t)task_cells(task)[TASK_FIBER])->wide = 1;
    avra_wait_task(task, CASE_ENDED, 0);
    avra_wait_gate(g_case_alarm, CASE_ALARMED, 0);
    g_case_waited = 1;
    int64_t claim = avra_wait_park();
    g_case_waited = 0;
    if (claim >> 32 == CASE_ALARMED) case_cleared(1);
    avra_rc_release(task);
    wide_given_back();
    return g_case_answer;
}

// ── The runner's verdict ────────────────────────────────────────

// HOW MANY SCHEDULES, AND WHICH: settings read once, at the first case.
// ONE UNTIL TIME IS VIRTUAL: a suite whose tasks wait in real time
// would pay each extra schedule in wall time.
enum { SCHED_RUNS_DEFAULT = 1 };
static int64_t g_sched_runs = 0;
static int64_t g_sched_only = -1;
static int g_sched_settled = 0;
static int g_any_chose = 0;

static int64_t whole_setting(const char* name, int64_t least, int64_t fallback) {
    const char* said = getenv(name);
    if (!said || !*said) return fallback;
    char* end = NULL;
    long long n = strtoll(said, &end, 10);
    if (*end != 0 || n < least) {
        char words[160];
        avra_fmt(words, sizeof words, "%s takes a whole number%s", name, least > 0 ? " above zero" : "");
        avra_trap(words);
    }
    return n;
}

static void schedules_settled(void) {
    if (g_sched_settled) return;
    g_sched_runs = whole_setting(SCHED_RUNS_SETTING, 1, SCHED_RUNS_DEFAULT);
    g_sched_only = whole_setting(SCHED_SEED_SETTING, 0, -1);
    g_sched_settled = 1;
}

// A CASE'S BODY ANSWERS AN LLVM `i1`, which the backend returns with no
// extension: only its lowest bit is the answer. So it is called as a
// byte and that bit read — never as a C `bool`, whose caller may trust
// the bits above it.
static uint8_t (*g_case_body)(void) = NULL;
static int64_t case_body_called(void) { return g_case_body() & 1; }

// One schedule of the case: its verdict, and how many choices it made.
static int64_t case_under(int64_t schedule, int64_t* choices) {
    avra_sched_seed(schedule);
    avra_case_schedule = schedule;
    int64_t held = avra_case_run(case_body_called);
    avra_case_schedule = -1;
    *choices = avra_sched_settle();
    return held;
}

__attribute__((noinline, cold))
static int64_t case_failed_under(const char* label, int64_t schedule) {
    fprintf(stderr, "avra: %s failed under schedule %lld — " SCHED_SEED_SETTING "=%lld replays it\n", label, (long long)schedule, (long long)schedule);
    return 0;
}

int64_t avra_case_verdict(int64_t code, const char* label) {
    schedules_settled();
    g_case_body = (uint8_t (*)(void))(uintptr_t)code;
    int64_t choices = 0;
    if (g_sched_only >= 0) return case_under(g_sched_only, &choices) ? 1 : case_failed_under(label, g_sched_only);
    for (int64_t k = 0; k < g_sched_runs; k++) {
        // A CASE WITH ONE ORDER FAILS IN EVERY ORDER: no schedule replays
        // anything, so none is named.
        if (!case_under(k, &choices)) return choices == 0 && k == 0 ? 0 : case_failed_under(label, k);
        // A CASE THAT MADE NO CHOICE HAS ONE ORDER: no other schedule differs.
        if (choices == 0) return 1;
        g_any_chose = 1;
    }
    return 1;
}

void avra_case_schedules_said(void) {
    if (!g_any_chose || g_sched_only >= 0) return;
    fprintf(stderr, "avra: a case that chose an order ran up to %lld schedule%s — " SCHED_RUNS_SETTING "=8 runs more, as the nightly `orders` run does; orders past %d ready tasks are not all reachable\n", (long long)g_sched_runs, g_sched_runs == 1 ? "" : "s", PICK_WINDOW);
}

int64_t avra_sched_wide_resident(void) {
    if (!g_wide.base) return 0;
    size_t pages = g_wide_bytes / g_page;
#ifdef __APPLE__
    char* in = malloc(pages);
#else
    unsigned char* in = malloc(pages);
#endif
    if (!in || mincore(g_wide.base, g_wide_bytes, in) != 0) { free(in); return -1; }
    int64_t n = 0;
    for (size_t i = 0; i < pages; i++) n += in[i] & 1;
    free(in);
    return n;
}

int64_t avra_sched_tasks(void) {
    int64_t n = 0;
    for (const Fiber* f = g_all; f; f = f->all_next) n += f->state != FIBER_DONE;
    return n;
}

// ── What a test and a dump read ─────────────────────────────────

int64_t avra_sched_timers(void) { return (int64_t)g_timers_len; }

int64_t avra_sched_fd_waiters(void) { return g_parked_fds; }

int64_t avra_sched_polls(void) { return g_polls; }

int64_t avra_sched_pick_links(void) { return g_pick_links; }

int64_t avra_sched_world_visits(void) { return g_world_visits; }

// ── The listing: `avra tasks <pid>` ─────────────────────────────
//
// THE WALK AND WRITE IS ONE PLAIN FUNCTION, `avra_tasks_listed`: every
// live task, one line each — who, where it was spawned, what it waits
// on, and how long it has run at most. A signal is one door to it;
// a target with no signals calls it from its own.
//
// THE SIGNAL DOOR. `avra tasks` writes an ASK FILE, then sends SIGURG,
// whose default action is to be ignored — so a process that never
// spawned, or is not ours, is unharmed. The HANDLER does only what a
// handler may: it counts the ask and zeroes the switch's countdown (the
// word the fast switch already tests), so the next switch takes the
// world's path, which writes the listing; a process asleep in the
// poller is woken by the signal itself. The countdown's own decrement
// is a load and a store on some machines, so the zero can be lost to a
// switch the signal interrupted; a switch since then has moved the
// count. So a SECOND signal while the first is unanswered finds the
// count either still zero — no task has switched, and the handler
// writes that one line itself, with open, write, close and rename
// alone — or moved, and zeroes it again. The
// listing is written beside the ask, renamed into place, and the ask
// removed; with no ask file of ours there, a signal answers nothing.

// THE DOOR'S NAMES, TWICE: they are written into the copy no handler
// reads and then made the one it does by a single store, so a signal
// landing while they are rewritten — at an answer, at a fork — reads
// the whole of the old names or the whole of the new, never half.
struct DoorNames { char dir[256]; char ask[64], out[64], tmp[64], line[64]; };
static DoorNames g_doors[2];
static volatile sig_atomic_t g_door_at;
static struct sigaction g_prior_urg;

// AGES BY ID: a task's id is minted in order, so a clock reading taken
// when `g_fiber_seq` stood at n is a time every later task was spawned
// after. The world's path notes one wherever it already reads the
// clock; a task's age is at most the time since the latest reading
// taken before it was spawned. The first stands for good.
enum { AGES = 64 };
typedef struct { uint64_t seq; int64_t at; } Aged;
static Aged g_ages[AGES];
static Aged g_first_age;
static uint32_t g_ages_next = 0;

__attribute__((noinline, cold))
static void ages_noted(int64_t now) {
    if (!g_door_open) return;
    Aged* last = &g_ages[(g_ages_next + AGES - 1) % AGES];
    if (g_ages_next && last->seq == g_fiber_seq) { last->at = now; return; }
    g_ages[g_ages_next++ % AGES] = (Aged){ g_fiber_seq, now };
}

// The latest reading taken before task `id` was spawned.
static int64_t spawned_after(uint64_t id) {
    int64_t at = g_first_age.at;
    uint32_t n = g_ages_next < AGES ? g_ages_next : AGES;
    for (uint32_t i = 0; i < n; i++) {
        if (g_ages[i].seq < id && g_ages[i].at > at) at = g_ages[i].at;
    }
    return at;
}

// THE LISTING IS A TRACE: every live task as the trace's own lines, all
// stamped now — its spawn and site, a `join` or a `park` for each wait
// it has filed, and its `age` — so one reader prints a trace and a live
// process alike (`avra trace`, `avra tasks`). The program's own run is
// task 0 and needs no spawn.

// What a waiter waits on, as a trace's `park` line; nothing for a
// deadline, which is no wait of its own, or a join's gate, which the
// `join` line says.
static void waiter_listed(FILE* out, int64_t now, const Fiber* f, const Waiter* w) {
    if (!w->filed || w->kind == W_DEADLINE) return;
    if (w->kind == W_GATE && w->on.gate == f->joining) return;
    fprintf(out, "ts=%lld park id=%lld src=", (long long)now, (long long)id_of(f));
    switch (w->kind) {
        case W_FD_READ: fprintf(out, "fd:r:%d", w->on.fd); break;
        case W_FD_WRITE: fprintf(out, "fd:w:%d", w->on.fd); break;
        case W_GATE: fprintf(out, "gate:%p", w->on.gate); break;
        case W_AT: fputs("at", out); break;
        case W_DEADLINE: break;
    }
    fprintf(out, " arm=%d:%d\n", w->arm, w->member);
}

static void task_listed(FILE* out, const Fiber* f, int64_t now) {
    long long id = (long long)id_of(f);
    if (f != &g_main && id != 0) fprintf(out, "ts=%lld %s id=%lld\n", (long long)now, f->virtual ? "spawn-at" : "spawn", id);
    const char* site = f->virtual ? f->site : f != &g_main ? site_of((void*)(uintptr_t)task_cells(f->task)[TASK_BODY]) : NULL;
    if (site) fprintf(out, "ts=%lld site id=%lld %s\n", (long long)now, id, site);
    else if (!f->virtual && f != &g_main) fprintf(out, "ts=%lld site id=%lld %p\n", (long long)now, id, (void*)(uintptr_t)((AvraArray*)task_cells(f->task)[TASK_BODY])->data[0]);
    if (f->joining) {
        const Fiber* on = (const Fiber*)(uintptr_t)task_cells(f->joining)[TASK_FIBER];
        if (on) fprintf(out, "ts=%lld join id=%lld on=%lld\n", (long long)now, id, (long long)id_of(on));
        else fprintf(out, "ts=%lld join id=%lld on=unrun\n", (long long)now, id);
    }
    for (uint32_t i = 0; i < f->held_n; i++) waiter_listed(out, now, f, &f->held[i]);
    for (const Over* o = f->more; o; o = o->next) waiter_listed(out, now, f, &o->w);
    if (!f->virtual && f != &g_main) fprintf(out, "ts=%lld age id=%lld ms=%lld\n", (long long)now, id, (long long)((now - spawned_after((uint64_t)id_of(f))) / 1000000));
}

void avra_tasks_listed(FILE* out) {
    int64_t now = now_ns();
    // whose listing this is: an asker holds it to the process it asked
    fprintf(out, "ts=%lld listing id=0 pid=%lld\n", (long long)now, (long long)getpid());
    int evaluated = 0;
    for (const Fiber* f = g_all; f; f = f->all_next) evaluated |= f->virtual;
    if (!evaluated) task_listed(out, &g_main, now);
    // the list holds the newest first: walk it from its end
    const Fiber* last = g_all;
    while (last && last->all_next) last = last->all_next;
    for (const Fiber* f = last; f; f = f->all_prev) {
        if (f->state != FIBER_DONE) task_listed(out, f, now);
    }
}

// THE DOOR'S DIRECTORY IS THE USER'S OWN, never a name in a shared one:
// `AVRA_TASKS_DIR` when it is set, else the user's own directory
// (runtime/avra_door.h, the one definition `avra tasks` shares). It is
// CHOSEN AGAIN AT EVERY ANSWER, so a program started outside a login
// is answered in the directory an asker inside one finds. It is opened
// with no link followed and held to its owner and mode at every use,
// and every file in it is named relative to that open directory. Its
// file names carry this process's id: what a fork renames.
static void tasks_door_named(void) {
    if (!g_door_open) return;
    DoorNames* next = &g_doors[!g_door_at];
    const char* chosen = getenv("AVRA_TASKS_DIR");
    if (chosen && *chosen) {
        // a relative directory means two places to the asker and to us: none
        snprintf(next->dir, sizeof next->dir, "%s", chosen[0] == '/' ? chosen : "");
        size_t n = strlen(next->dir);
        while (n > 1 && next->dir[n - 1] == '/') next->dir[--n] = 0;
    } else {
        avra_user_dir(next->dir, sizeof next->dir);
    }
    long long pid = (long long)getpid();
    snprintf(next->ask, sizeof next->ask, "avra-tasks.%lld.ask", pid);
    snprintf(next->out, sizeof next->out, "avra-tasks.%lld", pid);
    snprintf(next->tmp, sizeof next->tmp, "avra-tasks.%lld.tmp", pid);
    snprintf(next->line, sizeof next->line, "avra-tasks.%lld.line", pid);
    atomic_signal_fence(memory_order_release);
    g_door_at = !g_door_at;
}

// A decimal, written as a handler may.
static size_t digits_put(char* at, long long v) {
    char rev[24];
    size_t n = 0;
    unsigned long long u = v < 0 ? (unsigned long long)-v : (unsigned long long)v;
    do { rev[n++] = (char)('0' + u % 10); u /= 10; } while (u);
    size_t k = 0;
    if (v < 0) at[k++] = '-';
    while (n) at[k++] = rev[--n];
    return k;
}

// The ask in the open door is ours: a plain file, no link, owned by
// whoever this process runs as.
static int ask_ours(int dfd, const DoorNames* names) {
    struct stat st;
    return fstatat(dfd, names->ask, &st, AT_SYMLINK_NOFOLLOW) == 0 && S_ISREG(st.st_mode) && st.st_uid == geteuid();
}

// No task has switched since the last ask: said by the handler itself,
// as a trace line under a name of its own, so it never touches a
// listing being written. An evaluated program's running task is its
// machine's, which the handler cannot name.
static void unswitched_said(int dfd, const DoorNames* names) {
    char line[128];
    static const char evaluated[] = " unswitched id=0 evaluated pid=";
    static const char head[] = " unswitched id=";
    static const char whose[] = " pid=";
    size_t k = 0;
    line[k++] = 't';
    line[k++] = 's';
    line[k++] = '=';
    k += digits_put(line + k, (long long)now_ns());
    if (g_evaluated) {
        memcpy(line + k, evaluated, sizeof evaluated - 1);
        k += sizeof evaluated - 1;
    } else {
        memcpy(line + k, head, sizeof head - 1);
        k += sizeof head - 1;
        k += digits_put(line + k, (long long)id_of(g_current));
        memcpy(line + k, whose, sizeof whose - 1);
        k += sizeof whose - 1;
    }
    k += digits_put(line + k, (long long)getpid());
    line[k++] = '\n';
    unlinkat(dfd, names->line, 0);
    int fd = openat(dfd, names->line, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (fd < 0) return;
    ssize_t w = write(fd, line, k);
    (void)w;
    close(fd);
    renameat(dfd, names->line, dfd, names->out);
}

// A handler that stood before ours is still called.
static void prior_called(int sig, siginfo_t* info, void* context) {
    if (g_prior_urg.sa_flags & SA_SIGINFO) {
        if (g_prior_urg.sa_sigaction) g_prior_urg.sa_sigaction(sig, info, context);
        return;
    }
    if (g_prior_urg.sa_handler != SIG_DFL && g_prior_urg.sa_handler != SIG_IGN) g_prior_urg.sa_handler(sig);
}

// A SECOND ask while the first is unanswered is answered here only when
// no task has switched since — the count still at the zero the first
// stored — and the scheduler is not in the world's path, which answers
// asks itself and may be sleeping or writing the listing.
static void tasks_asked(int sig, siginfo_t* info, void* context) {
    int saved = errno;
    if (g_asked++ > 0 && !g_in_world && g_until_poll == 0) {
        const DoorNames* names = &g_doors[g_door_at];
        int dfd = avra_dir_held(names->dir);
        if (dfd >= 0) {
            if (ask_ours(dfd, names)) unswitched_said(dfd, names);
            close(dfd);
        }
    }
    g_until_poll = 0;
    prior_called(sig, info, context);
    errno = saved;
}

// At a switch, after a signal: the listing, if one was asked of us.
__attribute__((noinline, cold))
static void tasks_answered(void) {
    g_asked = 0;
    tasks_door_named();
    const DoorNames* names = &g_doors[g_door_at];
    int dfd = avra_dir_held(names->dir);
    if (dfd < 0) return;
    if (ask_ours(dfd, names)) listing_written(dfd, names);
    close(dfd);
}

// The listing beside the ask, then into place — the ask taken first, so
// an asker who asks again on seeing the answer is answered again.
static void listing_written(int dfd, const DoorNames* names) {
    unlinkat(dfd, names->tmp, 0);
    int fd = openat(dfd, names->tmp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (fd < 0) return;
    FILE* out = fdopen(fd, "w");
    if (!out) { close(fd); return; }
    avra_tasks_listed(out);
    fclose(out);
    unlinkat(dfd, names->ask, 0);
    renameat(dfd, names->tmp, dfd, names->out);
}

// Once, at the first spawn or the evaluator's first task.
__attribute__((noinline))
static void tasks_door_opened(void) {
    if (g_door_open) return;
    g_door_open = 1;
    g_first_age = (Aged){ g_fiber_seq, now_ns() };
    tasks_door_named();
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_sigaction = tasks_asked;
    sa.sa_flags = SA_SIGINFO | SA_RESTART | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGURG, &sa, &g_prior_urg);
}

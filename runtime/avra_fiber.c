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
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#include "avra_box.h"
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
// `fiber_start` (see `fiber_stack_seed`).

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
    "    ret\n");
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
    "    movq %rsp, (%rdi)\n"
    "    movq %rsi, %rsp\n"
    "    popq %r15\n"
    "    popq %r14\n"
    "    popq %r13\n"
    "    popq %r12\n"
    "    popq %rbx\n"
    "    popq %rbp\n"
    "    ret\n");
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
    uintptr_t floor;        // a frame below this has left the stack; 0 for main
    const uint64_t* canary; // the word under the floor; non-zero when a neighbour was written
    AvraTaskLocal* local;   // the slots and id a program reads: main's are the core's
    void* task;             // the task this fiber answers; NULL for main
    Fiber* next;            // the run queue
    void* joining;          // the task this fiber waits to join, else NULL
    int state;
    int virtual;            // the evaluator's: filed here, switched by the evaluator
    uint8_t claimed;        // the set has been claimed
    uint8_t parked;         // switched out on an unclaimed set
    uint8_t legacy;         // parked by a sleep, a join or a descriptor park: cleared at its claim
    uint8_t heeds;          // the task's deadline may claim this set
    uint8_t expired;        // the deadline passed while a `within` stood
    uint8_t timed_out;      // whether the last legacy park ended by time
    uint8_t unwinding;      // a cancel met a cancel point
    int32_t arm, member;    // the claim
    uint32_t held_n;
    uint32_t cancel_by;     // 1 + the id of the task that asked, else 0
    int64_t deadline;       // the innermost `within`'s end, in ns; 0 when none
    int64_t due_at;         // the deadline `due` is filed under
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
    f->next = g_fiber_pool;
    g_fiber_pool = f;
}

static int64_t id_of(const Fiber* f) { return f->local->id; }

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

__attribute__((constructor))
static void trace_settle(void) {
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
    char out[256];
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

// ── Time ────────────────────────────────────────────────────────

static int64_t now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec;
}

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
    if (w->kind != W_GATE) g_parked_fds++;
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
    enum { BATCH = 256 };
#if AVRA_KQUEUE
    struct kevent evs[BATCH];
    struct timespec ts = { (time_t)(timeout_ns / 1000000000), (long)(timeout_ns % 1000000000) };
    int n = kevent(g_poller, NULL, 0, evs, BATCH, timeout_ns < 0 ? NULL : &ts);
    for (int i = 0; i < n; i++) {
        if (evs[i].filter == EVFILT_READ && (evs[i].flags & EV_EOF)) fd_closed((int)evs[i].ident);
        fd_ready((int)evs[i].ident, evs[i].filter == EVFILT_WRITE);
    }
#else
    struct epoll_event evs[BATCH];
    int ms = timeout_ns < 0 ? -1 : (int)((timeout_ns + 999999) / 1000000);
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

// THE DEADLINE IS THE TASK'S: a `within` narrows it for its scope and
// every wait inside heeds it; a nested `within` never widens it.
// Answers the outer one, which the scope's end restores.
static int64_t within_opened(Fiber* f, int64_t ms) {
    int64_t outer = f->deadline;
    int64_t at = deadline_after(ms < 0 ? 0 : ms);
    f->deadline = outer != 0 && outer < at ? outer : at;
    return outer;
}

static void within_ended(Fiber* f, int64_t outer) {
    f->deadline = outer;
    f->expired = 0;
    if (f->due.filed && f->due_at != outer) waiter_out(&f->due);
}

// IT IS ARMED AT THE FIRST WAIT UNDER IT, ONCE: that wait reads the
// clock and files the deadline's waiter, which stays until the scope
// ends — so a `within` nothing waits under does no heap work, and a
// second wait under one reads no clock. Whether it has passed.
static int deadline_passed(Fiber* f) {
    if (f->deadline == 0) return 0;
    if (f->expired) return 1;
    if (f->due.filed && f->due_at == f->deadline) return 0;
    waiter_out(&f->due);
    if (now_ns() >= f->deadline) {
        f->expired = 1;
        return 1;
    }
    f->due = (Waiter){ .fiber = f, .arm = -1, .member = 1, .kind = W_DEADLINE, .filed = 1 };
    f->due_at = f->deadline;
    timer_set(T_WAITER, &f->due, f->deadline);
    if (TRACING) traced_fiber("deadline-set", f, (long long)f->deadline);
    return 0;
}

static void deadline_fired(Fiber* f) {
    f->expired = 1;
    if (TRACING) traced_fiber("deadline-fired", f, (long long)f->deadline);
    if (f->parked && f->heeds) set_claimed(f, -1, 1, BY_DEADLINE);
}

// ── Stacks ──────────────────────────────────────────────────────

// Each stack is a RESERVATION: pages commit when touched, so a fiber
// costs what it used. A stack is bound to a task at its FIRST RUN, so a
// task spawned and not yet run holds none, and tasks that run one after
// another share the stack the last one left warm.
#define STACK_DEFAULT ((size_t)256 << 10)
// The switch's own frame, and room for the frames between a check and
// the switch it guards.
#define FLOOR_ROOM ((size_t)512)

// A stack and the page whose fault is its overflow: its own, directly
// under it, or the one at the foot of its slab.
typedef struct { char* base; char* guard; } Stack;

static size_t g_page = 0;
static size_t g_stack_bytes = 0;

// FINISHED STACKS ARE KEPT, WARM, AND NEVER UNMAPPED. Handing a stack
// back costs a syscall and taking a fresh one a page fault —
// microseconds against a spawn of about a hundred nanoseconds — so a
// stack goes to the pool with its pages. The pool's oldest members,
// past the POOL_HOT most recent, give their pages back when the
// scheduler has nothing to run (`pool_trim`), which is time nobody is
// waiting on.
#define POOL_HOT 256
static Stack* g_pool = NULL;
static size_t g_pool_len = 0;
static size_t g_pool_cap = 0;
static size_t g_pool_clean = 0;   // members below this have given their pages back

static void guard_handler_install(void);

#ifndef MADV_GUARD_INSTALL
#define MADV_GUARD_INSTALL 102
#endif

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
// it. The canary is the word under a stack's floor — the top word of
// the stack below, which nothing writes — so it costs no page. Past K a
// runaway recursion still reaches the slab's guard, since no other task
// runs meanwhile; a bounded overrun that returns before the next switch
// and never wrote that one word is not caught.
static int g_guard_regions = 0;
static int g_guards_all = 0;
static size_t g_each_left = 0;

static void guards_settle(void) {
    const char* env = getenv("AVRA_FIBER_GUARDS");
    if (env && strcmp(env, "all") == 0) { g_guards_all = 1; return; }
    if (env && *env) { g_each_left = (size_t)avra_number(env, 0); return; }
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
    if (g_stack_bytes < 4 * FLOOR_ROOM) g_stack_bytes = g_page;
    guards_settle();
    guard_handler_install();
}

static void stack_give(Stack s) {
    if (g_pool_len == g_pool_cap) {
        g_pool_cap = g_pool_cap ? g_pool_cap * 2 : 64;
        g_pool = realloc(g_pool, g_pool_cap * sizeof(Stack));
        if (!g_pool) avra_trap("the scheduler ran out of memory for its stack pool");
    }
    g_pool[g_pool_len++] = s;
}

// Whether `page` now faults when touched.
static int guard_set(char* page) {
    if (g_guard_regions) return madvise(page, g_page, MADV_GUARD_INSTALL) == 0;
    return mprotect(page, g_page, PROT_NONE) == 0;
}

__attribute__((noinline, cold, noreturn))
static void guard_refused(void) {
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

static Stack stack_take(void) {
    if (g_pool_len == 0) slab_made();
    Stack s = g_pool[--g_pool_len];
    if (g_pool_clean > g_pool_len) g_pool_clean = g_pool_len;
    return s;
}

static void pool_trim(void) {
    while (g_pool_len > POOL_HOT && g_pool_clean < g_pool_len - POOL_HOT) {
        madvise(g_pool[g_pool_clean].base, g_stack_bytes, MADV_FREE);
        g_pool_clean++;
    }
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

static void fire_due_timers(void) {
    if (g_timers_len == 0) return;
    int64_t now = now_ns();
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

static void fiber_start(void);

// A fiber's first run: a stack from the pool, and at its top a frame
// `avra_fiber_switch` will restore — zeroed callee-saved registers and
// `fiber_start` where the return goes. The top word stays untouched:
// it is the word the stack above reads as its canary.
__attribute__((noinline, cold))
static void fiber_bound(Fiber* f) {
    Stack s = stack_take();
    f->base = s.base;
    f->guard = s.guard;
    f->floor = (uintptr_t)s.base + FLOOR_ROOM;
    f->canary = s.guard == s.base - g_page ? &g_untouched : (const uint64_t*)(s.base - sizeof(uint64_t));
    uint64_t* frame = (uint64_t*)((((uintptr_t)s.base + g_stack_bytes - 16) & ~(uintptr_t)15) - FIBER_FRAME);
    memset(frame, 0, FIBER_FRAME);
    frame[FIBER_RETURN] = (uint64_t)(uintptr_t)fiber_start;
    f->sp = frame;
}

__attribute__((noinline, cold, noreturn))
static void overflowed(const Fiber* f) {
    char words[160];
    void* body = f->task ? (void*)(uintptr_t)task_cells(f->task)[TASK_BODY] : NULL;
    void* site = body ? (void*)(uintptr_t)((AvraArray*)body)->data[0] : NULL;
    avra_fmt(words, sizeof words, "a task's stack overflowed into its neighbour — caught at a switch (task %lld, spawned at %p)", (long long)id_of(f), site);
    avra_trap(words);
}

// The stack pointer, read without asking for a frame.
static inline uintptr_t sp_now(void) {
    uintptr_t sp;
#if defined(__aarch64__)
    __asm__("mov %0, sp" : "=r"(sp));
#else
    __asm__("movq %%rsp, %0" : "=r"(sp));
#endif
    return sp;
}

static void switch_to(Fiber* next) {
    Fiber* self = g_current;
    next->state = FIBER_RUNNING;
    if (next == self) return;
    if (__builtin_expect(sp_now() < self->floor || *self->canary != 0, 0)) overflowed(self);
    if (__builtin_expect(!next->sp, 0)) fiber_bound(next);
    g_current = next;
    avra_task_local = next->local;
    avra_fiber_switch(&self->sp, next->sp);
    bury_finished();
}

// THE WORLD IS ASKED EVERY FAIR_TURNS SWITCHES even while tasks are
// ready, so a crowd of yielding tasks cannot starve one waiting on a
// descriptor.
#define FAIR_TURNS 64
static int g_turns_since_poll = 0;

// The caller has already filed itself (ready, parked, waiting or
// done); run whoever is next, waiting on the world when nobody is.
// A world with nothing to wait on and nobody ready is a deadlock,
// and a deadlock is never a hang.
__attribute__((noinline))
// THE POLICY, ONE FOR BOTH ENGINES: who runs next. A compiled program
// switches to the fiber it answers; the evaluator is handed it and
// switches call stacks itself — so both interleave tasks alike.
static Fiber* next_ready(void) {
    for (;;) {
        fire_due_timers();
        if (g_parked_fds > 0 && ++g_turns_since_poll >= FAIR_TURNS) {
            g_turns_since_poll = 0;
            poller_wait(0);
        }
        Fiber* next = ready_pop();
        if (next) return next;
        if (g_timers_len == 0 && g_parked_fds == 0) avra_trap("every task is waiting — deadlock");
        pool_trim();
        int64_t wait = g_timers_len > 0 ? g_timers[0].at - now_ns() : -1;
        poller_wait(g_timers_len > 0 && wait < 0 ? 0 : wait);
    }
}

__attribute__((noinline))
static void run_next_with_world(void) {
    Fiber* next = next_ready();
    if (next->virtual) avra_trap("defect: a compiled task's scheduler met one of the evaluator's");
    switch_to(next);
}

// A COLD PATH IN A HOT LEAF COSTS EVERY SWITCH A FRAME: while no timer
// is set and no descriptor waited on, the queue alone decides, and the
// world's machinery stays out of line.
static inline void run_next(void) {
    if (__builtin_expect(g_timers_len == 0 && g_parked_fds == 0, 1)) {
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

// The set is about to be waited on: whether the task must switch out.
// A CLAIM COMES FIRST — a value handed while the set was arming is
// taken before anything else is heard — then a cancel that stands, then
// a deadline that has passed.
static int park_begun(Fiber* f) {
    f->heeds = 1;
    if (f->claimed) return 0;
    if (f->cancel_by != 0) { set_claimed(f, -1, 0, (int64_t)f->cancel_by - 1); return 0; }
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
    return claim_taken(self);
}

void* avra_gate_new(void) {
    void* gate = avra_array_sized(GATE_CELLS);
    for (int i = 0; i < GATE_CELLS; i++) avra_array_push(gate, 0);
    return gate;
}

int64_t avra_gate_claim(void* gate) {
    int64_t* cells = task_cells(gate);
    while (cells[GATE_HEAD]) {
        Waiter* w = (Waiter*)(uintptr_t)cells[GATE_HEAD];
        int32_t member = w->member;
        if (waiter_claims(w, id_of(g_current))) return member;
    }
    return -1;
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
    cells[TASK_END] = END_ANSWERED;
    gate_opened(task, id_of(self));
    if (self->due.filed) waiter_out(&self->due);
    for (int i = 0; i < AVRA_TASK_SLOTS; i++) {
        void* held = self->own.slot[i];
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
    f->deadline = g_current->deadline;          // a task inherits its spawner's `within`
    avra_rc_retain(task);                       // the running fiber's own reference
    if (TRACING) traced_fiber("spawn", f, (long long)id_of(g_current));
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

void* avra_task_join(void* task) {
    int64_t* cells = task_cells(task);
    if (!cells[GATE_OPEN]) {
        Fiber* self = g_current;
        refuse_join_ring(task, self);
        alone(self);
        self->joining = task;
        waits_gate(self, task, 0, 0);
        legacy_parked(self);
        run_next();
        self->joining = NULL;
        cells = task_cells(task);
    }
    void* answer = (void*)(uintptr_t)cells[TASK_ANSWER];
    avra_rc_retain(answer);
    return answer;
}

// An owner's scope ends: the task is joined, its answer left to its
// other holders. Joining a done task is free, so a copy's second
// settle costs nothing.
void avra_task_settle(void* task) {
    if (!task) return;
    void* answer = avra_task_join(task);
    avra_rc_release(answer);
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
    cells[TASK_AT] = 0;
    cells[TASK_END] = END_ANSWERED;
    gate_opened(task, BY_TIMER);
    avra_rc_release(task);
}

// A CANCEL IS A CLAIMANT THAT NEVER DISPLACES A CLAIM. It is recorded
// on the task, and claims the task's set only when nothing has: a task
// already claimed resumes on its arm, and hears the cancel at its next
// wait. A task parked by a sleep, a join or a descriptor park is not
// woken by it. A fiberless task simply ends.
static void fiber_cancelled(Fiber* f, int64_t by) {
    f->cancel_by = (uint32_t)(by + 1);
    if (TRACING) traced_fiber("cancel", f, (long long)by);
    if (f->parked && !f->legacy) set_claimed(f, -1, 0, by);
}

void avra_task_cancel(void* task) {
    int64_t* cells = task_cells(task);
    Fiber* f = (Fiber*)(uintptr_t)cells[TASK_FIBER];
    if (f) { fiber_cancelled(f, id_of(g_current)); return; }
    if (cells[TASK_END] == END_LIVE) task_ended(task, END_CANCELLED, id_of(g_current));
}

// ── The rows that predate the wait set ──────────────────────────

void avra_fiber_yield(void) {
    if (!g_ready_head && g_timers_len == 0 && g_parked_fds == 0) return;
    ready_push(g_current);
    run_next();
}

void avra_fiber_sleep(int64_t ms) {
    if (ms < 1) { avra_fiber_yield(); return; }
    Fiber* self = g_current;
    alone(self);
    waits_until(self, deadline_after(ms), 0, 0);
    legacy_parked(self);
    run_next();
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
    if (park_fd_filed(self, fd, writable, timeout_ms)) run_next();
    return self->timed_out ? 0 : 1;
}

int64_t avra_fiber_within(int64_t ms) { return within_opened(g_current, ms); }

void avra_fiber_within_end(int64_t outer) { within_ended(g_current, outer); }

// A FORKED CHILD KEEPS THE CALLING TASK ALONE: every other fiber leaves
// every list it is filed in — a gate lives in memory the child copied,
// and a waiter left on one would be a task of the parent's the child
// could ready.
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
        waiter_out(&f->due);
        if (f != g_current && !f->virtual) fiber_unlisted(f);
        f = after;
    }
    if (g_current != &g_main) {
        g_main.legacy = g_main.claimed = g_main.parked = 0;
        retract(&g_main);
    }
    waiter_out(&g_main.due);
    g_ready_head = g_ready_tail = NULL;
    g_timers_len = 0;
    g_parked_fds = 0;
    g_turns_since_poll = 0;
    if (g_fds) memset(g_fds, 0, g_fds_cap * sizeof(FdWaits));
}

// ── The evaluator's tasks ───────────────────────────────────────
//
// A VIRTUAL task has no stack: the evaluator runs every interpreted
// task on its own machine and asks the policy above which one is next.
// Its id is its record's address. Its slots are the evaluator's to
// keep: the host's own are never repointed for it.

static Fiber* virtual_at(int64_t t) { return (Fiber*)(uintptr_t)t; }

int64_t avra_vtask_new(void) {
    Fiber* f = fiber_new(NULL, 1);
    f->state = FIBER_PARKED;
    return (int64_t)(uintptr_t)f;
}

int64_t avra_vtask_new_at(int64_t site) {
    int64_t t = avra_vtask_new();
    if (TRACING) traced_fiber("spawn-at", virtual_at(t), (long long)site);
    return t;
}

// A task leaves every place the policy files it before it goes: its
// waiters and the gates they keep, its deadline, the ready queue.
void avra_vtask_free(int64_t t) {
    Fiber* f = virtual_at(t);
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
    fiber_freed(f);
}

void avra_vtask_ready(int64_t t) { ready_push(virtual_at(t)); }

void avra_vtask_sleep(int64_t t, int64_t ms) {
    Fiber* f = virtual_at(t);
    if (ms < 1) { ready_push(f); return; }
    alone(f);
    waits_until(f, deadline_after(ms), 0, 0);
    legacy_parked(f);
}

int64_t avra_vtask_park_fd(int64_t t, int64_t fd, int64_t writable, int64_t timeout_ms) {
    Fiber* f = virtual_at(t);
    if (park_fd_filed(f, fd, writable, timeout_ms)) return 1;
    if (!f->timed_out) ready_push(f);
    return 0;
}

int64_t avra_vtask_timed_out(int64_t t) { return virtual_at(t)->timed_out; }

int64_t avra_vtask_within(int64_t t, int64_t ms) { return within_opened(virtual_at(t), ms); }

void avra_vtask_within_end(int64_t t, int64_t outer) { within_ended(virtual_at(t), outer); }

int64_t avra_vtask_deadline(int64_t t) { return virtual_at(t)->deadline; }

void avra_vtask_wait_fd(int64_t t, int64_t fd, int64_t writable, int64_t arm, int64_t member) { waits_fd(virtual_at(t), fd, writable, arm, member); }

void avra_vtask_wait_until(int64_t t, int64_t at_ns, int64_t arm, int64_t member) { waits_until(virtual_at(t), at_ns, arm, member); }

void avra_vtask_wait_gate(int64_t t, void* gate, int64_t arm, int64_t member) { waits_gate(virtual_at(t), gate, arm, member); }

int64_t avra_vtask_park(int64_t t) { return park_begun(virtual_at(t)); }

int64_t avra_vtask_claim(int64_t t) { return claim_taken(virtual_at(t)); }

void avra_vtask_cancel(int64_t t, int64_t by) { fiber_cancelled(virtual_at(t), by); }

void avra_vgate_open(void* gate) { gate_opened(gate, BY_CLOSE); }

int64_t avra_vtask_next(void) {
    Fiber* next = next_ready();
    if (!next->virtual) avra_trap("defect: the evaluator's scheduler met a compiled task");
    next->state = FIBER_RUNNING;
    return (int64_t)(uintptr_t)next;
}

// ── What a test and a dump read ─────────────────────────────────

int64_t avra_sched_timers(void) { return (int64_t)g_timers_len; }

int64_t avra_sched_fd_waiters(void) { return g_parked_fds; }

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

#include <errno.h>
#include <signal.h>
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

// ── Fibers and tasks ────────────────────────────────────────────

enum { FIBER_RUNNING, FIBER_READY, FIBER_PARKED, FIBER_DONE };

// A spawned fiber's record sits at the top of its own stack mapping,
// so a task costs no allocation beyond its stack. `main` is static.
typedef struct Fiber Fiber;
struct Fiber {
    void* sp;            // the saved stack top while switched out
    char* map;           // the mapping, guard page first; NULL for main
    void* task;          // the task this fiber answers; NULL for main
    Fiber* next;         // the run queue, or a waiter list
    void* joining;       // the task this fiber waits to join, else NULL
    int state;
    int parked_fd;       // the descriptor a park waits on, else -1
    int parked_write;
    int timed_out;       // whether the last park ended by its deadline
    int64_t deadline;    // the innermost `within`'s end, in ns; 0 when none
    size_t timer;        // 1 + its index in the timer heap, 0 when none
    int virtual;         // the evaluator's: filed here, switched by the evaluator
};

// A TASK IS A RECORD: a slot array the core reclaims like any other,
// releasing the body and the answer it owns. The fiber and the
// waiter list are C pointers in unowned cells.
enum { TASK_FIBER, TASK_BODY, TASK_ANSWER, TASK_DONE, TASK_WAITERS, TASK_CELLS };

static int64_t* task_cells(void* task) { return ((AvraArray*)task)->data; }

static Fiber g_main = { .state = FIBER_RUNNING, .parked_fd = -1 };
static Fiber* g_current = &g_main;
static Fiber* g_ready_head = NULL;
static Fiber* g_ready_tail = NULL;
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

// THE DEADLINE IS THE TASK'S: a `within` narrows it for its scope and
// every park inside reads it; a nested `within` never widens it.
// Answers the outer one, which the scope's end restores.
static int64_t within_opened(Fiber* f, int64_t ms) {
    int64_t outer = f->deadline;
    int64_t at = deadline_after(ms < 0 ? 0 : ms);
    f->deadline = outer != 0 && outer < at ? outer : at;
    return outer;
}

// Whether the task's deadline has already passed — a park then times
// out at once, before it waits at all.
static int expired(Fiber* f) { return f->deadline != 0 && now_ns() >= f->deadline; }

// A min-heap of deadlines, one entry at most per fiber — a fiber waits
// on one thing at a time — and each fiber knows its entry, so a wake
// by any other cause takes the entry out and no timer is ever stale.
// Ties break by insertion order: two sleeps of one length wake in the
// order they were asked.
typedef struct { int64_t at; uint64_t seq; Fiber* fiber; } Timer;
static Timer* g_timers = NULL;
static size_t g_timers_len = 0;
static size_t g_timers_cap = 0;
static uint64_t g_timer_seq = 0;

static int timer_before(size_t a, size_t b) {
    const Timer* x = &g_timers[a];
    const Timer* y = &g_timers[b];
    return x->at < y->at || (x->at == y->at && x->seq < y->seq);
}

static void timer_swap(size_t a, size_t b) {
    Timer t = g_timers[a];
    g_timers[a] = g_timers[b];
    g_timers[b] = t;
    g_timers[a].fiber->timer = a + 1;
    g_timers[b].fiber->timer = b + 1;
}

static void timer_up(size_t i) {
    while (i > 0 && timer_before(i, (i - 1) / 2)) {
        timer_swap(i, (i - 1) / 2);
        i = (i - 1) / 2;
    }
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

static void timer_set(Fiber* f, int64_t at) {
    if (g_timers_len == g_timers_cap) {
        g_timers_cap = g_timers_cap ? g_timers_cap * 2 : 64;
        g_timers = realloc(g_timers, g_timers_cap * sizeof(Timer));
        if (!g_timers) avra_trap("the scheduler ran out of memory for timers");
    }
    size_t i = g_timers_len++;
    g_timers[i] = (Timer){ at, g_timer_seq++, f };
    f->timer = i + 1;
    timer_up(i);
}

// A park's timer: its own timeout (below zero: none), or the task's
// deadline, whichever comes first.
static void timer_set_within(Fiber* f, int64_t timeout_ms) {
    int64_t at = timeout_ms >= 0 ? deadline_after(timeout_ms) : 0;
    if (f->deadline != 0 && (at == 0 || f->deadline < at)) at = f->deadline;
    if (at != 0) timer_set(f, at);
}

static void timer_cancel(Fiber* f) {
    size_t i = f->timer - 1;
    f->timer = 0;
    size_t last = --g_timers_len;
    if (i == last) return;
    g_timers[i] = g_timers[last];
    g_timers[i].fiber->timer = i + 1;
    timer_up(i);
    timer_down(g_timers[i].fiber->timer - 1);
}

// ── The poller ──────────────────────────────────────────────────
//
// WAITERS ARE FILED BY DESCRIPTOR AND DIRECTION, never by fiber: two
// tasks may wait to read one socket, and a reader and a writer always
// share one. The poller watches a direction while anyone waits on it,
// ONE-SHOT; readiness wakes the first waiter and re-arms while others
// remain, so a byte left over after one reader wakes the next and no
// wakeup is lost.

// A descriptor's waiters, the directions registered with the poller,
// and the directions that MAY be ready: set by an edge, cleared when a
// read finds the socket drained or a task parks after finding nothing.
typedef struct { Fiber* readers; Fiber* writers; int armed; int ready; } FdWaits;

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
    int want = (w->readers ? ARMED_READ : 0) | (w->writers ? ARMED_WRITE : 0);
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

static Fiber** waiters_of(FdWaits* w, int writing) { return writing ? &w->writers : &w->readers; }

static void waiter_add(Fiber* f) {
    Fiber** list = waiters_of(fd_waits(f->parked_fd), f->parked_write);
    f->next = NULL;
    while (*list) list = &(*list)->next;
    *list = f;
    g_parked_fds++;
}

static void waiter_remove(Fiber* f) {
    for (Fiber** list = waiters_of(fd_waits(f->parked_fd), f->parked_write); *list; list = &(*list)->next) {
        if (*list == f) { *list = f->next; break; }
    }
    f->next = NULL;
    g_parked_fds--;
}

// A parked fiber is ready again: its deadline and its place among a
// descriptor's waiters, whichever did not wake it, are taken back.
static void unpark(Fiber* f, int timed_out) {
    if (f->timer) timer_cancel(f);
    if (f->parked_fd >= 0) {
        int fd = f->parked_fd;
        waiter_remove(f);
        f->parked_fd = -1;
        fd_arm(fd);
    }
    f->timed_out = timed_out;
    ready_push(f);
}

// A direction of `fd` is ready (or the descriptor failed): EVERY
// waiter in that direction wakes, since an edge comes once — a waiter
// left parked could wait for one that never comes. Each retries, and
// one that finds nothing parks again at no cost.
static void fd_ready(int fd, int writing) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    g_fds[fd].ready |= writing ? ARMED_WRITE : ARMED_READ;
    Fiber** list = waiters_of(&g_fds[fd], writing);
    while (*list) unpark(*list, 0);
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
// readies whoever it names.
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

// ── Stacks ──────────────────────────────────────────────────────

// Each stack is a RESERVATION: pages commit when touched, so a fiber
// costs what it used, and a guard page below it turns an overflow
// into a trap instead of a write into a neighbour. The Fiber record
// takes the top of the mapping.
#define STACK_DEFAULT ((size_t)1 << 20)
#define FIBER_HEAD ((sizeof(Fiber) + 63) & ~(size_t)63)

static size_t g_page = 0;
static size_t g_stack_bytes = 0;
static size_t g_map_bytes = 0;

// FINISHED STACKS ARE KEPT, WARM. Handing a stack back costs a
// syscall and taking a fresh one a page fault — microseconds against
// a spawn of about a hundred nanoseconds — so a stack goes to the
// pool with its pages. The pool's oldest members, past the POOL_HOT
// most recent, give their pages back when the scheduler has nothing
// to run (`pool_trim`), which is time nobody is waiting on.
#define POOL_MAX 65536
#define POOL_HOT 256
static char** g_pool = NULL;
static size_t g_pool_len = 0;
static size_t g_pool_cap = 0;
static size_t g_pool_clean = 0;   // members below this have given their pages back

static void guard_handler_install(void);

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
    g_map_bytes = g_page + g_stack_bytes;
    guard_handler_install();
}

static void stack_give(char* m);

// Fresh stacks come a SLAB at a time: one reservation carved into
// SLAB stacks, each with its own guard, all filed in the pool. One
// map call where there were SLAB.
#define SLAB 64

static void slab_made(void) {
    char* s = mmap(NULL, g_map_bytes * SLAB, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (s == MAP_FAILED) avra_trap("the scheduler could not reserve task stacks");
    for (int i = SLAB - 1; i >= 0; i--) {
        char* m = s + (size_t)i * g_map_bytes;
        if (mprotect(m, g_page, PROT_NONE) != 0) avra_trap("the scheduler could not guard a task's stack");
        stack_give(m);
    }
}

static char* stack_take(void) {
    if (g_pool_len == 0) slab_made();
    char* m = g_pool[--g_pool_len];
    if (g_pool_clean > g_pool_len) g_pool_clean = g_pool_len;
    return m;
}

static void stack_give(char* m) {
    if (g_pool_len == POOL_MAX) { munmap(m, g_map_bytes); return; }
    if (g_pool_len == g_pool_cap) {
        g_pool_cap = g_pool_cap ? g_pool_cap * 2 : 64;
        g_pool = realloc(g_pool, g_pool_cap * sizeof(char*));
        if (!g_pool) avra_trap("the scheduler ran out of memory for its stack pool");
    }
    g_pool[g_pool_len++] = m;
}

static void pool_trim(void) {
    while (g_pool_len > POOL_HOT && g_pool_clean < g_pool_len - POOL_HOT) {
        madvise(g_pool[g_pool_clean] + g_page, g_stack_bytes, MADV_FREE);
        g_pool_clean++;
    }
}

__attribute__((noinline, cold))
static void bury(void) {
    stack_give(g_finished->map);
    g_finished = NULL;
}

static inline void bury_finished(void) {
    if (__builtin_expect(g_finished != NULL, 0) && g_finished != g_current) bury();
}

// ── Choosing who runs ───────────────────────────────────────────

static void fire_due_timers(void) {
    if (g_timers_len == 0) return;
    int64_t now = now_ns();
    while (g_timers_len > 0 && g_timers[0].at <= now) unpark(g_timers[0].fiber, 1);
}

static void switch_to(Fiber* next) {
    Fiber* self = g_current;
    next->state = FIBER_RUNNING;
    if (next == self) return;
    g_current = next;
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
    return f->map && a >= (uintptr_t)f->map && a < (uintptr_t)f->map + g_page;
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

// ── A task's life ───────────────────────────────────────────────

// A task's body answers ONE box — its value in a one-cell list, made
// by the compiler's task lift — so one call serves every answer.
typedef void* (*TaskCode)(void*);

static void fiber_start(void);

// A fiber on a fresh or pooled mapping: its record at the top, and
// under it a frame `avra_fiber_switch` will restore — zeroed
// callee-saved registers and `fiber_start` where the return goes.
static Fiber* fiber_made(void* task) {
    char* map = stack_take();
    Fiber* f = (Fiber*)(map + g_map_bytes - FIBER_HEAD);
    *f = (Fiber){ .map = map, .task = task, .parked_fd = -1 };
    uint64_t* frame = (uint64_t*)((((uintptr_t)f) & ~(uintptr_t)15) - FIBER_FRAME);
    memset(frame, 0, FIBER_FRAME);
    frame[FIBER_RETURN] = (uint64_t)(uintptr_t)fiber_start;
    f->sp = frame;
    return f;
}

// Where every new fiber begins: run the body, keep its answer, wake
// whoever joined, and hand the thread on for good.
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
    cells[TASK_DONE] = 1;
    cells[TASK_FIBER] = 0;
    for (Fiber* w = (Fiber*)(uintptr_t)cells[TASK_WAITERS]; w;) {
        Fiber* after = w->next;
        ready_push(w);
        w = after;
    }
    cells[TASK_WAITERS] = 0;
    self->state = FIBER_DONE;
    g_finished = self;
    avra_rc_release(task);
    run_next();
    __builtin_unreachable();
}

void* avra_task_spawn(void* body) {
    stacks_settle();
    void* task = avra_array_sized(TASK_CELLS);
    Fiber* f = fiber_made(task);
    f->deadline = g_current->deadline;          // a task inherits its spawner's `within`
    avra_array_push(task, (int64_t)(uintptr_t)f);
    avra_array_push_owned(task, body);
    avra_array_push_owned(task, NULL);
    avra_array_push(task, 0);
    avra_array_push(task, 0);
    avra_rc_retain(task);                       // the running fiber's own reference
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

void* avra_task_join(void* task) {
    int64_t* cells = task_cells(task);
    if (!cells[TASK_DONE]) {
        Fiber* self = g_current;
        refuse_join_ring(task, self);
        self->state = FIBER_PARKED;
        self->joining = task;
        self->next = (Fiber*)(uintptr_t)cells[TASK_WAITERS];
        cells[TASK_WAITERS] = (int64_t)(uintptr_t)self;
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
        if (task_cells(t)[TASK_DONE]) {
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
    return task_cells(task)[TASK_DONE];
}

void avra_fiber_yield(void) {
    if (!g_ready_head && g_timers_len == 0 && g_parked_fds == 0) return;
    ready_push(g_current);
    run_next();
}

void avra_fiber_sleep(int64_t ms) {
    if (ms < 1) { avra_fiber_yield(); return; }
    Fiber* self = g_current;
    self->state = FIBER_PARKED;
    timer_set(self, deadline_after(ms));
    run_next();
}

void avra_fiber_fd_closing(int64_t fd) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    FdWaits* w = &g_fds[fd];
    while (w->readers) unpark(w->readers, 0);
    while (w->writers) unpark(w->writers, 0);
    w->armed = 0;
    w->ready = 0;
}

void avra_fiber_fd_interrupt(int64_t fd) {
    if (fd < 0 || (size_t)fd >= g_fds_cap) return;
    FdWaits* w = &g_fds[fd];
    while (w->readers) unpark(w->readers, 1);
}

int64_t avra_fiber_park_fd(int64_t fd, int64_t writable, int64_t timeout_ms) {
    if (fd < 0 || fd > INT32_MAX) return 1;
    Fiber* self = g_current;
    if (expired(self)) return 0;
    poller_open();
    self->parked_fd = (int)fd;
    self->parked_write = writable != 0;
    waiter_add(self);
    parked_unready((int)fd, writable);
    // A descriptor the poller refuses is ready now: the read or write
    // the caller retries reports its own error.
    if (!fd_arm((int)fd)) {
        waiter_remove(self);
        self->parked_fd = -1;
        return 1;
    }
    self->state = FIBER_PARKED;
    timer_set_within(self, timeout_ms);
    run_next();
    return self->timed_out ? 0 : 1;
}

int64_t avra_fiber_within(int64_t ms) { return within_opened(g_current, ms); }

void avra_fiber_within_end(int64_t outer) { g_current->deadline = outer; }

void avra_fiber_forked(void) {
#if AVRA_EPOLL
    if (g_poller >= 0) close(g_poller);
#endif
    g_poller = -1;
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
// Its id is its record's address.

static Fiber* virtual_at(int64_t t) { return (Fiber*)(uintptr_t)t; }

int64_t avra_vtask_new(void) {
    Fiber* f = calloc(1, sizeof(Fiber));
    if (!f) avra_trap("the scheduler ran out of memory for a task");
    f->parked_fd = -1;
    f->virtual = 1;
    f->state = FIBER_PARKED;
    return (int64_t)(uintptr_t)f;
}

// A task leaves every place the policy files it before it goes: its
// deadline, a descriptor's waiters, the ready queue.
void avra_vtask_free(int64_t t) {
    Fiber* f = virtual_at(t);
    if (f->timer) timer_cancel(f);
    if (f->parked_fd >= 0) {
        int fd = f->parked_fd;
        waiter_remove(f);
        fd_arm(fd);
    }
    if (f->state == FIBER_READY) {
        Fiber* prev = NULL;
        for (Fiber* q = g_ready_head; q; prev = q, q = q->next) {
            if (q != f) continue;
            if (prev) prev->next = q->next; else g_ready_head = q->next;
            if (g_ready_tail == q) g_ready_tail = prev;
            break;
        }
    }
    free(f);
}

void avra_vtask_ready(int64_t t) { ready_push(virtual_at(t)); }

void avra_vtask_sleep(int64_t t, int64_t ms) {
    Fiber* f = virtual_at(t);
    if (ms < 1) { ready_push(f); return; }
    f->state = FIBER_PARKED;
    timer_set(f, deadline_after(ms));
}

int64_t avra_vtask_park_fd(int64_t t, int64_t fd, int64_t writable, int64_t timeout_ms) {
    Fiber* f = virtual_at(t);
    if (fd < 0 || fd > INT32_MAX) { f->timed_out = 0; ready_push(f); return 0; }
    if (expired(f)) { f->timed_out = 1; return 0; }
    poller_open();
    f->parked_fd = (int)fd;
    f->parked_write = writable != 0;
    waiter_add(f);
    parked_unready((int)fd, writable);
    if (!fd_arm((int)fd)) {
        waiter_remove(f);
        f->parked_fd = -1;
        f->timed_out = 0;
        ready_push(f);
        return 0;
    }
    f->state = FIBER_PARKED;
    timer_set_within(f, timeout_ms);
    return 1;
}

int64_t avra_vtask_timed_out(int64_t t) { return virtual_at(t)->timed_out; }

int64_t avra_vtask_within(int64_t t, int64_t ms) { return within_opened(virtual_at(t), ms); }

void avra_vtask_within_end(int64_t t, int64_t outer) { virtual_at(t)->deadline = outer; }

int64_t avra_vtask_deadline(int64_t t) { return virtual_at(t)->deadline; }

int64_t avra_vtask_next(void) {
    Fiber* next = next_ready();
    if (!next->virtual) avra_trap("defect: the evaluator's scheduler met a compiled task");
    next->state = FIBER_RUNNING;
    return (int64_t)(uintptr_t)next;
}

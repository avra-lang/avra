// The scheduler, attacked. Each group is one attack class; a trap or a
// hang is checked in a child with a deadline, since either would end
// or stall the process that met it.
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "fiber_adversarial_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// A descriptor closed through the scheduler's door, as every closer must:
// its waiters woken and its registration forgotten, so the number's next
// tenant inherits none.
static void closed(int fd) { avra_fiber_fd_closing(fd); close(fd); }

typedef void* (*Code)(void*);

static void* closure(Code code, int n, const int64_t* caps) {
    void* box = avra_array_sized(1 + n);
    avra_array_push(box, (int64_t)(uintptr_t)code);
    for (int i = 0; i < n; i++) avra_array_push(box, caps[i]);
    return box;
}
static int64_t cap(void* box, int i) { return ((AvraArray*)box)->data[1 + i]; }
static void* answer(int64_t v) { void* r = avra_array_sized(1); avra_array_push(r, v); return r; }
static int64_t answered(void* r) { return r ? ((AvraArray*)r)->data[0] : -1; }

static void* spawn2(Code code, int64_t a, int64_t b) {
    int64_t caps[2] = { a, b };
    void* body = closure(code, 2, caps);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static void* spawn1(Code code, int64_t a) { return spawn2(code, a, 0); }

static int64_t join_value(void* task) {
    void* r = avra_task_join(task);
    int64_t v = answered(r);
    avra_rc_release(r);
    avra_rc_release(task);
    return v;
}

static double seconds(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

// A child run with a deadline: its status, its stderr, and whether it
// had to be killed. The deadline catches a HANG, never a slow machine:
// a loaded box makes a deep recursion slow, and that is not a finding.
#define HANG_S 60
typedef struct { int status; int hung; char words[512]; } Outcome;

static Outcome in_child(void (*body)(void), int deadline_s) {
    Outcome o = {0};
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm((unsigned)deadline_s);
        body();
        _exit(0);
    }
    close(out[1]);
    // TO END OF FILE: a trap writes its words in more than one write,
    // and a pipe closed after the first kills the child with SIGPIPE
    size_t got = 0;
    for (ssize_t n; got < sizeof o.words - 1 && (n = read(out[0], o.words + got, sizeof o.words - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    waitpid(pid, &o.status, 0);
    o.hung = WIFSIGNALED(o.status) && WTERMSIG(o.status) == SIGALRM;
    return o;
}

static int exited(Outcome o, int code) { return WIFEXITED(o.status) && WEXITSTATUS(o.status) == code; }
static int killed_by(Outcome o, int sig) { return WIFSIGNALED(o.status) && WTERMSIG(o.status) == sig; }

// ── bodies ──────────────────────────────────────────────────────

static void* nothing(void* self) { (void)self; return NULL; }
static void* echo(void* self) { return answer(cap(self, 0)); }
static void* yielder(void* self) { avra_fiber_yield(); return answer(cap(self, 0)); }

// a join that keeps the caller's handle
static int64_t join_value_keep(void* task) {
    void* r = avra_task_join(task);
    int64_t v = answered(r);
    avra_rc_release(r);
    return v;
}

static void* g_shared = NULL;
static void* joins_shared(void* self) { return answer(join_value_keep(g_shared) + cap(self, 0)); }

// fib by tasks: every call above the grain forks
static void* fib(void* self) {
    int64_t n = cap(self, 0);
    if (n < 2) return answer(n);
    void* a = spawn1(fib, n - 1);
    void* b = spawn1(fib, n - 2);
    return answer(join_value(a) + join_value(b));
}

static int g_pipe[2];
static void* read_one(void* self) {
    (void)self;
    char c = 0;
    for (;;) {
        ssize_t n = read(g_pipe[0], &c, 1);
        if (n == 1) return answer(c);
        avra_fiber_park_fd(g_pipe[0], 0, -1);
    }
}

static int g_sock[2];
static void* sock_reader(void* self) {
    (void)self;
    char c = 0;
    for (;;) {
        if (read(g_sock[0], &c, 1) == 1) return answer(c);
        avra_fiber_park_fd(g_sock[0], 0, -1);
    }
}
static void* sock_writer(void* self) {
    // fill the socket until it would block, then wait to write
    char buf[4096];
    memset(buf, 'w', sizeof buf);
    int64_t total = 0;
    for (;;) {
        ssize_t n = write(g_sock[0], buf, sizeof buf);
        if (n > 0) { total += n; continue; }
        if (total > 0 && cap(self, 0)) break;
        avra_fiber_park_fd(g_sock[0], 1, 50);
        if (cap(self, 0)) break;
    }
    return answer(total > 0);
}

static volatile int g_flag = 0;
static void* busy_until_flag(void* self) { (void)self; while (!g_flag) avra_fiber_yield(); return answer(1); }
static void* flag_on_read(void* self) { (void)self; answer(0); void* r = read_one(NULL); g_flag = 1; return r; }
static void* flag_on_sleep(void* self) { avra_fiber_sleep(cap(self, 0)); g_flag = 1; return answer(1); }
static void* write_later(void* self) {
    for (int i = 0; i < cap(self, 0); i++) avra_fiber_yield();
    ssize_t w = write(g_pipe[1], "z", 1);
    return answer(w);
}

static double now_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e3 + (double)t.tv_nsec / 1e6;
}

// ORDER, NEVER A MEASURED TIME. Every sleeper aims at ONE base plus its
// own offset, so its intended deadline is the offset alone; it sleeps
// what remains, and notes the offset when it wakes. The scheduler's own
// clock read lands a hair after the sleeper's, and a busy machine may
// stretch that hair: the offsets are spaced far wider than any stretch,
// so the order checked is the one the scheduler promises.
// A sleeper that first runs after its own deadline was never timed by
// the scheduler — it only yields — so it is noted LATE and left out.
static double g_base_ms = 0;
static int64_t g_order[5000];
static int g_order_len = 0;
static int g_late = 0;
static void* sleep_then_note(void* self) {
    int64_t offset = cap(self, 0);
    double left = g_base_ms + (double)offset - now_ms();
    if (left < 1) { g_late++; return NULL; }
    avra_fiber_sleep((int64_t)left);
    g_order[g_order_len++] = offset;
    return NULL;
}

static void* park_timeout(void* self) { return answer(avra_fiber_park_fd(cap(self, 0), cap(self, 1) & 1, cap(self, 1) >> 1)); }
static void* sleeps(void* self) { avra_fiber_sleep(cap(self, 0)); return answer(1); }

static void* g_cycle[3];
static void* joins_next(void* self) { return avra_task_join(g_cycle[(cap(self, 0) + 1) % 3]); }

static int64_t deep(int64_t n) {
    volatile char pad[512];
    pad[0] = (char)n;
    return n == 0 ? pad[0] : deep(n - 1) + pad[0];
}
static void* overflow(void* self) { return answer(deep(cap(self, 0))); }
// A frame the compiler cannot shrink: the buffer escapes to a call.
__attribute__((noinline)) static void scribble(char* p, size_t n) { memset(p, 1, n); }
__attribute__((noinline)) static int64_t wide(void) { char big[256 * 1024]; scribble(big, sizeof big); return big[7]; }
static void* wide_frame(void* self) { (void)self; return answer(wide()); }
static void* null_write(void* self) { (void)self; *(volatile int*)(uintptr_t)cap(self, 0) = 1; return NULL; }
static void* traps(void* self) { (void)self; avra_trap("a task's own trap"); }

// ── children ────────────────────────────────────────────────────

static void cycle_with_io_pending(void) {
    // a reader waits on a pipe nobody writes, so the world is not empty,
    // while three tasks join in a ring
    if (pipe(g_pipe) != 0) _exit(9);
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
    void* r = spawn1(read_one, 0);
    (void)r;
    for (int i = 0; i < 3; i++) g_cycle[i] = spawn1(joins_next, i);
    avra_task_join(g_cycle[0]);
}
static void wide_overflow(void) { setenv("AVRA_FIBER_STACK", "65536", 1); avra_task_join(spawn1(wide_frame, 0)); }
static void deep_overflow(void) { setenv("AVRA_FIBER_STACK", "65536", 1); avra_task_join(spawn1(overflow, 1000000)); }
static void overflow_in_case(void) { avra_case_begin("fibers / a named case"); deep_overflow(); }
static void null_in_task(void) { avra_task_join(spawn1(null_write, 8)); }
static void null_in_main_after_spawn(void) { avra_task_join(spawn1(echo, 1)); *(volatile int*)(uintptr_t)8 = 1; }
static void trap_in_task(void) { avra_task_join(spawn1(traps, 0)); }
static void huge_stack(void) { setenv("AVRA_FIBER_STACK", "99999999999999999", 1); avra_task_join(spawn1(echo, 1)); }
static void park_bad_fd(void) {
    int64_t r = join_value(spawn2(park_timeout, 987654, (100 << 1) | 0));
    fprintf(stderr, "answered %lld\n", (long long)r);
}
static int64_t main_deep(int64_t n) {
    volatile char pad[4096];
    pad[0] = (char)n;
    return n == 0 ? 0 : main_deep(n - 1) + pad[0];
}
static void main_recurses(void) {
    avra_task_join(spawn1(echo, 1));    // the guard handler is installed
    main_deep(INT64_MAX);
}

static int g_pipes[256][2];
static void* read_pipe_k(void* self) {
    int fd = g_pipes[cap(self, 0)][0];
    char c;
    for (;;) {
        if (read(fd, &c, 1) == 1) return answer(c);
        // a timeout DRAINS before it declares: a byte that arrived as
        // the deadline passed is still this reader's
        if (!avra_fiber_park_fd(fd, 0, cap(self, 1))) return answer(read(fd, &c, 1) == 1 ? c : -2);
    }
}

static void said(const char* what, Outcome o) {
    if (getenv("FIBER_TEST_VERBOSE")) fprintf(stderr, "%s: status %d hung %d words [%s]\n", what, o.status, o.hung, o.words);
}

int main(void) {
    // Children first: each forks from a process whose scheduler has not
    // yet settled, so a child's own AVRA_FIBER_STACK is the one read.
    // ── traps and faults, each in a child ───────────────────────
    Outcome o;
    o = in_child(cycle_with_io_pending, HANG_S);
    said("cycle_with_io_pending", o);
    CHECK(!o.hung, "a join cycle beside pending io does not hang");
    CHECK(exited(o, 2) && strstr(o.words, "tasks join each other in a ring — deadlock"), "a join cycle beside pending io is a deadlock, said as a ring");

    o = in_child(wide_overflow, HANG_S);
    said("wide_overflow", o);
    CHECK(exited(o, 2) && strstr(o.words, "a task's stack overflowed"), "one frame wider than the stack is an overflow");
    o = in_child(deep_overflow, HANG_S);
    said("deep_overflow", o);
    CHECK(exited(o, 2) && strstr(o.words, "a task's stack overflowed"), "deep recursion is an overflow");

    o = in_child(overflow_in_case, HANG_S);
    said("overflow_in_case", o);
    CHECK(exited(o, 2) && strstr(o.words, "avra: while running fibers / a named case\navra: a task's stack overflowed"), "an overflow names the case in flight, as every trap does");
    o = in_child(null_in_task, HANG_S);
    said("null_in_task", o);
    CHECK(killed_by(o, SIGSEGV) || killed_by(o, SIGBUS), "a null write in a task is still a crash, not an overflow");
    CHECK(!strstr(o.words, "overflow"), "a null write is never called an overflow");
    o = in_child(null_in_main_after_spawn, HANG_S);
    said("null_in_main_after_spawn", o);
    CHECK(killed_by(o, SIGSEGV) || killed_by(o, SIGBUS), "a null write in main is still a crash");
    o = in_child(main_recurses, HANG_S);
    said("main_recurses", o);
    CHECK((killed_by(o, SIGSEGV) || killed_by(o, SIGBUS)) && !strstr(o.words, "task"), "main's own overflow is main's crash, never a task's");

    o = in_child(trap_in_task, HANG_S);
    said("trap_in_task", o);
    CHECK(exited(o, 2) && strstr(o.words, "a task's own trap"), "a trap inside a task is the program's trap");

    o = in_child(huge_stack, HANG_S);
    said("huge_stack", o);
    CHECK(exited(o, 2) && strstr(o.words, "stack"), "an impossible stack size is refused in words");

    o = in_child(park_bad_fd, HANG_S);
    said("park_bad_fd", o);
    CHECK(!o.hung && exited(o, 0) && strstr(o.words, "answered 1"), "a park on a closed descriptor answers ready, so the read reports its own error");


    int64_t live = avra_mem_live();

    // ── degenerate shapes ───────────────────────────────────────
    {
        void* t = spawn1(nothing, 0);
        void* r = avra_task_join(t);
        CHECK(r == NULL, "a body answering nothing joins to nothing");
        CHECK(avra_task_join(t) == NULL, "a second join of it answers nothing again");
        avra_rc_release(t);

        void* e = spawn1(echo, 7);
        CHECK(join_value_keep(e) == 7 && join_value_keep(e) == 7, "a task joins twice to one answer");
        CHECK(avra_task_done(e) == 1, "a joined task is done");
        avra_rc_release(e);

        avra_fiber_yield();              // alone: returns at once
        avra_fiber_sleep(0);
        avra_fiber_sleep(-5);
        CHECK(1, "a lone yield and a non-positive sleep return");

        // a handle dropped before the task ran: the task still runs, and
        // everything it held is reclaimed
        void* dropped = spawn1(yielder, 3);
        avra_rc_release(dropped);
        avra_fiber_sleep(1);

        // many joiners of one task
        g_shared = spawn1(yielder, 100);
        void* js[5];
        for (int i = 0; i < 5; i++) js[i] = spawn1(joins_shared, i);
        int64_t sum = 0;
        for (int i = 0; i < 5; i++) sum += join_value(js[i]);
        CHECK(sum == 5 * 100 + 10, "five joiners of one task all hear its answer");
        avra_rc_release(g_shared);

        // tasks spawning tasks
        CHECK(join_value(spawn1(fib, 15)) == 610, "fib(15) by a tree of 1973 tasks");
        CHECK(avra_mem_live() == live, "every task, body and answer above is reclaimed, the dropped one included");
    }

    // ── the timer heap under load ───────────────────────────────
    {
        enum { SLEEPERS = 5000 };
        static void* ts[SLEEPERS];
        g_order_len = 0;
        g_late = 0;
        uint32_t lcg = 12345;
        for (int i = 0; i < SLEEPERS; i++) {
            lcg = lcg * 1103515245u + 12345u;
            ts[i] = spawn1(sleep_then_note, 20 * (1 + (lcg >> 16) % 8));
        }
        // no task has run yet: the base stands well past their first turns
        g_base_ms = now_ms() + 500;
        for (int i = 0; i < SLEEPERS; i++) join_value(ts[i]);
        int sorted = g_order_len + g_late == SLEEPERS;
        for (int i = 1; i < g_order_len; i++) sorted &= g_order[i - 1] <= g_order[i];
        CHECK(g_order_len > 0, "the timer heap check timed at least one sleeper");
        CHECK(sorted, "every sleeper the scheduler timed wakes in the order of its deadline");
    }

    // ── the world: descriptors ──────────────────────────────────
    {
        if (pipe(g_pipe) != 0) return 1;
        fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
        void* a = spawn1(read_one, 0);
        void* b = spawn1(read_one, 0);
        avra_fiber_sleep(2);
        CHECK(write(g_pipe[1], "ab", 2) == 2, "two bytes into the pipe");
        int64_t x = join_value(a), y = join_value(b);
        CHECK(x + y == 'a' + 'b', "two tasks reading one pipe both get a byte");
        closed(g_pipe[0]); closed(g_pipe[1]);

        // one reader and one writer on the SAME descriptor
        if (socketpair(AF_UNIX, SOCK_STREAM, 0, g_sock) != 0) return 1;
        fcntl(g_sock[0], F_SETFL, O_NONBLOCK);
        fcntl(g_sock[1], F_SETFL, O_NONBLOCK);
        void* rd = spawn1(sock_reader, 0);
        void* wr = spawn1(sock_writer, 1);
        avra_fiber_sleep(2);
        CHECK(write(g_sock[1], "q", 1) == 1, "the far end writes");
        CHECK(join_value(rd) == 'q', "a reader shares a descriptor with a parked writer");
        CHECK(join_value(wr) == 1, "the writer on that descriptor finishes");
        closed(g_sock[0]); closed(g_sock[1]);

        // a timeout of zero on a silent pipe
        if (pipe(g_pipe) != 0) return 1;
        fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
        CHECK(join_value(spawn2(park_timeout, g_pipe[0], (0 << 1) | 0)) == 0, "a zero timeout on a silent pipe answers 0");
        // a pipe already readable: the park answers ready
        CHECK(write(g_pipe[1], "r", 1) == 1, "a byte waits");
        CHECK(join_value(spawn2(park_timeout, g_pipe[0], (1000 << 1) | 0)) == 1, "a park on a readable pipe answers 1 at once");
        closed(g_pipe[0]); closed(g_pipe[1]);

        // 256 pipes, alternate ones written, every park with a deadline
        for (int i = 0; i < 256; i++) { if (pipe(g_pipes[i]) != 0) return 1; fcntl(g_pipes[i][0], F_SETFL, O_NONBLOCK); }
        void* ts[256];
        for (int i = 0; i < 256; i++) ts[i] = spawn2(read_pipe_k, i, 20 + (i % 7));
        avra_fiber_sleep(1);
        for (int i = 0; i < 256; i += 2) { ssize_t w = write(g_pipes[i][1], "k", 1); (void)w; }
        int right = 0;
        for (int i = 0; i < 256; i++) right += join_value(ts[i]) == (i % 2 == 0 ? 'k' : -2);
        CHECK(right == 256, "256 parks: the written ones read, the silent ones time out");
        for (int i = 0; i < 256; i++) { closed(g_pipes[i][0]); closed(g_pipes[i][1]); }
    }

    // ── fairness: the world is heard while tasks stay busy ──────
    {
        if (pipe(g_pipe) != 0) return 1;
        fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
        g_flag = 0;
        void* reader = spawn1(flag_on_read, 0);
        void* busy1 = spawn1(busy_until_flag, 0);
        void* busy2 = spawn1(busy_until_flag, 0);
        void* writer = spawn1(write_later, 10);
        CHECK(join_value(busy1) == 1 && join_value(busy2) == 1, "busy yielders do not starve a parked reader");
        join_value(reader); join_value(writer);
        closed(g_pipe[0]); closed(g_pipe[1]);

        g_flag = 0;
        void* sl = spawn1(flag_on_sleep, 5);
        void* b3 = spawn1(busy_until_flag, 0);
        CHECK(join_value(b3) == 1 && join_value(sl) == 1, "busy yielders do not starve a sleeper");
    }

    // ── time at the edges ───────────────────────────────────────
    {
        double t0 = seconds();
        void* never = spawn1(sleeps, INT64_MAX / 2);
        void* soon = spawn1(sleeps, 5);
        CHECK(join_value(soon) == 1, "a short sleep beside an endless one wakes");
        // generous: the claim is 2^62 ms against 5 ms, never a speed
        CHECK(seconds() - t0 < 10.0, "an endless sleep is not read as already due");
        CHECK(!avra_task_done(never), "the endless sleeper still sleeps");
        avra_rc_release(never);
    }

    // ── reclaim ─────────────────────────────────────────────────
    // (the endless sleeper holds its own task until the process ends)

    // ── pool: past the hot set, trimmed at idle, reused ─────────
    {
        enum { N = 1000 };
        static void* ts[N];
        for (int round = 0; round < 2; round++) {
            for (int i = 0; i < N; i++) ts[i] = spawn1(yielder, i);
            int64_t s = 0;
            for (int i = 0; i < N; i++) s += join_value(ts[i]);
            CHECK(s == (int64_t)N * (N - 1) / 2, "a thousand tasks, twice, through a trimmed pool");
            avra_fiber_sleep(2);        // idle: the pool trims
        }
    }
    (void)live;

    printf("fibers (adversarial): %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

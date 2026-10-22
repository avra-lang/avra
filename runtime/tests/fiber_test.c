// The scheduler, driven through its rows as compiled code drives them:
// a task's body is a closure box `[code, captures…]` called with the
// box at seat 0. Every check counts; a trap is checked in a child,
// since a trap ends the process that meets it.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "fiber_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// A descriptor closed through the scheduler's door, as every closer must:
// its waiters woken and its registration forgotten, so the number's next
// tenant inherits none.
static void closed(int fd) { avra_fiber_fd_closing(fd); close(fd); }

typedef void* (*Code)(void*);

// A closure box over `code` with integer captures.
static void* closure(Code code, int n, const int64_t* caps) {
    void* box = avra_array_sized(1 + n);
    avra_array_push(box, (int64_t)(uintptr_t)code);
    for (int i = 0; i < n; i++) avra_array_push(box, caps[i]);
    return box;
}

static int64_t cap(void* box, int i) { return ((AvraArray*)box)->data[1 + i]; }

// An answer: a one-cell record holding `v`.
static void* answer(int64_t v) {
    void* r = avra_array_sized(1);
    avra_array_push(r, v);
    return r;
}

static int64_t answered(void* r) { return ((AvraArray*)r)->data[0]; }

static void* spawn1(Code code, int64_t a) {
    void* body = closure(code, 1, &a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}

static int64_t join_value(void* task) {
    void* r = avra_task_join(task);
    int64_t v = answered(r);
    avra_rc_release(r);
    avra_rc_release(task);
    return v;
}

// ── the log a test reads its interleaving from ──────────────────

static int64_t g_log[64];
static int g_log_len = 0;
static void note(int64_t v) { if (g_log_len < 64) g_log[g_log_len++] = v; }
static void log_reset(void) { g_log_len = 0; }

// ── bodies ──────────────────────────────────────────────────────

static void* square(void* self) { int64_t n = cap(self, 0); return answer(n * n); }

static void* ping(void* self) {
    for (int i = 0; i < 3; i++) { note(cap(self, 0)); avra_fiber_yield(); }
    return answer(0);
}

static void* yield_once(void* self) { avra_fiber_yield(); return answer(cap(self, 0)); }

// A sleeper aims at one shared base plus its offset — order, never a
// measured time (fiber_adversarial_test.c says why).
static double g_base_ms = 0;
static double now_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e3 + (double)t.tv_nsec / 1e6;
}
static void* sleeper(void* self) {
    double left = g_base_ms + (double)cap(self, 0) - now_ms();
    avra_fiber_sleep(left > 0 ? (int64_t)left : 0);
    note(cap(self, 0));
    return answer(0);
}

static int g_pipe[2];
static void* reader(void* self) {
    (void)self;
    char c = 0;
    while (read(g_pipe[0], &c, 1) != 1) avra_fiber_park_fd(g_pipe[0], 0, -1);
    return answer(c);
}

static void* timed_park(void* self) { return answer(avra_fiber_park_fd(g_pipe[0], 0, cap(self, 0))); }

static void* g_a = NULL;
static void* g_b = NULL;
static void* joins_b(void* self) { (void)self; return avra_task_join(g_b); }
static void* joins_a(void* self) { (void)self; return avra_task_join(g_a); }

static void* self_join(void* self) { (void)self; return avra_task_join(g_a); }

static int64_t deep(int64_t n) {
    volatile char pad[512];
    pad[0] = (char)n;
    return n == 0 ? pad[0] : deep(n - 1) + pad[0];
}
static void* overflow(void* self) { return answer(deep(cap(self, 0))); }

static void* counter(void* self) { for (int64_t i = 0; i < cap(self, 0); i++) avra_fiber_yield(); return answer(0); }

// ── a trap, in a child: its words and its status ────────────────

static char g_trap_words[4096];
static void trapped(const char* what, void (*body)(void), const char* words) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        body();
        _exit(0);
    }
    close(out[1]);
    char buf[sizeof g_trap_words] = {0};
    // TO END OF FILE: a trap writes its words in more than one write,
    // and a pipe closed after the first kills the child with SIGPIPE
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    char label[128];
    snprintf(label, sizeof label, "%s exits 2", what);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2, label);
    snprintf(label, sizeof label, "%s says \"%s\"", what, words);
    CHECK(strstr(buf, words) != NULL, label);
    snprintf(g_trap_words, sizeof g_trap_words, "%s", buf);
}

static void deadlock(void) {
    g_a = spawn1(joins_b, 0);
    g_b = spawn1(joins_a, 0);
    avra_task_join(g_a);
}

static void joins_itself(void) {
    g_a = spawn1(self_join, 0);
    avra_task_join(g_a);
}

// A task parked on a gate nobody will claim, and the spawner waiting on
// its end: nobody is ready, no timer or descriptor is filed — the bare
// trap. The report must name both tasks.
static void* waits_on_a_gate(void* self) {
    (void)self;
    avra_wait_gate(g_a, 0, 0);
    avra_wait_park();
    return NULL;
}
static void stuck(void) {
    g_a = avra_gate_new();
    void* t = spawn1(waits_on_a_gate, 0);
    avra_task_join(t);
}

static void overflows(void) {
    setenv("AVRA_FIBER_STACK", "65536", 1);
    avra_task_join(spawn1(overflow, 100000));
}

static double seconds(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

int main(void) {
    // the traps first, before this process has a scheduler of its own
    trapped("two tasks joined on each other", deadlock, "tasks join each other in a ring — deadlock");
    trapped("a task joined on itself", joins_itself, "a task joined itself — deadlock");
    trapped("a recursion past the stack", overflows, "a task's stack overflowed");

    // the bare deadlock names every task and what it waits on
    trapped("a task parked on a gate nobody claims", stuck, "every task is waiting — deadlock");
    CHECK(strstr(g_trap_words, "every task is waiting, and nothing can wake one") != NULL, "a deadlock is headed");
    CHECK(strstr(g_trap_words, "task 0, the program's own run") != NULL, "the program's own run is named");
    CHECK(strstr(g_trap_words, "task 1,") != NULL && strstr(g_trap_words, "spawned at 0x") != NULL, "the task and its spawn site are named");
    CHECK(strstr(g_trap_words, " joins task 1") != NULL && strstr(g_trap_words, " waits on gate 0x") != NULL, "and what each waits on");

    int64_t live = avra_mem_live();

    // answers arrive, in any join order
    void* t[3];
    for (int i = 0; i < 3; i++) t[i] = spawn1(square, i + 2);
    CHECK(!avra_task_done(t[2]), "a spawned task has not run before the spawner waits");
    CHECK(join_value(t[2]) == 16, "the last task's answer");
    CHECK(join_value(t[0]) == 4, "the first task's answer");
    CHECK(join_value(t[1]) == 9, "the middle task's answer");

    // two tasks yielding interleave
    log_reset();
    void* a = spawn1(ping, 1);
    void* b = spawn1(ping, 2);
    join_value(a);
    join_value(b);
    int64_t want[] = {1, 2, 1, 2, 1, 2};
    CHECK(g_log_len == 6 && memcmp(g_log, want, sizeof want) == 0, "yielding tasks alternate");

    // sleeps wake by deadline, not by spawn order
    log_reset();
    g_base_ms = now_ms() + 20;
    void* s[3] = { spawn1(sleeper, 60), spawn1(sleeper, 20), spawn1(sleeper, 40) };
    for (int i = 0; i < 3; i++) join_value(s[i]);
    int64_t woke[] = {20, 40, 60};
    CHECK(g_log_len == 3 && memcmp(g_log, woke, sizeof woke) == 0, "sleepers wake in deadline order");

    // a parked reader wakes on a write
    if (pipe(g_pipe) != 0) { perror("pipe"); return 1; }
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);   // a park waits for readiness; a read must never block
    void* r = spawn1(reader, 0);
    avra_fiber_sleep(5);
    CHECK(!avra_task_done(r), "a reader parked on an empty pipe waits");
    CHECK(write(g_pipe[1], "x", 1) == 1, "the pipe takes a byte");
    CHECK(join_value(r) == 'x', "the parked reader reads what was written");

    // a park with a deadline answers 0 when the time runs out
    double t0 = seconds();
    CHECK(join_value(spawn1(timed_park, 20)) == 0, "a park on a silent pipe times out");
    CHECK(seconds() - t0 >= 0.019, "the timeout waited its time");
    closed(g_pipe[0]);
    closed(g_pipe[1]);

    // ten thousand tasks
    enum { MANY = 10000 };
    static void* many[MANY];
    double m0 = seconds();
    for (int i = 0; i < MANY; i++) many[i] = spawn1(yield_once, i);
    int64_t sum = 0;
    for (int i = 0; i < MANY; i++) sum += join_value(many[i]);
    double m1 = seconds();
    CHECK(sum == (int64_t)MANY * (MANY - 1) / 2, "ten thousand tasks all answer");

    // nothing a task held outlives it
    CHECK(avra_mem_live() == live, "every task, body and answer is reclaimed");

    // the cost of a switch: two tasks yielding to each other, the best
    // of five runs, since a shared machine only ever adds time
    enum { TURNS = 1000000 };
    double best = 1e9;
    for (int run = 0; run < 5; run++) {
        void* p = spawn1(counter, TURNS);
        void* q = spawn1(counter, TURNS);
        double c0 = seconds();
        join_value(p);
        join_value(q);
        double c1 = seconds();
        if (c1 - c0 < best) best = c1 - c0;
    }
    double warm = 1e9;
    for (int run = 0; run < 5; run++) {
        double w0 = seconds();
        for (int i = 0; i < MANY; i++) join_value(spawn1(square, i));
        double w1 = seconds();
        if (w1 - w0 < warm) warm = w1 - w0;
    }

    printf("fibers: %d checks, %d failed\n", g_checks, g_fails);
    printf("fibers: spawn+run+join %.0f ns a task, %d alive at once\n", (m1 - m0) / MANY * 1e9, MANY);
    printf("fibers: spawn+run+join %.0f ns a task, one at a time\n", warm / MANY * 1e9);
    printf("fibers: a switch %.1f ns (%d)\n", best / (2.0 * TURNS) * 1e9, 2 * TURNS);
    return g_fails ? 1 : 0;
}

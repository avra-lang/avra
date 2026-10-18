// The cores, attacked. A group is real processes, so every attack runs
// its supervisor in a child of this test with a deadline: a crash it
// must report, and a hang it must not have, end that child and never
// this one.
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_cores.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "cores_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

#define DEADLINE_S 30

// A supervisor run in a child: its exit status, its stdout and its
// stderr, and whether the deadline had to end it. The supervisor leads
// a process group of its own, so the deadline ends its cores too — an
// alarm is not inherited across a fork, and a hung core would hold the
// pipes open forever.
typedef struct { int status; int hung; char out[512]; char err[512]; } Outcome;

static double seconds(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

// Both pipes read to their ends, or 0 when the deadline passed first.
static int drained(int out, int err, Outcome* o) {
    struct pollfd fds[2] = { { .fd = out, .events = POLLIN }, { .fd = err, .events = POLLIN } };
    char* into[2] = { o->out, o->err };
    size_t got[2] = { 0, 0 };
    double end = seconds() + DEADLINE_S;
    for (int open = 2; open > 0;) {
        int left_ms = (int)((end - seconds()) * 1000);
        if (left_ms <= 0 || poll(fds, 2, left_ms) <= 0) return 0;
        for (int i = 0; i < 2; i++) {
            if (fds[i].fd < 0 || !fds[i].revents) continue;
            char scratch[256];
            size_t room = sizeof o->out - 1 - got[i];
            ssize_t n = read(fds[i].fd, room ? into[i] + got[i] : scratch, room ? room : sizeof scratch);
            if (n > 0 && room) got[i] += (size_t)n;
            if (n <= 0) { fds[i].fd = -1; open--; }
        }
    }
    return 1;
}

static Outcome supervised(void (*body)(void)) {
    Outcome o = {0};
    int out[2], err[2];
    if (pipe(out) != 0 || pipe(err) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        setpgid(0, 0);
        dup2(out[1], 1);
        dup2(err[1], 2);
        close(out[0]);
        close(err[0]);
        body();
        exit(0);
    }
    setpgid(pid, pid);
    close(out[1]);
    close(err[1]);
    o.hung = !drained(out[0], err[0], &o);
    if (o.hung) kill(-pid, SIGKILL);
    close(out[0]);
    close(err[0]);
    waitpid(pid, &o.status, 0);
    return o;
}

static int exited(Outcome o, int code) { return WIFEXITED(o.status) && WEXITSTATUS(o.status) == code; }

// Parks the calling task until core `core` of `g` has ended.
static void awaited(int64_t g, int64_t core) {
    while (avra_cores_heard(g, core) != 0) avra_fiber_park_fd(avra_cores_end_fd(g, core), 0, -1);
}

static void awaited_all(int64_t g, int64_t n) {
    for (int64_t i = 0; i < n; i++) awaited(g, i);
}

// Parks a core until its group stops.
static void until_stopped(int64_t g) {
    while (!avra_cores_stopped(g)) avra_fiber_park_fd(avra_cores_stop_fd(g), 0, -1);
}

// ── bodies: each a supervisor, its cores forked inside ──────────

// Three cores leave with 1, 2 and 3 accepted: the answer is their sum.
static void sums(void) {
    int64_t g = avra_cores_group(3);
    int64_t core = avra_cores_fork(g, -1);
    if (core < 3) avra_cores_leave(g, core, core + 1, 0);
    awaited_all(g, 3);
    printf("%lld", (long long)avra_cores_result(g));
}

// Core 1 of 2 traps; core 0 waits to be told to stop.
static void one_traps(void) {
    int64_t g = avra_cores_group(2);
    int64_t core = avra_cores_fork(g, -1);
    if (core == 1) avra_trap("a handler's defect");
    if (core == 0) { until_stopped(g); avra_cores_leave(g, core, 0, 0); }
    awaited(g, 1);
    avra_cores_stop(g);
    awaited(g, 0);
    avra_cores_result(g);
}

// Core 0 of 2 is killed.
static void one_killed(void) {
    int64_t g = avra_cores_group(2);
    int64_t core = avra_cores_fork(g, -1);
    if (core == 0) { raise(SIGKILL); }
    if (core == 1) { until_stopped(g); avra_cores_leave(g, core, 0, 0); }
    awaited(g, 0);
    avra_cores_stop(g);
    awaited(g, 1);
    avra_cores_result(g);
}

// A core's own exit, not a leave, is a crash too.
static void one_exits(void) {
    int64_t g = avra_cores_group(1);
    if (avra_cores_fork(g, -1) == 0) exit(0 + 7);
    awaited(g, 0);
    avra_cores_result(g);
}

// A core that leaves with an errno: the answer is that errno, negated.
static void one_fails(void) {
    int64_t g = avra_cores_group(2);
    int64_t core = avra_cores_fork(g, -1);
    if (core == 0) avra_cores_leave(g, core, 5, EBADF);
    if (core == 1) { until_stopped(g); avra_cores_leave(g, core, 4, 0); }
    awaited(g, 0);
    avra_cores_stop(g);
    awaited(g, 1);
    printf("%lld", (long long)avra_cores_result(g));
}

// Stop reaches every core, and each counts its connections for the sum.
static void stop_reaches_all(void) {
    int64_t g = avra_cores_group(4);
    int64_t core = avra_cores_fork(g, -1);
    if (core < 4) {
        avra_cores_count(g, core, 10);
        until_stopped(g);
        avra_cores_leave(g, core, 1, 0);
    }
    // the counts land before any core parks: wait for all four
    for (int i = 0; i < 1000 && avra_cores_live(g) != 40; i++) usleep(1000);
    printf("%lld ", (long long)avra_cores_live(g));
    avra_cores_stop(g);
    awaited_all(g, 4);
    printf("%lld", (long long)avra_cores_result(g));
}

// The supervisor dies without a word: every core reads the stop, and
// reports it on a pipe the test holds.
static int g_report[2];
static void supervisor_dies(void) {
    int64_t g = avra_cores_group(2);
    int64_t core = avra_cores_fork(g, g_report[1]);
    if (core < 2) {
        until_stopped(g);
        char c = 'a' + (char)core;
        (void)!write(g_report[1], &c, 1);
        avra_cores_leave(g, core, 0, 0);
    }
    _exit(0);
}

// A descriptor open before the fork is closed in every core but the one
// it serves; a core reports what it found through the served one.
static void descriptors_stay(void) {
    int stray[2];
    if (pipe(stray) != 0) exit(3);
    int report[2];
    if (pipe(report) != 0) exit(3);
    int64_t g = avra_cores_group(1);
    int64_t core = avra_cores_fork(g, report[1]);
    if (core == 0) {
        char c = fcntl(stray[0], F_GETFD) < 0 && fcntl(stray[1], F_GETFD) < 0 && fcntl(report[0], F_GETFD) < 0 ? 'y' : 'n';
        (void)!write(report[1], &c, 1);
        avra_cores_leave(g, core, 0, 0);
    }
    close(report[1]);
    char c = '?';
    (void)!read(report[0], &c, 1);
    awaited(g, 0);
    avra_cores_result(g);
    printf("%c", c);
}

// Text written before the fork and not yet flushed reaches the output
// once — never once per core.
static void flushed_once(void) {
    printf("once");
    int64_t g = avra_cores_group(3);
    int64_t core = avra_cores_fork(g, -1);
    if (core < 3) avra_cores_leave(g, core, 0, 0);
    awaited_all(g, 3);
    avra_cores_result(g);
}

// A task spawned before the fork never runs in a core: one already
// parked on its timer, one only ready. Only the supervisor's copies
// write their marks.
static int g_marks[2];
static void* marks(void* self) {
    avra_fiber_sleep(20);
    char c = (char)((AvraArray*)self)->data[1];
    (void)!write(g_marks[1], &c, 1);
    return NULL;
}
static void* marking(char c) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)marks);
    avra_array_push(body, c);
    void* t = avra_task_spawn(body);
    avra_rc_release(body);
    return t;
}
static void tasks_stay(void) {
    void* parked = marking('p');
    avra_fiber_yield();
    void* ready = marking('r');
    int64_t g = avra_cores_group(2);
    int64_t core = avra_cores_fork(g, g_marks[1]);
    if (core < 2) {
        avra_fiber_sleep(80);
        avra_cores_leave(g, core, 0, 0);
    }
    awaited_all(g, 2);
    avra_cores_result(g);
    avra_task_settle(parked);
    avra_task_settle(ready);
    avra_rc_release(parked);
    avra_rc_release(ready);
}

// One pipe read to its end.
static void read_all(int fd, char* into, size_t cap) {
    size_t got = 0;
    for (ssize_t n; got < cap - 1 && (n = read(fd, into + got, cap - 1 - got)) > 0;) got += (size_t)n;
    into[got] = 0;
}

// A TIMER TASK MADE BEFORE A FORK IS THE CHILD'S TOO: the heap keeps it,
// so cancelling one is no crash and waiting on one still ends.
static void* waits_on(void* self) {
    void* task = (void*)(uintptr_t)((AvraArray*)self)->data[1];
    avra_wait_task(task, 2, 0);
    void* r = avra_array_sized(1);
    avra_array_push(r, avra_wait_park() >> 32);
    return r;
}

static int64_t forked_with_timer_tasks(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    int64_t at = (int64_t)now.tv_sec * 1000000000 + now.tv_nsec;
    void* far = avra_task_at(at + 60000000000);
    void* farther = avra_task_at(at + 70000000000);
    void* near = avra_task_at(at + 20000000);
    pid_t pid = fork();
    if (pid == 0) {
        alarm(30);
        avra_fiber_forked();
        if (avra_sched_timers() != 3) _exit(11);
        avra_task_cancel(farther);
        if (avra_sched_timers() != 2) _exit(12);
        avra_task_cancel(far);
        if (avra_sched_timers() != 1) _exit(13);
        void* body = avra_array_sized(2);
        avra_array_push(body, (int64_t)(uintptr_t)waits_on);
        avra_array_push(body, (int64_t)(uintptr_t)near);
        void* r = avra_task_join(avra_task_spawn(body));
        _exit(((AvraArray*)r)->data[0] == 2 && avra_sched_timers() == 0 ? 0 : 14);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    avra_task_cancel(far);
    avra_task_cancel(farther);
    avra_task_cancel(near);
    avra_rc_release(far);
    avra_rc_release(farther);
    avra_rc_release(near);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -WTERMSIG(status);
}

int main(void) {
    // ── sizes ───────────────────────────────────────────────────
    CHECK(avra_cores_group(0) == -EINVAL, "no cores is refused");
    CHECK(avra_cores_group(-3) == -EINVAL, "a negative count is refused");
    CHECK(avra_cores_group(5000) == -EINVAL, "a count past the ceiling is refused");
    CHECK(avra_cores_online() >= 1, "this process may run on a core");

    // ── answers ─────────────────────────────────────────────────
    {
        Outcome o = supervised(sums);
        CHECK(exited(o, 0) && !strcmp(o.out, "6"), "the cores' accepted counts sum");
    }
    {
        Outcome o = supervised(one_fails);
        char want[16];
        snprintf(want, sizeof want, "%d", -EBADF);
        CHECK(exited(o, 0) && !strcmp(o.out, want), "a core's errno is the group's answer");
    }
    {
        Outcome o = supervised(stop_reaches_all);
        CHECK(exited(o, 0) && !strcmp(o.out, "40 4"), "stop reaches every core, and the live counts sum");
    }

    // ── crashes trap the supervisor, naming the core ────────────
    {
        Outcome o = supervised(one_traps);
        CHECK(!o.hung && exited(o, 2), "a core that traps traps the supervisor");
        CHECK(strstr(o.err, "a handler's defect") != NULL, "the core's own words reach stderr");
        CHECK(strstr(o.err, "core 1 of 2 ended with status 2") != NULL, "the supervisor names the core that trapped");
    }
    {
        Outcome o = supervised(one_killed);
        CHECK(!o.hung && exited(o, 2), "a core that is killed traps the supervisor");
        CHECK(strstr(o.err, "core 0 of 2 was killed by signal 9") != NULL, "the supervisor names the core and the signal");
    }
    {
        Outcome o = supervised(one_exits);
        CHECK(!o.hung && exited(o, 2) && strstr(o.err, "core 0 of 1 ended with status 7") != NULL, "a core's own exit is a crash");
    }

    // ── a dead supervisor stops its cores ───────────────────────
    {
        if (pipe(g_report) != 0) return 1;
        double t0 = seconds();
        Outcome o = supervised(supervisor_dies);
        close(g_report[1]);
        char got[4] = {0};
        read_all(g_report[0], got, sizeof got);
        close(g_report[0]);
        CHECK(exited(o, 0), "the supervisor ends");
        CHECK(strlen(got) == 2 && strchr(got, 'a') && strchr(got, 'b'), "every core reads its supervisor's death as a stop");
        CHECK(seconds() - t0 < DEADLINE_S, "no core outlives its supervisor");
    }

    // ── nothing crosses into a core ─────────────────────────────
    {
        Outcome o = supervised(descriptors_stay);
        CHECK(exited(o, 0) && !strcmp(o.out, "y"), "a core holds no descriptor it was not given");
    }
    {
        Outcome o = supervised(flushed_once);
        CHECK(exited(o, 0) && !strcmp(o.out, "once"), "unflushed output reaches the page once");
    }
    {
        if (pipe(g_marks) != 0) return 1;
        Outcome o = supervised(tasks_stay);
        close(g_marks[1]);
        char got[8] = {0};
        read_all(g_marks[0], got, sizeof got);
        close(g_marks[0]);
        CHECK(exited(o, 0) && strlen(got) == 2 && strchr(got, 'p') && strchr(got, 'r'), "a task spawned before the fork runs in the supervisor alone");
    }

    CHECK(forked_with_timer_tasks() == 0, "a forked child cancels and waits on timer tasks made before the fork");

    printf("cores: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

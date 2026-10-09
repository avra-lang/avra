// The evaluator's tasks: the SAME policy as a compiled program's,
// driven the way the evaluator drives it — so one scenario, run as
// fibers and as virtual tasks, interleaves alike.
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "vtask_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// A descriptor closed through the scheduler's door, as every closer must:
// its waiters woken and its registration forgotten, so the number's next
// tenant inherits none.
static void closed(int fd) { avra_fiber_fd_closing(fd); close(fd); }

static char g_log[128];
static int g_log_len = 0;
static void note(char c) { if (g_log_len < 127) g_log[g_log_len++] = c; g_log[g_log_len] = 0; }

// ── one scenario: three tasks, each noting its name, yielding, noting
// again; the second sleeps between. Written twice, once per engine. ──

// as fibers
typedef void* (*Code)(void*);
static void* closure(Code code, int64_t cap) {
    void* box = avra_array_sized(2);
    avra_array_push(box, (int64_t)(uintptr_t)code);
    avra_array_push(box, cap);
    return box;
}
static void* fiber_body(void* self) {
    char name = (char)((AvraArray*)self)->data[1];
    note(name);
    avra_fiber_yield();
    if (name == 'b') avra_fiber_sleep(5);
    note(name);
    return NULL;
}
static void as_fibers(void) {
    void* t[3];
    for (int i = 0; i < 3; i++) { void* b = closure(fiber_body, 'a' + i); t[i] = avra_task_spawn(b); avra_rc_release(b); }
    for (int i = 0; i < 3; i++) { void* r = avra_task_join(t[i]); avra_rc_release(r); avra_rc_release(t[i]); }
}

// as the evaluator: each task a step machine, resumed by the policy
typedef struct { int64_t id; char name; int step; } VTask;
static void as_virtual(void) {
    VTask ts[3];
    for (int i = 0; i < 3; i++) { ts[i] = (VTask){ avra_vtask_new(), (char)('a' + i), 0 }; avra_vtask_ready(ts[i].id); }
    int done = 0;
    while (done < 3) {
        int64_t id = avra_vtask_next();
        VTask* v = NULL;
        for (int i = 0; i < 3; i++) if (ts[i].id == id) v = &ts[i];
        if (v->step == 0) { note(v->name); v->step = 1; avra_vtask_ready(id); continue; }       // note, yield
        if (v->step == 1 && v->name == 'b') { v->step = 2; avra_vtask_sleep(id, 5); continue; }  // sleep
        note(v->name);
        v->step = 3;
        done++;
    }
    for (int i = 0; i < 3; i++) avra_vtask_free(ts[i].id);
}

// A join by a virtual task parks as a compiled join does: readied where
// the task ends, deaf to its own deadline.
static int64_t in_ms(int64_t ms) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec + ms * 1000000;
}
static void joins(void) {
    int64_t j = avra_vtask_new();
    void* timed = avra_task_at(in_ms(40));
    int64_t before = in_ms(0);
    int64_t outer = avra_vtask_within(j, 5);
    CHECK(avra_vtask_join(j, timed) == 1, "a virtual task joins a task the timer ends, and parks");
    CHECK(avra_vtask_next() == j, "the policy names it when the task's time comes");
    CHECK(in_ms(0) - before >= 35 * 1000000, "at that time: not at its own deadline");
    avra_vtask_within_end(j, outer);
    CHECK(avra_vtask_join(j, timed) == 0, "a join of a task that has ended parks nothing");
    CHECK(avra_sched_timers() == 0, "and nothing stays filed");
    avra_rc_release(timed);
    avra_vtask_free(j);
}

// A CANCEL CUTS A VIRTUAL JOIN: the task is readied at once with its
// own unwind bit set, as a compiled join's is.
static void cancelled_join(void) {
    int64_t j = avra_vtask_new();
    void* timed = avra_task_at(in_ms(60000));
    CHECK(avra_vtask_join(j, timed) == 1, "a virtual task parks on a timer's task");
    avra_vtask_cancel(j, 0);
    CHECK(avra_vtask_next() == j, "a cancel cuts the join and the policy names it at once");
    CHECK(avra_vtask_unwinding(j) == 1, "with its own unwind bit set");
    avra_task_cancel(timed);
    avra_rc_release(timed);
    avra_vtask_free(j);
}

static void deadlocked(void) {
    int64_t t = avra_vtask_new();   // filed nowhere: nothing ready, nothing to wait on
    (void)t;
    avra_vtask_next();
}

// Inside a run: two virtual tasks, each parked on its own gate, name
// what each waits on. The policy answers the evaluator no task.
static void run_deadlocked(void) {
    avra_sched_run_begins();
    int64_t a = avra_vtask_new(), b = avra_vtask_new();
    void* ga = avra_gate_new();
    void* gb = avra_gate_new();
    avra_vtask_wait_gate(a, ga, 0, 0);
    avra_vtask_park(a);
    avra_vtask_wait_gate(b, gb, 0, 0);
    avra_vtask_park(b);
    if (avra_vtask_next() != 0) _exit(3);
    avra_sched_run_ends();
}

int main(void) {
    joins();
    cancelled_join();
    // one scenario, both engines, one interleaving
    g_log_len = 0; as_fibers();
    char fibers[128]; strcpy(fibers, g_log);
    g_log_len = 0; as_virtual();
    CHECK(strcmp(fibers, "abcacb") == 0, "the fibers interleave as the policy says");
    CHECK(strcmp(fibers, g_log) == 0, "virtual tasks interleave exactly as fibers do");

    // a virtual park on a pipe wakes on a write, and a silent one times out
    int p[2];
    if (pipe(p) != 0) return 1;
    fcntl(p[0], F_SETFL, O_NONBLOCK);
    int64_t r = avra_vtask_new(), s = avra_vtask_new();
    CHECK(avra_vtask_park_fd(r, p[0], 0, -1) == 1, "a virtual task parks on a pipe");
    avra_vtask_sleep(s, 2);
    CHECK(avra_vtask_next() == s, "the sleeper wakes while the reader still waits");
    CHECK(write(p[1], "x", 1) == 1, "a byte written");
    CHECK(avra_vtask_next() == r && !avra_vtask_timed_out(r), "the reader wakes on the byte");
    CHECK(avra_vtask_park_fd(r, p[0], 0, 5) == 1, "parked again, with a deadline, on a pipe with a byte");
    CHECK(avra_vtask_next() == r, "a readable pipe answers at once");
    char c; CHECK(read(p[0], &c, 1) == 1, "the byte is there");
    CHECK(avra_vtask_park_fd(r, p[0], 0, 5) == 1, "parked on a silent pipe with a deadline");
    CHECK(avra_vtask_next() == r && avra_vtask_timed_out(r), "the deadline wakes it, timed out");
    CHECK(avra_vtask_park_fd(r, 987654, 0, -1) == 0, "a descriptor nobody holds is ready at once");
    CHECK(avra_vtask_next() == r, "and the task runs, for its read to say why");
    avra_vtask_free(r); avra_vtask_free(s);
    closed(p[0]); closed(p[1]);

    // a task freed while filed anywhere leaves nothing behind
    if (pipe(p) != 0) return 1;
    fcntl(p[0], F_SETFL, O_NONBLOCK);
    int64_t parked = avra_vtask_new(), readied = avra_vtask_new(), timed = avra_vtask_new(), last = avra_vtask_new();
    avra_vtask_park_fd(parked, p[0], 0, 1000);
    avra_vtask_ready(readied);
    avra_vtask_sleep(timed, 1000);
    avra_vtask_free(parked); avra_vtask_free(readied); avra_vtask_free(timed);
    CHECK(write(p[1], "y", 1) == 1, "a byte for a reader that is gone");
    avra_vtask_sleep(last, 3);
    CHECK(avra_vtask_next() == last, "the freed tasks are nowhere — the next is the one still filed");
    avra_vtask_free(last);
    closed(p[0]); closed(p[1]);

    // nothing ready and nothing to wait on: the policy's deadlock, in a child
    int out[2];
    if (pipe(out) != 0) return 1;
    pid_t pid = fork();
    if (pid == 0) { dup2(out[1], 2); close(out[0]); alarm(60); deadlocked(); _exit(0); }
    close(out[1]);
    char buf[1024] = {0};
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2 && strstr(buf, "every task is waiting — deadlock"), "a virtual deadlock is the policy's trap");
    CHECK(strstr(buf, "the evaluated program's own run") != NULL, "and names the task");

    // inside a run, the same deadlock is the evaluator's to file, named
    if (pipe(out) != 0) return 1;
    pid = fork();
    if (pid == 0) { dup2(out[1], 2); close(out[0]); alarm(60); run_deadlocked(); _exit(0); }
    close(out[1]);
    memset(buf, 0, sizeof buf);
    got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "inside a run, a virtual deadlock answers the evaluator: no task");
    CHECK(strstr(buf, "every task is waiting, and nothing can wake one") != NULL, "and the run's report is headed");
    CHECK(strstr(buf, "the evaluated program's own run") != NULL && strstr(buf, "waits on gate 0x") != NULL, "each task is named with the gate it waits on");
    CHECK(buf[0] != 0 && strstr(strstr(buf, "waits on gate 0x") + 1, "waits on gate 0x") != NULL, "both waiting tasks are named");

    printf("vtasks: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

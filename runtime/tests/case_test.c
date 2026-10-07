// A CASE IN ITS OWN TASK: a test's body runs as a task the runner waits
// on, so a deadlock fails that one case — each task named, with what it
// waits on — and a task that outlives its case fails it too; either
// way the tasks are abandoned and the next case runs in a clean world.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "case_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

typedef void* (*Code)(void*);
static void* spawn1(Code code, void* a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, (int64_t)(uintptr_t)a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static void* cap(void* box) { return (void*)(uintptr_t)((AvraArray*)box)->data[1]; }

// ── the cases ───────────────────────────────────────────────────

static int64_t passes(void) { return 1; }
static int64_t fails(void) { return 0; }

static void* adds(void* self) { (void)self; avra_fiber_yield(); return NULL; }
static int64_t spawns_and_joins(void) {
    void* t = spawn1(adds, NULL);
    avra_rc_release(avra_task_join(t));
    avra_rc_release(t);
    avra_fiber_sleep(3);
    return 1;
}

// Deeper than any task's own stack: a case's body has the main thread's.
static int64_t deep(int64_t n) {
    volatile char frame[1024];
    frame[0] = (char)n;
    return n == 0 ? frame[0] : deep(n - 1) + (frame[0] & 0);
}
static int64_t recurses(void) { return deep(2000) == 0; }

static void* waits_on(void* self) {
    avra_wait_gate(cap(self), 0, 0);
    avra_wait_park();
    return NULL;
}
static int64_t each_waits_on_the_other(void) {
    void* a = spawn1(waits_on, avra_gate_new());
    void* b = spawn1(waits_on, avra_gate_new());
    (void)b;
    avra_rc_release(avra_task_join(a));
    return 1;
}
static int64_t waits_alone(void) {
    avra_wait_gate(avra_gate_new(), 0, 0);
    avra_wait_park();
    return 1;
}

static void* g_kept_gate = NULL;
static void* g_kept_task = NULL;
static int g_ran_after = 0;
static void* parks_then_runs(void* self) {
    avra_wait_gate(cap(self), 0, 0);
    avra_wait_park();
    g_ran_after = 1;
    return NULL;
}
static int64_t leaves_one_parked(void) {
    g_kept_gate = avra_gate_new();
    g_kept_task = spawn1(parks_then_runs, g_kept_gate);
    avra_fiber_yield();
    return 1;
}
static void* runs_later(void* self) { (void)self; g_ran_after = 1; return NULL; }
static int64_t leaves_one_ready(void) {
    spawn1(runs_later, NULL);
    return 1;
}
static int64_t leaves_one_asleep(void) {
    spawn1(waits_on, avra_gate_new());
    avra_fiber_yield();
    return 1;
}

// ── the runner's side ───────────────────────────────────────────

// `body` in a child whose stderr is read: what it said, and that it
// ended by itself.
static char g_said[4096];
static void heard(const char* what, void (*body)(void)) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm(10);
        g_fails = 0;
        body();
        _exit(g_fails ? 1 : 0);
    }
    close(out[1]);
    size_t got = 0;
    for (ssize_t n; got < sizeof g_said - 1 && (n = read(out[0], g_said + got, sizeof g_said - 1 - got)) > 0;) got += (size_t)n;
    g_said[got] = 0;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    if (!(WIFEXITED(status) && WEXITSTATUS(status) == 0)) fputs(g_said, stderr);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, what);
}
static int says(const char* words) { return strstr(g_said, words) != NULL; }

static void plain_cases(void) {
    CHECK(avra_case_run(passes) == 1, "a case that answers true passes");
    CHECK(avra_case_run(fails) == 0, "a case that answers false fails");
    CHECK(avra_case_run(spawns_and_joins) == 1, "a case that spawns, joins and sleeps passes");
    CHECK(avra_case_run(recurses) == 1, "a case recurses two megabytes deep: its stack is the main thread's size");
    CHECK(avra_sched_tasks() == 0, "and no task outlives them");
}

static void deadlocked_pair(void) {
    CHECK(avra_case_run(each_waits_on_the_other) == 0, "a case whose tasks all wait fails");
    CHECK(avra_sched_tasks() == 0 && avra_sched_timers() == 0, "and its tasks are gone");
    CHECK(avra_case_run(spawns_and_joins) == 1, "the next case runs, and passes");
}
static void deadlocked_alone(void) {
    CHECK(avra_case_run(waits_alone) == 0, "a case that waits on a gate nobody holds fails");
    CHECK(avra_case_run(passes) == 1, "and the next passes");
}

static void leaked_parked(void) {
    g_ran_after = 0;
    CHECK(avra_case_run(leaves_one_parked) == 0, "a case that leaves a task parked fails");
    CHECK(avra_sched_tasks() == 0, "the task is gone");
    CHECK(avra_gate_claim(g_kept_gate) == -1, "from the gate it waited on too");
    CHECK(avra_task_done(g_kept_task) == 1, "and whoever still holds it reads a task that has ended");
    CHECK(avra_case_run(spawns_and_joins) == 1 && !g_ran_after, "and never runs again");
}
static void leaked_ready(void) {
    g_ran_after = 0;
    CHECK(avra_case_run(leaves_one_ready) == 0, "a case that leaves a task it never ran fails");
    CHECK(avra_case_run(spawns_and_joins) == 1 && !g_ran_after, "and that task never runs");
}
static void two_in_a_row(void) {
    CHECK(avra_case_run(leaves_one_asleep) == 0, "a first leak fails its case");
    CHECK(avra_case_run(leaves_one_asleep) == 0, "a second fails its own");
}

int main(void) {
    alarm(120);
    heard("cases that pass and fail by their answer", plain_cases);
    CHECK(g_said[0] == 0, "a case that neither leaks nor deadlocks says nothing");

    heard("a deadlocked pair fails one case and the next runs", deadlocked_pair);
    CHECK(says("every task is waiting, and nothing can wake one"), "a deadlock is named");
    CHECK(says("task 0, the case, joins task 1"), "the case's own task and whom it joins");
    CHECK(says("task 1, spawned at 0x") && says("task 2, spawned at 0x"), "each task and where it was spawned");
    CHECK(strstr(g_said, "waits on gate 0x") != NULL && strstr(strstr(g_said, "waits on gate 0x") + 1, "waits on gate 0x") != NULL, "and the gate each waits on");

    heard("a case alone on a gate fails and the next runs", deadlocked_alone);
    CHECK(says("task 0, the case, waits on gate 0x"), "the case's own wait is named");

    heard("a parked task that outlives its case", leaked_parked);
    CHECK(says("task 1, spawned at 0x") && says("outlived the case") && says("waits on gate 0x"), "a leak is named with what it waits on");
    CHECK(!says("every task is waiting"), "and is no deadlock");

    heard("a ready task that outlives its case", leaked_ready);
    CHECK(says("task 1, spawned at 0x") && says("outlived the case") && says("ready to run"), "a leak that never ran is named so");

    heard("two leaks in a row", two_in_a_row);
    CHECK(strstr(g_said, "task 1,") != NULL && strstr(strstr(g_said, "task 1,") + 1, "task 1,") != NULL, "a task's number is counted from its case's first spawn");
    CHECK(!says("task 2,"), "never from the process's");

    printf("case: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

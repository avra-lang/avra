// THE TICK: the byte the switch reads instead of the clock, the source
// that sets it, the `wanted` store that gates it, and the seeded DRAW a
// checked back-edge takes when there is no source. Each case runs as
// fibers; the draw is the same turn under the same schedule.
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_platform.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "tick_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

typedef void* (*Code)(void*);
static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static int64_t cap(void* box) { return ((AvraArray*)box)->data[1]; }
static void joined(void* task) {
    avra_rc_release(avra_task_join(task));
    avra_rc_release(task);
}

static void pause_ms(int ms) {
    struct timespec t = { ms / 1000, (long)(ms % 1000) * 1000000 };
    nanosleep(&t, NULL);
}

// ── the seeded draw, one log per schedule ───────────────────────
//
// Two tasks each take TURNS back-edges; each back-edge appends its own
// letter. With no preemption the order is A's whole run then B's; a
// drawn yield interleaves them, the SAME way under the same schedule.

enum { TURNS = 200 };
static char g_log[TURNS * 4 + 4];
static int g_log_len = 0;
static void fresh(void) { g_log_len = 0; g_log[0] = 0; }
static void note(char c) { if (g_log_len < TURNS * 4) g_log[g_log_len++] = c; g_log[g_log_len] = 0; }

static void* spinner(void* self) {
    char name = (char)cap(self);
    for (int i = 0; i < TURNS; i++) {
        note(name);
        avra_tick_cold();
    }
    return NULL;
}

static void order_under(int64_t schedule) {
    fresh();
    avra_sched_seed(schedule);
    CHECK(avra_tick == 1, "a seeded run holds the tick set");
    void* a = spawn1(spinner, 'A');
    void* b = spawn1(spinner, 'B');
    joined(a);
    joined(b);
    avra_sched_settle();
}

// Whether the log is A's whole run then B's — no interleaving.
static int uninterrupted(void) {
    int seen_b = 0;
    for (int i = 0; i < g_log_len; i++) {
        if (g_log[i] == 'B') seen_b = 1;
        else if (seen_b) return 0;
    }
    return 1;
}

// `body` in a child a hang cannot outlive.
static void in_child(const char* what, void (*body)(void)) {
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        alarm(30);
        g_fails = 0;
        g_checks = 0;
        body();
        printf("tick: %d checks, %d failed (%s)\n", g_checks, g_fails, what);
        fflush(stdout);
        _exit(g_fails ? 1 : 0);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, what);
}

static void body_seeded_do(void) {
    // schedule 0 draws nothing and never preempts: the queue's own order.
    order_under(0);
    char zero[TURNS * 4 + 4];
    strcpy(zero, g_log);
    CHECK(avra_tick == 0, "the tick clears when the schedule settles");
    CHECK(uninterrupted(), "schedule 0 never preempts a back-edge");
    CHECK(strlen(zero) == TURNS * 2, "schedule 0 runs every turn, in one run each");

    // a schedule that preempts does so at the SAME turn twice running.
    order_under(1);
    char one[TURNS * 4 + 4];
    strcpy(one, g_log);
    CHECK(!uninterrupted(), "schedule 1 preempts a spinning back-edge");
    order_under(1);
    CHECK(strcmp(one, g_log) == 0, "one schedule preempts at the same turn twice running");

    // a different schedule is a different order.
    order_under(2);
    CHECK(strcmp(one, g_log) != 0, "a different schedule draws a different turn");

    // THE BACK-EDGE COUNT IS DRAWN FROM THE SCHEDULE'S STREAM: one
    // spinner's next yield is a counted choice. A constant count draws
    // nothing and leaves the schedule's choices at zero.
    fresh();
    avra_sched_seed(1);
    joined(spawn1(spinner, 'A'));
    CHECK(avra_sched_settle() > 0, "the seeded back-edge count is drawn from the schedule");
}

// ── the source the switch reads ─────────────────────────────────

static void body_source_do(void) {
    avra_tick = 0;
    avra_tick_wanted = 1;
    avra_tick_armed();
    int armed_at = -1;
    for (int i = 0; i < 200; i++) {
        if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) { armed_at = i; break; }
        pause_ms(2);
    }
    CHECK(armed_at >= 0, "the source sets the tick while tasks are wanted");

    // A TICK ASKS THE WORLD AT THE NEXT SWITCH: a timer due now fires
    // at once with the byte set, and waits out AVRA_TIMER_TURNS without.
    void* timed = avra_task_at(1);
    avra_tick = 1;
    avra_fiber_yield();
    CHECK(avra_task_done(timed) != 0, "a tick makes a due timer fire on the next switch");
    CHECK(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED) == 0, "the switch consumes the tick");
    avra_rc_release(timed);
    // stood down, the source parks: clear the byte and see it stay clear.
    avra_tick_wanted = 0;
    avra_tick_stood_down();
    pause_ms(120);
    avra_tick = 0;
    pause_ms(120);
    CHECK(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED) == 0, "an unwanted source parks and stops ticking");

    // A PARKED SOURCE WAKES ON A RE-ARM: the byte goes set again.
    avra_tick = 0;
    avra_tick_wanted = 1;
    avra_tick_armed();
    int rearmed = 0;
    for (int i = 0; i < 200 && !rearmed; i++) {
        if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) rearmed = 1;
        else pause_ms(2);
    }
    CHECK(rearmed, "a parked source wakes on re-arm and sets the tick");

    // THE PERIOD IS THE SETTING'S: a tick is not up before it is.
    int64_t saved_us = avra_tick_us;
    avra_tick_us = 400000;
    avra_tick = 0;
    avra_tick_wanted = 1;
    avra_tick_armed();
    int ticked = 0;
    for (int i = 0; i < 200 && !ticked; i++) {
        if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) ticked = 1;
        else pause_ms(2);
    }
    CHECK(ticked, "the source sets a tick at all");
    __atomic_store_n(&avra_tick, 0, __ATOMIC_RELAXED);
    pause_ms(150);
    CHECK(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED) == 0, "the source waits out its period before the next tick");
    avra_tick_us = saved_us;

    // a forked child brings its own source up.
    avra_tick_wanted = 1;
    avra_tick_armed();
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        avra_tick_wanted = 1;
        avra_tick = 0;
        int seen = 0;
        for (int i = 0; i < 200 && !seen; i++) {
            if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) seen = 1;
            else pause_ms(2);
        }
        _exit(seen ? 0 : 1);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a forked child re-arms its own tick");
    avra_tick_wanted = 0;
}

// ── the deadline a spinning back-edge is cut by ─────────────────

static volatile int g_neighbour_ran;

// A task that never waits: only the checked back-edge can cut it.
static void* doomed(void* self) {
    (void)self;
    int64_t scope = avra_fiber_within(20);
    while (!__atomic_load_n(&avra_unwinding, __ATOMIC_RELAXED)) avra_tick_cold();
    avra_fiber_within_end(scope);
    return NULL;
}

static void* neighbour(void* self) {
    (void)self;
    g_neighbour_ran = 1;
    return NULL;
}

// A SPINNING TASK IS CANCELLED BY ITS DEADLINE AND A SECOND TASK STILL
// RUNS: the cold side checks the running task's own deadline, which no
// wait filed because the task never waits.
static void body_deadline_do(void) {
    avra_tick_wanted = 1;
    avra_tick_armed();
    g_neighbour_ran = 0;
    void* a = spawn1(doomed, 0);
    void* b = spawn1(neighbour, 0);
    int64_t waited = 0;
    while (avra_task_done(a) == 0 && waited < 4000) { avra_fiber_sleep(5); waited += 5; }
    CHECK(avra_task_done(a) != 0, "a spinning back-edge is cut by its deadline");
    CHECK(g_neighbour_ran, "a second task still runs beside the spinner");
    avra_task_settle(a);
    CHECK(avra_task_ended(a) == 2, "the spinner ends cancelled, never answered");
    avra_rc_release(a);
    joined(b);
    avra_tick_wanted = 0;
    avra_tick_stood_down();
}

// THE EVALUATOR'S OWN COLD SIDE over a virtual task: the same deadline
// cut, with no thread and no fiber.
static void body_vdeadline_do(void) {
    int64_t vt = avra_vtask_new();
    int64_t scope = avra_vtask_within(vt, 20);
    int64_t turns = 0;
    while (avra_vtask_unwinding(vt) == 0 && turns < 100000000) {
        avra_vtask_tick_cold(vt);
        turns++;
    }
    CHECK(avra_vtask_unwinding(vt) != 0, "the evaluator's cold side cuts a virtual spinner at its deadline");
    avra_vtask_within_end(vt, scope);
    avra_vtask_free(vt);
}

// A DUE TIMER FIRES AT A CHECKED BACK-EDGE: a task that computes and
// never switches still lets a due timer's task run, so the cold side
// fires the heap.
static void body_tick_timer_do(void) {
    avra_tick_wanted = 1;
    avra_tick_armed();
    void* timed = avra_task_at(1);
    pause_ms(20);
    __atomic_store_n(&avra_tick, 1, __ATOMIC_RELAXED);
    avra_tick_cold();
    CHECK(avra_task_done(timed) != 0, "a checked back-edge fires a due timer");
    avra_rc_release(timed);
    avra_tick_wanted = 0;
    avra_tick_stood_down();
}

// A TASK THAT OPENS A SCOPE ARMS THE SOURCE although it never waits:
// the scope's own opening stores `wanted`, so the source sets the tick
// and the spinner hears its deadline. Without it the source stands down
// and the spinner never ends.
static void body_scope_arms_do(void) {
    avra_tick_wanted = 0;
    __atomic_store_n(&avra_tick, 0, __ATOMIC_RELAXED);
    // the spawn arms the source; the scope's own opening must keep it wanted
    void* b = spawn1(neighbour, 0);
    int64_t scope = avra_fiber_within(20);
    int64_t turns = 0;
    while (!__atomic_load_n(&avra_unwinding, __ATOMIC_RELAXED) && turns < 100000000) {
        avra_tick_cold();
        turns++;
    }
    CHECK(__atomic_load_n(&avra_unwinding, __ATOMIC_RELAXED) != 0, "opening a scope arms the source and cuts the spinner");
    avra_fiber_within_end(scope);
    joined(b);
    avra_tick_wanted = 0;
    avra_tick_stood_down();
}

// A COMPILED BACK-EDGE INSIDE AN EVALUATED RUN STANDS STILL: the
// evaluator's own task counts the turns, so a compiled check reached
// from a host fn beside it must not consume the guest's tick.
static void body_guest_do(void) {
    avra_sched_run_begins();
    __atomic_store_n(&avra_tick, 1, __ATOMIC_RELAXED);
    for (int i = 0; i < 10; i++) avra_tick_cold();
    CHECK(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED) == 1, "a compiled back-edge inside an evaluated run leaves the guest's tick");
    __atomic_store_n(&avra_tick, 0, __ATOMIC_RELAXED);
    avra_sched_run_ends();
}

// ── the store the source reads ──────────────────────────────────

static volatile int g_running;
static void* yield_forever(void* self) {
    (void)self;
    while (g_running) avra_fiber_yield();
    return NULL;
}

// A SWITCH WITH ANOTHER TASK READY STORES `wanted`: the source reads it
// to know there is preemption work, and a store that never happens
// leaves the source parked while tasks run.
static void body_wanted_do(void) {
    avra_tick_wanted = 0;
    g_running = 1;
    void* a = spawn1(yield_forever, 0);
    void* b = spawn1(yield_forever, 0);
    avra_fiber_yield();
    CHECK(__atomic_load_n(&avra_tick_wanted, __ATOMIC_RELAXED) == 1, "a switch with another task ready stores wanted");
    g_running = 0;
    joined(a);
    joined(b);
    avra_tick_wanted = 0;
}

// A TICK FORCES THE WORLD PATH: with the queue's countdown still long and
// a ready task in hand, the switch reads the world and consumes the tick —
// the tick is time's word that a deadline may have passed.
static void* quiet(void* self) { (void)self; return NULL; }

static void body_tick_forces_world_do(void) {
    avra_tick_wanted = 0;                   // the source is parked: the byte is ours alone
    avra_tick = 1;
    void* t = spawn1(quiet, 0);
    avra_fiber_yield();
    CHECK(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED) == 0, "a tick forces the switch through the world");
    joined(t);
}

// ── the pid the arm compares ────────────────────────────────────

// THE HOT ARM READS NO PROCESS ID: the cold arm reads it once and the
// arms after compare the cache. The count is the witness.
static void body_hot_arm_reads_no_pid_do(void) {
    avra_tick_wanted = 1;
    avra_tick_armed();
    uint64_t before = avra_tick_cold_pid_reads();
    for (int i = 0; i < 10000; i++) { avra_tick_armed(); avra_tick_stood_down(); }
    CHECK(before >= 1, "the cold arm reads the process id");
    CHECK(avra_tick_cold_pid_reads() == before, "the hot arm reads no process id");
    avra_tick_wanted = 0;
}

// A RAW FORK RE-ARMS: no `avra_fiber_forked`, only the tick's own fork
// handling — the child's arm stands up a source of its own.
static void body_raw_fork_rearms_do(void) {
    avra_tick_wanted = 1;
    avra_tick_armed();
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        avra_tick = 0;
        avra_tick_wanted = 1;
        avra_tick_armed();
        int seen = 0;
        for (int i = 0; i < 200 && !seen; i++) {
            if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) seen = 1;
            else pause_ms(2);
        }
        _exit(seen ? 0 : 1);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a raw fork brings a source of its own up");
    avra_tick_wanted = 0;
}

int main(void) {
    in_child("a tick forces the world", body_tick_forces_world_do);
    in_child("the seeded draw", body_seeded_do);
    in_child("the hosted source", body_source_do);
    in_child("the pid the arm compares", body_hot_arm_reads_no_pid_do);
    in_child("a raw fork re-arms", body_raw_fork_rearms_do);
    in_child("the store the source reads", body_wanted_do);
    in_child("the deadline a spinner is cut by", body_deadline_do);
    in_child("the evaluator's deadline cut", body_vdeadline_do);
    in_child("a due timer at a checked back-edge", body_tick_timer_do);
    in_child("a scope's own opening arms the source", body_scope_arms_do);
    in_child("a compiled back-edge inside an evaluated run", body_guest_do);
    printf("tick: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

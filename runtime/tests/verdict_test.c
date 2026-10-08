// THE RUNNER'S VERDICT ON A CASE: schedule 0 first; a case that made no
// choice has one order and runs once; one that chose runs the next
// schedules up to AVRA_SCHED_RUNS (8), and the first that fails is named
// with the number that replays it; AVRA_SCHED_SEED runs that one alone.
#include <stdbool.h>
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
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "verdict_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

typedef void* (*Code)(void*);
static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static void joined(void* task) { avra_rc_release(avra_task_join(task)); avra_rc_release(task); }

static int g_runs = 0;
static char g_order[8];
static int g_at = 0;
static void* notes(void* self) { g_order[g_at++] = (char)((AvraArray*)self)->data[1]; return NULL; }

// No task: no choice.
static bool alone(void) { g_runs++; return true; }

// Three tasks; passes in every order.
static bool three_any(void) {
    g_runs++;
    g_at = 0;
    void* t[3];
    for (int i = 0; i < 3; i++) t[i] = spawn1(notes, 'a' + i);
    for (int i = 0; i < 3; i++) joined(t[i]);
    return true;
}

// Three tasks; fails unless `a` runs first — not under schedule 0.
static bool a_first(void) {
    g_runs++;
    g_at = 0;
    void* t[3];
    for (int i = 0; i < 3; i++) t[i] = spawn1(notes, 'a' + i);
    for (int i = 0; i < 3; i++) joined(t[i]);
    return g_order[0] == 'a';
}

static char g_said[2048];
static void heard(const char* what, void (*body)(void)) {
    int out[2];
    if (pipe(out) != 0) exit(1);
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm(20);
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
static int says(const char* w) { return strstr(g_said, w) != NULL; }

static int64_t verdict(bool (*body)(void)) { return avra_case_verdict((int64_t)(uintptr_t)body, "a case"); }

// An `i1` answer with its upper bits unspecified: only the lowest counts.
static uint8_t false_with_noise_above(void) { return 0xfe; }
static uint8_t true_with_noise_above(void) { return 0x81; }
static void lowest_bit(void) {
    CHECK(avra_case_verdict((int64_t)(uintptr_t)false_with_noise_above, "noise") == 0, "a case's answer is its lowest bit: 0xfe is false");
    CHECK(avra_case_verdict((int64_t)(uintptr_t)true_with_noise_above, "noise") == 1, "and 0x81 is true");
}
static bool fails_alone(void) { return false; }
static void one_order_fails_quietly(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    CHECK(verdict(fails_alone) == 0, "a case with one order that fails, fails");
}
// A case that sleeps a minute.
static int64_t g_case_clock = 0;
static bool sleeps_a_minute(void) {
    int64_t c0 = avra_now_ns();
    avra_fiber_sleep(60000);
    g_case_clock = avra_now_ns() - c0;
    return true;
}
static bool sleeps_briefly(void) {
    int64_t c0 = avra_now_ns();
    avra_fiber_sleep(30);
    g_case_clock = avra_now_ns() - c0;
    return true;
}
static int64_t wall_ns(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec; }
static void on_the_virtual_clock(void) {
    int64_t before = avra_now_ns() - wall_ns();
    int64_t w0 = wall_ns();
    CHECK(verdict(sleeps_a_minute) == 1, "a case that sleeps a minute passes");
    CHECK(g_case_clock == (int64_t)60000 * 1000000 && wall_ns() - w0 < 1000000000, "in a minute of its clock and none of the wall");
    int64_t drift = avra_now_ns() - wall_ns() - before;
    CHECK(drift > -1000000000 && drift < 1000000000, "and the runner's clock is the one it had: the minute ended with the case");
}
static void on_the_wall_clock(void) {
    setenv("AVRA_CLOCK", "real", 1);
    int64_t w0 = wall_ns();
    CHECK(verdict(sleeps_briefly) == 1 && wall_ns() - w0 >= 25 * 1000000, "AVRA_CLOCK=real runs a case on the wall's clock");
}
static bool fails_on_the_clock(void) { return false; }
static void failed_on_the_virtual_clock(void) {
    verdict(fails_on_the_clock);
    avra_case_schedules_said();
}
static void clock_misspelled(void) {
    setenv("AVRA_CLOCK", "wall", 1);
    verdict(alone);
}
// Spins on the frozen clock: in the case's own task, or in a task it made.
static bool spins_itself(void) {
    int64_t until = avra_now_ns() + 1000000;
    while (avra_now_ns() < until) {}
    return true;
}
static void* spinner(void* self) { (void)self; spins_itself(); return NULL; }
static bool spins_in_a_task(void) {
    void* t = spawn1(spinner, 0);
    joined(t);
    return true;
}
// A spin INSIDE A RUN the case opened — as the evaluator opens one for
// every program it runs — then nothing of that run outlives the case.
static bool spins_in_a_run(void) {
    avra_sched_run_begins();
    avra_clock_virtual(1);
    spins_itself();
    avra_sched_run_ends();
    return true;
}
// And inside a clock run alone, with no schedule's run around it.
static bool spins_in_a_clock_run(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    spins_itself();
    avra_clock_run_ends();
    return true;
}
static void spun_in_a_run(void) {
    setenv("AVRA_CLOCK_ASKS", "1000", 1);
    CHECK(verdict(spins_in_a_run) == 0, "a case that spins inside a run of its own fails");
    CHECK(avra_sched_run_depth() == 0, "and no run it opened stands after it");
    int64_t t0 = avra_now_ns();
    struct timespec nap = { 0, 2000000 };
    nanosleep(&nap, NULL);
    CHECK(avra_now_ns() - t0 >= 1000000, "the runner's clock flows again, as it did before the case");
    CHECK(verdict(alone) == 1, "and the next case passes");
    int64_t clocks = avra_clock_run_depth();
    CHECK(verdict(spins_in_a_clock_run) == 0, "a case that spins inside a clock run of its own fails");
    CHECK(avra_clock_run_depth() == clocks, "and no clock run it opened stands after it");
    t0 = avra_now_ns();
    nanosleep(&nap, NULL);
    CHECK(avra_now_ns() - t0 >= 1000000, "the runner's clock flows again");
}
static void spun_cases(void) {
    setenv("AVRA_CLOCK_ASKS", "1000", 1);
    CHECK(verdict(spins_itself) == 0, "a case that spins on the frozen clock fails");
    CHECK(verdict(alone) == 1, "and the next case runs, and passes");
    CHECK(verdict(spins_in_a_task) == 0, "a case whose task spins on the frozen clock fails");
    CHECK(avra_sched_tasks() == 0, "its tasks are gone");
    CHECK(verdict(alone) == 1, "and the next case passes");
}
// Program tests: a top level that prints.
static void* says_name(void* self) { char w[2] = { (char)((AvraArray*)self)->data[1], '\n' }; if (write(1, w, 2) != 2) _exit(3); return NULL; }
static int64_t two_tasks_print(void) {
    void* a = spawn1(says_name, 'a');
    void* b = spawn1(says_name, 'b');
    joined(a);
    joined(b);
    return 0;
}
static int64_t sleeps_then_prints(void) {
    avra_fiber_sleep(60000);
    if (write(1, "woke\n", 5) != 5) _exit(3);
    return 0;
}
static int64_t prog(int64_t (*body)(void), const char* expected) { return avra_program_verdict((int64_t)(uintptr_t)body, "a program", expected); }
static void programs(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    int64_t w0 = wall_ns();
    CHECK(prog(sleeps_then_prints, "woke") == 1 && wall_ns() - w0 < 1000000000, "a program that sleeps a minute prints what it must in no wall time");
    CHECK(prog(two_tasks_print, "a\nb") == 0, "a program whose order shows fails under some schedule");
}
static void by_default(void) {
    g_runs = 0;
    CHECK(verdict(three_any) == 1 && g_runs == 1, "by default a case that chose runs schedule 0 alone");
}
static void once_or_eight(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    g_runs = 0;
    CHECK(verdict(alone) == 1 && g_runs == 1, "a case that made no choice runs once");
    g_runs = 0;
    CHECK(verdict(three_any) == 1 && g_runs == 8, "a case that chose runs eight schedules");
}
static void fewer(void) {
    setenv("AVRA_SCHED_RUNS", "3", 1);
    g_runs = 0;
    CHECK(verdict(three_any) == 1 && g_runs == 3, "AVRA_SCHED_RUNS sets how many");
}
static int64_t g_failed_at = -1;
static void found(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    g_runs = 0;
    CHECK(verdict(a_first) == 0, "a case that fails in some order fails");
    CHECK(g_runs >= 2 && g_runs <= 8, "found after schedule 0, within eight");
    g_failed_at = g_runs - 1;
}
static void replayed(void) {
    char k[16];
    snprintf(k, sizeof k, "%lld", (long long)g_failed_at);
    setenv("AVRA_SCHED_SEED", k, 1);
    g_runs = 0;
    CHECK(verdict(a_first) == 0 && g_runs == 1, "AVRA_SCHED_SEED runs the failing schedule alone, and it fails again");
}
// The settings are read once, at a process's first case.
static void zero_alone(void) {
    setenv("AVRA_SCHED_SEED", "0", 1);
    g_runs = 0;
    CHECK(verdict(a_first) == 1 && g_runs == 1, "schedule 0 alone passes");
}
static void misspelled(void) {
    setenv("AVRA_SCHED_RUNS", "eight", 1);
    verdict(alone);
}
static bool traps_unless_a_first(void) {
    if (!a_first()) avra_trap("the order was not the one it wanted");
    return true;
}
static void trapped_under_a_schedule(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    avra_case_begin("a case that traps");
    verdict(traps_unless_a_first);
}
static void said_at_the_end(void) {
    setenv("AVRA_SCHED_RUNS", "8", 1);
    verdict(three_any);
    avra_case_schedules_said();
}

int main(void) {
    alarm(120);
    heard("a case with one order fails", one_order_fails_quietly);
    CHECK(g_said[0] == 0, "and names no schedule: none would replay anything");
    heard("by default, one schedule", by_default);
    heard("program tests run as cases, under their schedules", programs);
    CHECK(says("avra: a program failed under schedule") && says("AVRA_SCHED_SEED="), "a program that printed otherwise names the schedule that replays it");
    heard("a case on the virtual clock", on_the_virtual_clock);
    heard("cases that spin on the frozen clock fail, and the suite goes on", spun_cases);
    heard("a spin inside a run the case opened", spun_in_a_run);
    CHECK(says("avra: a task is waiting on the clock without sleeping"), "the spin is named");
    CHECK(says("the case, outlived the case — stopped: it waited on the frozen clock without sleeping"), "and the stopped task says why it stopped");
    heard("a case on the wall's clock", on_the_wall_clock);
    heard("a failed case on the virtual clock", failed_on_the_virtual_clock);
    CHECK(says("the cases ran on the virtual clock — AVRA_CLOCK=real runs them on the wall's"), "a suite that failed says how to run it on the wall's clock");
    heard("a case answers by its lowest bit", lowest_bit);
    heard("a case runs once, or eight times", once_or_eight);
    CHECK(g_said[0] == 0, "a passing case says nothing");
    heard("the setting", fewer);
    heard("a schedule that fails", found);
    CHECK(says("avra: a case failed under schedule") && says("AVRA_SCHED_SEED="), "the failing schedule is named with the number that replays it");
    char want[64];
    {
        // the child's count reaches the parent through what it said
        const char* at = strstr(g_said, "under schedule ");
        g_failed_at = at ? atoll(at + strlen("under schedule ")) : -1;
        snprintf(want, sizeof want, "AVRA_SCHED_SEED=%lld", (long long)g_failed_at);
        CHECK(g_failed_at > 0 && says(want), "the number said is the one that replays it");
    }
    heard("the failing schedule, replayed", replayed);
    heard("schedule 0 alone", zero_alone);
    heard("the count, said once", said_at_the_end);
    CHECK(says("8 schedules") && says("AVRA_SCHED_RUNS=8 runs more, as the nightly `orders` run does") && says("orders past 16 ready tasks are not all reachable"), "the count is said with how to run more and what it cannot reach");
    {
        int out[2];
        if (pipe(out) != 0) return 1;
        pid_t pid = fork();
        if (pid == 0) { dup2(out[1], 2); close(out[0]); trapped_under_a_schedule(); _exit(0); }
        close(out[1]);
        size_t got = 0;
        for (ssize_t n; got < sizeof g_said - 1 && (n = read(out[0], g_said + got, sizeof g_said - 1 - got)) > 0;) got += (size_t)n;
        g_said[got] = 0;
        int status = 0;
        waitpid(pid, &status, 0);
        CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2 && says("while running a case that traps under schedule ") && says("replays it") && !says("under schedule 0"), "a trap in a seeded case names its schedule");
    }
    {
        int out[2];
        if (pipe(out) != 0) return 1;
        pid_t pid = fork();
        if (pid == 0) { dup2(out[1], 2); close(out[0]); misspelled(); _exit(0); }
        close(out[1]);
        size_t got = 0;
        for (ssize_t n; got < sizeof g_said - 1 && (n = read(out[0], g_said + got, sizeof g_said - 1 - got)) > 0;) got += (size_t)n;
        g_said[got] = 0;
        int status = 0;
        waitpid(pid, &status, 0);
        CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2 && says("AVRA_SCHED_RUNS takes a whole number"), "a setting that is no number traps by name");
    }
    {
        int out[2];
        if (pipe(out) != 0) return 1;
        pid_t pid = fork();
        if (pid == 0) { dup2(out[1], 2); close(out[0]); clock_misspelled(); _exit(0); }
        close(out[1]);
        size_t got = 0;
        for (ssize_t n; got < sizeof g_said - 1 && (n = read(out[0], g_said + got, sizeof g_said - 1 - got)) > 0;) got += (size_t)n;
        g_said[got] = 0;
        int status = 0;
        waitpid(pid, &status, 0);
        CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2 && says("AVRA_CLOCK is `virtual` or `real`"), "a clock setting that is neither traps by name");
    }
    printf("verdict: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

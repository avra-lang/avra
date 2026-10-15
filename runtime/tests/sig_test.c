// A SIGNAL IS A WAKE A TASK PARKS ON: it files on two signals and a far
// timer, and the signal raised wakes it on that signal's own member. The
// signal is one wait per row, so a source watching several files each.
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "sig_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static int64_t now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec;
}
static int64_t in_ms(int64_t ms) { return now_ns() + ms * 1000000; }

// A claim as a task reads it.
static int arm_of(int64_t claim) { return (int)(claim >> 32); }
static int member_of(int64_t claim) { return (int)(int32_t)(uint32_t)claim; }

typedef void* (*Code)(void*);
static void* answer(int64_t v) { void* r = avra_array_sized(1); avra_array_push(r, v); return r; }
static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static void* joined(void* task) {
    void* r = avra_task_join(task);
    int64_t v = r ? ((AvraArray*)r)->data[0] : -99;
    avra_rc_release(r);
    avra_rc_release(task);
    return (void*)(uintptr_t)v;
}

static int64_t g_claim = -99;
static void* waits_for_sig(void* self) {
    (void)self;
    avra_wait_sig(SIGINT, 0, 5);
    avra_wait_sig(SIGTERM, 1, 6);
    avra_wait_until(in_ms(2000), 2, 9);
    g_claim = avra_wait_park();
    return answer(0);
}
static void a_signal_wakes_the_member_that_answers_it(void) {
    g_claim = -99;
    int64_t held = avra_sched_fd_waiters();
    void* t = spawn1(waits_for_sig, 0);
    avra_fiber_sleep(20);
    CHECK(avra_sched_fd_waiters() == held + 2, "the signal waiters are filed with the poller");
    kill(getpid(), SIGTERM);
    avra_fiber_sleep(20);
    CHECK(arm_of(g_claim) == 1 && member_of(g_claim) == 6, "the raised signal wakes the task on its own member");
    joined(t);
    CHECK(avra_sched_fd_waiters() == held, "nothing stays filed after the set");
}

// EACH SIGNAL IS ITS OWN MEMBER: SIGINT wakes the SIGINT waiter and
// leaves the SIGTERM waiter parked until its own signal.
static int64_t g_int_claim = -99;
static int64_t g_term_claim = -99;
static void* waits_int(void* self) {
    (void)self;
    avra_wait_sig(SIGINT, 0, 5);
    avra_wait_until(in_ms(2000), 2, 9);
    g_int_claim = avra_wait_park();
    return answer(0);
}
static void* waits_term(void* self) {
    (void)self;
    avra_wait_sig(SIGTERM, 1, 6);
    avra_wait_until(in_ms(2000), 2, 9);
    g_term_claim = avra_wait_park();
    return answer(0);
}
static void each_signal_is_its_own_member(void) {
    g_int_claim = g_term_claim = -99;
    void* a = spawn1(waits_int, 0);
    void* b = spawn1(waits_term, 0);
    avra_fiber_sleep(20);
    kill(getpid(), SIGINT);
    avra_fiber_sleep(20);
    CHECK(arm_of(g_int_claim) == 0 && member_of(g_int_claim) == 5, "SIGINT wakes its own waiter");
    CHECK(g_term_claim == -99, "the SIGTERM waiter stays parked on SIGINT");
    kill(getpid(), SIGTERM);
    avra_fiber_sleep(20);
    CHECK(arm_of(g_term_claim) == 1 && member_of(g_term_claim) == 6, "SIGTERM then wakes its own waiter");
    joined(a);
    joined(b);
}

int main(void) {
    alarm(120);
    a_signal_wakes_the_member_that_answers_it();
    each_signal_is_its_own_member();
    printf("sig: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

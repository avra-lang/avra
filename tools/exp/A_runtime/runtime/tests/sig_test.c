// A SIGNAL IS A WAKE A TASK PARKS ON: it files on two signals and a far
// timer, and the signal raised wakes it on that signal's own member. The
// signal is one wait per row, so a source watching several files each.
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
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
    avra_wait_sig(1, 0, 5);
    avra_wait_sig(3, 1, 6);
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
    avra_wait_sig(1, 0, 5);
    avra_wait_until(in_ms(2000), 2, 9);
    g_int_claim = avra_wait_park();
    return answer(0);
}
static void* waits_term(void* self) {
    (void)self;
    avra_wait_sig(3, 1, 6);
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

// A KIND IS THE PLATFORM'S NUMBER: `avra_sig_number` maps the portable
// `Sig` index to the header's own value, so kind 4 is SIGUSR1 on Darwin
// (30) and on Linux (10) alike. Before the mapping moved to the runtime
// the Avra table hardcoded Linux's 10, which on Darwin is SIGBUS — this
// check fails there, which is the point.
static void a_kind_is_the_platforms_number(void) {
    CHECK(avra_sig_number(0) == SIGHUP, "kind 0 is SIGHUP");
    CHECK(avra_sig_number(1) == SIGINT, "kind 1 is SIGINT");
    CHECK(avra_sig_number(2) == SIGQUIT, "kind 2 is SIGQUIT");
    CHECK(avra_sig_number(3) == SIGTERM, "kind 3 is SIGTERM");
    CHECK(avra_sig_number(4) == SIGUSR1, "kind 4 is SIGUSR1");
    CHECK(avra_sig_number(5) == SIGUSR2, "kind 5 is SIGUSR2");
    CHECK(avra_sig_number(6) == SIGPIPE, "kind 6 is SIGPIPE");
    CHECK(avra_sig_number(7) == SIGALRM, "kind 7 is SIGALRM");
    CHECK(avra_sig_number(8) == SIGCHLD, "kind 8 is SIGCHLD");
}

// THE DISPOSITION IS GIVEN BACK: once the last waiter leaves a signal,
// its action is what it was before any wait — a child fork inherits none
// of the ignore a wait spent. The prior action is remembered at entry,
// because a runner may itself have handed this process an `SIG_IGN`.
static struct sigaction g_prior_term;
static void remember_dispositions(void) { sigaction(SIGTERM, NULL, &g_prior_term); }
static void the_disposition_is_given_back(void) {
    struct sigaction sa;
    sigaction(SIGTERM, NULL, &sa);
    CHECK(sa.sa_handler == g_prior_term.sa_handler, "SIGTERM's disposition is what it was before any wait");
    if (g_prior_term.sa_handler != SIG_DFL) return;
    pid_t child = fork();
    if (child == 0) {
        raise(SIGTERM);
        _exit(0);
    }
    int status = 0;
    waitpid(child, &status, 0);
    CHECK(WIFSIGNALED(status) && WTERMSIG(status) == SIGTERM, "a forked child dies to SIGTERM");
}

int main(void) {
    alarm(120);
    remember_dispositions();
    a_kind_is_the_platforms_number();
    a_signal_wakes_the_member_that_answers_it();
    each_signal_is_its_own_member();
    the_disposition_is_given_back();
    printf("sig: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

// The wait set: one task waiting on a descriptor, a time and a gate at
// once, claimed by exactly one of them; a cancel that never displaces a
// claim; tasks nothing runs; the per-task slots; and the stacks past
// the count that get a guard page each. Every scenario a compiled
// program's fibers run is run again as the evaluator drives it.
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
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "flow_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static void closed(int fd) { avra_fiber_fd_closing(fd); close(fd); }

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
static int64_t cap(void* box) { return ((AvraArray*)box)->data[1]; }
static int64_t joined(void* task) {
    void* r = avra_task_join(task);
    int64_t v = r ? ((AvraArray*)r)->data[0] : -99;
    avra_rc_release(r);
    avra_rc_release(task);
    return v;
}
// How a task ended, once it has: 0 live, 1 answered, 2 cancelled.
static int64_t ended(void* task) {
    avra_task_settle(task);
    int64_t how = avra_task_ended(task);
    avra_rc_release(task);
    return how;
}

static int filed(void* gate) { return ((AvraArray*)gate)->data[0] != 0; }

static int64_t g_log[64];
static int g_log_len = 0;
static void note(int64_t v) { if (g_log_len < 64) g_log[g_log_len++] = v; }
static int logged(const int64_t* want, int n) { return g_log_len == n && memcmp(g_log, want, (size_t)n * sizeof(int64_t)) == 0; }

static int g_pipe[2];
static void* g_gate;
static void* g_gates[6];
static void* g_task;
static void* g_pending;
static int64_t g_handed = 0;
static int64_t g_seen = 0;

// ── a child's end: its words and its status ─────────────────────

// A CASE ON THE VIRTUAL CLOCK RUNS IN A CHILD UNDER A SHORT BOUND: a
// clock that never moves hangs it, and the bound turns the hang into a
// failing check.
// Whether the bound ended it.
static int said_within(const char* what, void (*body)(void), const char* words, unsigned seconds, int code) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        dup2(out[1], 2);
        close(out[0]);
        alarm(seconds);
        body();
        _exit(0);
    }
    close(out[1]);
    char buf[512] = {0};
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    char label[200];
    snprintf(label, sizeof label, "%s exits %d", what, code);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == code, label);
    snprintf(label, sizeof label, "%s says \"%s\"", what, words);
    CHECK(strstr(buf, words) != NULL, label);
    return WIFSIGNALED(status) && WTERMSIG(status) == SIGALRM;
}

static void trapped(const char* what, void (*body)(void), const char* words) { said_within(what, body, words, 60, 2); }

// ── three sources in one set ────────────────────────────────────

// Waits three times on the pipe (arm 0), a time (arm 1) and the gate
// (arm 2): the time far off, until the last round.
static void* three_sources(void* self) {
    (void)self;
    for (int round = 0; round < 3; round++) {
        avra_wait_fd(g_pipe[0], 0, 0, 10);
        avra_wait_until(in_ms(round == 2 ? 5 : 60000), 1, 11);
        avra_wait_gate(g_gate, 2, 12);
        int64_t claim = avra_wait_park();
        note(arm_of(claim) * 100 + member_of(claim));
        note(avra_sched_fd_waiters() + (filed(g_gate) ? 100 : 0));
        char c;
        if (arm_of(claim) == 0 && read(g_pipe[0], &c, 1) != 1) note(-1);
    }
    return answer(0);
}

static void three_sources_as_fibers(void) {
    g_log_len = 0;
    g_gate = avra_gate_new();
    void* t = spawn1(three_sources, 0);
    avra_fiber_sleep(2);
    CHECK(avra_sched_timers() == 1 && avra_sched_fd_waiters() == 1 && filed(g_gate), "a parked set is filed with all three sources");
    CHECK(avra_gate_claim(g_gate) == 12, "the gate's claim answers the waiter's member");
    CHECK(!filed(g_gate), "the claimant takes the winner out at the claim");
    CHECK(avra_gate_claim(g_gate) == -1, "a gate with no waiter left answers -1");
    avra_fiber_sleep(2);
    CHECK(write(g_pipe[1], "x", 1) == 1, "the pipe takes a byte");
    avra_fiber_sleep(2);
    joined(t);
    int64_t want[] = { 212, 0, 10, 0, 111, 0 };
    CHECK(logged(want, 6), "one task is woken by a gate, a descriptor and a time, once each, and the losers are retracted");
    CHECK(avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0, "nothing stays filed after the set");
    avra_rc_release(g_gate);
}

static void* parks_on_gate(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 0, 0);
    int64_t claim = avra_wait_park();
    return answer(claim);
}

static void* waits_on_pipe(void* self) {
    (void)self;
    avra_wait_fd(g_pipe[0], 0, 0, 10);
    int64_t claim = avra_wait_park();
    return answer(claim);
}

static void bad_direction(void) { (void)avra_fd_parked(g_pipe[0], 2); }

// A PARKED COUNT IS THE LIST'S: fibers filed on a gate, or on one
// direction of a descriptor, and none that left.
static void parked_counts(void) {
    g_gate = avra_gate_new();
    void* a = spawn1(parks_on_gate, 0);
    void* b = spawn1(parks_on_gate, 0);
    CHECK(avra_parked_on(g_gate) == 0, "nothing is parked on a gate before its waiters run");
    avra_fiber_sleep(2);
    CHECK(avra_parked_on(g_gate) == 2, "two fibers are parked on the gate once they run");
    CHECK(avra_gate_claim(g_gate) >= 0, "a claim wakes one");
    CHECK(avra_parked_on(g_gate) == 1, "the claimant leaves the count");
    CHECK(avra_gate_claim(g_gate) >= 0, "a claim wakes the other");
    CHECK(avra_parked_on(g_gate) == 0, "no fiber is left parked");
    joined(a);
    joined(b);
    avra_rc_release(g_gate);
    void* r = spawn1(waits_on_pipe, 0);
    avra_fiber_sleep(2);
    CHECK(avra_fd_parked(g_pipe[0], 0) == 1, "the reader is parked on its descriptor's read side");
    CHECK(avra_fd_parked(g_pipe[0], 1) == 0, "and no one on its write side");
    CHECK(avra_fd_parked(-1, 0) == 0, "a descriptor that is no fd has no waiters");
    CHECK(write(g_pipe[1], "x", 1) == 1, "the pipe takes a byte");
    avra_fiber_sleep(2);
    joined(r);
    CHECK(avra_fd_parked(g_pipe[0], 0) == 0, "the woken reader leaves the descriptor");
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "the byte is drained");
}

// A DESCRIPTOR THAT STAYS WRITABLE CLAIMS EVERY WAIT, NOT ONLY THE
// FIRST: the poller's watch is edge-triggered, so a second wait on a
// descriptor the first consumed the edge for must restore the
// readiness it found — else the wait parks until its own deadline.
static void* waits_writable_fd_twice(void* self) {
    (void)self;
    int p[2];
    if (pipe(p) != 0) { note(-1); return answer(0); }
    avra_wait_fd(p[1], 1, 3, 7);
    int64_t first = avra_wait_park();
    note(arm_of(first) * 100 + member_of(first));
    avra_wait_fd(p[1], 1, 3, 7);
    avra_wait_until(in_ms(30), 2, 9);
    int64_t second = avra_wait_park();
    note(arm_of(second) * 100 + member_of(second));
    closed(p[0]);
    closed(p[1]);
    return answer(0);
}

static void writable_fd_waits_twice(void) {
    g_log_len = 0;
    joined(spawn1(waits_writable_fd_twice, 0));
    int64_t want[] = { 307, 307 };
    CHECK(logged(want, 2), "a continuously writable descriptor claims every wait that asks for it, not only the first");
}

// ── a cancel never displaces a claim ────────────────────────────

static void* taker(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 3, 7);
    int64_t first = avra_wait_park();
    note(arm_of(first) * 100 + member_of(first));
    note(g_handed);
    avra_wait_gate(g_gate, 3, 7);
    int64_t second = avra_wait_park();
    note(arm_of(second) * 100 + member_of(second));
    return answer(0);
}

static void claim_then_cancel(void) {
    g_log_len = 0;
    g_handed = 0;
    g_gate = avra_gate_new();
    void* t = spawn1(taker, 0);
    avra_fiber_sleep(2);
    CHECK(avra_gate_claim(g_gate) == 7, "the taker is claimed");
    g_handed = 41;
    avra_task_cancel(t);
    ended(t);
    int64_t want[] = { 307, 41, -100 };
    CHECK(logged(want, 3), "a cancel after a claim: the task resumes on its arm, takes what was handed, and its next wait answers the cancel");
    CHECK(!filed(g_gate), "the cancelled wait left the gate");
    avra_rc_release(g_gate);

    g_log_len = 0;
    g_gate = avra_gate_new();
    t = spawn1(taker, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(avra_gate_claim(g_gate) == -1, "a claim after a cancel finds the set taken and moves on");
    ended(t);
    CHECK(g_log_len == 3 && g_log[0] == -100 && g_log[2] == -100, "a cancel first: the wait answers -1:0, and so does the next");
    avra_rc_release(g_gate);
}

// ── a cancel and the rows that predate the set ──────────────────

// What it slept, by the process's own clock: virtual where the case is.
static void* sleeper(void* self) { int64_t t0 = avra_now_ns(); avra_fiber_sleep(cap(self)); return answer((avra_now_ns() - t0) / 1000000); }

static int64_t g_byte_a = -1, g_byte_b = -1, g_byte_c = -1, g_byte_d = -1;
static int64_t g_spent_ms = -1;
static void bytes_unseen(void) { g_byte_a = g_byte_b = g_byte_c = g_byte_d = g_spent_ms = -1; }
static int64_t ms_since(int64_t t0) { return (avra_now_ns() - t0) / 1000000; }

// A ten-second sleep, and what the task held when it came back.
static void* sleeps_long(void* self) {
    (void)self;
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(10000);
    g_byte_a = avra_unwinding;
    g_spent_ms = ms_since(t0);
    return answer(0);
}

// EVERY CASE BELOW RUNS ON THE VIRTUAL CLOCK, in a child of its own: a
// wait the cancel does not cut jumps the clock to its end, so a cut is
// told from a whole wait by the time spent, never by wall time.
static void cancel_cuts_sleep(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    int64_t live = avra_mem_live();
    void* t = spawn1(sleeps_long, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    avra_rc_retain(t);
    CHECK(ended(t) == 2, "a task whose sleep a cancel cut ends cancelled");
    CHECK(g_byte_a == 1, "its sleep comes back with the unwind bit set");
    CHECK(g_spent_ms < 1000, "at once, not after its ten seconds");
    CHECK(avra_sched_timers() == 0, "its time leaves the heap");
    CHECK(avra_unwinding == 0, "the bit is the task's: the canceller's own stays clear");
    avra_rc_release(t);
    CHECK(avra_mem_live() == live, "a cancelled end leaves nothing behind");
    avra_clock_run_ends();
}

// A JOIN IS A CANCEL POINT: the caller's own cancel cuts the park,
// the join hands back no answer, and the bit is set for the code
// after the call.
static void* joins_long(void* self) {
    (void)self;
    g_task = spawn1(sleeper, 10000);
    avra_rc_retain(g_task);
    void* r = avra_task_join(g_task);
    avra_rc_release(r);
    g_byte_a = avra_unwinding;
    avra_task_settle(g_task);
    avra_rc_release(g_task);
    return answer(0);
}

static void cut_join(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* j = spawn1(joins_long, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(j);
    CHECK(ended(j) == 2 && g_byte_a == 1, "a join its caller's own cancel cut ends the caller cancelled, the bit set");
    CHECK(avra_task_ended(g_task) == 2, "and its scope's end cancels what it was joining");
    avra_rc_release(g_task);
    avra_clock_run_ends();
}

// A task cut at a sleep, then ending its scope with what it owns.
static void* owns_long(void* self) {
    (void)self;
    avra_fiber_sleep(10000);
    g_byte_a = avra_unwinding;
    g_task = spawn1(sleeper, 10000);
    avra_rc_retain(g_task);
    avra_task_settle(g_task);
    avra_rc_release(g_task);
    return answer(0);
}

static void a_scopes_end_cancels_what_it_owns(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    int64_t t0 = avra_now_ns();
    void* t = spawn1(owns_long, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1, "a cut owner ends cancelled");
    CHECK(avra_task_ended(g_task) == 2 && ms_since(t0) < 1000, "its scope's end cancels what it owns, then joins it");
    CHECK(avra_sched_timers() == 0, "so no time of either stays filed");
    avra_rc_release(g_task);
    avra_clock_run_ends();
}

static void* parks_long(void* self) {
    (void)self;
    g_byte_b = avra_fiber_park_fd(g_pipe[0], 0, -1);
    g_byte_a = avra_unwinding;
    return answer(0);
}

static void cancel_cuts_fd_park(void) {
    bytes_unseen();
    void* t = spawn1(parks_long, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a task whose descriptor park a cancel cut ends cancelled");
    CHECK(g_byte_a == 1 && g_byte_b == 0, "the park answers that the descriptor did not wake it, and the bit is set");
    CHECK(avra_sched_fd_waiters() == 0, "and it leaves the descriptor");
}

// A wait set on a gate nobody opens, parked once under `ms` of deadline
// (no deadline when negative).
static void* parks_on_a_shut_gate(void* self) {
    int64_t ms = cap(self);
    int64_t outer = ms >= 0 ? avra_fiber_within(ms) : 0;
    avra_wait_gate(g_gate, 0, 0);
    g_byte_b = avra_wait_park();
    g_byte_a = avra_unwinding;
    if (ms >= 0) avra_fiber_within_end(outer);
    return answer(0);
}

static void wait_park_sets_the_bit(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_gate = avra_gate_new();
    bytes_unseen();
    void* t = spawn1(parks_on_a_shut_gate, -1);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_b == (int64_t)0xffffffff00000000LL && g_byte_a == 1, "a park a cancel claims answers -1:0 with the bit set");
    bytes_unseen();
    t = spawn1(parks_on_a_shut_gate, 5);
    CHECK(ended(t) == 1, "a task whose scope landed the unwind its park began answers");
    CHECK(g_byte_b == (int64_t)0xffffffff00000001LL && g_byte_a == 1, "a park its deadline claims answers -1:1 with the bit set");
    avra_rc_release(g_gate);
    avra_clock_run_ends();
}

// Two yields: the first before the cancel, the second after it.
static void* yields_twice(void* self) {
    (void)self;
    avra_fiber_yield();
    g_byte_a = avra_unwinding;
    avra_fiber_yield();
    g_byte_b = avra_unwinding;
    return answer(0);
}

static void a_yield_is_a_cancel_point(void) {
    bytes_unseen();
    void* t = spawn1(yields_twice, 0);
    avra_fiber_yield();
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a task cancelled while ready ends cancelled");
    CHECK(g_byte_a == 0, "a cancel claims no task that is ready: the bit stays clear until its next cancel point");
    CHECK(g_byte_b == 1, "and that point is its next yield");
}

static void* sleeps_then_sleeps(void* self) {
    (void)self;
    avra_fiber_sleep(3);
    g_byte_a = avra_unwinding;
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(10000);
    g_byte_b = avra_unwinding;
    g_spent_ms = ms_since(t0);
    return answer(0);
}

// THE CLAIM COMES FIRST: both times fall due at once, the canceller's
// asked first, so it runs while the sleeper is claimed and not yet back.
static void claim_first_then_cancel(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(sleeps_then_sleeps, 0);
    avra_fiber_sleep(3);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the sleeper ends cancelled");
    CHECK(g_byte_a == 0, "a sleep its time claimed before the cancel comes back whole, the bit clear");
    CHECK(g_byte_b == 1 && g_spent_ms < 1000, "and its next sleep is cut at once");
    avra_clock_run_ends();
}

static void* sleeps_once(void* self) {
    (void)self;
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(10000);
    g_byte_a = avra_unwinding;
    g_spent_ms = ms_since(t0);
    return answer(0);
}

static void cancelled_before_it_runs(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(sleeps_once, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a task cancelled before it ran ends cancelled");
    CHECK(g_byte_a == 1 && g_spent_ms < 1000, "it runs to its first cancel point, which answers at once");
    avra_clock_run_ends();
}

// A JOIN UNDER A STANDING CANCEL OF AN UNFINISHED TASK READS NO CELL:
// the cancel is met where it stops the park, so the bit the caller's
// after-call test reads is set and nothing of the task is handed back.
static void* joins_first(void* self) {
    (void)self;
    int64_t t0 = avra_now_ns();
    g_byte_b = avra_unwinding;
    g_byte_c = avra_task_join(g_task) == NULL;
    g_byte_a = avra_unwinding;
    g_spent_ms = ms_since(t0);
    return answer(0);
}

static void standing_join_of_an_unfinished_task(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    g_task = spawn1(sleeper, 10000);
    void* t = spawn1(joins_first, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_b == 0, "a task cancelled before it ran reaches its join with the bit clear, and ends cancelled");
    CHECK(g_byte_c == 1 && g_byte_a == 1, "the join hands back nothing and sets the bit, though its task has not ended");
    CHECK(g_spent_ms < 1000 && !avra_task_done(g_task), "at once: the task it named is still running");
    avra_task_cancel(g_task);
    ended(g_task);
    avra_clock_run_ends();
}

// The child reads its own bit before and after its own cut sleep.
static void* reads_its_bit(void* self) {
    (void)self;
    g_byte_c = avra_unwinding;
    avra_fiber_sleep(10000);
    g_byte_d = avra_unwinding;
    return answer(0);
}

// Cut, then owning a child whose join (its scope's end) switches out.
static void* cut_then_owns(void* self) {
    (void)self;
    avra_fiber_sleep(10000);
    g_byte_a = avra_unwinding;
    void* c = spawn1(reads_its_bit, 0);
    avra_task_settle(c);
    g_byte_b = avra_unwinding;
    avra_rc_release(c);
    return answer(0);
}

static void the_bit_is_the_running_tasks(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(cut_then_owns, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the owner ends cancelled");
    CHECK(g_byte_a == 1, "its cut sleep set its bit");
    CHECK(g_byte_c == 0, "the child it then made reads its own bit, clear, while the owner is switched out");
    CHECK(g_byte_d == 1, "and the cancel its owner's scope end gave it cut the child's sleep");
    CHECK(g_byte_b == 1, "back in the owner the bit is the owner's again");
    CHECK(avra_unwinding == 0, "and main's stays clear");
    avra_clock_run_ends();
}

// Cut once, then a descriptor park under the cancel that stands.
static void* cut_then_parks(void* self) {
    (void)self;
    avra_fiber_sleep(10000);
    g_byte_b = avra_fiber_park_fd(g_pipe[0], 0, -1);
    g_byte_a = avra_unwinding;
    return answer(0);
}

static void a_standing_cancel_parks_no_descriptor(void) {
    bytes_unseen();
    void* t = spawn1(cut_then_parks, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the task ends cancelled");
    CHECK(g_byte_b == 0 && g_byte_a == 1, "a descriptor park under a standing cancel answers at once, the bit set");
}

// Cut once, then a join under the cancel that stands: the standing
// cancel meets the join at once, with no answer and the bit set.
static void* cut_then_joins(void* self) {
    (void)self;
    avra_fiber_sleep(10000);
    g_task = spawn1(sleeper, 10000);
    avra_rc_retain(g_task);
    int64_t t0 = avra_now_ns();
    void* r = avra_task_join(g_task);
    g_spent_ms = ms_since(t0);
    g_byte_b = r == NULL;
    avra_rc_release(r);
    g_byte_a = avra_unwinding;
    avra_task_settle(g_task);
    avra_rc_release(g_task);
    return answer(0);
}

static void standing_join(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(cut_then_joins, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1 && g_byte_b == 1, "a standing cancel cuts the join at once, the bit set, no answer handed back");
    CHECK(g_spent_ms < 1000, "at once: it waited for nothing of the task's ten seconds");
    avra_rc_release(g_task);
    avra_clock_run_ends();
}

// A CUT YIELD STILL SWITCHES: it waits for nothing, so there is nothing
// to cut — a cancelled task that polls lets the one it polls run.
static int64_t g_done = 0;
static void* sets_done(void* self) {
    (void)self;
    for (int i = 0; i < 3; i++) avra_fiber_yield();
    g_done = 1;
    return answer(0);
}

static void* polls_done(void* self) {
    (void)self;
    while (!g_done) avra_fiber_yield();
    g_byte_a = avra_unwinding;
    return answer(0);
}

static void a_cut_yield_still_switches(void) {
    bytes_unseen();
    g_done = 0;
    void* p = spawn1(polls_done, 0);
    void* s = spawn1(sets_done, 0);
    avra_task_cancel(p);
    CHECK(ended(p) == 2 && g_byte_a == 1, "a cancelled task that polls by yielding lets the task it polls run, and ends cancelled");
    CHECK(ended(s) == 1, "the task it polled ran to its end");
}

// An owner whose scope's end is already joining when the cancel comes.
static void* owns_a_sleeper(void* self) {
    (void)self;
    g_task = spawn1(sleeper, 10000);
    avra_rc_retain(g_task);
    avra_task_settle(g_task);
    g_byte_a = avra_unwinding;
    avra_rc_release(g_task);
    return answer(0);
}

static void cancel_passes_down_a_scopes_join(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    int64_t t0 = avra_now_ns();
    void* t = spawn1(owns_a_sleeper, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 1, "an owner whose only wait was its scope's end met no cancel point: it ends answered");
    CHECK(g_byte_a == 0, "its bit stays clear");
    CHECK(avra_task_ended(g_task) == 2 && ms_since(t0) < 1000, "the cancel passed down the join it was waiting in, and cut what it owns");
    avra_rc_release(g_task);
    avra_clock_run_ends();
}

// A CAUGHT JOIN READS HOW ITS TASK ENDED WITHOUT PASSING THE CANCEL:
// a two-cell `Cancelled` box (the asker's id, the site), or NULL when
// the task answered.
static void* a_sleeper(void* self) { (void)self; avra_fiber_sleep(10000); return answer(5); }
static void caught_join_of_cancelled(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(a_sleeper, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    void* box = avra_task_join_caught(t);
    CHECK(box != NULL, "a caught join of a cancelled task answers its `Cancelled` box");
    CHECK(box && ((AvraArray*)box)->data[0] == 0, "whose `by` names main, the asking task");
    // No writer records where a cancel was met yet, so `at` stands as
    // the placeholder the boxing leaves it.
    CHECK(box && ((AvraArray*)box)->data[1] == 0, "and whose `at` is still the placeholder zero");
    if (box) avra_rc_release(box);
    CHECK(avra_unwinding == 0, "and the caught join passed no cancel to the caller");
    avra_rc_release(t);
    avra_clock_run_ends();
}

// A CAUGHT JOIN OF A SPAWNED TASK NAMES ITS ASKER: a cancel from a
// task other than main records that task's id, never the default zero.
static int64_t g_asker = 0;
static void* catches_after_asking(void* self) {
    (void)self;
    g_asker = avra_task_id();
    void* t = spawn1(a_sleeper, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    g_byte_b = avra_task_ended_by(t) == g_asker;
    void* box = avra_task_join_caught(t);
    g_byte_a = box != NULL && ((AvraArray*)box)->data[0] == g_asker;
    if (box) avra_rc_release(box);
    avra_rc_release(t);
    return answer(0);
}

static void caught_join_names_its_asker(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* watcher = spawn1(catches_after_asking, 0);
    ended(watcher);
    CHECK(g_asker != 0 && g_byte_a == 1, "a spawned task's cancel names the asker, not the default zero");
    CHECK(g_byte_b == 1, "a cancel records its asker at once, before the task it cancelled ends");
    avra_clock_run_ends();
}

// A TASK THAT ENDED CANCELLED HAS NO ANSWER, AND ITS CANCEL IS ITS
// AWAITER'S: the join hands back nothing, the awaiter's bit is set, and
// its own end names the asker — so whoever joins the awaiter is passed
// the same cancel in turn.
static void* g_links[3];
static void* cancelled_sleeper(void* self) { (void)self; avra_fiber_sleep(10000); return answer(5); }
static void* cancels_the_first_link(void* self) {
    (void)self;
    g_asker = avra_task_id();
    avra_task_cancel(g_links[0]);
    return answer(0);
}
static void* awaits_a_link(void* self) {
    int64_t at = cap(self);
    void* r = avra_task_join(g_links[at]);
    if (at == 0) {
        g_byte_b = r == NULL;
        g_byte_a = avra_unwinding;
    }
    return answer(0);
}

static void join_of_cancelled(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    g_links[0] = spawn1(cancelled_sleeper, 0);
    avra_fiber_sleep(2);
    ended(spawn1(cancels_the_first_link, 0));
    avra_task_settle(g_links[0]);
    g_links[1] = spawn1(awaits_a_link, 0);
    g_links[2] = spawn1(awaits_a_link, 1);
    void* last = spawn1(awaits_a_link, 2);
    avra_task_settle(last);
    CHECK(g_byte_b == 1, "a join of a cancelled task hands back no answer");
    CHECK(g_byte_a == 1, "and sets its caller's unwind bit");
    CHECK(g_asker != 0 && avra_task_ended(g_links[1]) == 2 && avra_task_ended_by(g_links[1]) == g_asker, "the awaiter ends cancelled by the same asker");
    CHECK(avra_task_ended(last) == 2 && avra_task_ended_by(last) == g_asker, "and so does each task up a chain of joins");
    CHECK(avra_unwinding == 0, "a settle of a task that ended so passes nothing on");
    avra_rc_release(last);
    for (int i = 0; i < 3; i++) avra_rc_release(g_links[i]);
    avra_clock_run_ends();
}

// A REQUEST THAT STANDS IS NOT DISPLACED: a task cancelled while the
// gate's claim was already its own meets a cancelled task at its join,
// and ends by the asker whose request stood.
static void* joins_the_pending(void* self) { (void)self; avra_task_join(g_pending); return answer(0); }
static void* cancels_the_pending(void* self) {
    (void)self;
    g_asker = avra_task_id();
    avra_task_cancel(g_pending);
    return answer(0);
}

static void passed_cancel_keeps_a_standing_request(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_pending = avra_task_pending();
    void* joiner = spawn1(joins_the_pending, 0);
    avra_fiber_sleep(2);
    void* other = spawn1(cancels_the_pending, 0);
    avra_fiber_yield();
    avra_task_cancel(joiner);
    avra_task_settle(joiner);
    CHECK(g_asker != 0 && avra_task_ended(joiner) == 2 && avra_task_ended_by(joiner) == 0, "a cancel passed on by a join leaves a standing request its asker");
    avra_rc_release(joiner);
    ended(other);
    avra_rc_release(g_pending);
    avra_clock_run_ends();
}

// A CALLER ALREADY UNWINDING UNDER ITS SCOPE'S REQUEST TAKES ON NO
// OTHER: its join of a cancelled task hands back nothing, and the
// scope still lands.
static void* g_nothing_opens;
static void* lands_past_a_cancelled_join(void* self) {
    (void)self;
    int64_t scope = avra_fiber_within(20);
    avra_wait_gate(g_nothing_opens, 0, 0);
    avra_wait_park();
    avra_unwinding = 1;                     // as the back-edge's cold side raises it
    g_byte_a = avra_task_join(g_pending) == NULL;
    g_byte_b = avra_scope_end(scope) == 1;
    avra_unwinding = 0;
    return answer(0);
}

static void scope_unwinding_join_of_cancelled(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    g_nothing_opens = avra_gate_new();
    g_pending = avra_task_pending();
    avra_task_cancel(g_pending);
    CHECK(ended(spawn1(lands_past_a_cancelled_join, 0)) == 1, "a task its own scope's limit cut lands and answers");
    CHECK(g_byte_a == 1 && g_byte_b == 1, "its join of a cancelled task on the way displaced no request: the scope landed");
    avra_rc_release(g_pending);
    avra_clock_run_ends();
}

// A CALLER ITS OWN CANCEL CUT TAKES NO ANSWER, though the task answered
// before the caller ran again: nothing is retained for it to drop.
static void* joins_and_keeps_nothing(void* self) {
    (void)self;
    g_byte_a = avra_task_join(g_pending) == NULL;
    g_byte_b = avra_unwinding;
    return answer(0);
}

static void cut_join_of_an_answered_task(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    int64_t live = avra_mem_live();
    g_pending = avra_task_pending();
    void* joiner = spawn1(joins_and_keeps_nothing, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(joiner);
    void* unit = answer(7);
    avra_task_answer(g_pending, unit);
    avra_rc_release(unit);
    CHECK(ended(joiner) == 2 && g_byte_b == 1, "a join its caller's cancel cut ends the caller cancelled");
    CHECK(g_byte_a == 1, "and hands it no answer, though the task answered meanwhile");
    avra_rc_release(g_pending);
    CHECK(avra_mem_live() == live, "so nothing it never read is left behind");
    avra_clock_run_ends();
}

// UNDER A SHIELD A DEFERRED CALL RUNS WHOLE: nothing may cut it, and
// the join has no answer for it to go on with, so the join refuses.
static void shielded_join_of_cancelled(void) {
    void* t = avra_task_pending();
    avra_task_cancel(t);
    avra_fiber_shield_enter();
    avra_task_join(t);
}

// THE PROGRAM'S OWN RUN, CANCELLED: its end says one line naming who
// asked, and answers 1 whatever the entry answered.
static void main_awaits_a_cancelled(void) {
    g_pending = avra_task_pending();
    ended(spawn1(cancels_the_pending, 0));
    void* r = avra_task_join(g_pending);
    int passed = r == NULL && avra_unwinding == 1 && g_asker != 0 && avra_main_asker == g_asker + 1;
    _exit(passed ? avra_main_ended(0) : 3);
}

static void main_awaits_what_it_cancelled(void) {
    void* t = avra_task_pending();
    avra_task_cancel(t);
    avra_task_join(t);
    _exit(avra_main_ended(0));
}

static int words_are(int64_t by, const char* want) {
    return strcmp(avra_main_cancelled_words(by), want) == 0;
}

// The words are immortal boxes: a child reads them, so the process that
// counts what its fibers left behind holds none.
static void a_run_end_in_words(void) {
    CHECK(avra_main_ended(7) == 7, "a run that ended uncancelled answers its own code");
    avra_unwinding = 1;
    CHECK(avra_main_ended(7) == 7, "and so does one unwinding under no passed cancel: its end claims no await");
    avra_unwinding = 0;
    CHECK(words_are(7, "main was cancelled — awaiting a task cancelled by task 7"), "the words name the asking task");
    CHECK(words_are(0, "main was cancelled — awaiting a task cancelled by main"), "or the run itself");
    CHECK(words_are(AVRA_SCOPE_IDS | 3, "main was cancelled — awaiting a task cancelled by a `within` limit"), "or a scope's limit");
}

static void caught_join_of_answered(void) {
    int64_t live = avra_mem_live();
    void* t = avra_task_pending();
    void* unit = answer(7);
    avra_task_answer(t, unit);
    avra_rc_release(unit);
    CHECK(avra_task_join_caught(t) == NULL, "a caught join of an answered task answers no cancel");
    void* r = avra_task_join(t);
    CHECK(r && ((AvraArray*)r)->data[0] == 7, "and its answer is there to join");
    avra_rc_release(r);
    avra_rc_release(t);
    CHECK(avra_mem_live() == live, "and the caught join left nothing behind");
}

// A VIRTUAL TASK IS CUT AT ITS PARK TOO: a cancel claims it, readies
// it, and sets its own unwind bit for the evaluator's test after the
// call — the runtime's parks have no `cancel_met` on that side.
static void virtual_cut_at_a_park(void) {
    int64_t vt = avra_vtask_new_at(11, 71);
    avra_vtask_sleep(vt, 10000);
    avra_vtask_cancel(vt, 0);
    CHECK(avra_vtask_next() == vt, "a cancel readies the virtual task it cut at its park");
    CHECK(avra_vtask_unwinding(vt) == 1, "and sets its own unwind bit");
    avra_vtask_free(vt);
}

static void cancel_twice(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    void* t = spawn1(sleeps_long, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1, "a second cancel by the same asker changes nothing");
    avra_clock_run_ends();
}

// A cancel is recorded with WHO ASKED: a task reads it back after the
// end, and the asker is the task that called `avra_task_cancel`.
static void* cancels_and_reads(void* self) {
    (void)self;
    avra_task_cancel(g_task);
    avra_task_settle(g_task);
    note(avra_task_ended_by(g_task));
    return answer(avra_task_id());
}

static void a_cancel_names_its_asker(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_task = spawn1(cancelled_sleeper, 0);
    g_log_len = 0;
    avra_fiber_sleep(2);
    int64_t asker = joined(spawn1(cancels_and_reads, 0));
    CHECK(avra_task_ended(g_task) == 2, "the cancelled task ended cancelled");
    CHECK(g_log_len == 1 && g_log[0] == asker, "and names the task that asked");
    CHECK(avra_task_ended_by(g_task) == asker, "as the row reads it back");
    avra_rc_release(g_task);
    avra_clock_run_ends();
}

// A body that returns names itself; a task nothing runs names whoever
// answered or cancelled it.
static void* notes_its_id(void* self) { (void)self; note(avra_task_id()); return answer(7); }
static void an_answer_names_the_task_itself(void) {
    g_log_len = 0;
    void* t = spawn1(notes_its_id, 0);
    avra_task_settle(t);
    CHECK(avra_task_ended(t) == 1 && g_log_len == 1 && avra_task_ended_by(t) == g_log[0], "a body that answered names itself");
    avra_rc_release(t);
}

static void* cancels_a_pending(void* self) {
    (void)self;
    g_pending = avra_task_pending();
    avra_task_cancel(g_pending);
    note(avra_task_ended_by(g_pending));
    return answer(avra_task_id());
}
static void a_fiberless_end_names_its_asker(void) {
    g_log_len = 0;
    void* t = spawn1(cancels_a_pending, 0);
    int64_t asker = joined(t);
    CHECK(g_log_len == 1 && g_log[0] == asker, "a task nothing runs names the task that cancelled it");
    avra_rc_release(g_pending);
}

// A FIBERLESS TASK THAT ANSWERS NAMES ITSELF: no cancel and no fiber
// reached it, so `task_ended` is the ended-by row's only writer.
static void* answers_a_pending(void* self) {
    (void)self;
    void* t = avra_task_pending();
    void* unit = answer(9);
    avra_task_answer(t, unit);
    avra_rc_release(unit);
    g_byte_a = avra_task_ended_by(t) == avra_task_id();
    avra_rc_release(t);
    return answer(0);
}

static void a_fiberless_answer_names_itself(void) {
    void* t = spawn1(answers_a_pending, 0);
    joined(t);
    CHECK(g_byte_a == 1, "a fiberless task that answered names itself in the ended-by row");
}

// ── one set at a time ───────────────────────────────────────────

static void* sleeps_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); avra_fiber_sleep(5); return answer(0); }
static void* joins_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); return answer(joined(spawn1(sleeper, 5))); }
static void* parks_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); return answer(avra_fiber_park_fd(g_pipe[0], 0, 5)); }
static void sleep_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(sleeps_in_a_set, 0)); }
static void join_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(joins_in_a_set, 0)); }
static void park_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(parks_in_a_set, 0)); }

// ── a time falls due on a set already claimed ───────────────────

// THE ORDER IS MADE, NOT WAITED FOR: under the virtual clock the time is
// far, the gate is claimed, and only then does the clock reach the time.
// Each such case is a run of its own, so the hour it jumps ends with it
// and the cases after it read the wall again.
static int64_t g_due_at = 0;
static void* gate_or_time(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 0, 1);
    g_due_at = avra_now_ns() + (int64_t)60000 * 1000000;
    avra_wait_until(g_due_at, 1, 2);
    int64_t claim = avra_wait_park();
    return answer(arm_of(claim) * 100 + member_of(claim) + avra_sched_timers() * 1000);
}

static void due_on_a_claimed_set(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_gate = avra_gate_new();
    void* t = spawn1(gate_or_time, 0);
    avra_fiber_yield();
    CHECK(avra_gate_claim(g_gate) == 1, "the gate claims first");
    CHECK(avra_clock_jumped(g_due_at) == 1, "and then the clock reaches the time");
    avra_fiber_yield();
    CHECK(joined(t) == 1, "a time due on a claimed set is dropped: the task resumes on the gate's arm, the heap empty");
    avra_rc_release(g_gate);
    avra_clock_run_ends();
}

// ── a forked child keeps no other task's waiters ────────────────

static void* waits_for_ever(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 0, 5);
    return answer(member_of(avra_wait_park()));
}

static void fork_forgets_gate_waiters(void) {
    g_gate = avra_gate_new();
    void* t = spawn1(waits_for_ever, 0);
    avra_fiber_sleep(2);
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        _exit(avra_gate_claim(g_gate) == -1 && !filed(g_gate) ? 0 : 1);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a forked child's gate holds none of the parent's waiters");
    CHECK(avra_gate_claim(g_gate) == 5, "the parent's waiter is still its own");
    CHECK(joined(t) == 5, "and it wakes");
    avra_rc_release(g_gate);
}

// ── tasks nothing runs ──────────────────────────────────────────

static void* waits_on_task(void* self) {
    (void)self;
    avra_wait_task(g_task, 4, 9);
    int64_t claim = avra_wait_park();
    return answer(arm_of(claim) * 100 + member_of(claim));
}

static void answers_twice(void) {
    void* t = avra_task_pending();
    void* v = answer(1);
    avra_task_answer(t, v);
    avra_task_answer(t, v);
}

static void fiberless_tasks(void) {
    int64_t live = avra_mem_live();
    g_task = avra_task_pending();
    void* w = spawn1(waits_on_task, 0);
    avra_fiber_sleep(2);
    CHECK(!avra_task_done(w), "a wait on a pending task waits");
    void* v = answer(77);
    avra_task_answer(g_task, v);
    avra_rc_release(v);
    CHECK(avra_task_done(g_task), "an answered task is done");
    CHECK(joined(w) == 409, "its waiter is claimed on its arm");
    avra_rc_retain(g_task);
    CHECK(joined(g_task) == 77, "and a join answers what it was answered");
    avra_rc_release(g_task);

    int64_t t0 = now_ns();
    g_task = avra_task_at(in_ms(8));
    w = spawn1(waits_on_task, 0);
    CHECK(joined(w) == 409 && now_ns() - t0 >= 7000000, "a task the timer heap completes wakes its waiter at its time");
    CHECK(avra_sched_timers() == 0, "and leaves the heap");
    avra_rc_release(g_task);

    g_task = avra_task_at(in_ms(60000));
    w = spawn1(waits_on_task, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(g_task);
    CHECK(avra_sched_timers() == 0, "a cancelled timer task leaves the heap at once");
    CHECK(joined(w) == 409, "its waiter is claimed");
    avra_task_cancel(g_task);
    avra_rc_release(g_task);
    CHECK(avra_mem_live() == live, "a cancelled timer task is reclaimed");

    avra_rc_release(avra_task_at(in_ms(3)));
    CHECK(avra_sched_timers() == 1, "a timer task nobody holds stays until its time");
    avra_fiber_sleep(8);
    CHECK(avra_sched_timers() == 0 && avra_mem_live() == live, "and is reclaimed when it fires");
    trapped("a task answered twice", answers_twice, "a task answered twice");
}

// ── a join takes a task that answers ────────────────────────────

// A TASK NOTHING RUNS, CANCELLED, PASSES ITS CANCEL ON ALIKE: the
// program's own run is the awaiter here, and keeps who asked.
static void joins_cancelled(void) {
    void* t = avra_task_pending();
    avra_task_cancel(t);
    CHECK(avra_task_join(t) == NULL && avra_unwinding == 1, "a join of a cancelled task nothing ran hands back nothing and sets the bit");
    CHECK(avra_main_asker == 1, "and the run's own record names who asked: itself");
}

// A CALLER ALREADY UNWINDING IS REFUSED NOTHING: its join of a
// cancelled task hands back no answer, and the cancel it carries stands.
static void* cut_then_joins_a_cancelled(void* self) {
    (void)self;
    avra_fiber_sleep(10000);
    void* r = avra_task_join(g_pending);
    g_byte_b = r == NULL;
    g_byte_a = avra_unwinding;
    return answer(0);
}

static void standing_join_of_cancelled(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    g_pending = avra_task_pending();
    avra_task_cancel(g_pending);
    void* t = spawn1(cut_then_joins_a_cancelled, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1 && g_byte_b == 1, "an unwinding caller's join of a cancelled task hands back nothing and traps nothing");
    avra_rc_release(g_pending);
    avra_clock_run_ends();
}

static void joins_of_tasks_nothing_runs(void) {
    int64_t live = avra_mem_live();
    void* t = avra_task_at(in_ms(2));
    avra_rc_retain(t);
    CHECK(joined(t) == 0, "a fired timer task joins to a unit box");
    avra_rc_retain(t);
    CHECK(joined(t) == 0, "and to the same box again");
    avra_rc_release(t);
    CHECK(avra_mem_live() == live, "the box leaves with its record");

    t = avra_task_pending();
    avra_task_cancel(t);
    avra_task_settle(t);
    CHECK(avra_task_done(t), "a settle of a cancelled task returns");
    avra_rc_release(t);
    CHECK(avra_mem_live() == live, "and leaves nothing");
}

// ── the trace names a virtual task by its machine's id ──────────

static void* answers_cap(void* body) { return answer(cap(body)); }

// Run alone, in a process started with the trace on.
static int traced_scene(void) {
    if (joined(spawn1(answers_cap, 3)) != 3) return 1;
    void* gate = avra_gate_new();
    int64_t claimant = avra_vtask_new_at(7, 41);
    int64_t waiter = avra_vtask_new_at(8, 42);
    avra_vtask_wait_gate(waiter, gate, 0, 5);
    if (avra_vtask_park(waiter) != 1) return 1;
    if (avra_vgate_claim(claimant, gate) != 5) return 1;
    if (avra_vgate_claim(claimant, gate) != -1) return 1;
    if (avra_vtask_next() != waiter) return 1;
    avra_vtask_claim(waiter);
    avra_vtask_end(waiter);
    int64_t joiner = avra_vtask_new_at(9, 43);
    avra_vtask_joins(joiner, 41);
    avra_vtask_joins(joiner, -2);
    avra_vtask_end(joiner);
    void* end = avra_gate_new();
    int64_t gated = avra_vtask_new_at(10, 44);
    avra_vtask_joins(gated, 41);
    if (avra_vtask_join(gated, end) != 1) return 1;
    avra_vgate_ended(end, 41);
    if (avra_vtask_next() != gated) return 1;
    avra_vtask_end(gated);
    avra_rc_release(end);
    avra_vtask_free(claimant);
    avra_rc_release(gate);
    return 0;
}

// Task bodies with a row in the site table, as the backend files one.
// Spawned and never run.
static void* sited_body(void* body) { return answer(cap(body)); }
static void* other_sited(void* body) { return answer(cap(body) + 1); }
#if defined(__APPLE__)
#define SITES_SECTION AVRA_SITES_MACHO_SEGMENT "," AVRA_SITES_MACHO_SECTION
#else
#define SITES_SECTION AVRA_SITES_ELF_SECTION
#endif
__attribute__((used, section(SITES_SECTION))) static const AvraSiteRow g_sited = { (const void*)sited_body, "pkg/main.av:7" };
__attribute__((used, section(SITES_SECTION))) static const AvraSiteRow g_other_sited = { (const void*)other_sited, "pkg/two.av:12" };

// Run alone, traced: a task whose code carries a site, one whose code
// carries none, and a virtual task told its own.
static int sited_scene(void) {
    spawn1(sited_body, 0);
    spawn1(answers_cap, 0);
    spawn1(other_sited, 0);
    avra_vtask_sited(avra_vtask_new_at(0, 51), "pkg/other.av:3");
    return 0;
}

// What `scene` wrote to its trace, run alone in a process started with
// the trace on; its exit status.
static int traced_run(const char* self, const char* scene, char* buf, size_t cap) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        setenv("AVRA_FLOW_TRACE", "1", 1);
        execl(self, self, scene, (char*)NULL);
        _exit(9);
    }
    close(out[1]);
    memset(buf, 0, cap);
    size_t got = 0;
    for (ssize_t n; got < cap - 1 && (n = read(out[0], buf + got, cap - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    return status;
}

static void trace_names_sites(const char* self) {
    char buf[4096];
    int status = traced_run(self, "sited-scene", buf, sizeof buf);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "the sited scene runs");
    CHECK(strstr(buf, "site id=1 pkg/main.av:7\n") != NULL, "a task whose body has a row is traced by its source line");
    CHECK(strstr(buf, "site id=2 0x") != NULL, "a task whose body has none is traced by its address");
    CHECK(strstr(buf, "site id=3 pkg/two.av:12\n") != NULL, "each body by its own row");
    CHECK(strstr(buf, "site id=51 pkg/other.av:3\n") != NULL, "a virtual task is traced by the line its machine names");
}

static void trace_names_virtual_tasks(const char* self) {
    char buf[4096];
    int status = traced_run(self, "traced-scene", buf, sizeof buf);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "the traced scene runs");
    CHECK(strstr(buf, "spawn-at id=42 8") != NULL, "a virtual task is traced under the id it was given, at its site");
    CHECK(strstr(buf, "claim id=42 by=41 arm=0:5") != NULL, "a virtual claim names the virtual claimant");
    CHECK(strstr(buf, "end id=42 0") != NULL, "a virtual task's end is traced");
    CHECK(strstr(buf, "end id=41") == NULL, "and a task freed unfinished says no end");
    CHECK(strstr(buf, "join id=0 on=1\n") != NULL, "a compiled join names the task it waits for");
    CHECK(strstr(buf, "claim id=0 by=1 arm=0:0") != NULL, "and the joined task's end claims the joiner");
    CHECK(strstr(buf, "join id=43 on=41\n") != NULL, "a virtual join names the task it waits for");
    CHECK(strstr(buf, "join id=43 on=unrun") != NULL, "a join of a task nothing runs says so");
    CHECK(strstr(buf, "claim id=44 by=41 arm=0:0") != NULL, "a join parked on a task's end gate is claimed under the task that ended");
}

// ── more waiters than a fiber holds inline ──────────────────────

static void* six_gates(void* self) {
    (void)self;
    for (int i = 0; i < 6; i++) avra_wait_gate(g_gates[i], i, i * 10);
    int64_t claim = avra_wait_park();
    return answer(arm_of(claim) * 100 + member_of(claim));
}

static void overflow_list(void) {
    int64_t live = avra_mem_live();
    for (int i = 0; i < 6; i++) g_gates[i] = avra_gate_new();
    void* t = spawn1(six_gates, 0);
    avra_fiber_sleep(2);
    int all = 1;
    for (int i = 0; i < 6; i++) all = all && filed(g_gates[i]);
    CHECK(all, "six waiters are filed, two past the four a fiber holds");
    CHECK(avra_gate_claim(g_gates[5]) == 50, "the sixth is claimed");
    CHECK(joined(t) == 550, "and wakes the task on its arm");
    int none = 1;
    for (int i = 0; i < 6; i++) { none = none && !filed(g_gates[i]); avra_rc_release(g_gates[i]); }
    CHECK(none, "the five losers are retracted");
    CHECK(avra_mem_live() == live, "and nothing of the set is kept");
}

// ── overflow waiters come from one list, and go back to it ──────

// Files `n` waiters on gates nobody opens and one on an open gate, and
// parks: the open one claims, and the rest are retracted.
static void files_and_parks(void** gates, int n, void* open) {
    for (int i = 0; i < n; i++) avra_wait_gate(gates[i], 0, i);
    avra_wait_gate(open, 1, 0);
    avra_wait_park();
}

static void overflow_waiters_are_kept_and_trimmed(void) {
    enum { MANY = 200 };
    void* gates[MANY];
    for (int i = 0; i < MANY; i++) gates[i] = avra_gate_new();
    void* open = avra_gate_new();
    avra_vgate_open(open);
    CHECK(avra_sched_waiters_kept() == 0, "none is kept before any is filed");
    files_and_parks(gates, 6, open);
    CHECK(avra_sched_waiters_kept() == 2, "a set of six gives its two past the fiber's four back to the list");
    files_and_parks(gates, 6, open);
    CHECK(avra_sched_waiters_kept() == 2, "the next set of six takes those two and gives them back: nothing more is made");
    files_and_parks(gates, MANY, open);
    CHECK(avra_sched_waiters_kept() == MANY - 4, "the list grows to the widest set filed at once");
    avra_fiber_sleep(2);
    CHECK(avra_sched_waiters_kept() == 64, "where the world idles it is cut back to its floor");
    for (int i = 0; i < MANY; i++) avra_rc_release(gates[i]);
    avra_rc_release(open);
}

// ── a gate opened for ever ──────────────────────────────────────

static void opened_gate(void) {
    g_gate = avra_gate_new();
    void* t = spawn1(waits_for_ever, 0);
    avra_fiber_sleep(2);
    avra_vgate_open(g_gate);
    CHECK(joined(t) == 5, "an opened gate wakes its waiter");
    avra_wait_gate(g_gate, 6, 3);
    CHECK(!filed(g_gate), "a wait on an open gate files nothing");
    int64_t claim = avra_wait_park();
    CHECK(arm_of(claim) == 6 && member_of(claim) == 3, "and is claimed at once, without a switch");
    avra_rc_release(g_gate);
}

// ── the deadline, armed at the first wait under it ──────────────

static void* claims_when_filed(void* self) {
    int64_t most = 0;
    for (int64_t i = 0; i < cap(self);) {
        if (avra_sched_timers() > most) most = avra_sched_timers();
        if (avra_gate_claim(g_gate) >= 0) i++;
        avra_fiber_yield();
    }
    return answer(most);
}

static void deadline_once(void) {
    int64_t outer = avra_fiber_within(10000);
    CHECK(avra_sched_timers() == 0, "a `within` nothing waits under files no timer");
    g_gate = avra_gate_new();
    void* helper = spawn1(claims_when_filed, 50);
    int ok = 1;
    for (int i = 0; i < 50; i++) {
        avra_wait_gate(g_gate, 0, i);
        ok = ok && member_of(avra_wait_park()) == i;
    }
    CHECK(ok, "fifty waits under one `within` are each claimed");
    CHECK(joined(helper) == 1, "and file its deadline once");
    CHECK(avra_sched_timers() == 1, "which stays filed while the scope stands");
    avra_fiber_within_end(outer);
    CHECK(avra_sched_timers() == 0, "and leaves with the scope");

    outer = avra_fiber_within(5);
    avra_wait_gate(g_gate, 0, 0);
    int64_t claim = avra_wait_park();
    CHECK(arm_of(claim) == -1 && member_of(claim) == 1, "a deadline that passes while its task waits claims the set");
    CHECK(!filed(g_gate), "and the wait it cut short is retracted");
    avra_wait_gate(g_gate, 0, 0);
    claim = avra_wait_park();
    CHECK(arm_of(claim) == -1 && member_of(claim) == 1, "a wait under a passed deadline answers it at once");
    avra_fiber_within_end(outer);

    outer = avra_fiber_within(0);
    CHECK(write(g_pipe[1], "y", 1) == 1, "the pipe takes a byte");
    avra_wait_fd(g_pipe[0], 0, 0, 0);
    claim = avra_wait_park();
    CHECK(arm_of(claim) == -1, "a deadline already past is heard before a descriptor that is ready");
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "the byte is still there");
    avra_fiber_within_end(outer);
    CHECK(avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0, "nothing stays filed");
    avra_rc_release(g_gate);
}

// ── the per-task slots ──────────────────────────────────────────

static void* reads_slots(void* self) {
    (void)self;
    void* inherited = avra_task_slot(0);
    void* mine = answer(5);
    avra_task_slot_set(1, mine);
    avra_rc_release(mine);
    void* back = avra_task_slot(1);
    int64_t seen = (inherited == NULL) * 100 + (back == mine) * 10;
    avra_rc_release(back);
    avra_fiber_yield();
    g_seen = avra_task_id();
    return answer(seen);
}
static void* its_id(void* self) { (void)self; avra_fiber_yield(); return answer(avra_task_id()); }
static void slot_out_of_range(void) { avra_task_slot(4); }

static void slots(void) {
    int64_t live = avra_mem_live();
    void* held = answer(9);
    avra_task_slot_set(0, held);
    avra_rc_release(held);
    CHECK(avra_task_id() == 0, "main's id is 0");
    void* t = spawn1(reads_slots, 0);
    void* u = spawn1(its_id, 0);
    int64_t other = joined(u);
    CHECK(joined(t) == 110, "a task's slots start empty, and hold what it sets");
    CHECK(g_seen != 0 && other != 0 && g_seen != other, "each task has an id of its own");
    void* still = avra_task_slot(0);
    CHECK(still == held, "main's slot is main's, whoever ran meanwhile");
    avra_rc_release(still);
    void* none = avra_task_slot(1);
    CHECK(none == NULL, "and a task's slot is not main's");
    avra_task_slot_set(0, NULL);
    CHECK(avra_mem_live() == live, "a task's slots are released when it ends");
    trapped("a slot past the table", slot_out_of_range, "a task has four slots");
}

// ── a task that ends with a wait it never parked on ─────────────

static void* arms_gate_and_ends(void* self) { (void)self; avra_wait_gate(g_gate, 1, 42); return answer(0); }
static void* arms_time_and_ends(void* self) { (void)self; avra_wait_until(in_ms(10), 3, 9); return answer(0); }

static void ends_without_parking(void) {
    int64_t live = avra_mem_live();
    g_gate = avra_gate_new();
    joined(spawn1(arms_gate_and_ends, 0));
    CHECK(!filed(g_gate), "a task that ends takes the gate wait it never parked on with it");
    void* s = spawn1(sleeper, 30);
    avra_fiber_sleep(2);
    CHECK(avra_gate_claim(g_gate) == -1, "the gate has no waiter of a task that is gone");
    CHECK(joined(s) >= 29, "and the next task to take its record sleeps its whole sleep");
    avra_rc_release(g_gate);
    CHECK(avra_mem_live() == live, "nothing of the ended task's wait is kept");

    joined(spawn1(arms_time_and_ends, 0));
    CHECK(avra_sched_timers() == 0, "a task that ends takes the time it never parked on out of the heap");
    CHECK(joined(spawn1(sleeper, 40)) >= 39, "and the next task to take its record is not woken by it");
    CHECK(avra_sched_timers() == 0, "the heap is empty after");
}

// ── the deadline, where it must and must not reach ──────────────

// Parks once under a `within` it never closes, then ends.
static void* ends_inside_within(void* self) {
    (void)self;
    avra_fiber_within(60000);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    return answer(0);
}

// A real wait files the deadline; a sleep or a join after it, running
// past the deadline, is cut short by it. The joined task is spawned
// before the scope, so it inherits no limit and sleeps its whole sleep.
static void* sleeps_past_deadline(void* self) {
    void* slow = cap(self) ? spawn1(sleeper, 40) : NULL;
    int64_t outer = avra_fiber_within(15);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    int64_t t0 = now_ns();
    if (slow) joined(slow); else avra_fiber_sleep(40);
    int64_t ms = (now_ns() - t0) / 1000000;
    avra_fiber_within_end(outer);
    return answer(ms);
}

static void* waits_reports(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 0, 5);
    int64_t claim = avra_wait_park();
    return answer(arm_of(claim) * 100 + member_of(claim));
}

static void deadline_reach(void) {
    g_gate = avra_gate_new();
    void* t = spawn1(ends_inside_within, 0);
    avra_fiber_sleep(2);
    CHECK(avra_sched_timers() == 1, "a wait under a `within` files the deadline");
    CHECK(avra_gate_claim(g_gate) == 0, "the waiter is claimed");
    joined(t);
    CHECK(avra_sched_timers() == 0, "a task that ends inside its `within` takes its deadline out of the heap");

    for (int joins = 0; joins < 2; joins++) {
        t = spawn1(sleeps_past_deadline, joins);
        avra_fiber_sleep(2);
        CHECK(avra_gate_claim(g_gate) == 0, "the task under the deadline is claimed");
        avra_fiber_sleep(45);
        CHECK(joined(t) < 39, joins ? "a deadline filed by an earlier wait cuts a join short" : "a deadline filed by an earlier wait cuts a sleep short");
    }
    CHECK(avra_sched_timers() == 0, "and leaves the heap with its scope");

    int64_t outer = avra_fiber_within(8);
    t = spawn1(waits_reports, 0);
    avra_fiber_within_end(outer);
    CHECK(ended(t) == 2, "a task inherits its spawner's deadline: its wait is cut when that passes");
    CHECK(!filed(g_gate), "and the wait the deadline cut short is retracted");
    avra_rc_release(g_gate);
}

// A parked task's deadline is another task's: a forked child keeps none of it.
static void fork_forgets_deadlines(void) {
    g_gate = avra_gate_new();
    void* t = spawn1(ends_inside_within, 0);
    avra_fiber_sleep(2);
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        _exit(avra_sched_timers() == 0 ? 0 : 1);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a forked child's heap holds no other task's deadline");
    CHECK(avra_gate_claim(g_gate) == 0, "the parent's task is still parked");
    joined(t);
    avra_rc_release(g_gate);
}

// ── a claim another party made while the set armed is heard before a
//    standing cancel; an arm the task found ready itself is not ──────

// Cut once, then two waits under the cancel that stands: `self`'s cap
// says whether the second set's waiter is claimed through its gate
// before the park.
static void* cancelled_then_armed(void* self) {
    avra_wait_gate(g_gate, 3, 7);
    note(arm_of(avra_wait_park()));
    avra_wait_gate(g_gates[0], 5, 8);
    if (cap(self)) note(avra_gate_claim(g_gates[0]));
    int64_t second = avra_wait_park();
    note(arm_of(second) * 100 + member_of(second));
    avra_wait_gate(g_gate, 3, 7);
    note(arm_of(avra_wait_park()));
    return answer(0);
}

static void claim_before_cancel(void) {
    g_log_len = 0;
    g_gate = avra_gate_new();
    g_gates[0] = avra_gate_new();
    void* t = spawn1(cancelled_then_armed, 1);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    ended(t);
    int64_t handed[] = { -1, 8, 508, -1 };
    CHECK(logged(handed, 4), "under a standing cancel a waiter claimed through its gate while the set armed answers that claim, and the next wait answers the cancel");
    avra_rc_release(g_gates[0]);

    g_log_len = 0;
    g_gates[0] = avra_gate_new();
    avra_vgate_open(g_gates[0]);
    t = spawn1(cancelled_then_armed, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    ended(t);
    int64_t found[] = { -1, -100, -1 };
    CHECK(logged(found, 3), "under a standing cancel an arm the task found ready as it armed answers the cancel");
    avra_rc_release(g_gate);
    avra_rc_release(g_gates[0]);
}

// ── a task whose every wait finds an arm ready hears a cancel and a
//    limit all the same ──────────────────────────────────────────────

static void* ended_task(void) {
    void* t = avra_task_pending();
    void* unit = answer(0);
    avra_task_answer(t, unit);
    avra_rc_release(unit);
    return t;
}

enum { BUSY_TURNS = 20000000 };
static int64_t g_busy_turns;

// Waits on an ended task, over and over, with no back-edge check: only
// the park can hear anything.
static void* always_ready(void* self) {
    (void)self;
    void* done = ended_task();
    avra_fiber_yield();
    for (g_busy_turns = 0; g_busy_turns < BUSY_TURNS; g_busy_turns++) {
        avra_wait_task(done, 0, 0);
        g_byte_b = avra_wait_park();
        if (arm_of(g_byte_b) == -1) break;
    }
    g_byte_a = avra_unwinding;
    avra_rc_release(done);
    return answer(0);
}

static void a_ready_arm_hears_a_cancel(void) {
    bytes_unseen();
    void* t = spawn1(always_ready, 0);
    avra_fiber_yield();
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a task cancelled while its every wait finds an arm ready ends cancelled");
    CHECK(g_busy_turns == 0 && g_byte_b == (int64_t)0xffffffff00000000LL && g_byte_a == 1, "the cancel is heard at its first wait: -1:0, the bit set");
}

static int g_fed[2];
static void* reads_what_is_fed(void* self) {
    (void)self;
    char b;
    while (read(g_fed[0], &b, 1) != 1) avra_fiber_park_fd(g_fed[0], 0, -1);
    return answer(0);
}

// A reader's byte is there while the one running task waits on an ended
// task over and over: its turns ask the poller, and the reader is
// readied within a window of them.
static void a_ready_arms_turns_ask_the_poller(void) {
    if (pipe(g_fed) != 0) { CHECK(0, "a pipe"); return; }
    fcntl(g_fed[0], F_SETFL, O_NONBLOCK);
    void* reader = spawn1(reads_what_is_fed, 0);
    avra_fiber_yield();
    CHECK(avra_sched_fd_waiters() == 1, "the reader waits on its descriptor");
    CHECK(write(g_fed[1], "x", 1) == 1, "its byte is written");
    void* done = ended_task();
    int64_t turns = 0;
    while (avra_sched_fd_waiters() != 0 && turns < 100000) {
        avra_wait_task(done, 0, 0);
        avra_wait_park();
        turns++;
    }
    CHECK(avra_sched_fd_waiters() == 0 && turns <= 64, "waits that switch to nobody ask the poller within a window of turns, and the reader is readied");
    avra_rc_release(done);
    joined(reader);
    closed(g_fed[0]);
    closed(g_fed[1]);
}

// The program's own task, alone, under a limit that passes while it
// waits on an ended task over and over: nothing switches, so the turns
// themselves must ask the heap.
static void a_ready_arm_hears_a_limit(void) {
    void* done = ended_task();
    int64_t t0 = avra_now_ns();
    int64_t scope = avra_fiber_within(50);
    int64_t claim = 0, turns = 0;
    while (turns < (int64_t)1 << 40) {
        avra_wait_task(done, 0, 0);
        claim = avra_wait_park();
        turns++;
        if (arm_of(claim) == -1 || ((turns & 0xffff) == 0 && ms_since(t0) > 2000)) break;
    }
    int64_t spent = ms_since(t0);
    CHECK(claim == (int64_t)0xffffffff00000001LL, "a limit that passes while every wait finds an arm ready is heard: -1:1");
    CHECK(turns > 1 && spent >= 45 && spent < 1000, "where it passes, after the waits before it answered their arm");
    avra_fiber_within_end(scope);
    avra_rc_release(done);

    done = ended_task();
    scope = avra_fiber_within(0);
    avra_wait_task(done, 0, 0);
    CHECK(avra_wait_park() == (int64_t)0xffffffff00000001LL, "a limit already passed is heard at the first wait, over an arm ready as it armed");
    avra_fiber_within_end(scope);
    avra_rc_release(done);
}

// ── the scan chooses, the park only wakes ───────────────────────

// Every end that answered draws the next stamp, whoever ended it; a
// live task and one that ended cancelled read 0.
static void stamps_follow_the_ends(void) {
    void* live = avra_task_pending();
    void* first = ended_task();
    void* ran = spawn1(answers_cap, 3);
    avra_fiber_yield();
    void* timed = avra_task_at(1);
    avra_fiber_sleep(2);
    void* last = ended_task();
    void* cut = avra_task_pending();
    avra_task_cancel(cut);
    void* cut_running = spawn1(sleeper, 10000);
    avra_fiber_yield();
    avra_task_cancel(cut_running);
    avra_task_settle(cut_running);
    CHECK(avra_task_since(live) == 0, "a live task is not ready");
    CHECK(avra_task_since(first) > 0, "an answered task's stamp is above zero");
    CHECK(avra_task_since(first) < avra_task_since(ran) && avra_task_since(ran) < avra_task_since(timed) && avra_task_since(timed) < avra_task_since(last),
        "each end that answered — another's answer, a body's own, a timer's — draws the next stamp");
    CHECK(avra_task_done(cut) == 1 && avra_task_since(cut) == 0, "a task nothing ran that ended cancelled is done and never ready");
    CHECK(avra_task_ended(cut_running) == 2 && avra_task_since(cut_running) == 0, "and so is one whose body was cut");
    avra_task_cancel(live);
    void* all[] = { live, first, ran, timed, last, cut, cut_running };
    for (size_t i = 0; i < sizeof all / sizeof all[0]; i++) avra_rc_release(all[i]);
}

// A time is ready once it has come, before every task; one scan reads
// the clock once, and the next reads it afresh.
static void a_due_time_is_ready_first(void) {
    int64_t soon = avra_now_ns() + 20 * 1000000;
    CHECK(avra_wait_enter("pkg/main.av:7") == 0, "a scan begins with nothing standing");
    CHECK(avra_time_since(avra_now_ns() - 1) < 0, "a time that has come is ready, below every task's stamp");
    CHECK(avra_time_since(soon) == 0, "a time to come is not");
    avra_fiber_sleep(30);
    CHECK(avra_time_since(soon) == 0, "one scan reads the clock once: a time that came since is not seen by it");
    CHECK(avra_wait_enter("pkg/main.av:7") == 0 && avra_time_since(soon) < 0, "and the next scan sees it");
}

static void* scans_for_ever(void* self) {
    (void)self;
    void* done = ended_task();
    avra_fiber_yield();
    for (g_busy_turns = 0; g_busy_turns < BUSY_TURNS; g_busy_turns++) {
        g_byte_b = avra_wait_enter("pkg/main.av:7");
        if (g_byte_b != 0 || !avra_task_since(done)) break;
    }
    g_byte_a = avra_unwinding;
    avra_rc_release(done);
    return answer(0);
}

static void a_scan_hears_a_cancel(void) {
    bytes_unseen();
    void* t = spawn1(scans_for_ever, 0);
    avra_fiber_yield();
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a task cancelled while every scan finds an arm ready ends cancelled");
    CHECK(g_busy_turns == 0 && g_byte_b == (int64_t)0xffffffff00000000LL && g_byte_a == 1, "its next scan answers the cancel before any arm: -1:0, the bit set");
}

// The program's own task, alone, scanning an arm that is always ready
// under a limit that passes: no park, no switch, no back-edge.
static void a_scan_hears_a_limit(void) {
    void* done = ended_task();
    int64_t t0 = avra_now_ns();
    int64_t scope = avra_fiber_within(50);
    int64_t word = 0, turns = 0;
    while (turns < (int64_t)1 << 40) {
        word = avra_wait_enter("pkg/main.av:7");
        turns++;
        if (word != 0 || !avra_task_since(done) || ((turns & 0xffff) == 0 && ms_since(t0) > 2000)) break;
    }
    int64_t spent = ms_since(t0);
    CHECK(word == (int64_t)0xffffffff00000001LL, "a limit that passes while every scan finds an arm ready is heard: -1:1");
    CHECK(turns > 1 && spent >= 45 && spent < 1000, "where it passes");
    CHECK(avra_unwinding == 1, "a limit met at a scan is a cut: the bit is raised");
    avra_fiber_within_end(scope);
    avra_rc_release(done);
}

static void* answers_low_then_high(void* self) {
    (void)self;
    void* unit = answer(0);
    avra_task_answer(g_pending, unit);
    avra_task_answer(g_task, unit);
    avra_rc_release(unit);
    return answer(0);
}

// PRIORITY HOLDS AT THE WAKE: parked on an upper and a lower arm, the
// lower ends first and claims the set, the upper ends before the task
// runs again — the claim names the lower, and the scan finds the upper.
static void the_scan_outranks_the_claim(void) {
    g_task = avra_task_pending();
    g_pending = avra_task_pending();
    void* ender = spawn1(answers_low_then_high, 0);
    CHECK(avra_wait_enter("pkg/main.av:7") == 0 && avra_task_since(g_task) == 0 && avra_task_since(g_pending) == 0, "the first scan finds neither arm ready");
    avra_wait_task(g_task, 0, 0);
    avra_wait_task(g_pending, 1, 0);
    int64_t claim = avra_wait_rest();
    CHECK(arm_of(claim) == 1, "the arm that ended first claims the park: the lower");
    CHECK(avra_wait_enter("pkg/main.av:7") == 0 && avra_task_since(g_task) != 0, "and the scan from the top finds the upper ready");
    CHECK(avra_task_since(g_pending) < avra_task_since(g_task), "the stamps keep the order the two ended in");
    joined(ender);
    avra_rc_release(g_task);
    avra_rc_release(g_pending);
}

static void* cancels_then_answers(void* self) {
    (void)self;
    avra_task_cancel(g_task);
    avra_fiber_sleep(2);
    void* unit = answer(0);
    avra_task_answer(g_pending, unit);
    avra_rc_release(unit);
    return answer(0);
}

// A member cancelled while the task is parked on it wakes the park
// once and is passed over: it is never ready, and no longer live to be
// filed on. Armed all the same, an ended task claims at once, every turn.
static void a_cancelled_member_is_passed_over(void) {
    g_task = avra_task_pending();
    g_pending = avra_task_pending();
    void* members[] = { g_task, g_pending };
    void* other = spawn1(cancels_then_answers, 0);
    int taken = -1, parks = 0;
    while (taken < 0 && parks < 10 && avra_wait_enter("pkg/main.av:7") == 0) {
        for (int i = 0; i < 2 && taken < 0; i++) if (avra_task_since(members[i])) taken = i;
        if (taken >= 0) break;
        for (int i = 0; i < 2; i++) if (!avra_task_done(members[i])) avra_wait_task(members[i], 0, i);
        avra_wait_rest();
        parks++;
    }
    CHECK(taken == 1 && parks == 2, "the member that answered is taken after two parks: the cancelled one's end woke the first");
    avra_wait_task(g_task, 0, 0);
    CHECK(avra_wait_park() == 0, "armed all the same, a cancelled member claims at once");
    joined(other);
    avra_rc_release(g_task);
    avra_rc_release(g_pending);
}

// The oldest of `n` stamps: the least that is not 0, or -1.
static int oldest(const int64_t* since, int n) {
    int best = -1;
    for (int i = 0; i < n; i++) if (since[i] != 0 && (best < 0 || since[i] < since[best])) best = i;
    return best;
}

// TIMES THAT HAVE COME GO FIRST, THE EARLIER INSTANT AHEAD: beside a
// task that answered long before, and whichever is asked first.
static void due_times_go_first(void) {
    void* done = ended_task();
    int64_t now = avra_now_ns();
    CHECK(avra_wait_enter("pkg/main.av:7") == 0, "a scan begins");
    int64_t since[] = { avra_task_since(done), avra_time_since(now - 1000), avra_time_since(now - 5000), avra_time_since(now + 5000000000LL) };
    CHECK(since[3] == 0, "a time to come is not ready");
    CHECK(oldest(since, 4) == 2, "of a task that answered and two times that have come, the earlier time is the oldest");
    since[2] = 0;
    CHECK(oldest(since, 4) == 1, "then the later time, still ahead of the task");
    avra_rc_release(done);
}

// A DRAWN STAMP QUEUES WITH THE EVENTS: behind the task that answered
// before it was drawn, ahead of the one that answered after.
static void a_drawn_stamp_queues_with_the_events(void) {
    void* before = ended_task();
    int64_t drawn = avra_stamp_next();
    void* after = ended_task();
    CHECK(avra_task_since(before) < drawn && drawn < avra_task_since(after), "a stamp drawn between two answers stands between them");
    CHECK(avra_stamp_next() > avra_task_since(after), "and the next drawn is the newest");
    avra_rc_release(before);
    avra_rc_release(after);
}

// OLDEST-READY FIRST HAS A HARD BOUND: with every arm ready and each
// taken arm made ready anew — its stamp the newest — no arm is passed
// over more than arms - 1 times, and each is passed over that often.
static void oldest_ready_is_bounded(void) {
    enum { ARMS = 5, TURNS = 10000 };
    void* arm[ARMS];
    int passed[ARMS] = {0}, most = 0, least = ARMS;
    for (int i = 0; i < ARMS; i++) arm[i] = ended_task();
    for (int turn = 0; turn < TURNS; turn++) {
        int64_t since[ARMS];
        for (int i = 0; i < ARMS; i++) since[i] = avra_task_since(arm[i]);
        int a = oldest(since, ARMS);
        if (turn >= ARMS) { if (passed[a] > most) most = passed[a]; if (passed[a] < least) least = passed[a]; }
        for (int i = 0; i < ARMS; i++) passed[i] += i != a;
        passed[a] = 0;
        avra_rc_release(arm[a]);
        arm[a] = ended_task();
    }
    CHECK(most == ARMS - 1, "no ready arm is passed over more than arms - 1 times in ten thousand turns");
    CHECK(least == ARMS - 1, "and none is taken sooner: the oldest goes first every turn");
    for (int i = 0; i < ARMS; i++) avra_rc_release(arm[i]);
}

// ── on one instant the scope wins ───────────────────────────────

// A limit and an arm's time on one instant, parked on once: the claim.
// `waited_before` puts an earlier park under the scope, so the limit's
// waiter is the older entry in the heap.
static int64_t tied(int waited_before) {
    int64_t at = avra_now_ns() + 5000LL * 1000000;
    int64_t scope = avra_fiber_within(5000);
    if (waited_before) {
        avra_wait_until(avra_now_ns() + 1000000, 7, 0);
        avra_wait_park();
    }
    avra_wait_until(at, 0, 0);
    int64_t claim = avra_wait_park();
    avra_fiber_within_end(scope);
    return claim;
}

static void a_limit_wins_its_instant(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    CHECK(tied(0) == (int64_t)0xffffffff00000001LL, "a limit and an arm's time on one instant, the arm filed first: the limit answers");
    CHECK(tied(1) == (int64_t)0xffffffff00000001LL, "and the same when the limit was filed first");
    avra_clock_run_ends();
}

// Counted text, as a program's own would be.
const char* avra_int_text(int64_t v);

// A SITE THAT IS COUNTED TEXT IS KEPT BY THE RECORD: the writer gives
// its own reference up and the text stands; the next site, and the
// task's end, let it go.
static void* scans_under_owned_text(void* self) {
    (void)self;
    const char* site = avra_int_text(4242);
    avra_wait_enter(site);
    avra_rc_release((void*)site);
    return answer(0);
}

static void a_counted_site_is_kept(void) {
    int64_t live = avra_mem_live();
    const char* site = avra_int_text(4242);
    CHECK(avra_mem_live() > live, "the text is counted");
    CHECK(avra_wait_enter(site) == 0, "a scan begins under it");
    avra_rc_release((void*)site);
    CHECK(avra_mem_live() > live, "its writer lets go and the record still holds it");
    CHECK(avra_wait_enter(site) == 0 && avra_mem_live() > live, "the same site again takes nothing more");
    CHECK(avra_wait_enter("pkg/main.av:7") == 0 && avra_mem_live() == live, "the next site lets it go");
    joined(spawn1(scans_under_owned_text, 0));
    avra_fiber_yield();
    CHECK(avra_mem_live() == live, "and a task's end lets go of the site it held");
}

static void rests_on_nothing(void) {
    if (avra_wait_enter("pkg/main.av:7") == 0) avra_wait_rest();
}

static void scans_inside_a_set(void) {
    g_gate = avra_gate_new();
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_enter("pkg/main.av:7");
}

// ── an interrupt reads as time, not readiness ───────────────────

static void* parks_on_pipe(void* self) { (void)self; return answer(avra_fiber_park_fd(g_pipe[0], 0, -1)); }

// A descriptor park, and whether it was interrupted: 10 + the latter
// when the park answered 0, else the park's own answer.
static void* parks_and_tells(void* self) {
    int64_t woken = avra_fiber_park_fd(g_pipe[0], 0, cap(self));
    return answer(woken ? woken : 10 + avra_fiber_interrupted());
}

// Under a scope of its own, the interrupt asks nothing of it.
static void* parks_under_a_scope(void* self) {
    (void)self;
    int64_t scope = avra_fiber_within(5000);
    int64_t woken = avra_fiber_park_fd(g_pipe[0], 0, -1);
    int64_t landed = avra_scope_end(scope);
    return answer(woken == 0 && avra_fiber_interrupted() == 1 && landed == 0);
}

// Interrupted once, then a park a passed deadline cuts at once: its
// scope lands the unwind.
static void* interrupted_then_late(void* self) {
    (void)self;
    avra_fiber_park_fd(g_pipe[0], 0, -1);
    int64_t first = avra_fiber_interrupted();
    int64_t scope = avra_fiber_within(0);
    int64_t woken = avra_fiber_park_fd(g_pipe[0], 0, -1);
    int64_t landed = avra_fiber_within_end(scope);
    return answer(first == 1 && woken == 0 && landed == 1 && avra_fiber_interrupted() == 0);
}

static void* waits_on_the_pipe(void* self) {
    (void)self;
    avra_wait_fd(g_pipe[0], 0, 0, 0);
    return answer(avra_wait_park());
}

// AN INTERRUPT IS NOT A DEADLINE: its own claim, `-1:2`. A descriptor
// park still answers 0 for it, and says it was interrupted.
static void interrupt_is_its_own_claim(void) {
    void* t = spawn1(parks_and_tells, -1);
    avra_fiber_sleep(2);
    avra_fiber_fd_interrupt(g_pipe[0]);
    CHECK(joined(t) == 11, "a descriptor park that is interrupted answers 0, and says it was interrupted");
    CHECK(avra_sched_fd_waiters() == 0, "and leaves the descriptor");
    CHECK(joined(spawn1(parks_and_tells, 5)) == 10, "one whose own time ran out says it was not");
    int64_t scope = avra_fiber_within(5);
    t = spawn1(parks_and_tells, -1);
    avra_scope_end(scope);
    CHECK(ended(t) == 2, "one an inherited deadline ended is cut: its task ends cancelled");
    t = spawn1(parks_under_a_scope, 0);
    avra_fiber_sleep(2);
    avra_fiber_fd_interrupt(g_pipe[0]);
    CHECK(joined(t) == 1, "an interrupt under a scope makes no request, and the scope's end lands nothing");
    t = spawn1(interrupted_then_late, 0);
    avra_fiber_sleep(2);
    avra_fiber_fd_interrupt(g_pipe[0]);
    CHECK(joined(t) == 1, "a park after an interrupted one says only what ended it");
    t = spawn1(waits_on_the_pipe, 0);
    avra_fiber_sleep(2);
    avra_fiber_fd_interrupt(g_pipe[0]);
    int64_t claim = joined(t);
    CHECK(arm_of(claim) == -1 && member_of(claim) == 2, "a wait set's descriptor wait is claimed -1:2");
    int64_t v = avra_vtask_new();
    CHECK(avra_vtask_park_fd(v, g_pipe[0], 0, -1) == 1, "a virtual task parks on the descriptor");
    avra_fiber_fd_interrupt(g_pipe[0]);
    CHECK(avra_vtask_timed_out(v) == 1 && avra_vtask_interrupted(v) == 1, "and is told its park was interrupted");
    CHECK(avra_vtask_unwinding(v) == 0, "an interrupt is a value of the park: it raises no bit");
    avra_vtask_free(v);
}

// ── an edge belongs to whoever waited when it came ──────────────

static void* parks_briefly(void* self) {
    int64_t woken = avra_fiber_park_fd(g_pipe[0], 0, cap(self));
    char c;
    return answer(woken ? 10 + (read(g_pipe[0], &c, 1) == 1) : 0);
}

static void late_parker(void) {
    void* early = spawn1(parks_briefly, 2000);
    avra_fiber_sleep(2);
    CHECK(write(g_pipe[1], "e", 1) == 1, "the pipe takes a byte");
    void* late = spawn1(parks_briefly, 30);
    CHECK(joined(early) == 11, "the task parked when the byte came is woken and reads it");
    CHECK(joined(late) == 0, "a task that parks after it waits for the next, and times out");
    CHECK(avra_sched_fd_waiters() == 0 && avra_sched_timers() == 0, "nothing stays filed");
}

// A waiter gone by a hand other than the poller's — an interrupt, its
// own time — while a byte it was never told of still waits: the byte is
// the descriptor's, so the next task to park there is woken at once and
// reads it. Nothing is lost with the waiter that left.
static void late_parker_after_interrupt(void) {
    void* early = spawn1(parks_on_pipe, 0);
    avra_fiber_sleep(2);
    CHECK(write(g_pipe[1], "e", 1) == 1, "the pipe takes a byte nobody has been told of");
    avra_fiber_fd_interrupt(g_pipe[0]);
    int64_t t0 = now_ns();
    void* late = spawn1(parks_briefly, 2000);
    CHECK(joined(early) == 0, "the interrupted waiter answers as one whose time ran out");
    CHECK(joined(late) == 11 && now_ns() - t0 < 1000000000, "the next task to park after an interrupted waiter left reads the byte, at once");

    early = spawn1(parks_briefly, 3);
    avra_fiber_yield();
    avra_fiber_sleep(6);                    // its time passes while nobody is ready, so its deadline fires
    CHECK(write(g_pipe[1], "e", 1) == 1, "a byte comes after the waiter has left by its time");
    avra_fiber_yield();
    CHECK(avra_sched_fd_waiters() == 0, "the waiter has left by its time");
    t0 = now_ns();
    late = spawn1(parks_briefly, 2000);
    CHECK(joined(early) == 0, "the waiter answers as timed out");
    CHECK(joined(late) == 11 && now_ns() - t0 < 1000000000, "the next task to park after a timed-out waiter left reads the byte, at once");
    CHECK(avra_sched_fd_waiters() == 0 && avra_sched_timers() == 0, "nothing stays filed");
}

// ── the world's turn: bounded in time, and in switches ──────────

static volatile int g_stop;
static int64_t g_turns, g_due, g_due_turn;

// Computes for `cap` ms between yields, until told to stop; counts its
// turns and notes the one at which the time `g_due` had come.
static void* works_between_yields(void* self) {
    while (!g_stop) {
        int64_t until = now_ns() + cap(self) * 1000000;
        while (now_ns() < until) {}
        g_turns++;
        if (g_due && !g_due_turn && now_ns() >= g_due) g_due_turn = g_turns;
        avra_fiber_yield();
    }
    return answer(0);
}

// Sleeps `cap` ms; answers how many turns of the others passed between
// its time and its waking.
static void* sleeps_counting(void* self) {
    g_due = now_ns() + cap(self) * 1000000;
    avra_fiber_sleep(cap(self));
    return answer(g_due_turn ? g_turns - g_due_turn : 0);
}

// A 5 ms deadline on a gate nobody claims; answers how many turns of the
// others passed between its time and its waking, or -1.
static void* deadline_counting(void* self) {
    (void)self;
    int64_t outer = avra_fiber_within(5);
    g_due = now_ns() + 5000000;
    avra_wait_gate(g_gate, 0, 0);
    int64_t claim = avra_wait_park();
    avra_fiber_within_end(outer);
    return answer(arm_of(claim) == -1 ? (g_due_turn ? g_turns - g_due_turn : 0) : -1);
}

// Eight tasks that each compute 2 ms between yields: a 5 ms sleep and a
// 5 ms deadline are heard within AVRA_TIMER_TURNS switches of due or one
// tick, whichever is sooner — the switch reads the timer heap every that
// many switches, never every switch — plus one round of the eight. The
// deadline is read at most that late too. COUNTED IN TURNS, never timed:
// a loaded machine stretches a turn, never adds one.
static void timers_heard_within_the_window(void) {
    g_gate = avra_gate_new();
    void* workers[8];
    g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
    for (int i = 0; i < 8; i++) workers[i] = spawn1(works_between_yields, 2);
    int64_t slept = joined(spawn1(sleeps_counting, 5));
    g_stop = 1;
    for (int i = 0; i < 8; i++) joined(workers[i]);
    g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
    for (int i = 0; i < 8; i++) workers[i] = spawn1(works_between_yields, 2);
    int64_t heard = joined(spawn1(deadline_counting, 0));
    g_stop = 1;
    for (int i = 0; i < 8; i++) joined(workers[i]);
    CHECK(slept >= 0 && slept <= avra_sched_timer_turns() + 8 + 2, "a sleep among tasks that compute between yields is heard within AVRA_TIMER_TURNS or one tick, plus a round");
    CHECK(heard >= 0 && heard <= avra_sched_timer_turns() + 8 + 2, "a deadline among them is heard within AVRA_TIMER_TURNS or one tick, plus a round");
    avra_rc_release(g_gate);

    // counted, not timed: two such tasks, a 46 ms sleep — woken at the
    // first switch after its time, then behind the two already ready
    g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
    for (int i = 0; i < 2; i++) workers[i] = spawn1(works_between_yields, 2);
    int64_t late = joined(spawn1(sleeps_counting, 46));
    g_stop = 1;
    for (int i = 0; i < 2; i++) joined(workers[i]);
    CHECK(late <= avra_sched_timer_turns() + 5, "a sleep among them is asked about within AVRA_TIMER_TURNS or one tick, not a window of rounds later");
}

// Yields `g_quick` times at once, then computes 2 ms between yields
// `g_slow` times; over and over.
static int g_quick, g_slow;
static void burst_turn(void) {
    g_turns++;
    if (g_due && !g_due_turn && now_ns() >= g_due) g_due_turn = g_turns;
    avra_fiber_yield();
}
static void* works_in_bursts(void* self) {
    (void)self;
    while (!g_stop) {
        for (int i = 0; i < g_quick && !g_stop; i++) burst_turn();
        for (int i = 0; i < g_slow && !g_stop; i++) {
            int64_t until = now_ns() + 2000000;
            while (now_ns() < until) {}
            burst_turn();
        }
    }
    return answer(0);
}

// `cap` sleeps of 5 ms; the most turns of the others any of them was
// woken past its time.
static void* naps(void* self) {
    int64_t worst = 0;
    for (int64_t i = 0; i < cap(self); i++) {
        g_due_turn = 0;
        g_due = now_ns() + 5000000;
        avra_fiber_sleep(5);
        int64_t late = g_due_turn ? g_turns - g_due_turn : 0;
        g_due = 0;
        if (late > worst) worst = late;
    }
    return answer(worst);
}

// Files a timer ALREADY DUE on an empty heap — the empty-to-filed edge
// the window is zeroed at — and parks; answers the most turns of the
// others before it woke.
static void* naps_due_now(void* self) {
    int64_t worst = 0;
    for (int64_t i = 0; i < cap(self); i++) {
        g_due_turn = 0;
        g_due = now_ns();
        avra_wait_until(now_ns(), 0, 0);
        avra_wait_park();
        int64_t late = g_due_turn ? g_turns - g_due_turn : 0;
        g_due = 0;
        if (late > worst) worst = late;
    }
    return answer(worst);
}

// Tasks that alternate a run of quick yields with a run of long slices:
// a sleep is heard within AVRA_TIMER_TURNS or one tick, plus one round of
// them, however the quick run before it went; a timer filed ALREADY DUE
// on an empty heap is heard at the next switch, a round of them at most
// — the window's zeroing at the empty-to-filed edge is what arms that
// read. Counted in turns.
static void timers_heard_within_the_window_among_bursts(void) {
    static const int shapes[2][3] = { { 8, 100, 8 }, { 2, 300, 40 } };
    for (int s = 0; s < 2; s++) {
        int workers = shapes[s][0];
        g_stop = 0; g_quick = shapes[s][1]; g_slow = shapes[s][2]; g_turns = 0; g_due = 0; g_due_turn = 0;
        void* w[8];
        for (int i = 0; i < workers; i++) w[i] = spawn1(works_in_bursts, 0);
        int64_t worst = joined(spawn1(naps, 20));
        g_stop = 1;
        for (int i = 0; i < workers; i++) joined(w[i]);
        CHECK(worst <= avra_sched_timer_turns() + workers + 2, s == 0 ? "twenty sleeps among eight bursting tasks are each heard within AVRA_TIMER_TURNS or one tick, plus a round" : "twenty sleeps among two bursting tasks are each heard within AVRA_TIMER_TURNS or one tick, plus a round");

        g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
        for (int i = 0; i < workers; i++) w[i] = spawn1(works_in_bursts, 0);
        int64_t at_once = joined(spawn1(naps_due_now, 20));
        g_stop = 1;
        for (int i = 0; i < workers; i++) joined(w[i]);
        CHECK(at_once >= 0 && at_once <= workers + 2, s == 0 ? "a sleep already due among eight bursting tasks is heard within a round of them, not a window later" : "a sleep already due among two bursting tasks is heard within a round of them, not a window later");
    }
}

// Yields `cap` times at most, counting; notes the turn at which the
// time `g_due` had come.
static void* yields_counting(void* self) {
    for (int64_t i = 0; i < cap(self) && !g_stop; i++) {
        g_turns++;
        if (g_due && !g_due_turn && now_ns() >= g_due) g_due_turn = g_turns;
        avra_fiber_yield();
    }
    return answer(0);
}

// Files its sleep only after the yielders have run a while with nothing
// filed; answers how many turns passed between its time and its waking.
static void* sleeps_among_yielders(void* self) {
    (void)self;
    for (int i = 0; i < 2000; i++) avra_fiber_yield();
    g_due = now_ns() + 3000000;
    avra_fiber_sleep(3);
    int64_t late = g_due_turn ? g_turns - g_due_turn : 0;
    g_stop = 1;
    return answer(late);
}

// Parks on the pipe after the yielders have run a while; a second task
// writes once it sees the reader parked.
static void* reads_among_yielders(void* self) {
    (void)self;
    for (int i = 0; i < 2000; i++) avra_fiber_yield();
    int64_t woken = avra_fiber_park_fd(g_pipe[0], 0, 2000);
    int64_t late = g_turns - g_due_turn;
    char c;
    g_stop = 1;
    return answer(woken && read(g_pipe[0], &c, 1) == 1 ? late : -1);
}
static void* writes_once_parked(void* self) {
    (void)self;
    while (avra_sched_fd_waiters() == 0 && !g_stop) avra_fiber_yield();
    g_due_turn = g_turns;
    return answer(write(g_pipe[1], "w", 1));
}

static void world_within_reach(void) {
    enum { YIELDERS = 4, MOST = 1000000 };
    // two windows (the timer heap's and the poller's) plus a round.
    int64_t reach = 2 * avra_sched_timer_turns() + 4 * YIELDERS;
    void* y[YIELDERS];
    g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
    for (int i = 0; i < YIELDERS; i++) y[i] = spawn1(yields_counting, MOST);
    int64_t late = joined(spawn1(sleeps_among_yielders, 0));
    for (int i = 0; i < YIELDERS; i++) joined(y[i]);
    CHECK(late >= 0 && late <= reach, "a sleep filed among yielding tasks wakes within a window of switches of its time");

    g_stop = 0; g_turns = 0; g_due = 0; g_due_turn = 0;
    for (int i = 0; i < YIELDERS; i++) y[i] = spawn1(yields_counting, MOST);
    void* r = spawn1(reads_among_yielders, 0);
    void* w = spawn1(writes_once_parked, 0);
    late = joined(r);
    joined(w);
    for (int i = 0; i < YIELDERS; i++) joined(y[i]);
    CHECK(late >= 0 && late <= reach + avra_sched_timer_turns(), "a reader parked among yielding tasks wakes within a window of switches of its byte");
}

// ── laws whose breaking would hang the rest: each in a child ────

// `body` in a child that a hang cannot outlive; passes when every check
// the child made held.
// Whether the bound ended it.
static int in_child_within(const char* what, void (*body)(void), unsigned seconds) {
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        alarm(seconds);
        g_fails = 0;
        body();
        _exit(g_fails ? 1 : 0);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, what);
    return WIFSIGNALED(status) && WTERMSIG(status) == SIGALRM;
}

static void in_child(const char* what, void (*body)(void)) { in_child_within(what, body, 30); }

// A CLOCK THAT NEVER MOVES HANGS EVERY CASE ON IT: the first one its
// bound ends says so, and each after it fails at once, unrun.
static int g_clock_stuck = 0;

static void on_virtual_clock(const char* what, void (*body)(void)) {
    if (g_clock_stuck) { CHECK(0, what); return; }
    g_clock_stuck = in_child_within(what, body, 5);
}

static void winner_leaves_at_claim(void) {
    g_gate = avra_gate_new();
    spawn1(waits_for_ever, 0);
    avra_fiber_sleep(2);
    CHECK(avra_gate_claim(g_gate) == 5, "the waiter is claimed");
    CHECK(!filed(g_gate), "and is out of the gate's list at the claim");
}

static void freed_vtask_leaves_its_sources(void) {
    g_gate = avra_gate_new();
    int64_t vt = avra_vtask_new();
    avra_vtask_wait_gate(vt, g_gate, 0, 0);
    avra_vtask_wait_until(vt, in_ms(60000), 1, 0);
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 2, 0);
    CHECK(avra_vtask_park(vt) == 1, "a virtual task parks");
    avra_vtask_free(vt);
    CHECK(!filed(g_gate) && avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0, "freed, it is filed nowhere");
}

static void* parks_on_number(void* self) { return answer(avra_fiber_park_fd(cap(self), 0, 2000)); }

// A descriptor closed through the scheduler's door, its number given to
// another pipe: a park on the number is watched afresh.
static void closed_number_is_watched_afresh(void) {
    int first[2], second[2];
    if (pipe(first) != 0 || pipe(second) != 0) _exit(9);
    fcntl(first[0], F_SETFL, O_NONBLOCK);
    void* t = spawn1(parks_on_number, first[0]);
    avra_fiber_sleep(2);
    avra_fiber_fd_closing(first[0]);
    close(first[0]);
    CHECK(joined(t) == 1, "a close wakes the task parked on the descriptor");
    if (dup2(second[0], first[0]) != first[0]) _exit(9);
    fcntl(first[0], F_SETFL, O_NONBLOCK);
    t = spawn1(parks_on_number, first[0]);
    avra_fiber_sleep(2);
    CHECK(write(second[1], "n", 1) == 1, "the new pipe takes a byte");
    CHECK(joined(t) == 1, "a park on the number's next tenant is woken by its byte");
}

// ── a wait on an open gate is a set too ─────────────────────────

static void* sleeps_in_a_claimed_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); avra_fiber_sleep(5); return answer(0); }
static void sleep_in_claimed_set(void) { g_gate = avra_gate_new(); avra_vgate_open(g_gate); joined(spawn1(sleeps_in_a_claimed_set, 0)); }

// ── stacks past the count that get a guard each ─────────────────

static void* yields_thrice(void* self) { for (int i = 0; i < 3; i++) avra_fiber_yield(); return answer(cap(self)); }

__attribute__((noinline)) static void touch(volatile char* p) { p[0] = 1; }

// A frame that reaches under the stack's floor, standing at a switch.
static void* yields_below_floor(void* self) {
    (void)self;
    volatile char big[80000];
    touch(big);
    avra_fiber_yield();
    return answer(big[0]);
}

// A frame a little larger than the stack, written whole and left.
__attribute__((noinline)) static int64_t overruns(void) {
    volatile char big[65536];
    for (size_t i = 0; i < sizeof big; i++) big[i] = 1;
    return big[100];
}
static void* overruns_then_yields(void* self) {
    (void)self;
    int64_t v = overruns();
    avra_fiber_yield();
    return answer(v);
}

static int64_t deep(int64_t n) {
    volatile char pad[512];
    pad[0] = (char)n;
    return n == 0 ? pad[0] : deep(n - 1) + pad[0];
}
static void* recurses(void* self) { return answer(deep(cap(self))); }

// `before` tasks stand, each on a stack of its own, and the next runs `body`.
static void nth_task(int before, Code body) {
    setenv("AVRA_FIBER_STACK", "65536", 1);
    void* others[8];
    for (int i = 0; i < before; i++) others[i] = spawn1(yields_thrice, i);
    void* t = spawn1(body, 1000000);
    joined(t);
    for (int i = 0; i < before; i++) joined(others[i]);
}

static void floor_past_k(void) { setenv("AVRA_FIBER_GUARDS", "0", 1); nth_task(1, yields_below_floor); }
static void canary_past_k(void) { setenv("AVRA_FIBER_GUARDS", "0", 1); nth_task(1, overruns_then_yields); }
static void runaway_past_k(void) { setenv("AVRA_FIBER_GUARDS", "0", 1); nth_task(1, recurses); }
static void first_of_k(void) { setenv("AVRA_FIBER_GUARDS", "1", 1); nth_task(0, overruns_then_yields); }
static void third_past_k(void) { setenv("AVRA_FIBER_GUARDS", "1", 1); nth_task(2, overruns_then_yields); }
static void third_with_all(void) { setenv("AVRA_FIBER_GUARDS", "all", 1); nth_task(2, overruns_then_yields); }

// A burst past the guarded count parks, ends, and ONE task then overruns.
static void lone_after_burst(void) {
    setenv("AVRA_FIBER_STACK", "65536", 1);
    setenv("AVRA_FIBER_GUARDS", "64", 1);
    g_gate = avra_gate_new();
    enum { BURST = 200 };
    static void* all[BURST];
    for (int i = 0; i < BURST; i++) all[i] = spawn1(waits_for_ever, 0);
    avra_fiber_sleep(2);
    while (avra_gate_claim(g_gate) >= 0) {}
    for (int i = 0; i < BURST; i++) joined(all[i]);
    void* other = spawn1(yields_thrice, 0);
    joined(spawn1(overruns_then_yields, 0));
    joined(other);
}

// A stack that shares its slab's guard, used, given back and taken again.
static void* ends_at_once(void* self) { return answer(cap(self)); }
static void recycled_past_k(void) {
    setenv("AVRA_FIBER_STACK", "65536", 1);
    setenv("AVRA_FIBER_GUARDS", "0", 1);
    void* below = spawn1(yields_thrice, 0);
    joined(spawn1(ends_at_once, 0));
    joined(spawn1(overruns_then_yields, 0));
    joined(below);
}

static void guards_spelled(const char* value) {
    setenv("AVRA_FIBER_GUARDS", value, 1);
    joined(spawn1(ends_at_once, 0));
}
static void guards_upper(void) { guards_spelled("ALL"); }
static void guards_short(void) { guards_spelled("al"); }
static void guards_negative(void) { guards_spelled("-1"); }
static void guards_trailing(void) { guards_spelled("12x"); }

// THE LAW'S OWN HOLE, pinned: past the guarded count a bounded overrun
// that returns before the next switch and never writes the canary word
// changes its neighbour's stack and nothing traps. Exits 0 when that
// is what happened.
__attribute__((noinline)) static void skips(volatile char* p) { p[0] = 7; p[4096] = 7; p[8192] = 7; }
__attribute__((noinline)) static int64_t dips(void) { volatile char big[70000]; skips(big); return big[0]; }
static void* dips_then_yields(void* self) { (void)self; int64_t v = dips(); avra_fiber_yield(); return answer(v); }
static void* holds_bytes(void* self) {
    (void)self;
    volatile char mine[2048];
    for (size_t i = 0; i < sizeof mine; i++) mine[i] = 0x55;
    for (int i = 0; i < 3; i++) avra_fiber_yield();
    int64_t changed = 0;
    for (size_t i = 0; i < sizeof mine; i++) changed += mine[i] != 0x55;
    return answer(changed);
}
static int uncaught_overrun(void) {
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        alarm(60);
        setenv("AVRA_FIBER_STACK", "65536", 1);
        setenv("AVRA_FIBER_GUARDS", "0", 1);
        void* below = spawn1(holds_bytes, 0);
        void* t = spawn1(dips_then_yields, 0);
        int64_t answered = joined(t);
        _exit(answered == 7 && joined(below) > 0 ? 0 : 3);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

static void stacks(void) {
    const char* at_switch = "a task's stack overflowed into its neighbour — caught at a switch";
    const char* at_write = "a task's stack overflowed\n";
    trapped("a frame under its floor at a switch, past the guarded count", floor_past_k, at_switch);
    trapped("an overrun that returned, past the guarded count", canary_past_k, at_switch);
    trapped("a runaway recursion past the guarded count", runaway_past_k, at_write);
    trapped("an overrun on the one stack that has a guard", first_of_k, at_write);
    trapped("an overrun on the third stack, one guarded", third_past_k, at_switch);
    trapped("an overrun on the third stack, every stack guarded", third_with_all, at_write);
    trapped("a lone task after a burst past the guarded count", lone_after_burst, at_write);
    trapped("an overrun on a stack given back and taken again, past the guarded count", recycled_past_k, at_switch);
    const char* misspelled = "it is `all`, or a whole number of stacks that get a guard page each";
    trapped("AVRA_FIBER_GUARDS=ALL", guards_upper, misspelled);
    trapped("AVRA_FIBER_GUARDS=al", guards_short, misspelled);
    trapped("AVRA_FIBER_GUARDS=-1", guards_negative, misspelled);
    trapped("AVRA_FIBER_GUARDS=12x", guards_trailing, misspelled);
    CHECK(uncaught_overrun() == 0, "the law's hole stands as written: an overrun that skips the canary word changes its neighbour and nothing traps");
}

// ── the same set, as the evaluator drives it ────────────────────

static void as_virtual(void) {
    int64_t live = avra_mem_live();
    g_gate = avra_gate_new();
    int64_t vt = avra_vtask_new_at(0x1234, 9);

    // woken by the gate
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 0, 10);
    avra_vtask_wait_until(vt, in_ms(60000), 1, 11);
    avra_vtask_wait_gate(vt, g_gate, 2, 12);
    CHECK(avra_vtask_park(vt) == 1, "a virtual task parks on an unclaimed set");
    CHECK(avra_gate_claim(g_gate) == 12, "its gate waiter is claimed");
    CHECK(avra_vtask_next() == vt, "the policy names it next");
    int64_t claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == 2 && member_of(claim) == 12, "it reads the gate's arm");
    CHECK(avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0 && !filed(g_gate), "reading the claim retracts the losers");

    // woken by the descriptor
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 0, 10);
    avra_vtask_wait_until(vt, in_ms(60000), 1, 11);
    avra_vtask_wait_gate(vt, g_gate, 2, 12);
    CHECK(avra_vtask_park(vt) == 1, "it parks again");
    CHECK(write(g_pipe[1], "v", 1) == 1, "the pipe takes a byte");
    CHECK(avra_vtask_next() == vt, "the policy names it when the pipe is readable");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == 0 && member_of(claim) == 10, "it reads the descriptor's arm");
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "and its byte");

    // woken by the time
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 0, 10);
    avra_vtask_wait_until(vt, in_ms(5), 1, 11);
    avra_vtask_wait_gate(vt, g_gate, 2, 12);
    CHECK(avra_vtask_park(vt) == 1, "it parks a third time");
    CHECK(avra_vtask_next() == vt, "the policy names it when the time comes");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == 1 && member_of(claim) == 11, "it reads the time's arm");
    CHECK(avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0 && !filed(g_gate), "nothing stays filed");

    // a claim, then a cancel
    avra_vtask_wait_gate(vt, g_gate, 3, 7);
    CHECK(avra_vtask_park(vt) == 1, "it parks on the gate");
    CHECK(avra_gate_claim(g_gate) == 7, "and is claimed");
    avra_vtask_cancel(vt, 0);
    CHECK(avra_vtask_next() == vt, "the cancel readies nothing twice");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == 3 && member_of(claim) == 7, "the claim stands under the cancel");
    avra_vtask_wait_gate(vt, g_gate, 3, 7);
    CHECK(avra_vtask_park(vt) == 0, "its next wait does not park");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == -1 && member_of(claim) == 0 && !filed(g_gate), "it answers the cancel");
    avra_vtask_free(vt);

    // freed while filed
    vt = avra_vtask_new();
    avra_vtask_wait_gate(vt, g_gate, 0, 0);
    avra_vtask_wait_until(vt, in_ms(60000), 1, 0);
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 2, 0);
    CHECK(avra_vtask_park(vt) == 1, "a second virtual task parks");
    avra_vtask_free(vt);
    CHECK(!filed(g_gate) && avra_sched_timers() == 0 && avra_sched_fd_waiters() == 0, "a freed virtual task leaves every source it waited on");

    // freed with a wait it never parked on
    vt = avra_vtask_new();
    avra_vtask_wait_gate(vt, g_gate, 0, 0);
    avra_vtask_wait_until(vt, in_ms(60000), 1, 0);
    avra_vtask_free(vt);
    CHECK(!filed(g_gate) && avra_sched_timers() == 0, "a virtual task freed before it parks leaves every source it registered with");

    // freed inside a `within` it waited under
    vt = avra_vtask_new();
    avra_vtask_within(vt, 60000);
    avra_vtask_wait_gate(vt, g_gate, 0, 0);
    CHECK(avra_vtask_park(vt) == 1 && avra_sched_timers() == 1, "a virtual task's wait under a `within` files its deadline");
    avra_vtask_free(vt);
    CHECK(!filed(g_gate) && avra_sched_timers() == 0, "and freeing it takes the deadline out of the heap");

    // a switch between ready virtual tasks, a descriptor waiter filed meanwhile
    vt = avra_vtask_new();
    avra_vtask_wait_fd(vt, g_pipe[0], 0, 0, 0);
    CHECK(avra_vtask_park(vt) == 1, "a virtual task parks on the pipe");
    int64_t runner = avra_vtask_new();
    int64_t polls = avra_sched_polls();
    int named = 1;
    for (int i = 0; i < 1000; i++) {
        avra_vtask_ready(runner);
        named = named && avra_vtask_next() == runner;
    }
    CHECK(named, "the policy names the ready task each time");
    CHECK(avra_sched_polls() - polls <= 1000 / 64 + 2, "and asks the poller once a window, not once a switch");
    avra_vtask_free(runner);
    avra_vtask_free(vt);

    // an opened gate, as a finished task's
    vt = avra_vtask_new();
    avra_vtask_wait_gate(vt, g_gate, 4, 1);
    CHECK(avra_vtask_park(vt) == 1, "a third parks on the gate");
    avra_vgate_open(g_gate);
    CHECK(avra_vtask_next() == vt, "opening it readies the waiter");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == 4, "on its arm");
    avra_vtask_wait_gate(vt, g_gate, 4, 2);
    CHECK(avra_vtask_park(vt) == 0 && member_of(avra_vtask_claim(vt)) == 2, "and a wait on it after is claimed at once");

    // the deadline, armed at the first wait
    int64_t outer = avra_vtask_within(vt, 5);
    CHECK(avra_sched_timers() == 0, "a virtual task's `within` files nothing until it waits");
    void* closed_gate = avra_gate_new();
    avra_vtask_wait_gate(vt, closed_gate, 0, 0);
    CHECK(avra_vtask_park(vt) == 1 && avra_sched_timers() == 1, "its first wait files the deadline");
    CHECK(avra_vtask_next() == vt, "the deadline readies it");
    claim = avra_vtask_claim(vt);
    CHECK(arm_of(claim) == -1 && member_of(claim) == 1 && !filed(closed_gate), "and it reads the deadline's claim");
    avra_vtask_within_end(vt, outer);
    avra_vtask_free(vt);
    avra_rc_release(closed_gate);
    avra_rc_release(g_gate);
    CHECK(avra_sched_timers() == 0 && avra_mem_live() == live, "the virtual tasks leave nothing behind");
}

// ── every scope's own limit, and which request stands ───────────

// A park on a gate nothing opens, so the clock stays frozen: 0 when a
// deadline cut it.
static void* g_silent;
static int64_t parks_silent(void) {
    avra_wait_gate(g_silent, 0, 0);
    int64_t claim = avra_wait_park();
    return arm_of(claim) == -1 && member_of(claim) == 1 ? 0 : 1;
}

static int64_t g_outer = 0, g_inner = 0;
static void* g_me;      // the task the case runs as
static void* g_kid;     // the task it spawns

// `ms` pass with the task at no cancel point: it waits a timer's task out
// as a scope's end does, where a sleep would heed its deadline.
static void unheeding(int64_t ms) {
    void* timed = avra_task_at(avra_now_ns() + ms * 1000000);
    avra_task_settle(timed);
    avra_rc_release(timed);
}

static void* outer_fires_inner_passes(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    g_inner = avra_fiber_within(5000);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == g_outer;
    g_byte_b = avra_scope_end(g_inner) == 0 && avra_task_request(g_me) == g_outer;
    g_byte_c = avra_scope_end(g_outer) == 1 && avra_task_request(g_me) == 0;
    return answer(0);
}

static void* inner_fires_outer_stands(void* self) {
    (void)self;
    g_outer = avra_fiber_within(5000);
    g_inner = avra_fiber_within(20);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == g_inner;
    g_byte_b = avra_sched_timers() == 1;
    int64_t under = avra_fiber_within(10);
    unheeding(20);
    g_byte_c = avra_scope_end(under) == 0 && avra_task_request(g_me) == g_inner && avra_sched_timers() == 1;
    g_byte_c = g_byte_c && avra_scope_end(g_inner) == 1 && avra_task_request(g_me) == 0 && avra_sched_timers() == 1;
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(30);
    g_spent_ms = ms_since(t0);
    g_byte_d = avra_scope_end(g_outer) == 0 && avra_sched_timers() == 0;
    return answer(0);
}

// A child copies the owner: which scope owns a tie is seen in its request.
static void* hears_the_outer(void* self) {
    (void)self;
    g_byte_d = parks_silent() == 0 && avra_task_request(g_kid) == g_outer;
    return answer(0);
}

static void* equal_limits_outer_owns(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    g_inner = avra_fiber_within(20);
    g_kid = spawn1(hears_the_outer, 0);
    ended(g_kid);
    g_byte_a = g_byte_d == 1 && parks_silent() == 0 && avra_task_request(g_me) == g_outer;
    g_byte_b = avra_scope_end(g_inner) == 0 && avra_scope_end(g_outer) == 1;
    // the tie found again: once an earlier inner scope has ended, and
    // once one has asked
    g_outer = avra_fiber_within(20);
    int64_t mid = avra_fiber_within(20);
    avra_scope_end(avra_fiber_within(10));
    g_byte_d = 0;
    g_kid = spawn1(hears_the_outer, 0);
    ended(g_kid);
    g_byte_c = g_byte_d == 1 && avra_scope_end(mid) == 0 && avra_scope_end(g_outer) == 0;
    g_outer = avra_fiber_within(20);
    mid = avra_fiber_within(20);
    g_inner = avra_fiber_within(10);
    g_byte_c = g_byte_c && parks_silent() == 0 && avra_task_request(g_me) == g_inner;
    g_byte_c = g_byte_c && parks_silent() == 0 && avra_task_request(g_me) == g_inner;
    unheeding(30);
    g_byte_d = avra_task_request(g_me) == g_outer && avra_scope_end(g_inner) == 0 && avra_scope_end(mid) == 0 && avra_scope_end(g_outer) == 1;
    return answer(0);
}

// The inner limit passes while nothing heeds it: the next park hears it.
static void* fires_while_running(void* self) {
    (void)self;
    g_outer = avra_fiber_within(5000);
    g_inner = avra_fiber_within(20);
    unheeding(30);
    g_byte_a = avra_task_request(g_me) == 0;
    g_byte_b = parks_silent() == 0 && avra_task_request(g_me) == g_inner;
    g_byte_c = avra_scope_end(g_inner) == 1 && avra_scope_end(g_outer) == 0;
    return answer(0);
}

// A limit that passes after the block's last park asks nothing.
static void* late_limit(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    unheeding(30);
    g_byte_a = avra_scope_end(g_outer) == 0 && avra_task_request(g_me) == 0;
    return answer(0);
}

static void* child_under_the_outer(void* self) {
    (void)self;
    int64_t own = avra_fiber_within(5000);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_kid) == g_outer;
    g_byte_b = avra_scope_end(own) == 0 && avra_task_request(g_kid) == g_outer;
    return answer(0);
}

static void* spawns_under_the_outer(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    g_kid = spawn1(child_under_the_outer, 0);
    g_byte_c = parks_silent() == 0 && avra_task_request(g_me) == g_outer;
    ended(g_kid);
    g_byte_d = avra_scope_end(g_outer) == 1;
    return answer(0);
}

// A spawner whose inner limit has asked: its child starts under that.
static void* child_of_a_request(void* self) {
    (void)self;
    int64_t t0 = avra_now_ns();
    g_byte_a = parks_silent() == 0 && avra_task_request(g_kid) == g_inner && ms_since(t0) < 1000;
    return answer(0);
}

static void* spawns_under_a_request(void* self) {
    (void)self;
    g_outer = avra_fiber_within(5000);
    g_inner = avra_fiber_within(20);
    parks_silent();
    g_kid = spawn1(child_of_a_request, 0);
    ended(g_kid);
    g_byte_b = avra_scope_end(g_inner) == 1 && avra_scope_end(g_outer) == 0;
    return answer(0);
}

// `body` as a task on the frozen clock, with a gate nothing opens.
static void scopes_on(void* (*body)(void*)) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    g_silent = avra_gate_new();
    g_me = spawn1(body, 0);
    ended(g_me);
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}

static void every_scope_its_own_limit(void) {
    scopes_on(outer_fires_inner_passes);
    CHECK(g_byte_a == 1, "an outer limit that passes first is the request, whichever scope is innermost");
    CHECK(g_byte_b == 1, "the inner scope's end passes it on");
    CHECK(g_byte_c == 1, "and the outer's end lands it");
    scopes_on(inner_fires_outer_stands);
    CHECK(g_byte_a == 1, "an inner limit that passes first is the inner's request");
    CHECK(g_byte_b == 1, "and the outer's limit is filed in its place, the one entry");
    CHECK(g_byte_c == 1, "a scope opened under the request never asks; the inner's end lands it, and the outer's entry stands");
    CHECK(g_spent_ms >= 30 && g_byte_d == 1, "the outer scope runs on, and its end takes its entry out");
    scopes_on(equal_limits_outer_owns);
    CHECK(g_byte_a == 1 && g_byte_b == 1, "two limits on one instant are the outer's");
    CHECK(g_byte_c == 1 && g_byte_d == 1, "and the outer's again when an inner one has asked first");
    scopes_on(fires_while_running);
    CHECK(g_byte_a == 1, "a limit that passes while nothing heeds it asks nothing yet");
    CHECK(g_byte_b == 1 && g_byte_c == 1, "the next park hears it as the inner's");
    scopes_on(late_limit);
    CHECK(g_byte_a == 1, "a limit that passes after the last park leaves the scope's end nothing to land");
    scopes_on(spawns_under_the_outer);
    CHECK(g_byte_a == 1 && g_byte_b == 1, "a child under an inherited limit hears the spawner's scope, and passes its own");
    CHECK(g_byte_c == 1 && g_byte_d == 1, "and the spawner's scope lands its own request");
    scopes_on(spawns_under_a_request);
    CHECK(g_byte_a == 1 && g_byte_b == 1, "a child spawned under a standing request starts under it, and hears it at once");
}

enum { SCOPE_TASKS = 10, SCOPES_EACH = 10000 };
static int64_t g_scope_ids[SCOPE_TASKS * SCOPES_EACH];
static int64_t g_task_ids[SCOPE_TASKS + 1];

static void* opens_scopes(void* self) {
    int64_t k = cap(self);
    g_task_ids[k] = avra_task_id();
    for (int i = 0; i < SCOPES_EACH; i++) {
        int64_t id = avra_fiber_within(1000);
        g_scope_ids[k * SCOPES_EACH + i] = id;
        avra_scope_end(id);
        if (i % 1000 == 0) avra_fiber_yield();
    }
    return answer(0);
}

static int ids_ordered(const void* a, const void* b) {
    int64_t x = *(const int64_t*)a, y = *(const int64_t*)b;
    return (x > y) - (x < y);
}

static void scope_ids(void) {
    void* ts[SCOPE_TASKS];
    for (int k = 0; k < SCOPE_TASKS; k++) ts[k] = spawn1(opens_scopes, k);
    for (int k = 0; k < SCOPE_TASKS; k++) joined(ts[k]);
    g_task_ids[SCOPE_TASKS] = avra_task_id();
    qsort(g_scope_ids, SCOPE_TASKS * SCOPES_EACH, sizeof(int64_t), ids_ordered);
    int unique = 1, apart = 1;
    for (int i = 1; i < SCOPE_TASKS * SCOPES_EACH; i++) unique = unique && g_scope_ids[i] != g_scope_ids[i - 1];
    for (int i = 0; i < SCOPE_TASKS * SCOPES_EACH; i++)
        for (int k = 0; k <= SCOPE_TASKS; k++) apart = apart && g_scope_ids[i] != g_task_ids[k] && g_scope_ids[i] != g_task_ids[k] + 1;
    CHECK(unique, "a hundred thousand scopes across ten tasks have a hundred thousand ids");
    CHECK(apart, "and none is a task's, nor a task's request");
}

static void one_entry_under_three_scopes(void) {
    int64_t a = avra_fiber_within(7000), b = avra_fiber_within(6000), c = avra_fiber_within(5000);
    g_gate = avra_gate_new();
    void* helper = spawn1(claims_when_filed, 1000);
    int most = 0;
    for (int i = 0; i < 1000; i++) {
        avra_wait_gate(g_gate, 0, i);
        avra_wait_park();
        if (avra_sched_timers() > most) most = (int)avra_sched_timers();
    }
    joined(helper);
    CHECK(most == 1, "a thousand parks under three scopes keep one deadline entry");
    CHECK(avra_scope_end(c) == 0 && avra_sched_timers() == 0, "the owner's end takes it out");
    helper = spawn1(claims_when_filed, 1);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    joined(helper);
    CHECK(avra_sched_timers() == 1, "and the next park files the next owner's");
    CHECK(avra_scope_end(b) == 0 && avra_scope_end(a) == 0 && avra_sched_timers() == 0, "nothing is left after the last scope");
    avra_rc_release(g_gate);
}

// Six scopes, the innermost earliest, then the outermost: the records
// past the inline four behave as the four do.
static void* six_deep(void* self) {
    (void)self;
    int64_t ids[6];
    for (int i = 0; i < 6; i++) ids[i] = avra_fiber_within(i == 5 ? 20 : 5000 + i);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == ids[5];
    int landed = 0;
    for (int i = 5; i >= 0; i--) landed += (int)avra_scope_end(ids[i]) << i;
    g_byte_b = landed == 1 << 5;
    for (int i = 0; i < 6; i++) ids[i] = avra_fiber_within(i == 0 ? 20 : 5000 + i);
    g_byte_c = parks_silent() == 0 && avra_task_request(g_me) == ids[0];
    landed = 0;
    for (int i = 5; i >= 0; i--) landed += (int)avra_scope_end(ids[i]) << i;
    g_byte_d = landed == 1 && avra_sched_timers() == 0;
    return answer(0);
}

static void a_fifth_scope(void) {
    scopes_on(six_deep);
    CHECK(g_byte_a == 1 && g_byte_b == 1, "a sixth scope's limit is its own request, and only its end lands it");
    CHECK(g_byte_c == 1 && g_byte_d == 1, "the outermost of six owns its limit over five inner ones");
}

// A hundred thousand nested scopes, each earlier than the one outside
// it, so each owns the limit while it stands: they open and end in
// time proportional to their number.
static void a_deep_nest_ends_in_linear_time(void) {
    enum { DEEP = 100000 };
    static int64_t ids[DEEP];
    int64_t t0 = avra_now_ns();
    for (int i = 0; i < DEEP; i++) ids[i] = avra_fiber_within(10000000 - i);
    for (int i = DEEP - 1; i >= 0; i--) avra_scope_end(ids[i]);
    CHECK(ms_since(t0) < 500, "a hundred thousand nested scopes, each the owner, open and end in linear time");
}

static void scope_ended_out_of_order(void) {
    int64_t outer = avra_fiber_within(1000);
    avra_fiber_within(2000);
    avra_scope_end(outer);
}

// A deadline's request stands; then the task is cancelled, and meets
// the cancel at its next point.
static void* fired_then_cancelled(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == g_outer;
    unheeding(10000);
    avra_fiber_yield();
    g_byte_b = avra_task_request(g_me) == 1;
    g_byte_c = avra_scope_end(g_outer) == 0 && avra_task_request(g_me) == 1;
    return answer(0);
}

// A cancel stands; then the deadline passes.
static void* cancelled_then_fired(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    int64_t t0 = avra_now_ns();
    while (ms_since(t0) < 40) avra_fiber_yield();
    g_byte_a = avra_task_request(g_me) == 1;
    g_byte_b = avra_scope_end(g_outer) == 0 && avra_task_request(g_me) == 1;
    return answer(0);
}

static void task_cancel_outranks_a_scope(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_silent = avra_gate_new();
    void* t = g_me = spawn1(fired_then_cancelled, 0);
    avra_fiber_sleep(30);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1, "a deadline's request stands, and the task is cancelled after");
    CHECK(g_byte_b == 1 && g_byte_c == 1, "the task's request displaces the scope's, and the scope's end lands nothing");
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}

static void a_scope_does_not_displace_a_task_cancel(void) {
    bytes_unseen();
    g_gate = avra_gate_new();
    void* t = g_me = spawn1(cancelled_then_fired, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2 && g_byte_a == 1, "a limit that passes under a task's cancel leaves the task's request standing");
    CHECK(g_byte_b == 1, "and the scope's end lands nothing");
    avra_rc_release(g_gate);
}

// Two limits pass during one wait, the inner's first: the outer's stands.
static void* inner_then_outer(void* self) {
    (void)self;
    g_outer = avra_fiber_within(40);
    g_inner = avra_fiber_within(20);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == g_inner;
    unheeding(60);
    g_byte_b = avra_task_request(g_me) == g_outer;
    g_byte_c = avra_scope_end(g_inner) == 0 && avra_scope_end(g_outer) == 1;
    return answer(0);
}

// The outer's first: the inner's limit asks nothing.
static void* outer_then_inner(void* self) {
    (void)self;
    g_outer = avra_fiber_within(20);
    g_inner = avra_fiber_within(40);
    g_byte_a = parks_silent() == 0 && avra_task_request(g_me) == g_outer;
    unheeding(60);
    g_byte_b = avra_task_request(g_me) == g_outer && avra_sched_timers() == 0;
    g_byte_c = avra_scope_end(g_inner) == 0 && avra_scope_end(g_outer) == 1;
    return answer(0);
}

static void the_outer_request_stands(void) {
    scopes_on(inner_then_outer);
    CHECK(g_byte_a == 1, "the inner limit passes first");
    CHECK(g_byte_b == 1, "the outer's, passing later, displaces it");
    CHECK(g_byte_c == 1, "and only the outer's end lands it");
    scopes_on(outer_then_inner);
    CHECK(g_byte_a == 1, "the outer limit passes first");
    CHECK(g_byte_b == 1, "the inner's, passing later, asks nothing and files nothing");
    CHECK(g_byte_c == 1, "and only the outer's end lands it");
}

// Run alone, traced: a cancel stands when a deadline passes.
static int dropped_scene(void) {
    a_scope_does_not_displace_a_task_cancel();
    return g_fails ? 1 : 0;
}

static void a_dropped_request_is_traced(const char* self) {
    char buf[8192];
    int status = traced_run(self, "dropped-scene", buf, sizeof buf);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "the dropped scene runs");
    char want[64];
    snprintf(want, sizeof want, "request-dropped id=1 by=scope:");
    CHECK(strstr(buf, want) != NULL && strstr(buf, " for=task:0") != NULL, "a request a standing one outranks is one line naming both askers");
}

static void forked_keeps_the_callers_scopes(void) {
    int64_t outer = avra_fiber_within(5000), inner = avra_fiber_within(6000);
    g_gate = avra_gate_new();
    void* helper = spawn1(claims_when_filed, 1);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    joined(helper);
    pid_t pid = fork();
    if (pid == 0) {
        avra_fiber_forked();
        int kept = avra_sched_timers() == 1;
        kept = kept && avra_scope_end(inner) == 0 && avra_sched_timers() == 1;
        kept = kept && avra_scope_end(outer) == 0 && avra_sched_timers() == 0;
        _exit(kept ? 0 : 1);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a forked child keeps the caller's scopes and their one entry");
    avra_scope_end(inner);
    avra_scope_end(outer);
    avra_rc_release(g_gate);
}

// A virtual task inherits a scope as a fiber does.
static void virtual_scopes(void) {
    int64_t parent = avra_vtask_new(), child = avra_vtask_new();
    int64_t outer = avra_vtask_within(parent, 1000);
    avra_vtask_inherits(child, parent);
    CHECK(avra_vtask_deadline(child) == avra_vtask_deadline(parent) && avra_vtask_deadline(child) != 0, "a virtual child inherits its spawner's limit");
    avra_vtask_within_end(parent, outer);
    CHECK(avra_vtask_deadline(parent) == 0 && avra_vtask_deadline(child) != 0, "and keeps it after the spawner's scope ends");
    avra_vtask_free(child);
    avra_vtask_free(parent);
}

// ── the shield: a `defer` runs whole, and waits only as long as it says ──

// The frame's cold exit brackets its deferred calls: the bit is saved and
// cleared so the calls are not cut between them, and put back at the end.
static void* shield_round_trip(void* self) {
    (void)self;
    avra_fiber_sleep(2);                    // cut by the cancel before it parks
    g_byte_a = avra_unwinding;              // 1
    avra_fiber_shield_enter();
    g_byte_b = avra_unwinding;              // 0: nothing inside is cut at a call
    avra_unwinding = 1;                     // a call inside reaches a cancel point
    avra_fiber_shield_leave();
    g_byte_c = avra_unwinding;              // 1: the saved bit comes back
    return answer(0);
}

static void a_shield_saves_and_restores_the_bit(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    void* t = spawn1(shield_round_trip, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a shielded task that was cancelled still ends cancelled");
    CHECK(g_byte_a == 1, "the cancel set the unwind bit at the cut sleep");
    CHECK(g_byte_b == 0, "the shield clears the bit while it stands");
    CHECK(g_byte_c == 1, "and the leave puts the saved bit back");
    avra_clock_run_ends();
}

// A bracket inside a bracket is the OUTERMOST that saves and restores: a
// deferred call's own cold exit nests without unshielding the defer.
static void* shield_nests(void* self) {
    (void)self;
    g_byte_a = avra_unwinding;              // 0
    avra_fiber_shield_enter();              // saved 0, clear
    avra_unwinding = 1;                     // a call under the outer shield reaches
    avra_fiber_shield_enter();              // depth 2: no second save, no clear
    g_byte_b = avra_unwinding;              // 1
    avra_fiber_shield_leave();              // depth 1: nothing restored
    g_byte_c = avra_unwinding;              // 1
    avra_fiber_shield_leave();              // depth 0: the saved bit ORs back
    g_byte_d = avra_unwinding;              // 1: the bit raised inside stands
    return answer(0);
}

static void a_nested_shield_does_not_restore_early(void) {
    bytes_unseen();
    void* t = spawn1(shield_nests, 0);
    CHECK(ended(t) == 2, "a bit raised inside the bracket still unwinds the task");
    CHECK(g_byte_a == 0, "the bit starts clear");
    CHECK(g_byte_b == 1, "a nested bracket does not clear the outer's work");
    CHECK(g_byte_c == 1, "nor does its leave restore the outer's saved bit");
    CHECK(g_byte_d == 1, "a bit raised inside the bracket stands after the outer leave");
}

// A CANCEL MET INSIDE THE SHIELD STANDS: the wait the bracket holds is cut
// by the standing cancel, which raises the bit, and the leave ORs the saved
// bit back without clearing it — a cancel from either side stands.
static void* shield_cancel_inside(void* self) {
    (void)self;
    avra_fiber_shield_enter();
    avra_fiber_sleep(2);                    // the standing cancel cuts this wait and raises the bit
    g_byte_a = avra_unwinding;              // 1
    avra_fiber_shield_leave();
    g_byte_b = avra_unwinding;              // 1: the leave does not clear it
    return answer(0);
}

static void a_cancel_met_inside_a_shield_survives(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    void* t = spawn1(shield_cancel_inside, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "a cancel met inside a shield still ends the task cancelled");
    CHECK(g_byte_a == 1, "the wait inside the shield raises the bit");
    CHECK(g_byte_b == 1, "and the leave does not clear it");
    avra_clock_run_ends();
}

// A checked back-edge in a shielded task yields and raises nothing.
static int g_tick_ran = 0;
static void* tick_neighbour(void* self) { (void)self; g_tick_ran = 1; return answer(0); }

static void* shielded_back_edge(void* self) {
    (void)self;
    avra_fiber_sleep(2);
    avra_fiber_shield_enter();
    void* n = spawn1(tick_neighbour, 0);
    g_tick_ran = 0;
    avra_tick = 1;
    avra_tick_cold();
    g_byte_a = avra_unwinding;              // 0: the bit was not raised
    g_byte_b = g_tick_ran;                  // 1: the back-edge yielded to the neighbour
    avra_fiber_shield_leave();
    ended(n);
    return answer(0);
}

static void a_shielded_back_edge_yields_and_raises_nothing(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    void* t = spawn1(shielded_back_edge, 0);
    avra_task_cancel(t);
    ended(t);
    CHECK(g_byte_a == 0, "a shielded back-edge raises no cancel");
    CHECK(g_byte_b == 1, "and it still yields to a ready task");
    avra_clock_run_ends();
}

// A `within` opened while shielded: its own limit alone cuts the wait.
static void* shield_scope_waits(void* self) {
    (void)self;
    avra_fiber_sleep(2);                    // cut; the bit is set
    g_byte_a = avra_unwinding;
    avra_fiber_shield_enter();
    int64_t scope = avra_fiber_within(5);
    avra_wait_gate(g_silent, 0, 0);
    int64_t claim = avra_wait_park();       // parks: the scope ignores the cancel
    g_byte_b = arm_of(claim) == -1 && member_of(claim) == 1;
    g_byte_c = avra_scope_end(scope) == 1;
    avra_fiber_shield_leave();
    g_byte_d = avra_unwinding;              // the saved bit comes back
    return answer(0);
}

static void a_shield_scope_waits_only_its_own_limit(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_silent = avra_gate_new();
    void* t = spawn1(shield_scope_waits, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the shielded task still ends cancelled");
    CHECK(g_byte_a == 1, "a cancel stood before the shield");
    CHECK(g_byte_b == 1, "a wait under a shield scope answers its own limit, not the cancel");
    CHECK(g_byte_c == 1, "and that scope's end lands it");
    CHECK(g_byte_d == 1, "the leave puts the saved bit back");
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}

// A cancel that arrives WHILE a shield-scope wait is parked does not claim it.
static void* shield_scope_parked(void* self) {
    (void)self;
    avra_fiber_sleep(2);                    // cut by the first ask: the bit is set
    avra_fiber_shield_enter();
    int64_t scope = avra_fiber_within(5);
    avra_wait_gate(g_silent, 0, 0);
    int64_t claim = avra_wait_park();
    g_byte_a = arm_of(claim) == -1 && member_of(claim) == 1;
    g_byte_b = avra_scope_end(scope) == 1;
    avra_fiber_shield_leave();
    return answer(0);
}

static void a_cancel_while_a_shield_scope_waits_does_not_claim_it(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_silent = avra_gate_new();
    void* t = spawn1(shield_scope_parked, 0);
    avra_task_cancel(t);                    // met at its first cancel point
    avra_fiber_sleep(1);                    // it parks under the shield scope
    avra_task_cancel(t);                    // a second ask while it is parked
    CHECK(ended(t) == 2, "the shielded task still ends cancelled");
    CHECK(g_byte_a == 1, "the parked wait is claimed by its own limit, not the cancel");
    CHECK(g_byte_b == 1, "and its scope's end lands it");
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}

// A sleep written inside a shield scope is not cut by the cancel either:
// it has its own time, and the `within` is the limit over that wait.
static void* shield_scope_sleeps(void* self) {
    (void)self;
    avra_fiber_sleep(2);                    // cut; the bit is set
    avra_fiber_shield_enter();
    int64_t scope = avra_fiber_within(1000);
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(5);
    g_spent_ms = ms_since(t0);
    g_byte_a = g_spent_ms >= 5;
    avra_scope_end(scope);
    avra_fiber_shield_leave();
    return answer(0);
}

static void a_shield_scope_sleep_is_not_cut(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    void* t = spawn1(shield_scope_sleeps, 0);
    avra_task_cancel(t);
    ended(t);
    CHECK(g_byte_a == 1, "a sleep under a shield scope is not cut by the cancel");
    avra_clock_run_ends();
}

// ── a deadline cuts a sleep and a join ──────────────────────────

// Forty ms of sleep under `cap` ms of limit: what the task held after.
static void* sleeps_under_a_limit(void* self) {
    g_outer = avra_fiber_within(cap(self));
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(40);
    g_spent_ms = ms_since(t0);
    g_byte_a = avra_unwinding;
    g_byte_b = avra_scope_end(g_outer);
    return answer(0);
}

// A forty-ms sleeper spawned under a limit, waited out by its owner.
static void* spawns_a_sleeper_under_a_limit(void* self) {
    (void)self;
    g_outer = avra_fiber_within(5);
    g_kid = spawn1(sleeper, 40);
    avra_task_settle(g_kid);
    g_byte_a = avra_task_ended(g_kid) == 2 && avra_task_ended_by(g_kid) == g_outer;
    avra_rc_release(g_kid);
    g_byte_b = avra_scope_end(g_outer);
    return answer(0);
}

static void deadline_cuts_sleep(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    CHECK(ended(spawn1(sleeps_under_a_limit, 5)) == 2, "a task whose sleep its deadline cut ends cancelled");
    CHECK(g_spent_ms >= 5 && g_spent_ms < 40, "the sleep ends where the limit passes");
    CHECK(g_byte_a == 1, "a sleep its deadline cuts sets the bit");
    CHECK(g_byte_b == 1, "and the scope that asked lands it");
    bytes_unseen();
    CHECK(ended(spawn1(sleeps_under_a_limit, 0)) == 2, "a sleep under a limit already passed ends its task cancelled");
    CHECK(g_spent_ms == 0 && g_byte_a == 1 && g_byte_b == 1, "it parks nothing, and the bit is set at once");
    bytes_unseen();
    CHECK(ended(spawn1(sleeps_under_a_limit, 5000)) == 1, "a sleep its limit outlasts answers");
    CHECK(g_spent_ms >= 40 && g_byte_a == 0 && g_byte_b == 0, "whole, with the bit clear and nothing to land");
    CHECK(avra_sched_timers() == 0, "no deadline stays filed");
    bytes_unseen();
    CHECK(ended(spawn1(spawns_a_sleeper_under_a_limit, 0)) == 1, "a spawner at no cancel point answers");
    CHECK(g_byte_a == 1, "a child whose sleep an inherited limit cut ends cancelled by the scope that asked");
    CHECK(g_byte_b == 0, "and the spawner's scope, which heard nothing, has nothing to land");
    avra_clock_run_ends();
}

// A join of a forty-ms task under `cap` ms of limit. The task is spawned
// before the scope, so the limit is the joiner's alone; its owner's
// settle then waits it out under the request that stands.
static void* joins_under_a_limit(void* self) {
    void* slow = spawn1(sleeper, 40);
    g_outer = avra_fiber_within(cap(self));
    int64_t t0 = avra_now_ns();
    void* got = avra_task_join(slow);
    g_spent_ms = ms_since(t0);
    g_byte_a = avra_unwinding;
    g_byte_c = got == NULL;
    avra_rc_release(got);
    g_byte_d = ended(slow) == 1 && ms_since(t0) >= 40;
    g_byte_b = avra_scope_end(g_outer);
    return answer(0);
}

static void deadline_cuts_join(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    CHECK(ended(spawn1(joins_under_a_limit, 5)) == 2, "a task whose join its deadline cut ends cancelled");
    CHECK(g_spent_ms >= 5 && g_spent_ms < 40, "the join ends where the limit passes");
    CHECK(g_byte_a == 1 && g_byte_c == 1, "a join its deadline cuts sets the bit and hands back no answer");
    CHECK(g_byte_d == 1, "a scope's end under the request that stands still waits its task out");
    CHECK(g_byte_b == 1, "and the scope that asked lands it");
    bytes_unseen();
    CHECK(ended(spawn1(joins_under_a_limit, 0)) == 2, "a join under a limit already passed ends its task cancelled");
    CHECK(g_spent_ms == 0 && g_byte_a == 1 && g_byte_c == 1 && g_byte_b == 1, "it parks nothing, and the bit is set at once");
    bytes_unseen();
    CHECK(ended(spawn1(joins_under_a_limit, 5000)) == 1, "a join its limit outlasts answers");
    CHECK(g_spent_ms >= 40 && g_byte_a == 0 && g_byte_c == 0 && g_byte_b == 0, "with the task's answer, the bit clear and nothing to land");
    CHECK(avra_sched_timers() == 0, "no deadline stays filed");
    avra_clock_run_ends();
}

// A scope's end parked on a forty-ms task when the limit passes. The
// sleep before it files the deadline.
static void* settles_under_a_limit(void* self) {
    (void)self;
    void* slow = spawn1(sleeper, 40);
    g_outer = avra_fiber_within(5);
    avra_fiber_sleep(1);
    int64_t t0 = avra_now_ns();
    g_byte_c = ended(slow) == 1;
    g_spent_ms = ms_since(t0);
    g_byte_a = avra_unwinding;
    g_byte_b = avra_scope_end(g_outer);
    return answer(0);
}

static void a_deadline_does_not_cut_a_scopes_end(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    bytes_unseen();
    CHECK(ended(spawn1(settles_under_a_limit, 0)) == 1, "a task whose scope's end outlived its limit answers");
    CHECK(g_byte_c == 1 && g_spent_ms >= 39, "a scope's end waits its task out past the limit");
    CHECK(g_byte_a == 0, "and no bit is set by it");
    CHECK(g_byte_b == 1, "though the scope's request stands for its next cancel point");
    avra_clock_run_ends();
}

// A sleep under a shield scope past that scope's own limit.
static void* shield_scope_sleeps_past_its_limit(void* self) {
    (void)self;
    avra_fiber_sleep(2);                    // cut by the cancel; the bit is set
    avra_fiber_shield_enter();
    int64_t scope = avra_fiber_within(5);
    int64_t t0 = avra_now_ns();
    avra_fiber_sleep(40);
    g_spent_ms = ms_since(t0);
    g_byte_a = avra_unwinding;              // raised inside the shield, by the wait
    g_byte_b = avra_scope_end(scope) == 1;
    avra_fiber_shield_leave();
    return answer(0);
}

static void a_shield_scope_sleep_is_cut_by_its_own_limit(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    void* t = spawn1(shield_scope_sleeps_past_its_limit, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the shielded task still ends cancelled");
    CHECK(g_spent_ms >= 5 && g_spent_ms < 40, "a sleep under a shield scope ends where that scope's limit passes");
    CHECK(g_byte_a == 1, "and raises the bit inside the shield");
    CHECK(g_byte_b == 1, "and that scope's end lands it");
    avra_clock_run_ends();
}

// A VIRTUAL TASK'S DEADLINE CUTS ITS SLEEP AND ITS JOIN: the claim
// readies it and sets its own unwind bit, and a request that stands
// parks neither.
static void virtual_deadline_cuts(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    int64_t vt = avra_vtask_new_at(11, 72);
    int64_t scope = avra_vtask_within(vt, 5);
    avra_vtask_sleep(vt, 10000);
    CHECK(avra_vtask_next() == vt, "a deadline readies the virtual task whose sleep it cut");
    CHECK(avra_vtask_unwinding(vt) == 1, "and sets its unwind bit");
    avra_vtask_set_unwinding(vt, 0);
    avra_vtask_sleep(vt, 10000);
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 1, "a sleep under the request that stands parks nothing and sets the bit");
    CHECK(avra_vtask_within_end(vt, scope) == 1, "and the scope that asked lands it");
    avra_vtask_free(vt);

    vt = avra_vtask_new_at(11, 73);
    void* end = avra_gate_new();
    scope = avra_vtask_within(vt, 5);
    CHECK(avra_vtask_cut(vt) == 0 && avra_vtask_unwinding(vt) == 0, "a join under a limit not yet passed may wait");
    CHECK(avra_vtask_join(vt, end) == 1, "and parks on the task's end");
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 1, "a deadline readies the virtual task whose join it cut, its bit set");
    CHECK(avra_vtask_cut(vt) == 1, "and a join under the request that stands must not wait");
    avra_vtask_within_end(vt, scope);
    avra_vtask_free(vt);

    vt = avra_vtask_new_at(11, 74);
    int64_t other = avra_vtask_new_at(11, 75);
    scope = avra_vtask_within(vt, 5);
    avra_vtask_sleep(vt, 1);
    CHECK(avra_vtask_next() == vt, "a sleep under its limit wakes at its time, the deadline filed");
    CHECK(avra_vtask_settle(vt, end) == 1, "a scope's end parks on the task's end");
    avra_vtask_sleep(other, 20);
    CHECK(avra_vtask_next() == other && avra_vtask_unwinding(vt) == 0, "a limit that passes cuts no scope's end");
    avra_vgate_ended(end, 75);
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 0, "the task's end wakes it, the bit clear");
    avra_vtask_within_end(vt, scope);
    avra_vtask_sleep(vt, 10000);
    avra_vtask_cancel(vt, 0);
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 1, "and a cancel cuts its next sleep: it is deaf no longer");
    avra_vtask_free(vt);
    avra_rc_release(end);

    vt = avra_vtask_new_at(11, 76);
    end = avra_gate_new();
    CHECK(avra_vtask_settle(vt, end) == 1, "a scope's end parks again");
    avra_vtask_cancel(vt, 0);
    avra_vtask_ready(other);
    CHECK(avra_vtask_next() == other && avra_vtask_unwinding(vt) == 0, "a cancel cuts no scope's end");
    avra_vgate_ended(end, 75);
    CHECK(avra_vtask_next() == vt, "the task's end wakes it");
    CHECK(avra_vtask_settle(vt, end) == 0, "and a scope's end of a task that has ended parks nothing");
    avra_vtask_free(other);
    avra_vtask_free(vt);
    avra_rc_release(end);

    vt = avra_vtask_new_at(11, 77);
    scope = avra_vtask_within(vt, 5);
    void* timed = avra_task_at(in_ms(60000));
    CHECK(avra_vtask_cut(vt) == 0 && avra_vtask_join(vt, timed) == 1, "a virtual task parks on a timer's task under its limit");
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 1, "and its deadline cuts that join too");
    avra_vtask_within_end(vt, scope);
    avra_task_cancel(timed);
    avra_rc_release(timed);
    avra_vtask_free(vt);

    vt = avra_vtask_new_at(11, 78);
    avra_vtask_cancel(vt, 0);
    CHECK(avra_vtask_cut(vt) == 1 && avra_vtask_unwinding(vt) == 1, "a cancel that stands on a virtual task parks no join either");
    avra_vtask_shield_enter(vt);
    scope = avra_vtask_within(vt, 5000);
    CHECK(avra_vtask_cut(vt) == 0 && avra_vtask_unwinding(vt) == 0, "under a shield scope the cancel cuts nothing: its own limit is what the wait is for");
    avra_vtask_within_end(vt, scope);
    avra_vtask_shield_leave(vt);
    avra_vtask_free(vt);
    avra_clock_run_ends();
}

// A DESCRIPTOR PARK IS CUT BY ITS TASK'S DEADLINE: the park answers that
// its time ran out with the bit raised, parked or under a limit passed
// already, and its own timeout stays a value.
static void virtual_deadline_cuts_fd_park(void) {
    int64_t vt = avra_vtask_new_at(11, 79);
    avra_vtask_sleep(vt, 1);
    CHECK(avra_vtask_next() == vt && avra_vtask_unwinding(vt) == 0, "a virtual sleep wakes at its time, the bit clear");
    int64_t scope = avra_vtask_within(vt, 5);
    CHECK(avra_vtask_park_fd(vt, g_pipe[0], 0, -1) == 1, "a virtual task parks on the descriptor under its limit");
    CHECK(avra_vtask_next() == vt && avra_vtask_timed_out(vt) == 1, "its deadline ends the park as time run out");
    CHECK(avra_vtask_unwinding(vt) == 1 && avra_vtask_interrupted(vt) == 0, "and raises its bit: a cut, no interrupt");
    avra_vtask_set_unwinding(vt, 0);
    CHECK(avra_vtask_park_fd(vt, g_pipe[0], 0, -1) == 0 && avra_vtask_timed_out(vt) == 1, "a park under the request that stands parks nothing");
    CHECK(avra_vtask_unwinding(vt) == 1 && avra_unwinding == 0, "and raises the task's own bit, never the running one");
    CHECK(avra_vtask_within_end(vt, scope) == 1 && avra_vtask_unwinding(vt) == 0, "the scope's landing ends the unwind and clears the bit");
    CHECK(avra_vtask_park_fd(vt, g_pipe[0], 0, 3) == 1, "the task parks on the descriptor for its own three ms");
    CHECK(avra_vtask_next() == vt && avra_vtask_timed_out(vt) == 1 && avra_vtask_unwinding(vt) == 0, "a park's own time is a value: no bit");
    avra_vtask_free(vt);
}

// ── a `within`'s landing ────────────────────────────────────────

// A gate park under `cap` ms of limit, then the landing.
static void* lands_its_own(void* self) {
    int64_t scope = avra_fiber_within(cap(self));
    avra_wait_gate(g_silent, 0, 0);
    avra_wait_park();
    g_byte_a = avra_unwinding;
    g_byte_b = avra_fiber_within_end(scope);
    g_byte_c = avra_unwinding;
    return answer(0);
}

// The outer limit passes under an inner scope: the inner's landing
// passes the unwind on, and the outer's ends it.
static void* lands_the_outer(void* self) {
    (void)self;
    int64_t outer = avra_fiber_within(5);
    int64_t inner = avra_fiber_within(5000);
    avra_fiber_sleep(40);
    g_byte_a = avra_fiber_within_end(inner) == 0 && avra_unwinding == 1;
    g_byte_b = avra_fiber_within_end(outer) == 1 && avra_unwinding == 0;
    return answer(0);
}

// The limit passes while the block waits at no cancel point: it answers.
static void* lands_nothing(void* self) {
    (void)self;
    int64_t scope = avra_fiber_within(5);
    avra_fiber_sleep(1);
    unheeding(40);
    g_byte_a = avra_task_request(g_me) == scope;
    g_byte_b = avra_fiber_within_end(scope);
    g_byte_c = avra_unwinding;
    return answer(0);
}

static void a_landing_ends_its_own_unwind(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_silent = avra_gate_new();
    bytes_unseen();
    CHECK(ended(spawn1(lands_its_own, 5)) == 1, "a task whose scope landed its own unwind answers");
    CHECK(g_byte_a == 1 && g_byte_b == 1 && g_byte_c == 0, "the landing answers 1 for the unwind its scope asked for, and clears the bit");
    bytes_unseen();
    CHECK(ended(spawn1(lands_the_outer, 0)) == 1, "a task whose outer scope landed answers");
    CHECK(g_byte_a == 1, "an inner scope's landing passes an outer's unwind on, the bit still set");
    CHECK(g_byte_b == 1, "and the outer's own landing ends it");
    bytes_unseen();
    g_me = spawn1(lands_nothing, 0);
    CHECK(ended(g_me) == 1, "a task whose block outlived its limit at no cancel point answers");
    CHECK(g_byte_a == 1, "the limit's request stood");
    CHECK(g_byte_b == 0 && g_byte_c == 0, "and the landing answers 0: nothing was cut, the block answered");
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}

// Without a `within` written in the defer, the wait cuts at once.
static void* plain_shield_wait(void* self) {
    (void)self;
    avra_fiber_sleep(2);
    avra_fiber_shield_enter();
    avra_wait_gate(g_silent, 0, 0);
    int64_t claim = avra_wait_park();
    g_byte_a = arm_of(claim) == -1 && member_of(claim) == 0;
    avra_fiber_shield_leave();
    return answer(0);
}

static void a_plain_shield_wait_still_cuts(void) {
    bytes_unseen();
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_silent = avra_gate_new();
    void* t = spawn1(plain_shield_wait, 0);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the task still ends cancelled");
    CHECK(g_byte_a == 1, "a wait under a plain shield answers the standing cancel at once");
    avra_rc_release(g_silent);
    avra_clock_run_ends();
}
// ── the unwind's frame list ─────────────────────────────────────
// A frame is one pointer, and the list lives on the task's record:
// sixteen kept, the middle dropped and counted once they fill, and the
// list emptied at the cancel point that begins an unwind.

static int64_t g_frame_marks[24];
static int64_t g_frame_n = -1;
static int64_t g_frame_dropped = -1;

static void* frame_marked(int64_t v) {
    void* a = avra_array_sized(1);
    avra_array_push(a, v);
    return a;
}
static int64_t frame_mark(void* box) { return box ? ((AvraArray*)box)->data[0] : -1; }

static void* pushes_twenty(void* self) {
    (void)self;
    void* held[20];
    for (int i = 0; i < 20; i++) { held[i] = frame_marked(i); avra_unwind_push(held[i]); }
    g_frame_n = avra_unwind_count();
    for (int64_t i = 0; i < g_frame_n && i < 24; i++) g_frame_marks[i] = frame_mark(avra_unwind_at(i));
    g_frame_dropped = avra_unwind_dropped();
    for (int i = 0; i < 20; i++) avra_rc_release(held[i]);
    return answer(0);
}

static void the_cap_drops_the_middle(void) {
    static const int64_t want[16] = { 0, 1, 2, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16, 17, 18, 19 };
    g_frame_n = -1;
    g_frame_dropped = -1;
    joined(spawn1(pushes_twenty, 0));
    CHECK(g_frame_n == 16, "twenty pushes leave sixteen frames");
    CHECK(memcmp(g_frame_marks, want, sizeof want) == 0, "the first eight stand, the middle is dropped, the newest eight follow");
    CHECK(g_frame_dropped == 4, "and four drops are counted");
}

// The program's own run keeps its frames as a task's record keeps its
// own.
static void the_programs_own_run_pushes(void) {
    void* a = frame_marked(7);
    avra_unwind_push(a);
    avra_unwind_push(a);
    CHECK(avra_unwind_count() == 2, "main's own frames stand");
    // `at(16)` is past the cap and lands on the list's own count — a word,
    // never a frame — so the bound must refuse it, not a zero sitting there.
    CHECK(avra_unwind_at(16) == NULL && avra_unwind_at(-1) == NULL, "and a read past them answers null");
    avra_rc_release(a);
}

static int64_t g_frame_before = -1;
static int64_t g_frame_after = -1;
static int64_t g_frame_again = -1;
static int64_t g_frame_held = -1;

static void* pushes_then_waits(void* self) {
    (void)self;
    void* a = frame_marked(1);
    void* b = frame_marked(2);
    avra_unwind_push(a);
    avra_unwind_push(b);
    g_frame_before = avra_unwind_count();
    avra_fiber_sleep(10000);
    g_frame_after = avra_unwind_count();
    void* c = frame_marked(3);
    avra_unwind_push(c);
    g_frame_again = avra_unwind_count();
    avra_fiber_sleep(10000);
    g_frame_held = avra_unwind_count();
    avra_rc_release(a);
    avra_rc_release(b);
    avra_rc_release(c);
    return answer(0);
}

static void a_cancel_point_begins_the_list(void) {
    avra_clock_run_begins();
    avra_clock_virtual(1);
    g_frame_before = g_frame_after = g_frame_again = g_frame_held = -1;
    void* t = spawn1(pushes_then_waits, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the task ends cancelled");
    CHECK(g_frame_before == 2, "two frames stood before the cancel point");
    CHECK(g_frame_after == 0, "and none after it: the list begins there");
    CHECK(g_frame_again == 1, "a frame pushed after it stands");
    CHECK(g_frame_held == 1, "and a later cancel point does not clear it again");
    avra_clock_run_ends();
}

int main(int argc, char** argv) {
    alarm(120);
    if (argc > 1 && strcmp(argv[1], "traced-scene") == 0) return traced_scene();
    if (argc > 1 && strcmp(argv[1], "sited-scene") == 0) return sited_scene();
    if (argc > 1 && strcmp(argv[1], "dropped-scene") == 0) return dropped_scene();
    if (pipe(g_pipe) != 0) { perror("pipe"); return 1; }
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
    in_child("a claimant takes the winner out of its list at the claim", winner_leaves_at_claim);
    in_child("a freed virtual task leaves every source it was filed with", freed_vtask_leaves_its_sources);
    in_child("a closed descriptor's number is watched afresh for its next tenant", closed_number_is_watched_afresh);
    in_child("a sleep and a reader among yielding tasks wake within reach", world_within_reach);
    in_child("a sleep and a deadline among tasks that compute between yields are heard within the window", timers_heard_within_the_window);
    in_child_within("a deadline is filed once, and heard", deadline_once, 10);
    in_child_within("a deadline reaches what it must, and no further", deadline_reach, 10);
    if (g_fails) {
        printf("flow: %d checks, %d failed — the rest would hang on what these hold\n", g_checks, g_fails);
        return 1;
    }
    trapped("a sleep inside a set", sleep_in_set, "a task waited inside a wait it had not parked");
    trapped("a join inside a set", join_in_set, "a task waited inside a wait it had not parked");
    trapped("a descriptor park inside a set", park_in_set, "a task waited inside a wait it had not parked");
    trapped("a descriptor direction past write", bad_direction, "a descriptor's waiters are read (0) or write (1)");
    trapped("a sleep after a wait an open gate claimed", sleep_in_claimed_set, "a task waited inside a wait it had not parked");
    stacks();

    int64_t live = avra_mem_live();
    three_sources_as_fibers();
    parked_counts();
    writable_fd_waits_twice();
    claim_then_cancel();
    // ON THE VIRTUAL CLOCK, each in a child: a clock that never moves is
    // a hang, which the short alarm turns into a failing check, and the
    // cases after them run on a clock nothing here can have left moved
    on_virtual_clock("a cancel cuts a sleep, on the virtual clock", cancel_cuts_sleep);
    on_virtual_clock("a join a cancel cuts", cut_join);
    on_virtual_clock("a join under a standing cancel", standing_join);
    on_virtual_clock("a join under a standing cancel of an unfinished task", standing_join_of_an_unfinished_task);
    on_virtual_clock("a scope's end cancels what it owns, then joins it", a_scopes_end_cancels_what_it_owns);
    in_child_within("a cut yield still switches", a_cut_yield_still_switches, 5);
    in_child_within("a cancel cuts a descriptor park", cancel_cuts_fd_park, 5);
    on_virtual_clock("a park a cancel or a deadline claims sets the bit", wait_park_sets_the_bit);
    in_child_within("a yield is a cancel point", a_yield_is_a_cancel_point, 5);
    in_child_within("a ready arm hears a cancel", a_ready_arm_hears_a_cancel, 10);
    in_child_within("a ready arm hears a limit", a_ready_arm_hears_a_limit, 10);
    in_child_within("a ready arm's turns ask the poller", a_ready_arms_turns_ask_the_poller, 10);
    in_child_within("every answered end draws the next stamp", stamps_follow_the_ends, 10);
    in_child_within("a due time is ready first", a_due_time_is_ready_first, 10);
    in_child_within("a scan hears a cancel", a_scan_hears_a_cancel, 10);
    in_child_within("a scan hears a limit", a_scan_hears_a_limit, 10);
    in_child_within("the scan outranks the claim", the_scan_outranks_the_claim, 10);
    in_child_within("a cancelled member is passed over", a_cancelled_member_is_passed_over, 10);
    in_child_within("due times go first", due_times_go_first, 10);
    in_child_within("a drawn stamp queues with the events", a_drawn_stamp_queues_with_the_events, 10);
    in_child_within("oldest-ready is bounded", oldest_ready_is_bounded, 10);
    on_virtual_clock("a limit wins its instant", a_limit_wins_its_instant);
    in_child_within("a counted site is kept", a_counted_site_is_kept, 10);
    in_child_within("overflow waiters are kept and trimmed", overflow_waiters_are_kept_and_trimmed, 10);
    trapped("a park with no arm filed", rests_on_nothing, "a `select` had no open arm");
    trapped("a scan begun inside a set", scans_inside_a_set, "a task waited inside a wait it had not parked");
    on_virtual_clock("a claim made before a cancel is taken first", claim_first_then_cancel);
    on_virtual_clock("a task cancelled before it runs meets the cancel at its first point", cancelled_before_it_runs);
    on_virtual_clock("the unwind bit is the running task's", the_bit_is_the_running_tasks);
    on_virtual_clock("a second cancel changes nothing", cancel_twice);
    on_virtual_clock("a cancel names its asker", a_cancel_names_its_asker);
    an_answer_names_the_task_itself();
    a_fiberless_end_names_its_asker();
    a_fiberless_answer_names_itself();
    in_child_within("a standing cancel parks no descriptor", a_standing_cancel_parks_no_descriptor, 5);
    on_virtual_clock("a cancel passes down a scope's join to what it owns", cancel_passes_down_a_scopes_join);
    on_virtual_clock("a join of a cancelled task passes its cancel on", join_of_cancelled);
    in_child("a join of a cancelled task nothing ran", joins_cancelled);
    on_virtual_clock("a passed cancel keeps a standing request", passed_cancel_keeps_a_standing_request);
    on_virtual_clock("a join of a cancelled task under a scope's unwind", scope_unwinding_join_of_cancelled);
    on_virtual_clock("a cut join of a task that answered meanwhile", cut_join_of_an_answered_task);
    trapped("a shielded join of a cancelled task", shielded_join_of_cancelled, "a join takes a task that answers, and this one was cancelled");
    in_child("a run's end, in words", a_run_end_in_words);
    said_within("a cancelled run", main_awaits_a_cancelled, "avra: main was cancelled — awaiting a task cancelled by task ", 60, 1);
    said_within("a run cancelled by its own ask", main_awaits_what_it_cancelled, "avra: main was cancelled — awaiting a task cancelled by main", 60, 1);
    on_virtual_clock("a caught join of a cancelled task", caught_join_of_cancelled);
    on_virtual_clock("a join of a cancelled task under a standing cancel", standing_join_of_cancelled);
    on_virtual_clock("a caught join names its asker", caught_join_names_its_asker);
    caught_join_of_answered();
    on_virtual_clock("a time due on a claimed set is dropped, on the virtual clock", due_on_a_claimed_set);
    on_virtual_clock("every scope keeps its own limit", every_scope_its_own_limit);
    in_child_within("scope ids never collide", scope_ids, 10);
    in_child_within("three scopes keep one deadline entry", one_entry_under_three_scopes, 5);
    on_virtual_clock("a fifth scope behaves as the four", a_fifth_scope);
    in_child_within("a deep nest of scopes ends in linear time", a_deep_nest_ends_in_linear_time, 30);
    trapped("a scope ended while one inside it stands", scope_ended_out_of_order, "a `within` ended while one inside it stands");
    on_virtual_clock("a task's cancel outranks a scope's request", task_cancel_outranks_a_scope);
    in_child_within("a scope's request does not displace a task's cancel", a_scope_does_not_displace_a_task_cancel, 5);
    on_virtual_clock("the outer scope's request stands", the_outer_request_stands);
    a_dropped_request_is_traced(argv[0]);
    in_child_within("a fork keeps the caller's scopes", forked_keeps_the_callers_scopes, 5);
    in_child_within("a virtual task inherits a scope", virtual_scopes, 5);
    a_shield_saves_and_restores_the_bit();
    a_cancel_met_inside_a_shield_survives();
    a_nested_shield_does_not_restore_early();
    a_shielded_back_edge_yields_and_raises_nothing();
    a_shield_scope_waits_only_its_own_limit();
    a_cancel_while_a_shield_scope_waits_does_not_claim_it();
    a_shield_scope_sleep_is_not_cut();
    a_shield_scope_sleep_is_cut_by_its_own_limit();
    a_plain_shield_wait_still_cuts();
    the_cap_drops_the_middle();
    the_programs_own_run_pushes();
    a_cancel_point_begins_the_list();
    fork_forgets_gate_waiters();
    fiberless_tasks();
    joins_of_tasks_nothing_runs();
    overflow_list();
    opened_gate();
    slots();
    ends_without_parking();
    fork_forgets_deadlines();
    claim_before_cancel();
    interrupt_is_its_own_claim();
    late_parker();
    late_parker_after_interrupt();
    timers_heard_within_the_window();
    timers_heard_within_the_window_among_bursts();
    world_within_reach();
    CHECK(avra_mem_live() == live, "the fibers leave nothing behind");
    virtual_cut_at_a_park();
    on_virtual_clock("a deadline cuts a sleep", deadline_cuts_sleep);
    on_virtual_clock("a deadline cuts a join", deadline_cuts_join);
    on_virtual_clock("a deadline does not cut a scope's end", a_deadline_does_not_cut_a_scopes_end);
    on_virtual_clock("a virtual task's deadline cuts its sleep and its join", virtual_deadline_cuts);
    in_child_within("a virtual task's deadline cuts its descriptor park", virtual_deadline_cuts_fd_park, 5);
    on_virtual_clock("a landing ends its own unwind", a_landing_ends_its_own_unwind);
    as_virtual();
    trace_names_virtual_tasks(argv[0]);
    trace_names_sites(argv[0]);
    closed(g_pipe[0]);
    closed(g_pipe[1]);

    printf("flow: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

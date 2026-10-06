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
static int filed(void* gate) { return ((AvraArray*)gate)->data[0] != 0; }

static int64_t g_log[64];
static int g_log_len = 0;
static void note(int64_t v) { if (g_log_len < 64) g_log[g_log_len++] = v; }
static int logged(const int64_t* want, int n) { return g_log_len == n && memcmp(g_log, want, (size_t)n * sizeof(int64_t)) == 0; }

static int g_pipe[2];
static void* g_gate;
static void* g_gates[6];
static void* g_task;
static int64_t g_handed = 0;
static int64_t g_seen = 0;

// ── a trap, in a child: its words and its status ────────────────

static void trapped(const char* what, void (*body)(void), const char* words) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm(60);
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
    snprintf(label, sizeof label, "%s exits 2", what);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2, label);
    snprintf(label, sizeof label, "%s says \"%s\"", what, words);
    CHECK(strstr(buf, words) != NULL, label);
}

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
    joined(t);
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
    joined(t);
    CHECK(g_log_len == 3 && g_log[0] == -100 && g_log[2] == -100, "a cancel first: the wait answers -1:0, and so does the next");
    avra_rc_release(g_gate);
}

// ── a cancel and the rows that predate the set ──────────────────

static void* sleeper(void* self) { int64_t t0 = now_ns(); avra_fiber_sleep(cap(self)); return answer((now_ns() - t0) / 1000000); }
static void* joiner(void* self) { (void)self; avra_rc_retain(g_task); return answer(joined(g_task)); }

static void cancel_and_old_rows(void) {
    g_task = spawn1(sleeper, 30);
    void* j = spawn1(joiner, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(g_task);
    avra_task_cancel(j);
    avra_fiber_sleep(5);
    CHECK(!avra_task_done(g_task) && !avra_task_done(j), "a cancel wakes neither a sleep nor a join");
    CHECK(joined(j) >= 29, "the join answers what the sleeper answered, after its whole sleep");
    CHECK(joined(g_task) >= 29, "the sleeper slept its time");
}

// ── one set at a time ───────────────────────────────────────────

static void* sleeps_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); avra_fiber_sleep(5); return answer(0); }
static void* joins_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); return answer(joined(spawn1(sleeper, 5))); }
static void* parks_in_a_set(void* self) { (void)self; avra_wait_gate(g_gate, 0, 0); return answer(avra_fiber_park_fd(g_pipe[0], 0, 5)); }
static void sleep_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(sleeps_in_a_set, 0)); }
static void join_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(joins_in_a_set, 0)); }
static void park_in_set(void) { g_gate = avra_gate_new(); joined(spawn1(parks_in_a_set, 0)); }

// ── a time falls due on a set already claimed ───────────────────

static void* gate_or_time(void* self) {
    avra_wait_gate(g_gate, 0, 1);
    avra_wait_until(in_ms(cap(self)), 1, 2);
    int64_t claim = avra_wait_park();
    return answer(arm_of(claim) * 100 + member_of(claim) + avra_sched_timers() * 1000);
}

static void due_on_a_claimed_set(void) {
    g_gate = avra_gate_new();
    void* t = spawn1(gate_or_time, 3);
    avra_fiber_sleep(1);
    CHECK(avra_gate_claim(g_gate) == 1, "the gate claims first");
    int64_t until = in_ms(6);
    while (now_ns() < until) {}
    avra_fiber_yield();
    CHECK(joined(t) == 1, "a time due on a claimed set is dropped: the task resumes on the gate's arm, the heap empty");
    avra_rc_release(g_gate);
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
// past the deadline, must not be cut short by it.
static void* sleeps_past_deadline(void* self) {
    int64_t outer = avra_fiber_within(15);
    avra_wait_gate(g_gate, 0, 0);
    avra_wait_park();
    int64_t t0 = now_ns();
    if (cap(self)) joined(spawn1(sleeper, 40)); else avra_fiber_sleep(40);
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
        CHECK(joined(t) >= 39, joins ? "a deadline filed by an earlier wait does not cut a join short" : "a deadline filed by an earlier wait does not cut a sleep short");
    }
    CHECK(avra_sched_timers() == 0, "and leaves the heap with its scope");

    int64_t outer = avra_fiber_within(8);
    t = spawn1(waits_reports, 0);
    avra_fiber_within_end(outer);
    CHECK(joined(t) == -99, "a task inherits its spawner's deadline: its wait answers -1:1 when that passes");
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

// ── a claim made while arming is heard before a standing cancel ─

static void* cancelled_then_handed(void* self) {
    (void)self;
    avra_wait_gate(g_gate, 3, 7);
    note(arm_of(avra_wait_park()));
    avra_wait_gate(g_gates[0], 5, 8);
    int64_t handed = avra_wait_park();
    note(arm_of(handed) * 100 + member_of(handed));
    avra_wait_gate(g_gate, 3, 7);
    note(arm_of(avra_wait_park()));
    return answer(0);
}

static void claim_before_cancel(void) {
    g_log_len = 0;
    g_gate = avra_gate_new();
    g_gates[0] = avra_gate_new();
    avra_vgate_open(g_gates[0]);
    void* t = spawn1(cancelled_then_handed, 0);
    avra_fiber_sleep(2);
    avra_task_cancel(t);
    joined(t);
    int64_t want[] = { -1, 508, -1 };
    CHECK(logged(want, 3), "under a standing cancel a wait a source claims while arming answers that source, and the next answers the cancel");
    avra_rc_release(g_gate);
    avra_rc_release(g_gates[0]);
}

// ── an interrupt reads as time, not readiness ───────────────────

static void* parks_on_pipe(void* self) { (void)self; return answer(avra_fiber_park_fd(g_pipe[0], 0, -1)); }

static void interrupt_is_time(void) {
    void* t = spawn1(parks_on_pipe, 0);
    avra_fiber_sleep(2);
    avra_fiber_fd_interrupt(g_pipe[0]);
    CHECK(joined(t) == 0, "a descriptor park that is interrupted answers as one whose time ran out");
    CHECK(avra_sched_fd_waiters() == 0, "and leaves the descriptor");
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
    int64_t vt = avra_vtask_new_at(0x1234);

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

int main(void) {
    alarm(120);
    trapped("a sleep inside a set", sleep_in_set, "a task waited inside a wait it had not parked");
    trapped("a join inside a set", join_in_set, "a task waited inside a wait it had not parked");
    trapped("a descriptor park inside a set", park_in_set, "a task waited inside a wait it had not parked");
    trapped("a sleep after a wait an open gate claimed", sleep_in_claimed_set, "a task waited inside a wait it had not parked");
    stacks();

    if (pipe(g_pipe) != 0) { perror("pipe"); return 1; }
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
    int64_t live = avra_mem_live();
    three_sources_as_fibers();
    claim_then_cancel();
    cancel_and_old_rows();
    due_on_a_claimed_set();
    fork_forgets_gate_waiters();
    fiberless_tasks();
    overflow_list();
    opened_gate();
    deadline_once();
    slots();
    ends_without_parking();
    deadline_reach();
    fork_forgets_deadlines();
    claim_before_cancel();
    interrupt_is_time();
    late_parker();
    CHECK(avra_mem_live() == live, "the fibers leave nothing behind");
    as_virtual();
    closed(g_pipe[0]);
    closed(g_pipe[1]);

    printf("flow: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

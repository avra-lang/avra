// THE SEEDED ORDER: a schedule names one order of the ready tasks, the
// same for a compiled program's fibers and for the evaluator's virtual
// tasks; schedule 0 is the queue's own order with its choices counted;
// and seeded or not, the poller keeps its cadence.
#include <fcntl.h>
#include <signal.h>
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
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "seed_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

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

static char g_log[64];
static int g_log_len = 0;
static void note(char c) { if (g_log_len < 63) g_log[g_log_len++] = c; g_log[g_log_len] = 0; }
static void fresh(void) { g_log_len = 0; g_log[0] = 0; }

// `body` in a child that a hang cannot outlive.
static void in_child(const char* what, void (*body)(void)) {
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        alarm(30);
        g_fails = 0;
        body();
        _exit(g_fails ? 1 : 0);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, what);
}

// ── one scenario, both engines ──────────────────────────────────
//
// Four tasks of three steps. Between its first and second step `a`
// waits on a task nothing runs, which `b` answers there; `c` makes a
// task the timer ends and waits on it; `d` makes one and JOINS it. The
// root joins all four.

enum { TASKS = 4 };
static void* g_pending = NULL;

static void* stepper(void* self) {
    char name = (char)cap(self);
    note(name);
    avra_fiber_yield();
    if (name == 'a') { avra_wait_task(g_pending, 0, 0); avra_wait_park(); }
    if (name == 'b') avra_task_answer(g_pending, NULL);
    if (name == 'c') {
        void* timed = avra_task_at(1);
        avra_wait_task(timed, 0, 0);
        avra_wait_park();
        avra_rc_release(timed);
    }
    if (name == 'd') {
        void* timed = avra_task_at(1);
        avra_rc_release(avra_task_join(timed));
        avra_rc_release(timed);
    }
    note(name);
    avra_fiber_yield();
    note(name);
    return NULL;
}

static void as_fibers(void) {
    void* t[TASKS];
    g_pending = avra_task_pending();
    for (int i = 0; i < TASKS; i++) t[i] = spawn1(stepper, 'a' + i);
    for (int i = 0; i < TASKS; i++) joined(t[i]);
    avra_rc_release(g_pending);
}

// The evaluator's shape: every task a step machine the policy names,
// the root one of them, a join filed with the driver, and a timer's
// task the runtime's own — waited on through its gate, never a task
// the policy names.
typedef struct { int64_t id; char name; int step, done, joined_by_root, parked, joins; void* timed; } Virtual;

static void as_virtual(void) {
    Virtual ts[TASKS + 1];
    memset(ts, 0, sizeof ts);
    g_pending = avra_task_pending();
    Virtual* root = &ts[TASKS];
    *root = (Virtual){ .id = avra_vtask_new(), .name = 'R' };
    for (int i = 0; i < TASKS; i++) {
        ts[i] = (Virtual){ .id = avra_vtask_new(), .name = (char)('a' + i) };
        avra_vtask_ready(ts[i].id);
    }
    for (Virtual* v = root;;) {
        int runs_on = 0;
        if (v == root) {
            while (v->step < TASKS && ts[v->step].done) v->step++;
            if (v->step == TASKS) break;
            ts[v->step].joined_by_root = 1;
        } else if (v->step == 0) {
            note(v->name);
            v->step = 1;
            avra_vtask_ready(v->id);
        } else if (v->step == 1) {
            v->step = 2;
            void* on = NULL;
            if (v->name == 'a') on = g_pending;
            if (v->name == 'b') avra_task_answer(g_pending, NULL);
            if (v->name == 'c') on = v->timed = avra_task_at(1);
            if (on) {
                avra_vtask_wait_gate(v->id, on, 0, 0);
                v->parked = (int)avra_vtask_park(v->id);
            }
            if (v->name == 'd') {
                v->timed = avra_task_at(1);
                v->joins = (int)avra_vtask_join(v->id, v->timed);
            }
            runs_on = !v->parked && !v->joins;
            if (on && runs_on) avra_vtask_claim(v->id);
        } else if (v->step == 2) {
            if (v->parked) avra_vtask_claim(v->id);
            v->parked = v->joins = 0;
            if (v->timed) avra_rc_release(v->timed);
            v->timed = NULL;
            note(v->name);
            v->step = 3;
            avra_vtask_ready(v->id);
        } else {
            note(v->name);
            v->done = 1;
            if (v->joined_by_root) avra_vtask_ready(root->id);
        }
        if (runs_on) continue;
        int64_t id = avra_vtask_next();
        for (int i = 0; i <= TASKS; i++) if (ts[i].id == id) v = &ts[i];
    }
    for (int i = 0; i <= TASKS; i++) avra_vtask_free(ts[i].id);
    avra_rc_release(g_pending);
}

static void engines_agree(void) {
    enum { SCHEDULES = 400 };
    int same = 0, distinct = 0, replayed = 0;
    static char seen[SCHEDULES][16];
    for (int64_t k = 0; k < SCHEDULES; k++) {
        char fibers[64], again[64];
        fresh(); avra_sched_seed(k); as_fibers(); avra_sched_settle(); strcpy(fibers, g_log);
        fresh(); avra_sched_seed(k); as_fibers(); avra_sched_settle(); strcpy(again, g_log);
        fresh(); avra_sched_seed(k); as_virtual(); avra_sched_settle();
        replayed += strcmp(fibers, again) == 0;
        same += strcmp(fibers, g_log) == 0;
        if (g_log_len != 3 * TASKS) same = -SCHEDULES;
        int known = 0;
        for (int i = 0; i < distinct; i++) known |= strcmp(seen[i], fibers) == 0;
        if (!known) strcpy(seen[distinct++], fibers);
    }
    CHECK(replayed == SCHEDULES, "one schedule gives one order, twice");
    CHECK(same == SCHEDULES, "fibers and virtual tasks agree on every schedule: a fiberless task, a timer's task waited on and one joined among them");
    CHECK(distinct > 40, "schedules reach many orders");
}

// ── schedule 0, a pick among one, every order ───────────────────

static void* notes_once(void* self) { note((char)cap(self)); return NULL; }

static void three_once(void) {
    void* t[3];
    for (int i = 0; i < 3; i++) t[i] = spawn1(notes_once, 'a' + i);
    for (int i = 0; i < 3; i++) joined(t[i]);
}

static void schedule_zero(void) {
    char unseeded[64];
    fresh(); as_fibers(); strcpy(unseeded, g_log);
    fresh(); avra_sched_seed(0); as_fibers();
    int64_t choices = avra_sched_settle();
    CHECK(strcmp(unseeded, g_log) == 0, "schedule 0 is the queue's own order");
    CHECK(choices > 0, "and its choices are counted");

    fresh(); avra_sched_seed(1);
    joined(spawn1(notes_once, 'x'));
    CHECK(avra_sched_settle() == 0, "a pick among one is no choice");

    fresh(); avra_sched_seed(1); three_once();
    CHECK(avra_sched_settle() == 2, "three tasks that run once are two choices: among three, then among two");
}

static void every_order(void) {
    static const char* orders[6] = { "abc", "acb", "bac", "bca", "cab", "cba" };
    int reached[6] = {0};
    for (int64_t k = 0; k < 64; k++) {
        fresh(); avra_sched_seed(k); three_once(); avra_sched_settle();
        for (int i = 0; i < 6; i++) reached[i] |= strcmp(g_log, orders[i]) == 0;
    }
    int n = 0;
    for (int i = 0; i < 6; i++) n += reached[i];
    CHECK(n == 6, "64 schedules reach all six orders of three tasks");
}

// ── the poller's cadence ────────────────────────────────────────

static int g_pipe[2];
static volatile int g_woke = 0;

static void* yields_n(void* self) {
    for (int64_t i = 0; i < cap(self); i++) avra_fiber_yield();
    return NULL;
}
static void* reads_pipe(void* self) {
    (void)self;
    avra_fiber_park_fd(g_pipe[0], 0, -1);
    g_woke = 1;
    return NULL;
}
static void* yields_until_woke(void* self) {
    for (int64_t i = 0; !g_woke && i < cap(self); i++) avra_fiber_yield();
    return NULL;
}

// Two yielders beside a reader parked for the whole run: how often the
// poller is asked, and how many of the switches were choices.
static void cadence(int64_t* polls, int64_t* choices, int seeded) {
    enum { YIELDS = 3200 };
    g_woke = 0;
    if (seeded) avra_sched_seed(3);
    void* r = spawn1(reads_pipe, 0);
    avra_fiber_yield();
    int64_t before = avra_sched_polls();
    void* a = spawn1(yields_n, YIELDS);
    void* b = spawn1(yields_n, YIELDS);
    joined(a);
    joined(b);
    *polls = avra_sched_polls() - before;
    CHECK(write(g_pipe[1], "p", 1) == 1, "the pipe takes a byte");
    joined(r);
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "and gives it back");
    *choices = seeded ? avra_sched_settle() : 0;
}

static void poller_cadence(void) {
    int64_t polls, choices, plain, none;
    cadence(&plain, &none, 0);
    cadence(&polls, &choices, 1);
    CHECK(plain >= 90 && plain <= 110, "unseeded, 6,400 switches beside a parked reader ask the poller about a hundred times");
    CHECK(polls >= 90 && polls <= 110, "seeded, the same: never a poll a switch");
    CHECK(choices >= 6300, "and every one of those switches is still a choice");
    cadence(&plain, &none, 0);
    CHECK(plain >= 90 && plain <= 110, "after a settle the poller's cadence is the unseeded one");
}

static void reader_among_yielders(void) {
    g_woke = 0;
    avra_sched_seed(5);
    void* r = spawn1(reads_pipe, 0);
    avra_fiber_yield();
    CHECK(write(g_pipe[1], "p", 1) == 1, "the pipe takes a byte");
    void* a = spawn1(yields_until_woke, 100000);
    void* b = spawn1(yields_until_woke, 100000);
    joined(a);
    joined(b);
    CHECK(g_woke, "a seeded run wakes a pipe's reader among tasks that never stop yielding");
    joined(r);
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "and its byte is read");
    avra_sched_settle();
}

// ── the pick is bounded ─────────────────────────────────────────

static void bounded_pick(void) {
    enum { CROWD = 10000, WINDOW = 16 };
    static void* t[CROWD];
    avra_sched_seed(7);
    int64_t links = avra_sched_pick_links();
    for (int i = 0; i < CROWD; i++) t[i] = spawn1(yields_n, 3);
    for (int i = 0; i < CROWD; i++) joined(t[i]);
    links = avra_sched_pick_links() - links;
    int64_t choices = avra_sched_settle();
    CHECK(choices >= 3 * CROWD, "ten thousand ready tasks are picked among");
    CHECK(links <= WINDOW * choices + CROWD, "and a pick walks at most sixteen links of the queue");
}

// ── after a settle ──────────────────────────────────────────────

static void settled(void) {
    avra_sched_seed(9);
    three_once();
    avra_sched_settle();
    int same = 1;
    for (int i = 0; i < 8; i++) {
        fresh(); three_once();
        same &= strcmp(g_log, "abc") == 0;
    }
    CHECK(same, "after a settle the order is the queue's own");
    int64_t links = avra_sched_pick_links();
    void* a = spawn1(yields_n, 1000);
    void* b = spawn1(yields_n, 1000);
    joined(a);
    joined(b);
    CHECK(avra_sched_pick_links() == links, "and no switch reaches the pick");
    int64_t asked = avra_sched_world_visits();
    a = spawn1(yields_n, 1000);
    b = spawn1(yields_n, 1000);
    joined(a);
    joined(b);
    CHECK(avra_sched_world_visits() - asked <= 4, "nor leaves the fast path: two thousand switches ask the world a handful of times");
}

// A forked child is a new program: its order is the queue's own.
static void child_of_a_seeded_run(void) {
    avra_fiber_forked();
    int64_t links = avra_sched_pick_links();
    int same = 1;
    for (int i = 0; i < 8; i++) {
        fresh(); three_once();
        same &= strcmp(g_log, "abc") == 0;
    }
    CHECK(same && avra_sched_pick_links() == links, "a forked child does not inherit its parent's schedule");
}

static void forked_while_seeded(void) {
    avra_sched_seed(11);
    in_child("a forked child of a seeded run is unseeded", child_of_a_seeded_run);
    avra_sched_settle();
}

int main(void) {
    alarm(120);
    if (pipe(g_pipe) != 0) { perror("pipe"); return 1; }
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
    in_child("a seeded run wakes a reader among yielding tasks", reader_among_yielders);
    if (g_fails) {
        printf("seed: %d checks, %d failed — the rest would hang on what this holds\n", g_checks, g_fails);
        return 1;
    }
    int64_t live = avra_mem_live();
    schedule_zero();
    every_order();
    engines_agree();
    poller_cadence();
    reader_among_yielders();
    bounded_pick();
    settled();
    forked_while_seeded();
    CHECK(avra_mem_live() == live, "a seeded run leaves nothing behind");
    avra_fiber_fd_closing(g_pipe[0]);
    close(g_pipe[0]);
    close(g_pipe[1]);
    printf("seed: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

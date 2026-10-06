// THE VIRTUAL CLOCK: frozen, time moves only when every task waits and
// then jumps to the earliest timer; it flows at wall rate while the
// world is held; it never goes back in the run that froze it; and a run
// inside another puts the outer clock back as it found it.
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
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "clock_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

enum { MS = 1000000 };
#define SECOND ((int64_t)1000 * MS)

static int64_t wall(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec;
}

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

static char g_log[32];
static int g_log_len = 0;
static void note(char c) { if (g_log_len < 31) g_log[g_log_len++] = c; g_log[g_log_len] = 0; }
static void fresh(void) { g_log_len = 0; g_log[0] = 0; }

// A trap in a child: its status and what it said.
static void trapped(const char* what, void (*body)(void), const char* words) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm(10);
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

// ── a sleep takes no wall time ──────────────────────────────────

static void* sleeps_ms(void* self) {
    avra_fiber_sleep(cap(self) / 1000);
    note((char)('a' + cap(self) % 1000));
    return NULL;
}
// A sleep of `ms`, noting letter `n` when it wakes.
static void* sleeper(int64_t ms, int n) { return spawn1(sleeps_ms, ms * 1000 + n); }

static void sleeps_jump(void) {
    avra_clock_virtual(1);
    int64_t w0 = wall(), c0 = avra_now_ns();
    avra_fiber_sleep(60000);
    CHECK(avra_now_ns() - c0 == 60 * SECOND, "a sleep of a minute moves the clock one minute, to the nanosecond");
    CHECK(wall() - w0 < SECOND, "and takes no wall time");

    fresh();
    c0 = avra_now_ns();
    int64_t jumps = avra_clock_jumps();
    void* t[3] = { sleeper(60000, 0), sleeper(30000, 1), sleeper(90000, 2) };
    for (int i = 0; i < 3; i++) joined(t[i]);
    CHECK(strcmp(g_log, "bac") == 0, "three sleeps wake in the order of their times");
    CHECK(avra_now_ns() - c0 == 90 * SECOND, "and the clock stands at the last one");
    CHECK(avra_clock_jumps() - jumps == 3, "by one jump a timer");
    CHECK(avra_now_ns() == avra_now_ns(), "frozen, two reads are one instant");
    c0 = avra_now_ns();
    CHECK(avra_clock_jumped(c0 - SECOND) == 1 && avra_now_ns() == c0, "a jump to a time already past moves nothing");
    avra_clock_virtual(0);
}

// Seeded and virtual at once: which task runs is the schedule's, when
// each wakes is the clock's.
static void seeded_too(void) {
    fresh();
    avra_sched_seed(3);
    avra_clock_virtual(1);
    int64_t w0 = wall(), c0 = avra_now_ns();
    void* t[3] = { sleeper(60000, 0), sleeper(30000, 1), sleeper(90000, 2) };
    for (int i = 0; i < 3; i++) joined(t[i]);
    CHECK(strcmp(g_log, "bac") == 0 && avra_now_ns() - c0 == 90 * SECOND && wall() - w0 < SECOND, "under a seeded order the clock jumps as it does unseeded");
    avra_clock_virtual(0);
    avra_sched_settle();
}

// ── it never goes back ──────────────────────────────────────────

static void never_back(void) {
    int64_t before = avra_now_ns();
    int64_t ahead = before - wall();
    avra_clock_virtual(1);
    int64_t frozen = avra_now_ns();
    CHECK(frozen >= before, "freezing does not move the clock back");
    avra_fiber_sleep(60000);
    int64_t after = avra_now_ns();
    avra_clock_virtual(0);
    int64_t flowing = avra_now_ns();
    CHECK(flowing >= after, "flowing again starts from where the clock stood");
    CHECK(flowing - wall() - ahead >= 59 * SECOND, "so it stays ahead of the wall by what it jumped");
    struct timespec nap = { 0, 3 * MS };
    nanosleep(&nap, NULL);
    CHECK(avra_now_ns() - flowing >= 2 * MS, "and it flows");
    avra_clock_virtual(0);
    CHECK(avra_now_ns() >= flowing, "switching off twice changes nothing");
}

// ── a timer filed before the freeze ─────────────────────────────

static void filed_before(void) {
    fresh();
    void* early = sleeper(40, 0);
    avra_fiber_yield();
    avra_clock_virtual(1);
    int64_t w0 = wall();
    void* late = sleeper(60000, 1);
    joined(early);
    joined(late);
    CHECK(strcmp(g_log, "ab") == 0, "a timer filed before the freeze fires at its time, before a later one");
    CHECK(wall() - w0 < SECOND, "with no wall time waited");
    avra_clock_virtual(0);
}

// ── a real descriptor waits in real time ────────────────────────

static int g_pipe[2];
static int64_t g_reader_woke = 0, g_reader_clock = 0, g_reader_wall = 0;

static void* reads_within_5s(void* self) {
    (void)self;
    g_reader_woke = avra_fiber_park_fd(g_pipe[0], 0, 5000);
    g_reader_clock = avra_now_ns();
    g_reader_wall = wall();
    return NULL;
}

static void world_and_time(void) {
    fresh();
    pid_t writer = fork();
    if (writer == 0) {
        struct timespec nap = { 0, 50 * MS };
        nanosleep(&nap, NULL);
        if (write(g_pipe[1], "w", 1) != 1) _exit(1);
        _exit(0);
    }
    avra_clock_virtual(1);
    int64_t w0 = wall(), c0 = avra_now_ns();
    void* r = spawn1(reads_within_5s, 0);
    void* s = sleeper(60000, 0);
    joined(r);
    CHECK(g_reader_woke == 1, "a reader under a five-second limit is woken by its pipe, not by the clock");
    CHECK(g_reader_wall - w0 >= 40 * MS, "after the wall time the writer took");
    CHECK(g_reader_clock - c0 >= 40 * MS && g_reader_clock - c0 < 4 * SECOND, "and the clock moved by that wall time, no further");
    joined(s);
    CHECK(avra_now_ns() - c0 == 60 * SECOND, "the sleeper beside it then wakes at its minute");
    CHECK(wall() - w0 < 4 * SECOND, "which no wall time was waited for");
    char c;
    CHECK(read(g_pipe[0], &c, 1) == 1, "the byte is read");
    waitpid(writer, NULL, 0);
    avra_clock_virtual(0);
}

// ── the world held from outside the scheduler ───────────────────

static void held(void) {
    avra_clock_virtual(1);
    avra_clock_hold(1);
    int64_t w0 = wall(), c0 = avra_now_ns();
    avra_fiber_sleep(30);
    CHECK(wall() - w0 >= 25 * MS, "held, a sleep takes its wall time");
    CHECK(avra_now_ns() - c0 >= 25 * MS && avra_now_ns() - c0 < 5 * SECOND, "and the clock flows with it");
    avra_clock_hold(1);
    avra_clock_hold(-1);
    w0 = wall();
    avra_fiber_sleep(20);
    CHECK(wall() - w0 >= 15 * MS, "a hold is a count: one of two given back still holds");
    avra_clock_hold(-1);
    w0 = wall();
    c0 = avra_now_ns();
    avra_fiber_sleep(60000);
    CHECK(wall() - w0 < SECOND && avra_now_ns() - c0 == 60 * SECOND, "let go, the clock is frozen again and a sleep jumps");

    avra_clock_hold(1);
    avra_clock_hold(1);
    CHECK(avra_clock_holds_dropped() == 2, "holds nobody is left to give back are dropped, and counted");
    w0 = wall();
    avra_fiber_sleep(60000);
    CHECK(wall() - w0 < SECOND, "and the clock is frozen again");
    CHECK(avra_clock_holds_dropped() == 0, "none stands after");
    avra_clock_virtual(0);

    avra_clock_hold(1);
    w0 = wall();
    avra_fiber_sleep(10);
    CHECK(wall() - w0 >= 8 * MS, "a hold on a clock that is not virtual changes nothing");
    avra_clock_hold(-1);
}

// ── a deadline reads the same clock ─────────────────────────────

static void* waits_on_a_gate_within_5s(void* self) {
    void* gate = (void*)(uintptr_t)cap(self);
    int64_t outer = avra_fiber_within(5000);
    avra_wait_gate(gate, 0, 0);
    int64_t claim = avra_wait_park();
    avra_fiber_within_end(outer);
    note(claim >> 32 == -1 && (int32_t)claim == 1 ? 'd' : '?');
    return NULL;
}

static void deadline_jumps(void) {
    fresh();
    void* gate = avra_gate_new();
    avra_clock_virtual(1);
    int64_t w0 = wall(), c0 = avra_now_ns();
    joined(spawn1(waits_on_a_gate_within_5s, (int64_t)(uintptr_t)gate));
    CHECK(strcmp(g_log, "d") == 0, "a wait under `within` ends by its deadline");
    CHECK(avra_now_ns() - c0 == 5 * SECOND && wall() - w0 < SECOND, "at five seconds of the clock and none of the wall");
    avra_clock_virtual(0);
    avra_rc_release(gate);
}

// ── waiting on the clock without sleeping ───────────────────────
//
// The limit is each child's own: the setting is read when a clock first
// freezes.

static void asks_most(const char* n) { setenv("AVRA_CLOCK_ASKS", n, 1); }

static void* yields_n(void* self) {
    for (int64_t i = 0; i < cap(self); i++) avra_fiber_yield();
    return NULL;
}
static void* yields_until_later(void* self) {
    (void)self;
    int64_t until = avra_now_ns() + MS;
    while (avra_now_ns() < until) avra_fiber_yield();
    return NULL;
}
static void spins_yielding(void) {
    asks_most("1000");
    avra_clock_virtual(1);
    void* other = spawn1(yields_n, (int64_t)1 << 40);
    joined(spawn1(yields_until_later, 0));
    joined(other);
}
static void spins_computing(void) {
    asks_most("1000");
    avra_clock_virtual(1);
    int64_t until = avra_now_ns() + MS;
    while (avra_now_ns() < until) {}
}
// Five thousand reads and done: a trap only because the setting says a
// thousand.
static void reads_past_its_setting(void) {
    asks_most("1000");
    avra_clock_virtual(1);
    int64_t sum = 0;
    for (int i = 0; i < 5000; i++) sum += avra_now_ns() & 1;
    _exit(sum < 0);
}
static void misspelled(void) {
    asks_most("many");
    avra_clock_virtual(1);
}

// TASKS THAT WORK THROUGH GATES, each reading the clock once a trip and
// nobody ever sleeping: no jump comes, and none of them is waiting on
// the clock — each parks, every trip.
enum { TRIPS = 100000 };
static void* g_gates[2];
static int64_t g_trips = 0;
static void* trips(void* self) {
    int me = (int)cap(self);
    for (;;) {
        g_trips += avra_now_ns() > 0;
        avra_gate_claim(g_gates[1 - me]);
        if (g_trips >= TRIPS) return NULL;
        avra_wait_gate(g_gates[me], 0, 0);
        avra_wait_park();
    }
}
static void working_through_gates(void) {
    asks_most("1000");
    avra_clock_virtual(1);
    g_gates[0] = avra_gate_new();
    g_gates[1] = avra_gate_new();
    g_trips = 0;
    void* a = spawn1(trips, 0);
    void* b = spawn1(trips, 1);
    joined(a);
    joined(b);
    CHECK(g_trips >= TRIPS, "tasks that park on a gate every trip read the clock as often as they like");

    // the scheduler reads the clock at every switch while a timer is
    // filed: those reads are its own
    void* s = sleeper(60000, 0);
    a = spawn1(yields_n, 50000);
    b = spawn1(yields_n, 50000);
    joined(a);
    joined(b);
    joined(s);

    // a task that reads much and sleeps between is not waiting on it
    int64_t sum = 0;
    for (int turn = 0; turn < 20; turn++) {
        for (int i = 0; i < 900; i++) sum += avra_now_ns() & 1;
        avra_fiber_sleep(1);
    }
    CHECK(sum >= 0, "a task that sleeps between its reads begins its count again");

    // the evaluator's reads are its host's, and begin again when one of
    // its tasks parks
    int64_t v = avra_vtask_new();
    for (int turn = 0; turn < 20; turn++) {
        for (int i = 0; i < 900; i++) sum += avra_now_ns() & 1;
        avra_vtask_sleep(v, 1);
        CHECK(avra_vtask_next() == v, "the sleeping virtual task is named at its time");
    }
    avra_vtask_free(v);
    avra_clock_virtual(0);
}

static void never_told(void) {
    asks_most("0");
    avra_clock_virtual(1);
    int64_t sum = 0;
    for (int i = 0; i < 3000000; i++) sum += avra_now_ns() & 1;
    CHECK(sum >= 0, "a limit of 0 never traps");
    avra_clock_virtual(0);
}

static void lets_go_twice(void) {
    avra_clock_hold(1);
    avra_clock_hold(-1);
    avra_clock_hold(-1);
}

// ── a run inside another ────────────────────────────────────────

static void run_in_a_run(void) {
    int64_t ahead = avra_now_ns() - wall();
    avra_clock_run_begins();
    int64_t w1 = wall();
    avra_fiber_sleep(10);
    CHECK(wall() - w1 >= 8 * MS, "a run begins on its host's clock: flowing, where its host's flows");
    avra_clock_virtual(1);
    int64_t c0 = avra_now_ns();
    avra_fiber_sleep(60000);
    CHECK(avra_now_ns() - c0 == 60 * SECOND, "and virtual once it says so");
    avra_clock_run_begins();
    avra_fiber_sleep(60000);
    avra_clock_run_ends();
    CHECK(avra_now_ns() - c0 == 60 * SECOND, "a run inside it leaves the outer run's clock where it stood");
    avra_clock_run_ends();
    int64_t drift = avra_now_ns() - wall() - ahead;
    CHECK(drift > -SECOND && drift < SECOND, "and when the run ends its host's clock is the one it had: no jump stays, and it is not virtual");
    struct timespec nap = { 0, 3 * MS };
    int64_t c1 = avra_now_ns();
    nanosleep(&nap, NULL);
    CHECK(avra_now_ns() - c1 >= 2 * MS, "flowing as before");

    avra_clock_virtual(1);
    avra_clock_hold(1);
    avra_clock_run_begins();
    int64_t w0 = wall();
    avra_fiber_sleep(60000);
    CHECK(wall() - w0 < SECOND, "a run begins with no hold, whatever its host holds");
    avra_clock_run_ends();
    w0 = wall();
    avra_fiber_sleep(20);
    CHECK(wall() - w0 >= 15 * MS, "and its host's hold stands again when it ends");
    avra_clock_hold(-1);
    avra_clock_run_begins();
    avra_clock_hold(1);
    avra_clock_run_ends();
    w0 = wall();
    avra_fiber_sleep(60000);
    CHECK(wall() - w0 < SECOND, "a hold a run left standing ends with the run");
    avra_clock_virtual(0);
    // the scheduler's bracket carries the clock's
    avra_sched_run_begins();
    avra_clock_virtual(1);
    avra_fiber_sleep(60000);
    avra_sched_run_ends();
    w0 = wall();
    avra_fiber_sleep(10);
    CHECK(wall() - w0 >= 8 * MS, "a run that ends takes its virtual clock with it, whichever bracket ended it");
}

// `body` in a child under a short alarm, its checks counted here: a
// break that turns a jump into a wait fails by a check, not by a bound.
static void in_child(const char* what, void (*body)(void)) {
    int counts[2];
    if (pipe(counts) != 0) { perror("pipe"); exit(1); }
    fflush(stderr);
    pid_t pid = fork();
    if (pid == 0) {
        alarm(10);
        g_checks = g_fails = 0;
        body();
        int said[2] = { g_checks, g_fails };
        if (write(counts[1], said, sizeof said) != sizeof said) _exit(3);
        _exit(g_fails ? 1 : 0);
    }
    close(counts[1]);
    int said[2] = { 0, 0 };
    if (read(counts[0], said, sizeof said) == sizeof said) { g_checks += said[0]; g_fails += said[1]; }
    close(counts[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    char label[200];
    snprintf(label, sizeof label, "%s — it ended, and not by its alarm", what);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) < 2, label);
}

static void leaves_nothing(void (*body)(void)) {
    int64_t live = avra_mem_live();
    body();
    CHECK(avra_mem_live() == live, "the clock leaves nothing behind");
}
static void jumps(void) { leaves_nothing(sleeps_jump); leaves_nothing(seeded_too); leaves_nothing(never_back); leaves_nothing(filed_before); }
static void world(void) {
    if (pipe(g_pipe) != 0) { perror("pipe"); exit(1); }
    fcntl(g_pipe[0], F_SETFL, O_NONBLOCK);
    leaves_nothing(world_and_time);
    avra_fiber_fd_closing(g_pipe[0]);
    close(g_pipe[0]);
    close(g_pipe[1]);
}
static void holds(void) { leaves_nothing(held); }
static void deadlines(void) { leaves_nothing(deadline_jumps); }
static void runs(void) { leaves_nothing(run_in_a_run); }

int main(void) {
    alarm(120);
    static const struct { const char* what; void (*body)(void); } groups[] = {
        { "sleeps jump and the clock never goes back", jumps },
        { "a real descriptor beside a sleeper", world },
        { "the world held", holds },
        { "a deadline on a gate", deadlines },
        { "a run inside a run", runs },
        { "tasks that work and read the clock", working_through_gates },
        { "a limit of none", never_told },
    };
    for (size_t i = 0; i < sizeof groups / sizeof groups[0]; i++) {
        in_child(groups[i].what, groups[i].body);
        if (g_fails) {
            printf("clock: %d checks, %d failed — stopped at the first group that failed\n", g_checks, g_fails);
            return 1;
        }
    }
    trapped("a task that yields until the clock moves", spins_yielding, "a task is waiting on the clock without sleeping");
    trapped("a task that computes until the clock moves", spins_computing, "AVRA_CLOCK_ASKS sets how many");
    trapped("a task that reads past the setting's limit", reads_past_its_setting, "read it 1000 times");
    trapped("a limit that is no number", misspelled, "AVRA_CLOCK_ASKS takes a whole number of reads, or 0 for never");
    trapped("a hold given back twice", lets_go_twice, "the world was let go more often than it was held");
    printf("clock: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

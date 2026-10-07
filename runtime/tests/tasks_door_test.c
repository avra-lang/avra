// THE LISTING AND ITS DOOR: `avra_tasks_listed` names every live task —
// where it was spawned and what it waits on — and a process that has
// spawned answers an ask file plus SIGURG with it at its next switch.
// Each scene runs as a child of this test, which asks it as
// `avra tasks <pid>` would.
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "tasks_door_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

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

static int g_ready_fd = -1;
// The scene has spawned and filed its waits: the asker may ask.
static void ready(void) {
    ssize_t w = write(g_ready_fd, "r", 1);
    (void)w;
    close(g_ready_fd);
}

// The door's directory, as `avra tasks` finds it: this user's own.
static char g_dir[200];
static const char* door_dir(void) {
#if defined(__APPLE__)
    size_t got = confstr(_CS_DARWIN_USER_TEMP_DIR, g_dir, sizeof g_dir);
    if (got == 0 || got > sizeof g_dir) snprintf(g_dir, sizeof g_dir, "/tmp/avra-%d/", (int)geteuid());
#else
    snprintf(g_dir, sizeof g_dir, "/tmp/avra-%d/", (int)geteuid());
    mkdir(g_dir, 0700);
    chmod(g_dir, 0700);
#endif
    return g_dir;
}

// ── the scenes, each run alone in a child ───────────────────────

static void* on_gate(void* self) {
    avra_wait_gate(cap(self), 0, 0);
    avra_wait_park();
    return NULL;
}
static void* on_fd(void* self) {
    avra_fiber_park_fd((int64_t)(intptr_t)cap(self), 0, -1);
    return NULL;
}
static void* on_time(void* self) {
    (void)self;
    avra_fiber_sleep(60000);
    return NULL;
}
static void* joins(void* self) {
    avra_rc_release(avra_task_join(cap(self)));
    return NULL;
}
static void* yields(void* self) {
    (void)self;
    for (;;) avra_fiber_yield();
    return NULL;
}
static void* spins(void* self) {
    (void)self;
    struct timespec t0, t;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    ready();
    do clock_gettime(CLOCK_MONOTONIC, &t); while (t.tv_sec - t0.tv_sec < 3);
    return NULL;
}

// A task in every state, listed by a direct call.
static int listed_scene(void) {
    int p[2];
    if (pipe(p) != 0) return 9;
    void* gated = spawn1(on_gate, avra_gate_new());
    spawn1(on_fd, (void*)(intptr_t)p[0]);
    spawn1(on_time, NULL);
    spawn1(joins, gated);
    avra_fiber_yield();
    spawn1(on_time, NULL);
    avra_tasks_listed(stdout);
    fflush(stdout);
    _exit(0);
}

// Tasks that only ever yield to each other: no timer, no descriptor —
// the switch's fast path alone, until it is asked.
static int yielding_scene(void) {
    void* a = spawn1(yields, NULL);
    spawn1(yields, NULL);
    avra_fiber_yield();
    ready();
    avra_rc_release(avra_task_join(a));
    return 0;
}

// The program asleep in the poller with nothing to wake it.
static int polled_scene(void) {
    int p[2];
    if (pipe(p) != 0) return 9;
    spawn1(on_gate, avra_gate_new());
    avra_fiber_yield();
    ready();
    avra_fiber_park_fd(p[0], 0, -1);
    return 0;
}

// A task that never switches for three seconds.
static int spinning_scene(void) {
    void* t = spawn1(spins, NULL);
    avra_rc_release(avra_task_join(t));
    return 0;
}

// A child forked after its parent spawned, asked under its own id: it
// says its id and sleeps in the poller; the parent sleeps too.
static int forked_scene(void) {
    int p[2];
    if (pipe(p) != 0) return 9;
    spawn1(on_gate, avra_gate_new());
    avra_fiber_yield();
    pid_t child = fork();
    if (child == 0) {
        avra_fiber_forked();
        spawn1(on_gate, avra_gate_new());
        avra_fiber_yield();
        char said[24];
        int n = snprintf(said, sizeof said, "%d", (int)getpid());
        ssize_t w = write(g_ready_fd, said, (size_t)n);
        (void)w;
        close(g_ready_fd);
        avra_fiber_park_fd(p[0], 0, -1);
        _exit(0);
    }
    close(g_ready_fd);
    avra_fiber_park_fd(p[0], 0, -1);
    return 0;
}

// The program asleep on a pipe the asker fills a byte at a time: it
// wakes, reads, and sleeps again — so an ask lands anywhere around the
// world's sleep.
static int pipeloop_scene(int fd) {
    spawn1(on_gate, avra_gate_new());
    avra_fiber_yield();
    ready();
    for (char b;;) {
        avra_fiber_park_fd(fd, 0, -1);
        ssize_t got = read(fd, &b, 1);
        if (got <= 0) return 0;
    }
}

// A hundred thousand tasks, so a listing takes long enough to be asked
// again while it is written; the program asleep in the poller.
static int crowded_scene(void) {
    int p[2];
    if (pipe(p) != 0) return 9;
    for (int i = 0; i < 100000; i++) spawn1(on_time, NULL);
    ready();
    avra_fiber_park_fd(p[0], 0, -1);
    return 0;
}

// An evaluated program's task taken from the policy, then spinning:
// the host's own task is not the one running.
static int vspin_scene(void) {
    int64_t root = avra_vtask_new_at(0, 0);
    int64_t five = avra_vtask_new_at(0, 5);
    (void)root;
    avra_vtask_ready(five);
    if (avra_vtask_next() != five) return 9;
    struct timespec t0, t;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    ready();
    do clock_gettime(CLOCK_MONOTONIC, &t); while (t.tv_sec - t0.tv_sec < 3);
    return 0;
}

// A SIGURG handler the program installed before it spawned: still called.
static char g_prior_mark[256];
static void prior_urg(int sig) {
    (void)sig;
    int fd = open(g_prior_mark, O_WRONLY | O_CREAT, 0600);
    if (fd >= 0) close(fd);
}
static int prior_scene(void) {
    int p[2];
    if (pipe(p) != 0) return 9;
    snprintf(g_prior_mark, sizeof g_prior_mark, "%savra-tasks.%d.prior", door_dir(), (int)getpid());
    signal(SIGURG, prior_urg);
    spawn1(on_gate, avra_gate_new());
    avra_fiber_yield();
    ready();
    avra_fiber_park_fd(p[0], 0, -1);
    return 0;
}

// A task asked while it spins, which forks: the child owes nothing of
// its parent's ask, spins in its turn, and is asked once.
static void* forks_spinning(void* self) {
    (void)self;
    raise(SIGURG);
    pid_t child = fork();
    if (child == 0) {
        avra_fiber_forked();
        char said[24];
        int n = snprintf(said, sizeof said, "%d", (int)getpid());
        ssize_t w = write(g_ready_fd, said, (size_t)n);
        (void)w;
        close(g_ready_fd);
        struct timespec t0, t;
        clock_gettime(CLOCK_MONOTONIC, &t0);
        do clock_gettime(CLOCK_MONOTONIC, &t); while (t.tv_sec - t0.tv_sec < 2);
        _exit(0);
    }
    close(g_ready_fd);
    return NULL;
}
static int forked_asked_scene(void) {
    void* t = spawn1(forks_spinning, NULL);
    avra_rc_release(avra_task_join(t));
    pause();
    return 0;
}

// A process that never spawned: the signal's own default.
static int unspawned_scene(void) {
    ready();
    usleep(400000);
    return 0;
}

// ── the asker ───────────────────────────────────────────────────

typedef struct { pid_t pid, scene; char ask[256], out[256]; } Child;

static Child scene_with(const char* self, const char* name, int extra) {
    int p[2];
    if (pipe(p) != 0) { perror("pipe"); exit(1); }
    Child c;
    c.pid = fork();
    if (c.pid == 0) {
        close(p[0]);
        char fd[16], more[16];
        snprintf(fd, sizeof fd, "%d", p[1]);
        snprintf(more, sizeof more, "%d", extra);
        execl(self, self, name, fd, more, (char*)NULL);
        _exit(9);
    }
    close(p[1]);
    char said[24] = {0};
    ssize_t got = read(p[0], said, sizeof said - 1);
    close(p[0]);
    // a scene that forked names the process to ask
    c.scene = c.pid;
    if (got > 1) c.pid = (pid_t)atoi(said);
    snprintf(c.ask, sizeof c.ask, "%savra-tasks.%d.ask", door_dir(), (int)c.pid);
    snprintf(c.out, sizeof c.out, "%savra-tasks.%d", door_dir(), (int)c.pid);
    unlink(c.out);
    return c;
}

static Child scene(const char* self, const char* name) { return scene_with(self, name, -1); }

static void asked(const Child* c) {
    int fd = open(c->ask, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd >= 0) close(fd);
}

// What the child answered within `ms`, or "" — read into `buf`.
static const char* answered(const Child* c, char* buf, size_t cap, int ms) {
    buf[0] = 0;
    for (int waited = 0; waited <= ms; waited += 2) {
        FILE* f = fopen(c->out, "r");
        if (f) {
            size_t n = fread(buf, 1, cap - 1, f);
            buf[n] = 0;
            fclose(f);
            return buf;
        }
        usleep(2000);
    }
    return buf;
}

// ASKED AS `avra tasks` ASKS: a signal, a tenth of a second, and again,
// up to `tries` times. A zero the handler stores can be lost to a switch
// it interrupted between the countdown's load and store, so one signal
// is never the whole ask.
static const char* asked_again(const Child* c, char* buf, size_t cap, int tries) {
    buf[0] = 0;
    for (int i = 0; i < tries && !buf[0]; i++) {
        kill(c->pid, SIGURG);
        answered(c, buf, cap, 100);
    }
    return buf;
}

// The child has finished answering: it takes the ask away after the
// answer stands, so an ask written before that would be taken too.
static void settled(const Child* c) {
    for (int waited = 0; waited < 500 && access(c->ask, F_OK) == 0; waited += 1) usleep(1000);
}

static int ended(Child* c) {
    kill(c->pid, SIGKILL);
    if (c->scene != c->pid) kill(c->scene, SIGKILL);
    int status = 0;
    waitpid(c->scene, &status, 0);
    unlink(c->ask);
    unlink(c->out);
    return status;
}

static int alive(const Child* c) { return kill(c->pid, 0) == 0; }

static void listing(const char* self) {
    int p[2];
    if (pipe(p) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(p[1], 1);
        close(p[0]);
        execl(self, self, "listed", "-1", (char*)NULL);
        _exit(9);
    }
    close(p[1]);
    char buf[4096] = {0};
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(p[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    close(p[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "the listed scene runs");
    CHECK(strstr(buf, "6 task(s)") != NULL, "the listing counts the program's own run and five tasks");
    CHECK(strstr(buf, "task 0, the program's own run, running") != NULL, "the asker's own task is running");
    CHECK(strstr(buf, "task 1, spawned at 0x") != NULL && strstr(buf, "waits on gate 0x") != NULL, "a task on a gate");
    CHECK(strstr(buf, "waits on descriptor") != NULL, "a task on a descriptor");
    CHECK(strstr(buf, "waits on a time") != NULL, "a task asleep");
    CHECK(strstr(buf, "joins task 1") != NULL, "a join names the task it waits for");
    CHECK(strstr(buf, "task 5, spawned at 0x") != NULL && strstr(buf, "task 5, spawned at 0x") && strstr(strstr(buf, "task 5,"), "ready, not yet run") != NULL, "a task that has not run");
    CHECK(strstr(buf, "task 1, spawned at 0x") && strstr(strstr(buf, "task 1,"), "spawned at most") != NULL, "a task says how long ago it was spawned, at most");
    const char* one = strstr(buf, "task 1,");
    const char* four = strstr(buf, "task 4,");
    CHECK(one && four && one < four, "oldest first");
}

static void door(const char* self) {
    char buf[4096];
    // Asked forty times, as `avra tasks` asks: a signal can land between
    // the countdown's load and store and lose its zero, so the next one
    // must bring the listing — never the line that says no task switched.
    Child c = scene(self, "yielding");
    int listed_each = 1, never_unswitched = 1;
    for (int turn = 0; turn < 40 && listed_each; turn++) {
        unlink(c.out);
        asked(&c);
        asked_again(&c, buf, sizeof buf, 20);
        settled(&c);
        listed_each &= strstr(buf, "task 1, spawned at") != NULL && strstr(buf, "task 2, spawned at") != NULL;
        never_unswitched &= strstr(buf, "has not switched") == NULL;
    }
    CHECK(listed_each, "tasks that only yield answer at their next switch, every time");
    CHECK(never_unswitched, "and a switching program is never said not to switch");
    CHECK(access(c.ask, F_OK) != 0, "an answered ask is taken away");
    CHECK(alive(&c), "and the program runs on");
    ended(&c);

    c = scene(self, "polled");
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 2000);
    CHECK(strstr(buf, "task 0, the program's own run, waits on descriptor") != NULL, "a program asleep in the poller is woken to answer");
    CHECK(alive(&c), "and sleeps on");
    ended(&c);

    c = scene(self, "polled");
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 400);
    CHECK(buf[0] == 0, "a signal with no ask answers nothing");
    CHECK(alive(&c), "and harms nothing");
    ended(&c);

    c = scene(self, "polled");
    if (symlink("/dev/null", c.ask) == 0) {
        kill(c.pid, SIGURG);
        answered(&c, buf, sizeof buf, 400);
        CHECK(buf[0] == 0, "an ask that is no plain file of ours answers nothing");
    }
    ended(&c);

    c = scene(self, "spinning");
    asked(&c);
    kill(c.pid, SIGURG);
    usleep(150000);
    CHECK(access(c.out, F_OK) != 0, "a task that does not switch answers nothing at the first ask");
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 1000);
    CHECK(strstr(buf, "task 1, running, has not switched since it was asked") != NULL, "the second ask is answered by the handler itself");
    ended(&c);

    c = scene(self, "forked");
    char parent[256];
    snprintf(parent, sizeof parent, "%savra-tasks.%d", door_dir(), (int)c.scene);
    unlink(parent);
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 2000);
    char header[48];
    snprintf(header, sizeof header, "process %d,", (int)c.pid);
    CHECK(strstr(buf, header) != NULL && strstr(buf, "task 2, spawned at") != NULL, "a forked child answers under its own id");
    CHECK(access(parent, F_OK) != 0, "and never under its parent's");
    ended(&c);

    // M1: an ask that lands around the world's sleep is answered, and
    // never by "has not switched" about a process that is asleep.
    int fill[2];
    if (pipe(fill) != 0) { perror("pipe"); exit(1); }
    c = scene_with(self, "pipeloop", fill[0]);
    close(fill[0]);
    int answered_each = 1, never_false = 1;
    for (int trial = 0; trial < 300 && answered_each; trial++) {
        unlink(c.out);
        asked(&c);
        ssize_t w = write(fill[1], "b", 1);
        (void)w;
        for (volatile int spin = 0; spin < (trial * 7919) % 4000; spin++) {}
        asked_again(&c, buf, sizeof buf, 20);
        settled(&c);
        answered_each &= strstr(buf, "process ") == buf;
        never_false &= strstr(buf, "has not switched") == NULL;
    }
    CHECK(answered_each, "an ask around the world's sleep is answered with the listing");
    CHECK(never_false, "and a sleeping process is never said not to switch");
    close(fill[1]);
    ended(&c);

    // M2: asked again while a long listing is written, the listing stands.
    c = scene(self, "crowded");
    asked(&c);
    kill(c.pid, SIGURG);
    for (int more = 0; more < 4; more++) {
        usleep(5000);
        kill(c.pid, SIGURG);
    }
    answered(&c, buf, sizeof buf, 5000);
    CHECK(strstr(buf, "process ") == buf && strstr(buf, "100001 task(s)") != NULL, "asks during a long listing never replace it");
    ended(&c);

    // M3: an evaluated program's spinning task is not named by the host's id.
    c = scene(self, "vspin");
    asked(&c);
    kill(c.pid, SIGURG);
    usleep(150000);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 1000);
    CHECK(strstr(buf, "the evaluated program has not switched since it was asked") == buf, "an evaluated program that does not switch is said so, with no task named");
    ended(&c);

    // a handler the program set first is still called, and the door answers
    c = scene(self, "prior");
    char mark[256];
    snprintf(mark, sizeof mark, "%savra-tasks.%d.prior", door_dir(), (int)c.pid);
    unlink(mark);
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 2000);
    CHECK(strstr(buf, "process ") == buf, "a program with a SIGURG handler of its own still answers");
    CHECK(access(mark, F_OK) == 0, "and its own handler is still called");
    unlink(mark);
    ended(&c);

    // a forked child owes nothing of an ask its parent had not answered
    c = scene(self, "forked-asked");
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 300);
    CHECK(strstr(buf, "has not switched") == NULL, "a child's first ask is never taken for a second");
    ended(&c);

#if !defined(__APPLE__)
    // M5: a door directory others may write is no door
    c = scene(self, "polled");
    chmod(door_dir(), 0755);
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 400);
    CHECK(buf[0] == 0, "a door directory that is not the user's alone answers nothing");
    chmod(door_dir(), 0700);
    ended(&c);
#endif

    c = scene(self, "unspawned");
    kill(c.pid, SIGURG);
    int status = 0;
    waitpid(c.pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 0, "a process that never spawned ignores the signal");
}

int main(int argc, char** argv) {
    if (argc > 2) {
        g_ready_fd = atoi(argv[2]);
        if (strcmp(argv[1], "listed") == 0) return listed_scene();
        if (strcmp(argv[1], "yielding") == 0) return yielding_scene();
        if (strcmp(argv[1], "polled") == 0) return polled_scene();
        if (strcmp(argv[1], "spinning") == 0) return spinning_scene();
        if (strcmp(argv[1], "unspawned") == 0) return unspawned_scene();
        if (strcmp(argv[1], "forked") == 0) return forked_scene();
        if (strcmp(argv[1], "pipeloop") == 0) return pipeloop_scene(atoi(argv[3]));
        if (strcmp(argv[1], "crowded") == 0) return crowded_scene();
        if (strcmp(argv[1], "vspin") == 0) return vspin_scene();
        if (strcmp(argv[1], "prior") == 0) return prior_scene();
        if (strcmp(argv[1], "forked-asked") == 0) return forked_asked_scene();
        return 9;
    }
    listing(argv[0]);
    door(argv[0]);
    printf("tasks_door: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

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

// A process that never spawned: the signal's own default.
static int unspawned_scene(void) {
    ready();
    usleep(400000);
    return 0;
}

// ── the asker ───────────────────────────────────────────────────

typedef struct { pid_t pid, scene; char ask[64], out[64]; } Child;

static Child scene(const char* self, const char* name) {
    int p[2];
    if (pipe(p) != 0) { perror("pipe"); exit(1); }
    Child c;
    c.pid = fork();
    if (c.pid == 0) {
        close(p[0]);
        char fd[16];
        snprintf(fd, sizeof fd, "%d", p[1]);
        execl(self, self, name, fd, (char*)NULL);
        _exit(9);
    }
    close(p[1]);
    char said[24] = {0};
    ssize_t got = read(p[0], said, sizeof said - 1);
    close(p[0]);
    // a scene that forked names the process to ask
    c.scene = c.pid;
    if (got > 1) c.pid = (pid_t)atoi(said);
    snprintf(c.ask, sizeof c.ask, "/tmp/avra-tasks.%d.ask", (int)c.pid);
    snprintf(c.out, sizeof c.out, "/tmp/avra-tasks.%d", (int)c.pid);
    unlink(c.out);
    return c;
}

static void asked(const Child* c) {
    int fd = open(c->ask, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd >= 0) close(fd);
}

// What the child answered within `ms`, or "" — read into `buf`.
static const char* answered(const Child* c, char* buf, size_t cap, int ms) {
    buf[0] = 0;
    for (int waited = 0; waited <= ms; waited += 20) {
        FILE* f = fopen(c->out, "r");
        if (f) {
            size_t n = fread(buf, 1, cap - 1, f);
            buf[n] = 0;
            fclose(f);
            return buf;
        }
        usleep(20000);
    }
    return buf;
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
    CHECK(strstr(buf, "first ran at most") != NULL, "a task that ran says for how long at most");
    const char* one = strstr(buf, "task 1,");
    const char* four = strstr(buf, "task 4,");
    CHECK(one && four && one < four, "oldest first");
}

static void door(const char* self) {
    char buf[4096];
    // Asked forty times: on a machine whose decrement is a load and a
    // store, some first signal lands between the two and its zero is
    // lost — and the second signal must bring the listing, never the
    // line that says no task switched.
    Child c = scene(self, "yielding");
    int listed_each = 1, never_unswitched = 1;
    for (int turn = 0; turn < 40 && listed_each; turn++) {
        unlink(c.out);
        asked(&c);
        kill(c.pid, SIGURG);
        answered(&c, buf, sizeof buf, 300);
        if (!buf[0]) {
            kill(c.pid, SIGURG);
            answered(&c, buf, sizeof buf, 1000);
        }
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
    char parent[64];
    snprintf(parent, sizeof parent, "/tmp/avra-tasks.%d", (int)c.scene);
    unlink(parent);
    asked(&c);
    kill(c.pid, SIGURG);
    answered(&c, buf, sizeof buf, 2000);
    char header[48];
    snprintf(header, sizeof header, "process %d,", (int)c.pid);
    CHECK(strstr(buf, header) != NULL && strstr(buf, "task 2, spawned at") != NULL, "a forked child answers under its own id");
    CHECK(access(parent, F_OK) != 0, "and never under its parent's");
    ended(&c);

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
        return 9;
    }
    listing(argv[0]);
    door(argv[0]);
    printf("tasks_door: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

// WHAT A SEEDED SWITCH COSTS BESIDE THE QUEUE'S OWN: n tasks all ready,
// each yielding, unseeded, under schedule 0 (the queue's order, through
// the pick) and under schedule 1 (drawn); then two yielders beside a
// reader parked on a pipe, with how often the poller was asked.
// Prints `<key> <total ns> <count>`.
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

#include "avra_box.h"
#include "avra_fiber.h"
#include "avra_runtime.h"

typedef void* (*Code)(void*);

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static void joined(void* task) { avra_rc_release(avra_task_join(task)); avra_rc_release(task); }

static void* yields_n(void* self) {
    int64_t n = ((AvraArray*)self)->data[1];
    for (int64_t i = 0; i < n; i++) avra_fiber_yield();
    return NULL;
}

static int g_pipe[2];
static void* reads_pipe(void* self) { (void)self; avra_fiber_park_fd(g_pipe[0], 0, -1); return NULL; }

enum { MOST = 20000 };
static void* g_tasks[MOST];

// `tasks` ready at once, `turns` yields each, timed from the first join.
static void crowd(const char* how, int64_t schedule, int tasks, int turns) {
    if (schedule >= 0) avra_sched_seed(schedule);
    for (int i = 0; i < tasks; i++) g_tasks[i] = spawn1(yields_n, turns);
    double t0 = now_ns();
    for (int i = 0; i < tasks; i++) joined(g_tasks[i]);
    double took = now_ns() - t0;
    if (schedule >= 0) avra_sched_settle();
    printf("switch_%d_ready_%s %.0f %lld\n", tasks, how, took, (long long)tasks * turns);
}

static void beside_a_reader(const char* how, int64_t schedule) {
    enum { YIELDS = 20000 };
    if (schedule >= 0) avra_sched_seed(schedule);
    void* r = spawn1(reads_pipe, 0);
    avra_fiber_yield();
    int64_t polls = avra_sched_polls();
    void* a = spawn1(yields_n, YIELDS);
    void* b = spawn1(yields_n, YIELDS);
    double t0 = now_ns();
    joined(a);
    joined(b);
    double took = now_ns() - t0;
    polls = avra_sched_polls() - polls;
    char c = 'p';
    if (write(g_pipe[1], &c, 1) != 1) return;
    joined(r);
    if (read(g_pipe[0], &c, 1) != 1) return;
    if (schedule >= 0) avra_sched_settle();
    printf("switch_beside_reader_%s %.0f %d\n", how, took, 2 * YIELDS);
    printf("polls_beside_reader_%s %lld %d\n", how, (long long)polls, 2 * YIELDS);
}

int main(void) {
    if (pipe(g_pipe) != 0) return 1;
    static const int sizes[] = { 2, 200, 2000, 20000 };
    for (int s = 0; s < 4; s++) {
        int turns = 4000000 / sizes[s] > 2000 ? 2000 : 4000000 / sizes[s];
        crowd("warmup", -1, sizes[s], 2);
        crowd("fifo", -1, sizes[s], turns);
        crowd("schedule0", 0, sizes[s], turns);
        crowd("schedule1", 1, sizes[s], turns);
    }
    beside_a_reader("fifo", -1);
    beside_a_reader("schedule1", 1);
    return 0;
}

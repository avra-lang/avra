// WHAT A BUSY SCHEDULER DOES TO A TIMER, AND TO THE EVALUATOR'S SWITCH —
// on the rows the scheduler has always had, so the same file measures
// any version of it.
//
//   c_timer_latency_busy: eight tasks each compute 2 ms between yields;
//     how long a 5 ms sleep takes among them.
//   c_vswitch_with_fd_waiter: a switch between ready virtual tasks while
//     one more stands parked on a descriptor.
//
// Prints `<tag>_<key> <total ns> <count>`.
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

#include "avra_box.h"
#include "avra_fiber.h"
#include "avra_runtime.h"

typedef void* (*Code)(void*);

static int64_t now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec;
}

static void* answer(int64_t v) { void* r = avra_array_sized(1); avra_array_push(r, v); return r; }

static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}

static int64_t joined(void* task) {
    void* r = avra_task_join(task);
    int64_t v = ((AvraArray*)r)->data[0];
    avra_rc_release(r);
    avra_rc_release(task);
    return v;
}

static volatile int g_stop;

static void* works(void* self) {
    int64_t each = ((AvraArray*)self)->data[1] * 1000000;
    while (!g_stop) {
        int64_t until = now_ns() + each;
        while (now_ns() < until) {}
        avra_fiber_yield();
    }
    return answer(0);
}

static void* sleeps(void* self) {
    int64_t t0 = now_ns();
    avra_fiber_sleep(((AvraArray*)self)->data[1]);
    return answer(now_ns() - t0);
}

int main(int argc, char** argv) {
    const char* tag = argc > 1 ? argv[1] : "c";
    enum { WORKERS = 8 };
    void* workers[WORKERS];
    int64_t least = INT64_MAX;
    for (int round = 0; round < 5; round++) {
        g_stop = 0;
        for (int i = 0; i < WORKERS; i++) workers[i] = spawn1(works, 2);
        int64_t slept = joined(spawn1(sleeps, 5));
        g_stop = 1;
        for (int i = 0; i < WORKERS; i++) joined(workers[i]);
        if (slept < least) least = slept;
    }
    printf("%s_timer_latency_busy %lld 1\n", tag, (long long)least);

    int p[2];
    if (pipe(p) != 0) return 1;
    fcntl(p[0], F_SETFL, O_NONBLOCK);
    int64_t parked = avra_vtask_new();
    avra_vtask_park_fd(parked, p[0], 0, -1);
    int64_t runner = avra_vtask_new();
    enum { SWITCHES = 200000 };
    int64_t best = INT64_MAX;
    for (int round = 0; round < 5; round++) {
        int64_t t0 = now_ns();
        for (int i = 0; i < SWITCHES; i++) {
            avra_vtask_ready(runner);
            avra_vtask_next();
        }
        int64_t spent = now_ns() - t0;
        if (spent < best) best = spent;
    }
    printf("%s_vswitch_with_fd_waiter %lld %d\n", tag, (long long)best, SWITCHES);
    return 0;
}

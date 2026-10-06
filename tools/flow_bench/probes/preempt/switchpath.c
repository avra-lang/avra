// THE SWITCH'S QUESTION "IS ANYTHING DUE", two ways: today's — while a
// timer is filed, read the clock and compare — and a tick's — load one
// byte and branch. Prints ns a question, the least of five; run.sh
// prints each body's instructions.
#include <stdint.h>
#include <stdio.h>
#include <time.h>

uint8_t g_tick = 0;
uint64_t g_timers_len = 1;
int64_t g_earliest = INT64_MAX;
uint64_t g_fired = 0;
__attribute__((noinline, cold)) void world_asked(void) { g_fired++; g_tick = 0; }

static inline int64_t clock_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec;
}

__attribute__((noinline)) void due_by_clock(void) {
    if (g_timers_len != 0 && clock_ns() >= g_earliest) world_asked();
}

__attribute__((noinline)) void due_by_tick(void) {
    if (__builtin_expect(g_tick, 0)) world_asked();
}

int main(void) {
    enum { N = 50000000 };
    double best_clock = 1e18, best_tick = 1e18;
    for (int r = 0; r < 5; r++) {
        int64_t t0 = clock_ns();
        for (int i = 0; i < N; i++) due_by_clock();
        int64_t t1 = clock_ns();
        for (int i = 0; i < N; i++) due_by_tick();
        int64_t t2 = clock_ns();
        if (t1 - t0 < best_clock) best_clock = (double)(t1 - t0);
        if (t2 - t1 < best_tick) best_tick = (double)(t2 - t1);
    }
    printf("due_by_clock %.3f ns   due_by_tick %.3f ns   (a call each; fired %llu)\n", best_clock / N, best_tick / N, (unsigned long long)g_fired);
    return 0;
}

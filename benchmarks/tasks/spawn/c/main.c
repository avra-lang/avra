// SPAWN COST in C: pthread_create and pthread_join, one task at a time and
// every task alive at once. Prints `spawn_one`/`spawn_alive` ns per task
// and `spawn_sum`, the sum of the joined answers.
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static int env_int(const char* name, int fallback) {
    const char* v = getenv(name);
    return v && *v ? atoi(v) : fallback;
}

static void* square(void* p) {
    int64_t n = (int64_t)(intptr_t)p;
    return (void*)(intptr_t)(n * n);
}

static double one_at_a_time(int n, int rounds, int64_t* sum) {
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        int64_t s = 0;
        double t0 = now_ns();
        for (int i = 0; i < n; i++) {
            pthread_t t;
            pthread_create(&t, NULL, square, (void*)(intptr_t)i);
            void* out;
            pthread_join(t, &out);
            s += (int64_t)(intptr_t)out;
        }
        double spent = now_ns() - t0;
        if (r == 0 || spent < best) best = spent;
        *sum = s;
    }
    return best;
}

static double all_at_once(int n, int rounds, int64_t* sum) {
    pthread_t* ts = malloc(sizeof(pthread_t) * n);
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        double t0 = now_ns();
        for (int i = 0; i < n; i++) pthread_create(&ts[i], NULL, square, (void*)(intptr_t)i);
        int64_t s = 0;
        for (int i = 0; i < n; i++) {
            void* out;
            pthread_join(ts[i], &out);
            s += (int64_t)(intptr_t)out;
        }
        double spent = now_ns() - t0;
        if (r == 0 || spent < best) best = spent;
        *sum = s;
    }
    free(ts);
    return best;
}

int main(void) {
    int n = env_int("BENCH_N", 10000);
    int rounds = env_int("BENCH_ROUNDS", 5);
    int64_t sum1 = 0, sum2 = 0;
    double one = one_at_a_time(n, rounds, &sum1);
    double all = all_at_once(n, rounds, &sum2);
    printf("spawn_one\t%.3f\tns\t%d\n", one / n, rounds);
    printf("spawn_alive\t%.3f\tns\t%d\n", all / n, rounds);
    printf("spawn_sum\t%lld\tops\t%d\n", (long long)sum1, rounds);
    return 0;
}

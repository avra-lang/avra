// PING-PONG in C: two threads alternate over one mutex and condition
// variable, a rendezvous on both legs. Prints `pingpong_ns` per round trip
// and `pingpong_rounds`.
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

static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t c = PTHREAD_COND_INITIALIZER;
static int seq;

// Answers every odd seq by the next even one, n times.
static void* ponger(void* p) {
    int n = (int)(intptr_t)p;
    for (int i = 0; i < n; i++) {
        pthread_mutex_lock(&m);
        while (seq % 2 == 0) pthread_cond_wait(&c, &m);
        seq++;
        pthread_cond_signal(&c);
        pthread_mutex_unlock(&m);
    }
    return NULL;
}

// n round trips: ring, wait for the answer, n times, then wait out the
// last answer so the count is whole.
static double rally(int n) {
    seq = 0;
    pthread_t t;
    pthread_create(&t, NULL, ponger, (void*)(intptr_t)n);
    double t0 = now_ns();
    for (int i = 0; i < n; i++) {
        pthread_mutex_lock(&m);
        while (seq % 2 == 1) pthread_cond_wait(&c, &m);
        seq++;
        pthread_cond_signal(&c);
        pthread_mutex_unlock(&m);
    }
    pthread_mutex_lock(&m);
    while (seq % 2 == 1) pthread_cond_wait(&c, &m);
    pthread_mutex_unlock(&m);
    double spent = now_ns() - t0;
    pthread_join(t, NULL);
    return spent;
}

int main(void) {
    int n = env_int("BENCH_N", 100000);
    int rounds = env_int("BENCH_ROUNDS", 5);
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        double s = rally(n);
        if (r == 0 || s < best) best = s;
    }
    printf("pingpong_ns\t%.3f\tns\t%d\n", best / n, rounds);
    printf("pingpong_rounds\t%d\tops\t%d\n", n, rounds);
    return 0;
}

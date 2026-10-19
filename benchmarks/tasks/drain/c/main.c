// BOUNDED-CHANNEL DRAIN in C: one producer thread pushes n items into a
// ring buffer of capacity cap while this thread drains them. Prints the
// per-item cost at two sizes, their ratio, the throughput, the bytes
// moved, and the sum of every item.
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

typedef struct {
    pthread_mutex_t m;
    pthread_cond_t not_full, not_empty;
    long* buf;
    int cap, head, count, closed;
} Chan;

static void chan_init(Chan* c, int cap) {
    c->buf = malloc(sizeof(long) * cap);
    c->cap = cap;
    c->head = 0;
    c->count = 0;
    c->closed = 0;
    pthread_mutex_init(&c->m, NULL);
    pthread_cond_init(&c->not_full, NULL);
    pthread_cond_init(&c->not_empty, NULL);
}

static void chan_push(Chan* c, long v) {
    pthread_mutex_lock(&c->m);
    while (c->count == c->cap && !c->closed) pthread_cond_wait(&c->not_full, &c->m);
    if (!c->closed) {
        c->buf[(c->head + c->count) % c->cap] = v;
        c->count++;
        pthread_cond_signal(&c->not_empty);
    }
    pthread_mutex_unlock(&c->m);
}

// Answers the next item; `done` is set once the channel is closed and empty.
static long chan_pop(Chan* c, int* done) {
    pthread_mutex_lock(&c->m);
    while (c->count == 0 && !c->closed) pthread_cond_wait(&c->not_empty, &c->m);
    long v = 0;
    *done = 0;
    if (c->count == 0 && c->closed) {
        *done = 1;
    } else {
        v = c->buf[c->head];
        c->head = (c->head + 1) % c->cap;
        c->count--;
        pthread_cond_signal(&c->not_full);
    }
    pthread_mutex_unlock(&c->m);
    return v;
}

static void chan_close(Chan* c) {
    pthread_mutex_lock(&c->m);
    c->closed = 1;
    pthread_cond_broadcast(&c->not_full);
    pthread_cond_broadcast(&c->not_empty);
    pthread_mutex_unlock(&c->m);
}

typedef struct {
    Chan* ch;
    int n;
} Producer;

static void* producer(void* p) {
    Producer* pr = p;
    for (int i = 0; i < pr->n; i++) chan_push(pr->ch, i);
    chan_close(pr->ch);
    return NULL;
}

static double drain_once(int n, int cap, long* sum) {
    Chan ch;
    chan_init(&ch, cap);
    Producer pr = {&ch, n};
    pthread_t t;
    pthread_create(&t, NULL, producer, &pr);
    double t0 = now_ns();
    long s = 0;
    for (int i = 0; i < n; i++) {
        int done;
        s += chan_pop(&ch, &done);
    }
    pthread_join(t, NULL);
    double spent = now_ns() - t0;
    *sum = s;
    return spent;
}

static double least(int n, int cap, int rounds, long* sum) {
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        long s = 0;
        double d = drain_once(n, cap, &s);
        if (r == 0 || d < best) best = d;
        *sum = s;
    }
    return best;
}

int main(void) {
    int small = env_int("BENCH_SMALL", 1000);
    int n = env_int("BENCH_N", 10000);
    int cap = env_int("BENCH_CAP", 64);
    int rounds = env_int("BENCH_ROUNDS", 5);
    long s1 = 0, s2 = 0;
    double d1 = least(small, cap, rounds, &s1);
    double d2 = least(n, cap, rounds, &s2);
    double per1 = d1 / small, per2 = d2 / n;
    printf("drain_1k_ns_per_op\t%.4f\tns\t%d\n", per1, rounds);
    printf("drain_10k_ns_per_op\t%.4f\tns\t%d\n", per2, rounds);
    printf("drain_scale\t%.4f\tx\t%d\n", per2 / per1, rounds);
    printf("drain_ops_per_s\t%.0f\tops\t%d\n", n / (d2 / 1e9), rounds);
    printf("drain_bytes\t%lld\tbytes\t%d\n", (long long)n * 8, rounds);
    printf("drain_sum\t%lld\tops\t%d\n", (long long)s2, rounds);
    return 0;
}

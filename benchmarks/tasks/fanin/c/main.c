// FAN-IN in C: n_producers threads push values into one bounded channel
// while this thread drains it until the channel closes. Prints the
// per-value cost and the received/dropped counts.
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
    int base, per;
} Producer;

static void* producer(void* p) {
    Producer* pr = p;
    for (int j = 0; j < pr->per; j++) chan_push(pr->ch, pr->base + j);
    return NULL;
}

// Joins every producer, then closes the channel so the consumer ends.
typedef struct {
    Chan* ch;
    pthread_t* ts;
    int producers;
} Closer;

static void* closer(void* p) {
    Closer* cl = p;
    for (int i = 0; i < cl->producers; i++) pthread_join(cl->ts[i], NULL);
    chan_close(cl->ch);
    return NULL;
}

static double fanin_once(int producers, int per, int cap, long* sum, int* received, int* dropped) {
    Chan ch;
    chan_init(&ch, cap);
    Producer* ps = malloc(sizeof(Producer) * producers);
    pthread_t* ts = malloc(sizeof(pthread_t) * producers);
    double t0 = now_ns();
    for (int i = 0; i < producers; i++) {
        ps[i].ch = &ch;
        ps[i].base = i * per;
        ps[i].per = per;
        pthread_create(&ts[i], NULL, producer, &ps[i]);
    }
    Closer cl = {&ch, ts, producers};
    pthread_t ct;
    pthread_create(&ct, NULL, closer, &cl);
    long s = 0;
    int got = 0, done = 0;
    while (!done) {
        long v = chan_pop(&ch, &done);
        if (!done) {
            s += v;
            got++;
        }
    }
    pthread_join(ct, NULL);
    double spent = now_ns() - t0;
    *sum = s;
    *received = got;
    *dropped = producers * per - got;
    free(ps);
    free(ts);
    return spent;
}

int main(void) {
    int producers = env_int("BENCH_PRODUCERS", 8);
    int per = env_int("BENCH_PER", 6250);
    int cap = env_int("BENCH_CAP", 64);
    int rounds = env_int("BENCH_ROUNDS", 5);
    int total = producers * per;
    double best = 0;
    long sum = 0;
    int received = 0, dropped = 0;
    for (int r = 0; r < rounds; r++) {
        double d = fanin_once(producers, per, cap, &sum, &received, &dropped);
        if (r == 0 || d < best) best = d;
    }
    printf("fanin_ns_per_op\t%.4f\tns\t%d\n", best / total, rounds);
    printf("fanin_received\t%d\tops\t%d\n", received, rounds);
    printf("fanin_dropped\t%d\tops\t%d\n", dropped, rounds);
    return 0;
}

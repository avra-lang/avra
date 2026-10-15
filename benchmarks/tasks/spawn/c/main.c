// SPAWN COST in C, TWO ANALOGUES SIDE BY SIDE — the category the thread
// twin and the fiber twin each belong to is named in the row:
//   * an OS thread (pthread_create/pthread_join) is the thread floor
//   * a user-space fiber (ucontext/makecontext) is the fair analogue of
//     a goroutine, so `spawn_fiber` is comparable to Go's and Avra's rows
// Prints spawn_thread/spawn_thread_alive and spawn_fiber/spawn_fiber_alive
// ns per task, plus spawn_sum, the sum of the joined answers.
#define _XOPEN_SOURCE 700
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <ucontext.h>

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static int env_int(const char* name, int fallback) {
    const char* v = getenv(name);
    return v && *v ? atoi(v) : fallback;
}

// ── the thread analogue ──────────────────────────────────────────────

static void* square(void* p) {
    int64_t n = (int64_t)(intptr_t)p;
    return (void*)(intptr_t)(n * n);
}

static double thread_one_at_a_time(int n, int rounds, int64_t* sum) {
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

static double thread_all_at_once(int n, int rounds, int64_t* sum) {
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

// ── the fiber analogue ───────────────────────────────────────────────
//
// A fiber gets its own stack and a ucontext; the scheduler swaps into it,
// and the fiber's return follows uc_link back to the scheduler. This is
// the same shape a goroutine has (a user-space task the runtime switches
// to), never an OS thread — that is the whole reason the row exists.

#define FIBER_STACK (16 * 1024)

static ucontext_t fiber_back;
static int64_t fiber_result;

// Runs on its own stack; returning follows uc_link to fiber_back.
static void fiber_body(int hi, int lo) {
    int64_t i = ((int64_t)hi << 32) | (int64_t)(uint32_t)lo;
    fiber_result = i * i;
}

static void fiber_make(ucontext_t* ctx, char* stack, int64_t i) {
    getcontext(ctx);
    ctx->uc_stack.ss_sp = stack;
    ctx->uc_stack.ss_size = FIBER_STACK;
    ctx->uc_link = &fiber_back;
    makecontext(ctx, (void (*)(void))fiber_body, 2, (int)(i >> 32), (int)(uint32_t)i);
}

static double fiber_one_at_a_time(int n, int rounds, int64_t* sum) {
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        int64_t s = 0;
        double t0 = now_ns();
        for (int i = 0; i < n; i++) {
            ucontext_t ctx;
            char* stack = malloc(FIBER_STACK);
            fiber_make(&ctx, stack, i);
            swapcontext(&fiber_back, &ctx);
            s += fiber_result;
            free(stack);
        }
        double spent = now_ns() - t0;
        if (r == 0 || spent < best) best = spent;
        *sum = s;
    }
    return best;
}

static double fiber_all_at_once(int n, int rounds, int64_t* sum) {
    typedef struct { ucontext_t ctx; char* stack; } Fiber;
    Fiber* fs = malloc(sizeof(Fiber) * n);
    double best = 0;
    for (int r = 0; r < rounds; r++) {
        double t0 = now_ns();
        for (int i = 0; i < n; i++) {
            fs[i].stack = malloc(FIBER_STACK);
            fiber_make(&fs[i].ctx, fs[i].stack, i);
        }
        int64_t s = 0;
        for (int i = 0; i < n; i++) {
            swapcontext(&fiber_back, &fs[i].ctx);
            s += fiber_result;
        }
        double spent = now_ns() - t0;
        if (r == 0 || spent < best) best = spent;
        for (int i = 0; i < n; i++) free(fs[i].stack);
        *sum = s;
    }
    free(fs);
    return best;
}

int main(void) {
    int n = env_int("BENCH_N", 10000);
    int rounds = env_int("BENCH_ROUNDS", 5);
    int64_t sum_thread = 0, ignored = 0;
    double thread_one = thread_one_at_a_time(n, rounds, &sum_thread);
    double thread_alive = thread_all_at_once(n, rounds, &ignored);
    double fiber_one = fiber_one_at_a_time(n, rounds, &ignored);
    double fiber_alive = fiber_all_at_once(n, rounds, &ignored);
    printf("spawn_thread\t%.3f\tns\t%d\n", thread_one / n, rounds);
    printf("spawn_thread_alive\t%.3f\tns\t%d\n", thread_alive / n, rounds);
    printf("spawn_fiber\t%.3f\tns\t%d\n", fiber_one / n, rounds);
    printf("spawn_fiber_alive\t%.3f\tns\t%d\n", fiber_alive / n, rounds);
    printf("spawn_sum\t%lld\tops\t%d\n", (long long)sum_thread, rounds);
    return 0;
}

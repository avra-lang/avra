// WHAT A STACK-LIMIT CHECK IN EVERY PROLOGUE COSTS: two call-heavy
// loops — a recursive fib(35), and a tight loop calling a small leaf that
// is never inlined — built plain, with a hand-written `cmp sp, limit; jb
// cold` in each function (LIMIT_GLOBAL: the limit a global the scheduler
// would repoint at a switch; LIMIT_TLS: the thread's slot split-stack
// reads), or by the compiler's own flags. Prints `<key> <ns a call>`,
// the least of five.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

uintptr_t avra_stack_limit = 0;
void stack_grow(void) { abort(); }

#if defined(LIMIT_GLOBAL) && defined(__x86_64__)
#define CHECK() __asm__ volatile("cmpq avra_stack_limit(%%rip), %%rsp\n\tjb stack_grow" ::: "cc")
#elif defined(LIMIT_TLS) && defined(__x86_64__)
#define CHECK() __asm__ volatile("cmpq %%fs:0x70, %%rsp\n\tjb stack_grow" ::: "cc")
#elif defined(LIMIT_GLOBAL) && defined(__aarch64__)
#define CHECK() do { uintptr_t sp_; __asm__ volatile("mov %0, sp" : "=r"(sp_)); if (__builtin_expect(sp_ < avra_stack_limit, 0)) stack_grow(); } while (0)
#else
#define CHECK()
#endif

__attribute__((noinline)) uint64_t fib(uint64_t n) {
    CHECK();
    return n < 2 ? n : fib(n - 1) + fib(n - 2);
}

__attribute__((noinline)) uint64_t leaf(uint64_t a, uint64_t b) {
    CHECK();
    return a * 31 + b;
}

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

int main(int argc, char** argv) {
    const char* tag = argc > 1 ? argv[1] : "plain";
    enum { LEAVES = 300000000 };
    const double fib_calls = 29860703.0;   // calls fib(35) makes
    double best_fib = 1e18, best_leaf = 1e18;
    uint64_t sink = 0;
    for (int r = 0; r < 5; r++) {
        double t0 = now_ns();
        sink += fib(35);
        double t1 = now_ns();
        for (uint64_t i = 0; i < LEAVES; i++) sink = leaf(sink, i);
        double t2 = now_ns();
        if (t1 - t0 < best_fib) best_fib = t1 - t0;
        if (t2 - t1 < best_leaf) best_leaf = t2 - t1;
    }
    printf("%-14s fib(35) %.3f ns a call   leaf %.3f ns a call   (sink %llu)\n", tag, best_fib / fib_calls, best_leaf / LEAVES, (unsigned long long)sink);
    return 0;
}

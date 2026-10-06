// WHAT ONE TEST AFTER A CALL COSTS: fib(35) with a test of the task's
// `unwinding` byte after each of its two calls, and a loop calling a
// leaf that is never inlined with one test after the call. BYTE reads a
// global byte; TASK reads the byte through the current task's record,
// reloaded after every call as a switch may have moved it. Prints
// `<variant> <ns a call>`, the least of five.
#include <stdint.h>
#include <stdio.h>
#include <time.h>

// Volatile, so each test is a load made after its call: the callee is
// compiled apart in a real program and may have set the byte.
typedef struct { uint64_t pad[8]; volatile uint8_t unwinding; } Task;
volatile uint8_t avra_unwinding = 0;
Task g_main_task;
Task* volatile g_current = &g_main_task;

#if defined(BYTE)
#define UNWINDING() __builtin_expect(avra_unwinding, 0)
#elif defined(TASK)
#define UNWINDING() __builtin_expect(g_current->unwinding, 0)
#else
#define UNWINDING() 0
#endif

__attribute__((noinline)) uint64_t fib(uint64_t n) {
    if (n < 2) return n;
    uint64_t a = fib(n - 1);
    if (UNWINDING()) return 0;
    uint64_t b = fib(n - 2);
    if (UNWINDING()) return 0;
    return a + b;
}

__attribute__((noinline)) uint64_t leaf(uint64_t a, uint64_t b) { return a * 31 + b; }

__attribute__((noinline)) uint64_t calls(uint64_t n) {
    uint64_t s = 0;
    for (uint64_t i = 0; i < n; i++) {
        s = leaf(s, i);
        if (UNWINDING()) return 0;
    }
    return s;
}

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

int main(int argc, char** argv) {
    const char* tag = argc > 1 ? argv[1] : "plain";
    enum { LEAVES = 300000000 };
    const double fib_calls = 29860703.0;
    double best_fib = 1e18, best_leaf = 1e18;
    volatile uint64_t sink = 0;
    for (int r = 0; r < 5; r++) {
        double t0 = now_ns();
        sink += fib(35);
        double t1 = now_ns();
        sink += calls(LEAVES);
        double t2 = now_ns();
        if (t1 - t0 < best_fib) best_fib = t1 - t0;
        if (t2 - t1 < best_leaf) best_leaf = t2 - t1;
    }
    printf("%-6s fib(35) %.3f ns a call   leaf loop %.3f ns a call\n", tag, best_fib / fib_calls, best_leaf / LEAVES);
    return (int)(sink & 0);
}

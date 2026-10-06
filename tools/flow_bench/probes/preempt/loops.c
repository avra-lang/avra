// WHAT A PREEMPTION CHECK ON EVERY LOOP BACK-EDGE COSTS: five tight
// loops, built plain and with one check at each back-edge. FLAG loads a
// global byte a tick would set; TASK reads it through the current
// task's record; COUNT counts turns in a register and looks at the flag
// every 1024th; CHUNK is what a compiler can do for a counted loop —
// the loop split into runs of 1024 with the check between runs — and
// falls back to FLAG where the trip count is unknown. Prints
// `<variant> <loop> <ns a turn>`, the least of five.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct { uint64_t pad[8]; uint8_t preempt; } Task;
uint8_t avra_tick = 0;
Task g_main_task;
Task* g_current = &g_main_task;
__attribute__((noinline, cold)) void preempted(void) { avra_tick = 0; g_current->preempt = 0; }

#if defined(FLAG) || defined(CHUNK)
#define EDGE() do { if (__builtin_expect(__atomic_load_n(&avra_tick, __ATOMIC_RELAXED), 0)) preempted(); } while (0)
#elif defined(TASK)
#define EDGE() do { if (__builtin_expect(__atomic_load_n(&g_current->preempt, __ATOMIC_RELAXED), 0)) preempted(); } while (0)
#elif defined(COUNT)
#define EDGE() do { if (__builtin_expect(--budget == 0, 0)) { budget = 1024; if (__atomic_load_n(&avra_tick, __ATOMIC_RELAXED)) preempted(); } } while (0)
#else
#define EDGE() do { } while (0)
#endif
#if defined(COUNT)
#define BUDGET uint32_t budget = 1024;
#else
#define BUDGET
#endif

enum { N = 4096, M = 64 };
static uint32_t words[N];
static uint8_t bytes[N];
static double ma[M][M], mb[M][M], mc[M][M];
typedef struct Node { struct Node* next; uint64_t v; } Node;
static Node nodes[N];

// A sum the compiler vectorizes when nothing stands in the loop.
__attribute__((noinline)) uint64_t sum(const uint32_t* a, size_t n) {
    uint64_t s = 0;
    BUDGET
#if defined(CHUNK)
    for (size_t lo = 0; lo < n; lo += 1024) {
        size_t hi = lo + 1024 < n ? lo + 1024 : n;
        for (size_t i = lo; i < hi; i++) s += a[i];
        EDGE();
    }
#else
    for (size_t i = 0; i < n; i++) { s += a[i]; EDGE(); }
#endif
    return s;
}

// A byte hash: one multiply a turn, a chain the compiler cannot widen.
__attribute__((noinline)) uint64_t fnv(const uint8_t* p, size_t n) {
    uint64_t h = 1469598103934665603ull;
    BUDGET
#if defined(CHUNK)
    for (size_t lo = 0; lo < n; lo += 1024) {
        size_t hi = lo + 1024 < n ? lo + 1024 : n;
        for (size_t i = lo; i < hi; i++) h = (h ^ p[i]) * 1099511628211ull;
        EDGE();
    }
#else
    for (size_t i = 0; i < n; i++) { h = (h ^ p[i]) * 1099511628211ull; EDGE(); }
#endif
    return h;
}

// A `while` whose trip count nobody knows.
__attribute__((noinline)) uint64_t collatz(uint64_t n) {
    uint64_t steps = 0;
    BUDGET
    while (n != 1) { n = (n & 1) ? 3 * n + 1 : n >> 1; steps++; EDGE(); }
    return steps;
}

// A nest: the inner loop is short, so its back-edge is most of the work.
__attribute__((noinline)) void matmul(void) {
    BUDGET
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < M; j++) {
            double s = 0;
#if defined(CHUNK)
            for (int k = 0; k < M; k++) s += ma[i][k] * mb[k][j];
#else
            for (int k = 0; k < M; k++) { s += ma[i][k] * mb[k][j]; EDGE(); }
#endif
            mc[i][j] = s;
            EDGE();
        }
        EDGE();
    }
}

// A list walk: a turn is one load the next turn waits on.
__attribute__((noinline)) uint64_t chase(const Node* p) {
    uint64_t s = 0;
    BUDGET
    while (p) { s += p->v; p = p->next; EDGE(); }
    return s;
}

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

int main(int argc, char** argv) {
    const char* tag = argc > 1 ? argv[1] : "plain";
    for (int i = 0; i < N; i++) {
        words[i] = (uint32_t)i * 2654435761u;
        bytes[i] = (uint8_t)(i * 31 + 7);
        nodes[i].v = (uint64_t)i;
        nodes[i].next = i + 1 < N ? &nodes[i + 1] : NULL;
    }
    for (int i = 0; i < M; i++) for (int j = 0; j < M; j++) { ma[i][j] = i + j; mb[i][j] = i - j; }
    uint64_t steps = collatz(837799);
    double best[5] = { 1e18, 1e18, 1e18, 1e18, 1e18 };
    volatile uint64_t sink = 0;
    for (int r = 0; r < 5; r++) {
        double t0 = now_ns();
        for (int k = 0; k < 60000; k++) sink += sum(words, N);
        double t1 = now_ns();
        for (int k = 0; k < 20000; k++) sink += fnv(bytes, N);
        double t2 = now_ns();
        for (int k = 0; k < 200000; k++) sink += collatz(837799);
        double t3 = now_ns();
        for (int k = 0; k < 400; k++) { matmul(); sink += (uint64_t)mc[3][5]; }
        double t4 = now_ns();
        for (int k = 0; k < 30000; k++) sink += chase(nodes);
        double t5 = now_ns();
        double got[5] = { (t1 - t0) / (60000.0 * N), (t2 - t1) / (20000.0 * N), (t3 - t2) / (200000.0 * steps), (t4 - t3) / (400.0 * M * M * M), (t5 - t4) / (30000.0 * N) };
        for (int i = 0; i < 5; i++) if (got[i] < best[i]) best[i] = got[i];
    }
    printf("%-6s sum %.3f  fnv %.3f  collatz %.3f  matmul %.3f  chase %.3f   ns a turn\n", tag, best[0], best[1], best[2], best[3], best[4]);
    return (int)(sink & 0);
}

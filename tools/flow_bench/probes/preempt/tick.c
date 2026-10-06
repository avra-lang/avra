// WHAT A 1 ms TICK COSTS, by a helper thread and by a signal. A tick
// only sets a byte; the worker is a hash loop that looks at the byte on
// every back-edge and counts what it saw. Three questions, each printed:
//   busy  — the worker's turns a second with no tick, a thread's, a
//           signal's; the ticks seen; the longest gap between two; the
//           process's CPU beyond the worker's own wall time;
//   idle  — what a tick left armed costs a process that waits on its
//           poller: CPU a second, and how often the poller is broken in on;
//   fork  — whether a forked child still has its tick.
#define _GNU_SOURCE
#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static uint8_t g_tick;
static volatile int g_stop;
static double g_ticker_cpu_ns;   // the tick thread's own CPU, read as it ends

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static double cpu_ns(void) {
    struct rusage u;
    getrusage(RUSAGE_SELF, &u);
    return (u.ru_utime.tv_sec + u.ru_stime.tv_sec) * 1e9 + (u.ru_utime.tv_usec + u.ru_stime.tv_usec) * 1e3;
}

static void* ticker(void* _) {
    (void)_;
    struct timespec at;
    clock_gettime(CLOCK_MONOTONIC, &at);
    while (!g_stop) {
        at.tv_nsec += 1000000;
        if (at.tv_nsec >= 1000000000) { at.tv_nsec -= 1000000000; at.tv_sec++; }
#if defined(__linux__)
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &at, NULL);
#else
        struct timespec d = { 0, 1000000 };
        nanosleep(&d, NULL);
#endif
        __atomic_store_n(&g_tick, 1, __ATOMIC_RELAXED);
    }
    struct timespec own;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &own);
    g_ticker_cpu_ns = own.tv_sec * 1e9 + own.tv_nsec;
    return NULL;
}

static void on_alarm(int _) { (void)_; __atomic_store_n(&g_tick, 1, __ATOMIC_RELAXED); }

static pthread_t g_thread;
static void armed(const char* how) {
    g_stop = 0;
    if (!strcmp(how, "thread")) pthread_create(&g_thread, NULL, ticker, NULL);
    if (!strcmp(how, "signal")) {
        struct sigaction sa = { 0 };
        sa.sa_handler = on_alarm;
        sa.sa_flags = SA_RESTART;
        sigaction(SIGALRM, &sa, NULL);
        struct itimerval it = { { 0, 1000 }, { 0, 1000 } };
        setitimer(ITIMER_REAL, &it, NULL);
    }
}

static void disarmed(const char* how) {
    g_stop = 1;
    if (!strcmp(how, "thread")) pthread_join(g_thread, NULL);
    if (!strcmp(how, "signal")) { struct itimerval it = { { 0, 0 }, { 0, 0 } }; setitimer(ITIMER_REAL, &it, NULL); }
}

static uint8_t bytes[4096];

// The worker: a hash loop with the check on its back-edge, for `secs`.
static void busy(const char* how, double secs) {
    armed(how);
    double start = now_ns(), last = start, longest = 0;
    uint64_t turns = 0, seen = 0, h = 1469598103934665603ull;
    for (;;) {
        for (int i = 0; i < 4096; i++) {
            h = (h ^ bytes[i]) * 1099511628211ull;
            if (__builtin_expect(__atomic_load_n(&g_tick, __ATOMIC_RELAXED), 0)) {
                __atomic_store_n(&g_tick, 0, __ATOMIC_RELAXED);
                double t = now_ns();
                if (seen > 0 && t - last > longest) longest = t - last;
                last = t;
                seen++;
            }
        }
        turns += 4096;
        if ((turns & 0xfffff) == 0 && now_ns() - start >= secs * 1e9) break;
    }
    double wall = now_ns() - start;
    g_ticker_cpu_ns = 0;
    disarmed(how);
    printf("busy %-6s %.1f M turns/s   ticks seen %llu in %.2f s   longest gap %.3f ms   the tick thread's own CPU %.3f ms/s   (h %llx)\n",
        how, turns / wall * 1e3, (unsigned long long)seen, wall / 1e9, longest / 1e6, g_ticker_cpu_ns / wall * 1e3, (unsigned long long)(h & 0xff));
}

// A process with nothing ready waits on its poller; the tick is left armed.
static void idle(const char* how, double secs) {
    armed(how);
    double start = now_ns(), cpu0 = cpu_ns();
    uint64_t waits = 0, broken = 0;
    while (now_ns() - start < secs * 1e9) {
        int n = poll(NULL, 0, 100);
        waits++;
        if (n < 0 && errno == EINTR) broken++;
    }
    double wall = now_ns() - start, cpu = cpu_ns() - cpu0;
    disarmed(how);
    printf("idle %-6s CPU %.3f ms/s   poller waits %llu, broken in on %llu (%.0f a second)\n", how, cpu / wall * 1e3, (unsigned long long)waits, (unsigned long long)broken, broken / (wall / 1e9));
}

// A forked child counts the ticks it sees in 50 ms.
static void forked(const char* how) {
    armed(how);
    pid_t pid = fork();
    if (pid == 0) {
        __atomic_store_n(&g_tick, 0, __ATOMIC_RELAXED);
        double start = now_ns();
        int seen = 0;
        while (now_ns() - start < 50e6) if (__atomic_load_n(&g_tick, __ATOMIC_RELAXED)) { __atomic_store_n(&g_tick, 0, __ATOMIC_RELAXED); seen++; }
        _exit(seen > 250 ? 250 : seen);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    disarmed(how);
    printf("fork %-6s the child saw %d ticks in 50 ms\n", how, WEXITSTATUS(status));
}

int main(void) {
    for (int i = 0; i < 4096; i++) bytes[i] = (uint8_t)(i * 31 + 7);
    const char* hows[] = { "none", "thread", "signal" };
    for (int r = 0; r < 2; r++) for (int i = 0; i < 3; i++) busy(hows[i], 2.0);
    for (int i = 0; i < 3; i++) idle(hows[i], 2.0);
    for (int i = 1; i < 3; i++) forked(hows[i]);
    return 0;
}

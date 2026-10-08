// THE HOSTED TICK: one thread that stores `avra_tick` each period while
// the scheduler has preemption work. It lives OUTSIDE `runtime/*.c` so a
// kernel with no threads still builds the scheduler (D7), and it rides
// the scheduler's object: a program that never spawns links neither.
//
// A FORK MUST RE-ARM IT, and a child cannot inherit the parent's thread,
// so `avra_tick_armed` starts a fresh one under the child's own pid and
// a fresh wake pipe. For that to be safe in a forked child of a
// two-thread process the thread BODY holds no lock and allocates
// nothing — it sleeps, polls its wake pipe, and reads it; the keeper
// `make tick-object` holds the object's undefined symbols to that list.
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <pthread.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "avra_fiber.h"

// How many periods unwanted before the thread parks on its pipe; one
// wake brings it back. An idle process then costs nothing.
enum { TICK_PARK_PERIODS = 8 };

static pthread_t g_thread;
static int g_started = 0;
static pid_t g_owner = 0;
static int g_wake[2] = { -1, -1 };
static volatile uint8_t g_parked = 0;

static struct timespec us_as_ts(int64_t us) {
    if (us < 0) us = 0;
    struct timespec t;
    t.tv_sec = (time_t)(us / 1000000);
    t.tv_nsec = (long)((us % 1000000) * 1000);
    return t;
}

// The wake pipe drained, never blocking: a byte left for the next read
// would wake a park that has already been served.
static void wake_drained(void) {
    char b;
    while (read(g_wake[0], &b, 1) == 1) { }
}

static void wake_once(void) {
    char b = 'x';
    ssize_t n = write(g_wake[1], &b, 1);
    (void)n;
}

static void* tick_loop(void* self) {
    (void)self;
    int unwanted = 0;
    for (;;) {
        if (__atomic_load_n(&avra_tick_wanted, __ATOMIC_RELAXED)) {
            unwanted = 0;
            __atomic_store_n(&avra_tick, 1, __ATOMIC_RELAXED);
            struct timespec d = us_as_ts(avra_tick_us);
            nanosleep(&d, NULL);
            wake_drained();
        } else if (++unwanted > TICK_PARK_PERIODS) {
            struct pollfd p = { .fd = g_wake[0], .events = POLLIN };
            __atomic_store_n(&g_parked, 1, __ATOMIC_RELAXED);
            poll(&p, 1, -1);
            __atomic_store_n(&g_parked, 0, __ATOMIC_RELAXED);
            wake_drained();
            unwanted = 0;
        } else {
            struct timespec d = us_as_ts(avra_tick_us);
            nanosleep(&d, NULL);
            wake_drained();
        }
    }
    return NULL;
}

// The source comes up, or a parked one is woken. A different pid is a
// forked child: the parent's thread is gone and its pipe is shared, so
// both are replaced before a new thread starts.
void avra_tick_armed(void) {
    if (g_started && g_owner == getpid()) {
        if (__atomic_load_n(&g_parked, __ATOMIC_RELAXED)) wake_once();
        return;
    }
    if (g_wake[0] >= 0) { close(g_wake[0]); close(g_wake[1]); g_wake[0] = g_wake[1] = -1; }
    if (pipe(g_wake) != 0) { g_wake[0] = g_wake[1] = -1; g_started = 1; g_owner = getpid(); return; }
    fcntl(g_wake[0], F_SETFL, O_NONBLOCK);
    g_started = 1;
    g_owner = getpid();
    __atomic_store_n(&g_parked, 0, __ATOMIC_RELAXED);
    if (pthread_create(&g_thread, NULL, tick_loop, NULL) != 0) g_started = 0;
}

// The scheduler has nothing to run: the thread may park at once rather
// than wait out its unwanted periods.
void avra_tick_stood_down(void) {
    if (g_started && g_owner == getpid()) wake_once();
}

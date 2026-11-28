/* @std/time's OWN C — the wall clock, and the host's monotonic clock
   as it runs. Each answers an int and mints nothing
   (docs/2026_09_07_PACKAGE_C_STANDARD.md §2.1); the clock a program's
   tasks share, which a case may run virtually, is the runtime's own row. */

#include <stdint.h>
#include <time.h>

/* Whole seconds since 1970-01-01 UTC by the host's wall clock, which
   may step either way. The coarse clock where the host has one: a
   second's grain needs no finer, and it is the cheaper read. */
int64_t avra_time_wall_s(void) {
    struct timespec ts;
#ifdef CLOCK_REALTIME_COARSE
    clock_gettime(CLOCK_REALTIME_COARSE, &ts);
#else
    clock_gettime(CLOCK_REALTIME, &ts);
#endif
    return (int64_t)ts.tv_sec;
}

/* Nanoseconds since 1970-01-01 UTC by the host's wall clock. The same clock as
   avra_time_wall_s, at the grain an instant carries. */
int64_t avra_time_wall_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (int64_t)ts.tv_sec * 1000000000 + (int64_t)ts.tv_nsec;
}

/* Nanoseconds by the host's monotonic clock, which no virtual clock moves:
   what a deadline over a process or a socket reads, since what it bounds
   runs on the host's time. */
int64_t avra_time_host_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000 + (int64_t)ts.tv_nsec;
}

/* @std/time's OWN C — the wall clock. It answers an int and mints
   nothing (docs/2026_09_07_PACKAGE_C_STANDARD.md §2.1); the monotonic
   clock is the runtime's own row. */

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

// The write leaf's cost in three states: nobody observes the box, a site
// observes it and it was already written this turn, and a site observes it and
// every write is the turn's first (the log path).
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include "../../runtime/avra_runtime.h"

#ifdef WITH_OBS
int64_t avra_box_observe(void* p);
int64_t avra_turn_next(void);
void* avra_changes_take(void);
#endif
void* avra_array_new(void);
void avra_array_push(void* arr, int64_t v);
void avra_slot_set(void* arr, int64_t i, int64_t v);

static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec / 1e9; }

int main(void) {
    const int64_t N = 200000000;
    void* c = avra_array_new();
    avra_array_push(c, 0);
    double t0 = now();
    for (int64_t i = 0; i < N; i++) avra_slot_set(c, 0, i);
    double t1 = now();
    printf("unobserved        %.2f ns/write\n", (t1 - t0) / N * 1e9);
#ifdef WITH_OBS
    avra_box_observe(c);
    avra_turn_next();
    avra_slot_set(c, 0, 0);
    t0 = now();
    for (int64_t i = 0; i < N; i++) avra_slot_set(c, 0, i);
    t1 = now();
    printf("observed, logged  %.2f ns/write\n", (t1 - t0) / N * 1e9);
    avra_rc_release(avra_changes_take());
    const int64_t M = 20000000;
    t0 = now();
    for (int64_t i = 0; i < M; i++) { avra_turn_next(); avra_slot_set(c, 0, i); if ((i & 1023) == 1023) avra_rc_release(avra_changes_take()); }
    t1 = now();
    printf("observed, first   %.2f ns/write (with the turn)\n", (t1 - t0) / M * 1e9);
#endif
    return 0;
}

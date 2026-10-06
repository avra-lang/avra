// THE SCHEDULER'S ROWS, CALLED FROM C: a switch, a spawn and join one at
// a time, and ten thousand tasks alive at once (the first round cold,
// then the best of four). No closure lift, no `Tasks` owner, no Avra
// frame — what the runtime alone costs. Prints `<key> <total ns> <count>`.
// A second argument `switch` runs the ten million switches alone, for an
// instruction count taken from outside; `parked` runs instead ten
// thousand tasks alive AND parked, each having yielded once, cold first.
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "avra_box.h"
#include "avra_fiber.h"
#include "avra_runtime.h"

typedef void* (*Code)(void*);

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static void* answer(int64_t v) { void* r = avra_array_sized(1); avra_array_push(r, v); return r; }

static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}

static int64_t joined(void* task) {
    void* r = avra_task_join(task);
    int64_t v = ((AvraArray*)r)->data[0];
    avra_rc_release(r);
    avra_rc_release(task);
    return v;
}

static void* square(void* self) { int64_t n = ((AvraArray*)self)->data[1]; return answer(n * n); }
static void* turns(void* self) {
    int64_t n = ((AvraArray*)self)->data[1];
    for (int64_t i = 0; i < n; i++) avra_fiber_yield();
    return answer(n);
}


enum { MANY = 10000, TURNS = 1000000 };
static void* g_many[MANY];

static void* yields(void* self) { avra_fiber_yield(); return square(self); }

// Every task spawned, every task run to its yield, then every task joined.
static double parked(void) {
    double t0 = now_ns();
    for (int i = 0; i < MANY; i++) g_many[i] = spawn1(yields, i);
    avra_fiber_yield();
    for (int i = 0; i < MANY; i++) joined(g_many[i]);
    return now_ns() - t0;
}

static double alive(void) {
    double t0 = now_ns();
    for (int i = 0; i < MANY; i++) g_many[i] = spawn1(square, i);
    for (int i = 0; i < MANY; i++) joined(g_many[i]);
    return now_ns() - t0;
}

int main(int argc, char** argv) {
    const char* tag = argc > 1 ? argv[1] : "c";
    int switches_only = argc > 2 && strcmp(argv[2], "switch") == 0;
    if (argc > 2 && strcmp(argv[2], "parked") == 0) {
        double first = parked();
        double then = 1e18;
        for (int r = 0; r < 5; r++) { double w = parked(); if (w < then) then = w; }
        printf("%s_spawn_parked_cold %.0f %d\n", tag, first, MANY);
        printf("%s_spawn_parked_warm %.0f %d\n", tag, then, MANY);
        return 0;
    }
    double cold = switches_only ? 0 : alive();
    double warm = 1e18;
    for (int r = 0; r < 4 && !switches_only; r++) { double w = alive(); if (w < warm) warm = w; }
    double one = 1e18;
    for (int r = 0; r < 5 && !switches_only; r++) {
        double t0 = now_ns();
        for (int i = 0; i < MANY; i++) joined(spawn1(square, i));
        double t1 = now_ns();
        if (t1 - t0 < one) one = t1 - t0;
    }
    double best = 1e18;
    for (int r = 0; r < 5; r++) {
        void* p = spawn1(turns, TURNS);
        void* q = spawn1(turns, TURNS);
        double t0 = now_ns();
        joined(p);
        joined(q);
        double t1 = now_ns();
        if (t1 - t0 < best) best = t1 - t0;
    }
    printf("%s_switch %.0f %d\n", tag, best, 2 * TURNS);
    if (switches_only) return 0;
    printf("%s_spawn_one %.0f %d\n", tag, one, MANY);
    printf("%s_spawn_alive_cold %.0f %d\n", tag, cold, MANY);
    printf("%s_spawn_alive_warm %.0f %d\n", tag, warm, MANY);
    return 0;
}

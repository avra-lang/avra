// What the rewritten program reads: the unwinding byte (and a task
// record holding one at offset 64 behind a pointer a switch would
// repoint), and the tick's byte. Nothing sets the first, so every test
// after a call is the not-taken path it is priced as. The tick's byte is
// set by a thread every AVRA_PROBE_TICK_US microseconds when that is
// named — always armed, in a forked child too — and cleared by the cold
// side a back-edge calls.
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

typedef struct { uint64_t pad[8]; uint8_t unwinding; } ProbeTask;
uint8_t avra_probe_byte = 0;
uint8_t avra_probe_tick = 0;
ProbeTask avra_probe_main;
ProbeTask* avra_probe_task = &avra_probe_main;
__attribute__((noinline, cold, noreturn)) void avra_probe_unwound(void) { abort(); }
__attribute__((noinline, cold)) void avra_probe_preempted(void) { __atomic_store_n(&avra_probe_tick, 0, __ATOMIC_RELAXED); }

static long g_period_us;

static void* ticker(void* _) {
    (void)_;
    struct timespec d = { g_period_us / 1000000, (g_period_us % 1000000) * 1000 };
    for (;;) {
        nanosleep(&d, NULL);
        __atomic_store_n(&avra_probe_tick, 1, __ATOMIC_RELAXED);
    }
    return NULL;
}

static void armed(void) {
    pthread_t t;
    if (g_period_us > 0) pthread_create(&t, NULL, ticker, NULL);
}

__attribute__((constructor)) static void settled(void) {
    const char* said = getenv("AVRA_PROBE_TICK_US");
    g_period_us = said ? atol(said) : 0;
    pthread_atfork(NULL, NULL, armed);
    armed();
}

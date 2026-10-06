// What the rewritten program reads: a byte, and a task record holding
// one at offset 64 behind a pointer a switch would repoint. Nothing
// sets either, so every test is the not-taken path it is priced as.
#include <stdint.h>
#include <stdlib.h>

typedef struct { uint64_t pad[8]; uint8_t unwinding; } ProbeTask;
uint8_t avra_probe_byte = 0;
ProbeTask avra_probe_main;
ProbeTask* avra_probe_task = &avra_probe_main;
__attribute__((noinline, cold, noreturn)) void avra_probe_unwound(void) { abort(); }
__attribute__((noinline, cold)) void avra_probe_preempted(void) { avra_probe_byte = 0; }

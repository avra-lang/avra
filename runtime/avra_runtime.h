// What the runtime's core (avra_runtime.c) lends the runtime's other
// objects. The core includes this too, so a definition that drifts
// from its declaration stops at the C compiler.
#ifndef AVRA_RUNTIME_H
#define AVRA_RUNTIME_H

#include <stdint.h>

void avra_trap(const char* msg) __attribute__((noreturn));
void avra_rc_retain(void* p);
void avra_rc_release(void* p);
void* avra_array_sized(int64_t n);
void avra_array_push(void* arr, int64_t v);
// Told when a read found a descriptor drained — a short read or none;
// set by the scheduler when it opens its poller, NULL until then.
extern void (*avra_fd_drained_hook)(int64_t fd);
// Room for at least `spare` more cells without another grow.
void avra_array_reserve(void* arr, int64_t spare);
void avra_array_push_owned(void* arr, void* v);
int64_t avra_mem_live(void);
// The suite case in flight, else NULL — what a trap names first.
void avra_case_begin(const char* label);
const char* avra_case_now(void);

#endif

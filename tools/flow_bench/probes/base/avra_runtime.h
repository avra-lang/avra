// What the runtime's core (avra_runtime.c) lends the runtime's other
// objects. The core includes this too, so a definition that drifts
// from its declaration stops at the C compiler.
#ifndef AVRA_RUNTIME_H
#define AVRA_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

void avra_trap(const char* msg) __attribute__((noreturn));
// The runtime's own words: %s %c %d %lld %llx %p %% under a width and
// `-`, into a buffer cut at `cap`, or whole onto stderr.
void avra_fmt(char* out, size_t cap, const char* fmt, ...) __attribute__((format(printf, 3, 4)));
void avra_say(const char* fmt, ...) __attribute__((format(printf, 1, 2)));
// A number as an env flag spells it; base 0 reads its own prefix.
unsigned long long avra_number(const char* s, unsigned base);
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

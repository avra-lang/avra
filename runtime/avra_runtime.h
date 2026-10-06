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
// WHAT A TASK CARRIES: a few managed values and its id. The running
// task's stand behind one pointer; `main`'s are the core's own, so a
// program that never spawns has them and links no scheduler.
enum { AVRA_SLOT_ASKER = 0, AVRA_SLOT_FLOW = 1, AVRA_TASK_SLOTS = 4 };
typedef struct { void* slot[AVRA_TASK_SLOTS]; int64_t id; } AvraTaskLocal;
extern AvraTaskLocal avra_main_local;
extern AvraTaskLocal* avra_task_local;
// The running task's slot `key`, owned; and `v` kept in it, what it
// held released. A slot past the table is a trap.
void* avra_task_slot(int64_t key);
void avra_task_slot_set(int64_t key, void* v);
// The running task's id; 0 for `main`.
int64_t avra_task_id(void);
// Room for at least `spare` more cells without another grow.
void avra_array_reserve(void* arr, int64_t spare);
void avra_array_push_owned(void* arr, void* v);
int64_t avra_mem_live(void);
// The suite case in flight, else NULL — what a trap names first.
void avra_case_begin(const char* label);
const char* avra_case_now(void);

#endif

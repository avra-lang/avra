// What the runtime's core (avra_runtime.c) lends the runtime's other
// objects. The core includes this too, so a definition that drifts
// from its declaration stops at the C compiler.
#ifndef AVRA_RUNTIME_H
#define AVRA_RUNTIME_H

#include <stddef.h>
#include <stdint.h>
#include <time.h>

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
// `clock_asks`: how often the task has read a frozen clock since it
// last waited; `clock_holds`: the holds on the world it stands in.
typedef struct { void* slot[AVRA_TASK_SLOTS]; int64_t id; int64_t clock_asks; int64_t clock_holds; } AvraTaskLocal;
extern AvraTaskLocal avra_main_local __attribute__((visibility("hidden")));
extern AvraTaskLocal* avra_task_local __attribute__((visibility("hidden")));
// The schedule the case in flight runs under, or -1; a trap says it.
extern int64_t avra_case_schedule __attribute__((visibility("hidden")));
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

// THE CLOCK, ONE FOR THE PROCESS: every reader asks here. FLOWING it is
// the monotonic clock plus a skew; FROZEN it is one reading. VIRTUAL, it
// is frozen — time moves only when every task waits, and then jumps to
// the earliest timer — except while the world is HELD, when it flows at
// wall rate. Each change keeps the present reading, so it never goes
// back.
typedef struct {
    int64_t skew;       // flowing: what is added to the monotonic clock
    int64_t at;         // frozen: the reading
    int32_t virtual;
    int32_t frozen;     // virtual and not held
    int32_t held;
} AvraClock;
extern AvraClock avra_clock __attribute__((visibility("hidden")));
// What a program reads. A task that reads a frozen clock AVRA_CLOCK_ASKS
// times without waiting between is waiting on a time that cannot come,
// and traps by name; 0 turns that off.
int64_t avra_now_ns(void);
void avra_clock_virtual(int64_t on);
// The scheduler's own read, in line: never counted as a task's waiting.
static inline int64_t avra_clock_read(void) {
    if (__builtin_expect(avra_clock.frozen, 0)) return avra_clock.at;
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (int64_t)t.tv_sec * 1000000000 + t.tv_nsec + avra_clock.skew;
}
// The scheduler's, called when the clock becomes virtual or real again.
extern void (*avra_clock_turned_hook)(void);
// The scheduler's, called with the watchdog's words when a task waits on
// a frozen clock without sleeping: inside a case it fails that case and
// never returns; outside one it returns, and the process traps.
extern void (*avra_clock_spun_hook)(const char* words);
// Frozen: the clock set to `at` when that is later, and 1. Flowing: 0.
int64_t avra_clock_jumped(int64_t at);
// THE WORLD IS HELD while something waits on it in real time: the
// poller with a descriptor waiter filed, and every blocking call in C
// (`make clock-holds` finds each). A count, charged to the task that
// takes it; giving back more than was taken traps, and a task that
// waited on the world has waited — its count of clock reads begins
// again.
void avra_clock_hold(int64_t by);
// What tasks abandoned while holding the world held, let go: only that
// share, never the holds a live task stands in.
void avra_clock_holds_let_go(int64_t n);
// Every hold given up at once, for a run whose holders are gone: how many.
int64_t avra_clock_holds_dropped(void);
// A RUN INSIDE ANOTHER PROGRAM: it begins on its host's clock with no
// hold, and whatever it does to the clock — turns it virtual, jumps it,
// holds it — ends with it: its end puts the outer clock back exactly as
// it was.
void avra_clock_run_begins(void);
void avra_clock_run_ends(void);
int64_t avra_clock_jumps(void);
// The suite case in flight, else NULL — what a trap names first.
void avra_case_begin(const char* label);
const char* avra_case_now(void);

#endif

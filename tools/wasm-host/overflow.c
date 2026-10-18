// A task that parks at the bottom of a recursion, with a frame of its own at
// every level: the unwind must fit the buffer the host gave it, or the host
// must say the task's stack overflowed (runtime/dom/tasks_overflow_test.js).
#include <stdint.h>
__attribute__((import_module("avra_host"), import_name("idle")))
extern void host_idle(int64_t ns);
static char arena[1 << 20];
static int arena_at = 0;
static volatile int sink[64];
__attribute__((export_name("avra_asyncify_buffer"))) void* avra_asyncify_buffer(int bytes) { void* p = &arena[arena_at]; arena_at += bytes; return p; }
__attribute__((export_name("canary"))) int canary(void) { return sink[0]; }
__attribute__((noinline)) static long deep(long d, long a, long b) {
    if (d == 0) { host_idle(1000); return a + b; }
    long r = deep(d - 1, a + d, b ^ d);
    sink[0] = (int)r;
    return r + a;
}
__attribute__((export_name("run"))) long run(long d) { return deep(d, 1, 2); }

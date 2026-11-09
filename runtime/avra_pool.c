// THE MACHINE'S MEMORY POOL: what every Avra process on this machine may hold together, shared out
// in slots. Past a small allowance, a process holds one slot for each SLOT_BYTES it uses, by an
// exclusive flock on a slot file in the user's own directory. The kernel drops a flock when the
// process that took it ends, however it ends, so no slot outlives its holder. With each process's
// own ceiling, the processes on a machine never hold more than the pool between them: too many at
// once wait for each other instead of taking the machine.
//
// A process holding nothing waits for its first slot as long as it takes. One that holds slots and
// can't get another waits a bounded time and then refuses, since two growing processes waiting on
// each other would otherwise wait forever: one run is lost, never the machine.
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#if defined(__APPLE__)
#include <sys/sysctl.h>
#endif
#include "avra_door.h"
#include "avra_platform.h"

#if AVRA_MEASURES_MEMORY && !defined(__wasm32__)

enum { SLOT_BYTES = 256 << 20, MOST_SLOTS = 1024, PATH_BYTES = 4096 };

// What a process may use before it holds any slot.
static const int64_t FREE_BYTES = (int64_t)SLOT_BYTES;

// The share of the machine's memory the pool hands out; the rest is the system's, and every
// process's free allowance.
static const int64_t POOL_PERCENT = 60;

// How long a process holding slots waits for one more before it refuses.
static const int64_t GROWTH_WAIT_MS = 120000;

static int g_slot_count = -1;
static int64_t g_wait_ms = GROWTH_WAIT_MS;
static int g_held[MOST_SLOTS];
static int g_held_count = 0;
static char g_dir[PATH_BYTES];

static int64_t machine_bytes(void) {
#if defined(__APPLE__)
    int64_t bytes = 0;
    size_t size = sizeof bytes;
    return sysctlbyname("hw.memsize", &bytes, &size, NULL, 0) == 0 ? bytes : 0;
#else
    long pages = sysconf(_SC_PHYS_PAGES), page = sysconf(_SC_PAGESIZE);
    return pages > 0 && page > 0 ? (int64_t)pages * page : 0;
#endif
}

// A forked child holds none of its parent's slots: its memory is its own, and the parent's copy
// of each descriptor keeps the parent's lock.
static void child_holds_none(void) {
    for (int i = 0; i < g_held_count; i++) close(g_held[i]);
    g_held_count = 0;
}

// The pool's size and directory, settled on first use. No pool when it's turned off, sized to
// nothing, or its directory can't be made.
static void pool_settled(void) {
    if (g_slot_count >= 0) return;
    g_slot_count = 0;
    const char* sized = getenv("AVRA_MEM_POOL_MB");
    int64_t bytes = sized && *sized ? (int64_t)atoll(sized) << 20 : machine_bytes() / 100 * POOL_PERCENT;
    const char* waits = getenv("AVRA_MEM_POOL_WAIT_MS");
    if (waits && *waits) g_wait_ms = atoll(waits);
    if (bytes <= 0) return;
    const char* placed = getenv("AVRA_MEM_POOL_DIR");
    if (placed && *placed) {
        snprintf(g_dir, sizeof g_dir, "%s", placed);
    } else {
        char base[PATH_BYTES];
        avra_user_dir(base, sizeof base);
        mkdir(base, 0700);
        snprintf(g_dir, sizeof g_dir, "%s/avra-pool", base);
    }
    if (mkdir(g_dir, 0700) != 0 && errno != EEXIST) return;
    int64_t slots = bytes / SLOT_BYTES;
    g_slot_count = (int)(slots < 1 ? 1 : slots > MOST_SLOTS ? MOST_SLOTS : slots);
    pthread_atfork(NULL, NULL, child_holds_none);
}

// One free slot taken, or -1 when every slot is held.
static int slot_taken(void) {
    for (int i = 0; i < g_slot_count; i++) {
        char path[PATH_BYTES];
        snprintf(path, sizeof path, "%s/slot-%d", g_dir, i);
        int fd = open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0600);
        if (fd < 0) continue;
        if (flock(fd, LOCK_EX | LOCK_NB) == 0) return fd;
        close(fd);
    }
    return -1;
}

static void napped(int64_t ms) {
    struct timespec t = { (time_t)(ms / 1000), (long)(ms % 1000) * 1000000L };
    nanosleep(&t, NULL);
}

// What this process may use before it asks again, having reserved slots to cover `in_use`: -1 when
// it needs more than the whole pool, -2 when others held what it needed past its wait. With no
// pool, everything.
int64_t avra_pool_allowed(int64_t in_use) {
    pool_settled();
    if (g_slot_count <= 0) return INT64_MAX;
    int64_t waited = 0;
    int said = 0;
    while (FREE_BYTES + (int64_t)g_held_count * SLOT_BYTES < in_use + SLOT_BYTES / 2) {
        if (g_held_count >= g_slot_count) return -1;
        int fd = slot_taken();
        if (fd >= 0) {
            g_held[g_held_count++] = fd;
            continue;
        }
        if (g_held_count > 0 && waited >= g_wait_ms) return -2;
        if (!said) {
            fprintf(stderr, "avra: waiting for memory: the machine's pool is held by other runs\n");
            said = 1;
        }
        napped(200);
        waited += 200;
    }
    return FREE_BYTES + (int64_t)g_held_count * SLOT_BYTES;
}

// How many slots this process holds.
int64_t avra_pool_held(void) { return g_held_count; }

// What a process may use before it first asks the pool.
int64_t avra_pool_free_bytes(void) { return FREE_BYTES; }

#else

int64_t avra_pool_allowed(int64_t in_use) { (void)in_use; return INT64_MAX; }

int64_t avra_pool_held(void) { return 0; }

int64_t avra_pool_free_bytes(void) { return INT64_MAX; }

#endif

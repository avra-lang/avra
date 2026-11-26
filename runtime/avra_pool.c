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
//
// A WAITER NEVER HOLDS A PARTIAL CLAIM: a growth that needs several slots takes all of them or none,
// and gives back what it took before it waits, so two runs each needing most of the pool never sit
// on half of it each. A slot file holds its holder's process id, so a wait can say who holds what.
//
// A POOL HELD WHOLLY BY WAITERS IS DEADLOCKED, and the waiter holding the fewest slots ends it. Two
// runs that each hold slots and each want more wait on each other; a wait marks the waiter's slots,
// so when no slot is free and every held one is marked, the smallest holder (the higher process id
// among equals) refuses at once instead of at the end of its wait. The same judgement twice, a nap
// apart, is what it acts on, so a holder leaving between two reads is never taken for a deadlock.
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
#if defined(__APPLE__)
#include <sys/sysctl.h>
#endif
#include "avra_door.h"
#include "avra_settings.h"
#include "avra_platform.h"
#include "avra_runtime.h"

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
// of each descriptor keeps the parent's lock. The child asks this itself, first, while the
// numbers are still the slots'.
static void pool_forked(void) {
    for (int i = 0; i < g_held_count; i++) close(g_held[i]);
    g_held_count = 0;
}

// The pool's size and directory, settled on first use. No pool when it's turned off, sized to
// nothing, or its directory can't be made.
static void pool_settled(void) {
    if (g_slot_count >= 0) return;
    g_slot_count = 0;
    const char* sized = getenv(AVRA_SET_MEM_POOL_MB);
    int64_t bytes = sized && *sized ? (int64_t)atoll(sized) << 20 : machine_bytes() / 100 * POOL_PERCENT;
    const char* waits = getenv(AVRA_SET_MEM_POOL_WAIT_MS);
    if (waits && *waits) g_wait_ms = atoll(waits);
    if (bytes <= 0) return;
    const char* placed = getenv(AVRA_SET_MEM_POOL_DIR);
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
}

// One free slot taken, its file naming this process, or -1 when every slot is held.
static int slot_taken(void) {
    for (int i = 0; i < g_slot_count; i++) {
        char path[PATH_BYTES];
        snprintf(path, sizeof path, "%s/slot-%d", g_dir, i);
        int fd = open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0600);
        if (fd < 0) continue;
        // the clock: LOCK_NB answers at once, taken or not
        if (flock(fd, LOCK_EX | LOCK_NB) == 0) {
            char pid[24];
            int n = snprintf(pid, sizeof pid, "%d\n", (int)getpid());
            if (ftruncate(fd, 0) == 0) { ssize_t w = pwrite(fd, pid, (size_t)n, 0); (void)w; }
            return fd;
        }
        close(fd);
    }
    return -1;
}

// Each slot this process holds marked as waiting, or as not.
static void held_marked(int waiting) {
    char text[32];
    int n = snprintf(text, sizeof text, waiting ? "%d w\n" : "%d\n", (int)getpid());
    for (int i = 0; i < g_held_count; i++) {
        if (ftruncate(g_held[i], 0) == 0) { ssize_t w = pwrite(g_held[i], text, (size_t)n, 0); (void)w; }
    }
}

// Whether the pool is held wholly by waiters and this process holds the fewest of its slots, the
// higher process id among equals: the one that ends the deadlock.
static int deadlock_ends_here(void) {
    int pids[MOST_SLOTS], counts[MOST_SLOTS], distinct = 0;
    for (int i = 0; i < g_slot_count; i++) {
        char path[PATH_BYTES];
        snprintf(path, sizeof path, "%s/slot-%d", g_dir, i);
        int fd = open(path, O_RDONLY | O_CLOEXEC);
        if (fd < 0) return 0;
        // the clock: LOCK_NB answers at once, taken or not
        int free_now = flock(fd, LOCK_SH | LOCK_NB) == 0;
        char text[32] = {0};
        ssize_t got = free_now ? 0 : pread(fd, text, sizeof text - 1, 0);
        close(fd);
        if (free_now || got <= 0 || !strchr(text, 'w')) return 0;
        int pid = atoi(text), at = 0;
        while (at < distinct && pids[at] != pid) at++;
        if (at == distinct) { pids[distinct] = pid; counts[distinct++] = 0; }
        counts[at]++;
    }
    for (int at = 0; at < distinct; at++) {
        if (pids[at] == (int)getpid()) continue;
        if (counts[at] < g_held_count || (counts[at] == g_held_count && pids[at] > (int)getpid())) return 0;
    }
    return 1;
}

// `need` slots taken together, or none: what was taken goes back when not all of them could be.
static int whole_claim_taken(int need) {
    int taken = 0;
    while (taken < need) {
        int fd = slot_taken();
        if (fd < 0) {
            while (taken > 0) close(g_held[g_held_count + --taken]);
            return 0;
        }
        g_held[g_held_count + taken++] = fd;
    }
    g_held_count += need;
    return 1;
}

// Who holds the pool's slots besides this process: each holder's process id and its count,
// written into `out`.
static void holders_said(char* out, size_t room) {
    int pids[MOST_SLOTS], counts[MOST_SLOTS], distinct = 0;
    for (int i = 0; i < g_slot_count; i++) {
        char path[PATH_BYTES];
        snprintf(path, sizeof path, "%s/slot-%d", g_dir, i);
        int fd = open(path, O_RDONLY | O_CLOEXEC);
        if (fd < 0) continue;
        // the clock: LOCK_NB answers at once, taken or not
        int free_now = flock(fd, LOCK_SH | LOCK_NB) == 0;
        char text[24] = {0};
        ssize_t got = free_now ? 0 : pread(fd, text, sizeof text - 1, 0);
        close(fd);
        int pid = got > 0 ? atoi(text) : 0;
        if (free_now || pid == (int)getpid()) continue;
        int at = 0;
        while (at < distinct && pids[at] != pid) at++;
        if (at == distinct) { pids[distinct] = pid; counts[distinct++] = 0; }
        counts[at]++;
    }
    size_t used = 0;
    out[0] = 0;
    for (int at = 0; at < distinct && used + 32 < room; at++) {
        used += (size_t)snprintf(out + used, room - used, "%s%d slot(s) by pid %d", at ? ", " : "", counts[at], pids[at]);
    }
    if (distinct == 0) snprintf(out, room, "no holder named");
}

static void napped(int64_t ms) {
    struct timespec t = { (time_t)(ms / 1000), (long)(ms % 1000) * 1000000L };
    // A HOLD WOULD BE WRONG HERE: it would move a virtual clock by however long another process kept
    // its memory, and give every growth a path to the clock's own traps.
    // the clock: a wait for another process's memory, timed by its own naps
    nanosleep(&t, NULL);
}

// What this process may use before it asks again, having reserved slots to cover `in_use`: -1 when
// it needs more than the whole pool, -2 when others held what it needed past its wait, -3 when it
// ends a deadlock. With no pool, everything.
int64_t avra_pool_allowed(int64_t in_use) {
    pool_settled();
    if (g_slot_count <= 0) return INT64_MAX;
    int64_t covered = FREE_BYTES + (int64_t)g_held_count * SLOT_BYTES;
    int64_t short_by = in_use + SLOT_BYTES / 2 - covered;
    if (short_by <= 0) return covered;
    int need = (int)((short_by + SLOT_BYTES - 1) / SLOT_BYTES);
    if (g_held_count + need > g_slot_count) return -1;
    int64_t waited = 0, nap = 200;
    int said = 0, deadlocked = 0;
    while (!whole_claim_taken(need)) {
        if (g_held_count > 0 && waited >= g_wait_ms) return -2;
        if (g_held_count > 0) {
            if (!said) held_marked(1);
            deadlocked = deadlock_ends_here() ? deadlocked + 1 : 0;
            if (deadlocked == 2) return -3;
        }
        if (!said) {
            char who[512];
            holders_said(who, sizeof who);
            fprintf(stderr, "avra: waiting for memory: this run holds %d slot(s) and needs %d more of the pool's %d; held: %s\n",
                    g_held_count, need, g_slot_count, who);
            said = 1;
        }
        // a nap that grows, and differs by process, so two waiters do not retry in step
        napped(nap + (int64_t)(getpid() % 97));
        waited += nap;
        if (nap < 2000) nap *= 2;
    }
    if (said) held_marked(0);
    return FREE_BYTES + (int64_t)g_held_count * SLOT_BYTES;
}

// The use at or under which this process holds a slot it does not fill: one slot gone still
// leaves a whole slot of room, twice the half `avra_pool_allowed` asks for, so a run hovering at
// a boundary neither takes nor gives back on every look. INT64_MIN while it holds none.
int64_t avra_pool_spare_at(void) {
    return g_held_count > 0 ? FREE_BYTES + (int64_t)(g_held_count - 2) * SLOT_BYTES : INT64_MIN;
}

// The slots this process holds that `in_use` does not fill, given back to the machine; what it
// may use before it asks again.
int64_t avra_pool_let_go(int64_t in_use) {
    pool_settled();
    if (g_slot_count <= 0) return INT64_MAX;
    while (in_use <= avra_pool_spare_at()) close(g_held[--g_held_count]);
    return FREE_BYTES + (int64_t)g_held_count * SLOT_BYTES;
}

// How many slots this process holds.
int64_t avra_pool_held(void) { return g_held_count; }

// What a process may use before it first asks the pool.
int64_t avra_pool_free_bytes(void) { return FREE_BYTES; }

static const char* pool_refused(int64_t code) {
    if (code == -1) return "this run needs more than the machine's whole memory pool: %lld MB in use (AVRA_MEM_POOL_MB)";
    if (code == -2) return "other runs held the machine's memory pool past this run's wait: %lld MB in use (AVRA_MEM_POOL_WAIT_MS)";
    return "the machine's memory pool is held wholly by runs waiting for more, and this run holds the least of it: %lld MB in use";
}

static const AvraPool pool = {
    .allowed = avra_pool_allowed,
    .let_go = avra_pool_let_go,
    .spare_at = avra_pool_spare_at,
    .held = avra_pool_held,
    .free_bytes = avra_pool_free_bytes,
    .forked = pool_forked,
    .refused = pool_refused,
};

__attribute__((constructor))
static void pool_installed(void) { avra_pool_install(&pool); }

#endif

// What a build names (`-u avra_pool_linked`) to link the pool: nothing in the runtime reaches this
// member, so a build that does not name it carries no pool.
const int avra_pool_linked = 1;

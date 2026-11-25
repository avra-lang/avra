// ── Cores: one process per core, sharing nothing ────────────────
//
// A GROUP is n processes forked from one: each a CORE with its own
// scheduler, heap and descriptors, the one before the fork its
// SUPERVISOR. Nothing crosses into a core but the descriptor it was
// forked to serve, and nothing crosses back but what the group's
// record says: open connections while it runs, and how it ended.
//
// Every call here answers at once; the waits are the caller's parks
// (`avra_fiber_park_fd`), so the evaluator runs the same C.
//
// THE PIPES ARE THE PROTOCOL, and they carry no bytes. Every core
// holds the read end of ONE stop pipe whose write end only the
// supervisor holds: closing it — or the supervisor dying — reads as
// end-of-file in every core at once. Each core holds the write end of
// its OWN pipe: the kernel closes it when the core ends, however it
// ends, so the supervisor learns of a crash without a signal.

#if defined(__linux__)
#define _GNU_SOURCE
#endif

#include <dirent.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <sched.h>
#include <time.h>
#include <unistd.h>
#if defined(__APPLE__)
#include <libproc.h>
#include <sys/proc.h>
#endif

#include "avra_cores.h"
#include "avra_settings.h"
#include "avra_fiber.h"
#include "avra_runtime.h"

// What a core tells the supervisor, in memory the whole group shares.
// Each core writes only its own slot. One slot past the cores' is the
// group's own: its `live` counts the turns its cores have claimed.
typedef struct {
    int64_t live;        // open connections
    int64_t accepted;    // written as it leaves
    int64_t err;         // the errno it left with, or 0
} Slot;

// The group as ONE PROCESS holds it: private memory, so a fork copies
// it and each process's descriptors are its own to close. Nothing
// here is shared but the slots it points at.
typedef struct {
    int64_t n;
    pid_t supervisor;
    int stop_read, stop_write;
    Slot* slots;
    struct {
        pid_t pid;
        int end_read, end_write;
        int ended;           // reaped, by the supervisor
        int status;          // its wait status, once reaped
    } core[];
} Group;

static Group* group_at(int64_t g) { return (Group*)(uintptr_t)g; }

// A reaped core's id marked gone in the table its wave shares, where there is one.
static void core_marked_gone(int64_t pid);

static int is_supervisor(const Group* gr) { return gr->supervisor == getpid(); }

int64_t avra_cores_online(void) {
#if defined(__linux__)
    cpu_set_t set;
    if (sched_getaffinity(0, sizeof set, &set) == 0) return CPU_COUNT(&set);
#endif
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return n > 0 ? n : 1;
}

static int marked(int fd, int nonblocking) {
    int fl = fcntl(fd, F_GETFL);
    return fcntl(fd, F_SETFD, FD_CLOEXEC) == 0 && (!nonblocking || (fl >= 0 && fcntl(fd, F_SETFL, fl | O_NONBLOCK) == 0));
}

static int piped(int* read_end, int* write_end) {
    int p[2];
    if (pipe(p) != 0) return -errno;
    if (!marked(p[0], 1) || !marked(p[1], 0)) { int e = errno; close(p[0]); close(p[1]); return -e; }
    *read_end = p[0];
    *write_end = p[1];
    return 0;
}

static void group_free(Group* gr) {
    if (gr->stop_read >= 0) close(gr->stop_read);
    if (gr->stop_write >= 0) close(gr->stop_write);
    for (int64_t i = 0; i < gr->n; i++) {
        if (gr->core[i].end_read >= 0) { avra_fiber_fd_closing(gr->core[i].end_read); close(gr->core[i].end_read); }
        if (gr->core[i].end_write >= 0) close(gr->core[i].end_write);
    }
    if (gr->slots) munmap(gr->slots, (size_t)(gr->n + 1) * sizeof(Slot));
    free(gr);
}

// A group of `n` cores, not yet forked: its record and its pipes. The
// handle, or -errno.
int64_t avra_cores_group(int64_t n) {
    if (n < 1 || n > 4096) return -EINVAL;
    Group* gr = calloc(1, sizeof(Group) + (size_t)n * sizeof(gr->core[0]));
    if (!gr) return -ENOMEM;
    gr->n = n;
    gr->supervisor = getpid();
    gr->stop_read = gr->stop_write = -1;
    for (int64_t i = 0; i < n; i++) gr->core[i].end_read = gr->core[i].end_write = -1;
    void* slots = mmap(NULL, (size_t)(n + 1) * sizeof(Slot), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
    if (slots == MAP_FAILED) { int64_t e = -errno; group_free(gr); return e; }
    gr->slots = slots;
    int64_t err = piped(&gr->stop_read, &gr->stop_write);
    for (int64_t i = 0; i < n && err == 0; i++) err = piped(&gr->core[i].end_read, &gr->core[i].end_write);
    if (err < 0) { group_free(gr); return err; }
    return (int64_t)(uintptr_t)gr;
}

static int kept(int fd, const int* keep, int n) {
    for (int i = 0; i < n; i++) if (keep[i] == fd) return 1;
    return 0;
}

// Every descriptor but `keep` closed. What is open is read from the
// system's own list, then closed — never while the listing is open.
// NO STATIC HOLDS A DESCRIPTOR NUMBER ACROSS THIS CLOSE: a number kept past
// it names whatever the core opens next. A static's descriptor is in
// `keep`, or forgotten before the close, or opened only after it.
static void close_all_but(const int* keep, int n) {
    DIR* d = opendir("/dev/fd");
    if (!d) avra_trap("a core could not list its descriptors");
    int* open_fds = NULL;
    size_t count = 0, cap = 0;
    for (struct dirent* e; (e = readdir(d));) {
        if (e->d_name[0] < '0' || e->d_name[0] > '9') continue;
        if (count == cap) {
            cap = cap ? cap * 2 : 64;
            open_fds = realloc(open_fds, cap * sizeof(int));
            if (!open_fds) avra_trap("a core ran out of memory listing its descriptors");
        }
        open_fds[count++] = atoi(e->d_name);
    }
    int listing = dirfd(d);
    closedir(d);
    for (size_t i = 0; i < count; i++) {
        if (open_fds[i] != listing && !kept(open_fds[i], keep, n)) close(open_fds[i]);
    }
    free(open_fds);
}

// The child's half of a fork: its descriptors are the standard three, the
// one it serves, the stop pipe's read end and its own pipe's write end, and
// its scheduler keeps the calling task alone. DESCRIPTORS FIRST: what the
// scheduler brings up in the child (the tick's wake pipe) opens its own, and
// a close after it would free numbers the tick still reads while the
// child's own files take them.
static void became_core(Group* gr, int64_t i, int64_t serving) {
    int keep[] = { 0, 1, 2, (int)serving, gr->stop_read, gr->core[i].end_write, avra_fiber_trace_fd() };
    avra_pool_forked();
    avra_mem_forked();
    avra_descriptors_forgotten();
    close_all_but(keep, 7);
    avra_fiber_forked();
}

// THE FORK HOOKS: process-global state a package keeps (a database driver's connections and
// the files they lock) does not survive a fork, so each package that holds some registers a
// PREPARE hook here, and the cores' fork asks every one before it forks. A hook readies its
// state to be dropped and rebuilt on either side of the fork, or refuses (nonzero) with its words
// left in `*why`, and then nothing forks.
#define FORK_HOOKS 16
static int (*g_fork_hooks[FORK_HOOKS])(const char** why);
static int g_fork_hook_count = 0;

void avra_fork_hook(int (*prepare)(const char** why)) {
    if (g_fork_hook_count < FORK_HOOKS) g_fork_hooks[g_fork_hook_count++] = prepare;
}

// The first refusal among the hooks, or 0. A refusal is reported on stderr in its own words,
// and the fork answers EBUSY to its caller.
static int fork_prepared(void) {
    for (int i = 0; i < g_fork_hook_count; i++) {
        const char* why = NULL;
        if (g_fork_hooks[i](&why) != 0) {
            fprintf(stderr, "avra: not forking cores: %s\n", why ? why : "a package holds state that cannot cross a fork");
            return -EBUSY;
        }
    }
    return 0;
}

// Forks the group: answers the core's index in each core, `n` in the
// supervisor, or -errno — the cores already forked told to stop and
// reaped. `serving` is the descriptor the cores keep.
int64_t avra_cores_fork(int64_t g, int64_t serving) {
    Group* gr = group_at(g);
    int refused = fork_prepared();
    if (refused != 0) { group_free(gr); return refused; }
    fflush(NULL);
    for (int64_t i = 0; i < gr->n; i++) {
        pid_t pid = fork();
        if (pid == 0) { became_core(gr, i, serving); return i; }
        if (pid < 0) {
            int64_t err = -errno;
            close(gr->stop_write);
            gr->stop_write = -1;
            avra_clock_hold(1);
            for (int64_t j = 0; j < i; j++) waitpid(gr->core[j].pid, NULL, 0);
            avra_clock_hold(-1);
            group_free(gr);
            return err;
        }
        gr->core[i].pid = pid;
    }
    close(gr->stop_read);
    gr->stop_read = -1;
    for (int64_t i = 0; i < gr->n; i++) { close(gr->core[i].end_write); gr->core[i].end_write = -1; }
    return gr->n;
}

// THE NEXT TURN OF THE GROUP'S WORK, claimed by the core that asks: 0, then 1, and on, each
// answered to one core alone, whichever asks first. Cores sharing a list of work each take the
// item at the turn they claim, so none waits while another still holds items.
int64_t avra_cores_claimed(int64_t g) {
    Group* gr = group_at(g);
    return __atomic_fetch_add(&gr->slots[gr->n].live, 1, __ATOMIC_SEQ_CST);
}

// A core's end of the stop pipe, to park on.
int64_t avra_cores_stop_fd(int64_t g) { return group_at(g)->stop_read; }

// 1 when the group has been told to stop — or its supervisor is gone —
// else 0. A core parks on the stop pipe while this answers 0.
int64_t avra_cores_stopped(int64_t g) {
    char b;
    // the clock: the stop pipe's read end is O_NONBLOCK, a read answers at once
    ssize_t got = read(group_at(g)->stop_read, &b, 1);
    return got == 0 || (got < 0 && errno != EAGAIN && errno != EINTR);
}

// The core's open connections, for the supervisor to sum.
void avra_cores_count(int64_t g, int64_t core, int64_t live) {
    __atomic_store_n(&group_at(g)->slots[core].live, live, __ATOMIC_RELAXED);
}

int64_t avra_cores_live(int64_t g) {
    Group* gr = group_at(g);
    int64_t sum = 0;
    for (int64_t i = 0; i < gr->n; i++) sum += __atomic_load_n(&gr->slots[i].live, __ATOMIC_RELAXED);
    return sum;
}

// The core ends: what it accepted and the errno it failed with (0 when
// it stopped as asked) left in the record, the process exited — 1 on a
// failure, else 0. Never returns.
int64_t avra_cores_leave(int64_t g, int64_t core, int64_t accepted, int64_t err) {
    Group* gr = group_at(g);
    gr->slots[core].accepted = accepted;
    gr->slots[core].err = err;
    exit(err != 0);
}

// The descriptor that ends when core `core` does, to park on.
int64_t avra_cores_end_fd(int64_t g, int64_t core) { return group_at(g)->core[core].end_read; }

// 0 once core `core` has ended — reaped, its status kept — else
// -EAGAIN while it runs.
int64_t avra_cores_heard(int64_t g, int64_t core) {
    Group* gr = group_at(g);
    if (gr->core[core].ended) return 0;
    char b[16];
    // the clock: the end pipe's read end is O_NONBLOCK, a read answers at once
    ssize_t got = read(gr->core[core].end_read, b, sizeof b);
    if (got != 0 && !(got < 0 && errno != EAGAIN && errno != EINTR)) return -EAGAIN;
    int status = 0;
    // A CLOSED END PIPE IS NOT AN ENDED CORE: a read that failed, or a
    // child that closed its end and runs on, leaves this waiting on it.
    avra_clock_hold(1);
    while (waitpid(gr->core[core].pid, &status, 0) < 0 && errno == EINTR) {}
    avra_clock_hold(-1);
    gr->core[core].status = status;
    gr->core[core].ended = 1;
    core_marked_gone((int64_t)gr->core[core].pid);
    avra_fiber_fd_closing(gr->core[core].end_read);
    close(gr->core[core].end_read);
    gr->core[core].end_read = -1;
    return 0;
}

// Core `core` ended at once, by SIGKILL, when it has not ended yet, and reaped: a supervisor
// that gives up waiting on it leaves nothing running. 0 once it has ended.
int64_t avra_cores_killed(int64_t g, int64_t core) {
    Group* gr = group_at(g);
    if (gr->core[core].ended) return 0;
    kill(gr->core[core].pid, SIGKILL);
    while (avra_cores_heard(g, core) != 0) {}
    return 0;
}

// Every core told to stop: the stop pipe's write end closed. Only the
// supervisor holds it; anywhere else this does nothing.
void avra_cores_stop(int64_t g) {
    Group* gr = group_at(g);
    if (!is_supervisor(gr) || gr->stop_write < 0) return;
    close(gr->stop_write);
    gr->stop_write = -1;
}

// A core ended as a core ends: exited 0 when stopped, or 1 having left
// its errno. Anything else — a trap, a signal, an exit of its own — is
// a crash.
static int clean(int status, int64_t err) {
    return WIFEXITED(status) && (WEXITSTATUS(status) == 0 || (WEXITSTATUS(status) == 1 && err != 0));
}

static void crashed(int64_t core, int64_t n, int status) {
    char why[160];
    if (WIFSIGNALED(status)) snprintf(why, sizeof why, "core %lld of %lld was killed by signal %d — the server stopped", (long long)core, (long long)n, WTERMSIG(status));
    else snprintf(why, sizeof why, "core %lld of %lld ended with status %d — the server stopped", (long long)core, (long long)n, WEXITSTATUS(status));
    avra_trap(why);
}

// How the group ended, once every core has: the connections accepted
// across it, or -errno for the first core that failed. A core that
// trapped or was killed traps here, naming it. The group is gone after.
int64_t avra_cores_result(int64_t g) {
    Group* gr = group_at(g);
    int64_t n = gr->n, accepted = 0, err = 0;
    for (int64_t i = 0; i < n; i++) {
        if (!clean(gr->core[i].status, gr->slots[i].err)) {
            int status = gr->core[i].status;
            group_free(gr);
            crashed(i, n, status);
        }
        accepted += gr->slots[i].accepted;
        if (err == 0) err = gr->slots[i].err;
    }
    group_free(gr);
    return err != 0 ? -err : accepted;
}

// How many cores ended as a core ends with no errno left, once every core
// has. A core that trapped or was killed is only not counted: nothing traps
// here. The group is gone after.
int64_t avra_cores_finished(int64_t g) {
    Group* gr = group_at(g);
    int64_t finished = 0;
    for (int64_t i = 0; i < gr->n; i++) finished += clean(gr->core[i].status, gr->slots[i].err) && gr->slots[i].err == 0;
    group_free(gr);
    return finished;
}

// AN HEIR: a process forked to finish what this one leaves, which outlives it. It keeps every
// descriptor and mapping this process holds, leads a session of its own, is no child of this
// process once the call answers, and reads nothing of the standard three; with `quiet` it writes
// nothing to them either. `AVRA_HEIR_LINGERS_MS` holds it back that long before it answers. Answers 0 in the heir, 1 in the process that forked it, or -errno where
// none was forked.
int64_t avra_cores_heir(int64_t quiet) {
    int refused = fork_prepared();
    if (refused != 0) return refused;
    fflush(NULL);
    pid_t between = fork();
    if (between < 0) return -errno;
    if (between > 0) {
        int status = 0;
        avra_clock_hold(1);
        while (waitpid(between, &status, 0) < 0 && errno == EINTR) {}
        avra_clock_hold(-1);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 1 : -ECHILD;
    }
    setsid();
    pid_t heir = fork();
    if (heir != 0) _exit(heir < 0);
    avra_pool_forked();
    avra_descriptors_forgotten();
    avra_fiber_forked();
    int null = open("/dev/null", O_RDWR);
    if (null >= 0) {
        dup2(null, 0);
        if (quiet) { dup2(null, 1); dup2(null, 2); }
        if (null > 2) close(null);
    }
    // the test hook that holds an heir back, so a witness meets its work unfinished
    const char* lingers = getenv(AVRA_SET_HEIR_LINGERS_MS);
    if (lingers && *lingers) {
        avra_clock_hold(1);
        usleep((useconds_t)atoll(lingers) * 1000);
        avra_clock_hold(-1);
    }
    return 0;
}

// ── What a wave's cores share while they work ───────────────────
//
// A SHARED TABLE is memory every core of a wave maps: octets one core
// kept, found by the others by a 128-bit key, and the claims of the
// keys being worked. It is made before the fork and is each core's to
// read and append; nothing in it is ever changed once it can be found.
//
// OCTETS ARE WRITTEN BEFORE THEY CAN BE FOUND: a writer takes its room
// by one atomic add, copies into it, and only then takes a slot, so a
// slot that names octets names whole ones. A slot is taken by one
// compare-and-swap to BUSY, filled, and made READY; a reader that meets
// a BUSY slot waits for it, and one whose writer died in between
// reads it as dead, never as a key. A CLAIM is a slot whose state is
// the claimant's process id: it stands while that process lives.

// The kinds a table keeps: 0 and 1 octets by key, 2 the claims, 3 and 4 octets by key again.
enum { SHARED_KINDS = 5, SHARED_CLAIMS = 2 };
enum { SLOT_FREE = 0, SLOT_READY = -1, SLOT_BUSY_BASE = -1000000000, SLOT_DEAD = -2, SLOT_LET_GO = -3 };

typedef struct {
    int64_t state;   // FREE, READY, DEAD, LET_GO, a claimant's pid, or BUSY_BASE - the writer's pid
    uint64_t hi, lo;
    int64_t from, to;
} SharedSlot;

// THE KINDS FROM `SHARED_APART` ON keep their octets in an arena of their own, and log where each
// kept octets lie in the order they were kept: a reader of every one of them reads the log and that
// arena, never the slots or the octets of the other kinds.
enum { SHARED_APART = 3 };

typedef struct {
    int64_t slots;       // per kind, a power of two
    int64_t room;        // octets
    int64_t used;        // octets taken, by atomic add
    SharedSlot* table;   // SHARED_KINDS * slots
    char* octets;
    AvraSharedView view; // what a reader maps the octets as
    char* apart;         // the octets of the kinds from SHARED_APART on
    AvraSharedView apart_view;
    int64_t* apart_words; // the octets taken there, then each logged kind's count and its log
} Shared;

// A logged kind's count, then two words a logged octets: where they end, then where they start, plus one.
static int64_t* apart_count(Shared* sh, int64_t kind) { return sh->apart_words + 1 + (kind - SHARED_APART) * (1 + 2 * sh->slots); }

// The words every process of a table shares beside its slots: the octets used, the claims counted,
// how many processes are known gone, and their ids.
enum { SHARED_GONE_MOST = 4096, SHARED_WORDS = 3 + SHARED_GONE_MOST };

// The table this process's wave shares, once one is made: what the supervisor marks an ended core in.
static void* g_shared = NULL;

// WHETHER A PROCESS HAS ENDED AND WAITS ONLY TO BE REAPED: it holds its id until then, and answers
// a signal as a living one does, so its state is read from the system's own record of it.
static int pid_is_zombie(int64_t pid) {
#if defined(__linux__)
    char path[64], line[512];
    snprintf(path, sizeof path, "/proc/%lld/stat", (long long)pid);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 0;
    // the clock: a proc file is the kernel's own record, read at once
    ssize_t got = read(fd, line, sizeof line - 1);
    close(fd);
    if (got <= 0) return 0;
    line[got] = 0;
    // the command name is in parentheses and may hold one itself: the state follows the LAST `)`
    ssize_t close_at = got - 1;
    while (close_at >= 0 && line[close_at] != ')') close_at--;
    if (close_at < 0) return 0;
    const char* after = line + close_at;
    return after[1] == ' ' && (after[2] == 'Z' || after[2] == 'X');
#elif defined(__APPLE__)
    struct proc_bsdinfo info;
    if (proc_pidinfo((int)pid, PROC_PIDTBSDINFO, 0, &info, sizeof info) != (int)sizeof info) return 0;
    return info.pbi_status == SZOMB;
#else
    (void)pid;
    return 0;
#endif
}

static int pid_lives(int64_t pid);


// A table of `slots` slots a kind (rounded up to a power of two) and `room` octets; null where the
// machine gives none.
void* avra_shared_made(int64_t slots, int64_t room) {
    int64_t n = 1024;
    while (n < slots) n <<= 1;
    Shared* sh = calloc(1, sizeof(Shared));
    if (!sh) return NULL;
    size_t table_bytes = (size_t)SHARED_KINDS * (size_t)n * sizeof(SharedSlot);
    void* table = mmap(NULL, table_bytes, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    void* octets = mmap(NULL, (size_t)room, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    int64_t* used = mmap(NULL, SHARED_WORDS * sizeof(int64_t), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (table == MAP_FAILED || octets == MAP_FAILED || used == MAP_FAILED) {
        if (table != MAP_FAILED) munmap(table, table_bytes);
        if (octets != MAP_FAILED) munmap(octets, (size_t)room);
        if (used != MAP_FAILED) munmap(used, SHARED_WORDS * sizeof(int64_t));
        free(sh);
        return NULL;
    }
    sh->slots = n;
    sh->room = room;
    sh->used = (int64_t)(intptr_t)used;
    sh->table = table;
    sh->octets = octets;
    sh->view.base = octets;
    sh->view.len = room;
    size_t apart_room = (size_t)room / 4;
    size_t apart_words = (size_t)(1 + (SHARED_KINDS - SHARED_APART) * (1 + 2 * n)) * sizeof(int64_t);
    void* apart = mmap(NULL, apart_room, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    void* words = mmap(NULL, apart_words, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    if (apart == MAP_FAILED || words == MAP_FAILED) {
        if (apart != MAP_FAILED) munmap(apart, apart_room);
        if (words != MAP_FAILED) munmap(words, apart_words);
        munmap(table, table_bytes);
        munmap(octets, (size_t)room);
        munmap(used, SHARED_WORDS * sizeof(int64_t));
        free(sh);
        return NULL;
    }
    sh->apart = apart;
    sh->apart_view.base = apart;
    sh->apart_view.len = (int64_t)apart_room;
    sh->apart_words = words;
    g_shared = sh;
    return sh;
}

static int64_t* shared_used(Shared* sh) { return (int64_t*)(intptr_t)sh->used; }

// A process of the table's wave marked gone by the supervisor that reaped it: its id is never
// again a living holder's here, whoever the system gives the id to next.
static void shared_gone(Shared* sh, int64_t pid) {
    int64_t* words = shared_used(sh);
    int64_t at = __atomic_fetch_add(words + 2, 1, __ATOMIC_ACQ_REL);
    if (at < SHARED_GONE_MOST) __atomic_store_n(words + 3 + at, pid, __ATOMIC_RELEASE);
}

static int shared_knows_gone(Shared* sh, int64_t pid) {
    int64_t* words = shared_used(sh);
    int64_t n = __atomic_load_n(words + 2, __ATOMIC_ACQUIRE);
    if (n > SHARED_GONE_MOST) n = SHARED_GONE_MOST;
    for (int64_t i = 0; i < n; i++) if (__atomic_load_n(words + 3 + i, __ATOMIC_ACQUIRE) == pid) return 1;
    return 0;
}

static void core_marked_gone(int64_t pid) { if (g_shared) shared_gone(g_shared, pid); }

// WHETHER THE PROCESS `pid` STILL RUNS, as a holder of a claim must: not one the supervisor reaped,
// not one the system no longer knows, and not one that has ended and waits to be reaped.
static int pid_lives(int64_t pid) {
    if (pid <= 0) return 0;
    if (g_shared && shared_knows_gone(g_shared, pid)) return 0;
    if (kill((pid_t)pid, 0) != 0 && errno != EPERM) return 0;
    return !pid_is_zombie(pid);
}

// The table unmapped and gone, in the process that made it once its cores have ended.
void avra_shared_ended(void* h) {
    Shared* sh = h;
    if (!sh) return;
    munmap(sh->table, (size_t)SHARED_KINDS * (size_t)sh->slots * sizeof(SharedSlot));
    munmap(sh->octets, (size_t)sh->room);
    munmap(shared_used(sh), SHARED_WORDS * sizeof(int64_t));
    munmap(sh->apart, (size_t)sh->apart_view.len);
    munmap(sh->apart_words, (size_t)(1 + (SHARED_KINDS - SHARED_APART) * (1 + 2 * sh->slots)) * sizeof(int64_t));
    if (g_shared == sh) g_shared = NULL;
    free(sh);
}

// The octets of the table, as a mapping a reader reads in place.
void* avra_shared_view(void* h) { return &((Shared*)h)->view; }

// The octets of the kinds kept apart, as a mapping a reader reads in place.
void* avra_shared_apart_view(void* h) { return &((Shared*)h)->apart_view; }

// The state of a slot once it is no longer being written: a slot whose writer died is made dead.
static int64_t slot_settled(SharedSlot* s) {
    for (int spins = 0;; spins++) {
        int64_t st = __atomic_load_n(&s->state, __ATOMIC_ACQUIRE);
        if (st > SLOT_BUSY_BASE / 2) return st;
        if (spins > 64 && !pid_lives(SLOT_BUSY_BASE - st)) {
            __atomic_compare_exchange_n(&s->state, &st, SLOT_DEAD, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
            continue;
        }
        if (spins > 64) sched_yield();
    }
}

// The slot of `kind` that holds the key, or the free one it would take; null where the table is full.
static SharedSlot* slot_for(Shared* sh, int64_t kind, uint64_t hi, uint64_t lo, int* found) {
    SharedSlot* base = sh->table + kind * sh->slots;
    uint64_t mask = (uint64_t)sh->slots - 1;
    *found = 0;
    for (uint64_t i = 0; i < (uint64_t)sh->slots; i++) {
        SharedSlot* s = base + ((lo + i) & mask);
        int64_t st = slot_settled(s);
        if (st == SLOT_FREE) return s;
        if (st == SLOT_DEAD) continue;
        if (s->hi == hi && s->lo == lo) { *found = 1; return s; }
    }
    return NULL;
}

// A free slot of `kind` taken for the key and left BUSY, or the slot another took for it first
// (`*found`); null where the table is full.
static SharedSlot* slot_taken(Shared* sh, int64_t kind, uint64_t hi, uint64_t lo, int* found) {
    for (;;) {
        SharedSlot* s = slot_for(sh, kind, hi, lo, found);
        if (!s || *found) return s;
        int64_t free_state = SLOT_FREE;
        if (!__atomic_compare_exchange_n(&s->state, &free_state, SLOT_BUSY_BASE - (int64_t)getpid(), 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) continue;
        s->hi = hi;
        s->lo = lo;
        return s;
    }
}

// `n` octets at `p` kept under the key in `kind` (0 or 1), found by every core from here on: 0 kept,
// 1 already kept by another, -1 no room. The first to keep a key keeps it.
int64_t avra_shared_kept(void* h, int64_t kind, int64_t hi, int64_t lo, const char* p, int64_t n) {
    Shared* sh = h;
    if (kind < 0 || kind >= SHARED_KINDS || kind == SHARED_CLAIMS) return -1;
    int found = 0;
    if (slot_for(sh, kind, (uint64_t)hi, (uint64_t)lo, &found) && found) return 1;
    int apart = kind >= SHARED_APART;
    int64_t* used = apart ? sh->apart_words : shared_used(sh);
    int64_t room = apart ? sh->apart_view.len : sh->room;
    char* octets = apart ? sh->apart : sh->octets;
    int64_t from = __atomic_fetch_add(used, (n + 7) & ~(int64_t)7, __ATOMIC_ACQ_REL);
    if (from + n > room) return -1;
    memcpy(octets + from, p, (size_t)n);
    SharedSlot* s = slot_taken(sh, kind, (uint64_t)hi, (uint64_t)lo, &found);
    if (!s) return -1;
    if (found) return 1;
    s->from = from;
    s->to = from + n;
    __atomic_store_n(&s->state, SLOT_READY, __ATOMIC_RELEASE);
    if (apart) {
        // logged once kept whole: a reader of the log never meets octets still being written
        int64_t* count = apart_count(sh, kind);
        int64_t at = __atomic_fetch_add(count, 1, __ATOMIC_ACQ_REL);
        if (at < sh->slots) {
            __atomic_store_n(count + 2 + 2 * at, from + n, __ATOMIC_RELEASE);
            __atomic_store_n(count + 1 + 2 * at, from + 1, __ATOMIC_RELEASE);
        }
    }
    return 0;
}

// Where the octets kept under the key in `kind` start, or -1 where none are; `avra_shared_end` then
// answers where they end.
int64_t avra_shared_start(void* h, int64_t kind, int64_t hi, int64_t lo) {
    int found = 0;
    SharedSlot* s = slot_for(h, kind, (uint64_t)hi, (uint64_t)lo, &found);
    return s && found ? s->from : -1;
}

int64_t avra_shared_end(void* h, int64_t kind, int64_t hi, int64_t lo) {
    int found = 0;
    SharedSlot* s = slot_for(h, kind, (uint64_t)hi, (uint64_t)lo, &found);
    return s && found ? s->to : -1;
}

// THE OCTETS A KIND KEPT APART, READ ONE BY ONE in the order they were kept, which is no order a
// reader may keep: whoever reads every one sorts what it reads. How many were logged, and where the
// `at`th starts, -1 where it is still being logged; its end is what its own octets say.
int64_t avra_shared_logged(void* h, int64_t kind) {
    Shared* sh = h;
    if (kind < SHARED_APART || kind >= SHARED_KINDS) return 0;
    int64_t n = __atomic_load_n(apart_count(sh, kind), __ATOMIC_ACQUIRE);
    return n < sh->slots ? n : sh->slots;
}

int64_t avra_shared_logged_start(void* h, int64_t kind, int64_t at) {
    Shared* sh = h;
    if (kind < SHARED_APART || kind >= SHARED_KINDS || at < 0 || at >= sh->slots) return -1;
    return __atomic_load_n(apart_count(sh, kind) + 1 + 2 * at, __ATOMIC_ACQUIRE) - 1;
}

int64_t avra_shared_logged_end(void* h, int64_t kind, int64_t at) {
    Shared* sh = h;
    if (kind < SHARED_APART || kind >= SHARED_KINDS || at < 0 || at >= sh->slots) return -1;
    return __atomic_load_n(apart_count(sh, kind) + 2 + 2 * at, __ATOMIC_ACQUIRE);
}

// THE WITNESS'S HOOKS: the process that takes the table's `AVRA_SHARED_KILL_AT`-th claim is killed
// holding it, and the one that takes its `AVRA_SHARED_TRAP_AT`-th traps holding it, so a witness
// meets a claim whose holder is gone.
static void claim_counted(Shared* sh) {
    static int64_t kill_at = -1, trap_at = -1;
    if (kill_at < 0) {
        const char* k = getenv(AVRA_SET_SHARED_KILL_AT);
        const char* t = getenv(AVRA_SET_SHARED_TRAP_AT);
        kill_at = k && *k ? atoll(k) : 0;
        trap_at = t && *t ? atoll(t) : 0;
    }
    if (kill_at == 0 && trap_at == 0) return;
    int64_t nth = __atomic_add_fetch(shared_used(sh) + 1, 1, __ATOMIC_ACQ_REL);
    if (nth == kill_at) raise(SIGKILL);
    if (nth == trap_at) avra_trap("a witness trapped the holder of a claim");
}

// THE KEY CLAIMED by this process: 0 where it now holds the claim — nobody held it, or the process
// that did has let it go or died — else the id of the living process that holds it.
int64_t avra_shared_claimed(void* h, int64_t hi, int64_t lo) {
    Shared* sh = h;
    int64_t mine = (int64_t)getpid();
    int found = 0;
    SharedSlot* s = slot_taken(sh, SHARED_CLAIMS, (uint64_t)hi, (uint64_t)lo, &found);
    if (!s) return 0;
    if (!found) { __atomic_store_n(&s->state, mine, __ATOMIC_RELEASE); claim_counted(sh); return 0; }
    for (;;) {
        int64_t st = __atomic_load_n(&s->state, __ATOMIC_ACQUIRE);
        if (st == mine) return 0;
        if (st > 0 && pid_lives(st)) return st;
        if (__atomic_compare_exchange_n(&s->state, &st, mine, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) { claim_counted(sh); return 0; }
    }
}

// This process's claim of the key let go.
int64_t avra_shared_let_go(void* h, int64_t hi, int64_t lo) {
    int found = 0;
    SharedSlot* s = slot_for(h, SHARED_CLAIMS, (uint64_t)hi, (uint64_t)lo, &found);
    int64_t mine = (int64_t)getpid();
    if (s && found) __atomic_compare_exchange_n(&s->state, &mine, SLOT_LET_GO, 0, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
    return 0;
}

// Waits while the process `holder` holds the claim of the key and lives: it answers once the claim
// is let go or its holder is dead, never by the clock.
int64_t avra_shared_awaited(void* h, int64_t hi, int64_t lo, int64_t holder) {
    int found = 0;
    SharedSlot* s = slot_for(h, SHARED_CLAIMS, (uint64_t)hi, (uint64_t)lo, &found);
    if (!s || !found) return 0;
    struct timespec nap = { 0, 100000 };
    avra_clock_hold(1);
    while (__atomic_load_n(&s->state, __ATOMIC_ACQUIRE) == holder && pid_lives(holder)) nanosleep(&nap, NULL);
    avra_clock_hold(-1);
    return 0;
}

// The heir ends, its work done. Never returns.
int64_t avra_cores_heir_gone(void) { exit(0); }

// A forked process's own words, written to `path` in place of the stderr it shares with the process
// that forked it: 0, or -1 where the file would not open or take fd 2.
int64_t avra_cores_stderr_to(const char* path) {
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
    if (fd < 0) return -1;
    int moved = dup2(fd, 2);
    close(fd);
    return moved < 0 ? -1 : 0;
}

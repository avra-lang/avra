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
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <unistd.h>

#if defined(__linux__)
#include <sched.h>
#endif

#include "avra_cores.h"
#include "avra_fiber.h"
#include "avra_runtime.h"

// What a core tells the supervisor, in memory the whole group shares.
// Each core writes only its own slot.
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
    if (gr->slots) munmap(gr->slots, (size_t)gr->n * sizeof(Slot));
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
    void* slots = mmap(NULL, (size_t)n * sizeof(Slot), PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANON, -1, 0);
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

// The child's half of a fork: its scheduler keeps the calling task
// alone, and its descriptors are the standard three, the one it serves,
// the stop pipe's read end and its own pipe's write end.
static void became_core(Group* gr, int64_t i, int64_t serving) {
    avra_fiber_forked();
    int keep[] = { 0, 1, 2, (int)serving, gr->stop_read, gr->core[i].end_write };
    close_all_but(keep, 6);
}

// Forks the group: answers the core's index in each core, `n` in the
// supervisor, or -errno — the cores already forked told to stop and
// reaped. `serving` is the descriptor the cores keep.
int64_t avra_cores_fork(int64_t g, int64_t serving) {
    Group* gr = group_at(g);
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

// A core's end of the stop pipe, to park on.
int64_t avra_cores_stop_fd(int64_t g) { return group_at(g)->stop_read; }

// 1 when the group has been told to stop — or its supervisor is gone —
// else 0. A core parks on the stop pipe while this answers 0.
int64_t avra_cores_stopped(int64_t g) {
    char b;
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
    ssize_t got = read(gr->core[core].end_read, b, sizeof b);
    if (got != 0 && !(got < 0 && errno != EAGAIN && errno != EINTR)) return -EAGAIN;
    int status = 0;
    // the clock: not a wait on time — its end pipe has closed, the core has ended
    while (waitpid(gr->core[core].pid, &status, 0) < 0 && errno == EINTR) {}
    gr->core[core].status = status;
    gr->core[core].ended = 1;
    avra_fiber_fd_closing(gr->core[core].end_read);
    close(gr->core[core].end_read);
    gr->core[core].end_read = -1;
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

/* @std/process's OWN C. Every entry point answers an int: a token, a
   count, a handle, a descriptor, a tagged status, or a NEGATIVE
   errno. No text and no bytes cross here — a child's output rides the
   runtime's descriptor rows, which are the only door that mints a
   managed box (docs/2026_09_07_PACKAGE_C_STANDARD.md §2.5).  */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>
#include <stdio.h>

/* ── The stage ────────────────────────────────────────────────────
   THE WORDS FOR THE NEXT SPAWN, LANDED ONE AT A TIME. A spawn used to
   take `List<string>` argv and envp, which works only while it is a
   runtime ROW: the evaluator holds a list as a HANDLE into its own
   table, never as a box, so a package's extern could not be handed
   one and `corpus/process` would have lost its second engine. Landing
   the words is this tree's land-then-act idiom a fourth time — after
   the descriptor scratch, the io listing and the extern frame's own
   slots.

   TWO PROPERTIES ARE STRUCTURAL HERE, NOT CHECKED, because a stage
   that can be written wrong will be:

   SPARSE IS UNSPELLABLE. There is no index in this API. `word`
   APPENDS and answers the new count, so there is no way to write the
   third word without having written the second — an index-keyed
   `word(i, text)` could be called with 0 and 2 and leave a hole that
   reads as an empty argument.

   STALE IS REFUSED. Every stage carries a GENERATION, and a token
   from an abandoned one is refused by every verb that takes it. A
   caller who stages words and then fails before spawning cannot have
   those words picked up by the next spawn — which is the failure a
   plain "clear on spawn" leaves open, since the abandoned stage is
   never reached by a spawn at all.

   THE EMPTY CASE IS THE FIRST CASE: a stage opened and spawned with
   NO words and NO variables is a child run with argv holding only its
   own name, which is a legitimate spawn and not an error.  */

enum { PROC_WORDS = 4096, PROC_STAGE_BYTES = 1 << 20 };

static char* g_words[PROC_WORDS];
static char* g_vars[PROC_WORDS];
static int64_t g_nwords, g_nvars, g_stage_bytes;

/* 0 means NO STAGE IS OPEN. It only ever rises, so a token from an
   abandoned or spent stage can never name a later one. */
static int64_t g_stage_gen;

static void stage_freed(void) {
    for (int64_t i = 0; i < g_nwords; i++) free(g_words[i]);
    for (int64_t i = 0; i < g_nvars; i++) free(g_vars[i]);
    g_nwords = 0;
    g_nvars = 0;
    g_stage_bytes = 0;
}

/* A stage opened, and any stage still standing abandoned with it — a
   caller who failed between staging and spawning leaves nothing the
   next caller can spend. Answers the token every other verb carries. */
int64_t avra_proc_stage(void) {
    stage_freed();
    return ++g_stage_gen;
}

/* The stage let go without spawning. Idempotent: a token that is
   already spent names no stage and there is nothing to abandon. */
int64_t avra_proc_unstage(int64_t token) {
    if (token != g_stage_gen || g_stage_gen == 0) return 0;
    stage_freed();
    g_stage_gen++;
    return 0;
}

static int64_t staged(int64_t token, char** into, int64_t* n, const char* text) {
    if (token != g_stage_gen || g_stage_gen == 0) return -EINVAL;
    if (*n >= PROC_WORDS) return -E2BIG;
    size_t len = strlen(text);
    if (g_stage_bytes + (int64_t)len + 1 > PROC_STAGE_BYTES) return -E2BIG;
    char* copy = (char*)malloc(len + 1);
    if (!copy) return -ENOMEM;
    memcpy(copy, text, len + 1);
    into[*n] = copy;
    g_stage_bytes += (int64_t)len + 1;
    return ++(*n);
}

/* One argument appended; the new count, or -EINVAL for a token that
   names no open stage. */
int64_t avra_proc_word(int64_t token, const char* text) {
    return staged(token, g_words, &g_nwords, text);
}

/* One `NAME=VALUE` appended. An entry with no `=` names nothing the
   host can set, and neither does one whose NAME is empty — `=V` and
   `=` alone both have their separator and no name at all. Refused
   HERE rather than at the spawn, so the caller learns which entry was
   wrong while it still knows which one it was.

   The package's Avra face refuses an empty name too, and that is the
   door a program meets. This is not the same check twice: the C is a
   public seam its own corpus calls directly, so it owes the refusal
   on its own account. */
int64_t avra_proc_var(int64_t token, const char* text) {
    if (text[0] == '=' || !strchr(text, '=')) return -EINVAL;
    return staged(token, g_vars, &g_nvars, text);
}

/* What the stage holds — the words, or the variables when `which` is
   1. For a caller that wants to check its own staging. */
int64_t avra_proc_staged(int64_t token, int64_t which) {
    if (token != g_stage_gen || g_stage_gen == 0) return -EINVAL;
    return which == 1 ? g_nvars : g_nwords;
}

/* ── Standing facts ───────────────────────────────────────────────*/

/* Whether the path names a file this process may execute: 0 yes,
   -errno otherwise. The `which` search is the LANGUAGE's to walk —
   this answers the one question C can answer and no more, the same
   split as @std/io's environment predicate. */
int64_t avra_proc_executable(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return -errno;
    if (!S_ISREG(st.st_mode)) return -EACCES;
    return access(path, X_OK) == 0 ? 0 : -errno;
}

/* ── The children ─────────────────────────────────────────────────
   A HANDLE IS A GENERATION OVER AN INDEX, so a closed slot's handle
   never names the slot's next tenant.

   WHAT IS NOT HERE IS THE POINT: no growth buffers, no pending stdin,
   no pump. A child's streams are DESCRIPTORS and the language reads
   and writes them through the runtime's descriptor rows — the only
   door that mints a managed box. This C opens, signals, reaps and
   reports readiness; what flows is not its business.  */

#include <fcntl.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <signal.h>
#include <spawn.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <time.h>

/* A child's cwd bound through a file action: POSIX-2024's name where
   the SDK has it (macOS 26), the `_np` spelling before (Darwin 10.15,
   glibc 2.29); elsewhere a cwd is refused as unsupported. */
#if defined(__APPLE__)
#include <Availability.h>
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir
#else
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir_np
#endif
#elif defined(__GLIBC__)
#if __GLIBC_PREREQ(2, 29)
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir_np
#endif
#endif

extern char** environ;

// The runtime's: a blocking call here holds the world, so a virtual
// clock flows at wall rate across it.
void avra_clock_hold(int64_t by);

enum {
    PROC_PIPE_IN = 0x1, PROC_PIPE_OUT = 0x2, PROC_PIPE_ERR = 0x4, PROC_MERGE_ERR = 0x8,
    PROC_NULL_IN = 0x10, PROC_NULL_OUT = 0x20, PROC_NULL_ERR = 0x40,
    PROC_INHERIT_IN = 0x80, PROC_INHERIT_OUT = 0x100, PROC_INHERIT_ERR = 0x200,
    PROC_NEW_PGROUP = 0x400, PROC_NEW_SESSION = 0x800, PROC_INHERIT_ENV = 0x2000
};

/* A status is a TAGGED word — never a small code, so an exit of 0 and
   a signal of 0 can never read alike. */
enum { EXIT_CODE = 1, EXIT_SIGNAL = 2 };

/* What `ready` reports. Bits, because more than one can be true. */
enum { READY_OUT = 1, READY_ERR = 2, READY_IN = 4, READY_GONE = 8 };

typedef struct {
    int live;
    int64_t gen;
    pid_t pid;
    int pgid;
    int group;
    int group_gone;         /* the group has been observed EMPTY once */
    int in_fd, out_fd, err_fd;
    int in_gone, out_gone, err_gone; /* observed HUP/ERR with nothing left to drain */
    int64_t status;         /* the tagged word; 0 while running */
} Proc;

static Proc* g_procs = NULL;
static int64_t g_nprocs = 0;

static Proc* proc_at(int64_t h) {
    if (h < 0) return NULL;
    int64_t idx = h & 0xffffffffLL, gen = h >> 32;
    if (idx >= g_nprocs || !g_procs[idx].live || g_procs[idx].gen != gen) return NULL;
    return &g_procs[idx];
}

static int64_t proc_slot(void) {
    for (int64_t i = 0; i < g_nprocs; i++) if (!g_procs[i].live) return i;
    int64_t n = g_nprocs ? g_nprocs * 2 : 16;
    g_procs = (Proc*)realloc(g_procs, (size_t)n * sizeof(Proc));
    for (int64_t i = g_nprocs; i < n; i++) { memset(&g_procs[i], 0, sizeof(Proc)); g_procs[i].gen = 1; }
    int64_t at = g_nprocs;
    g_nprocs = n;
    return at;
}

static void close_fd(int* fd) {
    if (*fd >= 0) close(*fd);
    *fd = -1;
}

/* A pipe's ends kept clear of 0, 1 and 2, so a child's dup2 can never
   land on an end we still hold. */
static int raised(int fd) {
    while (fd >= 0 && fd <= 2) {
        int d = fcntl(fd, F_DUPFD_CLOEXEC, 3);
        close(fd);
        fd = d;
    }
    if (fd >= 0) fcntl(fd, F_SETFD, FD_CLOEXEC);
    return fd;
}

static int make_pipe(int p[2]) {
    if (pipe(p) != 0) return -errno;
    p[0] = raised(p[0]);
    p[1] = raised(p[1]);
    return (p[0] < 0 || p[1] < 0) ? -EMFILE : 0;
}

/* Exactly one of a group of flags, so a caller cannot ask for a pipe
   AND /dev/null on the same stream and get whichever the code tests
   first. */
static int one_of(int64_t flags, int64_t a, int64_t b, int64_t c, int64_t d) {
    return !!(flags & a) + !!(flags & b) + !!(flags & c) + !!(flags & d) == 1;
}

/* The staged words as C's argv: the file's own name first, then what
   was landed, NULL-terminated. The caller frees. */
static char** argv_of(const char* file) {
    char** out = (char**)malloc((size_t)(g_nwords + 2) * sizeof(char*));
    if (!out) return NULL;
    out[0] = (char*)file;
    for (int64_t i = 0; i < g_nwords; i++) out[i + 1] = g_words[i];
    out[g_nwords + 1] = NULL;
    return out;
}

/* The length of an entry's NAME: up to its `=`, or the whole entry. */
static size_t name_len(const char* entry) {
    const char* eq = strchr(entry, '=');
    return eq ? (size_t)(eq - entry) : strlen(entry);
}

/* Whether a staged variable carries the entry's name. */
static int restaged(const char* entry) {
    size_t n = name_len(entry);
    for (int64_t i = 0; i < g_nvars; i++)
        if (name_len(g_vars[i]) == n && memcmp(g_vars[i], entry, n) == 0) return 1;
    return 0;
}

/* The staged variables as C's envp, laid over `base` when there is one:
   a base entry whose name a staged variable carries gives way, so each
   name appears once. The caller frees. */
static char** envp_of(char** base) {
    int64_t nbase = 0;
    while (base && base[nbase]) nbase++;
    char** out = (char**)malloc((size_t)(nbase + g_nvars + 1) * sizeof(char*));
    if (!out) return NULL;
    int64_t k = 0;
    for (int64_t i = 0; i < nbase; i++)
        if (!restaged(base[i])) out[k++] = base[i];
    for (int64_t i = 0; i < g_nvars; i++) out[k++] = g_vars[i];
    out[k] = NULL;
    return out;
}

/* A child up, or -errno. The path is ALREADY RESOLVED — the PATH
   search is the language's walk over `executable`, so nothing here
   guesses which program a bare name meant.

   THE STAGE IS SPENT WHETHER OR NOT THE SPAWN SUCCEEDS, which is what
   makes a failed spawn's words unable to reach the next one. */
int64_t avra_proc_spawn(int64_t token, const char* file, const char* cwd, int64_t flags, int64_t from_h) {
    if (token != g_stage_gen || g_stage_gen == 0) return -EINVAL;
    Proc* from = from_h >= 0 ? proc_at(from_h) : NULL;
    if (from_h >= 0 && (!from || from->out_fd < 0)) { avra_proc_unstage(token); return -EBADF; }
    if (from) flags = (flags & ~(int64_t)(PROC_NULL_IN | PROC_INHERIT_IN)) | PROC_PIPE_IN;

    int64_t rc = 0;
    if (!one_of(flags, PROC_PIPE_IN, PROC_NULL_IN, PROC_INHERIT_IN, 0)) rc = -EINVAL;
    else if (!one_of(flags, PROC_PIPE_OUT, PROC_NULL_OUT, PROC_INHERIT_OUT, 0)) rc = -EINVAL;
    else if (!one_of(flags, PROC_PIPE_ERR, PROC_NULL_ERR, PROC_INHERIT_ERR, PROC_MERGE_ERR)) rc = -EINVAL;
    else if ((flags & PROC_MERGE_ERR) && !(flags & PROC_PIPE_OUT)) rc = -EINVAL;
    if (rc == 0 && cwd && cwd[0]) {
        struct stat st;
        if (stat(cwd, &st) != 0 || !S_ISDIR(st.st_mode)) rc = -ENOTDIR;
    }
    if (rc != 0) { avra_proc_unstage(token); return rc; }

    int in[2] = { -1, -1 }, out[2] = { -1, -1 }, err[2] = { -1, -1 };
    if (from) {
        /* the upstream's read end was ours to poll — non-blocking; the
           child that inherits it reads as a child does */
        in[0] = from->out_fd;
        fcntl(in[0], F_SETFL, 0);
    } else if ((flags & PROC_PIPE_IN) && (rc = make_pipe(in)) != 0) goto fail;
    if ((flags & PROC_PIPE_OUT) && (rc = make_pipe(out)) != 0) goto fail;
    if ((flags & PROC_PIPE_ERR) && (rc = make_pipe(err)) != 0) goto fail;

    posix_spawn_file_actions_t fa;
    posix_spawn_file_actions_init(&fa);
    if (flags & PROC_PIPE_IN) posix_spawn_file_actions_adddup2(&fa, in[0], 0);
    if (flags & PROC_NULL_IN) posix_spawn_file_actions_addopen(&fa, 0, "/dev/null", O_RDONLY, 0);
    if (flags & PROC_PIPE_OUT) posix_spawn_file_actions_adddup2(&fa, out[1], 1);
    if (flags & PROC_NULL_OUT) posix_spawn_file_actions_addopen(&fa, 1, "/dev/null", O_WRONLY, 0);
    if (flags & PROC_PIPE_ERR) posix_spawn_file_actions_adddup2(&fa, err[1], 2);
    if (flags & PROC_MERGE_ERR) posix_spawn_file_actions_adddup2(&fa, out[1], 2);
    if (flags & PROC_NULL_ERR) posix_spawn_file_actions_addopen(&fa, 2, "/dev/null", O_WRONLY, 0);
#ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
    /* Darwin closes every fd the actions do not name — so the three a
       child inherits are named. */
    if (flags & PROC_INHERIT_IN) posix_spawn_file_actions_addinherit_np(&fa, 0);
    if (flags & PROC_INHERIT_OUT) posix_spawn_file_actions_addinherit_np(&fa, 1);
    if (flags & PROC_INHERIT_ERR) posix_spawn_file_actions_addinherit_np(&fa, 2);
#endif
    if (cwd && cwd[0]) {
#ifdef AVRA_ADDCHDIR
        AVRA_ADDCHDIR(&fa, cwd);
#else
        posix_spawn_file_actions_destroy(&fa);
        rc = -ENOTSUP;
        goto fail;
#endif
    }
    posix_spawnattr_t at;
    posix_spawnattr_init(&at);
    short af = POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF;
    sigset_t none, all;
    sigemptyset(&none);
    sigfillset(&all);
    sigdelset(&all, SIGKILL);
    sigdelset(&all, SIGSTOP);
    posix_spawnattr_setsigmask(&at, &none);
    posix_spawnattr_setsigdefault(&at, &all);
    if (flags & PROC_NEW_PGROUP) { af |= POSIX_SPAWN_SETPGROUP; posix_spawnattr_setpgroup(&at, 0); }
#ifdef POSIX_SPAWN_SETSID
    if (flags & PROC_NEW_SESSION) af |= POSIX_SPAWN_SETSID;
#endif
#ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
    af |= POSIX_SPAWN_CLOEXEC_DEFAULT;
#endif
    posix_spawnattr_setflags(&at, af);

    char** cargv = argv_of(file);
    char** cenvp = envp_of((flags & PROC_INHERIT_ENV) ? environ : NULL);
    /* what this program printed comes out before the child's words */
    fflush(NULL);
    pid_t pid = -1;
    int started = (cargv && cenvp) ? posix_spawn(&pid, file, &fa, &at, cargv, cenvp) : ENOMEM;
    posix_spawn_file_actions_destroy(&fa);
    posix_spawnattr_destroy(&at);
    free(cargv);
    free(cenvp);
    avra_proc_unstage(token);
    /* the upstream's read end is the child's now; we stop reading it */
    if (from) { in[0] = -1; close_fd(&from->out_fd); }
    close_fd(&in[0]);
    close_fd(&out[1]);
    close_fd(&err[1]);
    if (started != 0) { rc = -started; goto fail; }
    if (in[1] >= 0) fcntl(in[1], F_SETFL, O_NONBLOCK);
    if (out[0] >= 0) fcntl(out[0], F_SETFL, O_NONBLOCK);
    if (err[0] >= 0) fcntl(err[0], F_SETFL, O_NONBLOCK);

    int64_t idx = proc_slot();
    Proc* p = &g_procs[idx];
    int64_t gen = p->gen;
    memset(p, 0, sizeof(Proc));
    p->gen = gen;
    p->live = 1;
    p->pid = pid;
    p->pgid = pid;
    p->group = (flags & (PROC_NEW_PGROUP | PROC_NEW_SESSION)) != 0;
    p->in_fd = in[1];
    p->out_fd = out[0];
    p->err_fd = err[0];
    return (gen << 32) | idx;

fail:
    avra_proc_unstage(token);
    if (from) in[0] = -1;
    close_fd(&in[0]); close_fd(&in[1]);
    close_fd(&out[0]); close_fd(&out[1]);
    close_fd(&err[0]); close_fd(&err[1]);
    return rc;
}

/* One of the child's streams as a DESCRIPTOR — 0 its stdin, 1 its
   stdout, 2 its stderr — for the runtime's read and write rows. A
   stream that was never a pipe, or whose end we have already let go,
   is -EBADF: absence is a refusal here and not a sentinel the caller
   might read as a descriptor. */
int64_t avra_proc_fd(int64_t h, int64_t stream) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    int fd = stream == 0 ? p->in_fd : stream == 1 ? p->out_fd : stream == 2 ? p->err_fd : -1;
    return fd >= 0 ? fd : -EBADF;
}

/* Our end of one stream let go. Closing the child's stdin is how it
   learns there is no more input; closing a read end stops us reading
   what we no longer want. Idempotent — a stream already let go is 0,
   because a caller unwinding should not have to remember. */
int64_t avra_proc_shut(int64_t h, int64_t stream) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    if (stream == 0) close_fd(&p->in_fd);
    else if (stream == 1) close_fd(&p->out_fd);
    else if (stream == 2) close_fd(&p->err_fd);
    else return -EINVAL;
    return 0;
}

/* WHAT IS READY, waiting at most timeout_ms — a negative waits until
   something is. The answer is BITS, because more than one can be
   true at once, and 0 means the wait expired with nothing ready.

   THE CHILD'S EXIT IS A BIT LIKE ANY OTHER (READY_GONE), so a pump
   never has to reap to find out whether to keep going. An interrupted
   wait answers 0 rather than an error: the caller's own deadline is
   the authority on whether to wait again. */
/* THIS PROCESS'S CONSUMED CPU, in milliseconds — user plus system, the
   whole tree of it. A WAIT AND A SPIN TAKE THE SAME WALL TIME, so only
   this tells them apart: the pump's own suite asserts that a grace
   window costs elapsed time and almost no CPU. Nothing in the language
   needs it; the row exists so the law is testable. */
int64_t avra_proc_cpu_ms(void) {
    struct rusage self, kids;
    if (getrusage(RUSAGE_SELF, &self) != 0 || getrusage(RUSAGE_CHILDREN, &kids) != 0) return -1;
    int64_t ms = 0;
    ms += (int64_t)self.ru_utime.tv_sec * 1000 + self.ru_utime.tv_usec / 1000;
    ms += (int64_t)self.ru_stime.tv_sec * 1000 + self.ru_stime.tv_usec / 1000;
    return ms;
}

/* A READ END REPORTING HUP WITH NOTHING LEFT TO READ IS DONE FOREVER —
   POLLHUP is sticky, so leaving it in the poll set makes every later
   call answer at once regardless of its timeout, the SAME spin the
   grace law below already names for an empty set. A read end still
   carrying data is not done: the caller has not drained it yet, and
   excluding it here would lose that data's readiness.
   WHETHER DATA REMAINS IS NOT POLLIN'S TO ANSWER: Linux sets POLLHUP
   alone once a pipe is truly empty, but Darwin sets POLLIN alongside
   POLLHUP the whole time the peer is gone, empty or not — measured
   here, both engines, the same source. `FIONREAD` asks the byte count
   directly, without consuming it, and agrees with itself on both. A
   write end has no such middle case — POLLERR or POLLHUP on it means
   the reader is gone and no later write will ever succeed, so it
   retires the moment either appears. */
static int read_end_gone(int fd, short revents) {
    if (!(revents & POLLHUP)) return 0;
    int avail = 0;
    if (ioctl(fd, FIONREAD, &avail) != 0) return 1;
    return avail == 0;
}
static int write_end_gone(short revents) { return (revents & (POLLERR | POLLHUP)) != 0; }

int64_t avra_proc_ready(int64_t h, int64_t timeout_ms) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    struct pollfd fds[3];
    int n = 0, slot_out = -1, slot_err = -1, slot_in = -1;
    if (p->out_fd >= 0 && !p->out_gone) { fds[n].fd = p->out_fd; fds[n].events = POLLIN; slot_out = n++; }
    if (p->err_fd >= 0 && !p->err_gone) { fds[n].fd = p->err_fd; fds[n].events = POLLIN; slot_err = n++; }
    if (p->in_fd >= 0 && !p->in_gone) { fds[n].fd = p->in_fd; fds[n].events = POLLOUT; slot_in = n++; }
    int64_t ev = 0;
    if (n > 0) {
        avra_clock_hold(1);
        int r = poll(fds, (nfds_t)n, timeout_ms < 0 ? -1 : (int)timeout_ms);
        avra_clock_hold(-1);
        if (r < 0 && errno != EINTR) return -errno;
        if (r > 0) {
            if (slot_out >= 0 && fds[slot_out].revents) {
                ev |= READY_OUT;
                if (read_end_gone(p->out_fd, fds[slot_out].revents)) p->out_gone = 1;
            }
            if (slot_err >= 0 && fds[slot_err].revents) {
                ev |= READY_ERR;
                if (read_end_gone(p->err_fd, fds[slot_err].revents)) p->err_gone = 1;
            }
            if (slot_in >= 0 && (fds[slot_in].revents & (POLLOUT | POLLERR | POLLHUP))) {
                ev |= READY_IN;
                if (write_end_gone(fds[slot_in].revents)) p->in_gone = 1;
            }
        }
    } else if (timeout_ms > 0) {
        /* NOTHING TO WATCH IS STILL A WAIT. A caller that asks for
           `timeout_ms` gets it whether or not the child is alive:
           polling no descriptors returns at once, so a driver that
           waits a grace OUT (`grace`, after the child is reaped and
           both pipes are closed) turned this row into a spin — a core
           burned for the whole grace, two seconds per command by
           default. The row answers "nothing became ready", after the
           wait it was asked for. A stream retired above for being
           permanently done reaches this same branch once every
           watched descriptor is exhausted, without a second mechanism. */
        struct timespec ts = { timeout_ms / 1000, (timeout_ms % 1000) * 1000000L };
        avra_clock_hold(1);
        nanosleep(&ts, NULL);
        avra_clock_hold(-1);
    }
    if (p->pid < 0) ev |= READY_GONE;
    return ev;
}

/* The child reaped if it has ended, without waiting: 0 while it runs,
   else its TAGGED status — the tag says whether the payload is an exit
   code or a signal, so an exit of 0 and a signal of 0 never read
   alike. Reaped once; the status stands for every later ask. */
int64_t avra_proc_reap(int64_t h) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    if (p->pid < 0) return p->status;
    int st = 0;
    pid_t r;
    // the clock: not a wait on time — WNOHANG answers at once
    while ((r = waitpid(p->pid, &st, WNOHANG)) < 0 && errno == EINTR) {}
    if (r == 0) return 0;
    if (r < 0) return -errno;
    p->pid = -1;
    if (WIFEXITED(st)) p->status = ((int64_t)EXIT_CODE << 32) | (int64_t)WEXITSTATUS(st);
    else {
        int64_t payload = WTERMSIG(st);
#ifdef WCOREDUMP
        if (WCOREDUMP(st)) payload |= 0x100;
#endif
        p->status = ((int64_t)EXIT_SIGNAL << 32) | payload;
    }
    return p->status;
}

/* A signal to the child, or to its whole group when it leads one and
   the caller asks — a tree is what a shell leaves behind, and killing
   only the leader leaves the grandchildren running. A child already
   reaped is 0, not an error: signalling the dead is a no-op the
   caller should not have to guard. */
int64_t avra_proc_signal(int64_t h, int64_t sig, int64_t to_group) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    /* A GROUP OUTLIVES ITS LEADER. The child may already be reaped
       while a grandchild it left behind still holds the group — and
       that grandchild is exactly who a caller signalling the TREE
       means to reach. Testing the child's own life first would make
       the signal a no-op precisely when it matters.

       AND THE SAME REASONING BOUNDS IT. A group is safe to signal
       only while some member exists; once it is genuinely EMPTY the
       OS may recycle the pgid, and a late signal lands on an
       UNRELATED group. The pgid is a raw OS number and no generation
       of ours can guard it — so the slot records the first emptiness
       it ever observes, and from then on the syscall is not made at
       all. That bounds the stale window to "never yet observed
       empty", which is as tight as this gets without the kernel's
       help. `avra_proc_close` fences a closed handle; this is the
       one still open. */
    if (to_group && p->group && p->pgid > 0) {
        if (p->group_gone) return -ESRCH;
        if (kill(-p->pgid, (int)sig) == 0) return 0;
        if (errno != ESRCH) return -errno;
        p->group_gone = 1;
        return -ESRCH;
    }
    if (p->pid < 0) return 0;
    int rc = kill(p->pid, (int)sig);
    return rc == 0 || errno == ESRCH ? 0 : -errno;
}

int64_t avra_proc_pid(int64_t h) {
    Proc* p = proc_at(h);
    return p ? (p->pid < 0 ? -ESRCH : p->pid) : -EBADF;
}

/* The handle let go: every end closed, and the child reaped if it has
   ended. A child still running is NOT waited for here — the caller
   decides whether to stop it; this only stops us holding its ends. */
int64_t avra_proc_close(int64_t h) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    close_fd(&p->in_fd);
    close_fd(&p->out_fd);
    close_fd(&p->err_fd);
    if (p->pid >= 0) {
        int st = 0;
        // the clock: not a wait on time — WNOHANG answers at once
        if (waitpid(p->pid, &st, WNOHANG) > 0) p->pid = -1;
    }
    p->live = 0;
    p->gen++;
    return 0;
}

/* A PROCESS NAMED BY ITS NUMBER, signalled — one this process did not
   start, and never a general kill: the signal is named by its place in
   @std/process's closed `Signal`, since the numbers differ by system —
   0 urgent (SIGURG, ignored unless asked for). A number of 0 or below
   names a group and is refused, and so is one past what a process
   number holds: `kill` takes 32 bits, so 2^32 would arrive as 0 (this
   process's group) and 2^32 - 1 as -1 (every process the user may
   signal) — -ERANGE, before anything is sent. This process's own number
   answers -1000, as @std/process names it. 0, or -errno: ESRCH no such
   process, EPERM not this user's. */
int64_t avra_proc_signal_pid(int64_t pid, int64_t which) {
    static const int signals[] = { SIGURG };
    if ((int64_t)(pid_t)pid != pid) return -ERANGE;
    if (pid <= 0 || which < 0 || which >= (int64_t)(sizeof signals / sizeof signals[0])) return -EINVAL;
    if ((pid_t)pid == getpid()) return -1000;
    return kill((pid_t)pid, signals[which]) == 0 ? 0 : -errno;
}

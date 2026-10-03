/* @std/io's OWN C — opening, standing, making, removing, and the two
   halves of a durable write. Every entry point answers an int: a
   status, a descriptor, a handle, a kind, or a NEGATIVE errno. No
   text and no bytes cross here; a file's contents ride the runtime's
   descriptor rows, which are the only door that mints a managed box
   (docs/2026_09_07_PACKAGE_C_STANDARD.md §2.5).  */

#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* What stands at the path: 0 nothing, 1 a file, 2 a directory, 3
   something else; -errno when the host will not say. */
int64_t avra_io_kind(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return errno == ENOENT ? 0 : -errno;
    if (S_ISREG(st.st_mode)) return 1;
    if (S_ISDIR(st.st_mode)) return 2;
    return 3;
}

/* A file's STAMP: its size, its two times and its inode folded to one
   positive number — what says "these are the bytes you read before"
   without reading them. 0 when there is no telling: the path is no
   file, or it moved within the last two seconds, where two writes can
   wear one time. */
int64_t avra_io_stamp(const char* path) {
    struct stat st;
    struct timespec now;
    if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) return 0;
#ifdef __APPLE__
    struct timespec m = st.st_mtimespec, c = st.st_ctimespec;
#else
    struct timespec m = st.st_mtim, c = st.st_ctim;
#endif
    clock_gettime(CLOCK_REALTIME, &now);
    if (now.tv_sec - m.tv_sec < 2 || now.tv_sec - c.tv_sec < 2) return 0;
    uint64_t h = 0x9E3779B97F4A7C15ull;
    uint64_t parts[6] = { (uint64_t)st.st_size, (uint64_t)m.tv_sec, (uint64_t)m.tv_nsec,
                          (uint64_t)c.tv_sec, (uint64_t)c.tv_nsec, (uint64_t)st.st_ino };
    for (int i = 0; i < 6; i++) { h ^= parts[i]; h *= 0x100000001B3ull; h ^= h >> 29; }
    h &= 0x7FFFFFFFFFFFFFFFull;
    return h == 0 ? 1 : (int64_t)h;
}

/* A read descriptor for the path, or -errno. A DIRECTORY is refused
   here rather than at the first read: `open` on one succeeds and
   `read` answers EISDIR only on some hosts, so the door says it. */
int64_t avra_io_open(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return -errno;
    if (S_ISDIR(st.st_mode)) return -EISDIR;
    int fd;
    while ((fd = open(path, O_RDONLY | O_CLOEXEC)) < 0 && errno == EINTR) {}
    return fd < 0 ? -errno : fd;
}

/* A descriptor closed. EINTR does NOT mean try again: on every host
   Avra targets the descriptor is already gone, and a retry would
   close whatever took its number. */
int64_t avra_io_close(int64_t fd) {
    return close((int)fd) == 0 || errno == EINTR ? 0 : -errno;
}

/* A write descriptor positioned at the file's current end, created if
   absent — every write through it lands AFTER whatever is already
   there, never over it. The append-only pack format's own primitive:
   a caller that wants a whole-file replace still goes through
   avra_io_temp's publish-or-remove door. */
int64_t avra_io_open_append(const char* path) {
    int fd;
    while ((fd = open(path, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0644)) < 0 && errno == EINTR) {}
    return fd < 0 ? -errno : fd;
}

/* The descriptor's writes durable on the device — a crash after this
   returns cannot lose bytes already written through it. */
int64_t avra_fd_sync(int64_t fd) {
    while (fsync((int)fd) != 0) { if (errno != EINTR) return -errno; }
    return 0;
}

/* The file cut back to exactly `len` bytes. A caller trims a TORN
   TAIL — bytes past the last frame it could verify, left by a writer
   that crashed mid-append — to this before appending past it, so a
   half-written frame never ends up sitting between two valid ones. */
int64_t avra_io_truncate(const char* path, int64_t len) {
    return truncate(path, (off_t)len) == 0 ? 0 : -errno;
}

/* Every directory along the path made; one already standing is fine,
   a FILE standing where a directory must is -ENOTDIR. */
int64_t avra_io_mkdir(const char* path) {
    size_t n = strlen(path);
    if (n == 0) return -ENOENT;
    if (n >= 4096) return -ENAMETOOLONG;
    char buf[4096];
    memcpy(buf, path, n + 1);
    for (size_t i = 1; i <= n; i++) {
        if (buf[i] != '/' && buf[i] != '\0') continue;
        char saved = buf[i];
        buf[i] = '\0';
        if (mkdir(buf, 0755) != 0) {
            if (errno != EEXIST) return -errno;
            struct stat st;
            if (stat(buf, &st) != 0) return -errno;
            if (!S_ISDIR(st.st_mode)) return -ENOTDIR;
        }
        buf[i] = saved;
    }
    return 0;
}

/* A file, or an empty directory, gone. */
int64_t avra_io_remove(const char* path) {
    return remove(path) == 0 ? 0 : -errno;
}

/* ── The durable write ────────────────────────────────────────────
   A reader sees the old file or the new and never half of one, so the
   bytes go to a TEMP beside the target and the rename is LAST.

   THE HANDLE'S WHOLE POINT IS THAT DROPPING AN UNCOMMITTED TEMP
   REMOVES IT. That is what makes `defer drop(h)` correct on both
   paths, which is what a `?` inside the write loop needs: the
   deferred call runs before the early exit, and a deferred COMMIT
   there would publish a truncated file over the reader's data in code
   that reads as careful. Committing is the deliberate act; dropping
   is the default.  */

enum { IO_TEMPS = 64, IO_PATH = 4096 };

typedef struct {
    int fd;                 /* -1 when the slot is free */
    int committed;
    char temp[IO_PATH];
    char target[IO_PATH];
} IoTemp;

static IoTemp g_io_temps[IO_TEMPS];
static int g_io_temps_armed = 0;

static void temps_armed(void) {
    if (g_io_temps_armed) return;
    for (int i = 0; i < IO_TEMPS; i++) g_io_temps[i].fd = -1;
    g_io_temps_armed = 1;
}

static IoTemp* temp_at(int64_t h) {
    return h >= 0 && h < IO_TEMPS && g_io_temps[h].fd >= 0 ? &g_io_temps[h] : NULL;
}

/* A temp open beside the target, or -errno. The name carries the
   PROCESS's id, so two processes writing the same path do not share a
   temp and clobber each other's half-written bytes. O_EXCL then means
   a leftover from a crashed run of THIS pid is refused rather than
   silently reused. */
int64_t avra_io_temp(const char* path) {
    temps_armed();
    int64_t h = -1;
    for (int i = 0; i < IO_TEMPS && h < 0; i++) if (g_io_temps[i].fd < 0) h = i;
    if (h < 0) return -EMFILE;
    IoTemp* t = &g_io_temps[h];
    if (strlen(path) + 32 >= IO_PATH) return -ENAMETOOLONG;
    snprintf(t->temp, IO_PATH, "%s.avra-%ld.tmp", path, (long)getpid());
    snprintf(t->target, IO_PATH, "%s", path);
    int fd;
    while ((fd = open(t->temp, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644)) < 0 && errno == EINTR) {}
    if (fd < 0 && errno == EEXIST) {
        unlink(t->temp);
        while ((fd = open(t->temp, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644)) < 0 && errno == EINTR) {}
    }
    if (fd < 0) return -errno;
    t->fd = fd;
    t->committed = 0;
    return h;
}

/* The temp's descriptor, for the runtime's write row. */
int64_t avra_io_temp_fd(int64_t h) {
    IoTemp* t = temp_at(h);
    return t ? t->fd : -EBADF;
}

/* THE CLOSE'S ERROR REACHES THE STATUS, and it must: a write can be
   held in the kernel until close, so a full disk or a failing device
   is reported HERE and nowhere earlier. Only then the rename, which
   is the publish and is last. */
int64_t avra_io_commit(int64_t h) {
    IoTemp* t = temp_at(h);
    if (!t) return -EBADF;
    int64_t shut = close(t->fd) == 0 || errno == EINTR ? 0 : -errno;
    t->fd = -1;
    if (shut < 0) { unlink(t->temp); return shut; }
    if (rename(t->temp, t->target) != 0) { int e = errno; unlink(t->temp); return -e; }
    t->committed = 1;
    return 0;
}

/* The handle let go. An UNCOMMITTED temp is removed — nothing
   half-written is ever left beside the target — and a committed one
   is already gone from the table, so this answers 0. */
int64_t avra_io_drop(int64_t h) {
    if (h < 0 || h >= IO_TEMPS) return -EBADF;
    IoTemp* t = &g_io_temps[h];
    if (t->fd < 0 && t->committed) { t->committed = 0; return 0; }
    if (t->fd < 0) return 0;
    close(t->fd);
    t->fd = -1;
    unlink(t->temp);
    return 0;
}

/* ── The environment ──────────────────────────────────────────────
   WHETHER THE VARIABLE IS SET, and nothing else: 0 set, -1 not. The
   VALUE comes from the runtime's own environment row, which answers
   immortal text — so no text crosses here and this package needs no
   door into the runtime's scratch.

   THE PREDICATE EXISTS BECAUSE THE VALUE CANNOT CARRY IT. `getenv`
   answers NULL for unset and "" for set-to-empty, and the runtime's
   row hands both back as "" — so the value alone cannot tell them
   apart, and `env` must answer null for one and "" for the other. */
int64_t avra_io_env_set(const char* name) {
    return getenv(name) != NULL ? 0 : -1;
}

/* A read descriptor for `rel` BENEATH the directory `root`, or
   -errno. Each segment is opened relative to the one before with
   O_NOFOLLOW, so a symlink anywhere below the root refuses (ELOOP or
   ENOTDIR) rather than leading out of it, and `..`, `.` and an empty
   segment refuse as EACCES — the walk never names a parent. The last
   segment opens O_NONBLOCK so a FIFO standing there cannot block the
   caller; `avra_io_fd_kind` says what was opened. `rel` is `/`-split
   and never begins with one. */
int64_t avra_io_open_beneath(const char* root, const char* rel) {
    int dir;
    while ((dir = open(root, O_RDONLY | O_DIRECTORY | O_CLOEXEC)) < 0 && errno == EINTR) {}
    if (dir < 0) return -errno;
    const char* seg = rel;
    for (;;) {
        const char* end = strchr(seg, '/');
        size_t n = end ? (size_t)(end - seg) : strlen(seg);
        if (n == 0 || n >= 256 || (n == 1 && seg[0] == '.') || (n == 2 && seg[0] == '.' && seg[1] == '.')) {
            close(dir);
            return -EACCES;
        }
        char name[256];
        memcpy(name, seg, n);
        name[n] = '\0';
        int flags = O_RDONLY | O_NOFOLLOW | O_CLOEXEC | (end ? O_DIRECTORY : O_NONBLOCK);
        int fd;
        while ((fd = openat(dir, name, flags)) < 0 && errno == EINTR) {}
        int err = errno;
        close(dir);
        if (fd < 0) return -err;
        if (!end) return fd;
        dir = fd;
        seg = end + 1;
    }
}

/* What a descriptor holds: 1 a file, 2 a directory, 3 something
   else; -errno when the host will not say. */
int64_t avra_io_fd_kind(int64_t fd) {
    struct stat st;
    if (fstat((int)fd, &st) != 0) return -errno;
    if (S_ISREG(st.st_mode)) return 1;
    if (S_ISDIR(st.st_mode)) return 2;
    return 3;
}

/* A descriptor's size in octets, or -errno. */
int64_t avra_io_fd_size(int64_t fd) {
    struct stat st;
    if (fstat((int)fd, &st) != 0) return -errno;
    return (int64_t)st.st_size;
}

/* A descriptor's modification time, whole seconds since the epoch,
   or -errno. */
int64_t avra_io_fd_mtime(int64_t fd) {
    struct stat st;
    if (fstat((int)fd, &st) != 0) return -errno;
#ifdef __APPLE__
    return (int64_t)st.st_mtimespec.tv_sec;
#else
    return (int64_t)st.st_mtim.tv_sec;
#endif
}

/* The descriptor positioned at `at` from its start: `at`, or -errno. */
int64_t avra_io_seek(int64_t fd, int64_t at) {
    off_t o = lseek((int)fd, (off_t)at, SEEK_SET);
    return o < 0 ? -errno : (int64_t)o;
}
/* ── The compile slot ─────────────────────────────────────────────
   One of AVRA_MAX_COMPILES machine-wide slots (default 3; 0 = off),
   each a flock on <AVRA_SLOT_DIR, default /tmp/avra-slots>/<i>, held
   until the process ends.
   A process whose parent already holds one (AVRA_COMPILE_SLOT set, and
   inherited) takes none, so a compile's own children never wait on
   the slot their parent holds. Waits when every slot is taken, saying
   so once. Answers the slot taken, or -1 when none is taken. */
int64_t avra_io_compile_slot(void) {
#if defined(__wasm32__)
    // WASI has no flock and no machine-wide compile slots; only the compiler's
    // own tools take one, and a wasm program is never one of them.
    return -1;
#else
    const char* held = getenv("AVRA_COMPILE_SLOT");
    if (held && *held) return -1;
    const char* max = getenv("AVRA_MAX_COMPILES");
    long n = (max && *max) ? strtol(max, NULL, 10) : 3;
    if (n <= 0) return -1;
    const char* dir = getenv("AVRA_SLOT_DIR");
    if (!dir || !*dir) dir = "/tmp/avra-slots";
    mkdir(dir, 0777);
    int said = 0;
    for (;;) {
        for (long i = 0; i < n; i++) {
            char path[1024];
            snprintf(path, sizeof path, "%s/%ld", dir, i);
            int fd = open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0666);
            if (fd < 0) continue;
            if (flock(fd, LOCK_EX | LOCK_NB) == 0) {
                char slot[24];
                snprintf(slot, sizeof slot, "%ld", i);
                setenv("AVRA_COMPILE_SLOT", slot, 1);
                return (int64_t)i;
            }
            close(fd);
        }
        if (!said) {
            fprintf(stderr, "avra: waiting for a compile slot (AVRA_MAX_COMPILES=%ld)\n", n);
            said = 1;
        }
        usleep(200000);
    }
#endif
}

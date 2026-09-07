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
#include <stdio.h>
#include <stdlib.h>

/* What stands at the path: 0 nothing, 1 a file, 2 a directory, 3
   something else; -errno when the host will not say. */
int64_t avra_io_kind(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return errno == ENOENT ? 0 : -errno;
    if (S_ISREG(st.st_mode)) return 1;
    if (S_ISDIR(st.st_mode)) return 2;
    return 3;
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

/* @std/io's WATCH — a set of paths the host reports on, behind ONE
   descriptor that reads ready while anything is pending: an inotify
   descriptor on Linux, a kqueue of its own on Darwin. Every entry
   point answers an int: a handle, a slot, a count, a kind, or a
   NEGATIVE errno. No text crosses outward — a watched path is known
   to the caller by its SLOT.

   A PATH IS A NAME IN ITS PARENT DIRECTORY: each entry shares one OS
   watch on its parent, so a replacement by rename, a removal and a
   later arrival are all seen. A directory entry also holds the watch
   on itself, for its entries.

   AN EVENT ONLY MARKS AN ENTRY TOUCHED. `take` settles each touched
   entry against what stands now, so what is answered is the net
   difference since the last look, however many events made it. */

#include <stdint.h>
#include <string.h>
#include <errno.h>

#if defined(__wasm32__)

int64_t avra_io_watch_open(void) { return -ENOSYS; }
int64_t avra_io_watch_fd(int64_t h) { (void)h; return -ENOSYS; }
int64_t avra_io_watch_add(int64_t h, const char* path) { (void)h; (void)path; return -ENOSYS; }
int64_t avra_io_watch_drop(int64_t h, const char* path) { (void)h; (void)path; return -ENOSYS; }
int64_t avra_io_watch_mark(int64_t h) { (void)h; return -ENOSYS; }
int64_t avra_io_watch_sweep(int64_t h) { (void)h; return -ENOSYS; }
int64_t avra_io_watch_take(int64_t h) { (void)h; return -ENOSYS; }
int64_t avra_io_watch_lost(int64_t h) { (void)h; return -ENOSYS; }
int64_t avra_io_watch_slot(int64_t h, int64_t i) { (void)h; (void)i; return -ENOSYS; }
int64_t avra_io_watch_what(int64_t h, int64_t i) { (void)h; (void)i; return -ENOSYS; }
int64_t avra_io_watch_close(int64_t h) { (void)h; return -ENOSYS; }

#else

#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <sys/inotify.h>
#define WATCH_INOTIFY 1
#else
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <limits.h>
#define WATCH_INOTIFY 0
#endif

// The scheduler's word that a descriptor is closing: whoever is
// parked on it wakes to find it gone.
void avra_fiber_fd_closing(int64_t fd);

// What an entry was touched for since it was last settled.
enum { T_EXIST = 1, T_CONTENT = 2, T_ATTR = 4 };

// What a settled entry is answered as.
enum { W_NONE = 0, W_CREATED = 1, W_CHANGED = 2, W_REMOVED = 3, W_UNWATCHED = 4 };

// One OS watch on a directory, shared by every entry that names it.
// `os` is the inotify watch or the event descriptor; -1 once the
// directory itself went. A free record has no path.
typedef struct { char* path; int os; int refs; } Dir;

// One watched path. `parent` is the Dir it is a name in; `own` the Dir
// on itself while it stands as a directory; `fd` the event descriptor
// on its inode while it stands as a file (Darwin). A free record has
// no path.
typedef struct {
    char* path;
    const char* name;
    int parent, own, fd;
    uint32_t gen;
    uint8_t touched, stood, was_dir, what;
    int64_t size, mtime_ns;
} Entry;

// One watch. A free record has `fd` -1.
typedef struct {
    int fd;
    Dir* dirs; int ndirs;
    Entry* entries; int nentries;
    int* touched; int ntouched, touched_cap;
    int* changed; int nchanged, changed_cap;
    uint32_t gen;
    int lost;
} Watch;

static Watch* g_watches = NULL;
static int g_nwatches = 0;

static Watch* watch_of(int64_t h) {
    if (h < 0 || h >= g_nwatches || g_watches[h].fd < 0) return NULL;
    return &g_watches[h];
}

// `*list` with room for one more of `size` bytes each; 0 when the
// host has no memory to give.
static int grown(void** list, int* cap, int len, size_t size) {
    if (len < *cap) return 1;
    int want = *cap ? *cap * 2 : 16;
    void* p = realloc(*list, (size_t)want * size);
    if (!p) return 0;
    *list = p;
    *cap = want;
    return 1;
}

#if !WATCH_INOTIFY
// A WATCH HERE COSTS A DESCRIPTOR A PATH, and a process starts with a
// soft limit far under what the host allows it. Out of descriptors, the
// soft limit is raised to the hard one — the bound the user set — and
// whether it moved is the answer: a second refusal is the host's own.
static int more_descriptors(void) {
    struct rlimit lim;
    if (getrlimit(RLIMIT_NOFILE, &lim) != 0) return 0;
    rlim_t most = lim.rlim_max < OPEN_MAX ? lim.rlim_max : OPEN_MAX;
    if (lim.rlim_cur >= most) return 0;
    lim.rlim_cur = most;
    return setrlimit(RLIMIT_NOFILE, &lim) == 0;
}

// An event descriptor on what stands at `path`, or -errno.
static int event_fd(const char* path, int flags) {
    int fd = open(path, O_EVTONLY | O_CLOEXEC | flags);
    if (fd < 0 && (errno == EMFILE) && more_descriptors()) fd = open(path, O_EVTONLY | O_CLOEXEC | flags);
    return fd < 0 ? -errno : fd;
}
#endif

// ── A directory's OS watch ──────────────────────────────────────

// The OS watch on `path` opened: its number, or -errno.
static int os_dir_open(Watch* w, const char* path, int at) {
#if WATCH_INOTIFY
    (void)at;
    int wd = inotify_add_watch(w->fd, path,
        IN_ONLYDIR | IN_MODIFY | IN_CLOSE_WRITE | IN_CREATE | IN_DELETE |
        IN_MOVED_FROM | IN_MOVED_TO | IN_DELETE_SELF | IN_MOVE_SELF);
    return wd < 0 ? -errno : wd;
#else
    int fd = event_fd(path, O_DIRECTORY);
    if (fd < 0) return fd;
    struct kevent ev;
    EV_SET(&ev, fd, EVFILT_VNODE, EV_ADD | EV_CLEAR,
           NOTE_WRITE | NOTE_DELETE | NOTE_RENAME | NOTE_REVOKE, 0, (void*)(intptr_t)(at << 1));
    // the clock: not a wait on time — a change list, no event asked for
    if (kevent(w->fd, &ev, 1, NULL, 0, NULL) != 0) { int e = errno; close(fd); return -e; }
    return fd;
#endif
}

// A directory's OS watch given back. An inotify watch is one per
// inode, so it is removed only when no other record wears it.
static void os_dir_close(Watch* w, Dir* d) {
    if (d->os < 0) return;
#if WATCH_INOTIFY
    int shared = 0;
    for (int i = 0; i < w->ndirs; i++) {
        Dir* o = &w->dirs[i];
        if (o != d && o->path && o->os == d->os) shared = 1;
    }
    if (!shared) inotify_rm_watch(w->fd, d->os);
#else
    (void)w;
    close(d->os);
#endif
    d->os = -1;
}

// The record watching the directory at `path`, one share taken: its
// index, or -errno.
static int dir_acquire(Watch* w, const char* path) {
    int spare = -1;
    for (int i = 0; i < w->ndirs; i++) {
        Dir* d = &w->dirs[i];
        if (!d->path) { if (spare < 0) spare = i; continue; }
        if (d->os >= 0 && strcmp(d->path, path) == 0) { d->refs++; return i; }
    }
    if (spare < 0) {
        Dir* grown_dirs = realloc(w->dirs, (size_t)(w->ndirs + 1) * sizeof(Dir));
        if (!grown_dirs) return -ENOMEM;
        w->dirs = grown_dirs;
        spare = w->ndirs++;
        w->dirs[spare].path = NULL;
    }
    int os = os_dir_open(w, path, spare);
    if (os < 0) return os;
    char* kept = strdup(path);
    if (!kept) {
        Dir gone = { NULL, os, 0 };
        os_dir_close(w, &gone);
        return -ENOMEM;
    }
    w->dirs[spare] = (Dir){ kept, os, 1 };
    return spare;
}

static void dir_release(Watch* w, int at) {
    if (at < 0) return;
    Dir* d = &w->dirs[at];
    if (--d->refs > 0) return;
    os_dir_close(w, d);
    free(d->path);
    d->path = NULL;
}

// A directory that went is watched again where its path stands now;
// whether it is.
static int dir_revived(Watch* w, int at) {
    Dir* d = &w->dirs[at];
    if (d->os >= 0) return 1;
    int os = os_dir_open(w, d->path, at);
    if (os < 0) return 0;
    d->os = os;
    return 1;
}

// ── Entries ─────────────────────────────────────────────────────

static void touch(Watch* w, int at, int why) {
    Entry* e = &w->entries[at];
    if (!e->touched) {
        if (!grown((void**)&w->touched, &w->touched_cap, w->ntouched, sizeof(int))) { w->lost = 1; return; }
        w->touched[w->ntouched++] = at;
    }
    e->touched |= (uint8_t)why;
}

// The directory went: every name in it and the entry it is are in
// question, content included — what stands there next is another's.
static void dir_dead(Watch* w, int at) {
    w->dirs[at].os = -1;
    for (int i = 0; i < w->nentries; i++) {
        Entry* e = &w->entries[i];
        if (e->path && (e->parent == at || e->own == at)) touch(w, i, T_EXIST | T_CONTENT);
    }
}

static void file_close(Entry* e) {
    if (e->fd >= 0) close(e->fd);
    e->fd = -1;
}

static void entry_free(Watch* w, int at) {
    Entry* e = &w->entries[at];
    file_close(e);
    dir_release(w, e->own);
    dir_release(w, e->parent);
    free(e->path);
    e->path = NULL;
    e->touched = 0;
}

#if !WATCH_INOTIFY
// The event descriptor on the file standing at the entry's path, armed;
// 0 or -errno.
static int file_open(Watch* w, int at) {
    Entry* e = &w->entries[at];
    int fd = event_fd(e->path, 0);
    if (fd < 0) return fd;
    struct kevent ev;
    EV_SET(&ev, fd, EVFILT_VNODE, EV_ADD | EV_CLEAR,
           NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_DELETE | NOTE_RENAME | NOTE_REVOKE,
           0, (void*)(intptr_t)((at << 1) | 1));
    // the clock: not a wait on time — a change list, no event asked for
    if (kevent(w->fd, &ev, 1, NULL, 0, NULL) != 0) { int err = errno; close(fd); return -err; }
    e->fd = fd;
    return 0;
}
#endif

static int64_t mtime_ns_of(const struct stat* st) {
#ifdef __APPLE__
    return (int64_t)st->st_mtimespec.tv_sec * 1000000000 + st->st_mtimespec.tv_nsec;
#else
    return (int64_t)st->st_mtim.tv_sec * 1000000000 + st->st_mtim.tv_nsec;
#endif
}

// What stands at the entry's path is what it watches: the directory's
// own watch while it is a directory, the file's descriptor while it is
// a file (re-opened when another inode took the name). Answers whether
// what is watched was REPLACED, or -errno when the host gave no watch.
static int entry_aimed(Watch* w, int at, int stands, const struct stat* st) {
    Entry* e = &w->entries[at];
    int replaced = 0;
    int is_dir = stands && S_ISDIR(st->st_mode);
    if (is_dir) {
        if (e->own >= 0 && !dir_revived(w, e->own)) { dir_release(w, e->own); e->own = -1; }
        if (e->own < 0) {
            int own = dir_acquire(w, e->path);
            if (own < 0) return own;
            // `dirs` may have moved; `e` has not.
            e->own = own;
            replaced = 1;
        }
    } else if (e->own >= 0) {
        dir_release(w, e->own);
        e->own = -1;
    }
#if !WATCH_INOTIFY
    if (stands && !is_dir) {
        struct stat held;
        if (e->fd >= 0 && (fstat(e->fd, &held) != 0 || held.st_ino != st->st_ino || held.st_dev != st->st_dev)) file_close(e);
        if (e->fd < 0) {
            int opened = file_open(w, at);
            if (opened < 0) return opened;
            replaced = 1;
        }
    } else {
        file_close(e);
    }
#endif
    return replaced;
}

// One touched entry settled against what stands now: what it is
// answered as.
static int settled(Watch* w, int at) {
    Entry* e = &w->entries[at];
    int why = e->touched;
    e->touched = 0;
    if (!dir_revived(w, e->parent)) {
        entry_free(w, at);
        return W_UNWATCHED;
    }
    struct stat st = { 0 };
    int stands = stat(e->path, &st) == 0;
    int is_dir = stands && S_ISDIR(st.st_mode);
    int moved = entry_aimed(w, at, stands, &st) != 0 || (why & T_CONTENT) != 0 || is_dir != e->was_dir;
    if (stands && !is_dir) {
        if ((why & T_ATTR) && (st.st_size != e->size || mtime_ns_of(&st) != e->mtime_ns)) moved = 1;
        e->size = st.st_size;
        e->mtime_ns = mtime_ns_of(&st);
    }
    int what = !e->stood ? (stands ? W_CREATED : W_NONE)
             : !stands ? W_REMOVED
             : moved ? W_CHANGED : W_NONE;
    e->stood = (uint8_t)stands;
    e->was_dir = (uint8_t)is_dir;
    return what;
}

// ── The host's events ───────────────────────────────────────────

#if WATCH_INOTIFY

static void routed(Watch* w, const struct inotify_event* ev) {
    if (ev->mask & IN_Q_OVERFLOW) { w->lost = 1; return; }
    int gone = (ev->mask & (IN_DELETE_SELF | IN_MOVE_SELF | IN_IGNORED | IN_UNMOUNT)) != 0;
    int entries = (ev->mask & (IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO)) != 0;
    int leaving = (ev->mask & (IN_DELETE | IN_MOVED_FROM)) != 0;
    int stale = 0;
    for (int d = 0; d < w->ndirs; d++) {
        if (!w->dirs[d].path || w->dirs[d].os != ev->wd) continue;
        if (gone) { stale = (ev->mask & IN_MOVE_SELF) != 0; dir_dead(w, d); continue; }
        for (int i = 0; i < w->nentries; i++) {
            Entry* e = &w->entries[i];
            if (!e->path) continue;
            if (e->own == d && entries) touch(w, i, T_CONTENT);
            if (e->parent == d && ev->len > 0 && strcmp(e->name, ev->name) == 0) touch(w, i, leaving ? T_EXIST : T_EXIST | T_CONTENT);
        }
    }
    // A moved directory keeps its inotify watch; nothing here wants it.
    if (stale) inotify_rm_watch(w->fd, ev->wd);
}

// Everything the host has queued, routed; 0 or -errno.
static int drained(Watch* w) {
    static _Alignas(struct inotify_event) char buf[1 << 16];
    for (;;) {
        // the clock: the inotify descriptor is IN_NONBLOCK, a read answers at once
        ssize_t n = read(w->fd, buf, sizeof buf);
        if (n < 0 && errno == EINTR) continue;
        if (n < 0) return errno == EAGAIN ? 0 : -errno;
        if (n == 0) return 0;
        for (char* p = buf; p < buf + n;) {
            const struct inotify_event* ev = (const struct inotify_event*)p;
            routed(w, ev);
            p += sizeof(struct inotify_event) + ev->len;
        }
    }
}

static int os_open(void) {
    int fd = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
    return fd < 0 ? -errno : fd;
}

#else

static void routed(Watch* w, const struct kevent* ev) {
    int at = (int)((intptr_t)ev->udata >> 1);
    int gone = (ev->fflags & (NOTE_DELETE | NOTE_RENAME | NOTE_REVOKE)) != 0;
    if ((intptr_t)ev->udata & 1) {
        if (at >= w->nentries || !w->entries[at].path || w->entries[at].fd != (int)ev->ident) return;
        int why = (gone ? T_EXIST : 0) |
                  ((ev->fflags & (NOTE_WRITE | NOTE_EXTEND)) ? T_CONTENT : 0) |
                  ((ev->fflags & NOTE_ATTRIB) ? T_ATTR : 0);
        if (why) touch(w, at, why);
        return;
    }
    if (at >= w->ndirs || !w->dirs[at].path || w->dirs[at].os != (int)ev->ident) return;
    if (gone) {
        close(w->dirs[at].os);
        dir_dead(w, at);
        return;
    }
    for (int i = 0; i < w->nentries; i++) {
        Entry* e = &w->entries[i];
        if (!e->path) continue;
        if (e->own == at) touch(w, i, T_CONTENT);
        if (e->parent == at) touch(w, i, T_EXIST);
    }
}

static int drained(Watch* w) {
    enum { BATCH = 64 };
    struct kevent evs[BATCH];
    struct timespec now = { 0, 0 };
    for (;;) {
        // the clock: not a wait on time — a zero timeout, a look
        int n = kevent(w->fd, NULL, 0, evs, BATCH, &now);
        if (n < 0 && errno == EINTR) continue;
        if (n < 0) return -errno;
        for (int i = 0; i < n; i++) routed(w, &evs[i]);
        if (n < BATCH) return 0;
    }
}

static int os_open(void) {
    int fd = kqueue();
    if (fd < 0) return -errno;
    fcntl(fd, F_SETFD, FD_CLOEXEC);
    return fd;
}

#endif

// ── The entry points ────────────────────────────────────────────

// A watch over nothing: its handle, or -errno.
int64_t avra_io_watch_open(void) {
    int at = 0;
    while (at < g_nwatches && g_watches[at].fd >= 0) at++;
    if (at == g_nwatches) {
        Watch* more = realloc(g_watches, (size_t)(g_nwatches + 1) * sizeof(Watch));
        if (!more) return -ENOMEM;
        g_watches = more;
        g_nwatches++;
    }
    int fd = os_open();
    if (fd < 0) { g_watches[at].fd = -1; return fd; }
    g_watches[at] = (Watch){ .fd = fd };
    return at;
}

// The descriptor that reads ready while anything is pending.
int64_t avra_io_watch_fd(int64_t h) {
    Watch* w = watch_of(h);
    return w ? w->fd : -EBADF;
}

// Where `path`'s last name begins.
static const char* name_in(const char* path) {
    const char* slash = strrchr(path, '/');
    return slash ? slash + 1 : path;
}

// The directory `path` is a name in, as a fresh string: what precedes
// its last slash, `/` for a name at the root, `.` for a bare name.
static char* parent_of(const char* path) {
    const char* name = name_in(path);
    if (name == path) return strdup(".");
    size_t n = (size_t)(name - path) - 1;
    if (n == 0) return strdup("/");
    char* p = malloc(n + 1);
    if (!p) return NULL;
    memcpy(p, path, n);
    p[n] = 0;
    return p;
}

// `path` as the set spells it, a fresh string: no slash after its last
// name, the root excepted.
static char* spelled(const char* path) {
    size_t n = strlen(path);
    while (n > 1 && path[n - 1] == '/') n--;
    char* s = malloc(n + 1);
    if (!s) return NULL;
    memcpy(s, path, n);
    s[n] = 0;
    return s;
}

// The slot of the entry spelled `path`, or -1.
static int entry_at(const Watch* w, const char* path) {
    for (int i = 0; i < w->nentries; i++) {
        if (w->entries[i].path && strcmp(w->entries[i].path, path) == 0) return i;
    }
    return -1;
}

// `path` joins the set, as it stands now: its slot, or -errno. A path
// already in the set keeps its slot. The parent directory must stand;
// the path itself need not.
int64_t avra_io_watch_add(int64_t h, const char* path) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    char* kept = spelled(path);
    if (!kept) return -ENOMEM;
    int at = entry_at(w, kept);
    if (at >= 0) { free(kept); w->entries[at].gen = w->gen; return at; }
    for (at = 0; at < w->nentries && w->entries[at].path; at++) {}
    if (at == w->nentries) {
        Entry* more = realloc(w->entries, (size_t)(w->nentries + 1) * sizeof(Entry));
        if (!more) { free(kept); return -ENOMEM; }
        w->entries = more;
        w->entries[w->nentries++].path = NULL;
    }
    char* parent = parent_of(kept);
    if (!parent) { free(kept); return -ENOMEM; }
    int dir = dir_acquire(w, parent);
    free(parent);
    if (dir < 0) { free(kept); return dir; }
    Entry* e = &w->entries[at];
    *e = (Entry){ .path = kept, .name = name_in(kept), .parent = dir, .own = -1, .fd = -1, .gen = w->gen };
    struct stat st = { 0 };
    int stands = stat(kept, &st) == 0;
    int aimed = entry_aimed(w, at, stands, &st);
    if (aimed < 0) { entry_free(w, at); return aimed; }
    e->stood = (uint8_t)stands;
    e->was_dir = (uint8_t)(stands && S_ISDIR(st.st_mode));
    if (stands) { e->size = st.st_size; e->mtime_ns = mtime_ns_of(&st); }
    return at;
}

// `path` leaves the set: 1 when it was in it, 0 when not.
int64_t avra_io_watch_drop(int64_t h, const char* path) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    char* kept = spelled(path);
    if (!kept) return -ENOMEM;
    int at = entry_at(w, kept);
    free(kept);
    if (at >= 0) entry_free(w, at);
    return at >= 0;
}

// A new round opens: every `add` from here marks its path kept.
int64_t avra_io_watch_mark(int64_t h) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    w->gen++;
    return 0;
}

// Every path not added since the mark leaves the set: how many did.
int64_t avra_io_watch_sweep(int64_t h) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    int swept = 0;
    for (int i = 0; i < w->nentries; i++) {
        if (w->entries[i].path && w->entries[i].gen != w->gen) { entry_free(w, i); swept++; }
    }
    return swept;
}

// Everything the host has queued is read and every touched entry
// settled: how many changed, each then read by `slot` and `what`.
// Never waits. When the host lost count the answer is 0, `lost` says
// so, and every entry is settled to what stands now.
int64_t avra_io_watch_take(int64_t h) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    int read = drained(w);
    if (read < 0) return read;
    w->nchanged = 0;
    if (w->lost) {
        for (int i = 0; i < w->nentries; i++) {
            if (w->entries[i].path) { w->entries[i].touched = T_EXIST; settled(w, i); }
        }
        w->ntouched = 0;
        return 0;
    }
    for (int k = 0; k < w->ntouched; k++) {
        int at = w->touched[k];
        Entry* e = &w->entries[at];
        if (!e->path || !e->touched) continue;
        int what = settled(w, at);
        if (what == W_NONE) continue;
        if (!grown((void**)&w->changed, &w->changed_cap, w->nchanged, sizeof(int))) { w->lost = 1; break; }
        w->entries[at].what = (uint8_t)what;
        w->changed[w->nchanged++] = at;
    }
    w->ntouched = 0;
    return w->lost ? 0 : w->nchanged;
}

// Whether the host lost count since this was last asked.
int64_t avra_io_watch_lost(int64_t h) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    int lost = w->lost;
    w->lost = 0;
    return lost;
}

// The slot of the `i`th change the last take answered.
int64_t avra_io_watch_slot(int64_t h, int64_t i) {
    Watch* w = watch_of(h);
    if (!w || i < 0 || i >= w->nchanged) return -EINVAL;
    return w->changed[i];
}

// What the `i`th change is: 1 created, 2 changed, 3 removed, 4 no
// longer watched.
int64_t avra_io_watch_what(int64_t h, int64_t i) {
    Watch* w = watch_of(h);
    if (!w || i < 0 || i >= w->nchanged) return -EINVAL;
    return w->entries[w->changed[i]].what;
}

// The watch ended and everything it held given back; a task parked on
// it wakes.
int64_t avra_io_watch_close(int64_t h) {
    Watch* w = watch_of(h);
    if (!w) return -EBADF;
    avra_fiber_fd_closing(w->fd);
    for (int i = 0; i < w->nentries; i++) if (w->entries[i].path) entry_free(w, i);
    close(w->fd);
    free(w->dirs);
    free(w->entries);
    free(w->touched);
    free(w->changed);
    *w = (Watch){ .fd = -1 };
    return 0;
}

#endif

// @std/io's watch, driven through its entry points as the package
// drives them, against the host's real events: each case makes a
// change on disk, waits for the watch's descriptor to read ready, and
// holds what one take answers. The package's C is compiled in here, so
// the test holds the body the package links.
// glibc declares `nftw` and `mkdtemp` only under a feature macro.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <ftw.h>
#include <poll.h>
#include <unistd.h>
#include <sys/resource.h>

#include "../../packages/std-io/src/c/std_io_watch.c"

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "watch_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

enum { SLOTS = 64 };
static const char* g_names[SLOTS];
static int64_t g_watch;

static int added(const char* path) {
    int64_t slot = avra_io_watch_add(g_watch, path);
    if (slot >= 0 && slot < SLOTS) g_names[slot] = path;
    return (int)slot;
}

static void sh(const char* line) {
    if (system(line) != 0) { g_fails++; fprintf(stderr, "watch_test: the step `%s` failed\n", line); }
}

// What one take answers once the descriptor reads ready (or 300 ms
// pass): each change as `path:mark `, in slot order — `+` created, `~`
// changed, `-` removed, `!` no longer watched — or LOST.
static const char* seen(void) {
    static char out[1024];
    out[0] = 0;
    struct pollfd pf = { (int)avra_io_watch_fd(g_watch), POLLIN, 0 };
    poll(&pf, 1, 300);
    int64_t n = avra_io_watch_take(g_watch);
    if (avra_io_watch_lost(g_watch)) return "LOST";
    if (n < 0) { snprintf(out, sizeof out, "errno %lld", (long long)-n); return out; }
    for (int slot = 0; slot < SLOTS; slot++) {
        for (int64_t i = 0; i < n; i++) {
            if (avra_io_watch_slot(g_watch, i) != slot) continue;
            size_t at = strlen(out);
            snprintf(out + at, sizeof out - at, "%s:%c ", g_names[slot], " +~-!"[avra_io_watch_what(g_watch, i)]);
        }
    }
    return out;
}

static void expect_at(const char* what, const char* want, int line) {
    const char* got = seen();
    g_checks++;
    if (strcmp(got, want) == 0) return;
    g_fails++;
    fprintf(stderr, "watch_test: FAILED %s — wanted [%s], saw [%s] (line %d)\n", what, want, got, line);
}
#define EXPECT(what, want) expect_at(what, want, __LINE__)

// The number the next descriptor opened would take: equal before and
// after means nothing in between is still held.
static int next_fd(void) {
    int fd = open(".", O_RDONLY);
    close(fd);
    return fd;
}

static int64_t cpu_us(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
    return (int64_t)(r.ru_utime.tv_sec + r.ru_stime.tv_sec) * 1000000 + r.ru_utime.tv_usec + r.ru_stime.tv_usec;
}

static int unlinked(const char* path, const struct stat* st, int kind, struct FTW* ftw) {
    (void)st; (void)kind; (void)ftw;
    return remove(path);
}

static void files(void) {
    added("d/f");
    added("d/late");
    EXPECT("nothing moved", "");
    sh("echo more >> d/f");
    EXPECT("an append", "d/f:~ ");
    sh("for i in 1 2 3 4 5 6 7 8; do echo $i >> d/f; done");
    EXPECT("a burst is one change", "d/f:~ ");
    sh(": > d/f");
    EXPECT("a truncation", "d/f:~ ");
    sh("chmod 600 d/f");
    EXPECT("a mode alone is no change", "");
    sh("echo y >> d/other");
    EXPECT("an unwatched sibling's write", "");
    sh("echo x > d/passing; rm d/passing");
    EXPECT("an unwatched sibling arriving and leaving", "");
    sh("echo t > d/.tmp && mv d/.tmp d/f");
    EXPECT("a save by rename over the file", "d/f:~ ");
    sh("echo again >> d/f");
    EXPECT("a write to the file that replaced it", "d/f:~ ");
    sh("mv d/f d/f.bak && echo z > d/f");
    EXPECT("a save that moves the old file aside", "d/f:~ ");
    sh("echo again >> d/f");
    EXPECT("a write after it", "d/f:~ ");
    sh("rm d/f");
    EXPECT("a removal", "d/f:- ");
    sh("echo back > d/f");
    EXPECT("the file created again", "d/f:+ ");
    sh("echo more >> d/f");
    EXPECT("a write to the one created again", "d/f:~ ");
    sh("rm d/f; echo back > d/f");
    EXPECT("removed and created between two looks is a change", "d/f:~ ");
    sh("echo x > d/late");
    EXPECT("a file that did not stand when added", "d/late:+ ");
    sh("echo x > d/late; rm d/late; echo x > d/late; rm d/late");
    EXPECT("and gone again, however it got there", "d/late:- ");
    sh("echo x > d/late; rm d/late");
    EXPECT("absent before and after is nothing", "");
}

static void directories(void) {
    added("sub");
    sh("echo n > sub/new");
    EXPECT("a directory's entry arriving", "sub:~ ");
    sh("echo n >> sub/new");
    EXPECT("a write inside a directory is not its entries", "");
    sh("mv sub/new sub/named");
    EXPECT("an entry renamed", "sub:~ ");
    sh("rm sub/named");
    EXPECT("an entry leaving", "sub:~ ");
    sh("rmdir sub");
    EXPECT("the directory removed", "sub:- ");
    sh("mkdir sub");
    EXPECT("the directory made again", "sub:+ ");
    sh("echo n > sub/new");
    EXPECT("an entry in the one made again", "sub:~ ");
    sh("rm sub/new && rmdir sub && echo now a file > sub");
    EXPECT("a file where the directory stood", "sub:~ ");
    sh("echo more >> sub");
    EXPECT("and it is watched as a file", "sub:~ ");
    sh("rm sub && mkdir sub");
    EXPECT("a directory where the file stood", "sub:~ ");
    sh("echo n > sub/new");
    EXPECT("and it is watched as a directory", "sub:~ ");
}

static void parents(void) {
    sh("mv d d.old && mkdir d && echo swapped > d/f");
    EXPECT("the parent swapped for another", "d/f:~ ");
    sh("echo more >> d/f");
    EXPECT("a write under the new parent", "d/f:~ ");
    sh("echo more >> d.old/f");
    EXPECT("a write under the old parent is another path's", "");
    sh("rm -r d");
    EXPECT("the parent gone takes its watches", "d/f:! d/late:! ");
    CHECK(added("d/f") < 0, "a path under no directory is refused");
    sh("mkdir d");
    CHECK(added("d/f") >= 0, "and added once its directory stands");
    sh("echo x > d/f");
    EXPECT("watched afresh", "d/f:+ ");
}

static void sets(void) {
    int f = added("d/f");
    CHECK(added("d/f") == f, "a path added twice keeps its slot");
    CHECK(avra_io_watch_add(g_watch, "d/f/") == f && avra_io_watch_add(g_watch, "d//f") != f, "a trailing slash spells the same path");
    avra_io_watch_drop(g_watch, "d//f");
    avra_io_watch_mark(g_watch);
    added("d/f");
    CHECK(avra_io_watch_sweep(g_watch) == 1, "a sweep drops what the round did not add");
    sh("echo n > sub/again; echo q >> d/f");
    EXPECT("only what was kept is answered", "d/f:~ ");
    CHECK(avra_io_watch_drop(g_watch, "d/f") == 1, "a drop of a watched path");
    CHECK(avra_io_watch_drop(g_watch, "d/f") == 0, "a drop of one that is not");
    sh("echo q >> d/f");
    EXPECT("a dropped path says nothing", "");
    added("d/f");
}

static void links(void) {
    sh("echo real > real; echo other > real2; ln -s ../real d/link");
    added("d/link");
    sh("ln -sf ../real2 d/link");
    EXPECT("a link aimed elsewhere", "d/link:~ ");
    sh("rm d/link");
    EXPECT("a link removed", "d/link:- ");
    avra_io_watch_drop(g_watch, "d/link");
}

static void nothing_held(void) {
    int before = next_fd();
    for (int i = 0; i < 1000; i++) {
        if (avra_io_watch_add(g_watch, "real") < 0 || avra_io_watch_add(g_watch, "sub") < 0) { CHECK(0, "an add in the cycle"); break; }
        avra_io_watch_drop(g_watch, "real");
        avra_io_watch_drop(g_watch, "sub");
    }
    CHECK(next_fd() == before, "1000 adds and drops hold no descriptor");
    int64_t other = avra_io_watch_open();
    CHECK(other >= 0 && other != g_watch, "a second watch");
    avra_io_watch_add(other, "real");
    avra_io_watch_add(other, "sub");
    avra_io_watch_close(other);
    CHECK(next_fd() == before, "a closed watch holds no descriptor");
    CHECK(avra_io_watch_take(other) == -EBADF, "a closed watch is no watch");
}

static void idle(void) {
    EXPECT("settled before the wait", "");
    int64_t began = cpu_us();
    struct pollfd pf = { (int)avra_io_watch_fd(g_watch), POLLIN, 0 };
    int ready = poll(&pf, 1, 1000);
    int64_t spent = cpu_us() - began;
    CHECK(ready == 0, "an idle watch does not read ready");
    CHECK(spent < 5000, "an idle second costs no CPU");
}

#if !WATCH_INOTIFY
// More paths than the soft limit has descriptors for: the limit is
// raised and every one is watched; with the hard limit as low, the
// refusal is the host's.
static void descriptors(void) {
    struct rlimit was, low;
    getrlimit(RLIMIT_NOFILE, &was);
    sh("mkdir many && for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19; do echo x > many/$i; done");
    static char paths[20][16];
    low = was;
    low.rlim_cur = (rlim_t)next_fd() + 8;
    setrlimit(RLIMIT_NOFILE, &low);
    int refused = 0;
    for (int i = 0; i < 20; i++) {
        snprintf(paths[i], sizeof paths[i], "many/%d", i);
        if (avra_io_watch_add(g_watch, paths[i]) < 0) refused++;
    }
    struct rlimit now;
    getrlimit(RLIMIT_NOFILE, &now);
    CHECK(refused == 0 && now.rlim_cur > low.rlim_cur, "out of descriptors, the soft limit is raised and every path watched");
    for (int i = 0; i < 20; i++) avra_io_watch_drop(g_watch, paths[i]);
    setrlimit(RLIMIT_NOFILE, &was);
}
#else
static void descriptors(void) {}
#endif

#if WATCH_INOTIFY
// More events than the host queues, none read: the count is lost, said
// once, and the watch stands settled after.
static void overflow(void) {
    long limit = 16384;
    FILE* f = fopen("/proc/sys/fs/inotify/max_queued_events", "r");
    if (f) { if (fscanf(f, "%ld", &limit) != 1) limit = 16384; fclose(f); }
    sh("mkdir flood");
    added("flood");
    added("flood/0");
    EXPECT("the flood directory joins", "");
    for (long i = 0; i < limit; i++) {
        char path[64];
        snprintf(path, sizeof path, "flood/%ld", i);
        int fd = open(path, O_WRONLY | O_CREAT, 0644);
        if (fd >= 0) close(fd);
    }
    EXPECT("a queue overrun is said", "LOST");
    EXPECT("and said once", "");
    sh("echo x >> flood/0");
    EXPECT("the watch stands after it", "flood/0:~ ");
}
#else
static void overflow(void) {}
#endif

int main(void) {
    char root[] = "/tmp/avra-watch-test-XXXXXX";
    if (!mkdtemp(root) || chdir(root) != 0) { fprintf(stderr, "watch_test: no scratch directory\n"); return 1; }
    sh("mkdir d sub && echo hi > d/f && echo o > d/other");
    g_watch = avra_io_watch_open();
    if (g_watch < 0) { fprintf(stderr, "watch_test: the host gave no watch (errno %lld)\n", (long long)-g_watch); return 1; }
    files();
    directories();
    parents();
    sets();
    links();
    nothing_held();
    descriptors();
    idle();
    overflow();
    avra_io_watch_close(g_watch);
    if (chdir("/") == 0) nftw(root, unlinked, 16, FTW_DEPTH | FTW_PHYS);
    printf("watch_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails != 0;
}

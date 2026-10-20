// THE OS'S ENTROPY, by the laws its answer keeps. The draw (runtime/avra_random.h)
// is held to sources that fail: none is an EMPTY box, only a source with nothing
// to give is absent, a negative length traps, a short read is read on and a box is
// never partly filled. The row itself is held to the real OS and to the box header.
#include <errno.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

const char* avra_random_bytes(int64_t n);
int64_t avra_bytes_len(const char* b);
void avra_rc_release(void* p);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "random_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// The runtime's own words, as the draw's header finds them in the runtime: here a
// box is a malloc, a release is a free, and a trap is exit 2 with its words.
static int g_released;
static char* stand_box(size_t n) { char* b = calloc(n + 1, 1); return b; }
static void stand_release(void* p) { g_released++; free(p); }
static void stand_fmt(char* out, size_t size, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsnprintf(out, size, fmt, args);
    va_end(args);
}
static void stand_trap(const char* words) __attribute__((noreturn));
static void stand_trap(const char* words) { fprintf(stderr, "avra: %s\n", words); _exit(2); }

#define bytes_box stand_box
#define avra_rc_release stand_release
#define avra_fmt stand_fmt
#define avra_trap stand_trap
#include "../avra_random.h"
#undef bytes_box
#undef avra_rc_release
#undef avra_fmt
#undef avra_trap

// A source that gives `step` bytes of 7 a call.
static size_t g_step;
static ssize_t trickle(void* out, size_t n) {
    size_t k = n < g_step ? n : g_step;
    memset(out, 7, k);
    return (ssize_t)k;
}

// A source that is interrupted once, then gives all.
static int g_interrupted;
static ssize_t interrupted(void* out, size_t n) {
    if (!g_interrupted++) { errno = EINTR; return -1; }
    memset(out, 7, n);
    return (ssize_t)n;
}

// A source that gives four bytes, then has nothing.
static size_t g_given;
static ssize_t runs_dry(void* out, size_t n) {
    if (g_given >= 4) { errno = EIO; return -1; }
    size_t k = n < 4 ? n : 4;
    memset(out, 7, k);
    g_given += k;
    return (ssize_t)k;
}

static ssize_t gives_nothing(void* out, size_t n) { (void)out; (void)n; return 0; }

static void asks_for_minus_three(void) { (void)random_from(-3, trickle); }

// `body` run in a child: it must exit 2 (a trap) with `words` on stderr.
static void trapped(const char* what, void (*body)(void), const char* words) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        alarm(10);
        body();
        _exit(0);
    }
    close(out[1]);
    char buf[512] = {0};
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2, what);
    CHECK(strstr(buf, words) != NULL, words);
}

static int all_sevens(const char* b, int64_t n) {
    for (int64_t i = 0; i < n; i++) if (b[i] != 7) return 0;
    return 1;
}

static int distinct_draws(int64_t n) {
    const char* a = avra_random_bytes(n);
    const char* b = avra_random_bytes(n);
    int ok = a && b && avra_bytes_len(a) == n && avra_bytes_len(b) == n && memcmp(a, b, (size_t)n) != 0;
    avra_rc_release((void*)a);
    avra_rc_release((void*)b);
    return ok;
}

int main(void) {
    const char* none = random_from(0, gives_nothing);
    CHECK(none != NULL, "none asks the source for nothing, so even an empty source answers a box");
    const char* empty = avra_random_bytes(0);
    CHECK(empty != NULL && avra_bytes_len(empty) == 0, "none from the OS is an empty box, never absent");
    trapped("a negative length traps", asks_for_minus_three, "random_bytes takes a length of 0 or more, found -3");

    g_step = 3;
    const char* slow = random_from(100, trickle);
    CHECK(slow != NULL && all_sevens(slow, 100), "a short read is read on until the box is whole");
    const char* once = random_from(10, interrupted);
    CHECK(once != NULL && all_sevens(once, 10), "an interrupted read is tried again");
    int before = g_released;
    CHECK(random_from(10, runs_dry) == NULL && g_released == before + 1, "a source that runs dry is absent and lets the box go, never a partly filled one");
    CHECK(random_from(10, gives_nothing) == NULL, "a source that gives nothing is absent");

    CHECK(distinct_draws(1) || distinct_draws(1) || distinct_draws(1), "one byte is drawn from the OS");
    CHECK(distinct_draws(32), "two draws of 32 bytes differ");
    const char* mib = avra_random_bytes(1 << 20);
    CHECK(mib != NULL && avra_bytes_len(mib) == (1 << 20), "a mebibyte is whole, in a headered box");
    int zeros = 0;
    for (int i = 0; i < (1 << 20); i++) zeros += mib[i] == 0;
    CHECK(zeros > 3000 && zeros < 5500, "a mebibyte of entropy holds about one zero byte in 256");

    free((void*)none);
    free((void*)slow);
    free((void*)once);
    avra_rc_release((void*)empty);
    avra_rc_release((void*)mib);
    printf("random: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

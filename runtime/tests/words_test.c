// THE RUNTIME'S OWN WORDS ARE PRINTF'S, for the conversions it uses: a
// trap's text is pinned by both engines, so `avra_fmt` is held to libc's
// own answer for every shape the runtime writes, at the values that
// break a digit loop — zero, the smallest int, a width the text
// overflows, a buffer too short for it.
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../avra_runtime.h"

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "words_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// One format at one argument list, both formatters into `cap` bytes.
#define SAME(cap, ...) do { \
    char ours[256], theirs[256]; \
    memset(ours, '#', sizeof ours); memset(theirs, '#', sizeof theirs); \
    avra_fmt(ours, cap, __VA_ARGS__); \
    snprintf(theirs, cap, __VA_ARGS__); \
    g_checks++; \
    if (strcmp(ours, theirs) != 0) { g_fails++; fprintf(stderr, "words_test: FAILED `%s` is not `%s` (%s:%d)\n", ours, theirs, __FILE__, __LINE__); } \
} while (0)

static const long long INTS[] = { 0, 1, -1, 9, 10, -10, 12345, 4294967296LL, LLONG_MAX, LLONG_MIN };

// What `avra_say` put on stderr, read back from the file it was aimed at.
static size_t said(char* out, size_t cap, const char* text) {
    char path[] = "/tmp/avra_words_XXXXXX";
    int fd = mkstemp(path);
    fflush(stderr);
    int kept = dup(2);
    dup2(fd, 2);
    avra_say("%s|%lld\n", text, 7LL);
    fflush(stderr);
    dup2(kept, 2);
    close(kept);
    lseek(fd, 0, SEEK_SET);
    ssize_t n = read(fd, out, cap - 1);
    close(fd);
    unlink(path);
    out[n < 0 ? 0 : n] = 0;
    return n < 0 ? 0 : (size_t)n;
}

int main(void) {
    for (size_t i = 0; i < sizeof INTS / sizeof INTS[0]; i++) {
        long long v = INTS[i];
        SAME(256, "index %lld is out of bounds (length %lld)", v, -v);
        SAME(256, "[%6lld] [%-9lld] [%12lld] [%1lld]", v, v, v, v);
        SAME(256, "0x%llx %d %d", (unsigned long long)v, (int)v, -(int)(v % 1000));
        SAME(8, "%lld..%lld", v, v);
    }
    SAME(256, "%s: site %lld", "copy", 3LL);
    SAME(256, "[%-13s] [%13s] [%2s] [%s]", "string", "list", "record", "");
    SAME(256, "e%c%d 100%% %c", '-', 12, 'x');
    SAME(256, "a take at EOF — `read` answered 0, which names no bytes");
    SAME(1, "%s", "cut to nothing");
    SAME(5, "%s", "cut");
    SAME(4, "%s", "cut");
    SAME(3, "%s", "cut");

    char ours[64], theirs[64];
    void* at = (void*)(uintptr_t)0x16fdff0a8ULL;
    avra_fmt(ours, sizeof ours, "site %p", at);
    snprintf(theirs, sizeof theirs, "site 0x%llx", (unsigned long long)(uintptr_t)at);
    CHECK(strcmp(ours, theirs) == 0, "a pointer is 0x and its hex");
    avra_fmt(ours, sizeof ours, "%p", (void*)0);
    CHECK(strcmp(ours, "0x0") == 0, "the null pointer is 0x0");

    static const char* SPELT[] = { "0", "42", "  42", "+42", "-5", "6000", "0x1F", "0X1f", "1f", "017", "12abc", "", "x", "0x", "-", "18446744073709551615", "18446744073709551616", "-18446744073709551616", "ffffffffffffffffff" };
    for (size_t i = 0; i < sizeof SPELT / sizeof SPELT[0]; i++) {
        CHECK(avra_number(SPELT[i], 10) == strtoull(SPELT[i], NULL, 10), SPELT[i]);
        CHECK(avra_number(SPELT[i], 16) == strtoull(SPELT[i], NULL, 16), SPELT[i]);
        CHECK(avra_number(SPELT[i], 0) == strtoull(SPELT[i], NULL, 0), SPELT[i]);
    }

    // a line longer than the buffer `avra_say` drains through, whole
    char longer[700], read_back[1024];
    for (size_t i = 0; i < sizeof longer - 1; i++) longer[i] = (char)('a' + i % 26);
    longer[sizeof longer - 1] = 0;
    size_t n = said(read_back, sizeof read_back, longer);
    CHECK(n == sizeof longer - 1 + 3, "a long line lands whole");
    CHECK(strncmp(read_back, longer, sizeof longer - 1) == 0 && strcmp(read_back + sizeof longer - 1, "|7\n") == 0, "and in order");

    if (g_fails) { fprintf(stderr, "words_test: %d of %d checks FAILED\n", g_fails, g_checks); return 1; }
    printf("words_test: %d checks hold\n", g_checks);
    return 0;
}

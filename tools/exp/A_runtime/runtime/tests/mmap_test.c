// THE PACK'S MMAP ROW: a read-only view of a file, handed back as an
// unmanaged handle. No Avra source calls these yet (M3a lands the row
// alone, Unhosted) — this is the only place they run before that.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_runtime.h"

void* avra_mmap_open(const char* path);
int64_t avra_mmap_len(void* h);
const char* avra_mmap_slice(void* h, int64_t lo, int64_t hi);
int64_t avra_mmap_word_at(void* h, int64_t i);
void avra_mmap_close(void* h);

int64_t avra_bytes_len(const char* b);
int64_t avra_bytes_at(const char* b, int64_t i);
const char* avra_str_from_codepoint(int64_t code);
const char* avra_str_concat(const char* a, const char* b);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "mmap_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static char* temp_file(const char* content, size_t n) {
    static char path[] = "/tmp/avra_mmap_test_XXXXXX";
    char* p = strdup(path);
    int fd = mkstemp(p);
    if (fd < 0) { perror("mkstemp"); exit(1); }
    if (n > 0 && write(fd, content, n) != (ssize_t)n) { perror("write"); exit(1); }
    close(fd);
    return p;
}

// A trap, in a child: its status and the words on its stderr.
static void trapped(const char* what, void (*body)(void), const char* words) {
    int out[2];
    if (pipe(out) != 0) { perror("pipe"); exit(1); }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(out[1], 2);
        close(out[0]);
        body();
        _exit(0);
    }
    close(out[1]);
    char buf[256] = {0};
    size_t got = 0;
    for (ssize_t n; got < sizeof buf - 1 && (n = read(out[0], buf + got, sizeof buf - 1 - got)) > 0;) got += (size_t)n;
    close(out[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    char label[160];
    snprintf(label, sizeof label, "%s exits 2", what);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) == 2, label);
    snprintf(label, sizeof label, "%s says \"%s\"", what, words);
    CHECK(strstr(buf, words) != NULL, label);
}

static char* g_bad_path_holder = NULL;
static void opens_nul_path(void) {
    avra_mmap_open(g_bad_path_holder);
}

static char* g_oob_path_holder = NULL;
static void reads_out_of_range(void) {
    void* h = avra_mmap_open(g_oob_path_holder);
    avra_mmap_slice(h, 0, avra_mmap_len(h) + 1);
}

static char* g_word_path_holder = NULL;
static void words_out_of_range(void) {
    void* h = avra_mmap_open(g_word_path_holder);
    avra_mmap_word_at(h, avra_mmap_len(h) - 4);
}

int main(void) {
    int64_t live = avra_mem_live();

    // The empty case first: a zero-byte file is a valid handle, not
    // absent, and its length is zero.
    {
        char* path = temp_file(NULL, 0);
        void* h = avra_mmap_open(path);
        CHECK(h != NULL, "an empty file opens");
        CHECK(avra_mmap_len(h) == 0, "an empty file's length is 0");
        const char* s = avra_mmap_slice(h, 0, 0);
        CHECK(avra_bytes_len(s) == 0, "an empty slice of an empty file is empty");
        avra_rc_release((void*)s);
        avra_mmap_close(h);
        unlink(path);
        free(path);
    }
    CHECK(avra_mem_live() == live, "the empty-file case leaves the live count where it began");

    // One byte.
    {
        char* path = temp_file("Q", 1);
        void* h = avra_mmap_open(path);
        CHECK(h != NULL, "a one-byte file opens");
        CHECK(avra_mmap_len(h) == 1, "a one-byte file's length is 1");
        const char* s = avra_mmap_slice(h, 0, 1);
        CHECK(avra_bytes_len(s) == 1 && avra_bytes_at(s, 0) == 'Q', "the one byte reads back");
        avra_rc_release((void*)s);
        avra_mmap_close(h);
        unlink(path);
        free(path);
    }
    CHECK(avra_mem_live() == live, "the one-byte case leaves the live count where it began");

    // A large file, with a known pattern, read in the middle and as
    // whole 8-byte words — the word reader's big-endian assembly is
    // wrong in EITHER direction if this disagrees with the byte reads.
    {
        enum { N = 1 << 20 };
        char* content = malloc(N);
        for (int i = 0; i < N; i++) content[i] = (char)(i * 2654435761u);
        char* path = temp_file(content, N);
        void* h = avra_mmap_open(path);
        CHECK(h != NULL, "a large file opens");
        CHECK(avra_mmap_len(h) == N, "a large file's length matches");
        int64_t at = N / 2;
        const char* s = avra_mmap_slice(h, at, at + 256);
        CHECK(avra_bytes_len(s) == 256, "a mid-file slice has the asked length");
        int ok = 1;
        for (int i = 0; i < 256; i++) if (avra_bytes_at(s, i) != (unsigned char)content[at + i]) ok = 0;
        CHECK(ok, "a mid-file slice matches the file's own bytes");
        avra_rc_release((void*)s);
        uint64_t w = (uint64_t)avra_mmap_word_at(h, at);
        uint64_t want = 0;
        for (int j = 0; j < 8; j++) want = (want << 8) | (unsigned char)content[at + j];
        CHECK(w == want, "a word read matches the byte-by-byte big-endian assembly");
        avra_mmap_close(h);
        unlink(path);
        free(path);
        free(content);
    }
    CHECK(avra_mem_live() == live, "the large-file case leaves the live count where it began");

    // Missing: absent, not a trap.
    {
        void* h = avra_mmap_open("/tmp/avra_mmap_test_does_not_exist_at_all");
        CHECK(h == NULL, "a missing file answers absent");
    }

    // A directory is not a file this door maps — also absent.
    {
        void* h = avra_mmap_open("/tmp");
        CHECK(h == NULL, "a directory answers absent");
    }

    // A NUL in the path is refused, not silently truncated.
    {
        char* path = temp_file("x", 1);
        const char* nul = avra_str_from_codepoint(0);
        const char* mid = avra_str_concat(path, nul);
        g_bad_path_holder = (char*)avra_str_concat(mid, "suffix");
        trapped("opening a path with an embedded NUL", opens_nul_path, "embedded NUL");
        avra_rc_release((void*)nul);
        avra_rc_release((void*)mid);
        avra_rc_release((void*)g_bad_path_holder);
        unlink(path);
        free(path);
    }

    // Reading past the mapping's end traps like the runtime's other
    // bounds checks, worded the same way `avra_bytes_slice` is.
    {
        g_oob_path_holder = temp_file("abc", 3);
        trapped("a slice past a mapping's end", reads_out_of_range, "out of bounds");
        unlink(g_oob_path_holder);
    }

    // Reading a word with fewer than 8 bytes left traps the same way.
    {
        g_word_path_holder = temp_file("abc", 3);
        trapped("a word read past a mapping's end", words_out_of_range, "out of bounds");
        unlink(g_word_path_holder);
    }

    // map -> read -> unmap -> reuse: closing one handle and opening a
    // fresh one (the same path, and a different one) both work — no
    // state a first mapping left behind corrupts the next.
    {
        char* path_a = temp_file("first", 5);
        char* path_b = temp_file("second-file", 11);

        void* h1 = avra_mmap_open(path_a);
        const char* s1 = avra_mmap_slice(h1, 0, 5);
        CHECK(avra_bytes_len(s1) == 5 && avra_bytes_at(s1, 0) == 'f', "the first mapping reads");
        avra_rc_release((void*)s1);
        avra_mmap_close(h1);

        void* h2 = avra_mmap_open(path_a);
        const char* s2 = avra_mmap_slice(h2, 0, 5);
        CHECK(avra_bytes_len(s2) == 5 && avra_bytes_at(s2, 0) == 'f', "reopening the same path reads the same bytes");
        avra_rc_release((void*)s2);
        avra_mmap_close(h2);

        void* h3 = avra_mmap_open(path_b);
        CHECK(avra_mmap_len(h3) == 11, "a different path opened after a close has its own length");
        const char* s3 = avra_mmap_slice(h3, 0, 11);
        CHECK(avra_bytes_at(s3, 0) == 's', "a different path opened after a close reads its own bytes");
        avra_rc_release((void*)s3);
        avra_mmap_close(h3);

        unlink(path_a);
        unlink(path_b);
        free(path_a);
        free(path_b);
    }
    CHECK(avra_mem_live() == live, "map/read/unmap/reuse leaves the live count where it began");

    printf("mmap: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

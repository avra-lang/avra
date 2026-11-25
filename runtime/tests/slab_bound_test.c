// A BOUNDED ADDRESS SPACE STILL RUNS A PROGRAM: the slabs ask for the largest range the machine
// grants, and with none the small blocks are malloc's. The same work runs in a child under three
// bounds — none (the whole range), one that grants a smaller range, one that grants none — and,
// with no range, under the guard as well. Every run must answer the same checksum, hold the same
// live bytes at its peak and free them all, and the bound must have moved where the blocks came
// from (read off the mapping that holds a fresh box, on Linux).
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/resource.h>

#include "../avra_runtime.h"

const char* avra_int_text(int64_t v);
void* avra_array_new(void);
void avra_array_push_moved(void* arr, void* v);
int64_t avra_array_get(void* arr, int64_t i);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "slab_bound_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// The size of the mapping that holds `p`, from /proc/self/maps; 0 where it is not read.
static long long mapping_of(const void* p) {
#ifdef __linux__
    FILE* f = fopen("/proc/self/maps", "r");
    if (!f) return 0;
    unsigned long long lo, hi;
    char line[512];
    long long size = 0;
    while (fgets(line, sizeof line, f)) {
        if (sscanf(line, "%llx-%llx", &lo, &hi) == 2 && (unsigned long long)(uintptr_t)p >= lo && (unsigned long long)(uintptr_t)p < hi) {
            size = (long long)(hi - lo);
            break;
        }
    }
    fclose(f);
    return size;
#else
    (void)p;
    return 0;
#endif
}

// The work: lists of texts inside a list, read back into a checksum, then all of it released.
static int child(void) {
    int64_t before = avra_mem_live();
    void* probe = (void*)avra_int_text(7);
    long long held = mapping_of(probe);
    void* outer = avra_array_new();
    for (int i = 0; i < 400; i++) {
        void* inner = avra_array_new();
        for (int j = 0; j < 50; j++) avra_array_push_moved(inner, (void*)avra_int_text(i * 1000 + j));
        avra_array_push_moved(outer, inner);
    }
    long long sum = 0;
    for (int i = 0; i < 400; i++) {
        void* inner = (void*)(uintptr_t)avra_array_get(outer, i);
        for (int j = 0; j < 50; j++) sum += (long long)strlen((const char*)(uintptr_t)avra_array_get(inner, j)) * (i + j + 1);
    }
    int64_t peak = avra_mem_live() - before;
    avra_rc_release(outer);
    avra_rc_release(probe);
    printf("%lld %lld %lld %lld\n", sum, (long long)peak, (long long)(avra_mem_live() - before), held);
    return 0;
}

typedef struct { long long sum, peak, left, held; int status; } Run;

// The child run under a bound of `bound` bytes of address space (0: none), with `guard` set.
static Run run(const char* self, long long bound, int guard) {
    Run r = {0, 0, 0, 0, -1};
    int fds[2];
    if (pipe(fds) != 0) return r;
    pid_t pid = fork();
    if (pid == 0) {
        dup2(fds[1], 1);
        close(fds[0]);
        if (bound > 0) {
            struct rlimit lim = {(rlim_t)bound, (rlim_t)bound};
            setrlimit(RLIMIT_AS, &lim);
        }
        if (guard) setenv("AVRA_RC_GUARD", "1", 1); else unsetenv("AVRA_RC_GUARD");
        execl(self, self, "child", (char*)NULL);
        _exit(127);
    }
    close(fds[1]);
    char buf[256] = {0};
    ssize_t n = read(fds[0], buf, sizeof buf - 1);
    close(fds[0]);
    int st = 0;
    waitpid(pid, &st, 0);
    r.status = WIFEXITED(st) ? WEXITSTATUS(st) : 128 + WTERMSIG(st);
    if (n > 0) sscanf(buf, "%lld %lld %lld %lld", &r.sum, &r.peak, &r.left, &r.held);
    return r;
}

int main(int argc, char** argv) {
    if (argc > 1 && strcmp(argv[1], "child") == 0) return child();
    Run whole = run(argv[0], 0, 0);
    Run smaller = run(argv[0], (long long)8 << 30, 0);
    Run none = run(argv[0], (long long)768 << 20, 0);
    Run guarded = run(argv[0], (long long)768 << 20, 1);
    Run* runs[] = {&whole, &smaller, &none, &guarded};
    const char* names[] = {"no bound", "an 8 GB bound", "a 768 MB bound", "a 768 MB bound under the guard"};
    for (int i = 0; i < 4; i++) {
        char what[160];
        snprintf(what, sizeof what, "the work ran to its end under %s", names[i]);
        CHECK(runs[i]->status == 0, what);
        snprintf(what, sizeof what, "the same checksum under %s", names[i]);
        CHECK(runs[i]->sum == whole.sum && whole.sum != 0, what);
        snprintf(what, sizeof what, "the same live bytes at the peak under %s", names[i]);
        CHECK(runs[i]->peak == whole.peak && whole.peak > 0, what);
        snprintf(what, sizeof what, "every byte freed under %s", names[i]);
        CHECK(runs[i]->left == 0, what);
    }
#ifdef __linux__
    CHECK(whole.held >= ((long long)64 << 30), "with no bound a box lies in the whole reserved range");
    CHECK(smaller.held >= ((long long)1 << 30) && smaller.held < ((long long)8 << 30), "an 8 GB bound grants a smaller range, and a box lies in it");
    CHECK(none.held < ((long long)1 << 30), "a 768 MB bound grants no range, and a box is malloc's");
#endif
    printf("slab_bound_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

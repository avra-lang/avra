// THE STACK ALLOCATOR, ALONE: reservations made a slab at a time as the
// scheduler makes them (runtime/avra_fiber.c, `slab_made`), each guarded
// one of three ways, then each stack's top touched as a parked task
// touches it. Prints what a guard and a first touch cost, what a parked
// stack holds resident and in page tables, how many mappings the
// process ends with, and where the kernel refused.
//
//   stacks <reserve bytes> <mprotect|madvise|none> <stacks> <touched bytes> [populate]
//
// `populate` asks the kernel for each stack's top page by name
// (`MADV_POPULATE_WRITE`) before it is touched, where a touch alone
// takes a fault.
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#ifndef MADV_POPULATE_WRITE
#define MADV_POPULATE_WRITE 23
#endif
#ifndef MADV_GUARD_INSTALL
#define MADV_GUARD_INSTALL 102
#endif

enum { SLAB = 64 };

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

// A kB field of the process's status, in bytes; 0 where there is none.
static long status(const char* key) {
    FILE* f = fopen("/proc/self/status", "r");
    if (!f) return 0;
    char line[256];
    long kb = 0;
    while (fgets(line, sizeof line, f)) {
        if (strncmp(line, key, strlen(key)) == 0) { kb = atol(line + strlen(key)); break; }
    }
    fclose(f);
    return kb * 1024;
}

static long mappings(void) {
    FILE* f = fopen("/proc/self/maps", "r");
    if (!f) return 0;
    long n = 0;
    for (int c; (c = fgetc(f)) != EOF;) n += c == '\n';
    fclose(f);
    return n;
}

int main(int argc, char** argv) {
    int populate = argc == 6 && strcmp(argv[5], "populate") == 0;
    if (argc != 5 && !populate) { fprintf(stderr, "usage: stacks <reserve> <mprotect|madvise|none> <stacks> <touched>\n"); return 1; }
    size_t page = (size_t)sysconf(_SC_PAGESIZE);
    size_t reserve = (strtoull(argv[1], NULL, 10) + page - 1) / page * page;
    const char* mode = argv[2];
    long want = atol(argv[3]);
    size_t touched = strtoull(argv[4], NULL, 10);
    size_t each = page + reserve;
    char** tops = malloc((size_t)want * sizeof(char*));
    long rss0 = status("VmRSS:"), pte0 = status("VmPTE:"), maps0 = mappings();
    long made = 0;
    const char* refused = "none";
    int why = 0;
    double guard_ns = 0;
    while (made < want && why == 0) {
        char* s = mmap(NULL, each * SLAB, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        if (s == MAP_FAILED) { refused = "mmap"; why = errno; break; }
        for (int i = 0; i < SLAB && made < want; i++) {
            char* m = s + (size_t)i * each;
            double g0 = now_ns();
            int bad = 0;
            if (strcmp(mode, "mprotect") == 0) bad = mprotect(m, page, PROT_NONE);
            else if (strcmp(mode, "madvise") == 0) bad = madvise(m, page, MADV_GUARD_INSTALL);
            guard_ns += now_ns() - g0;
            if (bad != 0) { refused = mode; why = errno; break; }
            tops[made++] = m + each;
        }
    }
    double t0 = now_ns();
    int refused_populate = 0;
    for (long i = 0; i < made; i++) {
        if (populate && madvise(tops[i] - page, page, MADV_POPULATE_WRITE) != 0) refused_populate = 1;
        memset(tops[i] - touched, 1, touched);
    }
    double touch_ns = now_ns() - t0;
    if (populate) printf("populate %s: ", refused_populate ? "REFUSED" : "asked");
    long n = made ? made : 1;
    printf("reserve %zu KiB, guard %s, page %zu, asked %ld: made %ld, refused by %s (%s)\n",
           reserve / 1024, mode, page, want, made, refused, why ? strerror(why) : "nothing");
    printf("  guard %.0f ns a stack; first touch of %zu bytes %.0f ns a stack\n", guard_ns / n, touched, touch_ns / n);
    printf("  resident %ld bytes a stack; page tables %ld bytes a stack; mappings %ld (+%ld)\n",
           (status("VmRSS:") - rss0) / n, (status("VmPTE:") - pte0) / n, mappings(), mappings() - maps0);
    return 0;
}

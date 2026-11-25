// A STRIDED LIST — each element its `k` words laid in place — answers in ELEMENTS where a row asks
// one: its count, an element's first word (bounds-checked in elements, the trap saying the
// program's own index and length), the last element popped, a slice clamped in elements before it
// is words, so a bound past any length never overflows. Every stride from 2 to 9 cells wide, every
// count past each buffer class; the slice held alone is cut in place, shared is copied. The guard's
// check refuses a box read at two strides and one holding part of an element. Every list dies with
// the live count back where it began.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_runtime.h"
#include "../avra_box.h"

void* avra_array_new_words(void);
int64_t avra_array_get(void* arr, int64_t i);
int64_t avra_array_len(void* arr);
int64_t avra_stride_len(void* arr, int64_t k);
int64_t avra_stride_at(void* arr, int64_t i, int64_t k);
int64_t avra_stride_last(void* arr, int64_t k);
int64_t avra_array_pop(void* arr);
void* avra_stride_slice(void* arr, int64_t lo, int64_t hi, int64_t k);
void* avra_stride_slice_reusing(void* arr, int64_t lo, int64_t hi, int64_t k);
void avra_stride_checked(void* arr, int64_t k);
void avra_rc_retain(void* p);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what, k, n) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "stride_list_test: FAILED %s (k %lld, n %lld, %s:%d)\n", what, (long long)(k), (long long)(n), __FILE__, __LINE__); } } while (0)

// Word `j` of element `e`: a value no other word in any list here holds.
static int64_t word(int64_t e, int64_t j) { return e * 100 + j; }

// A strided list of `n` elements of `k` words, pushed word by word as the lowering pushes them.
static void* elements(int64_t n, int64_t k) {
    void* xs = avra_array_new_words();
    for (int64_t e = 0; e < n; e++) for (int64_t j = 0; j < k; j++) avra_array_push(xs, word(e, j));
    return xs;
}

// Whether `xs` holds elements `from`.. in order, `n` of them, each read at its stride.
static int holds(void* xs, int64_t k, int64_t from, int64_t n) {
    if (avra_stride_len(xs, k) != n || avra_array_len(xs) != n * k) return 0;
    for (int64_t e = 0; e < n; e++) {
        int64_t w = avra_stride_at(xs, e, k);
        if (w != e * k) return 0;
        for (int64_t j = 0; j < k; j++) if (avra_array_get(xs, w + j) != word(from + e, j)) return 0;
    }
    return 1;
}

static void strided(int64_t k, int64_t n) {
    void* xs = elements(n, k);
    CHECK(avra_packed((AvraArray*)xs), "a strided list is packed", k, n);
    CHECK(holds(xs, k, 0, n), "every element reads back at its stride", k, n);
    void* s = avra_stride_slice(xs, n / 3, n - n / 3, k);
    CHECK(holds(s, k, n / 3, (n - n / 3) - n / 3), "a slice holds the elements between its bounds", k, n);
    avra_rc_release(s);
    void* wide = avra_stride_slice(xs, -5, ((int64_t)1) << 62, k);
    CHECK(holds(wide, k, 0, n), "a slice clamped in elements: a negative start, a bound past any length", k, n);
    avra_rc_release(wide);
    void* far = avra_stride_slice(xs, ((int64_t)1) << 62, (((int64_t)1) << 62) + 1, k);
    CHECK(avra_stride_len(far, k) == 0, "a slice starting past any length is empty, its start clamped before it is words", k, n);
    avra_rc_release(far);
    void* none = avra_stride_slice(xs, n, 1, k);
    CHECK(avra_stride_len(none, k) == 0 && avra_packed((AvraArray*)none), "a slice ending before it starts is the empty packed list", k, n);
    avra_rc_release(none);
    avra_rc_retain(xs);
    void* cut = avra_stride_slice_reusing(xs, 1, n, k);
    CHECK(cut != xs && holds(cut, k, 1, n - 1) && holds(xs, k, 0, n), "a shared list sliced is copied, the original standing", k, n);
    avra_rc_release(cut);
    int64_t w = avra_stride_last(xs, k);
    int ok = w == (n - 1) * k && avra_stride_len(xs, k) == n;
    for (int64_t j = 0; j < k; j++) ok = ok && avra_array_get(xs, w + j) == word(n - 1, j);
    CHECK(ok, "the last element's words begin where the row says, the list as it was", k, n);
    for (int64_t j = 0; j < k; j++) avra_array_pop(xs);
    CHECK(avra_stride_len(xs, k) == n - 1 && holds(xs, k, 0, n - 1), "a pop is its words taken off, the rest standing", k, n);
    void* alone = avra_stride_slice_reusing(xs, 1, n, k);
    CHECK(alone == xs && holds(alone, k, 1, n > 1 ? n - 2 : 0), "a list held alone is sliced in place", k, n);
    avra_rc_release(alone);
}

// Runs `act` in a child; true when it stops having said `law`.
static int refused(void (*act)(void), const char* law) {
    int err[2];
    if (pipe(err) != 0) return 0;
    fflush(stdout);
    fflush(stderr);
    pid_t child = fork();
    if (child == 0) {
        close(err[0]);
        dup2(err[1], 2);
        act();
        _exit(0);
    }
    close(err[1]);
    char said[512] = { 0 };
    ssize_t n = 0, got;
    while (n < (ssize_t)sizeof said - 1 && (got = read(err[0], said + n, sizeof said - 1 - (size_t)n)) > 0) n += got;
    close(err[0]);
    int status = 0;
    waitpid(child, &status, 0);
    return WIFEXITED(status) && WEXITSTATUS(status) != 0 && strstr(said, law) != NULL;
}

static void past_end(void) { avra_stride_at(elements(4, 3), 4, 3); }
static void below_zero(void) { avra_stride_at(elements(4, 3), -1, 3); }
static void popped_empty(void) { avra_stride_last(avra_array_new_words(), 2); }
static void two_strides(void) { void* xs = elements(6, 2); avra_stride_checked(xs, 2); avra_stride_checked(xs, 3); }
static void part_of_one(void) { void* xs = elements(2, 3); avra_array_push(xs, 7); avra_stride_checked(xs, 3); }
static void one_stride(void) { void* xs = elements(6, 2); avra_stride_checked(xs, 2); avra_stride_checked(xs, 2); }

int main(void) {
    int64_t live = avra_mem_live();
    int64_t ks[] = { 2, 3, 5, 9 };
    int64_t ns[] = { 1, 2, 3, 8, 9, 17, 40, 300 };
    for (size_t a = 0; a < sizeof ks / sizeof ks[0]; a++)
        for (size_t b = 0; b < sizeof ns / sizeof ns[0]; b++) strided(ks[a], ns[b]);
    CHECK(avra_mem_live() == live, "every strided list freed leaves the live count where it began", 0, 0);
    CHECK(refused(past_end, "index 4 is out of bounds (length 4)"), "an index past the end traps in elements", 3, 4);
    CHECK(refused(below_zero, "index -1 is out of bounds (length 4)"), "an index below zero traps in elements", 3, 4);
    CHECK(refused(popped_empty, "pop on an empty list"), "a pop of an empty strided list traps", 2, 0);
    CHECK(refused(two_strides, "read at two strides"), "the guard's check refuses a box read at two strides", 2, 6);
    CHECK(refused(part_of_one, "part of an element"), "the guard's check refuses a box holding part of an element", 3, 2);
    CHECK(!refused(one_stride, "defect"), "one box read again at its own stride stands", 2, 6);
    printf("stride_list_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

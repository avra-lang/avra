// A DYING LIST RELEASES EXACTLY ITS OWNED CELLS: every length from the empty list to 33, every
// pattern of owned and plain cells for the short lengths and the edge patterns for the long ones,
// in a list whose cells lie in its box and in one whose cells grew into a buffer of their own. The
// scan reads the marks a word at a time, so the lengths around a word (7, 8, 9, 15, 16, 17) and a
// tail that ends inside a word are where it would read past the marks or miss a cell. Each cell
// holds a text box counted once more than it is owned elsewhere, so a release the list owes and does
// not make, or makes twice, or makes for a plain cell, moves a count the check reads.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../avra_runtime.h"
#include "../avra_box.h"

const char* avra_int_text(int64_t v);
void* avra_array_new(void);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what, n, pat) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "reclaim_marks_test: FAILED %s (n %d, pattern %llx, %s:%d)\n", what, n, (unsigned long long)(pat), __FILE__, __LINE__); } } while (0)

static int32_t rc_of(const void* p) { return ((const Header*)p - 1)->rc; }

// A list of `n` cells, cell `i` owned where bit `i` of `pattern` is set, each cell a text of its own
// held once by `held`; laid in the box, or grown into a buffer of its own.
static void one(int n, uint64_t pattern, int laid) {
    const char* held[40];
    for (int i = 0; i < n; i++) held[i] = avra_int_text(1000 + i);
    void* list = laid ? avra_array_sized(n) : avra_array_new();
    for (int i = 0; i < n; i++) {
        if ((pattern >> i) & 1) avra_array_push_owned(list, (void*)held[i]);
        else avra_array_push(list, (int64_t)(uintptr_t)held[i]);
    }
    for (int i = 0; i < n; i++)
        CHECK(rc_of(held[i]) == (((pattern >> i) & 1) ? 2 : 1), "a cell counted as it was pushed", n, pattern);
    avra_rc_release(list);
    for (int i = 0; i < n; i++) CHECK(rc_of(held[i]) == 1, "the dying list released exactly its owned cells", n, pattern);
    for (int i = 0; i < n; i++) avra_rc_release((void*)held[i]);
}

int main(void) {
    int64_t live = avra_mem_live();
    for (int laid = 0; laid < 2; laid++) {
        for (int n = 0; n <= 33; n++) {
            if (n <= 12) {
                for (uint64_t p = 0; p < ((uint64_t)1 << n); p++) one(n, p, laid);
            } else {
                uint64_t all = ((uint64_t)1 << n) - 1;
                one(n, 0, laid);
                one(n, all, laid);
                one(n, 0x5555555555555555ull & all, laid);
                one(n, 0xAAAAAAAAAAAAAAAAull & all, laid);
                for (int i = 0; i < n; i++) {
                    one(n, (uint64_t)1 << i, laid);
                    one(n, all & ~((uint64_t)1 << i), laid);
                }
            }
        }
    }
    CHECK(avra_mem_live() == live, "every list and text freed leaves the live count where it began", 0, 0);
    printf("reclaim_marks_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

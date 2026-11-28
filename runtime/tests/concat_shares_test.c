// A CONCAT WITH ONE SIDE EMPTY ANSWERS THE OTHER SIDE'S OWN BOX, one reference more, and its reusing
// twin passes its consumed side through or trades it for the other; with both sides full it answers a
// fresh list, and with both empty the one empty list. Every answer, released, leaves the live count
// where it began.
#include <stdint.h>
#include <stdio.h>

#include "../avra_runtime.h"

void* avra_array_concat(void* a, void* b);
void* avra_array_concat_reusing(void* a, void* b);
void* avra_array_empty_words(void);
int64_t avra_array_len(void* arr);
int64_t avra_array_get(void* arr, int64_t i);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "concat_shares_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// A list of the words `n` .. `n + k - 1`.
static void* words(int64_t n, int64_t k) {
    void* xs = avra_array_sized(k);
    for (int64_t i = 0; i < k; i++) avra_array_push(xs, n + i);
    return xs;
}

int main(void) {
    int64_t live = avra_mem_live();

    void* a = words(1, 2);
    void* none = avra_array_sized(0);
    void* left = avra_array_concat(a, none);
    CHECK(left == a, "an empty right side answers the left side's own box");
    void* right = avra_array_concat(none, a);
    CHECK(right == a, "an empty left side answers the right side's own box");
    avra_rc_release(left);
    avra_rc_release(right);
    CHECK(avra_array_len(a) == 2 && avra_array_get(a, 1) == 2, "the shared side keeps its slots once its answers are released");

    void* both = avra_array_concat(a, a);
    CHECK(both != a && avra_array_len(both) == 4, "two full sides make a fresh list of both");
    avra_rc_release(both);

    void* empty = avra_array_concat(none, avra_array_empty_words());
    CHECK(avra_array_len(empty) == 0, "two empty sides answer an empty list");
    avra_rc_release(empty);

    void* consumed = words(5, 1);
    void* passed = avra_array_concat_reusing(consumed, none);
    CHECK(passed == consumed && avra_array_len(passed) == 1, "the reusing twin passes its consumed side through when the other is empty");
    avra_rc_release(passed);

    void* emptied = avra_array_sized(0);
    void* traded = avra_array_concat_reusing(emptied, a);
    CHECK(traded == a, "the reusing twin trades an empty consumed side for the other side's box");
    avra_rc_release(traded);

    avra_rc_release(none);
    avra_rc_release(a);
    CHECK(avra_mem_live() == live, "every answer, released, leaves the live count where it began");

    fprintf(stderr, "concat_shares_test: %d/%d checks passed\n", g_checks - g_fails, g_checks);
    return g_fails == 0 ? 0 : 1;
}

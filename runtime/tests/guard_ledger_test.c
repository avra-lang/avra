// A BOX THE GUARD KEEPS IS FREED TO EVERY LEDGER. Under AVRA_RC_GUARD a
// box at rc 0 is kept, marked dead and poisoned so a stale read traps —
// but its bytes leave the live count, as its reclaim would take them,
// or a settlement's budget reads a guarded run as holding everything it
// ever made and refuses a program an unguarded run accepts.
#include <stdio.h>
#include <string.h>

#include "../avra_runtime.h"

extern int avra_rc_guard_on;
const char* avra_int_text(int64_t v);
const char* avra_str_concat(const char* a, const char* b);
const char* avra_str_concat_reusing(const char* a, const char* b);
void* avra_array_new(void);
void* avra_map_new(void);
void avra_map_set_owned(void* map, const char* key, void* v);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "guard_ledger_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

int main(void) {
    avra_rc_guard_on = 1;

    int64_t live = avra_mem_live();
    for (int64_t i = 0; i < 1000; i++) avra_rc_release((void*)avra_int_text(i * 7919));
    CHECK(avra_mem_live() == live, "a text the guard keeps leaves the live count");

    live = avra_mem_live();
    void* xs = avra_array_new();
    for (int64_t i = 0; i < 100; i++) avra_array_push(xs, i);
    avra_rc_release(xs);
    CHECK(avra_mem_live() == live, "a list the guard keeps leaves the live count, its cells' buffer with it");

    live = avra_mem_live();
    void* outer = avra_array_new();
    for (int64_t i = 0; i < 10; i++) {
        // the list takes a reference of its own; ours is released
        const char* t = avra_int_text(i);
        avra_array_push_owned(outer, (void*)t);
        avra_rc_release((void*)t);
    }
    avra_rc_release(outer);
    CHECK(avra_mem_live() == live, "a list's owned texts are released with it and leave the count");

    live = avra_mem_live();
    void* m = avra_map_new();
    for (int64_t i = 0; i < 20; i++) {
        const char* k = avra_int_text(i);
        const char* v = avra_int_text(i * 3);
        avra_map_set_owned(m, k, (void*)v);
        avra_rc_release((void*)k);
        avra_rc_release((void*)v);
    }
    avra_rc_release(m);
    CHECK(avra_mem_live() == live, "a map the guard keeps leaves the count, its keys, values and index with it");

    live = avra_mem_live();
    const char* s = avra_int_text(1);
    for (int i = 0; i < 50; i++) {
        const char* longer = avra_str_concat(s, "abcdefgh");
        avra_rc_release((void*)s);
        s = longer;
    }
    avra_rc_release((void*)s);
    CHECK(avra_mem_live() == live, "a text grown and released under the guard leaves the count");

    live = avra_mem_live();
    const char* grown = avra_int_text(1);
    for (int i = 0; i < 50; i++) grown = avra_str_concat_reusing(grown, "abcdefgh");
    avra_rc_release((void*)grown);
    CHECK(avra_mem_live() == live, "a text grown in place moves under the guard and its old box leaves the count");

    printf("guard ledger: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

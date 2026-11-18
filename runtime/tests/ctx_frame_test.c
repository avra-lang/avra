// THE CONTEXTS A TASK RUNS UNDER: a read answers the cell the nearest set
// still in force gave its key, or NULL; a set makes the next frame and a
// back takes it to the one it replaced, so nested sets unwind in order and
// every frame and cell is released once nothing holds it; a trap a guard
// catches puts back the frame the guard was entered under.
#include <stdio.h>
#include <stdint.h>

#include "../avra_runtime.h"

void* avra_array_new(void);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "ctx_frame_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

enum { DEPTH = 11, WIDTH = 22 };

// A read, its reference released: whether it answered `want`.
static int reads(int64_t key, void* want) {
    void* got = avra_ctx_read(key);
    avra_rc_release(got);
    return got == want;
}

// The guarded body: two sets, then a trap with neither block ended.
static _Bool trapping(void* box) {
    (void)box;
    void* a = avra_array_new();
    void* b = avra_array_new();
    avra_ctx_set(DEPTH, a);
    avra_ctx_set(WIDTH, b);
    avra_rc_release(a);
    avra_rc_release(b);
    avra_trap("ctx_frame_test: a trap under two sets");
}

// The guarded body that ends: a set, and its block's end.
static _Bool ending(void* box) {
    (void)box;
    void* a = avra_array_new();
    avra_ctx_set(DEPTH, a);
    avra_rc_release(a);
    avra_ctx_back();
    return 1;
}

// A body box for the guard: its code in the first slot.
static void* body_of(_Bool (*code)(void*)) {
    void* box = avra_array_new();
    avra_array_push(box, (int64_t)(uintptr_t)code);
    return box;
}

int main(void) {
    int64_t live = avra_mem_live();

    CHECK(avra_ctx_read(DEPTH) == NULL, "a key nothing set reads as nothing");
    avra_ctx_back();
    CHECK(avra_ctx_read(DEPTH) == NULL, "a back with nothing set leaves nothing set");

    void* a = avra_array_new();
    void* b = avra_array_new();
    void* c = avra_array_new();
    avra_ctx_set(DEPTH, a);
    CHECK(reads(DEPTH, a), "a set reaches a read of its key");
    CHECK(avra_ctx_read(WIDTH) == NULL, "and no other key");
    avra_ctx_set(WIDTH, b);
    CHECK(reads(DEPTH, a) && reads(WIDTH, b), "a second key's set keeps the first");
    avra_ctx_set(DEPTH, c);
    CHECK(reads(DEPTH, c) && reads(WIDTH, b), "a set of a key already set shadows it");
    avra_ctx_back();
    CHECK(reads(DEPTH, a) && reads(WIDTH, b), "its back uncovers the set below");
    avra_ctx_back();
    CHECK(reads(DEPTH, a) && avra_ctx_read(WIDTH) == NULL, "each back takes one set");
    avra_ctx_back();
    CHECK(avra_ctx_read(DEPTH) == NULL, "the last back leaves nothing set");
    avra_rc_release(a);
    avra_rc_release(b);
    avra_rc_release(c);
    CHECK(avra_mem_live() == live, "every frame and cell is released once nothing holds it");

    void* outer = avra_array_new();
    avra_ctx_set(DEPTH, outer);
    avra_rc_release(outer);
    void* body = body_of(trapping);
    CHECK(avra_guard_run(body) == 1, "the guard catches the trap");
    CHECK(reads(DEPTH, outer) && avra_ctx_read(WIDTH) == NULL, "and the frame it was entered under is back");
    avra_rc_release(body);
    body = body_of(ending);
    CHECK(avra_guard_run(body) == 0, "a guarded body that ends answers 0");
    CHECK(reads(DEPTH, outer), "and leaves the frame it found");
    avra_rc_release(body);
    avra_ctx_back();
    CHECK(avra_ctx_read(DEPTH) == NULL, "the outer set's back leaves nothing set");
    CHECK(avra_mem_live() == live, "a caught trap's frames are released with the rest");

    if (g_fails) {
        fprintf(stderr, "ctx_frame_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("ctx_frame_test: %d checks passed\n", g_checks);
    return 0;
}

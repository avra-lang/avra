// A SLOT TAKEN hands its box out with the slot's own reference and leaves the slot empty, so the write
// that follows releases nothing; a slot holding no reference of its own answers a retained read and
// stands. Every box, released, leaves the live count where it began.
#include <stdint.h>
#include <stdio.h>

#include "../avra_runtime.h"

void* avra_slot_taken(void* arr, int64_t i);
void avra_array_push_owned(void* arr, void* v);
void avra_slot_set_owned(void* arr, int64_t i, void* v);
int64_t avra_array_get(void* arr, int64_t i);
int64_t avra_array_len(void* arr);
void* avra_array_sized_words(int64_t n);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "slot_taken_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

int main(void) {
    int64_t live = avra_mem_live();

    void* outer = avra_array_sized(2);
    void* inner = avra_array_sized(1);
    avra_array_push(inner, 7);
    avra_array_push_owned(outer, inner);
    avra_rc_release(inner);
    void* taken = avra_slot_taken(outer, 0);
    CHECK(taken == inner, "the slot's own box is handed out");
    CHECK(avra_array_get(outer, 0) == 0, "the slot is left empty");
    avra_slot_set_owned(outer, 0, taken);
    avra_rc_release(taken);
    CHECK((void*)(uintptr_t)avra_array_get(outer, 0) == inner && avra_array_len(inner) == 1, "the write that follows stores it and releases nothing");

    void* words = avra_array_sized_words(1);
    avra_array_push(words, 42);
    void* word = avra_slot_taken(words, 0);
    CHECK((int64_t)(uintptr_t)word == 42 && avra_array_get(words, 0) == 42, "a slot of words is read and stands");

    avra_rc_release(words);
    avra_rc_release(outer);
    CHECK(avra_mem_live() == live, "every box, released, leaves the live count where it began");

    fprintf(stderr, "slot_taken_test: %d/%d checks passed\n", g_checks - g_fails, g_checks);
    return g_fails == 0 ? 0 : 1;
}

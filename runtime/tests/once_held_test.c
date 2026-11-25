// WHAT A CACHE HOLDS IS NOT OWED: a `once` answer filled after it is
// cached — a record whose cell holds a list pushed ask by ask — reads as
// nothing still owed, while a box nobody holds still reads as owed.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../avra_runtime.h"
#include "../avra_box.h"

void avra_once_set(void* key, void* value);
void* avra_array_new(void);
void avra_slot_set_owned(void* arr, int64_t i, void* v);
const char* avra_int_text(int64_t v);

// A list baked as the backend bakes a const's: its header immortal from
// the start, its one cell laid after it, never counted by the ledger.
static struct {
    Header h;
    AvraArray a;
    int64_t cells[1];
    uint8_t marks[8];
} __attribute__((aligned(16))) g_baked = {
    { AVRA_TAG, KIND_IMMORTAL(KIND_ARRAY), 1, sizeof(AvraArray) },
    { 1, 1, NULL, NULL, NULL },
    { 7 },
    { 0 },
};

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "once_held_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

int main(void) {
    int64_t owed = avra_mem_owed();
    CHECK(avra_mem_owed() == owed, "nothing made, nothing owed");

    // a record of one field, a cell, the cell holding a list: cached first, filled after
    void* list = avra_array_new();
    void* cell = avra_array_new();
    avra_array_push_owned(cell, list);
    avra_rc_release(list);
    void* record = avra_array_new();
    avra_array_push_owned(record, cell);
    avra_rc_release(cell);
    avra_once_set("once_held_test.record", record);
    avra_rc_release(record);
    CHECK(avra_mem_owed() == owed, "an answer cached holds what it was made of");

    for (int64_t i = 0; i < 1000; i++) {
        const char* text = avra_int_text(i * 7919);
        avra_array_push_owned(list, (void*)text);
        avra_rc_release((void*)text);
    }
    CHECK(avra_mem_owed() == owed, "a list filled after its cache was set is held, not owed");

    const char* replaced = avra_int_text(42);
    avra_slot_set_owned(cell, 0, (void*)replaced);
    avra_rc_release((void*)replaced);
    CHECK(avra_mem_owed() == owed, "a cache's field replaced: the old list is freed, the new value held");

    const char* loose = avra_int_text(123456789);
    CHECK(avra_mem_owed() > owed, "a text nobody holds is owed");
    avra_rc_release((void*)loose);
    CHECK(avra_mem_owed() == owed, "and owed no more once released");

    void* outer = avra_array_new();
    void* inner = avra_array_new();
    avra_array_push_owned(outer, inner);
    avra_rc_release(inner);
    avra_once_set("once_held_test.nested", outer);
    avra_rc_release(outer);
    for (int64_t i = 0; i < 100; i++) {
        const char* text = avra_int_text(i);
        avra_array_push_owned(inner, (void*)text);
        avra_rc_release((void*)text);
    }
    CHECK(avra_mem_owed() == owed, "a list inside a cached list, filled after, is held");

    g_baked.a.data = g_baked.cells;
    g_baked.a.marks = g_baked.marks;
    void* baked = &g_baked.a;
    avra_once_set("once_held_test.baked", baked);
    CHECK(avra_mem_owed() == owed, "a baked const cached is credited as nothing: the ledger never counted it");
    void* holder = avra_array_new();
    avra_array_push_owned(holder, baked);
    avra_once_set("once_held_test.holder", holder);
    avra_rc_release(holder);
    CHECK(avra_mem_owed() == owed, "a baked const a cached list holds is credited as nothing");

    printf("once held: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

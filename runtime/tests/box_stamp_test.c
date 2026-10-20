// A BOX A SITE HAS READ IS LOGGED ONCE PER TURN WHENEVER IT IS WRITTEN: the
// first write stamps it and files it, later writes that turn only compare,
// and a turn that wrote nothing logs nothing. The cases begin with the empty
// one (nothing observed, nothing logged) and reach the stamp's wrap.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../avra_box.h"
#include "../avra_runtime.h"

int64_t avra_box_observe(void* p);
int64_t avra_box_key(void* p);
int64_t avra_box_unobserve(void* p);
int64_t avra_turn_next(void);
void* avra_changes_take(void);
void* avra_array_new(void);
void avra_array_push(void* arr, int64_t v);
void avra_slot_set(void* arr, int64_t i, int64_t v);
void* avra_slot_unique(void* arr, int64_t i);
int64_t avra_array_len(void* arr);
int64_t avra_array_get(void* arr, int64_t i);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "box_stamp_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// The boxes the turn wrote, as a count; the list is released.
static int64_t taken(void) {
    void* log = avra_changes_take();
    int64_t n = avra_array_len(log);
    avra_rc_release(log);
    return n;
}

static void* cell(int64_t v) {
    void* c = avra_array_new();
    avra_array_push(c, v);
    return c;
}

int main(void) {
    int64_t live = avra_mem_live();
    CHECK(taken() == 0, "an untouched runtime has an empty log");

    void* quiet = cell(1);
    avra_turn_next();
    avra_slot_set(quiet, 0, 2);
    CHECK(taken() == 0, "a box nobody observes is never logged");

    void* seen = cell(1);
    CHECK(avra_box_observe(seen) == 1, "a box can be observed");
    avra_turn_next();
    CHECK(taken() == 0, "observing writes nothing, so the turn logs nothing");
    avra_slot_set(seen, 0, 2);
    avra_slot_set(seen, 0, 3);
    avra_slot_set(seen, 0, 4);
    CHECK(taken() == 1, "three writes in a turn log the box once");
    CHECK(taken() == 0, "taking the log empties it");

    avra_turn_next();
    avra_slot_set(seen, 0, 5);
    CHECK(taken() == 1, "the next turn's first write logs it again");

    avra_turn_next();
    CHECK(taken() == 0, "a turn that wrote nothing logs nothing");

    avra_turn_next();
    for (int64_t i = 0; i < (1LL << 24) + 1; i++) avra_slot_set(seen, 0, i);
    CHECK(taken() == 1, "2^24 + 1 writes between two looks are seen, as one box");

    avra_turn_next();
    void* inner = cell(7);
    avra_slot_set(quiet, 0, (int64_t)(uintptr_t)inner);
    avra_box_observe(quiet);
    avra_turn_next();
    avra_slot_unique(quiet, 0);
    CHECK(taken() == 1, "opening a slot for writing logs its holder");

    void* laid = cell(1);
    ((Header*)laid - 1)->kind_word = (int32_t)0xFFFFFF01u;
    avra_turn_next();
    avra_slot_set(laid, 0, 2);
    CHECK(taken() == 0, "a box laid out by the backend (every flag set) is never logged");
    ((Header*)laid - 1)->kind_word = 1;
    avra_rc_release(laid);

    // A `once` answer lives for the process and is the runtime's own to mark: a
    // top-level state's cell is one, and it can be observed.
    void* forever = cell(1);
    ((Header*)forever - 1)->kind_word = (int32_t)(-5 & 0xFF);
    CHECK(avra_box_observe(forever) == 1, "a box that lives for the process can be observed");
    avra_turn_next();
    avra_slot_set(forever, 0, 2);
    CHECK(taken() == 1, "and a write to it is logged");
    CHECK(avra_box_unobserve(forever) == 1, "and let go");
    ((Header*)forever - 1)->kind_word = 1;
    avra_rc_release(forever);

    avra_box_unobserve(seen);
    avra_turn_next();
    avra_slot_set(seen, 0, 9);
    CHECK(taken() == 0, "a box no site reads any more is not logged");

    avra_box_observe(seen);
    int wraps = 0;
    for (int i = 0; i < 70000; i++) {
        if (avra_turn_next()) { wraps++; avra_box_observe(seen); }
        if (i % 9000 == 0) { avra_slot_set(seen, 0, i); CHECK(taken() == 1, "a write is logged across the wrap"); }
        else taken();
    }
    CHECK(wraps == 1, "the stamp wraps once in 70000 turns and says so");

    // THE OBSERVER HOLDS WHAT IT OBSERVES: the owner lets go while a site still
    // names the box, and the box stands until the site does.
    int64_t before = avra_mem_live();
    void* kept = cell(1);
    avra_box_observe(kept);
    avra_box_observe(kept);
    int64_t key = avra_box_key(kept);
    avra_rc_release(kept);
    CHECK(avra_mem_live() > before, "an observed box outlives its owner's release");
    avra_turn_next();
    avra_slot_set(kept, 0, 5);
    void* log = avra_changes_take();
    CHECK(avra_array_len(log) == 1 && avra_array_get(log, 0) == key, "a write after the owner let go still files the box's key");
    avra_rc_release(log);
    CHECK(avra_box_unobserve(kept) == 1, "the site lets the box go");
    CHECK(avra_mem_live() == before, "observing twice held it once, and the last unobserve frees it");
    CHECK(avra_box_unobserve(seen) == 1 && avra_box_unobserve(seen) == 0, "unobserving a box not observed leaves it alone");
    CHECK(avra_box_key((void*)16) == 0 && avra_box_key(seen) != 0, "a key names a box and nothing else");

    void* laid_again = cell(1);
    ((Header*)laid_again - 1)->kind_word = (int32_t)0xFFFFFF01u;
    CHECK(avra_box_observe(laid_again) == 0, "a box laid out by the backend is not observed");
    ((Header*)laid_again - 1)->kind_word = 1;
    avra_rc_release(laid_again);

    CHECK(avra_box_observe((void*)16) == 0 && avra_box_observe(NULL) == 0, "a pointer that is not a box is not observed");

    avra_box_unobserve(quiet);
    avra_rc_release(seen);
    avra_rc_release(quiet);
    avra_rc_release(inner);
    CHECK(avra_mem_live() == live, "the boxes, logged and released, leave the live count where it began");

    printf("box_stamp_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

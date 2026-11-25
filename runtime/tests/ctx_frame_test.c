// THE CONTEXTS A TASK RUNS UNDER: a read answers the cell the nearest set
// still in force gave its key, or NULL; a set makes the next frame and a
// back takes it to the one it replaced, so nested sets unwind in order and
// every frame and cell is released once nothing holds it; a trap a guard
// catches puts back the frame the guard was entered under.
#include <stdio.h>
#include <stdint.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
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

typedef void* (*Code)(void*);

// A task's body: it sets its own key to a cell of its own, yields so the
// other task runs, then answers whether its read still finds its cell and
// the other task's key reads as nothing; and the frame it started under.
static void* tasked(void* box) {
    int64_t mine = ((AvraArray*)box)->data[1];
    int64_t theirs = mine == DEPTH ? WIDTH : DEPTH;
    void* started = avra_ctx_frame();
    void* cell = avra_array_new();
    avra_ctx_set(mine, cell);
    avra_fiber_yield();
    void* got = avra_ctx_read(mine);
    void* other = avra_ctx_read(theirs);
    int64_t held = got == cell && other == NULL && started == NULL && avra_ctx_now != NULL;
    avra_rc_release(got);
    avra_rc_release(other);
    avra_rc_release(cell);
    avra_ctx_back();
    void* r = avra_array_sized(1);
    avra_array_push(r, held);
    return r;
}

// A task whose body is `tasked`, over the key `key`.
static void* spawned(int64_t key) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)(Code)tasked);
    avra_array_push(body, key);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}

// Whether the task `task` answered that its frame held across the switch.
static int held_across(void* task) {
    void* r = avra_task_join(task);
    int ok = ((AvraArray*)r)->data[0] == 1;
    avra_rc_release(r);
    avra_rc_release(task);
    return ok;
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

    // THE FRAME A BODY IS MADE UNDER: entering the one in force changes
    // nothing; entering another makes its contexts the ones in force, none
    // of the caller's among them, and its back puts the caller's back.
    live = avra_mem_live();
    CHECK(avra_ctx_frame() == NULL && avra_ctx_now == NULL, "with nothing set the frame is none");
    CHECK(avra_ctx_enter(NULL) == 0, "entering the frame in force changes nothing");
    void* d = avra_array_new();
    avra_ctx_set(DEPTH, d);
    avra_rc_release(d);
    void* made = avra_ctx_frame();
    CHECK(made == avra_ctx_now && made != NULL, "the frame is the one in force");
    CHECK(avra_ctx_enter(made) == 0, "entering the frame in force, set, changes nothing");
    avra_ctx_back();
    void* w = avra_array_new();
    avra_ctx_set(WIDTH, w);
    avra_rc_release(w);
    CHECK(avra_ctx_enter(made) == 1, "entering another frame is a change");
    CHECK(reads(DEPTH, d) && reads(WIDTH, w), "its contexts are laid over the caller's: what it set, and what the caller set that it didn't");
    avra_ctx_back();
    CHECK(avra_ctx_read(DEPTH) == NULL && reads(WIDTH, w), "its back puts the caller's frame back");
    void* d2 = avra_array_new();
    avra_ctx_set(DEPTH, d2);
    avra_rc_release(d2);
    CHECK(avra_ctx_enter(made) == 1 && reads(DEPTH, d) && reads(WIDTH, w), "a context both set reads as the made frame set it");
    avra_ctx_back();
    CHECK(reads(DEPTH, d2), "and the caller's again after its back");
    avra_ctx_back();
    CHECK(avra_ctx_enter(NULL) == 1, "entering the empty frame over a set one is a change");
    CHECK(reads(WIDTH, w), "and the caller's contexts still read under it");
    avra_ctx_back();
    avra_ctx_back();

    // A BOX MADE UNDER ANOTHER FRAME: the same box where its frame is the
    // one asked; else a copy, the frame in its slot and the rest its own.
    // Only a slot marked as the box's frame is one.
    void* code_only = avra_array_sized(1);
    avra_array_push(code_only, 7);
    void* same = avra_ctx_reframed(code_only, 1, made);
    CHECK(same == code_only, "a box with no frame's slot is the same box");
    avra_rc_release(same);
    void* lane = avra_array_new();
    void* framed = avra_array_sized(3);
    avra_array_push(framed, 7);
    avra_ctx_frame_pushed(framed);
    avra_array_push_owned(framed, lane);
    avra_rc_release(lane);
    void* again = avra_ctx_reframed(framed, 1, NULL);
    CHECK(again == framed, "a box made under the frame asked is the same box");
    avra_rc_release(again);
    void* moved = avra_ctx_reframed(framed, 1, made);
    CHECK(moved != framed && ((AvraArray*)moved)->data[1] == (int64_t)(uintptr_t)made, "else a copy holds the frame");
    CHECK(((AvraArray*)moved)->data[2] == (int64_t)(uintptr_t)lane && ((AvraArray*)moved)->data[0] == 7, "and the rest of the box");
    avra_rc_release(moved);
    avra_rc_release(framed);
    avra_rc_release(code_only);

    // A CLOSURE THAT CARRIES NO FRAME: its first lane stands where a frame
    // would, and is no frame, so a reframe answers the box untouched.
    void* captured = avra_array_new();
    void* unframed = avra_array_sized(3);
    avra_array_push(unframed, 7);
    avra_array_push(unframed, 42);
    avra_array_push_owned(unframed, captured);
    void* untouched = avra_ctx_reframed(unframed, 1, made);
    CHECK(untouched == unframed && ((AvraArray*)unframed)->data[1] == 42, "a reframe of a closure that carries no frame answers the box untouched");
    avra_rc_release(untouched);
    void* untouched_lane = avra_ctx_reframed(unframed, 2, made);
    CHECK(untouched_lane == unframed && ((AvraArray*)unframed)->data[2] == (int64_t)(uintptr_t)captured, "and so does one of an owned lane");
    avra_rc_release(untouched_lane);
    avra_rc_release(unframed);
    avra_rc_release(captured);

    // A FRAME PUSHED UNDER A SET: the box holds the frame in force.
    void* e = avra_array_new();
    avra_ctx_set(DEPTH, e);
    avra_rc_release(e);
    void* under = avra_array_sized(2);
    avra_array_push(under, 7);
    avra_ctx_frame_pushed(under);
    CHECK(((AvraArray*)under)->data[1] == (int64_t)(uintptr_t)avra_ctx_now, "a frame pushed under a set is the frame in force");
    void* still = avra_ctx_reframed(under, 1, avra_ctx_now);
    CHECK(still == under, "and a reframe to it changes nothing");
    avra_rc_release(still);
    avra_ctx_back();
    avra_rc_release(under);

    // A BOX WHOSE FRAME IS ANOTHER SLOT: a value boxed with its table, the
    // frame after them; the value is shared by the copy, never moved.
    void* held = avra_array_new();
    void* boxed = avra_array_sized(3);
    avra_array_push_owned(boxed, held);
    avra_rc_release(held);
    avra_array_push(boxed, 9);
    avra_ctx_frame_pushed(boxed);
    void* unslotted = avra_ctx_reframed(boxed, 3, made);
    CHECK(unslotted == boxed, "a box with no slot where its frame would be is the same box");
    avra_rc_release(unslotted);
    void* stamped = avra_ctx_reframed(boxed, 2, made);
    CHECK(stamped != boxed && ((AvraArray*)stamped)->data[2] == (int64_t)(uintptr_t)made, "a box under no frame, asked another, is a copy holding it in that slot");
    CHECK(((AvraArray*)stamped)->data[0] == (int64_t)(uintptr_t)held && ((AvraArray*)stamped)->data[1] == 9, "and its value and table");
    void* kept = avra_ctx_reframed(stamped, 2, made);
    CHECK(kept == stamped, "a box stamped with the frame asked is the same box");
    avra_rc_release(kept);
    void* cleared = avra_ctx_reframed(stamped, 2, NULL);
    CHECK(cleared != stamped && ((AvraArray*)cleared)->data[2] == 0 && ((AvraArray*)cleared)->data[0] == (int64_t)(uintptr_t)held, "a stamped box asked no frame is a copy holding none");
    avra_rc_release(cleared);
    avra_rc_release(stamped);
    avra_rc_release(boxed);
    avra_rc_release(made);
    CHECK(avra_mem_live() == live, "frames, boxes and cells are released once nothing holds them");

    // EACH TASK RUNS UNDER ITS OWN FRAME: a switch makes the next task's
    // frame the one in force, and a task starts from none.
    void* one = spawned(DEPTH);
    void* two = spawned(WIDTH);
    CHECK(held_across(one) && held_across(two), "each task reads its own set across the switch, from no frame of its parent's");
    CHECK(avra_ctx_now == NULL && avra_ctx_read(DEPTH) == NULL, "and the parent's frame is its own after them");

    // WHAT A RUNNING QUERY HEARS: one word a read tests, NULL with no query
    // open; a recording opened and closed around a body files each read —
    // a set's value by its word, a default apart from every set — and holds
    // while the frame in force holds the same values; a closed recording
    // is heard by the one open around it, as a reused answer's is.
    CHECK(avra_ctx_heard_now == NULL, "with no query open the word a read tests is NULL");
    avra_ctx_listen();
    CHECK(avra_ctx_heard_now != NULL, "a query open sets it");
    CHECK(avra_ctx_listened() == NULL && avra_ctx_heard_now == NULL, "a body that read no context hears nothing, and the word is NULL same_ten");
    int64_t heard_live = avra_mem_live();
    void* ten = avra_array_new();
    avra_array_push(ten, 10);
    avra_ctx_set(DEPTH, ten);
    avra_ctx_listen();
    avra_ctx_heard(DEPTH, 0, ten);
    avra_ctx_heard(WIDTH, 0, NULL);
    void* heard = avra_ctx_listened();
    CHECK(heard && ((AvraArray*)heard)->len == 6, "two reads are two triples");
    CHECK(avra_ctx_holds(heard) == 1, "they hold under the frame they were heard under");
    avra_ctx_back();
    CHECK(avra_ctx_holds(heard) == 0, "and not once the set is gone");
    void* same_ten = avra_array_new();
    avra_array_push(same_ten, 10);
    avra_ctx_set(DEPTH, same_ten);
    CHECK(avra_ctx_holds(heard) == 1, "a later set of the same value holds them");
    avra_ctx_back();
    void* other = avra_array_new();
    avra_array_push(other, 11);
    avra_ctx_set(DEPTH, other);
    CHECK(avra_ctx_holds(heard) == 0, "a set of another value does not");
    avra_ctx_set(WIDTH, same_ten);
    avra_ctx_back();
    avra_ctx_back();
    avra_ctx_set(DEPTH, ten);
    avra_ctx_set(WIDTH, same_ten);
    CHECK(avra_ctx_holds(heard) == 0, "nor does a set where a default was heard");
    avra_ctx_back();
    avra_ctx_listen();
    avra_ctx_listen();
    avra_ctx_heard(DEPTH, 0, ten);
    void* inner = avra_ctx_listened();
    void* around = avra_ctx_listened();
    CHECK(inner && around && ((AvraArray*)around)->len == 3, "what an inner query heard the one around it heard too");
    avra_ctx_listen();
    avra_ctx_reheard(inner);
    void* reused = avra_ctx_listened();
    CHECK(reused && ((AvraArray*)reused)->len == 3, "and so is what a reused answer heard");
    avra_ctx_listen();
    avra_ctx_heard(DEPTH, 2, ten);
    void* untold = avra_ctx_listened();
    CHECK(avra_ctx_holds(untold) == 0, "a value told apart by nothing never holds");
    avra_ctx_back();
    avra_ctx_heard_drop(heard);
    avra_ctx_heard_drop(inner);
    avra_ctx_heard_drop(around);
    avra_ctx_heard_drop(reused);
    avra_ctx_heard_drop(untold);
    avra_rc_release(ten);
    avra_rc_release(same_ten);
    avra_rc_release(other);
    CHECK(avra_mem_live() == heard_live, "every recording a cell let go is released");

    if (g_fails) {
        fprintf(stderr, "ctx_frame_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("ctx_frame_test: %d checks passed\n", g_checks);
    return 0;
}

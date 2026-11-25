// A task handle's release as a join point: `avra_task_release` joins a
// running task only when the handle is the last outside the scheduler, and
// `avra_tasks_release` joins a list's members only when the list is released
// by its last handle. Driven through the rows as compiled code drives them.
#include <stdio.h>
#include <stdlib.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;

#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "task_release_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

typedef void* (*Code)(void*);

static void* answer(int64_t v) {
    void* r = avra_array_sized(1);
    avra_array_push(r, v);
    return r;
}

static int g_ran = 0;

// A body that yields twice before it ends, so it is running when its spawner releases.
static void* lingers(void* self) {
    (void)self;
    avra_fiber_yield();
    avra_fiber_yield();
    g_ran++;
    return answer(7);
}

static void* spawned(void) {
    void* body = avra_array_sized(1);
    avra_array_push(body, (int64_t)(uintptr_t)(Code)lingers);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}

static int32_t rc_of(void* p) { return ((const Header*)p - 1)->rc; }

int main(void) {
    // the last handle: releasing it joins the running task
    g_ran = 0;
    void* last = spawned();
    CHECK(!avra_task_done(last), "a spawned task has not run before the spawner waits");
    CHECK(rc_of(last) == 2, "a running task holds the handle and the scheduler's own reference");
    avra_task_release(last);
    CHECK(avra_task_done(last) && g_ran == 1, "the last handle's release joined the task");
    avra_rc_release(last);

    // a second handle: the first release joins nothing
    g_ran = 0;
    void* shared = spawned();
    avra_rc_retain(shared);
    CHECK(rc_of(shared) == 3, "a copy is a third reference");
    avra_task_release(shared);
    CHECK(!avra_task_done(shared) && g_ran == 0, "a handle that is not the last joins nothing");
    avra_rc_release(shared);
    avra_task_release(shared);
    CHECK(avra_task_done(shared) && g_ran == 1, "the last of two handles joined it");
    avra_rc_release(shared);

    // an ended task: the release joins nothing and breaks nothing
    void* ended = spawned();
    void* r = avra_task_join(ended);
    avra_rc_release(r);
    CHECK(avra_task_done(ended), "the task ended");
    avra_task_release(ended);
    CHECK(avra_task_done(ended), "an ended task's release is free");
    avra_rc_release(ended);

    // an ended task that still has two handles: the release is as free
    void* twice = spawned();
    avra_rc_retain(twice);
    void* answered = avra_task_join(twice);
    avra_rc_release(answered);
    CHECK(rc_of(twice) == 2 && avra_task_done(twice), "an ended task keeps only its handles");
    avra_task_release(twice);
    CHECK(avra_task_done(twice), "an ended task with two handles joins nothing");
    avra_rc_release(twice);
    avra_rc_release(twice);

    // a list released by its last handle joins each member
    g_ran = 0;
    void* list = avra_array_sized(2);
    avra_tasks_push(list, spawned());
    avra_tasks_push(list, spawned());
    avra_tasks_release(list);
    CHECK(g_ran == 2, "a list's last release joined both members");
    avra_rc_release(list);

    // a list with another handle joins nothing
    g_ran = 0;
    void* held = avra_array_sized(2);
    avra_tasks_push(held, spawned());
    avra_rc_retain(held);
    avra_tasks_release(held);
    CHECK(g_ran == 0, "a list that is not released by its last handle joins nothing");
    avra_rc_release(held);
    avra_tasks_release(held);
    CHECK(g_ran == 1, "the last release of the list joined its member");
    avra_rc_release(held);

    // null is nothing
    avra_task_release(NULL);
    avra_tasks_release(NULL);
    CHECK(1, "a null release is ignored");

    if (g_fails) {
        fprintf(stderr, "task_release_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("task_release_test: %d checks hold\n", g_checks);
    return 0;
}

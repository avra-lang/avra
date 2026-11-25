// FLOW 05 S0 — the in-memory channel carrier's runtime law: a fiber
// parks on a full channel's gate, a taker's claim moves one item and
// wakes it, a cancel claims a parked sender and its park answers -1,
// and the buffer never exceeds n. The channel itself is Avra data; this
// test drives the gate rows the library's verbs ride.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../avra_box.h"
#include "../avra_fiber.h"
#include "../avra_runtime.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "channel_gate_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

typedef void* (*Code)(void*);
static void* answer(int64_t v) { void* r = avra_array_sized(1); avra_array_push(r, v); return r; }
static void* spawn1(Code code, int64_t a) {
    void* body = avra_array_sized(2);
    avra_array_push(body, (int64_t)(uintptr_t)code);
    avra_array_push(body, a);
    void* task = avra_task_spawn(body);
    avra_rc_release(body);
    return task;
}
static int64_t cap(void* box) { return ((AvraArray*)box)->data[1]; }
static int filed(void* gate) { return ((AvraArray*)gate)->data[0] != 0; }
static int arm_of(int64_t claim) { return (int)(claim >> 32); }
static int64_t ended(void* task) {
    avra_task_settle(task);
    int64_t how = avra_task_ended(task);
    avra_rc_release(task);
    return how;
}

// The channel: a buffer of CAP cells and the gate a full sender parks
// on. `g_parked` is the member a sender named when it parked, and
// `g_send_false` says a send answered false (the cancel point).
#define CAP 3
static int64_t g_buf[CAP];
static int g_len = 0;
static void* g_gate = NULL;
static int64_t g_parked = -1;
static int g_send_false = 0;

// A sender: fill the buffer, park when full, and on a claim push the
// value that made it park. A park answered below zero is a cancel, and
// the send answers false.
static void* sender(void* self) {
    int64_t n = cap(self);
    for (int64_t i = 0; i < n; i++) {
        if (g_len < CAP) {
            g_buf[g_len++] = i;
        } else {
            g_parked = i;
            avra_wait_gate(g_gate, 0, i);
            int64_t claim = avra_wait_park();
            if (arm_of(claim) < 0) {
                g_send_false = 1;
                break;
            }
            g_buf[g_len++] = i;
        }
    }
    return answer(0);
}

// One item fills the buffer, a claim moves it, and the buffer is never
// over its bound.
static void a_full_channel_parks_its_sender(void) {
    g_len = 0;
    g_parked = -1;
    g_send_false = 0;
    g_gate = avra_gate_new();
    void* t = spawn1(sender, CAP + 1);
    avra_fiber_sleep(2);
    CHECK(g_len == CAP, "the buffer fills to its bound and the sender parks");
    CHECK(filed(g_gate), "the full channel holds the sender parked on its givers gate");
    g_len--;                                   // a taker takes one
    CHECK(avra_gate_claim(g_gate) == CAP, "the claim answers the parked sender's member");
    CHECK(ended(t) == 1, "the woken sender runs to its end");
    CHECK(g_len == CAP, "the buffer never exceeds its bound");
    CHECK(!filed(g_gate), "and no sender is parked once the buffer is full again");
    avra_rc_release(g_gate);
}

// A cancel claims the parked sender: the park answers -1 and the send
// answers false.
static void a_cancel_claims_a_parked_sender(void) {
    g_len = 0;
    g_parked = -1;
    g_send_false = 0;
    g_gate = avra_gate_new();
    void* t = spawn1(sender, 99);
    avra_fiber_sleep(2);
    CHECK(g_len == CAP && filed(g_gate), "the sender parks when the channel is full");
    avra_task_cancel(t);
    CHECK(ended(t) == 2, "the cancelled sender ends cancelled");
    CHECK(g_send_false == 1, "its park answered -1, so the send answered false");
    CHECK(g_len == CAP, "and the buffer never went over its bound");
    CHECK(!filed(g_gate), "the cancelled wait left the gate");
    avra_rc_release(g_gate);
}

int main(void) {
    alarm(60);
    a_full_channel_parks_its_sender();
    a_cancel_claims_a_parked_sender();
    printf("channel_gate: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

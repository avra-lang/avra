// THE HOT LEAVES' CONTRACT. runtime/avra_hot.c holds the runtime's
// hottest fns — a count, a release, a slot read — compiled into the
// library AND to bitcode the backend links into every module, so a
// program inlines them. Everything they reach is here: the header
// test (inline, pure), and what avra_runtime.c exports for them — the
// guard flag and the cold paths. The hot file owns NO state: a copy
// linked into a module would be a second copy of it.
#ifndef AVRA_HOT_H
#define AVRA_HOT_H

#include <stdint.h>
#include "avra_box.h"
#include "avra_platform.h"

#ifdef AVRA_CENSUS
#define CENSUS(x) x
extern int64_t g_rc_retains, g_rc_releases, g_rc_frees, g_list_gets, g_list_pushes;
void note_retain(void* site);
void note_push(void* site);
#else
#define CENSUS(x)
#endif

// The lowest address a box may have: the page no mapping ever gets.
#define AVRA_NULL_PAGE 0x10000ull

// The payload's header. NULL for a pointer that is not a box: the
// null pointer, an unaligned address or one in the null page (a box
// is sixteen-aligned and never there — a small scalar mistaken for
// one is refused before anything is read), or a header without the
// tag. Where the loader puts the image and the heap decides nothing.
static inline Header* avra_hdr(void* p) {
    uintptr_t a = (uintptr_t)p;
    if ((a & 15) != 0 || a < AVRA_NULL_PAGE) return 0;
    Header* h = (Header*)p - 1;
    return h->tag == AVRA_TAG ? h : 0;
}

// A box's flags byte: 0 for a box no site observed, OBSERVED for one a
// site did, every bit for the binary's own data (runtime/avra_box.h).
static inline uint8_t avra_box_flags(const void* payload) {
    return ((const uint8_t*)((const Header*)payload - 1))[AVRA_FLAGS_AT];
}
// The leaves themselves (avra_hot.c).
void avra_rc_retain(void* p);
void avra_rc_release(void* p);
// A row of releases, each as `avra_rc_release` releases it, in order.
void avra_rc_release2(void* a, void* b);
void avra_rc_release3(void* a, void* b, void* c);
void avra_rc_release4(void* a, void* b, void* c, void* d);
void avra_rc_retain_tagged(int64_t word, int64_t tag, int64_t counted);
void avra_rc_release_tagged(int64_t word, int64_t tag, int64_t counted);
int64_t avra_array_get(void* arr, int64_t i);
void* avra_array_get_owned(void* arr, int64_t i);
int64_t avra_slot_get(void* box, int64_t i);
void* avra_slot_get_owned(void* box, int64_t i);
int64_t avra_array_len(void* arr);
int64_t avra_stride_len(void* arr, int64_t k);
int64_t avra_stride_at(void* arr, int64_t i, int64_t k);
void* avra_box_thawed(void* p);
void* avra_seat_opened(void* p);
void avra_array_push(void* arr, int64_t v);
void avra_array_push_owned(void* arr, void* v);
void avra_array_push_moved(void* arr, void* v);
void avra_slot_put(void* arr, int64_t i, int64_t v);
void avra_slot_set(void* arr, int64_t i, int64_t v);
void* avra_slot_unique(void* arr, int64_t i);
int64_t avra_int_shl(int64_t a, int64_t b);
int64_t avra_int_shr(int64_t a, int64_t b);
int64_t avra_bytes_at(const char* b, int64_t i);

// AVRA_RC_GUARD, settled at load.
#if AVRA_INSTRUMENTS
extern int avra_rc_guard_on;
#else
enum { avra_rc_guard_on = 0 };
#endif

// Each guarded tail is WHOLE: the fast path hands over live values
// only (a pointer, a header already in hand) and computes nothing for
// the call — the return address and the increment are the callee's
// to make, out of line, so a hot leaf's guarded branch costs the fast
// path a single untaken test and nothing else.
void avra_retain_noted(void* p, Header* h);
void avra_release_guarded(void* p, Header* h);
void avra_release_dead(void* p, int32_t kind);
int64_t avra_get_guarded(void* arr, int64_t i);
void avra_stride_checked(void* arr, int64_t k);
void* avra_get_owned_guarded(void* arr, int64_t i);
__attribute__((noreturn)) void avra_trap_bounds(int64_t i, int64_t len);
__attribute__((noreturn)) void avra_trap(const char* msg);
void* avra_box_thawed_cloned(void* p, void* ra);
__attribute__((noreturn)) void avra_seat_static(void);
// The writes' whole rows, for every case but the fast one.
void avra_push_grown(void* arr, int64_t v);
void avra_push_owned_grown(void* arr, void* v);
void avra_push_moved_grown(void* arr, void* v);
void avra_slot_put_logged(void* arr, int64_t i, int64_t v);
void avra_slot_put_flagged(void* arr, int64_t i, int64_t v);
void avra_slot_set_guarded(void* arr, int64_t i, int64_t v);
void* avra_slot_opened(void* arr, int64_t i);

#endif

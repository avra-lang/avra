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
extern int64_t g_rc_retains, g_rc_releases, g_rc_frees, g_list_gets;
void note_retain(void* site);
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

// The leaves themselves (avra_hot.c).
void avra_rc_retain(void* p);
void avra_rc_release(void* p);
void avra_rc_retain_tagged(int64_t word, int64_t tag, int64_t counted);
void avra_rc_release_tagged(int64_t word, int64_t tag, int64_t counted);
int64_t avra_array_get(void* arr, int64_t i);
void* avra_array_get_owned(void* arr, int64_t i);
int64_t avra_slot_get(void* box, int64_t i);
void* avra_slot_get_owned(void* box, int64_t i);
int64_t avra_array_len(void* arr);
void* avra_box_thawed(void* p);

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
void* avra_get_owned_guarded(void* arr, int64_t i);
__attribute__((noreturn)) void avra_trap_bounds(int64_t i, int64_t len);
void* avra_box_thawed_cloned(void* p, void* ra);

#endif

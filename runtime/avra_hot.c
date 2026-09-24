// THE HOT LEAVES (runtime/avra_hot.h says why they stand apart): a
// count, a release, a slot read. Each fast path is a load, a test and
// a store; every slow one is a tail call into avra_runtime.c.
#include "avra_hot.h"

void avra_rc_retain(void* p) {
    Header* h = avra_hdr(p);
    if (h == 0 || h->kind < 0) return;
    CENSUS(g_rc_retains++);
    CENSUS(note_retain(__builtin_return_address(0)));
    h->rc++;
    if (__builtin_expect(avra_rc_guard_on, 0)) avra_retain_noted(p, h->rc, __builtin_return_address(0));
}

void avra_rc_release(void* p) {
    Header* h = avra_hdr(p);
    if (h == 0) return;
    if (__builtin_expect(avra_rc_guard_on, 0)) { avra_release_guarded(p, h); return; }
    if (h->kind < 0) return;
    CENSUS(g_rc_releases++);
    h->rc--;
    if (__builtin_expect(h->rc > 0, 1)) return;
    CENSUS(g_rc_frees++);
    // The kind is read FIRST — a slot's release below may reclaim
    // this box's neighbours, and the header goes with the box — so
    // it is READ HERE and HANDED to the reclaim, which is out of
    // line and tail-called: a release that does not free keeps no
    // frame, and most releases do not free.
    avra_release_dead(p, h->kind);
}

// A value enum's word counted only when bit `tag` of `counted` says
// that variant carries a pointer — an int payload is never a header,
// and the absent tag (-1) carries nothing.
void avra_rc_retain_tagged(int64_t word, int64_t tag, int64_t counted) {
    if (tag >= 0 && ((counted >> tag) & 1)) avra_rc_retain((void*)(uintptr_t)word);
}

void avra_rc_release_tagged(int64_t word, int64_t tag, int64_t counted) {
    if (tag >= 0 && ((counted >> tag) & 1)) avra_rc_release((void*)(uintptr_t)word);
}

int64_t avra_array_get(void* arr, int64_t i) {
    CENSUS(g_list_gets++);
    if (__builtin_expect(avra_rc_guard_on, 0)) return avra_get_guarded(arr, i);
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(i < 0 || i >= a->len, 0)) avra_trap_bounds(i, a->len);
    return a->data[i];
}

// A managed read is an owned +1: the reader's scope releases it,
// the pointer stays shared. The bounds trap is avra_array_get's.
void* avra_array_get_owned(void* arr, int64_t i) {
    void* v = (void*)(uintptr_t)avra_array_get(arr, i);
    avra_rc_retain(v);
    return v;
}

int64_t avra_array_len(void* arr) {
    return ((AvraArray*)arr)->len;
}

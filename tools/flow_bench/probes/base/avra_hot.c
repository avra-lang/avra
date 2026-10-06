// THE HOT LEAVES (runtime/avra_hot.h says why they stand apart): a
// count, a release, a slot read. Each fast path is a load, a test and
// a store; every slow one is a tail call into avra_runtime.c, and the
// call is handed only values already live at the site — a return
// address or an incremented count computed HERE would be computed
// again in every one of the 395 copies this file is inlined into; the
// callee, compiled once, computes its own.
#include "avra_hot.h"

void avra_rc_retain(void* p) {
    Header* h = avra_hdr(p);
    if (h == 0 || h->kind < 0) return;
    CENSUS(g_rc_retains++);
    CENSUS(note_retain(AVRA_CALLER()));
    if (__builtin_expect(avra_rc_guard_on, 0)) { avra_retain_noted(p, h); return; }
    h->rc++;
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
// the pointer stays shared. Composing avra_array_get and
// avra_rc_retain would inline BOTH of their guard tests and BOTH of
// their header checks into every copy; the guard is asked once here,
// and the fast path is the two fast paths fused, never their sum.
void* avra_array_get_owned(void* arr, int64_t i) {
    CENSUS(g_list_gets++);
    if (__builtin_expect(avra_rc_guard_on, 0)) return avra_get_owned_guarded(arr, i);
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(i < 0 || i >= a->len, 0)) avra_trap_bounds(i, a->len);
    void* v = (void*)(uintptr_t)a->data[i];
    Header* h = avra_hdr(v);
    if (h != 0 && h->kind >= 0) { CENSUS(g_rc_retains++); h->rc++; }
    return v;
}

// A slot the reader's type proves exists — a declared field, a cell's
// one slot — so the read is two loads and no bounds test. The guard's
// dead-box check is left to the counts around it.
int64_t avra_slot_get(void* box, int64_t i) {
    CENSUS(g_list_gets++);
    return ((AvraArray*)box)->data[i];
}

// The proven read plus its owned +1, fused as `avra_array_get_owned` is.
void* avra_slot_get_owned(void* box, int64_t i) {
    CENSUS(g_list_gets++);
    void* v = (void*)(uintptr_t)((AvraArray*)box)->data[i];
    Header* h = avra_hdr(v);
    if (h != 0 && h->kind >= 0) {
        if (__builtin_expect(avra_rc_guard_on, 0)) { avra_retain_noted(v, h); return v; }
        CENSUS(g_rc_retains++);
        h->rc++;
    }
    return v;
}

int64_t avra_array_len(void* arr) {
    return ((AvraArray*)arr)->len;
}

// The no-cell law with no cell to hold the answer — a method's
// receiver, a borrowed parameter. Overwhelmingly not the binary's own
// data, so the fast path is a retain; the rare clone is a tail call,
// out of line, with the caller's own return address carried across it
// so the clone log names the write site and not this leaf.
void* avra_box_thawed(void* p) {
    Header* h = avra_hdr(p);
    if (__builtin_expect(h != 0 && IS_IMMORTAL(h->kind), 0))
        return avra_box_thawed_cloned(p, AVRA_CALLER());
    avra_rc_retain(p);
    return p;
}

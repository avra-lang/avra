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
    if (h == 0 || avra_kind(h) < 0) return;
    CENSUS(g_rc_retains++);
    CENSUS(note_retain(p, AVRA_CALLER()));
    if (__builtin_expect(avra_rc_guard_on, 0)) { avra_retain_noted(p, h); return; }
    h->rc++;
}

void avra_rc_release(void* p) {
    Header* h = avra_hdr(p);
    if (h == 0) return;
    if (__builtin_expect(avra_rc_guard_on, 0)) { avra_release_guarded(p, h); return; }
    if (avra_kind(h) < 0) return;
    CENSUS(g_rc_releases++);
    CENSUS(note_release(p, AVRA_CALLER()));
    h->rc--;
    if (__builtin_expect(h->rc > 0, 1)) return;
    CENSUS(g_rc_frees++);
    // The kind is read FIRST — a slot's release below may reclaim
    // this box's neighbours, and the header goes with the box — so
    // it is READ HERE and HANDED to the reclaim, which is out of
    // line and tail-called: a release that does not free keeps no
    // frame, and most releases do not free.
    avra_release_dead(p, avra_kind(h));
}

// A value enum's word counted only when bit `tag` of `counted` says
// that variant carries a pointer — an int payload is never a header,
// and the absent tag (-1) carries nothing.
void avra_rc_retain_tagged(int64_t word, int64_t tag, int64_t counted) {
    if (tag >= 0 && ((counted >> tag) & 1)) avra_rc_retain((void*)(uintptr_t)word);
}

void avra_rc_release2(void* a, void* b) {
    avra_rc_release(a);
    avra_rc_release(b);
}

void avra_rc_release3(void* a, void* b, void* c) {
    avra_rc_release(a);
    avra_rc_release(b);
    avra_rc_release(c);
}

void avra_rc_release4(void* a, void* b, void* c, void* d) {
    avra_rc_release(a);
    avra_rc_release(b);
    avra_rc_release(c);
    avra_rc_release(d);
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
    if (h != 0 && avra_kind(h) >= 0) { CENSUS(g_rc_retains++); h->rc++; }
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
    if (h != 0 && avra_kind(h) >= 0) {
        if (__builtin_expect(avra_rc_guard_on, 0)) { avra_retain_noted(v, h); return v; }
        CENSUS(g_rc_retains++);
        h->rc++;
    }
    return v;
}

int64_t avra_array_len(void* arr) {
    return ((AvraArray*)arr)->len;
}

// A STRIDED LIST: each element its `k` words laid in place, so the list's length counts words and
// its element count is that over `k`. The stride is the element type's, handed in by every site
// that reads one; the rows that only move words never need it.
int64_t avra_stride_len(void* arr, int64_t k) {
    return ((AvraArray*)arr)->len / k;
}

// Element `i`'s first word, bounds-checked in ELEMENTS, so a trap says what the program wrote.
int64_t avra_stride_at(void* arr, int64_t i, int64_t k) {
    if (__builtin_expect(avra_rc_guard_on, 0)) avra_stride_checked(arr, k);
    int64_t n = ((AvraArray*)arr)->len / k;
    if (__builtin_expect((uint64_t)i >= (uint64_t)n, 0)) avra_trap_bounds(i, n);
    return i * k;
}

// The no-cell law with no cell to hold the answer — a method's
// receiver, a borrowed parameter. Overwhelmingly not the binary's own
// data, so the fast path is a retain; the rare clone is a tail call,
// out of line, with the caller's own return address carried across it
// so the clone log names the write site and not this leaf.
void* avra_box_thawed(void* p) {
    Header* h = avra_hdr(p);
    if (__builtin_expect(h != 0 && IS_IMMORTAL(avra_kind(h)), 0))
        return avra_box_thawed_cloned(p, AVRA_CALLER());
    avra_rc_retain(p);
    return p;
}

// A write through `self` or a `mut` seat: its caller opened the box, so
// the write rides the seat's own reference and the binary's own data
// never reaches here.
void* avra_seat_opened(void* p) {
    Header* h = avra_hdr(p);
    if (__builtin_expect(h != 0 && IS_IMMORTAL(avra_kind(h)), 0)) avra_seat_static();
    return p;
}

// THE WRITES. Each fast path is the write a unique, roomy box takes —
// the word and its mark stored, the length bumped; a packed list's word
// alone — and every other case is the WHOLE row, out of line in
// avra_runtime.c and tail-called with the leaf's own arguments: a full
// list's grow, an owned push into a packed list (a defect), a box a
// turn's log must stamp first, a guarded run, a shared slot's clone.

// One word onto the list; a full list grows out of line.
void avra_array_push(void* arr, int64_t v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(a->len == a->cap, 0)) { avra_push_grown(arr, v); return; }
    a->data[a->len] = v;
    if (a->marks != 0) a->marks[a->len] = 0;
    a->len++;
}

// RETAIN-AT-PACK: the list takes its own reference to a managed value
// and marks the slot, so reclaim releases it.
void avra_array_push_owned(void* arr, void* v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(a->len == a->cap || avra_packed(a), 0)) { avra_push_owned_grown(arr, v); return; }
    a->data[a->len] = (int64_t)(uintptr_t)v;
    a->marks[a->len] = MARK_OWNED;
    a->len++;
    avra_rc_retain(v);
}

// The push twin of `avra_slot_set_moved`: the caller's reference moves
// into the new slot.
void avra_array_push_moved(void* arr, void* v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(a->len == a->cap || avra_packed(a), 0)) { avra_push_moved_grown(arr, v); return; }
    a->data[a->len] = (int64_t)(uintptr_t)v;
    a->marks[a->len] = MARK_OWNED;
    a->len++;
}

// A write into a slot the box's shape proves exists — a cell's one
// slot, a record's declared field — so it has no bound to trap on. The
// new word is stored BEFORE the old owned one is released, so a release
// that frees reads a box already written, and is the leaf's tail. A box
// with a flag set — one a site observed, or the binary's own data — is
// the whole write out of line: one byte tested where a plain box is
// written.
static inline void slot_written(void* arr, int64_t i, int64_t v) {
    if (__builtin_expect(avra_box_flags(arr) != 0, 0)) { avra_slot_put_flagged(arr, i, v); return; }
    AvraArray* a = (AvraArray*)arr;
    int64_t old = a->data[i];
    uint8_t mark = avra_mark_at(a, i);
    a->data[i] = v;
    if (mark != 0) a->marks[i] = 0;
    if (mark & MARK_OWNED) avra_rc_release((void*)(uintptr_t)old);
}

void avra_slot_put(void* arr, int64_t i, int64_t v) { slot_written(arr, i, v); }

// A write into a slot by index: bounds-checked, then the slot write.
void avra_slot_set(void* arr, int64_t i, int64_t v) {
    if (__builtin_expect(avra_rc_guard_on, 0)) { avra_slot_set_guarded(arr, i, v); return; }
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect((uint64_t)i >= (uint64_t)a->len, 0)) avra_trap_bounds(i, a->len);
    slot_written(arr, i, v);
}

// The box in a slot opened for writing: itself when nothing else holds
// it. A shared or immortal one — and any open a turn's log or the guard
// must see — is the whole row out of line, which clones into the slot.
void* avra_slot_unique(void* arr, int64_t i) {
    if (__builtin_expect(avra_box_unlogged(arr), 0)) return avra_slot_opened(arr, i);
    if (__builtin_expect(avra_rc_guard_on, 0)) return avra_slot_opened(arr, i);
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect((uint64_t)i >= (uint64_t)a->len, 0)) avra_trap_bounds(i, a->len);
    void* p = (void*)(uintptr_t)a->data[i];
    Header* h = avra_hdr(p);
    if (h == 0) return p;
    int32_t k = avra_kind(h);
    if (__builtin_expect(IS_IMMORTAL(k) || (k >= 0 && h->rc > 1), 0)) return avra_slot_opened(arr, i);
    return p;
}

// THE ARITHMETIC AND OCTET LEAVES: a shift is two instructions behind its range test, and an
// octet read one load behind its bound; a call around either costs more than the work, so both
// are here, inlined where they are used, the trap out of line.
int64_t avra_int_shl(int64_t a, int64_t b) {
    if (b < 0 || b >= 64) { avra_trap("a shift count must be between 0 and 63"); }
    /* shifting INTO the sign bit is undefined for a signed left
       operand, so the shift is done on the unsigned twin and read
       back — the bits are what the program asked for either way. */
    return (int64_t)((uint64_t)a << (uint64_t)b);
}

int64_t avra_int_shr(int64_t a, int64_t b) {
    if (b < 0 || b >= 64) { avra_trap("a shift count must be between 0 and 63"); }
    /* ARITHMETIC: the sign bit fills, so `-8 >> 1` is -4 and not a
       huge positive. That is the shift Avra's one integer means, and
       it is what LLVM's `ashr` does on the other side. */
    return a >> b;
}

int64_t avra_bytes_at(const char* b, int64_t i) {
    int64_t n = (int64_t)((const Header*)b - 1)->len;
    if (__builtin_expect(i < 0 || i >= n, 0)) avra_trap_bounds(i, n);
    return (unsigned char)b[i];
}

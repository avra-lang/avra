// The Avra runtime — the native half of the language's semantics.
//
// Every function here is a CONTRACT the compiler lowers against:
// what `${x}` prints, what `==` means for strings, what an index
// out of bounds does. Language semantics live in this tree, in this
// file — never in a dependency.
//
// MEMORY MODEL (v3): a HEADER, not a registry. Every allocation
// this runtime hands a program carries sixteen bytes before its
// payload: a tag that says the header is ours, the box's kind, and
// its refcount. avra_rc_retain / avra_rc_release read the header
// the payload's own cache line holds — no table, no probe, no
// rehash. The tag is what restores "not mine": a pointer whose
// header does not carry it (a raw scalar, a foreign address) is
// left alone. THE LAW THE TAG BACKS: every pointer Avra holds
// carries a header — the backend's string constants (see
// avra_llvm_build_global_string_ptr), the runtime's own literals,
// argv and the environment included — so a retain never reads
// before an address that is not ours. A STATIC box is immortal:
// its header is read and never written, so a constant may live in
// read-only memory. Strings and ARRAYS both carry headers; an
// array's kind decides its reclaim, which releases its OWNED slots
// first (the compiler marks them at pack time via
// avra_array_push_owned), so nesting reclaims by recursion. Reads
// of owned slots go through avra_array_get_owned, which retains —
// every managed read is a +1 the reader's scope releases, so
// aliasing shares the pointer while counts balance.
//
// TRAP CONTRACT: an impossible-at-runtime operation (index out of
// bounds) prints one line to stderr — worded EXACTLY like the
// evaluator's refusal — and exits 1. The divergence registry pins
// both sides.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

// ── The box header ──────────────────────────────────────────────

// A box's KIND decides how it reclaims and clones: 0 a plain
// allocation, 1 an array, 2 a map. Below zero it is not counted:
// STATIC is immortal, DEAD is the guard's mark on a reclaimed box.
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2 };

// "AVRA" — the bytes that say a header is this runtime's.
#define AVRA_TAG 0x41565241u

// A string box also carries its LENGTH, so `.length`, a byte read
// and a substring cost no walk; zero means "not recorded" (a
// constant emitted before lengths were), and the text is measured.
typedef struct {
    uint32_t tag;
    int32_t kind;
    int32_t rc;
    uint32_t len;
} Header;

// The payload's header. NULL for a pointer that is not a box: the
// null pointer, an unaligned or low address (a box is sixteen-
// aligned and lives above the image base — a scalar mistaken for
// one is refused before anything is read), or a header without the
// tag.
static Header* hdr(void* p) {
    uintptr_t a = (uintptr_t)p;
    if ((a & 15) != 0 || a < 0x100000000ull) return NULL;
    Header* h = (Header*)p - 1;
    return h->tag == AVRA_TAG ? h : NULL;
}

// A fresh box of `size` payload bytes, refcount 1.
static void* box_alloc(size_t size, int32_t kind) {
    Header* h = (Header*)malloc(sizeof(Header) + (size > 0 ? size : 1));
    h->tag = AVRA_TAG;
    h->kind = kind;
    h->rc = 1;
    h->len = 0;
    return (void*)(h + 1);
}

// A string box of `n` bytes plus its terminator, its length known.
static char* str_box(size_t n, int32_t kind) {
    char* buf = (char*)box_alloc(n + 1, kind);
    ((Header*)buf - 1)->len = (uint32_t)n;
    return buf;
}

// A string's length in O(1) — the header's, or measured when the
// box predates lengths (a zero) or the text is not a box.
static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return (h && h->len) ? h->len : strlen(s);
}

// The tag goes before the memory does: a stale release of a freed
// box then reads "not mine" instead of a count that is no longer
// anyone's.
static void box_free(void* p) {
    Header* h = (Header*)p - 1;
    h->tag = 0;
    free(h);
}

// An IMMORTAL copy of `s`: retain and release leave it alone. What
// every text the runtime answers without owning becomes — a
// keyword, an argument, the environment's word.
static const char* str_static(const char* s) {
    size_t n = strlen(s);
    char* buf = str_box(n, KIND_STATIC);
    memcpy(buf, s, n + 1);
    return buf;
}

// The guard's event log: every retain and release of every box,
// with the caller's address, so a double release can show its own
// history. Debug-only, and BOUNDED: past the budget the log stops
// and the report says so — a guarded run of a large program must
// not take the machine with it.
typedef struct { void* ptr; int delta; void* at; int64_t rc; } RcEvent;
static RcEvent* g_log = NULL;
static size_t g_log_len = 0;
static size_t g_log_cap = 0;
#define RC_LOG_BUDGET ((size_t)1 << 23)

static void rc_note(void* p, int delta, void* at, int64_t rc) {
    if (g_log_len == RC_LOG_BUDGET) return;
    if (g_log_len == g_log_cap) {
        g_log_cap = g_log_cap ? g_log_cap * 2 : 1 << 16;
        g_log = (RcEvent*)realloc(g_log, g_log_cap * sizeof(RcEvent));
    }
    g_log[g_log_len].ptr = p;
    g_log[g_log_len].delta = delta;
    g_log[g_log_len].at = at;
    g_log[g_log_len].rc = rc;
    g_log_len++;
}

static void rc_history(void* p) {
    if (g_log_len == RC_LOG_BUDGET) fputs("    (history truncated at the log's budget)\n", stderr);
    for (size_t i = 0; i < g_log_len; i++) {
        if (g_log[i].ptr == p) {
            fprintf(stderr, "    %s from %p -> rc %lld\n",
                    g_log[i].delta > 0 ? "retain" : "release", g_log[i].at, (long long)g_log[i].rc);
        }
    }
}

static void array_reclaim(void* p);
static void array_poison(void* p);
static void map_reclaim(void* p);
static void* box_clone(void* p);

// DEBUG GUARD (AVRA_RC_GUARD=1): a box that reaches rc 0 is KEPT,
// marked dead, so the next read of it traps at the site that used
// it rather than somewhere later.
static int g_guard = -1;
static void* g_chain[64];
static int g_chain_len = 0;

// An array box's cell count, for the guard's report; -1 when the
// pointer is not an array this runtime owns.
static int64_t guard_len(void* p);

static int rc_guarded(void) {
    if (g_guard < 0) g_guard = getenv("AVRA_RC_GUARD") != NULL;
    return g_guard;
}

void avra_rc_dead_check(void* p, const char* what) {
    if (!rc_guarded()) return;
    Header* h = hdr(p);
    if (h && h->kind == KIND_DEAD) {
        fprintf(stderr, "avra: %s read a RELEASED box %p\n", what, p);
        abort();
    }
}

void avra_rc_retain(void* p) {
    Header* h = hdr(p);
    if (h == NULL || h->kind < 0) return;
    h->rc++;
    if (rc_guarded()) rc_note(p, 1, __builtin_return_address(0), h->rc);
}

// The guard's release: the box is kept and marked dead, its cells
// poisoned; a second release of a dead box reports its history.
static void release_guarded(void* p, Header* h) {
    if (h->kind == KIND_DEAD) {
        fprintf(stderr, "avra: released an already-dead box %p (len %lld)\n", p, (long long)guard_len(p));
        fprintf(stderr, "  this one from %p\n", __builtin_return_address(0));
        rc_history(p);
        for (int k = g_chain_len - 1; k >= 0; k--) {
            fprintf(stderr, "  reclaiming %p (len %lld)\n", g_chain[k], (long long)guard_len(g_chain[k]));
        }
        abort();
    }
    if (h->kind < 0) return;
    h->rc--;
    rc_note(p, -1, __builtin_return_address(0), h->rc);
    if (h->rc > 0) return;
    int32_t kind = h->kind;
    h->kind = KIND_DEAD;
    h->rc = 0;
    if (kind == KIND_ARRAY) {
        int pushed = g_chain_len < 64;
        if (pushed) { g_chain[g_chain_len] = p; g_chain_len++; }
        array_poison(p);
        if (pushed) g_chain_len--;
    }
}

void avra_rc_release(void* p) {
    Header* h = hdr(p);
    if (h == NULL) return;
    if (rc_guarded()) { release_guarded(p, h); return; }
    if (h->kind < 0) return;
    h->rc--;
    if (h->rc > 0) return;
    // The kind is read FIRST: a slot's release below may reclaim
    // this box's neighbours, and the header goes with the box.
    int32_t kind = h->kind;
    if (kind == KIND_ARRAY) {
        array_reclaim(p);
    } else if (kind == KIND_MAP) {
        map_reclaim(p);
    } else {
        box_free(p);
    }
}

// ── The trap contract ───────────────────────────────────────────

// THE CASE IN FLIGHT. A suite runs in one process, so a trap kills
// every case after it — this is how the wreck names which one it
// was running when it died.
static const char* g_case = NULL;

void avra_case_begin(const char* label) {
    g_case = label;
}

// A TRAP IS A WRECK, not a verdict: status 2 keeps it distinct from
// the 1 a program leaves when it merely disagrees with its input.
static void avra_trap(const char* msg) {
    if (g_case) {
        fputs("avra: while running ", stderr);
        fputs(g_case, stderr);
        fputc('\n', stderr);
    }
    fputs("avra: ", stderr);
    fputs(msg, stderr);
    fputc('\n', stderr);
    exit(2);
}

// ── Printing ────────────────────────────────────────────────────

// One printed line: the text, then a newline.
void avra_puts(const char* s) {
    if (s) fputs(s, stdout);
    fputc('\n', stdout);
}

// ── Strings ─────────────────────────────────────────────────────

// Value equality; null equals only null.
int64_t avra_streq(const char* a, const char* b) {
    if (a == NULL || b == NULL) return a == b;
    return strcmp(a, b) == 0;
}

// An int's decimal text — what `${n}` interpolates and `print`
// shows. Owned.
// `/` and `%` by zero: the interpreter REFUSES, so the native
// binary must too. LLVM's sdiv/srem by zero is undefined behaviour —
// left raw it printed an answer and exited 0, which is a silently
// wrong program.
int64_t avra_int_div(int64_t a, int64_t b) {
    if (b == 0) { avra_trap("division by zero"); }
    return a / b;
}

int64_t avra_int_mod(int64_t a, int64_t b) {
    if (b == 0) { avra_trap("division by zero"); }
    return a % b;
}

const char* avra_int_text(int64_t v) {
    char* buf = str_box(23, KIND_PLAIN);
    ((Header*)buf - 1)->len = (uint32_t)snprintf(buf, 24, "%lld", (long long)v);
    return buf;
}

// A bool's keyword — static, immortal.
const char* avra_bool_text(int64_t b) {
    static const char* words[2] = { NULL, NULL };
    if (words[0] == NULL) { words[0] = str_static("false"); words[1] = str_static("true"); }
    return words[b != 0];
}

// ── Aggregates: int64 slot arrays ───────────────────────────────
// Slots carry every value category: ints and bools directly,
// pointers cast down by the compiler (rt_arg). An array is a box
// of kind 1 — see the memory model note.

typedef struct {
    int64_t cap;
    int64_t len;
    int64_t* data;
    // Which slots hold OWNED managed values — marked at pack time
    // by the compiler, walked at reclaim. Parallel to data.
    uint8_t* owned;
} AvraArray;

void* avra_array_new(void) {
    AvraArray* a = (AvraArray*)box_alloc(sizeof(AvraArray), KIND_ARRAY);
    a->cap = 8;
    a->len = 0;
    a->data = (int64_t*)malloc((size_t)a->cap * sizeof(int64_t));
    a->owned = (uint8_t*)calloc((size_t)a->cap, 1);
    return a;
}

// The guard's reclaim: children released as usual, the box kept and
// its cells poisoned, so a stale reader trips instead of finding a
// plausible value.
static void array_poison(void* p) {
    AvraArray* a = (AvraArray*)p;
    for (int64_t i = 0; i < a->len; i++) {
        if (a->owned[i]) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    memset(a->data, 0xDD, (size_t)a->len * sizeof(int64_t));
}

static int64_t guard_len(void* p) {
    Header* h = hdr(p);
    return h == NULL ? -1 : ((AvraArray*)p)->len;
}

// Releases every owned slot, then the array itself.
static void array_reclaim(void* p) {
    AvraArray* a = (AvraArray*)p;
    for (int64_t i = 0; i < a->len; i++) {
        if (a->owned[i]) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    free(a->data);
    free(a->owned);
    box_free(a);
}

// No list holds more cells than this: a capacity past it is a
// corrupted box, and the program stops rather than asking the
// machine for the memory.
#define CELL_CEILING ((int64_t)1 << 31)

void avra_array_push(void* arr, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == a->cap) {
        if (a->cap >= CELL_CEILING || a->cap <= 0) avra_trap("a list grew past any possible size — a corrupted box");
        a->cap *= 2;
        a->data = (int64_t*)realloc(a->data, (size_t)a->cap * sizeof(int64_t));
        a->owned = (uint8_t*)realloc(a->owned, (size_t)a->cap);
        memset(a->owned + a->len, 0, (size_t)(a->cap - a->len));
    }
    a->data[a->len] = v;
    a->owned[a->len] = 0;
    a->len++;
}

// RETAIN-AT-PACK: the array takes its own reference to a managed
// value and remembers the slot, so reclaim releases it.
void avra_array_push_owned(void* arr, void* v) {
    avra_array_push(arr, (int64_t)(uintptr_t)v);
    AvraArray* a = (AvraArray*)arr;
    a->owned[a->len - 1] = 1;
    avra_rc_retain(v);
}

int64_t avra_array_len(void* arr) {
    return ((AvraArray*)arr)->len;
}

// Worded exactly like the evaluator's refusal — the divergence
// registry pins both.
// `v!` — slot 1 of a tagged value, insisting slot 0 says PRESENT.
// The writer claimed absence would not happen; if it does the
// program STOPS rather than reading a slot never written.
// `v!` on a NICHE nullable — the pointer IS the value and absence is
// the null pointer, so insisting is identity through the guard. The
// wording matches avra_insist_scalar and the evaluator: the
// divergence registry pins all three.
// The answer is the SAME box, so it comes back OWNED: the caller's
// scope releases both the subject and the answer, and a reference
// that escapes through `!` must survive its subject's release.
void* avra_insist(void* p) {
    if (!p) { avra_trap("unwrapped an absent value"); }
    avra_rc_retain(p);
    return p;
}

// `v!` on a PAIR nullable — the flag guards, the value passes.
int64_t avra_insist_scalar(int64_t present, int64_t value) {
    if (!present) { avra_trap("unwrapped an absent value"); }
    return value;
}

int64_t avra_array_get(void* arr, int64_t i) {
    // THE GUARD IS A BRANCH, not a call: every read asked, and the
    // answer is no on every run that is not debugging.
    if (rc_guarded()) { avra_rc_dead_check(arr, "array_get"); }
    AvraArray* a = (AvraArray*)arr;
    if (i < 0 || i >= a->len) {
        char msg[80];
        snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
                 (long long)i, (long long)a->len);
        avra_trap(msg);
    }
    return a->data[i];
}

// A managed read is an owned +1: the reader's scope releases it,
// the pointer stays shared. The bounds trap is avra_array_get's.
void* avra_array_get_owned(void* arr, int64_t i) {
    void* v = (void*)(uintptr_t)avra_array_get(arr, i);
    avra_rc_retain(v);
    return v;
}

// A mut CELL's own reference dies: releases whatever the cell
// currently holds. What is not a counted box no-ops by construction.
// A cell settles by giving up its reference AND forgetting it: a
// scope re-entered (a loop body) finds an empty cell, so an
// iteration that never stores releases nothing.
void avra_cell_release(void* slot) {
    avra_rc_release(*(void**)slot);
    *(void**)slot = NULL;
}

// ── Places: copy-on-write ───────────────────────────────────────

// A shallow clone that takes its own reference to every owned
// slot — exactly what reclaim would release. A fresh box, rc 1.
static void* array_clone(AvraArray* a) {
    AvraArray* c = (AvraArray*)avra_array_new();
    for (int64_t i = 0; i < a->len; i++) {
        avra_array_push(c, a->data[i]);
        if (a->owned[i]) {
            c->owned[i] = 1;
            avra_rc_retain((void*)(uintptr_t)a->data[i]);
        }
    }
    return c;
}

// Shared means a count above one — the holder's own reference is
// the one. What is not a counted box is never one a place opens.
static int is_shared(void* p) {
    Header* h = hdr(p);
    return h != NULL && h->kind >= 0 && h->rc > 1;
}

// Opens a mut cell's box for writing: itself when nothing else
// holds it, else a clone stored into the cell (the old reference
// released). The answer is BORROWED from the cell.
void* avra_cell_unique(void* slot) {
    void* p = *(void**)slot;
    if (!is_shared(p)) return p;
    void* c = box_clone(p);
    *(void**)slot = c;
    avra_rc_release(p);
    return c;
}

// The same one level down: the box in a slot, made unique in place.
void* avra_slot_unique(void* arr, int64_t i) {
    void* p = (void*)(uintptr_t)avra_array_get(arr, i);
    if (!is_shared(p)) return p;
    AvraArray* a = (AvraArray*)arr;
    void* c = box_clone(p);
    a->data[i] = (int64_t)(uintptr_t)c;
    a->owned[i] = 1;
    avra_rc_release(p);
    return c;
}

// A write into a slot: the old owned content is released.
void avra_slot_set(void* arr, int64_t i, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    avra_array_get(arr, i);
    if (a->owned[i]) avra_rc_release((void*)(uintptr_t)a->data[i]);
    a->data[i] = v;
    a->owned[i] = 0;
}

// RETAIN-AT-PACK for a slot write: the incoming value is retained
// FIRST (a self-store must not free what it keeps), then the old
// content goes.
void avra_slot_set_owned(void* arr, int64_t i, void* v) {
    avra_rc_retain(v);
    avra_slot_set(arr, i, (int64_t)(uintptr_t)v);
    ((AvraArray*)arr)->owned[i] = 1;
}

// ── Maps: string-keyed, insertion-ordered ───────────────────────

// Two arrays keep the written order (keys owned — the map holds
// its own reference to every key; values marked owned at set) and
// an open-addressing index over key hashes finds a slot. Kind 2.
typedef struct {
    AvraArray* keys;
    AvraArray* vals;
    int64_t* index;   // slot + 1, 0 when empty
    int64_t icap;
} AvraMap;

static uint64_t str_hash(const char* s) {
    uint64_t h = 1469598103934665603ull;
    for (; *s; s++) { h ^= (unsigned char)*s; h *= 1099511628211ull; }
    return h;
}

static void map_index_rebuild(AvraMap* m, int64_t icap) {
    if (icap >= CELL_CEILING || icap <= 0) avra_trap("a map grew past any possible size — a corrupted box");
    free(m->index);
    m->icap = icap;
    m->index = (int64_t*)calloc((size_t)icap, sizeof(int64_t));
    for (int64_t s = 0; s < m->keys->len; s++) {
        const char* k = (const char*)(uintptr_t)m->keys->data[s];
        uint64_t i = str_hash(k) & (uint64_t)(icap - 1);
        while (m->index[i] != 0) i = (i + 1) & (uint64_t)(icap - 1);
        m->index[i] = s + 1;
    }
}

void* avra_map_new(void) {
    AvraMap* m = (AvraMap*)box_alloc(sizeof(AvraMap), KIND_MAP);
    m->keys = (AvraArray*)avra_array_new();
    m->vals = (AvraArray*)avra_array_new();
    m->index = NULL;
    m->icap = 0;
    map_index_rebuild(m, 16);
    return m;
}

// Releases both arrays (their owned slots follow), then the map.
static void map_reclaim(void* p) {
    AvraMap* m = (AvraMap*)p;
    avra_rc_release(m->keys);
    avra_rc_release(m->vals);
    free(m->index);
    box_free(m);
}

// The slot a key names, or -1.
static int64_t map_find(AvraMap* m, const char* key) {
    uint64_t i = str_hash(key) & (uint64_t)(m->icap - 1);
    while (m->index[i] != 0) {
        int64_t s = m->index[i] - 1;
        if (avra_streq((const char*)(uintptr_t)m->keys->data[s], key)) return s;
        i = (i + 1) & (uint64_t)(m->icap - 1);
    }
    return -1;
}

int64_t avra_map_len(void* map) {
    return ((AvraMap*)map)->keys->len;
}

int64_t avra_map_has(void* map, const char* key) {
    return map_find((AvraMap*)map, key) >= 0;
}

// The value under a key — read only after avra_map_has said so.
int64_t avra_map_get(void* map, const char* key) {
    AvraMap* m = (AvraMap*)map;
    int64_t s = map_find(m, key);
    return s < 0 ? 0 : m->vals->data[s];
}

void* avra_map_get_owned(void* map, const char* key) {
    void* v = (void*)(uintptr_t)avra_map_get(map, key);
    avra_rc_retain(v);
    return v;
}

// A write under a key: an existing slot is overwritten (the old
// owned value released), a new key appends in written order and
// the map takes its own reference to the key.
void avra_map_set(void* map, const char* key, int64_t v) {
    AvraMap* m = (AvraMap*)map;
    int64_t s = map_find(m, key);
    if (s >= 0) { avra_slot_set(m->vals, s, v); return; }
    avra_array_push_owned(m->keys, (void*)key);
    avra_array_push(m->vals, v);
    if (m->keys->len * 10 >= m->icap * 7) { map_index_rebuild(m, m->icap * 2); return; }
    uint64_t i = str_hash(key) & (uint64_t)(m->icap - 1);
    while (m->index[i] != 0) i = (i + 1) & (uint64_t)(m->icap - 1);
    m->index[i] = m->keys->len;
}

void avra_map_set_owned(void* map, const char* key, void* v) {
    AvraMap* m = (AvraMap*)map;
    int64_t s = map_find(m, key);
    if (s >= 0) { avra_slot_set_owned(m->vals, s, v); return; }
    avra_map_set(map, key, (int64_t)(uintptr_t)v);
    s = map_find(m, key);
    m->vals->owned[s] = 1;
    avra_rc_retain(v);
}

// A map's shallow clone: both arrays cloned (their owned slots
// retained), the index rebuilt. A fresh box, rc 1.
static void* map_clone(AvraMap* m) {
    AvraMap* c = (AvraMap*)box_alloc(sizeof(AvraMap), KIND_MAP);
    c->keys = (AvraArray*)array_clone(m->keys);
    c->vals = (AvraArray*)array_clone(m->vals);
    c->index = NULL;
    c->icap = 0;
    map_index_rebuild(c, m->icap);
    return c;
}

// The clone a place opens — by the box's kind.
static void* box_clone(void* p) {
    Header* h = hdr(p);
    return (h && h->kind == KIND_MAP) ? map_clone((AvraMap*)p) : array_clone((AvraArray*)p);
}

// ── Text building ───────────────────────────────────────────────

// Concatenate string slots with `sep` between — what interpolation
// joins. Owned.
const char* avra_str_join(void* arr, const char* sep) {
    AvraArray* a = (AvraArray*)arr;
    size_t sep_len = str_len(sep);
    size_t total = 1;
    for (int64_t i = 0; i < a->len; i++) {
        const char* s = (const char*)a->data[i];
        total += s ? str_len(s) : 0;
        if (i > 0) total += sep_len;
    }
    char* buf = str_box(total - 1, KIND_PLAIN);
    char* p = buf;
    for (int64_t i = 0; i < a->len; i++) {
        if (i > 0) { memcpy(p, sep, sep_len); p += sep_len; }
        const char* s = (const char*)a->data[i];
        if (s) { size_t l = str_len(s); memcpy(p, s, l); p += l; }
    }
    *p = '\0';
    return buf;
}

// A bracketed element list — shared by the typed printers below.
static const char* list_text(void* arr, const char* (*text)(int64_t)) {
    AvraArray* a = (AvraArray*)arr;
    void* parts = avra_array_new();
    for (int64_t i = 0; i < a->len; i++) {
        avra_array_push(parts, (int64_t)(uintptr_t)text(a->data[i]));
    }
    const char* body = avra_str_join(parts, ", ");
    size_t l = str_len(body);
    char* buf = str_box(l + 2, KIND_PLAIN);
    buf[0] = '[';
    memcpy(buf + 1, body, l);
    buf[l + 1] = ']';
    buf[l + 2] = '\0';
    return buf;
}

// `[1, 2, 3]` — exactly how the evaluator prints an int list.
const char* avra_ints_text(void* arr) {
    return list_text(arr, avra_int_text);
}

// `[true, false]` — exactly how the evaluator prints a bool list.
const char* avra_bools_text(void* arr) {
    return list_text(arr, avra_bool_text);
}

// A string slot prints as itself, unquoted — the evaluator's way.
static const char* str_slot_text(int64_t v) {
    static const char* absent = NULL;
    if (absent == NULL) absent = str_static("null");
    return v ? (const char*)(uintptr_t)v : absent;
}

// `[a, b]` — exactly how the evaluator prints a string list.
const char* avra_strs_text(void* arr) {
    return list_text(arr, str_slot_text);
}

// ── The list vocabulary ─────────────────────────────────────────

// The last slot, removed — a trap on an empty list. The plain form
// answers a scalar; the owned twin hands the slot's reference to
// the caller (no retain when the slot owned it, one when it did
// not), so the answer is owned either way.
int64_t avra_array_pop(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == 0) avra_trap("pop on an empty list");
    a->len--;
    if (a->owned[a->len]) avra_trap("a managed slot popped as a scalar");
    return a->data[a->len];
}

void* avra_array_pop_owned(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == 0) avra_trap("pop on an empty list");
    a->len--;
    void* v = (void*)(uintptr_t)a->data[a->len];
    if (a->owned[a->len]) {
        a->owned[a->len] = 0;
    } else {
        avra_rc_retain(v);
    }
    return v;
}

// `src`'s slots from lo up to hi appended to `out`, owned ones
// retained — a copy holds its own references.
static void array_append(void* out, AvraArray* src, int64_t lo, int64_t hi) {
    for (int64_t i = lo; i < hi; i++) {
        if (src->owned[i]) {
            avra_array_push_owned(out, (void*)(uintptr_t)src->data[i]);
        } else {
            avra_array_push(out, src->data[i]);
        }
    }
}

// A fresh list: `a`'s slots, then `b`'s. Owned.
void* avra_array_concat(void* a, void* b) {
    void* out = avra_array_new();
    array_append(out, (AvraArray*)a, 0, ((AvraArray*)a)->len);
    array_append(out, (AvraArray*)b, 0, ((AvraArray*)b)->len);
    return out;
}

// A fresh list of the slots from lo up to hi, clamped to the list;
// nothing when lo is not below hi. Owned.
void* avra_array_slice(void* arr, int64_t lo, int64_t hi) {
    AvraArray* a = (AvraArray*)arr;
    if (lo < 0) lo = 0;
    if (hi > a->len) hi = a->len;
    void* out = avra_array_new();
    if (lo < hi) array_append(out, a, lo, hi);
    return out;
}

// ── The string vocabulary ───────────────────────────────────────
// Byte offsets, ends exclusive, clamped to the text; every answer
// that is new text is owned.

static const char* str_owned(const char* s, size_t n) {
    char* buf = str_box(n, KIND_PLAIN);
    memcpy(buf, s, n);
    buf[n] = '\0';
    return buf;
}

// A list slot holding fresh text — the list owns the one reference.
static void push_fresh_text(void* arr, const char* s, size_t n) {
    avra_array_push(arr, (int64_t)(uintptr_t)str_owned(s, n));
    AvraArray* a = (AvraArray*)arr;
    a->owned[a->len - 1] = 1;
}

const char* avra_str_substring(const char* s, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)str_len(s);
    if (lo < 0) lo = 0;
    if (hi > n) hi = n;
    if (lo >= hi) return str_owned("", 0);
    return str_owned(s + lo, (size_t)(hi - lo));
}

int64_t avra_str_contains(const char* s, const char* needle) {
    return strstr(s, needle) != NULL;
}

int64_t avra_str_starts_with(const char* s, const char* prefix) {
    return strncmp(s, prefix, str_len(prefix)) == 0;
}

int64_t avra_str_ends_with(const char* s, const char* suffix) {
    size_t n = str_len(s);
    size_t m = str_len(suffix);
    return m <= n && memcmp(s + n - m, suffix, m) == 0;
}

// The first position of `needle`, or -1.
int64_t avra_str_index_of(const char* s, const char* needle) {
    const char* at = strstr(s, needle);
    return at ? (int64_t)(at - s) : -1;
}

// UTF-8 characters, not bytes: continuation bytes (10xxxxxx) belong
// to the character before them. What alignment measures.
int64_t avra_str_codepoint_count(const char* s) {
    int64_t n = 0;
    for (const unsigned char* p = (const unsigned char*)s; *p; p++) {
        if ((*p & 0xC0) != 0x80) n++;
    }
    return n;
}

// The byte at `i` as a code — a trap past the text, worded like a
// list's. The bound is the header's length: a scan that reads
// every byte costs one load per byte.
int64_t avra_str_char_code(const char* s, int64_t i) {
    int64_t n = (int64_t)str_len(s);
    if (i < 0 || i >= n) {
        char msg[80];
        snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
                 (long long)i, (long long)n);
        avra_trap(msg);
    }
    return (unsigned char)s[i];
}

// `.length` on text — the header's count, no walk.
int64_t avra_str_len(const char* s) {
    return (int64_t)str_len(s);
}

static int is_blank(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

const char* avra_str_trim(const char* s) {
    size_t n = str_len(s);
    size_t lo = 0;
    while (lo < n && is_blank(s[lo])) lo++;
    while (n > lo && is_blank(s[n - 1])) n--;
    return str_owned(s + lo, n - lo);
}

// Every occurrence of `from` becomes `to`; an empty `from` changes
// nothing.
const char* avra_str_replace(const char* s, const char* from, const char* to) {
    size_t n = strlen(s);
    size_t fl = strlen(from);
    size_t tl = strlen(to);
    if (fl == 0) return str_owned(s, n);
    size_t count = 0;
    for (const char* p = strstr(s, from); p; p = strstr(p + fl, from)) count++;
    char* buf = str_box(n + count * tl - count * fl, KIND_PLAIN);
    char* w = buf;
    const char* r = s;
    for (const char* p; (p = strstr(r, from)) != NULL;) {
        memcpy(w, r, (size_t)(p - r));
        w += p - r;
        memcpy(w, to, tl);
        w += tl;
        r = p + fl;
    }
    strcpy(w, r);
    return buf;
}

// The pieces between separators: a leading empty piece stays, one
// trailing empty piece is dropped, and empty text splits to
// nothing. An empty separator keeps the text whole. Owned, holding
// owned pieces.
void* avra_str_split(const char* s, const char* sep) {
    void* out = avra_array_new();
    size_t sl = strlen(sep);
    if (*s == '\0') return out;
    if (sl == 0) {
        push_fresh_text(out, s, strlen(s));
        return out;
    }
    const char* r = s;
    for (;;) {
        const char* p = strstr(r, sep);
        if (p == NULL) {
            if (*r != '\0') push_fresh_text(out, r, strlen(r));
            return out;
        }
        push_fresh_text(out, r, (size_t)(p - r));
        r = p + sl;
    }
}

// `a + b` on text — one fresh string. Owned.
const char* avra_str_concat(const char* a, const char* b) {
    size_t n = str_len(a);
    size_t m = str_len(b);
    char* buf = str_box(n + m, KIND_PLAIN);
    memcpy(buf, a, n);
    memcpy(buf + n, b, m + 1);
    return buf;
}

// ── The host: what a program declares `extern` and the CLI leans on ──
// Each answers as the CLI reads it: files as text ("" when unreadable),
// verdicts and statuses as words, listings as newline-joined names.

#include <sys/stat.h>
#include <sys/wait.h>
#include <spawn.h>
#include <poll.h>
#include <signal.h>
#include <fcntl.h>

// A child's cwd bound through a file action: POSIX-2024's name where
// the SDK has it (macOS 26), the `_np` spelling before (Darwin
// 10.15, glibc 2.29); elsewhere a cwd is refused as unsupported.
#if defined(__APPLE__)
#include <Availability.h>
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir
#else
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir_np
#endif
#elif defined(__GLIBC__)
#if __GLIBC_PREREQ(2, 29)
#define AVRA_ADDCHDIR posix_spawn_file_actions_addchdir_np
#endif
#endif
extern char** environ;
#include <dirent.h>
#include <time.h>
#include <unistd.h>

void println(const char* s) {
    fputs(s, stdout);
    fputc('\n', stdout);
}

void eprintln(const char* s) {
    fputs(s, stderr);
    fputc('\n', stderr);
}

// THE PROGRAM'S ARGUMENTS. The emitted `main` hands the C pair over
// once, before any statement runs; each argument is copied into an
// immortal box, so a program reads text that carries a header and
// never owns it.
static int64_t g_argc = 0;
static const char** g_argv = NULL;

void avra_args_init(int64_t argc, char** argv) {
    g_argc = argc;
    g_argv = (const char**)malloc((size_t)(argc > 0 ? argc : 1) * sizeof(char*));
    for (int64_t i = 0; i < argc; i++) g_argv[i] = str_static(argv[i]);
    // A write to a closed pipe is an EPIPE the writer sees, never a
    // signal that kills the program mid-sentence; every child spawned
    // here gets the default back (posix_spawn's SETSIGDEF).
    signal(SIGPIPE, SIG_IGN);
}

int64_t avra_selfhost_argc(void) {
    return g_argc;
}

const char* avra_selfhost_get_arg_cstr(int64_t i) {
    if (i < 0 || i >= g_argc || g_argv == NULL) return str_static("");
    return g_argv[i];
}

// An environment variable's value, or "" — what a manifest's link
// flags expand so a machine's own paths stay out of the tree.
// Immortal: the environment is the invoker's, never the program's.
const char* avra_host_env(const char* name) {
    const char* v = getenv(name);
    return str_static(v ? v : "");
}

int64_t avra_now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}

void avra_process_exit(int64_t code) {
    exit((int)code);
}

int64_t avra_selfhost_file_exists(const char* path) {
    struct stat st;
    return stat(path, &st) == 0;
}

int64_t avra_host_is_dir(const char* path) {
    struct stat st;
    return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

// The whole file as text; "" when it cannot be read. Owned.
const char* avra_selfhost_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return str_owned("", 0);
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (size < 0) { fclose(f); return str_owned("", 0); }
    char* buf = str_box((size_t)size, KIND_PLAIN);
    size_t got = fread(buf, 1, (size_t)size, f);
    buf[got] = '\0';
    ((Header*)buf - 1)->len = (uint32_t)got;
    fclose(f);
    return buf;
}

// The text written whole, through a sibling temp file and a rename,
// so a reader never sees a half-written file. 1 on success.
int64_t avra_selfhost_write_file(const char* path, const char* content) {
    size_t n = strlen(path);
    char* tmp = (char*)malloc(n + 8);
    memcpy(tmp, path, n);
    memcpy(tmp + n, ".tmpav", 7);
    FILE* f = fopen(tmp, "wb");
    if (!f) { free(tmp); return 0; }
    size_t len = strlen(content);
    int64_t ok = fwrite(content, 1, len, f) == len;
    fclose(f);
    if (ok) ok = rename(tmp, path) == 0;
    if (!ok) remove(tmp);
    free(tmp);
    return ok;
}

// ── Processes ───────────────────────────────────────────────────
//
// THE SUBSTRATE @std.process stands on: twelve functions over a
// handle table. The host seam carries words and pointers only, so a
// spawn answers ONE integer and C keeps the pid, the pipes and the
// buffers behind it. ONE PUMP drains stdout, stderr and a pending
// stdin in one poll set — the only shape that cannot deadlock at a
// full pipe — and reaps exactly once, after which the pid is -1 and
// a signal answers -ESRCH: the pid-reuse race cannot be written.
// A STATUS IS A TAGGED WORD: the tag in the high half (0 running,
// 1 exited, 2 signalled), the payload below, so success is never
// zero and a signal death can never read as a small exit code; a
// spawn that fails answers -errno and mints no handle. Every text
// answered is a box (str_owned / str_static), never a bare malloc.
// The program is spawned by ABSOLUTE PATH through posix_spawn —
// never posix_spawnp, which searches the parent's PATH and, on
// Darwin, resolves against the parent's cwd.

enum {
    PROC_PIPE_IN = 0x1, PROC_PIPE_OUT = 0x2, PROC_PIPE_ERR = 0x4, PROC_MERGE_ERR = 0x8,
    PROC_NULL_IN = 0x10, PROC_NULL_OUT = 0x20, PROC_NULL_ERR = 0x40,
    PROC_INHERIT_IN = 0x80, PROC_INHERIT_OUT = 0x100, PROC_INHERIT_ERR = 0x200,
    PROC_NEW_PGROUP = 0x400, PROC_NEW_SESSION = 0x800, PROC_SEARCH_PATH = 0x1000, PROC_INHERIT_ENV = 0x2000
};
enum {
    EV_OUT = 0x1, EV_ERR = 0x2, EV_OUT_EOF = 0x4, EV_ERR_EOF = 0x8, EV_IN_WROTE = 0x10, EV_IN_CLOSED = 0x20,
    EV_EXITED = 0x40, EV_TIMEOUT = 0x80, EV_CAPPED_OUT = 0x100, EV_CAPPED_ERR = 0x200,
    EV_TERMED = 0x400, EV_KILLED = 0x800, EV_TRUNCATED = 0x1000
};
enum { EXIT_CODE = 1, EXIT_SIGNAL = 2 };

// A captured stream's bytes so far.
typedef struct { char* buf; size_t len; size_t cap; } Grow;

typedef struct {
    int live;
    int64_t gen;
    pid_t pid;              // -1 once reaped
    pid_t pgid;             // the group the child leads, outliving its reap
    int group;              // the child leads its own process group
    int in_fd, out_fd, err_fd;
    Grow out, err;
    char* in_text;          // pending stdin, ours
    size_t in_len, in_off;
    int in_close;           // close stdin once the pending text has drained
    int64_t status;         // the tagged word; 0 while running
    int64_t sticky;         // events that stay: timeout, capped, termed, killed, truncated
    size_t max_bytes;
} Proc;

static Proc* g_procs = NULL;
static int64_t g_nprocs = 0;

static int64_t mono_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + (int64_t)ts.tv_nsec / 1000000;
}

// A handle is the slot's generation over its index, so a closed
// slot's handle never names the slot's next tenant.
static Proc* proc_at(int64_t h) {
    if (h < 0) return NULL;
    int64_t idx = h & 0xffffffffLL, gen = h >> 32;
    if (idx >= g_nprocs || !g_procs[idx].live || g_procs[idx].gen != gen) return NULL;
    return &g_procs[idx];
}

static int64_t proc_slot(void) {
    for (int64_t i = 0; i < g_nprocs; i++) if (!g_procs[i].live) return i;
    int64_t n = g_nprocs ? g_nprocs * 2 : 16;
    g_procs = (Proc*)realloc(g_procs, (size_t)n * sizeof(Proc));
    for (int64_t i = g_nprocs; i < n; i++) { memset(&g_procs[i], 0, sizeof(Proc)); g_procs[i].gen = 1; }
    int64_t at = g_nprocs;
    g_nprocs = n;
    return at;
}

static void grow_append(Grow* g, const char* s, size_t n) {
    if (g->len + n + 1 > g->cap) {
        size_t cap = g->cap ? g->cap : 4096;
        while (cap < g->len + n + 1) cap *= 2;
        g->buf = (char*)realloc(g->buf, cap);
        g->cap = cap;
    }
    memcpy(g->buf + g->len, s, n);
    g->len += n;
    g->buf[g->len] = '\0';
}

static void close_fd(int* fd) {
    if (*fd >= 0) close(*fd);
    *fd = -1;
}

// A pipe end above the standard three (a dup2 target must never be
// one we hold), CLOEXEC so it never leaks into a child.
static int raised(int fd) {
    while (fd >= 0 && fd <= 2) {
        int d = fcntl(fd, F_DUPFD_CLOEXEC, 3);
        close(fd);
        fd = d;
    }
    if (fd >= 0) fcntl(fd, F_SETFD, FD_CLOEXEC);
    return fd;
}

static int make_pipe(int p[2]) {
    if (pipe(p) != 0) return -errno;
    p[0] = raised(p[0]);
    p[1] = raised(p[1]);
    return (p[0] < 0 || p[1] < 0) ? -EMFILE : 0;
}

static int executable(const char* path) {
    struct stat st;
    return stat(path, &st) == 0 && S_ISREG(st.st_mode) && access(path, X_OK) == 0;
}

// The program's absolute path: as written when it names a directory,
// else the first PATH entry holding it — relative and empty entries
// are skipped, so the current directory is never searched. Ours.
static char* resolved(const char* file, const char* path) {
    if (strchr(file, '/')) return executable(file) ? strdup(file) : NULL;
    if (!path) return NULL;
    const char* p = path;
    size_t flen = strlen(file);
    while (1) {
        const char* colon = strchr(p, ':');
        size_t n = colon ? (size_t)(colon - p) : strlen(p);
        if (n > 0 && p[0] == '/') {
            char* cand = (char*)malloc(n + flen + 2);
            memcpy(cand, p, n);
            cand[n] = '/';
            memcpy(cand + n + 1, file, flen + 1);
            if (executable(cand)) return cand;
            free(cand);
        }
        if (!colon) return NULL;
        p = colon + 1;
    }
}

// A NULL-terminated vector over an Avra `List<string>`, the strings
// borrowed for one call; `head` leads it when given.
static char** words_of(void* arr, const char* head) {
    AvraArray* a = (AvraArray*)arr;
    int64_t n = a ? a->len : 0;
    char** v = (char**)malloc((size_t)(n + 2) * sizeof(char*));
    int64_t k = 0;
    if (head) v[k++] = (char*)head;
    for (int64_t i = 0; i < n; i++) v[k++] = (char*)(uintptr_t)a->data[i];
    v[k] = NULL;
    return v;
}

static int one_of(int64_t flags, int64_t a, int64_t b, int64_t c, int64_t d) {
    return !!(flags & a) + !!(flags & b) + !!(flags & c) + !!(flags & d) == 1;
}

// A child spawned. `max_bytes` caps each captured stream (0 lifts the
// cap); `from_h` names an upstream child whose stdout becomes this
// child's stdin through the kernel's own pipe — no bytes through us —
// or -1 for the stdin the flags say.
int64_t avra_proc_spawn(const char* file, void* argv, void* envp, const char* cwd, int64_t flags, int64_t max_bytes, int64_t from_h) {
    Proc* from = from_h >= 0 ? proc_at(from_h) : NULL;
    if (from_h >= 0 && (!from || from->out_fd < 0)) return -EBADF;
    if (from) flags = (flags & ~(int64_t)(PROC_NULL_IN | PROC_INHERIT_IN)) | PROC_PIPE_IN;
    if (!one_of(flags, PROC_PIPE_IN, PROC_NULL_IN, PROC_INHERIT_IN, 0)) return -EINVAL;
    if (!one_of(flags, PROC_PIPE_OUT, PROC_NULL_OUT, PROC_INHERIT_OUT, 0)) return -EINVAL;
    if (!one_of(flags, PROC_PIPE_ERR, PROC_NULL_ERR, PROC_INHERIT_ERR, PROC_MERGE_ERR)) return -EINVAL;
    if ((flags & PROC_MERGE_ERR) && !(flags & PROC_PIPE_OUT)) return -EINVAL;
    AvraArray* env = (AvraArray*)envp;
    for (int64_t i = 0; env && i < env->len; i++) {
        if (!strchr((const char*)(uintptr_t)env->data[i], '=')) return -EINVAL;
    }
    if (cwd && cwd[0]) {
        struct stat st;
        if (stat(cwd, &st) != 0 || !S_ISDIR(st.st_mode)) return -ENOTDIR;
    }
    char* path = ((flags & PROC_SEARCH_PATH) && !strchr(file, '/')) ? resolved(file, getenv("PATH")) : strdup(file);
    if (!path) return -ENOENT;
    int in[2] = { -1, -1 }, out[2] = { -1, -1 }, err[2] = { -1, -1 };
    int rc = 0;
    if (from) {
        // the upstream's read end was ours to poll — non-blocking; the
        // child that inherits it reads as a child does
        in[0] = from->out_fd;
        fcntl(in[0], F_SETFL, 0);
    } else if ((flags & PROC_PIPE_IN) && (rc = make_pipe(in)) != 0) goto fail;
    if ((flags & PROC_PIPE_OUT) && (rc = make_pipe(out)) != 0) goto fail;
    if ((flags & PROC_PIPE_ERR) && (rc = make_pipe(err)) != 0) goto fail;

    posix_spawn_file_actions_t fa;
    posix_spawn_file_actions_init(&fa);
    if (flags & PROC_PIPE_IN) posix_spawn_file_actions_adddup2(&fa, in[0], 0);
    if (flags & PROC_NULL_IN) posix_spawn_file_actions_addopen(&fa, 0, "/dev/null", O_RDONLY, 0);
    if (flags & PROC_PIPE_OUT) posix_spawn_file_actions_adddup2(&fa, out[1], 1);
    if (flags & PROC_NULL_OUT) posix_spawn_file_actions_addopen(&fa, 1, "/dev/null", O_WRONLY, 0);
    if (flags & PROC_PIPE_ERR) posix_spawn_file_actions_adddup2(&fa, err[1], 2);
    if (flags & PROC_MERGE_ERR) posix_spawn_file_actions_adddup2(&fa, out[1], 2);
    if (flags & PROC_NULL_ERR) posix_spawn_file_actions_addopen(&fa, 2, "/dev/null", O_WRONLY, 0);
#ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
    // Darwin closes every fd the actions do not name — so the three
    // a child inherits are named.
    if (flags & PROC_INHERIT_IN) posix_spawn_file_actions_addinherit_np(&fa, 0);
    if (flags & PROC_INHERIT_OUT) posix_spawn_file_actions_addinherit_np(&fa, 1);
    if (flags & PROC_INHERIT_ERR) posix_spawn_file_actions_addinherit_np(&fa, 2);
#endif
    if (cwd && cwd[0]) {
#ifdef AVRA_ADDCHDIR
        AVRA_ADDCHDIR(&fa, cwd);
#else
        posix_spawn_file_actions_destroy(&fa);
        rc = -ENOTSUP;
        goto fail;
#endif
    }
    posix_spawnattr_t at;
    posix_spawnattr_init(&at);
    short af = POSIX_SPAWN_SETSIGMASK | POSIX_SPAWN_SETSIGDEF;
    sigset_t none, all;
    sigemptyset(&none);
    sigfillset(&all);
    sigdelset(&all, SIGKILL);
    sigdelset(&all, SIGSTOP);
    posix_spawnattr_setsigmask(&at, &none);
    posix_spawnattr_setsigdefault(&at, &all);
    if (flags & PROC_NEW_PGROUP) { af |= POSIX_SPAWN_SETPGROUP; posix_spawnattr_setpgroup(&at, 0); }
#ifdef POSIX_SPAWN_SETSID
    if (flags & PROC_NEW_SESSION) af |= POSIX_SPAWN_SETSID;
#endif
#ifdef POSIX_SPAWN_CLOEXEC_DEFAULT
    af |= POSIX_SPAWN_CLOEXEC_DEFAULT;
#endif
    posix_spawnattr_setflags(&at, af);

    char** cargv = words_of(argv, file);
    char** cenvp = (flags & PROC_INHERIT_ENV) ? environ : words_of(envp, NULL);
    // what this program printed comes out before the child's words
    fflush(NULL);
    pid_t pid = -1;
    int started = posix_spawn(&pid, path, &fa, &at, cargv, cenvp);
    posix_spawn_file_actions_destroy(&fa);
    posix_spawnattr_destroy(&at);
    free(cargv);
    if (cenvp != environ) free(cenvp);
    // the upstream's read end is the child's now; we stop reading it
    if (from) { in[0] = -1; close_fd(&from->out_fd); }
    close_fd(&in[0]);
    close_fd(&out[1]);
    close_fd(&err[1]);
    if (started != 0) { rc = -started; goto fail; }
    if (in[1] >= 0) fcntl(in[1], F_SETFL, O_NONBLOCK);
    if (out[0] >= 0) fcntl(out[0], F_SETFL, O_NONBLOCK);
    if (err[0] >= 0) fcntl(err[0], F_SETFL, O_NONBLOCK);
    free(path);

    int64_t idx = proc_slot();
    Proc* p = &g_procs[idx];
    int64_t gen = p->gen;
    memset(p, 0, sizeof(Proc));
    p->gen = gen;
    p->live = 1;
    p->pid = pid;
    p->pgid = pid;
    p->group = (flags & (PROC_NEW_PGROUP | PROC_NEW_SESSION)) != 0;
    p->in_fd = in[1];
    p->out_fd = out[0];
    p->err_fd = err[0];
    p->max_bytes = max_bytes > 0 ? (size_t)max_bytes : (size_t)-1;
    return (gen << 32) | idx;

fail:
    free(path);
    if (from) in[0] = -1;
    close_fd(&in[0]); close_fd(&in[1]);
    close_fd(&out[0]); close_fd(&out[1]);
    close_fd(&err[0]); close_fd(&err[1]);
    return rc;
}

static int64_t encoded(int st) {
    if (WIFEXITED(st)) return ((int64_t)EXIT_CODE << 32) | (int64_t)WEXITSTATUS(st);
    int64_t payload = WTERMSIG(st);
#ifdef WCOREDUMP
    if (WCOREDUMP(st)) payload |= 0x100;
#endif
    return ((int64_t)EXIT_SIGNAL << 32) | payload;
}

// One stream's readable bytes into its buffer; EOF and the cap both
// close our end.
static int64_t drained(Proc* p, int* fd, Grow* g, int64_t got, int64_t eof, int64_t capped) {
    char chunk[65536];
    ssize_t n = read(*fd, chunk, sizeof chunk);
    if (n > 0) {
        grow_append(g, chunk, (size_t)n);
        if (g->len > p->max_bytes) { close_fd(fd); p->sticky |= capped; return capped; }
        return got;
    }
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR)) return 0;
    close_fd(fd);
    return eof;
}

// Pending stdin fed as far as the pipe takes it; the child closing
// its end is a normal close, never an error.
static int64_t fed(Proc* p) {
    int64_t ev = 0;
    if (p->in_off < p->in_len) {
        ssize_t n = write(p->in_fd, p->in_text + p->in_off, p->in_len - p->in_off);
        if (n > 0) { p->in_off += (size_t)n; ev |= EV_IN_WROTE; }
        else if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) { close_fd(&p->in_fd); return EV_IN_CLOSED; }
    }
    if (p->in_off >= p->in_len && p->in_close) { close_fd(&p->in_fd); ev |= EV_IN_CLOSED; }
    return ev;
}

static int proc_done(Proc* p) {
    return p->pid < 0 && p->out_fd < 0 && p->err_fd < 0;
}

// One tick of the pump: poll every open end at once, move what
// moves, reap once. Answers the tick's events over the standing
// state — exited, ends at EOF, the sticky verdicts.
static int64_t pump_tick(Proc* p, int64_t timeout_ms) {
    int64_t ev = 0;
    if (p->in_fd >= 0 && p->in_off >= p->in_len && p->in_close) { close_fd(&p->in_fd); ev |= EV_IN_CLOSED; }
    struct pollfd fds[3];
    int n = 0, io = -1, ie = -1, ii = -1;
    if (p->out_fd >= 0) { fds[n].fd = p->out_fd; fds[n].events = POLLIN; fds[n].revents = 0; io = n++; }
    if (p->err_fd >= 0) { fds[n].fd = p->err_fd; fds[n].events = POLLIN; fds[n].revents = 0; ie = n++; }
    if (p->in_fd >= 0 && p->in_off < p->in_len) { fds[n].fd = p->in_fd; fds[n].events = POLLOUT; fds[n].revents = 0; ii = n++; }
    // a live child is re-checked at least every 100ms, so an exit is
    // seen while its output is still open
    int wait = timeout_ms < 0 ? -1 : (int)timeout_ms;
    if (p->pid > 0 && (wait < 0 || wait > 100)) wait = 100;
    int r = poll(n ? fds : NULL, (nfds_t)n, wait);
    if (r < 0 && errno != EINTR) return -errno;
    if (r > 0) {
        if (io >= 0 && fds[io].revents) ev |= drained(p, &p->out_fd, &p->out, EV_OUT, EV_OUT_EOF, EV_CAPPED_OUT);
        if (ie >= 0 && fds[ie].revents) ev |= drained(p, &p->err_fd, &p->err, EV_ERR, EV_ERR_EOF, EV_CAPPED_ERR);
        if (ii >= 0 && fds[ii].revents) ev |= fed(p);
    }
    if (p->pid > 0) {
        int st;
        pid_t w = waitpid(p->pid, &st, WNOHANG);
        if (w == p->pid) { p->status = encoded(st); p->pid = -1; ev |= EV_EXITED; }
    }
    if (p->pid < 0) ev |= EV_EXITED;
    if (p->out_fd < 0) ev |= EV_OUT_EOF;
    if (p->err_fd < 0) ev |= EV_ERR_EOF;
    if (p->in_fd < 0) ev |= EV_IN_CLOSED;
    return ev | p->sticky;
}

// A signal to the child — its whole group when it leads one. The
// group id outlives the reap: a pid is never reused while it names a
// living group, so the tree a finished child left behind is still ours.
static void signalled(Proc* p, int sig) {
    if (p->group) { if (p->pgid > 0) killpg(p->pgid, sig); return; }
    if (p->pid > 0) kill(p->pid, sig);
}

// Ticks until `until` says stop or `ms` have passed.
static void pumped_until(Proc* p, int64_t ms, int (*until)(Proc*)) {
    int64_t deadline = mono_ms() + ms;
    while (!until(p)) {
        int64_t remain = deadline - mono_ms();
        if (remain <= 0) return;
        if (pump_tick(p, remain) < 0) return;
    }
}

static int reaped(Proc* p) { return p->pid < 0; }

// TERM to the tree, a grace, then KILL — which cannot be caught, so
// the reap follows.
static void escalated(Proc* p, int64_t grace_ms) {
    signalled(p, SIGTERM);
    p->sticky |= EV_TERMED;
    pumped_until(p, grace_ms, reaped);
    if (p->pid > 0) {
        signalled(p, SIGKILL);
        p->sticky |= EV_KILLED;
        pumped_until(p, grace_ms > 1000 ? grace_ms : 1000, reaped);
    }
}

// THE ONE-SHOT: spawn, pump to the end, escalate past the deadline
// or the cap, and bound the drain after the exit — a grandchild that
// keeps the pipe open is a TRUNCATED capture, never a hang. Answers
// a finished handle, or the spawn's -errno.
int64_t avra_proc_run(const char* file, void* argv, void* envp, const char* cwd, int64_t flags,
                      const char* stdin_text, int64_t timeout_ms, int64_t grace_ms, int64_t max_bytes) {
    int64_t h = avra_proc_spawn(file, argv, envp, cwd, flags, max_bytes, -1);
    if (h < 0) return h;
    Proc* p = proc_at(h);
    if (p->in_fd >= 0) {
        size_t n = stdin_text ? strlen(stdin_text) : 0;
        if (n > 0) { p->in_text = (char*)malloc(n); memcpy(p->in_text, stdin_text, n); p->in_len = n; }
        p->in_close = 1;
    }
    int64_t deadline = timeout_ms >= 0 ? mono_ms() + timeout_ms : -1;
    int64_t exited_at = -1;
    while (!proc_done(p)) {
        int64_t now = mono_ms();
        if (deadline >= 0 && now >= deadline) { p->sticky |= EV_TIMEOUT; break; }
        if (exited_at >= 0 && now - exited_at >= grace_ms) break;
        int64_t ev = pump_tick(p, 100);
        if (ev < 0) break;
        if ((ev & EV_EXITED) && exited_at < 0) exited_at = mono_ms();
        if (ev & (EV_CAPPED_OUT | EV_CAPPED_ERR)) break;
    }
    if (!proc_done(p)) {
        if (p->pid > 0) escalated(p, grace_ms);
        pumped_until(p, grace_ms, proc_done);
        if (!proc_done(p)) {
            // whoever still holds the pipe is the child's own tree; a
            // one-shot leaves nothing behind
            signalled(p, SIGKILL);
            close_fd(&p->out_fd);
            close_fd(&p->err_fd);
            p->sticky |= EV_TRUNCATED;
        }
    }
    close_fd(&p->in_fd);
    return h;
}

int64_t avra_proc_poll(int64_t h, int64_t timeout_ms) {
    Proc* p = proc_at(h);
    return p ? pump_tick(p, timeout_ms) : -EBADF;
}

// Text queued for the child's stdin; the pump writes it as the pipe
// takes it. Answers the bytes queued.
int64_t avra_proc_write(int64_t h, const char* text) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    if (p->in_fd < 0) return -EPIPE;
    size_t n = str_len(text);
    p->in_text = (char*)realloc(p->in_text, p->in_len + n + 1);
    memcpy(p->in_text + p->in_len, text, n);
    p->in_len += n;
    return (int64_t)n;
}

int64_t avra_proc_stdin_close(int64_t h) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    p->in_close = 1;
    if (p->in_fd >= 0 && p->in_off >= p->in_len) close_fd(&p->in_fd);
    return 0;
}

// Everything a stream buffered since the last take — 1 stdout, 2
// stderr — as fresh owned text; "" when nothing.
const char* avra_proc_take(int64_t h, int64_t stream) {
    Proc* p = proc_at(h);
    Grow* g = !p ? NULL : stream == 1 ? &p->out : stream == 2 ? &p->err : NULL;
    if (!g || g->len == 0) return str_owned("", 0);
    const char* s = str_owned(g->buf, g->len);
    g->len = 0;
    return s;
}

// A signal to the child — the whole group when it leads one and
// `to_group` asks. -ESRCH once reaped: a recycled pid is never hit.
int64_t avra_proc_signal(int64_t h, int64_t sig, int64_t to_group) {
    Proc* p = proc_at(h);
    if (!p) return -EBADF;
    if (p->pid <= 0) return -ESRCH;
    int r = (to_group && p->group) ? killpg(p->pgid, (int)sig) : kill(p->pid, (int)sig);
    return r == 0 ? 0 : -errno;
}

// The tagged word — 0 while the child runs.
int64_t avra_proc_status(int64_t h) {
    Proc* p = proc_at(h);
    return p ? p->status : -EBADF;
}

int64_t avra_proc_pid(int64_t h) {
    Proc* p = proc_at(h);
    return p ? (int64_t)p->pid : -1;
}

// The handle released: a live child is killed with its tree and
// reaped, every end closed, the slot's generation bumped. Idempotent.
void avra_proc_close(int64_t h) {
    Proc* p = proc_at(h);
    if (!p) return;
    if (p->pid > 0) {
        int st;
        signalled(p, SIGKILL);
        while (waitpid(p->pid, &st, 0) < 0 && errno == EINTR) {}
        p->pid = -1;
    } else if (p->group) {
        signalled(p, SIGKILL);
    }
    close_fd(&p->in_fd);
    close_fd(&p->out_fd);
    close_fd(&p->err_fd);
    free(p->out.buf);
    free(p->err.buf);
    free(p->in_text);
    int64_t gen = p->gen + 1;
    memset(p, 0, sizeof(Proc));
    p->gen = gen;
}

// Where `file` resolves on `path` — the absolute path as owned text,
// "" when nothing resolves.
const char* avra_proc_which(const char* file, const char* path) {
    char* found = resolved(file, path);
    if (!found) return str_owned("", 0);
    const char* s = str_owned(found, strlen(found));
    free(found);
    return s;
}

// An errno's words, immortal; the number stays the value.
const char* avra_proc_error_text(int64_t err) {
    return str_static(strerror((int)(err < 0 ? -err : err)));
}

// Every directory along the path made, 1 when the whole path stands.
int64_t avra_mkdir_p(const char* path) {
    size_t n = strlen(path);
    if (n == 0 || n >= 4096) return 0;
    char buf[4096];
    memcpy(buf, path, n + 1);
    for (size_t i = 1; i < n; i++) {
        if (buf[i] == '/') {
            buf[i] = '\0';
            if (mkdir(buf, 0755) != 0 && errno != EEXIST) return 0;
            buf[i] = '/';
        }
    }
    return mkdir(buf, 0755) == 0 || errno == EEXIST;
}

// The directory's entries, newline-joined, in the order the host
// lists them; "" for a directory that cannot be read. Owned.
const char* avra_host_list_dir(const char* path) {
    DIR* d = opendir(path);
    if (!d) return str_owned("", 0);
    void* names = avra_array_new();
    struct dirent* e;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
        push_fresh_text(names, e->d_name, strlen(e->d_name));
    }
    closedir(d);
    const char* joined = avra_str_join(names, "\n");
    avra_rc_release(names);
    return joined;
}

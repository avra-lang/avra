// The Avra runtime — the native half of the language's semantics.
//
// Every function here is a CONTRACT the compiler lowers against:
// what `${x}` prints, what `==` means for strings, what an index
// out of bounds does. Language semantics live in this tree, in this
// file — never in a dependency.
//
// MEMORY MODEL (v2): an ownership REGISTRY, not headers and not
// trust. Every allocation this runtime hands to a program is
// registered with refcount 1. avra_rc_retain / avra_rc_release act
// only on registered pointers — statics, literals, and foreign
// pointers pass through as no-ops BY CONSTRUCTION, with no header
// reads and no undefined behavior. Strings and ARRAYS both
// register; an array's entry knows its kind, and releasing one at
// rc 0 releases its OWNED slots first (the compiler marks them at
// pack time via avra_array_push_owned), so nesting reclaims by
// recursion. Reads of owned slots go through avra_array_get_owned,
// which retains — every managed read is a +1 the reader's scope
// releases, so aliasing shares the pointer while counts balance.
//
// TRAP CONTRACT: an impossible-at-runtime operation (index out of
// bounds) prints one line to stderr — worded EXACTLY like the
// evaluator's refusal — and exits 1. The divergence registry pins
// both sides.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// ── The ownership registry ──────────────────────────────────────

// A box's KIND decides how it reclaims and clones: 0 a plain
// allocation, 1 an array, 2 a map.
typedef struct {
    void* ptr;
    int64_t rc;
    int64_t kind;
} OwnEntry;

static OwnEntry* g_own = NULL;
static size_t g_own_cap = 0;
static size_t g_own_len = 0;

static size_t own_slot(OwnEntry* table, size_t cap, void* p) {
    size_t h = ((uintptr_t)p >> 4) * 2654435761u;
    size_t i = h & (cap - 1);
    while (table[i].ptr != NULL && table[i].ptr != p) {
        i = (i + 1) & (cap - 1);
    }
    return i;
}

static void own_grow(void) {
    size_t cap = g_own_cap ? g_own_cap * 2 : 1024;
    OwnEntry* next = (OwnEntry*)calloc(cap, sizeof(OwnEntry));
    for (size_t i = 0; i < g_own_cap; i++) {
        if (g_own[i].ptr != NULL) {
            next[own_slot(next, cap, g_own[i].ptr)] = g_own[i];
        }
    }
    free(g_own);
    g_own = next;
    g_own_cap = cap;
}

// Registers a fresh allocation as owned, refcount 1.
static void* own_kind(void* p, int64_t kind) {
    if (p == NULL) return p;
    if (g_own_len * 10 >= g_own_cap * 7) own_grow();
    size_t i = own_slot(g_own, g_own_cap, p);
    g_own[i].ptr = p;
    g_own[i].rc = 1;
    g_own[i].kind = kind;
    g_own_len++;
    return p;
}

static void* own(void* p) {
    return own_kind(p, 0);
}

static OwnEntry* owned(void* p) {
    if (g_own_cap == 0 || p == NULL) return NULL;
    size_t i = own_slot(g_own, g_own_cap, p);
    return g_own[i].ptr == p ? &g_own[i] : NULL;
}

void avra_rc_retain(void* p) {
    OwnEntry* e = owned(p);
    if (e) e->rc++;
}

// Note: removal leaves the entry in place with ptr intact would
// break probing — entries are cleared and the table tolerates the
// resulting probe holes by re-inserting on grow. Deletion keeps a
// tombstone via rc 0 and a NULLed ptr is never left mid-chain;
// instead the slot is re-linked by rehashing the cluster.
static void own_delete(size_t i) {
    g_own[i].ptr = NULL;
    g_own[i].rc = 0;
    g_own_len--;
    // Re-insert the cluster after the hole so probing stays sound.
    size_t j = (i + 1) & (g_own_cap - 1);
    while (g_own[j].ptr != NULL) {
        OwnEntry moved = g_own[j];
        g_own[j].ptr = NULL;
        g_own_len--;
        g_own[own_slot(g_own, g_own_cap, moved.ptr)] = moved;
        g_own_len++;
        j = (j + 1) & (g_own_cap - 1);
    }
}

static void array_reclaim(void* p);
static void map_reclaim(void* p);
static void* box_clone(void* p);

void avra_rc_release(void* p) {
    if (g_own_cap == 0 || p == NULL) return;
    size_t i = own_slot(g_own, g_own_cap, p);
    if (g_own[i].ptr != p) return;
    g_own[i].rc--;
    if (g_own[i].rc <= 0) {
        int64_t kind = g_own[i].kind;
        // The entry dies FIRST: slot releases below may reshape the
        // table, and a dead entry must not be found mid-walk.
        own_delete(i);
        if (kind == 1) {
            array_reclaim(p);
        } else if (kind == 2) {
            map_reclaim(p);
        } else {
            free(p);
        }
    }
}

// ── The trap contract ───────────────────────────────────────────

static void avra_trap(const char* msg) {
    fputs("avra: ", stderr);
    fputs(msg, stderr);
    fputc('\n', stderr);
    exit(1);
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
    char* buf = (char*)malloc(24);
    snprintf(buf, 24, "%lld", (long long)v);
    return (const char*)own(buf);
}

// A bool's keyword — static, unowned.
const char* avra_bool_text(int64_t b) {
    return b != 0 ? "true" : "false";
}

// ── Aggregates: int64 slot arrays ───────────────────────────────
// Slots carry every value category: ints and bools directly,
// pointers cast down by the compiler (rt_arg). Arrays are
// unregistered — see the memory model note.

typedef struct {
    int64_t cap;
    int64_t len;
    int64_t* data;
    // Which slots hold OWNED managed values — marked at pack time
    // by the compiler, walked at reclaim. Parallel to data.
    uint8_t* owned;
} AvraArray;

void* avra_array_new(void) {
    AvraArray* a = (AvraArray*)malloc(sizeof(AvraArray));
    a->cap = 8;
    a->len = 0;
    a->data = (int64_t*)malloc((size_t)a->cap * sizeof(int64_t));
    a->owned = (uint8_t*)calloc((size_t)a->cap, 1);
    return own_kind(a, 1);
}

// Releases every owned slot, then the array itself. The registry
// entry is already gone — see avra_rc_release.
static void array_reclaim(void* p) {
    AvraArray* a = (AvraArray*)p;
    for (int64_t i = 0; i < a->len; i++) {
        if (a->owned[i]) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    free(a->data);
    free(a->owned);
    free(a);
}

void avra_array_push(void* arr, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == a->cap) {
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
void* avra_insist(void* p) {
    if (!p) { avra_trap("unwrapped an absent value"); }
    return p;
}

// `v!` on a PAIR nullable — the flag guards, the value passes.
int64_t avra_insist_scalar(int64_t present, int64_t value) {
    if (!present) { avra_trap("unwrapped an absent value"); }
    return value;
}

int64_t avra_array_get(void* arr, int64_t i) {
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
// currently holds. Unregistered content no-ops by construction.
void avra_cell_release(void* slot) {
    avra_rc_release(*(void**)slot);
}

// ── Places: copy-on-write ───────────────────────────────────────

// A shallow clone that takes its own reference to every owned
// slot — exactly what reclaim would release. Registered, rc 1.
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
// the one. Unregistered pointers are never boxes a place opens.
static int is_shared(void* p) {
    OwnEntry* e = owned(p);
    return e != NULL && e->rc > 1;
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
    AvraMap* m = (AvraMap*)malloc(sizeof(AvraMap));
    m->keys = (AvraArray*)avra_array_new();
    m->vals = (AvraArray*)avra_array_new();
    m->index = NULL;
    m->icap = 0;
    map_index_rebuild(m, 16);
    return own_kind(m, 2);
}

// Releases both arrays (their owned slots follow), then the map.
static void map_reclaim(void* p) {
    AvraMap* m = (AvraMap*)p;
    avra_rc_release(m->keys);
    avra_rc_release(m->vals);
    free(m->index);
    free(m);
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
// retained), the index rebuilt. Registered, rc 1.
static void* map_clone(AvraMap* m) {
    AvraMap* c = (AvraMap*)malloc(sizeof(AvraMap));
    c->keys = (AvraArray*)array_clone(m->keys);
    c->vals = (AvraArray*)array_clone(m->vals);
    c->index = NULL;
    c->icap = 0;
    map_index_rebuild(c, m->icap);
    return own_kind(c, 2);
}

// The clone a place opens — by the box's kind.
static void* box_clone(void* p) {
    OwnEntry* e = owned(p);
    return (e && e->kind == 2) ? map_clone((AvraMap*)p) : array_clone((AvraArray*)p);
}

// ── Text building ───────────────────────────────────────────────

// Concatenate string slots with `sep` between — what interpolation
// joins. Owned.
const char* avra_str_join(void* arr, const char* sep) {
    AvraArray* a = (AvraArray*)arr;
    size_t sep_len = strlen(sep);
    size_t total = 1;
    for (int64_t i = 0; i < a->len; i++) {
        const char* s = (const char*)a->data[i];
        total += s ? strlen(s) : 0;
        if (i > 0) total += sep_len;
    }
    char* buf = (char*)malloc(total);
    char* p = buf;
    for (int64_t i = 0; i < a->len; i++) {
        if (i > 0) { memcpy(p, sep, sep_len); p += sep_len; }
        const char* s = (const char*)a->data[i];
        if (s) { size_t l = strlen(s); memcpy(p, s, l); p += l; }
    }
    *p = '\0';
    return (const char*)own(buf);
}

// A bracketed element list — shared by the typed printers below.
static const char* list_text(void* arr, const char* (*text)(int64_t)) {
    AvraArray* a = (AvraArray*)arr;
    void* parts = avra_array_new();
    for (int64_t i = 0; i < a->len; i++) {
        avra_array_push(parts, (int64_t)(uintptr_t)text(a->data[i]));
    }
    const char* body = avra_str_join(parts, ", ");
    size_t l = strlen(body);
    char* buf = (char*)malloc(l + 3);
    buf[0] = '[';
    memcpy(buf + 1, body, l);
    buf[l + 1] = ']';
    buf[l + 2] = '\0';
    return (const char*)own(buf);
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
    return v ? (const char*)(uintptr_t)v : "null";
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
    int64_t v = a->data[a->len];
    if (a->owned[a->len]) {
        a->owned[a->len] = 0;
        avra_rc_release((void*)(uintptr_t)v);
    }
    return v;
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
    char* buf = (char*)malloc(n + 1);
    memcpy(buf, s, n);
    buf[n] = '\0';
    return (const char*)own(buf);
}

// A list slot holding fresh text — the list owns the one reference.
static void push_fresh_text(void* arr, const char* s, size_t n) {
    avra_array_push(arr, (int64_t)(uintptr_t)str_owned(s, n));
    AvraArray* a = (AvraArray*)arr;
    a->owned[a->len - 1] = 1;
}

const char* avra_str_substring(const char* s, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)strlen(s);
    if (lo < 0) lo = 0;
    if (hi > n) hi = n;
    if (lo >= hi) return str_owned("", 0);
    return str_owned(s + lo, (size_t)(hi - lo));
}

int64_t avra_str_contains(const char* s, const char* needle) {
    return strstr(s, needle) != NULL;
}

int64_t avra_str_starts_with(const char* s, const char* prefix) {
    return strncmp(s, prefix, strlen(prefix)) == 0;
}

int64_t avra_str_ends_with(const char* s, const char* suffix) {
    size_t n = strlen(s);
    size_t m = strlen(suffix);
    return m <= n && memcmp(s + n - m, suffix, m) == 0;
}

// The first position of `needle`, or -1.
int64_t avra_str_index_of(const char* s, const char* needle) {
    const char* at = strstr(s, needle);
    return at ? (int64_t)(at - s) : -1;
}

// The byte at `i` as a code — a trap past the text, worded like a
// list's.
int64_t avra_str_char_code(const char* s, int64_t i) {
    int64_t n = (int64_t)strlen(s);
    if (i < 0 || i >= n) {
        char msg[80];
        snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
                 (long long)i, (long long)n);
        avra_trap(msg);
    }
    return (unsigned char)s[i];
}

static int is_blank(char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

const char* avra_str_trim(const char* s) {
    size_t n = strlen(s);
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
    char* buf = (char*)malloc(n + count * tl - count * fl + 1);
    char* w = buf;
    const char* r = s;
    for (const char* p = strstr(r, from); p; p = strstr(r, from)) {
        memcpy(w, r, (size_t)(p - r));
        w += p - r;
        memcpy(w, to, tl);
        w += tl;
        r = p + fl;
    }
    strcpy(w, r);
    return (const char*)own(buf);
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

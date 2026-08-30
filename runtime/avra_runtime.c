// The Avra runtime — the native half of the language's semantics.
//
// Every function here is a CONTRACT the compiler lowers against:
// what `${x}` prints, what `==` means for strings, what an index
// out of bounds does. Language semantics live in this tree, in this
// file — never in a dependency.
//
// MEMORY MODEL (v1): an ownership REGISTRY, not headers and not
// trust. Every allocation this runtime hands to a program is
// registered with refcount 1. avra_rc_retain / avra_rc_release act
// only on registered pointers — statics, literals, and foreign
// pointers pass through as no-ops BY CONSTRUCTION, with no header
// reads and no undefined behavior. Owned strings genuinely reclaim
// at zero. Aggregates (arrays) are deliberately unregistered until
// ownership analysis arrives for managed elements — releasing an
// array is a no-op, and that is a choice this file states, not an
// accident.
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

typedef struct {
    void* ptr;
    int64_t rc;
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
static void* own(void* p) {
    if (p == NULL) return p;
    if (g_own_len * 10 >= g_own_cap * 7) own_grow();
    size_t i = own_slot(g_own, g_own_cap, p);
    g_own[i].ptr = p;
    g_own[i].rc = 1;
    g_own_len++;
    return p;
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

void avra_rc_release(void* p) {
    if (g_own_cap == 0 || p == NULL) return;
    size_t i = own_slot(g_own, g_own_cap, p);
    if (g_own[i].ptr != p) return;
    g_own[i].rc--;
    if (g_own[i].rc <= 0) {
        free(p);
        own_delete(i);
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
} AvraArray;

void* avra_array_new(void) {
    AvraArray* a = (AvraArray*)malloc(sizeof(AvraArray));
    a->cap = 8;
    a->len = 0;
    a->data = (int64_t*)malloc((size_t)a->cap * sizeof(int64_t));
    return a;
}

void avra_array_push(void* arr, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == a->cap) {
        a->cap *= 2;
        a->data = (int64_t*)realloc(a->data, (size_t)a->cap * sizeof(int64_t));
    }
    a->data[a->len] = v;
    a->len++;
}

int64_t avra_array_len(void* arr) {
    return ((AvraArray*)arr)->len;
}

// Worded exactly like the evaluator's refusal — the divergence
// registry pins both.
// `v!` — slot 1 of a tagged value, insisting slot 0 says PRESENT.
// The writer claimed absence would not happen; if it does the
// program STOPS rather than reading a slot never written.
int64_t avra_unwrap(void* v) {
    AvraArray* a = (AvraArray*)v;
    if (!v || a->len < 2 || a->data[0] == 0) {
        avra_trap("unwrapped an absent value");
    }
    return a->data[1];
}

// `v!` on a NICHE nullable — the pointer IS the value and absence is
// the null pointer, so insisting is identity through the guard. The
// wording matches avra_unwrap and the evaluator: the divergence
// registry pins all three.
void* avra_insist(void* p) {
    if (!p) { avra_trap("unwrapped an absent value"); }
    return p;
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

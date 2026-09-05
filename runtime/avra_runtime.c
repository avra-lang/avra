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
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

// ── The box header ──────────────────────────────────────────────

// A box's KIND decides how it reclaims and clones: 0 a plain
// allocation, 1 an array, 2 a map. Below zero it is not counted:
// STATIC is immortal, DEAD is the guard's mark on a reclaimed box.
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3 };

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

// SIZE CLASSES: a box of up to CLASS_MAX payload bytes is recycled
// through a per-class free list instead of handed back to malloc —
// a parse mints and drops a record per match, and malloc and free
// were a third of it. A record's header `len` holds its payload
// bytes; a string's holds its text length, one less than its
// payload. The class follows from either; past the classes a box is
// malloc's.
// A list is BOUNDED: it holds the churn (a parse mints and drops
// the same records by the million) and no more — past LIST_LIMIT a
// freed box goes back to malloc, whose pools any size can reuse.
// Unbounded lists hoarded a phase's freed memory by class and
// nearly doubled a gate's peak.
#define CLASS_BYTES 16
#define CLASS_MAX 256
#define CLASSES (CLASS_MAX / CLASS_BYTES + 1)
#define LIST_LIMIT 16384
static Header* g_free[CLASSES];
static int64_t g_free_len[CLASSES];

// THE ACCOUNTING (AVRA_MEM_STATS=1): live bytes by what they hold —
// records, strings, list boxes and their buffers, map boxes and their
// indexes — with each one's high-water mark, printed at exit. What a
// 2.4 GB compiler run is MADE OF, category by category.
enum { ACC_RECORD, ACC_STR, ACC_LIST, ACC_BUF, ACC_MAP, ACC_INDEX, ACC_KINDS };
static const char* g_acc_name[ACC_KINDS] = { "records", "strings", "list boxes", "list buffers", "map boxes", "map indexes" };
static int64_t g_acc_live[ACC_KINDS];
static int64_t g_acc_peak[ACC_KINDS];
static int64_t g_acc_total_live = 0;
static int64_t g_acc_total_peak = 0;
static int g_acc_on = -1;
// list buffers by capacity (log2), live bytes and count, with peaks
#define CAP_BUCKETS 40
static int64_t g_cap_live[CAP_BUCKETS];
static int64_t g_cap_peak[CAP_BUCKETS];
static int64_t g_cap_count[CAP_BUCKETS];

static int cap_bucket(int64_t cap) {
    int b = 0;
    while ((cap >> b) > 1 && b < CAP_BUCKETS - 1) b++;
    return b;
}

// LIVE LIST BYTES BY THE SITE THAT MADE THEM — the return address of
// the constructor, which is inside the Avra fn that called it; the
// report prints it unslid, so `atos -o build/avra <addr>` names it.
#define SITES 8192
typedef struct { void* site; int64_t live; int64_t peak; int64_t count; int64_t made; void* sample; } Site;
static Site g_sites[SITES];
static int64_t g_site_slots = 0;

static Site* site_of(void* site) {
    uint64_t i = ((uint64_t)(uintptr_t)site >> 2) & (SITES - 1);
    while (g_sites[i].site != NULL && g_sites[i].site != site) i = (i + 1) & (SITES - 1);
    if (g_sites[i].site == NULL) {
        if (g_site_slots >= SITES - 1) return NULL;
        g_sites[i].site = site;
        g_site_slots++;
    }
    return &g_sites[i];
}

// a clone's site is the Avra fn that wrote to a shared value, not
// the runtime's own clone path
static void* g_clone_site = NULL;
// the hundredth box a site made, whose life the guard can replay
static void* g_sample_next = NULL;
static void rc_history(void* p);

static void acc_site(void* site, int64_t bytes, int64_t count) {
    if (site == NULL) return;
    Site* s = site_of(site);
    if (s == NULL) return;
    s->live += bytes;
    s->count += count;
    if (count > 0) s->made += count;
    if (count > 0 && s->made == 100) s->sample = g_sample_next;
    if (s->live > s->peak) s->peak = s->live;
}

static void acc_buf(int64_t cap, int64_t bytes, int64_t count) {
    int b = cap_bucket(cap);
    g_cap_live[b] += bytes;
    g_cap_count[b] += count;
    if (g_cap_live[b] > g_cap_peak[b]) g_cap_peak[b] = g_cap_live[b];
}

static void acc_report(void) {
    fprintf(stderr, "mem: peak %lld MB in all\n", (long long)(g_acc_total_peak >> 20));
    for (int k = 0; k < ACC_KINDS; k++) {
        fprintf(stderr, "mem:   %-13s peak %6lld MB, now %6lld MB\n", g_acc_name[k],
                (long long)(g_acc_peak[k] >> 20), (long long)(g_acc_live[k] >> 20));
    }
    intptr_t slide = 0;
#ifdef __APPLE__
    slide = _dyld_get_image_vmaddr_slide(0);
#endif
    for (int shown = 0; shown < 24; shown++) {
        Site* top = NULL;
        for (int i = 0; i < SITES; i++) {
            if (g_sites[i].site && g_sites[i].peak >= 0 && (top == NULL || g_sites[i].peak > top->peak)) top = &g_sites[i];
        }
        if (top == NULL || top->peak < (1 << 20)) break;
        fprintf(stderr, "mem:   site 0x%llx peak %6lld MB, now %6lld MB, %lld live of %lld made\n",
                (unsigned long long)((uintptr_t)top->site - (uintptr_t)slide), (long long)(top->peak >> 20),
                (long long)(top->live >> 20), (long long)top->count, (long long)top->made);
        top->peak = -1;
    }
    // Under the guard nothing is freed, so a sample box still COUNTED
    // at exit is one whose references never balanced: its life, replayed,
    // names the retain nobody released.
    if (getenv("AVRA_RC_GUARD")) {
        int replayed = 0;
        for (int i = 0; i < SITES && replayed < 6; i++) {
            Site* st = &g_sites[i];
            Header* sh = st->site && st->sample ? hdr(st->sample) : NULL;
            if (sh == NULL || sh->rc <= 0) continue;
            fprintf(stderr, "mem:   LEAK at site 0x%llx (%lld made): its hundredth box ends at rc %d — its life (unslid):\n",
                    (unsigned long long)((uintptr_t)st->site - (uintptr_t)slide), (long long)st->made, sh->rc);
            rc_history(st->sample);
            replayed++;
        }
    }
    for (int b = 0; b < CAP_BUCKETS; b++) {
        if (g_cap_peak[b] == 0) continue;
        fprintf(stderr, "mem:     cap %-9lld peak %6lld MB, now %6lld MB in %lld buffers\n",
                (long long)1 << b, (long long)(g_cap_peak[b] >> 20), (long long)(g_cap_live[b] >> 20), (long long)g_cap_count[b]);
    }
}

static int accounting(void) {
    if (g_acc_on < 0) {
        g_acc_on = getenv("AVRA_MEM_STATS") != NULL;
        if (g_acc_on) atexit(acc_report);
    }
    return g_acc_on;
}

static void acc_add(int k, int64_t bytes) {
    if (!accounting()) return;
    g_acc_live[k] += bytes;
    g_acc_total_live += bytes;
    if (g_acc_live[k] > g_acc_peak[k]) g_acc_peak[k] = g_acc_live[k];
    if (g_acc_total_live > g_acc_total_peak) g_acc_total_peak = g_acc_total_live;
}

static int acc_kind_of(int32_t kind) {
    return kind == KIND_ARRAY ? ACC_LIST : kind == KIND_MAP ? ACC_MAP : kind == KIND_STR ? ACC_STR : ACC_RECORD;
}

static size_t class_of(size_t bytes) {
    size_t cls = (bytes + CLASS_BYTES - 1) / CLASS_BYTES;
    return cls < CLASSES ? cls : 0;
}

// A fresh box of `size` payload bytes, refcount 1.
static void* box_alloc(size_t size, int32_t kind) {
    size_t bytes = size > 0 ? size : 1;
    size_t cls = class_of(bytes);
    Header* h = cls ? g_free[cls] : NULL;
    if (h) {
        g_free[cls] = *(Header**)(h + 1);
        g_free_len[cls]--;
    } else {
        h = (Header*)malloc(sizeof(Header) + (cls ? cls * CLASS_BYTES : bytes));
    }
    h->tag = AVRA_TAG;
    h->kind = kind;
    h->rc = 1;
    h->len = (uint32_t)bytes;
    acc_add(acc_kind_of(kind), (int64_t)(sizeof(Header) + bytes));
    return (void*)(h + 1);
}

// A string box of `n` bytes plus its terminator, its length known.
// An owned string wears KIND_STR so its class can be read back.
static char* str_box(size_t n, int32_t kind) {
    char* buf = (char*)box_alloc(n + 1, kind == KIND_PLAIN ? KIND_STR : kind);
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
static size_t box_bytes(Header* h) {
    return h->kind == KIND_STR ? (size_t)h->len + 1 : (size_t)h->len;
}

static void box_free(void* p) {
    Header* h = (Header*)p - 1;
    size_t bytes = box_bytes(h);
    size_t cls = class_of(bytes);
    acc_add(acc_kind_of(h->kind), -(int64_t)(sizeof(Header) + bytes));
    h->tag = 0;
    if (cls && g_free_len[cls] < LIST_LIMIT) {
        *(Header**)(h + 1) = g_free[cls];
        g_free[cls] = h;
        g_free_len[cls]++;
    } else {
        free(h);
    }
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
            intptr_t sl = 0;
#ifdef __APPLE__
            sl = _dyld_get_image_vmaddr_slide(0);
#endif
            fprintf(stderr, "    %s from 0x%llx -> rc %lld\n",
                    g_log[i].delta > 0 ? "retain" : "release", (unsigned long long)((uintptr_t)g_log[i].at - (uintptr_t)sl), (long long)g_log[i].rc);
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

static void put_line(const char* s) {
    if (s) fputs(s, stdout);
    fputc('\n', stdout);
}

void avra_puts(const char* s) {
    put_line(s);
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
    // where it was made — the accounting's return address, else NULL
    void* site;
} AvraArray;

// ONE BUFFER holds a list's cells and, after them, its owned marks:
// one allocation per list, not two. A buffer of a small capacity
// (up to BUF_CLASSES doublings from ARRAY_FIRST) is recycled through
// a per-capacity free list; a bigger one is malloc's and grows in
// place.
#define ARRAY_FIRST 8
#define BUF_CLASSES 3
static void* g_buf_free[BUF_CLASSES];
static int64_t g_buf_free_len[BUF_CLASSES];

static size_t buf_bytes(int64_t cap) {
    return (size_t)cap * (sizeof(int64_t) + 1);
}

// The class of a capacity: 0 for ARRAY_FIRST, 1 for its double, …;
// -1 past the classes.
static int buf_class(int64_t cap) {
    int cls = 0;
    for (int64_t c = ARRAY_FIRST; c < cap; c *= 2) cls++;
    return cls < BUF_CLASSES ? cls : -1;
}

static int64_t* buf_alloc(int64_t cap) {
    acc_add(ACC_BUF, (int64_t)buf_bytes(cap));
    if (g_acc_on > 0) acc_buf(cap, (int64_t)buf_bytes(cap), 1);
    int cls = buf_class(cap);
    if (cls >= 0 && g_buf_free[cls]) {
        int64_t* buf = (int64_t*)g_buf_free[cls];
        g_buf_free[cls] = *(void**)buf;
        g_buf_free_len[cls]--;
        return buf;
    }
    return (int64_t*)malloc(buf_bytes(cap));
}

static void buf_free(int64_t* buf, int64_t cap) {
    acc_add(ACC_BUF, -(int64_t)buf_bytes(cap));
    if (g_acc_on > 0) acc_buf(cap, -(int64_t)buf_bytes(cap), -1);
    int cls = buf_class(cap);
    if (cls >= 0 && g_buf_free_len[cls] < LIST_LIMIT) {
        *(void**)buf = g_buf_free[cls];
        g_buf_free[cls] = buf;
        g_buf_free_len[cls]++;
    } else {
        free(buf);
    }
}

// The marks live after the cells; a fresh mark region is all zero.
static void array_marks(AvraArray* a) {
    a->owned = (uint8_t*)(a->data + a->cap);
}

void* avra_array_new(void) {
    AvraArray* a = (AvraArray*)box_alloc(sizeof(AvraArray), KIND_ARRAY);
    a->cap = ARRAY_FIRST;
    a->len = 0;
    a->data = buf_alloc(a->cap);
    array_marks(a);
    memset(a->owned, 0, (size_t)a->cap);
    a->site = NULL;
    if (g_acc_on > 0) {
        a->site = g_clone_site ? g_clone_site : __builtin_return_address(0);
        g_sample_next = a;
        acc_site(a->site, (int64_t)(sizeof(Header) + sizeof(AvraArray) + buf_bytes(a->cap)), 1);
    }
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
    if (a->site) acc_site(a->site, -(int64_t)(sizeof(Header) + sizeof(AvraArray) + buf_bytes(a->cap)), -1);
    buf_free(a->data, a->cap);
    box_free(a);
}

// No list holds more cells than this: a capacity past it is a
// corrupted box, and the program stops rather than asking the
// machine for the memory.
#define CELL_CEILING ((int64_t)1 << 31)

// Doubles the capacity: a classed buffer moves to the next class, a
// big one grows in place; the marks follow the cells to their new
// place, the new marks zero.
static void array_grow(AvraArray* a) {
    int64_t old_cap = a->cap;
    int64_t cap = old_cap * 2;
    int64_t* buf;
    if (buf_class(old_cap) >= 0) {
        buf = buf_alloc(cap);
        memcpy(buf, a->data, (size_t)old_cap * sizeof(int64_t));
        memcpy((uint8_t*)(buf + cap), a->owned, (size_t)old_cap);
        buf_free(a->data, old_cap);
    } else {
        buf = (int64_t*)realloc(a->data, buf_bytes(cap));
        acc_add(ACC_BUF, (int64_t)(buf_bytes(cap) - buf_bytes(old_cap)));
        if (g_acc_on > 0) { acc_buf(old_cap, -(int64_t)buf_bytes(old_cap), -1); acc_buf(cap, (int64_t)buf_bytes(cap), 1); }
        memmove((uint8_t*)(buf + cap), (uint8_t*)(buf + old_cap), (size_t)old_cap);
    }
    a->data = buf;
    a->cap = cap;
    array_marks(a);
    memset(a->owned + a->len, 0, (size_t)(cap - a->len));
    if (a->site) acc_site(a->site, (int64_t)(buf_bytes(cap) - buf_bytes(old_cap)), 0);
}

void avra_array_push(void* arr, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == a->cap) {
        if (a->cap >= CELL_CEILING || a->cap <= 0) avra_trap("a list grew past any possible size — a corrupted box");
        array_grow(a);
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
    g_clone_site = __builtin_return_address(0);
    void* c = box_clone(p);
    g_clone_site = NULL;
    *(void**)slot = c;
    avra_rc_release(p);
    return c;
}

// The same one level down: the box in a slot, made unique in place.
void* avra_slot_unique(void* arr, int64_t i) {
    void* p = (void*)(uintptr_t)avra_array_get(arr, i);
    if (!is_shared(p)) return p;
    AvraArray* a = (AvraArray*)arr;
    g_clone_site = __builtin_return_address(0);
    void* c = box_clone(p);
    g_clone_site = NULL;
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
    acc_add(ACC_INDEX, (int64_t)((icap - m->icap) * (int64_t)sizeof(int64_t)));
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
    acc_add(ACC_INDEX, -(int64_t)(m->icap * (int64_t)sizeof(int64_t)));
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
    g_clone_site = __builtin_return_address(0);
    void* out = avra_array_new();
    g_clone_site = NULL;
    array_append(out, (AvraArray*)a, 0, ((AvraArray*)a)->len);
    array_append(out, (AvraArray*)b, 0, ((AvraArray*)b)->len);
    return out;
}

// A fresh list of the slots from lo up to hi, clamped to the list;
// nothing when lo is not below hi. Owned.
void* avra_array_slice(void* arr, int64_t lo, int64_t hi) {
    g_clone_site = __builtin_return_address(0);
    AvraArray* a = (AvraArray*)arr;
    if (lo < 0) lo = 0;
    if (hi > a->len) hi = a->len;
    void* out = avra_array_new();
    g_clone_site = NULL;
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
extern char** environ;
#include <dirent.h>
#include <time.h>
#include <unistd.h>

void println(const char* s) {
    put_line(s);
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

// A program run with its arguments AS A LIST — no shell, so no
// character in any argument means anything but itself. `args` is
// an Avra `List<string>`. The verdict is the shell's convention
// without the shell: the exit code, 128+signal when a signal
// killed it, 127 when it could not start — so a wreck never reads
// as a small exit code, and never as SUCCESS.
int64_t avra_spawn_status(const char* prog, void* args) {
    AvraArray* a = (AvraArray*)args;
    char** argv = (char**)malloc((size_t)(a->len + 2) * sizeof(char*));
    argv[0] = (char*)prog;
    for (int64_t i = 0; i < a->len; i++) argv[i + 1] = (char*)(uintptr_t)a->data[i];
    argv[a->len + 1] = NULL;
    // what this program printed comes out before the child's words:
    // a buffered stdout is flushed at the seam, or a pipe reorders
    fflush(NULL);
    pid_t pid;
    int started = posix_spawnp(&pid, prog, NULL, NULL, argv, environ);
    free(argv);
    if (started != 0) return 127;
    int status;
    if (waitpid(pid, &status, 0) < 0) return 127;
    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    return (int64_t)WEXITSTATUS(status);
}

// THIS PROGRAM AGAIN, with new words: the image is replaced, so the
// memory the program held is gone — how a heavy phase hands the
// light one a fresh process. Answers only when it cannot: 127.
static int self_path(char* buf, size_t cap) {
#ifdef __APPLE__
    uint32_t n = (uint32_t)cap;
    return _NSGetExecutablePath(buf, &n) == 0;
#else
    ssize_t n = readlink("/proc/self/exe", buf, cap - 1);
    if (n < 0) return 0;
    buf[n] = 0;
    return 1;
#endif
}

int64_t avra_exec_self(void* args) {
    AvraArray* a = (AvraArray*)args;
    char self[4096];
    if (!self_path(self, sizeof self)) return 127;
    char** argv = (char**)malloc((size_t)(a->len + 2) * sizeof(char*));
    argv[0] = self;
    for (int64_t i = 0; i < a->len; i++) argv[i + 1] = (char*)(uintptr_t)a->data[i];
    argv[a->len + 1] = NULL;
    if (accounting()) acc_report();
    fflush(NULL);
    execv(self, argv);
    free(argv);
    return 127;
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

// THE CAPTURE: between avra_capture_begin and avra_capture_end, fd 1
// is a temp file — a child process's output lands there too — and
// the end answers the text written, its final newline dropped.
static int g_cap_saved = -1;
static int g_cap_file = -1;

void avra_capture_begin(void) {
    if (g_cap_file >= 0) avra_trap("capture: begun twice");
    fflush(stdout);
    char path[] = "/tmp/avra-capture-XXXXXX";
    g_cap_file = mkstemp(path);
    if (g_cap_file < 0) avra_trap("capture: no temp file");
    unlink(path);
    g_cap_saved = dup(1);
    dup2(g_cap_file, 1);
}

const char* avra_capture_end(void) {
    if (g_cap_file < 0) avra_trap("capture: ended before it began");
    fflush(stdout);
    dup2(g_cap_saved, 1);
    close(g_cap_saved);
    g_cap_saved = -1;
    off_t size = lseek(g_cap_file, 0, SEEK_END);
    lseek(g_cap_file, 0, SEEK_SET);
    char* buf = (char*)malloc((size_t)size + 1);
    size_t got = 0;
    while (got < (size_t)size) {
        ssize_t n = read(g_cap_file, buf + got, (size_t)size - got);
        if (n <= 0) break;
        got += (size_t)n;
    }
    close(g_cap_file);
    g_cap_file = -1;
    if (got > 0 && buf[got - 1] == '\n') got--;
    const char* out = str_owned(buf, got);
    free(buf);
    return out;
}

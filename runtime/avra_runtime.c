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
#include <math.h>
#include <stdint.h>
#include <errno.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

// ── The box header ──────────────────────────────────────────────

// A box's KIND decides how it reclaims and clones: 0 a plain
// allocation, 1 an array, 2 a map, 3 text, 4 octets. Below zero it
// is not counted: STATIC is immortal, DEAD is the guard's mark on a
// reclaimed box.
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3, KIND_BYTES = 4 };

// AN IMMORTAL BOX KEEPS ITS SHAPE. A `once` answer lives for the
// process, so retain and release must no-op on it — which the
// `kind < 0` test already gives free — but `box_clone` still has to
// know whether it is a MAP, because a write through a shared value
// CLONES it, and a map cloned as an array is memory corruption.
// Overwriting the kind with KIND_STATIC loses exactly that. So
// immortality is a REFLECTION of the kind and never a replacement:
// negative for every shape, and it decodes back.
#define KIND_IMMORTAL(k) (-((k) + 4))
#define IS_IMMORTAL(k)   ((k) <= -4)
#define KIND_SHAPE(k)    (IS_IMMORTAL(k) ? -(k) - 4 : (k))

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
enum { ACC_RECORD, ACC_STR, ACC_BYTES, ACC_LIST, ACC_BUF, ACC_MAP, ACC_INDEX, ACC_KINDS };
// KEYED, never positional: a category inserted mid-enum would take its
// neighbour's name under a positional initialiser, and the report is
// read by whoever is asking where the memory went.
static const char* g_acc_name[ACC_KINDS] = {
    [ACC_RECORD] = "records",    [ACC_STR]   = "strings",
    [ACC_BYTES] = "bytes",
    [ACC_LIST]   = "list boxes", [ACC_BUF]   = "list buffers",
    [ACC_MAP]    = "map boxes",  [ACC_INDEX] = "map indexes",
};
static int64_t g_acc_live[ACC_KINDS];
static int64_t g_acc_peak[ACC_KINDS];
static int64_t g_acc_total_live = 0;
static int64_t g_acc_total_peak = 0;
static int g_acc_on = 0;
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
// the table is kept under half full, and a probe gives up at 64
// steps: a full table cost a suite compile a minute of probing
#define SITES 65536
typedef struct { void* site; int64_t live; int64_t peak; int64_t count; int64_t made; void* sample; } Site;
static Site g_sites[SITES];
static int64_t g_site_slots = 0;

static Site* site_in(Site* tbl, int64_t* slots, void* site) {
    uint64_t i = ((uint64_t)(uintptr_t)site >> 2) & (SITES - 1);
    for (int step = 0; step < 64; step++) {
        if (tbl[i].site == site) return &tbl[i];
        if (tbl[i].site == NULL) {
            if (*slots >= SITES / 2) return NULL;
            tbl[i].site = site;
            (*slots)++;
            return &tbl[i];
        }
        i = (i + 1) & (SITES - 1);
    }
    return NULL;
}

static Site* site_of(void* site) { return site_in(g_sites, &g_site_slots, site); }

// THE CENSUS (build with -DAVRA_CENSUS; `make census`): exact call
// counts, not a sample. Refcount traffic is the compiler's largest
// single cost, and a sampling profiler charges a cascade to whoever
// happened to be on the stack. Counting costs 8% of a run, so it is
// a SEPARATE BUILD and the shipping runtime carries none of it.
#ifdef AVRA_CENSUS
#define CENSUS(x) x

static int64_t g_rc_retains, g_rc_releases, g_rc_frees, g_list_gets, g_list_pushes;
static int64_t g_once_reads, g_once_steps;

// The per-caller tables (AVRA_CENSUS_SITES=1). A list write is the
// compiler's commonest single act, so writes are charged to the
// runtime fn that makes them; a concat or a clone is ONE call and
// many writes, so a whole-value copy is charged to the Avra fn that
// asked for it, where the push census would say only "concat".
static Site g_push_sites[SITES];
static int64_t g_push_slots = 0;
static Site g_copy_sites[SITES];
static int64_t g_copy_slots = 0;
static int g_sites_census = 0;

static void note_push(void* site) {
    if (!g_sites_census) return;
    Site* s = site_in(g_push_sites, &g_push_slots, site);
    if (s) s->made++;
}

static void note_copy(void* site) {
    if (!g_sites_census) return;
    Site* s = site_in(g_copy_sites, &g_copy_slots, site);
    if (s) s->made++;
}

// A RETAIN'S CALLER. The conditional ABI's prize is the retain
// traffic at CALL SEATS, and `retained_args` reaches `.Call`/`.CallPtr`
// alone — a managed list read (`avra_array_get_owned`) and a cell
// retain too, and neither is reachable. The total says nothing about
// the split, so a seat count and a self-time share are measured on
// DIFFERENT AXES and do not multiply. This charges each retain to the
// Avra fn that asked for it, which is the weight that makes them one
// axis again. Census-only: the shipping runtime carries no such read.
static Site g_retain_sites[SITES];
static int64_t g_retain_slots = 0;

static void note_retain(void* site) {
    if (!g_sites_census) return;
    Site* s = site_in(g_retain_sites, &g_retain_slots, site);
    if (s) s->made++;
}

// A table's heaviest callers, most first. A printed row is SPENT —
// its count goes negative — so the next pass finds the next one.
static void report_made(const char* label, Site* tbl, int limit, intptr_t slide) {
    for (int shown = 0; shown < limit; shown++) {
        Site* top = NULL;
        for (int i = 0; i < SITES; i++) {
            if (tbl[i].site && tbl[i].made > 0 &&
                (top == NULL || tbl[i].made > top->made)) top = &tbl[i];
        }
        if (top == NULL) return;
        fprintf(stderr, "%s: site %p %lld\n", label,
                (void*)((char*)top->site - slide), (long long)top->made);
        top->made = -top->made;
    }
}
#else
#define CENSUS(x)
#endif

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
#ifdef AVRA_CENSUS
    fprintf(stderr, "rc: %lld retains, %lld releases, %lld reclaims\n",
            (long long)g_rc_retains, (long long)g_rc_releases, (long long)g_rc_frees);
    fprintf(stderr, "rc: %lld list reads, %lld list writes\n",
            (long long)g_list_gets, (long long)g_list_pushes);
    fprintf(stderr, "once: %lld reads, %lld pointer compares\n",
            (long long)g_once_reads, (long long)g_once_steps);
#endif

    fprintf(stderr, "mem: peak %lld MB in all\n", (long long)(g_acc_total_peak >> 20));
    for (int k = 0; k < ACC_KINDS; k++) {
        fprintf(stderr, "mem:   %-13s peak %6lld MB, now %6lld MB\n", g_acc_name[k],
                (long long)(g_acc_peak[k] >> 20), (long long)(g_acc_live[k] >> 20));
    }
    intptr_t slide = 0;
#ifdef __APPLE__
    slide = _dyld_get_image_vmaddr_slide(0);
#endif
#ifdef AVRA_CENSUS
    if (g_sites_census) {
        report_made("copy", g_copy_sites, 12, slide);
        report_made("push", g_push_sites, 16, slide);
        report_made("retain", g_retain_sites, 20, slide);
    }
#endif
    const char* wanted = getenv("AVRA_MEM_SITES");
    int limit = wanted ? atoi(wanted) : 24;
    for (int shown = 0; shown < limit; shown++) {
        Site* top = NULL;
        for (int i = 0; i < SITES; i++) {
            if (g_sites[i].site && g_sites[i].peak >= 0 && (top == NULL || g_sites[i].peak > top->peak)) top = &g_sites[i];
        }
        if (top == NULL || top->peak < (wanted ? 1 : (1 << 20))) break;
        fprintf(stderr, "mem:   site 0x%llx peak %6lld MB, now %6lld MB, %lld live of %lld made\n",
                (unsigned long long)((uintptr_t)top->site - (uintptr_t)slide), (long long)(top->peak >> 20),
                (long long)(top->live >> 20), (long long)top->count, (long long)top->made);
        top->peak = -1;
    }
    // Under the guard nothing is freed, so a sample box still COUNTED
    // at exit is one whose references never balanced: its life, replayed,
    // names the retain nobody released.
    // AVRA_MEM_SITE=<unslid hex> replays that one site's sample
    // whatever its count; without it, every site whose sample never
    // balanced
    const char* asked = getenv("AVRA_MEM_SITE");
    uintptr_t asked_at = asked ? (uintptr_t)strtoull(asked, NULL, 16) + (uintptr_t)slide : 0;
    if (getenv("AVRA_RC_GUARD")) {
        int replayed = 0;
        for (int i = 0; i < SITES && replayed < 6; i++) {
            Site* st = &g_sites[i];
            Header* sh = st->site && st->sample ? hdr(st->sample) : NULL;
            if (sh == NULL) continue;
            if (asked_at ? (uintptr_t)st->site != asked_at : sh->rc <= 0) continue;
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

// Settled at load, for the reason `rc_guard_init` gives: a lazy
// getenv inside this carries into every allocation's fast path.
__attribute__((constructor))
static void acc_settled(void) {
    g_acc_on = getenv("AVRA_MEM_STATS") != NULL;
    if (g_acc_on) atexit(acc_report);
    CENSUS(g_sites_census = getenv("AVRA_CENSUS_SITES") != NULL);
}

static inline int accounting(void) { return g_acc_on; }

static void acc_add(int k, int64_t bytes) {
    if (!accounting()) return;
    g_acc_live[k] += bytes;
    g_acc_total_live += bytes;
    if (g_acc_live[k] > g_acc_peak[k]) g_acc_peak[k] = g_acc_live[k];
    if (g_acc_total_live > g_acc_total_peak) g_acc_total_peak = g_acc_total_live;
}

// EVERY KIND NAMED, so a new one is visible here rather than filed
// under whatever the chain ended in. C cannot demand exhaustiveness,
// so the arms are the record: an immortal string is still a STRING,
// and only a genuine record falls through.
static int acc_kind_of(int32_t kind) {
    switch (kind) {
        case KIND_ARRAY:  return ACC_LIST;
        case KIND_MAP:    return ACC_MAP;
        case KIND_STR:    return ACC_STR;
        case KIND_BYTES:  return ACC_BYTES;
        case KIND_STATIC: return ACC_STR;
        case KIND_PLAIN:  return ACC_RECORD;
        case KIND_DEAD:   return ACC_RECORD;
        default:          return ACC_RECORD;
    }
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

// A box of `n` payload bytes plus a terminator, its LENGTH in the
// header. The caller names the kind it means — no translation, so a
// new sized kind is one call and not a guess. Every kind made here
// allocates n+1 and must therefore join `box_bytes`'s `+1` arm.
static char* sized_box(size_t n, int32_t kind) {
    char* buf = (char*)box_alloc(n + 1, kind);
    ((Header*)buf - 1)->len = (uint32_t)n;
    return buf;
}

// A string's length in O(1) — the header's, or measured when the
// text is not a box. A ZERO LENGTH IS A LENGTH: distrusting it sent
// an EMPTY box to `strlen`, which discarded its header and answered
// from a terminator instead. That was right only because every text
// box is minted at n+1 with `buf[n]` written — a CONVENTION OF THE
// CALLERS, not a property of this function, and a live bug the day
// a box is allocated at exactly n, which is what a `Bytes` value is.
static size_t str_len(const char* s) {
    Header* h = hdr((void*)s);
    return h ? (size_t)h->len : strlen(s);
}

// The tag goes before the memory does: a stale release of a freed
// box then reads "not mine" instead of a count that is no longer
// anyone's.
// The ALLOCATION size of a box, which is what its size class is filed
// under. EVERY kind `sized_box` makes allocates n+1 and stores n, so
// every one of them is listed here — a new sized kind belongs in both
// places or in neither. C cannot demand that, so the arms are the
// record. KIND_STATIC was missing and under-reported by one: harmless
// only because a static box is immortal and `box_free` never sees
// one, which is safety by immortality rather than by arithmetic.
static size_t box_bytes(Header* h) {
    switch (h->kind) {
        case KIND_STR:
        case KIND_BYTES:
        case KIND_STATIC: return (size_t)h->len + 1;
        default:          return (size_t)h->len;
    }
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
    char* buf = sized_box(n, KIND_STATIC);
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
// the guard's log budget, in events; AVRA_RC_LOG_BUDGET overrides it
static size_t g_log_budget = (size_t)1 << 23;
#define RC_LOG_BUDGET g_log_budget

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
static int g_guard = 0;

// THE GUARD IS READ ONCE, AT LOAD. Retain and release are the two
// hottest functions in the compiler, and a lazy `if (g_guard < 0)`
// inside them carries getenv's register pressure into the fast
// path — clang then sets up a 64-byte frame before the increment.
// Settling it here keeps that path a load, an add and a store.
__attribute__((constructor))
static void rc_guard_init(void) {
    g_guard = getenv("AVRA_RC_GUARD") != NULL;
    const char* budget = getenv("AVRA_RC_LOG_BUDGET");
    if (budget) g_log_budget = (size_t)strtoull(budget, NULL, 10);
}
static void* g_chain[64];
static int g_chain_len = 0;

// An array box's cell count, for the guard's report; -1 when the
// pointer is not an array this runtime owns.
static int64_t guard_len(void* p);

static inline int rc_guarded(void) { return g_guard; }

void avra_rc_dead_check(void* p, const char* what) {
    if (!rc_guarded()) return;
    Header* h = hdr(p);
    if (h && h->kind == KIND_DEAD) {
        fprintf(stderr, "avra: %s read a RELEASED box %p\n", what, p);
        abort();
    }
}

__attribute__((noinline, cold))
static void retain_noted(void* p, int32_t rc, void* ra) { rc_note(p, 1, ra, rc); }

void avra_rc_retain(void* p) {
    Header* h = hdr(p);
    if (h == NULL || h->kind < 0) return;
    CENSUS(g_rc_retains++);
    CENSUS(note_retain(__builtin_return_address(0)));
    h->rc++;
    if (__builtin_expect(rc_guarded(), 0)) retain_noted(p, h->rc, __builtin_return_address(0));
}

// The guard's release: the box is kept and marked dead, its cells
// poisoned; a second release of a dead box reports its history.
__attribute__((noinline, cold))
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

__attribute__((noinline))
static void release_dead(void* p, int32_t kind) {
    if (kind == KIND_ARRAY) {
        array_reclaim(p);
    } else if (kind == KIND_MAP) {
        map_reclaim(p);
    } else {
        box_free(p);
    }
}

void avra_rc_release(void* p) {
    Header* h = hdr(p);
    if (h == NULL) return;
    if (__builtin_expect(rc_guarded(), 0)) { release_guarded(p, h); return; }
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
    release_dead(p, h->kind);
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
void avra_trap(const char* msg) {
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

/* A LINE IS AS LONG AS ITS HEADER SAYS. `fputs` stops at the first
   NUL, so a line holding one was printed truncated with nothing said —
   and the seam's trap does not govern this seat, because writing bytes
   RESOLVES nothing and a correct answer exists: write all of them.
   Making it correct is what lets its row be marked `inert` honestly. */
static void put_line(const char* s) {
    if (s) fwrite(s, 1, str_len(s), stdout);
    fputc('\n', stdout);
}

void avra_puts(const char* s) {
    put_line(s);
}

// ── Strings ─────────────────────────────────────────────────────

// Value equality; null equals only null.
// TEXT IS A LENGTH AND BYTES, NEVER A TERMINATOR. A NUL is a
// character like any other — `from_codepoint(0)` mints one with no
// foreign input at all — so a comparison that stops at the first one
// answers about a PREFIX and calls it the whole string. `"ab\0cd"`
// read EQUAL to `"ab"` while `.length` said 5. The length comes
// first: unequal lengths are unequal text in O(1), where `strcmp`
// scanned to the first difference.
int64_t avra_streq(const char* a, const char* b) {
    if (a == NULL || b == NULL) return a == b;
    size_t la = str_len(a);
    return la == str_len(b) && memcmp(a, b, la) == 0;
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

/* THE BITWISE SIX. The four unguarded ones exist for the EVALUATOR,
   which is Avra and reaches the machine only through C; the native
   backend emits LLVM instructions for them and never calls these.
   The two SHIFTS are called by both engines, because a shift past the
   width is undefined in C and poison in LLVM, and one guarded body is
   the only way the two engines cannot disagree about where the edge
   is. The words name the LAW, not the mechanism. */
int64_t avra_int_and(int64_t a, int64_t b) { return a & b; }
int64_t avra_int_or(int64_t a, int64_t b)  { return a | b; }
int64_t avra_int_xor(int64_t a, int64_t b) { return a ^ b; }
int64_t avra_int_not(int64_t a)            { return ~a; }

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

int64_t avra_int_mod(int64_t a, int64_t b) {
    if (b == 0) { avra_trap("division by zero"); }
    return a % b;
}

const char* avra_int_text(int64_t v) {
    char* buf = sized_box(23, KIND_STR);
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
// one allocation per list, not two. A buffer of a small capacity —
// one to eight exactly (a record's slots, a literal's elements),
// then sixteen and thirty-two — is recycled through a per-capacity
// free list; a bigger one is malloc's and grows in place.
#define ARRAY_FIRST 8
#define BUF_CLASSES 10
static void* g_buf_free[BUF_CLASSES];
static int64_t g_buf_free_len[BUF_CLASSES];

static size_t buf_bytes(int64_t cap) {
    return (size_t)cap * (sizeof(int64_t) + 1);
}

// The class of a capacity: 0..7 for one to eight, 8 for sixteen, 9
// for thirty-two; -1 past the classes.
static int buf_class(int64_t cap) {
    if (cap >= 1 && cap <= 8) return (int)cap - 1;
    if (cap == 16) return 8;
    if (cap == 32) return 9;
    return -1;
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

// A box that will hold `n` slots — a record's, a literal's — takes
// a buffer of exactly `n`; `n` of 0 is a builder's box, which grows.
// A LIST'S ONE CONSTRUCTION. `avra_array_new` is `avra_array_sized`
// with no size asked, so the shape is written once and the site is
// handed in — a return address read inside would name this fn, not
// the caller the accounting wants.
__attribute__((noinline, cold))
static void sized_noted(AvraArray* a, void* ra) {
    a->site = g_clone_site ? g_clone_site : ra;
    g_sample_next = a;
    acc_site(a->site, (int64_t)(sizeof(Header) + sizeof(AvraArray) + buf_bytes(a->cap)), 1);
}

static AvraArray* array_made(int64_t cap, void* ra) {
    AvraArray* a = (AvraArray*)box_alloc(sizeof(AvraArray), KIND_ARRAY);
    a->cap = cap > 0 ? cap : ARRAY_FIRST;
    a->len = 0;
    a->data = buf_alloc(a->cap);
    array_marks(a);
    memset(a->owned, 0, (size_t)a->cap);
    a->site = NULL;
    if (__builtin_expect(g_acc_on > 0, 0)) sized_noted(a, ra);
    return a;
}

void* avra_array_sized(int64_t n) { return array_made(n, __builtin_return_address(0)); }

void* avra_array_new(void) { return array_made(0, __builtin_return_address(0)); }

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
    int64_t cap = old_cap < ARRAY_FIRST ? ARRAY_FIRST : old_cap * 2;
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

// A FULL LIST'S WRITE, whole and out of line, so the common write
// TAIL-calls it and keeps no frame of its own.
__attribute__((noinline))
static void push_grown(AvraArray* a, int64_t v) {
    if (a->cap >= CELL_CEILING || a->cap <= 0) avra_trap("a list grew past any possible size — a corrupted box");
    array_grow(a);
    a->data[a->len] = v;
    a->owned[a->len] = 0;
    a->len++;
}

void avra_array_push(void* arr, int64_t v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(__builtin_return_address(0)));
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(a->len == a->cap, 0)) { push_grown(a, v); return; }
    a->data[a->len] = v;
    a->owned[a->len] = 0;
    a->len++;
}

// RETAIN-AT-PACK: the array takes its own reference to a managed
// value and remembers the slot, so reclaim releases it.
void avra_array_push_owned(void* arr, void* v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(__builtin_return_address(0)));
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

// ── THE ONCE CACHE ───────────────────────────────────────────────
// A `once fn`'s answer, settled for the process and asked by the
// fn's own SYMBOL — unique in a binary by the linker's own law.
// The cache keeps ONE reference to the key and ONE to the value,
// forever: both are the caller's, consumed here (callee-cleans).
// Every ask answers the value OWNED, so the caller's scope releases
// its own reference and the cache's survives.
#define AVRA_ONCE_MAX 256

typedef struct {
    void* key;
    void* value;
} OnceSlot;

static OnceSlot g_once[AVRA_ONCE_MAX];
static int g_once_count = 0;

// A POINTER INDEX, AND THE STRCMP ONLY IF IT MISSES. A key is a
// symbol constant, so after the first read the pointer matches — but
// SCANNING for it costs the i-th `once` i compares on EVERY read, and
// a program holding twenty tables paid nineteen per read where this
// compiler's single table paid three. The scan is an index now: the
// key POINTER is the hash, so a hit is one probe whatever the count.
// The strcmp pass stays for a key arriving as a DIFFERENT constant,
// and it must not run before the pointer one; it is safe in that
// order because `avra_once_set` refuses a duplicate, so no two
// entries can share a string. A key found that way is INDEXED on the
// way out, so it costs the scan once rather than once per read.
#define AVRA_ONCE_IX 1024   /* power of two, a quarter full at MAX */
static int g_once_ix[AVRA_ONCE_IX];   /* index + 1; 0 is empty */

static int once_slot(const void* key) {
    return (int)(((uintptr_t)key >> 4) & (AVRA_ONCE_IX - 1));
}

static void once_index(const void* key, int at) {
    int i = once_slot(key);
    for (int step = 0; step < AVRA_ONCE_IX; step++) {
        if (g_once_ix[i] == 0) { g_once_ix[i] = at + 1; return; }
        i = (i + 1) & (AVRA_ONCE_IX - 1);
    }
}

static int once_at(const char* key) {
    int i = once_slot(key);
    for (int step = 0; step < AVRA_ONCE_IX; step++) {
        CENSUS(g_once_steps++);
        int at = g_once_ix[i];
        if (at == 0) break;
        if (g_once[at - 1].key == (void*)key) return at - 1;
        i = (i + 1) & (AVRA_ONCE_IX - 1);
    }
    for (int j = 0; j < g_once_count; j++) {
        if (strcmp((const char*)g_once[j].key, key) == 0) {
            once_index(key, j);
            return j;
        }
    }
    return -1;
}

// A runtime row BORROWS its arguments — only an Avra call retains
// for its callee — so the cache takes its OWN reference to each
// thing it keeps, and gives one away with every answer.
void* avra_once_get(void* key) {
    CENSUS(g_once_reads++);
    int at = once_at((const char*)key);
    void* held = at < 0 ? NULL : g_once[at].value;
    avra_rc_retain(held);
    return held;
}

void avra_once_set(void* key, void* value) {
    // the guard answered absent, so a second setter cannot happen;
    // if it did, the FIRST answer stands
    if (once_at((const char*)key) >= 0) { return; }
    if (g_once_count == AVRA_ONCE_MAX) { avra_trap("more `once` values than the cache holds"); }
    avra_rc_retain(key);
    avra_rc_retain(value);
    // THE ANSWER BECOMES IMMORTAL. It is held for the life of the
    // process, so every later retain and release of it is bookkeeping
    // for a death that cannot happen — 104M of them in one framer
    // run. Marked here, where the cache takes its reference, so the
    // kind reflects the fact rather than the intention.
    Header* vh = hdr(value);
    if (vh != NULL && vh->kind >= 0) vh->kind = KIND_IMMORTAL(vh->kind);
    g_once[g_once_count].key = key;
    g_once[g_once_count].value = value;
    once_index(key, g_once_count);
    g_once_count++;
}

// `v!` on a PAIR nullable — the flag guards, the value passes.
int64_t avra_insist_scalar(int64_t present, int64_t value) {
    if (!present) { avra_trap("unwrapped an absent value"); }
    return value;
}

// A READ'S TWO COLD ENDINGS, out of line and NORETURN so the read
// itself needs no frame: an 80-byte message buffer written into the
// hot path cost every one of a compile's hundreds of millions of
// reads a 128-byte stack reservation.
/* A STRING CROSSING TO C IS ONE STRING. Avra measures text by the
   header's length and C reads to the first NUL, so a string holding
   one is TWO VALUES at the seam — the guard and the callee inspect
   different bytes, and a name that was checked is not the name that
   is used. Every mature runtime refuses this rather than truncating:
   Rust's `CString::new` answers a `NulError` carrying the position,
   Go's `syscall.ByteSliceFromString` answers EINVAL, Python raises
   `ValueError: embedded null byte`, Node throws
   `ERR_INVALID_ARG_VALUE`. Avra traps, with the offset, and never
   truncates and never escapes.

   THE CHECK IS AT THE CROSSING AND NOWHERE ELSE, so both engines
   share it: the native lowering calls this and so does the extern
   frame's text staging. A face that refuses earlier with words a
   program can handle — `@std/io`'s `Holed(path, at)` — is the door;
   this is the belt behind it.

   `Bytes` IS THE ESCAPE: a seat that carries its own length is for a
   caller who means octets, and nothing here touches one. */
__attribute__((noinline, cold, noreturn))
static void trap_nul(size_t at) {
    char msg[96];
    snprintf(msg, sizeof msg,
             "a string holding a NUL crossed to C as two strings — byte %lld",
             (long long)at);
    avra_trap(msg);
    abort();
}

const char* avra_str_crossing(const char* s) {
    /* THE GUARD READS THE SAME BYTES THE CALLEE WILL, so it asks the
       HEADER directly and never `str_len`. That helper falls back to
       `strlen` for a pointer that is not ours, and a scan bounded by
       `strlen` can never find an interior NUL — it would pass every
       foreign string VACUOUSLY while looking exactly like a check.
       A foreign pointer has no interior NUL by definition: whatever C
       handed us ends where C says it ends. So the check is SKIPPED
       there, deliberately and visibly, rather than performed on a
       length that makes it meaningless. */
    Header* h = hdr((void*)s);
    if (__builtin_expect(h != NULL, 1)) {
        const char* at = (const char*)memchr(s, 0, (size_t)h->len);
        if (__builtin_expect(at != NULL, 0)) trap_nul((size_t)(at - s));
    }
    return s;
}

__attribute__((noinline, cold, noreturn))
static void trap_bounds(int64_t i, int64_t len) {
    char msg[80];
    snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
             (long long)i, (long long)len);
    avra_trap(msg);
    abort();
}

__attribute__((noinline, cold, noreturn))
static void trap_slice(int64_t lo, int64_t hi, int64_t len) {
    char msg[96];
    snprintf(msg, sizeof msg, "slice %lld..%lld is out of bounds (length %lld)",
             (long long)lo, (long long)hi, (long long)len);
    avra_trap(msg);
    abort();
}

// THE GUARDED READ, whole and out of line. The guard is a BRANCH on
// the read's path, never a call — a call there would cost the read a
// frame it does not otherwise need.
__attribute__((noinline, cold))
static int64_t get_guarded(void* arr, int64_t i) {
    avra_rc_dead_check(arr, "array_get");
    AvraArray* a = (AvraArray*)arr;
    if (i < 0 || i >= a->len) trap_bounds(i, a->len);
    return a->data[i];
}

int64_t avra_array_get(void* arr, int64_t i) {
    CENSUS(g_list_gets++);
    if (__builtin_expect(rc_guarded(), 0)) return get_guarded(arr, i);
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(i < 0 || i >= a->len, 0)) trap_bounds(i, a->len);
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
    AvraArray* c = (AvraArray*)avra_array_sized(a->len);
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
// AN IMMORTAL VALUE IS SHARED BY DEFINITION — nothing can hold the
// only reference to something that never dies, so a write through it
// must COPY. Without this an immortal box reads as UNIQUE and the
// write lands in the process-wide original.
static int is_shared(void* p) {
    Header* h = hdr(p);
    if (h == NULL) return 0;
    if (IS_IMMORTAL(h->kind)) return 1;
    return h->kind >= 0 && h->rc > 1;
}

// Opens a mut cell's box for writing: itself when nothing else
// holds it, else a clone stored into the cell (the old reference
// released). The answer is BORROWED from the cell.
void* avra_cell_unique(void* slot) {
    void* p = *(void**)slot;
    if (!is_shared(p)) return p;
    CENSUS(note_copy(__builtin_return_address(0)));
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
    CENSUS(note_copy(__builtin_return_address(0)));
    Header* h = hdr(p);
    return (h && KIND_SHAPE(h->kind) == KIND_MAP) ? map_clone((AvraMap*)p) : array_clone((AvraArray*)p);
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
    char* buf = sized_box(total - 1, KIND_STR);
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
    char* buf = sized_box(l + 2, KIND_STR);
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
    CENSUS(note_copy(__builtin_return_address(0)));
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
    char* buf = sized_box(n, KIND_STR);
    memcpy(buf, s, n);
    buf[n] = '\0';
    return buf;
}

/* ── THE FLOAT SEAM. Avra's float is binary64 and the machine's, so
   these are reinterpretations and IEEE arithmetic, never decimal.

   The compiler that emits a float literal is written in Avra, whose
   own source holds no float, so a literal crosses it as its BIT
   PATTERN in an int64. `_bits` names every entry point that speaks
   that currency; the plain ones take the real thing. */
static double as_double(int64_t bits) { double d; memcpy(&d, &bits, sizeof d); return d; }
static int64_t as_bits(double d) { int64_t b; memcpy(&b, &d, sizeof b); return b; }

/* A literal's text to its bits — compile-time only. Text the lexer
   already shaped as digits, a point and digits, so `strtod` reads all
   of it; anything it would refuse cannot reach here. */
int64_t avra_float_bits(const char* s) { return as_bits(strtod(s, NULL)); }

/* Whether the text names a real a `float` HOLDS. Overflow answers
   infinity, and infinity is not the number on the page — the same
   law the integer literal already keeps, where a wrapped value must
   never stand. UNDERFLOW is not refused: every float literal is an
   approximation, and a subnormal is the nearest one. */
int64_t avra_float_fits(const char* s) { return isfinite(strtod(s, NULL)); }

/* THE SHORTEST TEXT THAT READS BACK AS THE SAME DOUBLE — `%.17g`
   round-trips every binary64 but prints 0.1 as 0.10000000000000001,
   so the shortest faithful form is found by trying. A trailing `.0`
   is added when the text would otherwise read as an integer, because
   a float that prints as `3` is a float wearing an int's clothes. */
static const char* float_text(double d) {
    char buf[40];
    for (int prec = 1; prec <= 17; prec++) {
        snprintf(buf, sizeof buf, "%.*g", prec, d);
        if (strtod(buf, NULL) == d) break;
    }
    if (!strpbrk(buf, ".eEni")) { strncat(buf, ".0", sizeof buf - strlen(buf) - 1); }
    return str_owned(buf, strlen(buf));
}
const char* avra_float_text(double d) { return float_text(d); }
const char* avra_float_text_bits(int64_t bits) { return float_text(as_double(bits)); }

/* The EVALUATOR's arithmetic. It holds a float as bits and reaches
   the machine only through here, so an answer under `avra run` and an
   answer from a compiled program are the same instruction's. */
int64_t avra_float_add(int64_t a, int64_t b) { return as_bits(as_double(a) + as_double(b)); }
int64_t avra_float_sub(int64_t a, int64_t b) { return as_bits(as_double(a) - as_double(b)); }
int64_t avra_float_mul(int64_t a, int64_t b) { return as_bits(as_double(a) * as_double(b)); }
int64_t avra_float_div(int64_t a, int64_t b) { return as_bits(as_double(a) / as_double(b)); }

/* ORDERED comparisons: NaN answers false to every one, IEEE-754's
   rule. `!=` is NOT the negation of `==` for NaN and is spelled
   separately for that reason. */
int64_t avra_float_eq(int64_t a, int64_t b) { return as_double(a) == as_double(b); }
int64_t avra_float_ne(int64_t a, int64_t b) { return as_double(a) != as_double(b); }
int64_t avra_float_lt(int64_t a, int64_t b) { return as_double(a) <  as_double(b); }
int64_t avra_float_le(int64_t a, int64_t b) { return as_double(a) <= as_double(b); }
int64_t avra_float_gt(int64_t a, int64_t b) { return as_double(a) >  as_double(b); }
int64_t avra_float_ge(int64_t a, int64_t b) { return as_double(a) >= as_double(b); }

// ── Bytes ─────────────────────────────────────────────────────────
// Immutable octets in a box of their own kind. THE HEADER'S LENGTH IS
// THE LENGTH: no fallback, no scan, no terminator anyone reads. The
// box is minted at n+1 through `sized_box`, so every sized kind
// shares one size-class rule and the empty value is a real box. The
// spare byte holds a NUL: a Bytes lent to C as a string then reads
// its own content and STOPS — a bounded truncation, never a walk
// past the box, which on network data is a vulnerability and not a
// bug. A length crosses the boundary beside the pointer.

static size_t bytes_len(const char* b) { return (size_t)((const Header*)b - 1)->len; }

static char* bytes_box(size_t n) {
    if (n >= UINT32_MAX) avra_trap("a Bytes value is longer than its header can carry");
    char* b = sized_box(n, KIND_BYTES);
    b[n] = '\0';
    return b;
}

// An owned copy of n foreign octets: how every byte enters.
static const char* bytes_owned(const void* p, size_t n) {
    char* b = bytes_box(n);
    if (n) memcpy(b, p, n);
    return b;
}

int64_t avra_bytes_len(const char* b) { return (int64_t)bytes_len(b); }

// Equality is the reason the kind exists: lengths, then every byte.
int64_t avra_bytes_eq(const char* a, const char* b) {
    size_t n = bytes_len(a);
    return n == bytes_len(b) && memcmp(a, b, n) == 0;
}

// One octet, 0..255. A bad index traps: -1 is not a byte.
int64_t avra_bytes_at(const char* b, int64_t i) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(i < 0 || i >= n, 0)) trap_bounds(i, n);
    return (unsigned char)b[i];
}

// The octets from lo up to hi, owned. Bounds are a precondition: a
// slice traps and never clamps, because a short answer parses.
const char* avra_bytes_slice(const char* b, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    return bytes_owned(b + lo, (size_t)(hi - lo));
}

const char* avra_bytes_concat(const char* a, const char* b) {
    size_t n = bytes_len(a), m = bytes_len(b);
    char* out = bytes_box(n + m);
    memcpy(out, a, n);
    memcpy(out + n, b, m);
    return out;
}

// Where `needle` first begins at or after `from`, or -1. `from` may
// equal the length, and an empty needle is found there.
int64_t avra_bytes_index_of(const char* b, const char* needle, int64_t from) {
    int64_t n = (int64_t)bytes_len(b), m = (int64_t)bytes_len(needle);
    if (__builtin_expect(from < 0 || from > n, 0)) trap_bounds(from, n);
    if (m == 0) return from;
    if (m > n - from) return -1;
    const char* end = b + n - m + 1;
    for (const char* p = b + from; (p = (const char*)memchr(p, needle[0], (size_t)(end - p))) != NULL; p++)
        if (memcmp(p, needle, (size_t)m) == 0) return (int64_t)(p - b);
    return -1;
}

// Text to octets: total.
const char* avra_bytes_of_str(const char* s) { return bytes_owned(s, str_len(s)); }

// Ints to octets: null when one of them is not a byte.
const char* avra_bytes_of_list(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    for (int64_t i = 0; i < a->len; i++)
        if (a->data[i] < 0 || a->data[i] > 255) return NULL;
    char* out = bytes_box((size_t)a->len);
    for (int64_t i = 0; i < a->len; i++) out[i] = (char)a->data[i];
    return out;
}

// Many values as one box: the lengths summed, one allocation, one copy
// each — what a body assembled from chunks and a response assembled
// from its parts both need, so neither is quadratic.
const char* avra_bytes_gathered(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    size_t total = 0;
    for (int64_t i = 0; i < a->len; i++) total += bytes_len((const char*)(uintptr_t)a->data[i]);
    char* out = bytes_box(total);
    size_t at = 0;
    for (int64_t i = 0; i < a->len; i++) {
        const char* part = (const char*)(uintptr_t)a->data[i];
        size_t n = bytes_len(part);
        memcpy(out + at, part, n);
        at += n;
    }
    return out;
}

// The offset of the first byte that is not UTF-8, or -1 when the
// whole buffer is. THE LEAD BYTE'S RANGE DECIDES EVERYTHING: how many
// continuations follow, and the range the FIRST must fall in, which
// is where overlongs and surrogates are refused. Every later
// continuation is 80..BF. U+0000 is text, one byte; its overlong
// spelling C0 80 is refused at the lead. A truncated sequence is
// reported at its lead, never at the buffer's end.
static int64_t utf8_bad_at(const char* p, size_t n) {
    const unsigned char* b = (const unsigned char*)p;
    size_t i = 0;
    while (i < n) {
        unsigned char c = b[i];
        size_t need;
        unsigned char lo, hi;
        if (c <= 0x7F)                   { i += 1; continue; }
        else if (c >= 0xC2 && c <= 0xDF) { need = 1; lo = 0x80; hi = 0xBF; }
        else if (c == 0xE0)              { need = 2; lo = 0xA0; hi = 0xBF; }
        else if (c >= 0xE1 && c <= 0xEC) { need = 2; lo = 0x80; hi = 0xBF; }
        else if (c == 0xED)              { need = 2; lo = 0x80; hi = 0x9F; }
        else if (c >= 0xEE && c <= 0xEF) { need = 2; lo = 0x80; hi = 0xBF; }
        else if (c == 0xF0)              { need = 3; lo = 0x90; hi = 0xBF; }
        else if (c >= 0xF1 && c <= 0xF3) { need = 3; lo = 0x80; hi = 0xBF; }
        else if (c == 0xF4)              { need = 3; lo = 0x80; hi = 0x8F; }
        else                             { return (int64_t)i; }
        if (i + need >= n) return (int64_t)i;
        if (b[i + 1] < lo || b[i + 1] > hi) return (int64_t)i;
        for (size_t k = 2; k <= need; k++)
            if (b[i + k] < 0x80 || b[i + k] > 0xBF) return (int64_t)i;
        i += need + 1;
    }
    return -1;
}

// Octets to text: null when they are not UTF-8, and the row below
// says where. A NUL is text.
const char* avra_str_of_bytes(const char* b) {
    size_t n = bytes_len(b);
    return utf8_bad_at(b, n) < 0 ? str_owned(b, n) : NULL;
}

int64_t avra_utf8_bad_at(const char* b) { return utf8_bad_at(b, bytes_len(b)); }

__attribute__((noinline, cold, noreturn))
static void trap_table(int64_t len) {
    char msg[80];
    snprintf(msg, sizeof msg, "a class table holds 256 bytes (length %lld)", (long long)len);
    avra_trap(msg);
    abort();
}

// The end of the run of bytes at or after `from` that `table` admits —
// a 256-byte table whose non-zero entry says "in the class". The
// caller asks where a token ENDS, never what each byte is: one scan
// in C is what makes a byte-at-a-time parser fast.
int64_t avra_bytes_run(const char* b, int64_t from, const char* table) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(from < 0 || from > n, 0)) trap_bounds(from, n);
    if (__builtin_expect(bytes_len(table) != 256, 0)) trap_table((int64_t)bytes_len(table));
    const unsigned char* t = (const unsigned char*)table;
    const unsigned char* p = (const unsigned char*)b;
    int64_t i = from;
    while (i < n && t[p[i]]) i++;
    return i;
}

// Whether the bytes from lo up to hi are exactly `needle`.
int64_t avra_bytes_eq_at(const char* b, int64_t lo, int64_t hi, const char* needle) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    return (size_t)(hi - lo) == bytes_len(needle) && memcmp(b + lo, needle, (size_t)(hi - lo)) == 0;
}

static unsigned char ascii_lower(unsigned char c) { return c >= 'A' && c <= 'Z' ? c + 32 : c; }

// `eq_at` with ASCII letters folded — how a field name is compared.
int64_t avra_bytes_ieq_at(const char* b, int64_t lo, int64_t hi, const char* needle) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    if ((size_t)(hi - lo) != bytes_len(needle)) return 0;
    for (int64_t i = 0; i < hi - lo; i++)
        if (ascii_lower((unsigned char)b[lo + i]) != ascii_lower((unsigned char)needle[i])) return 0;
    return 1;
}

// ── Descriptors ──────────────────────────────────────────────────
// THE ONE DOOR THROUGH WHICH FOREIGN BYTES BECOME A VALUE. A package's
// own C opens files and sockets and answers descriptors; what flows
// through a descriptor becomes a Bytes here and nowhere else, because
// only the runtime may mint a managed box. A read lands in ONE scratch
// and answers a TOKEN — the scratch's generation — that the take must
// present: a take with a stale token traps, so a read landing between
// a read and its take (a deferred call is how that happens) is a loud
// wreck and never a stranger's bytes. The count is the box's length;
// 0 is EOF and needs no take. A write takes a box from an offset and
// answers what the descriptor accepted; a short count is normal. Both
// answer -EAGAIN when a nonblocking descriptor has nothing to give or
// take, and a peer that has gone answers -EPIPE or -ECONNRESET to the
// caller who armed against SIGPIPE.

#include <unistd.h>
#include <errno.h>

enum { FD_SCRATCH = 1 << 20 };
static char g_fd_buf[FD_SCRATCH];
static int64_t g_fd_len = 0;
static int64_t g_fd_gen = 0;

// A take presents a token, and three values are not one: 0 is EOF,
// a negative is the errno the read answered, and a superseded token
// names bytes another read has replaced. Each refused in its own
// words, the reserved ones first, so the superseded message is always
// true when it is spoken.
__attribute__((noinline, cold, noreturn))
static void trap_take(int64_t token) {
    char msg[96];
    if (token == 0)
        snprintf(msg, sizeof msg, "a take at EOF — `read` answered 0, which names no bytes");
    else if (token < 0)
        snprintf(msg, sizeof msg, "a take of an error — `read` answered %lld, not a token", (long long)token);
    else
        snprintf(msg, sizeof msg, "a take of read %lld, but read %lld has landed since", (long long)token, (long long)g_fd_gen);
    avra_trap(msg);
    abort();
}

// Bytes landed in the scratch by whoever produced them: the token the
// take must present. The runtime's own producers enter through here.
static int64_t fd_landed(int64_t n) {
    g_fd_len = n;
    g_fd_gen++;
    return g_fd_gen;
}

// Up to `max` bytes (clamped to 1..1 MiB) into the scratch: the token
// of what landed, 0 at EOF, -EAGAIN when nothing is ready, -errno
// otherwise.
int64_t avra_fd_read(int64_t fd, int64_t max) {
    size_t n = max < 1 ? 1 : max > FD_SCRATCH ? FD_SCRATCH : (size_t)max;
    for (;;) {
        ssize_t got = read((int)fd, g_fd_buf, n);
        if (got > 0) return fd_landed(got);
        if (got == 0) return 0;
        if (errno == EAGAIN || errno == EWOULDBLOCK) return -EAGAIN;
        if (errno != EINTR) return -errno;
    }
}

// The errno a nonblocking descriptor answers when it has nothing to
// give or take — the platform's, asked rather than assumed.
int64_t avra_errno_again(void) { return EAGAIN; }

// The errno for an argument that names nothing — the platform's word.
int64_t avra_errno_invalid(void) { return EINVAL; }

// The bytes a token names, as a fresh box, once: a second take of the
// same token answers the empty box, and a take of anything that is
// not the current token traps.
const char* avra_fd_taken(int64_t token) {
    if (__builtin_expect(token <= 0 || token != g_fd_gen, 0)) trap_take(token);
    const char* b = bytes_owned(g_fd_buf, (size_t)g_fd_len);
    g_fd_len = 0;
    return b;
}

// The box's bytes from `from` written as far as the descriptor takes
// them: the count, -EAGAIN when it takes none, -errno otherwise.
// `from` past the box traps; `from` at its end writes nothing.
int64_t avra_fd_write(int64_t fd, const char* bytes, int64_t from) {
    int64_t n = (int64_t)bytes_len(bytes);
    if (__builtin_expect(from < 0 || from > n, 0)) trap_bounds(from, n);
    if (from == n) return 0;
    for (;;) {
        ssize_t put = write((int)fd, bytes + from, (size_t)(n - from));
        if (put >= 0) return put;
        if (errno == EAGAIN || errno == EWOULDBLOCK) return -EAGAIN;
        if (errno != EINTR) return -errno;
    }
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

// `strstr` reads both sides as C strings, so a needle after a NUL
// was unfindable and a haystack's tail invisible. An EMPTY needle is
// present in everything, which is what `strstr(s, "")` answered too.
int64_t avra_str_contains(const char* s, const char* needle) {
    size_t nl = str_len(needle);
    if (nl == 0) return 1;
    size_t sl = str_len(s);
    return nl <= sl && memmem(s, sl, needle, nl) != NULL;
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
    size_t nl = str_len(needle);
    if (nl == 0) return 0;
    size_t sl = str_len(s);
    if (nl > sl) return -1;
    const char* at = (const char*)memmem(s, sl, needle, nl);
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
    size_t n = str_len(s);
    size_t fl = str_len(from);
    size_t tl = str_len(to);
    if (fl == 0) return str_owned(s, n);
    const char* end = s + n;
    size_t count = 0;
    for (const char* p = s;;) {
        const char* q = (const char*)memmem(p, (size_t)(end - p), from, fl);
        if (q == NULL) break;
        count++;
        p = q + fl;
    }
    size_t out = n + count * tl - count * fl;
    char* buf = sized_box(out, KIND_STR);
    char* w = buf;
    const char* r = s;
    for (const char* p; (p = (const char*)memmem(r, (size_t)(end - r), from, fl)) != NULL;) {
        memcpy(w, r, (size_t)(p - r));
        w += p - r;
        memcpy(w, to, tl);
        w += tl;
        r = p + fl;
    }
    // `sized_box` mints n+1 and writes no terminator — that is the
    // CALLERS' convention, and `strcpy` was quietly keeping it here.
    memcpy(w, r, (size_t)(end - r));
    buf[out] = '\0';
    return buf;
}

// The pieces between separators: a leading empty piece stays, one
// trailing empty piece is dropped, and empty text splits to
// nothing. An empty separator keeps the text whole. Owned, holding
// owned pieces.
// A trailing empty segment is DROPPED and a leading one KEPT, which
// the length walk preserves exactly: the tail is pushed only when it
// is not empty, and an empty first segment is a real push.
void* avra_str_split(const char* s, const char* sep) {
    void* out = avra_array_new();
    size_t n = str_len(s), sl = str_len(sep);
    if (n == 0) return out;
    if (sl == 0) {
        push_fresh_text(out, s, n);
        return out;
    }
    const char* r = s;
    const char* end = s + n;
    for (;;) {
        const char* p = (const char*)memmem(r, (size_t)(end - r), sep, sl);
        if (p == NULL) {
            if (r != end) push_fresh_text(out, r, (size_t)(end - r));
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
    char* buf = sized_box(n + m, KIND_STR);
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

// An open file read to its end, as owned text.
static const char* read_whole(FILE* f) {
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (size < 0) size = 0;
    char* buf = sized_box((size_t)size, KIND_STR);
    size_t got = fread(buf, 1, (size_t)size, f);
    buf[got] = '\0';
    ((Header*)buf - 1)->len = (uint32_t)got;
    return buf;
}

// The whole file as text; "" when it cannot be read. Owned.
const char* avra_selfhost_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return str_owned("", 0);
    const char* text = read_whole(f);
    fclose(f);
    return text;
}

// The text written whole, through a sibling temp file named for
// this process and a rename, so a reader never sees a half-written
// file and two writers never share a temp. 0 done, -errno refused.
static int64_t write_whole(const char* path, const char* content) {
    size_t n = strlen(path);
    char* tmp = (char*)malloc(n + 32);
    memcpy(tmp, path, n);
    snprintf(tmp + n, 32, ".tmpav%ld", (long)getpid());
    FILE* f = fopen(tmp, "wb");
    if (!f) { int64_t e = -errno; free(tmp); return e; }
    // the HEADER's length, never strlen: a text may hold NUL bytes, and
    // a write that stopped at the first one would truncate in silence
    size_t len = str_len(content);
    int64_t status = fwrite(content, 1, len, f) == len ? 0 : -EIO;
    if (fclose(f) != 0 && status == 0) status = -errno;
    if (status == 0 && rename(tmp, path) != 0) status = -errno;
    if (status != 0) remove(tmp);
    free(tmp);
    return status;
}

int64_t avra_selfhost_write_file(const char* path, const char* content) {
    return write_whole(path, content) == 0;
}

// ── Streams, and the ONE directory listing ──────────────────────
// What is left of the io substrate after @std/io took its own C. A
// package opens, stats, makes and removes; only LISTING stays, because
// a directory entry's name is text that flows through no descriptor
// and nothing but the runtime may mint a box. RECORDED TRIGGER: the
// adoption row of docs/2026_09_06_FOREIGN_TEXT_ADOPTION.md, which is
// the owner's to export — the day it lands this leaves too.

void avra_eputs(const char* s) {
    if (s) fwrite(s, 1, str_len(s), stderr);
    fputc('\n', stderr);
}

static int by_text(const void* a, const void* b) {
    return strcmp((const char*)(uintptr_t)*(const int64_t*)a, (const char*)(uintptr_t)*(const int64_t*)b);
}

// The directory's entries in byte order, joined on `/` — the one byte
// no name can hold — landed in the descriptor scratch; `.` and `..`
// never among them. Answers the scratch's TOKEN, which avra_fd_taken
// mints from once.
int64_t avra_io_list(const char* path) {
    DIR* d = opendir(path);
    if (!d) return -errno;
    void* names = avra_array_new();
    struct dirent* e;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
        push_fresh_text(names, e->d_name, strlen(e->d_name));
    }
    closedir(d);
    AvraArray* a = (AvraArray*)names;
    qsort(a->data, (size_t)a->len, sizeof(int64_t), by_text);
    const char* joined = avra_str_join(names, "/");
    avra_rc_release(names);
    size_t n = str_len(joined);
    // ONE SCRATCH, ONE TAKE. A listing past the scratch is -E2BIG and
    // never a silent truncation; an EMPTY directory lands zero bytes
    // and answers a token whose take is the empty box, which is the
    // first case this had to answer and not the last.
    if (n > FD_SCRATCH) { avra_rc_release((void*)joined); return -E2BIG; }
    memcpy(g_fd_buf, joined, n);
    avra_rc_release((void*)joined);
    return fd_landed((int64_t)n);
}

// Every directory along the path made; one already standing is fine,
// a FILE standing where a directory must is -ENOTDIR.
static int64_t mkdir_all(const char* path) {
    size_t n = strlen(path);
    if (n == 0) return -ENOENT;
    if (n >= 4096) return -ENAMETOOLONG;
    char buf[4096];
    memcpy(buf, path, n + 1);
    for (size_t i = 1; i <= n; i++) {
        if (buf[i] != '/' && buf[i] != '\0') continue;
        char saved = buf[i];
        buf[i] = '\0';
        if (mkdir(buf, 0755) != 0) {
            if (errno != EEXIST) return -errno;
            struct stat st;
            if (stat(buf, &st) != 0) return -errno;
            if (!S_ISDIR(st.st_mode)) return -ENOTDIR;
        }
        buf[i] = saved;
    }
    return 0;
}

// ── The process's own life ──────────────────────────────────────
// What was the PROCESS section is @std/process's own C now
// (packages/std-process/src/c/std_process.c): the spawn table, the
// pipes, the signals and the reaping are a package's, answering ints,
// and a child's streams are DESCRIPTORS the language reads through
// the rows above. What stays here is what only this process can say
// about ITSELF.

// AN ADDRESS AS A POINTER. Making one is inert IN THE LANGUAGE:
// Avra has no dereference, so a `ptr` can be held, compared to null
// and handed on, and nothing reads through it. Zero answers the null
// pointer, so `ptr?`'s niche carries absence with no extra word and
// a C sentinel of 0 (SQLITE_STATIC) arrives as null on its own.
// NOT A CAST: the only direction is int -> ptr, and no seat widens
// implicitly, so a transposed argument stays a compile error.
//
// THE ROWS DEREFERENCE WHAT THEY ARE HANDED, and that is where the
// danger lives — not here. `avra_array_push` casts its argument to
// an array and writes through it with no header check, because it
// cannot afford one; the extern seam accepts any linked symbol at
// check time; so a program that declares both composes an arbitrary
// WRITE out of two safe-looking parts. That is the FFI's property,
// not this function's, and it holds with or without this door — but
// it must be said HERE, because this comment is what a later
// capability will be graded against.
void* avra_ptr_at(int64_t address) {
    return (void*)(intptr_t)address;
}

// A code point as the UTF-8 bytes that spell it; one that no
// sequence can carry (past U+10FFFF, or a surrogate) is U+FFFD.
const char* avra_str_from_codepoint(int64_t code) {
    if (code < 0 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) code = 0xFFFD;
    char b[4];
    size_t n;
    if (code < 0x80) { b[0] = (char)code; n = 1; }
    else if (code < 0x800) { b[0] = (char)(0xC0 | (code >> 6)); b[1] = (char)(0x80 | (code & 0x3F)); n = 2; }
    else if (code < 0x10000) { b[0] = (char)(0xE0 | (code >> 12)); b[1] = (char)(0x80 | ((code >> 6) & 0x3F)); b[2] = (char)(0x80 | (code & 0x3F)); n = 3; }
    else { b[0] = (char)(0xF0 | (code >> 18)); b[1] = (char)(0x80 | ((code >> 12) & 0x3F)); b[2] = (char)(0x80 | ((code >> 6) & 0x3F)); b[3] = (char)(0x80 | (code & 0x3F)); n = 4; }
    return str_owned(b, n);
}

// An errno's words, either sign — the process and io libraries share it.
const char* avra_errno_text(int64_t err) {
    return str_static(strerror((int)(err < 0 ? -err : err)));
}

// THE SEED'S SHIM: the seed that predates @std/process links this;
// nothing in Avra declares it. Deleted once a refreshed seed has
// landed (ROADMAP, lane B slice C).
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
    return mkdir_all(path) == 0;
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

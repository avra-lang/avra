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
// allocation, 1 an array, 2 a map. Below zero it is not counted:
// STATIC is immortal, DEAD is the guard's mark on a reclaimed box.
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3 };

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
enum { ACC_RECORD, ACC_STR, ACC_LIST, ACC_BUF, ACC_MAP, ACC_INDEX, ACC_KINDS };
// KEYED, never positional: a category inserted mid-enum would take its
// neighbour's name under a positional initialiser, and the report is
// read by whoever is asking where the memory went.
static const char* g_acc_name[ACC_KINDS] = {
    [ACC_RECORD] = "records",    [ACC_STR]   = "strings",
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

static void put_line(const char* s) {
    if (s) fputs(s, stdout);
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
__attribute__((noinline, cold, noreturn))
static void trap_bounds(int64_t i, int64_t len) {
    char msg[80];
    snprintf(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
             (long long)i, (long long)len);
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

// ── Files, streams and the environment ──────────────────────────
// The substrate @std/io stands on. Every verb answers a STATUS — 0
// done, -errno refused — and hands text through ONE stash that
// avra_io_taken empties: the library judges the status, then takes.

static const char* g_io_text = NULL;

// The stash holds one owned text; a new one releases the last.
static void io_stash(const char* owned) {
    if (g_io_text) avra_rc_release((void*)g_io_text);
    g_io_text = owned;
}

// The stashed text, handed over once — its reference moves to the
// caller; "" when nothing waits.
const char* avra_io_taken(void) {
    const char* text = g_io_text ? g_io_text : str_owned("", 0);
    g_io_text = NULL;
    return text;
}

void avra_eputs(const char* s) {
    if (s) fputs(s, stderr);
    fputc('\n', stderr);
}

// A DEBUG LINE, only under AVRA_DEBUG — the compiler's own instrument.
// A no-op otherwise, so a probe can stand in any pass without breaking
// the self-compile, whose environment has no such flag.
void avra_debug(const char* s) {
    if (s && getenv("AVRA_DEBUG")) fputs(s, stderr);
}

// What stands at the path: 0 nothing, 1 a file, 2 a directory, 3
// something else; -errno when the host will not say.
int64_t avra_io_kind(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return errno == ENOENT ? 0 : -errno;
    if (S_ISREG(st.st_mode)) return 1;
    if (S_ISDIR(st.st_mode)) return 2;
    return 3;
}

// The whole file, stashed.
int64_t avra_io_read(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return -errno;
    if (S_ISDIR(st.st_mode)) return -EISDIR;
    FILE* f = fopen(path, "rb");
    if (!f) return -errno;
    io_stash(read_whole(f));
    fclose(f);
    return 0;
}

/* `embed` is answered by the compiler, at compile time, under the
   const's own directory; a program that reaches this body called it
   outside a const. */
const char* avra_embed(const char* path) {
    (void)path;
    avra_trap("`embed` reads a file at compile time, into a const — this program reached it at run time");
    return "";
}

int64_t avra_io_write(const char* path, const char* content) {
    return write_whole(path, content);
}

static int by_text(const void* a, const void* b) {
    return strcmp((const char*)(uintptr_t)*(const int64_t*)a, (const char*)(uintptr_t)*(const int64_t*)b);
}

// The directory's entries in byte order, joined on `/` — the one
// byte no name can hold — and stashed; `.` and `..` never among them.
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
    io_stash(avra_str_join(names, "/"));
    avra_rc_release(names);
    return 0;
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

int64_t avra_io_mkdir(const char* path) {
    return mkdir_all(path);
}

// A file, or an empty directory, gone.
int64_t avra_io_remove(const char* path) {
    return remove(path) == 0 ? 0 : -errno;
}

// The variable's value stashed; -1 when it is not set at all — an
// empty value is set.
int64_t avra_io_env(const char* name) {
    const char* v = getenv(name);
    if (!v) return -1;
    io_stash(str_owned(v, strlen(v)));
    return 0;
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
        // the HEADER's length, never strlen: stdin is a byte stream and a
        // NUL is data — `avra_proc_write` has always read it this way
        size_t n = stdin_text ? str_len(stdin_text) : 0;
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

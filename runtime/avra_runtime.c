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
// avra_llvm_build_text), the runtime's own literals,
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

#ifndef __APPLE__
#define _GNU_SOURCE
#endif
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <errno.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <malloc/malloc.h>
#elif defined(__wasm32__)
#include <malloc.h>
#else
#include <link.h>
#include <malloc.h>
#include <sys/random.h>
#endif
#include <time.h>
#include <unistd.h>
#include "avra_box.h"
#include "avra_platform.h"
#include "avra_runtime.h"
#include "avra_hot.h"

// ── The runtime's own words ─────────────────────────────────────
//
// A trap, a guard and a report are FORMATTED HERE, never by libc's
// printf: its engine is ten kilobytes a wasm module would carry to
// print one index. The conversions are the ones these words use —
// %s %c %d %lld %llx %p %% under a width and `-` — and the `format`
// attribute holds every call to that subset's types. A number a
// program prints is a FLOAT's or an int's own row, not this.

// Where formatted text lands: a buffer, drained to `to` each time it
// fills when there is one, cut at its end when there is none.
typedef struct { char* base; char* at; char* end; FILE* to; } Words;

static void words_drain(Words* w) {
    if (w->to) fwrite(w->base, 1, (size_t)(w->at - w->base), w->to);
    w->at = w->base;
}

static void words_put(Words* w, const char* s, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (w->at == w->end) {
            if (!w->to) return;
            words_drain(w);
        }
        *w->at++ = s[i];
    }
}

static void words_fill(Words* w, int n) {
    for (; n > 0; n--) words_put(w, " ", 1);
}

// `v` in `base`, written backwards from `end`; answers its first digit.
static char* digits_before(char* end, unsigned long long v, unsigned base) {
    do { *--end = "0123456789abcdef"[v % base]; v /= base; } while (v);
    return end;
}

static void rt_vfmt(Words* w, const char* fmt, va_list ap) {
    for (; *fmt; fmt++) {
        if (*fmt != '%') { words_put(w, fmt, 1); continue; }
        int left = *++fmt == '-';
        if (left) fmt++;
        int width = 0;
        while (*fmt >= '0' && *fmt <= '9') width = width * 10 + (*fmt++ - '0');
        char held[24];
        char* end = held + sizeof held;
        const char* s = end;
        if (*fmt == 's') {
            s = va_arg(ap, const char*);
            end = (char*)s + strlen(s);
        } else if (*fmt == 'c') {
            *--end = (char)va_arg(ap, int);
            s = end++;
        } else if (*fmt == 'd' || (fmt[0] == 'l' && fmt[1] == 'l' && fmt[2] == 'd')) {
            long long v = *fmt == 'd' ? va_arg(ap, int) : va_arg(ap, long long);
            if (*fmt == 'l') fmt += 2;
            char* at = digits_before(end, v < 0 ? 0ULL - (unsigned long long)v : (unsigned long long)v, 10);
            if (v < 0) *--at = '-';
            s = at;
        } else if (fmt[0] == 'l' && fmt[1] == 'l' && fmt[2] == 'x') {
            fmt += 2;
            s = digits_before(end, va_arg(ap, unsigned long long), 16);
        } else if (*fmt == 'p') {
            char* at = digits_before(end, (unsigned long long)(uintptr_t)va_arg(ap, void*), 16);
            *--at = 'x';
            *--at = '0';
            s = at;
        } else {
            // `%%` is itself; a conversion outside the subset shows as written
            if (*fmt != '%') words_put(w, "%", 1);
            s = fmt;
            end = (char*)fmt + 1;
        }
        int n = (int)(end - s);
        if (!left) words_fill(w, width - n);
        words_put(w, s, (size_t)n);
        if (left) words_fill(w, width - n);
    }
}

// `snprintf`'s place: the text in `out`, cut at `cap`, terminated.
void avra_fmt(char* out, size_t cap, const char* fmt, ...) {
    Words w = { out, out, out + cap - 1, NULL };
    va_list ap;
    va_start(ap, fmt);
    rt_vfmt(&w, fmt, ap);
    va_end(ap);
    *w.at = 0;
}

// `fprintf(stderr, …)`'s place, whole however long the line.
__attribute__((noinline, cold))
void avra_say(const char* fmt, ...) {
    char line[160];
    Words w = { line, line, line + sizeof line, stderr };
    va_list ap;
    va_start(ap, fmt);
    rt_vfmt(&w, fmt, ap);
    va_end(ap);
    words_drain(&w);
}

// A number an env flag spells, as `strtoull` reads one: blanks, a
// sign, then digits in `base` up to the first that is none — 0 reads
// `0x` as hex, a leading `0` as octal, the rest as decimal; 16 takes
// the `0x` or leaves it. One past the widest word is the widest word.
unsigned long long avra_number(const char* s, unsigned base) {
    while (*s == ' ' || (*s >= '\t' && *s <= '\r')) s++;
    int negative = *s == '-';
    if (*s == '-' || *s == '+') s++;
    int hexed = s[0] == '0' && (s[1] == 'x' || s[1] == 'X');
    if (hexed && (base == 0 || base == 16)) { s += 2; base = 16; }
    if (base == 0) base = *s == '0' ? 8 : 10;
    unsigned long long v = 0;
    int past = 0;
    for (;; s++) {
        unsigned d = *s >= '0' && *s <= '9' ? (unsigned)(*s - '0')
                   : (*s | 32) >= 'a' && (*s | 32) <= 'f' ? (unsigned)((*s | 32) - 'a') + 10 : 16;
        if (d >= base) break;
        past |= v > (~0ULL - d) / base;
        v = v * base + d;
    }
    if (past) return ~0ULL;
    return negative ? 0ULL - v : v;
}

// ── The box header ──────────────────────────────────────────────
// The layouts are avra_box.h's — shared with the backend, which lays
// them out as static data.

// The payload's header. NULL for a pointer that is not a box: the
// null pointer, an unaligned address or one in the null page (a box
// is sixteen-aligned and never there — a small scalar mistaken for
// one is refused before anything is read), or a header without the
// tag.
static Header* hdr(void* p) { return avra_hdr(p); }

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
#if AVRA_INSTRUMENTS
static int g_acc_on = 0;
#else
enum { g_acc_on = 0 };
#endif
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

#if !defined(__APPLE__) && !defined(__wasm32__)
static int main_image_bias(struct dl_phdr_info* info, size_t size, void* out) {
    (void)size;
    *(uintptr_t*)out = (uintptr_t)info->dlpi_addr;
    return 1;
}
#endif

// The main image's load slide: a live code address minus it is the
// address the binary files its symbols under (`atos`, `addr2line`).
static intptr_t image_slide(void) {
#ifdef __APPLE__
    return _dyld_get_image_vmaddr_slide(0);
#elif defined(__wasm32__)
    // a wasm module carries no loader slide: every address is its own
    return 0;
#else
    uintptr_t bias = 0;
    dl_iterate_phdr(main_image_bias, &bias);
    return (intptr_t)bias;
#endif
}

// THE CENSUS (build with -DAVRA_CENSUS; `make census`): exact call
// counts, not a sample. Refcount traffic is the compiler's largest
// single cost, and a sampling profiler charges a cascade to whoever
// happened to be on the stack. Counting costs 8% of a run, so it is
// a SEPARATE BUILD and the shipping runtime carries none of it.
#ifdef AVRA_CENSUS

int64_t g_rc_retains, g_rc_releases, g_rc_frees, g_list_gets;
static int64_t g_list_pushes;
static int64_t g_once_reads, g_once_steps;
static int64_t g_boxes_made, g_bufs_made;
static int64_t g_made_by_kind[8];

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

void note_retain(void* site) {
    if (!g_sites_census) return;
    Site* s = site_in(g_retain_sites, &g_retain_slots, site);
    if (s) s->made++;
}

// Boxes a row answered owned, by what they are: each label is a type
// and the row (`List<int> by avra_array_sized`), counted where the
// backend was asked to (AVRA_CENSUS_TYPES), keyed by the label's address.
static Site g_type_sites[SITES];
static int64_t g_type_slots = 0;

static int by_label(const void* a, const void* b) {
    return strcmp((const char*)((const Site*)a)->site, (const char*)((const Site*)b)->site);
}

static int by_made(const void* a, const void* b) {
    int64_t x = ((const Site*)a)->made, y = ((const Site*)b)->made;
    return x < y ? 1 : x > y ? -1 : 0;
}

// The labels with the most boxes, most first. One label stands at
// one address per module that spells it, so equal texts are summed.
static void report_types(int limit) {
    if (g_type_slots == 0) return;
    Site* rows = malloc((size_t)g_type_slots * sizeof(Site));
    if (!rows) return;
    int64_t n = 0;
    for (int i = 0; i < SITES; i++) if (g_type_sites[i].site) rows[n++] = g_type_sites[i];
    qsort(rows, (size_t)n, sizeof(Site), by_label);
    int64_t merged = 0;
    for (int64_t i = 0; i < n; i++) {
        if (merged > 0 && by_label(&rows[merged - 1], &rows[i]) == 0) rows[merged - 1].made += rows[i].made;
        else rows[merged++] = rows[i];
    }
    qsort(rows, (size_t)merged, sizeof(Site), by_made);
    int64_t total = 0;
    for (int64_t i = 0; i < merged; i++) total += rows[i].made;
    avra_say("type: %lld boxes answered by owning rows (a _reusing row may answer the box it was handed), %lld labels\n",
            (long long)total, (long long)merged);
    for (int64_t i = 0; i < merged && i < limit; i++) {
        // a share in tenths of a percent, rounded
        long long share = total ? ((long long)rows[i].made * 2000 / total + 1) / 2 : 0;
        avra_say("type: %12lld  %3lld.%lld%%  %s\n", (long long)rows[i].made, share / 10, share % 10,
               (const char*)rows[i].site);
    }
    free(rows);
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
        avra_say("%s: site %p %lld\n", label,
                (void*)((char*)top->site - slide), (long long)top->made);
        top->made = -top->made;
    }
}
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

static int64_t g_mortal_live;

static void acc_report(void) {
#ifdef AVRA_CENSUS
    avra_say("rc: %lld retains, %lld releases, %lld reclaims\n",
            (long long)g_rc_retains, (long long)g_rc_releases, (long long)g_rc_frees);
    avra_say("rc: %lld list reads, %lld list writes\n",
            (long long)g_list_gets, (long long)g_list_pushes);
    avra_say("once: %lld reads, %lld pointer compares\n",
            (long long)g_once_reads, (long long)g_once_steps);
    avra_say("alloc: %lld boxes, %lld list buffers\n",
            (long long)g_boxes_made, (long long)g_bufs_made);
    for (int k = 0; k < ACC_KINDS; k++) {
        if (g_made_by_kind[k]) avra_say("alloc:   %-13s %lld\n", g_acc_name[k], (long long)g_made_by_kind[k]);
    }
#endif

    avra_say("mem: peak %lld MB in all\n", (long long)(g_acc_total_peak >> 20));
    // EXACT, never MB-rounded: a small program's leak is bytes, and a
    // shift that floors to zero would certify it clean. `avra_once_set`
    // already credited every cached answer out of this ledger the
    // moment it made one immortal, so this line is 0 exactly when
    // nothing outstanding would still need freeing — the soundness
    // runner reads this line alone.
    avra_say("mem: live %lld bytes at exit\n", (long long)g_mortal_live);
    for (int k = 0; k < ACC_KINDS; k++) {
        avra_say("mem:   %-13s peak %6lld MB, now %6lld MB\n", g_acc_name[k],
                (long long)(g_acc_peak[k] >> 20), (long long)(g_acc_live[k] >> 20));
    }
    intptr_t slide = image_slide();
#ifdef AVRA_CENSUS
    if (g_sites_census) {
        report_made("copy", g_copy_sites, 12, slide);
        report_made("push", g_push_sites, 16, slide);
        report_made("retain", g_retain_sites, 20, slide);
    }
    report_types(40);
#endif
    const char* wanted = getenv("AVRA_MEM_SITES");
    int limit = wanted ? (int)avra_number(wanted, 10) : 24;
    for (int shown = 0; shown < limit; shown++) {
        Site* top = NULL;
        for (int i = 0; i < SITES; i++) {
            if (g_sites[i].site && g_sites[i].peak >= 0 && (top == NULL || g_sites[i].peak > top->peak)) top = &g_sites[i];
        }
        if (top == NULL || top->peak < (wanted ? 1 : (1 << 20))) break;
        avra_say("mem:   site 0x%llx peak %6lld MB, now %6lld MB, %lld live of %lld made\n",
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
    uintptr_t asked_at = asked ? (uintptr_t)avra_number(asked, 16) + (uintptr_t)slide : 0;
    if (getenv("AVRA_RC_GUARD")) {
        int replayed = 0;
        for (int i = 0; i < SITES && replayed < 6; i++) {
            Site* st = &g_sites[i];
            Header* sh = st->site && st->sample ? hdr(st->sample) : NULL;
            if (sh == NULL) continue;
            if (asked_at ? (uintptr_t)st->site != asked_at : sh->rc <= 0) continue;
            avra_say("mem:   LEAK at site 0x%llx (%lld made): its hundredth box ends at rc %d — its life (unslid):\n",
                    (unsigned long long)((uintptr_t)st->site - (uintptr_t)slide), (long long)st->made, sh->rc);
            rc_history(st->sample);
            replayed++;
        }
    }
    for (int b = 0; b < CAP_BUCKETS; b++) {
        if (g_cap_peak[b] == 0) continue;
        avra_say("mem:     cap %-9lld peak %6lld MB, now %6lld MB in %lld buffers\n",
                (long long)1 << b, (long long)(g_cap_peak[b] >> 20), (long long)(g_cap_live[b] >> 20), (long long)g_cap_count[b]);
    }
}

#if AVRA_MEASURES_MEMORY
static int64_t g_mem_ceiling;
static int64_t g_mem_next;
#endif

// Settled at load, for the reason `rc_guard_init` gives: a lazy
// getenv inside this carries into every allocation's fast path.
__attribute__((constructor))
static void acc_settled(void) {
#if AVRA_INSTRUMENTS
    g_acc_on = getenv("AVRA_MEM_STATS") != NULL;
#endif
    if (g_acc_on) atexit(acc_report);
#if AVRA_MEASURES_MEMORY
    const char* ceiling = getenv("AVRA_MEM_CEILING_MB");
    if (ceiling && *ceiling) g_mem_ceiling = g_mem_next = (int64_t)avra_number(ceiling, 10) << 20;
#endif
    CENSUS(g_sites_census = getenv("AVRA_CENSUS_SITES") != NULL);
}

static inline int accounting(void) { return g_acc_on; }

// A box a runtime row just minted, named by `label`: counted by a census
// build, nothing in a shipping one. The calls exist only in a program
// the backend built with AVRA_CENSUS_TYPES set.
void avra_census_box(const char* label) {
#ifdef AVRA_CENSUS
    Site* s = site_in(g_type_sites, &g_type_slots, (void*)(uintptr_t)label);
    if (s) s->made++;
#else
    (void)label;
#endif
}

// EVERY BOX AND BUFFER ALIVE, in bytes, counted whether or not the
// report is on: a settlement's memory ceiling reads it, so it is
// never a guess and never a sampler's number. Measured free: the add
// sits in bodies that call malloc or free and already keep a frame,
// and `check packages/std-avrac` timed the same with it gated.
static int64_t g_live_bytes = 0;

int64_t avra_mem_live(void) { return g_live_bytes; }

// THE MEMORY CEILING: memory in use past AVRA_MEM_CEILING_MB traps, so
// a runaway program ends as a wreck instead of taking the machine. The
// default suits a 16 GB machine; 0 turns it off. Read only where fresh
// memory is taken from the system, never on a recycled box.
// THE LEDGER ONLY SAYS WHEN TO LOOK; THE ALLOCATOR DECIDES. The live
// ledger is cheap and can drift from what is really held, so crossing
// `g_mem_next` measures the allocator's own bytes in use: past the
// ceiling it traps, and under it the next look waits for the ledger to
// grow by the headroom that measurement left.
#if AVRA_MEASURES_MEMORY
static int64_t g_mem_ceiling = (int64_t)6000 << 20;
static int64_t g_mem_next = (int64_t)6000 << 20;

static int64_t mem_in_use(void) {
#ifdef __APPLE__
    malloc_statistics_t st;
    malloc_zone_statistics(NULL, &st);
    return (int64_t)st.size_in_use;
#else
    struct mallinfo2 mi = mallinfo2();
    return (int64_t)(mi.uordblks + mi.hblkhd);
#endif
}

__attribute__((noinline, cold))
static void mem_ceiling_measure(void) {
    int64_t used = mem_in_use();
    if (used > g_mem_ceiling) {
        char msg[96];
        avra_fmt(msg, sizeof msg, "memory ceiling exceeded: %lld MB (AVRA_MEM_CEILING_MB)",
               (long long)(g_mem_ceiling >> 20));
        avra_trap(msg);
    }
    g_mem_next = g_live_bytes + (g_mem_ceiling - used);
}
#endif

static inline void mem_ceiling_check(void) {
#if AVRA_MEASURES_MEMORY
    if (__builtin_expect(g_mem_ceiling > 0 && g_live_bytes > g_mem_next, 0)) mem_ceiling_measure();
#endif
}

// Fresh memory from the system, past the ceiling's check: one call in
// the caller either way, so the check adds nothing to a caller's size.
__attribute__((noinline))
static void* fresh(size_t n) {
    mem_ceiling_check();
    return malloc(n);
}

// THE MORTAL LEDGER: every byte a box or buffer holds that a normal
// release path would eventually free. A box `avra_once_set` makes
// IMMORTAL never reaches that path again by design (the answer is
// held for the process's life), so `avra_once_set` credits its bytes
// back out of this ledger the moment it promotes it (`once_box_credit`)
// rather than leaving them counted as still owed — a STATIC aggregate
// (a const's, baked by the backend at compile time) never touches
// this ledger to begin with, so it needs no credit at all. This is
// what lets a leak check read the ledger against zero without a
// `once` cache or a compile-time constant reading as one.
static int64_t g_mortal_live = 0;

// The report's own tables, kept only while it is on.
__attribute__((noinline, cold))
static void acc_note(int k, int64_t bytes) {
    g_acc_live[k] += bytes;
    g_acc_total_live += bytes;
    if (g_acc_live[k] > g_acc_peak[k]) g_acc_peak[k] = g_acc_live[k];
    if (g_acc_total_live > g_acc_total_peak) g_acc_total_peak = g_acc_total_live;
}

static inline void acc_add(int k, int64_t bytes) {
    g_live_bytes += bytes;
    g_mortal_live += bytes;
    if (__builtin_expect(accounting(), 0)) acc_note(k, bytes);
}

static int acc_kind_of(int32_t kind);

// A box's bytes moved: its kind's category is read only for the report.
// Immortal and static kinds (negative) never reach `box_free`, so they
// are excluded from the mortal ledger at the same test that already
// excludes them from retain/release (`kind < 0`) — a `once` answer's
// OWN box is credited back separately, since it is minted mortal and
// only turns immortal after this call already counted it.
static inline void acc_box(int32_t kind, int64_t bytes) {
    g_live_bytes += bytes;
    if (kind >= 0) g_mortal_live += bytes;
    if (__builtin_expect(accounting(), 0)) acc_note(acc_kind_of(kind), bytes);
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
    CENSUS(g_boxes_made++);
    CENSUS(g_made_by_kind[acc_kind_of(kind)]++);
    Header* h = cls ? g_free[cls] : NULL;
    if (h) {
        g_free[cls] = *(Header**)(h + 1);
        g_free_len[cls]--;
    } else {
        h = (Header*)fresh(sizeof(Header) + (cls ? cls * CLASS_BYTES : bytes));
    }
    h->tag = AVRA_TAG;
    h->kind = kind;
    h->rc = 1;
    h->len = (uint32_t)bytes;
    acc_box(kind, (int64_t)(sizeof(Header) + bytes));
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
    acc_box(h->kind, -(int64_t)(sizeof(Header) + bytes));
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

// An immutable value answered as ITSELF: one more reference, owned
// by the caller, to the same box.
static const char* shared(const char* p);

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
            intptr_t sl = image_slide();
            avra_say("    %s from 0x%llx -> rc %lld\n",
                    g_log[i].delta > 0 ? "retain" : "release", (unsigned long long)((uintptr_t)g_log[i].at - (uintptr_t)sl), (long long)g_log[i].rc);
        }
    }
}

static void array_reclaim(void* p);
static void array_poison(void* p);
static void map_reclaim(void* p);
static void guard_kept(void* p, Header* h);
static inline int64_t index_words(AvraMap* m);
static void* box_clone(void* p);

// DEBUG GUARD (AVRA_RC_GUARD=1): a box that reaches rc 0 is KEPT,
// marked dead, so the next read of it traps at the site that used
// it rather than somewhere later.
#if AVRA_INSTRUMENTS
int avra_rc_guard_on = 0;

// THE GUARD IS READ ONCE, AT LOAD. Retain and release are the two
// hottest functions in the compiler, and a lazy `if (g_guard < 0)`
// inside them carries getenv's register pressure into the fast
// path — clang then sets up a 64-byte frame before the increment.
// Settling it here keeps that path a load, an add and a store.
__attribute__((constructor))
static void rc_guard_init(void) {
    avra_rc_guard_on = getenv("AVRA_RC_GUARD") != NULL;
    const char* budget = getenv("AVRA_RC_LOG_BUDGET");
    if (budget) g_log_budget = (size_t)avra_number(budget, 10);
}
#endif
static void* g_chain[64];
static int g_chain_len = 0;

// An array box's cell count, for the guard's report; -1 when the
// pointer is not an array this runtime owns.
static int64_t guard_len(void* p);

static inline int rc_guarded(void) { return avra_rc_guard_on; }

void avra_rc_dead_check(void* p, const char* what) {
    if (!rc_guarded()) return;
    Header* h = hdr(p);
    if (h && h->kind == KIND_DEAD) {
        avra_say("avra: %s read a RELEASED box %p\n", what, p);
        abort();
    }
}

__attribute__((noinline, cold))
void avra_retain_noted(void* p, Header* h) {
    h->rc++;
    rc_note(p, 1, AVRA_CALLER(), h->rc);
}


// The guard's release: the box is kept and marked dead, its cells
// poisoned; a second release of a dead box reports its history.
__attribute__((noinline, cold))
void avra_release_guarded(void* p, Header* h) {
    if (h->kind == KIND_DEAD) {
        avra_say("avra: released an already-dead box %p (len %lld)\n", p, (long long)guard_len(p));
        avra_say("  this one from %p\n", AVRA_CALLER());
        rc_history(p);
        for (int k = g_chain_len - 1; k >= 0; k--) {
            avra_say("  reclaiming %p (len %lld)\n", g_chain[k], (long long)guard_len(g_chain[k]));
        }
        abort();
    }
    if (h->kind < 0) return;
    h->rc--;
    rc_note(p, -1, AVRA_CALLER(), h->rc);
    if (h->rc > 0) return;
    int32_t kind = h->kind;
    guard_kept(p, h);
    if (kind == KIND_ARRAY) {
        int pushed = g_chain_len < 64;
        if (pushed) { g_chain[g_chain_len] = p; g_chain_len++; }
        array_poison(p);
        if (pushed) g_chain_len--;
    } else if (kind == KIND_MAP) {
        avra_rc_release(((AvraMap*)p)->keys);
        avra_rc_release(((AvraMap*)p)->vals);
    }
}

__attribute__((noinline))
void avra_release_dead(void* p, int32_t kind) {
    if (kind == KIND_ARRAY) {
        array_reclaim(p);
    } else if (kind == KIND_MAP) {
        map_reclaim(p);
    } else {
        box_free(p);
    }
}


// ── Reuse in place ──────────────────────────────────────────────
// A `_reusing` twin CONSUMES its first seat: the compiler hands it a
// reference it owns and never reads again. A box that reference holds
// ALONE is written in place and answered; a shared or immortal one is
// left to its other holders, a fresh answer is made, and the handed
// reference is released. The compiler decides when a value may be
// handed over; the count decides whether the box may be written.

static const char* shared(const char* p) {
    avra_rc_retain((void*)p);
    return p;
}

// A text or octet box the handed reference holds alone.
static inline int sole_sized(const char* p) {
    Header* h = hdr((void*)p);
    return h && (h->kind == KIND_STR || h->kind == KIND_BYTES) && h->rc == 1;
}

static size_t block_size(Header* h) {
#ifdef __APPLE__
    return malloc_size(h);
#else
    return malloc_usable_size(h);
#endif
}

// The content bytes a sized box can hold, its NUL's byte spared. A
// classed box holds its class; a bigger one what its block holds. The
// class is read from the LENGTH, so a box shrunk in place answers the
// smaller class — cheap, and an UNDER-report only, never over: the
// slow path in `sized_moved` asks the block itself before it moves
// anything, so this stays the fast check every append pays.
static size_t sized_capacity(Header* h) {
    size_t cls = class_of((size_t)h->len + 1);
    if (cls) return cls * CLASS_BYTES - 1;
    return block_size(h) - sizeof(Header) - 1;
}

// Whether a sized box can hold `need` content bytes without moving:
// its block has the room, and the class its new length files under
// when freed is no bigger than the block.
static int in_place_fits(Header* h, size_t need) {
    size_t payload = block_size(h) - sizeof(Header);
    size_t cls = class_of(need + 1);
    return need + 1 <= payload && (cls == 0 || cls * CLASS_BYTES <= payload);
}

// A sized box's length moved to `n`, its terminator written.
// Accounting follows the LENGTH, as `box_free` does.
static void sized_resized(Header* h, size_t n) {
    acc_box(h->kind, (int64_t)n - (int64_t)h->len);
    h->len = (uint32_t)n;
    ((char*)(h + 1))[n] = '\0';
}

// A sole sized box grown to hold `need` content bytes: in place when
// its block has room, else moved to one with room to double into.
// Answers where the content lives now; the first `len` bytes carry.
__attribute__((noinline))
static char* sized_moved(char* p, size_t need) {
    Header* h = (Header*)p - 1;
    // The CLASS check that sent us here reads the LENGTH, which
    // truncation can shrink well under the block's real size — ask
    // the allocator once, here on the already-slow path, rather than
    // on every append's fast check, before paying for a move the
    // block never needed. `box_free` files a box by its LENGTH's
    // class, so growing in place is sound only while that class
    // still fits the block: an allocator may round a block past its
    // class (glibc does, by 8), and a box grown into that slack would
    // be handed out later as a bigger class than its block holds.
    if (!rc_guarded() && in_place_fits(h, need)) return p;
    size_t n = h->len;
    size_t room = need < 2 * n ? 2 * n : need;
    if (room + 1 <= CLASS_MAX || class_of(n + 1) != 0 || rc_guarded()) {
        // a classed box moves to a fresh one; under the guard every move
        // is fresh, and the old box is kept, marked dead and poisoned, so
        // a stale reader finds garbage rather than the text it expected
        char* out = (char*)box_alloc(room + 1, h->kind);
        Header* oh = (Header*)out - 1;
        acc_box(oh->kind, -(int64_t)(room - n));
        oh->len = (uint32_t)n;
        memcpy(out, p, n);
        if (rc_guarded()) {
            guard_kept(p, h);
            memset(p, 0xDD, n);
        } else {
            box_free(p);
        }
        return out;
    }
    mem_ceiling_check();
    Header* moved = (Header*)realloc(h, sizeof(Header) + room + 1);
    if (moved == NULL) avra_trap("out of memory growing a value in place");
    return (char*)(moved + 1);
}

static char* sized_grown(char* p, size_t need) {
    if (need >= UINT32_MAX) avra_trap("a value is longer than its header can carry");
    Header* h = (Header*)p - 1;
    char* out = need <= sized_capacity(h) ? p : sized_moved(p, need);
    sized_resized((Header*)out - 1, need);
    return out;
}

// `a` with `b` appended, `a` consumed.
static const char* appended(const char* a, const char* b, size_t m) {
    size_t n = ((Header*)a - 1)->len;
    char* out = sized_grown((char*)a, n + m);
    memcpy(out + n, b, m);
    return out;
}

// ── The trap contract ───────────────────────────────────────────

// THE CASE IN FLIGHT. A suite runs in one process, so a trap kills
// every case after it — this is how the wreck names which one it
// was running when it died.
static const char* g_case = NULL;

void avra_case_begin(const char* label) {
    g_case = label;
}

const char* avra_case_now(void) {
    return g_case;
}

// A TRAP IS A WRECK, not a verdict: status 2 keeps it distinct from
// the 1 a program leaves when it merely disagrees with its input.
// The program's own lines come first: stdout is block-buffered into a
// pipe, so without the flush a trap's words land AHEAD of lines printed
// before it, in exactly the logs a reader reads after a wreck.
void avra_trap(const char* msg) {
    fflush(stdout);
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
    // THE LINE IS ON ITS STREAM WHEN THIS RETURNS: stdout is fully buffered
    // when it is not a terminal, so a live-run flush is what lets a server's
    // line be heard and what keeps a trap from taking the lines before it.
    fflush(stdout);
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
    // one box is one text: a literal compared at its own call site is
    // the same static box every time
    if (a == b) return 1;
    if (a == NULL || b == NULL) return 0;
    size_t la = str_len(a);
    return la == str_len(b) && memcmp(a, b, la) == 0;
}

// An int's decimal text — what `${n}` interpolates and `print`
// shows. Owned.
// `/` and `%` by zero: the interpreter REFUSES, so the native
// binary must too. LLVM's sdiv/srem by zero is undefined behaviour —
// left raw it printed an answer and exited 0, which is a silently
// wrong program.
// Division by -1 is negation, which WRAPS on the smallest int as `-`
// does; C leaves that one quotient undefined, so it is spelled.
int64_t avra_int_div(int64_t a, int64_t b) {
    if (b == 0) { avra_trap("division by zero"); }
    if (b == -1) { return (int64_t)((uint64_t)0 - (uint64_t)a); }
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
    if (b == -1) { return 0; }
    return a % b;
}

// Formatted first and boxed at its exact length: a box's header
// length is what `box_free` files it by, so it must describe the
// allocation — shrinking it afterwards misfiles the box.
// Digits written backwards from the end of a scratch buffer — the
// magnitude taken as unsigned, so the smallest int has one too.
const char* avra_int_text(int64_t v) {
    char digits[24];
    char* end = digits + sizeof digits;
    char* p = end;
    uint64_t m = v < 0 ? (uint64_t)0 - (uint64_t)v : (uint64_t)v;
    do { *--p = (char)('0' + m % 10); m /= 10; } while (m != 0);
    if (v < 0) *--p = '-';
    size_t n = (size_t)(end - p);
    char* buf = sized_box(n, KIND_STR);
    memcpy(buf, p, n);
    buf[n] = '\0';
    return buf;
}

// TEXT -> INT, the walk `avra_int_text` inverts. `-`? digits, the
// ceiling on both sides, nothing else — no space, no `+`, no
// fraction. Reads the header's LENGTH, never `strlen`: a NUL inside
// is an ordinary byte the digit test refuses on sight, not a place
// the walk stops early and calls the prefix a number.
//
// THE MAGNITUDE ACCUMULATES NEGATIVE, whichever sign the text wears,
// and is negated back only for a positive answer. A POSITIVE walk
// bounded by `9223372036854775807` can never reach
// `-9223372036854775808` without first wrapping past it — the same
// wall the lexer's own token grammar hits, and why that literal has
// no spelling in the language today. Walking negative instead needs
// no wider type: the accumulator's floor is `INT64_MIN` for a `-`
// text and one short of it for a bare one, so a positive answer's
// final negation never overflows either.
static int64_t avra_int_parse_walk(const char* s, int64_t n, int64_t* out) {
    int64_t i = 0;
    int64_t negative = 0;
    if (n > 0 && s[0] == '-') { negative = 1; i = 1; }
    if (i == n) return 0;
    int64_t limit = negative ? (0 - 9223372036854775807 - 1) : (0 - 9223372036854775807);
    int64_t limit_div10 = limit / 10;
    int64_t limit_last = 0 - (limit - limit_div10 * 10);
    int64_t v = 0;
    for (; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c < '0' || c > '9') return 0;
        int64_t d = c - '0';
        if (v < limit_div10 || (v == limit_div10 && d > limit_last)) return 0;
        v = v * 10 - d;
    }
    *out = negative ? v : (0 - v);
    return 1;
}

// Whether `s` is exactly an int, by the walk above.
int64_t avra_str_parses_int(const char* s) {
    int64_t out = 0;
    return avra_int_parse_walk(s, (int64_t)str_len(s), &out);
}

// The int `s` spells — meaningful only where `avra_str_parses_int`
// answered true, so the two must read the SAME bytes: one walk, two
// exported doors onto it.
int64_t avra_str_parsed_int(const char* s) {
    int64_t out = 0;
    avra_int_parse_walk(s, (int64_t)str_len(s), &out);
    return out;
}

// TEXT -> FLOAT: `-`? digits, then `.` digits and an exponent
// (`e`/`E`, a sign, digits) each optional — the spelling `strtod`
// shares with every number format we read, and NOTHING it adds: no
// space, no `+` lead, no `inf`/`nan`, no hex. The walk reads the
// header's length and answers the span it covers, so `strtod` is
// only ever handed text the walk already read whole.
static int64_t avra_float_parse_walk(const char* s, int64_t n) {
    int64_t i = 0;
    if (i < n && s[i] == '-') i++;
    int64_t from = i;
    while (i < n && s[i] >= '0' && s[i] <= '9') i++;
    if (i == from) return 0;
    if (i < n && s[i] == '.') {
        from = ++i;
        while (i < n && s[i] >= '0' && s[i] <= '9') i++;
        if (i == from) return 0;
    }
    if (i < n && (s[i] == 'e' || s[i] == 'E')) {
        i++;
        if (i < n && (s[i] == '+' || s[i] == '-')) i++;
        from = i;
        while (i < n && s[i] >= '0' && s[i] <= '9') i++;
        if (i == from) return 0;
    }
    return i == n;
}

// The double a walked text spells, read from a bounded copy so the
// terminator `strtod` stops at is one this fn wrote.
static double avra_float_parse_read(const char* s, int64_t n) {
    char* t = malloc((size_t)n + 1);
    memcpy(t, s, (size_t)n);
    t[n] = '\0';
    double d = strtod(t, NULL);
    free(t);
    return d;
}

// Whether `s` is exactly a float the type HOLDS: the walk above,
// and finite — past the largest double is absent, never infinity.
// Underflow is kept: the nearest double, as a float literal is.
int64_t avra_str_parses_float(const char* s) {
    int64_t n = (int64_t)str_len(s);
    return avra_float_parse_walk(s, n) && isfinite(avra_float_parse_read(s, n));
}

// The float `s` spells — meaningful only where
// `avra_str_parses_float` answered true.
double avra_str_parsed_float(const char* s) {
    return avra_float_parse_read(s, (int64_t)str_len(s));
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
    CENSUS(g_bufs_made++);
    if (cls >= 0 && g_buf_free[cls]) {
        int64_t* buf = (int64_t*)g_buf_free[cls];
        g_buf_free[cls] = *(void**)buf;
        g_buf_free_len[cls]--;
        return buf;
    }
    return (int64_t*)fresh(buf_bytes(cap));
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
    a->marks = (uint8_t*)(a->data + a->cap);
}

// A box that will hold `n` slots — a record's, a literal's — takes
// a buffer of exactly `n`; `n` of 0 is a builder's box, which grows.
// A LIST'S ONE CONSTRUCTION. `avra_array_new` is `avra_array_sized`
// with no size asked, so the shape is written once and the site is
// handed in — a return address read inside would name this fn, not
// the caller the accounting wants.
static int laid_out(AvraArray* a);

// The bytes a list holds: its box, and its buffer when the cells are
// not laid inside the box.
static int64_t array_bytes(AvraArray* a) {
    int64_t box = (int64_t)(sizeof(Header) + ((Header*)a - 1)->len);
    return laid_out(a) ? box : box + (int64_t)buf_bytes(a->cap);
}

__attribute__((noinline, cold))
static void sized_noted(AvraArray* a, void* ra) {
    a->site = g_clone_site ? g_clone_site : ra;
    g_sample_next = a;
    acc_site(a->site, array_bytes(a), 1);
}

// A box asked for a SIZE is one block — its cells and marks laid right
// after the AvraArray, as static data is — so a record costs one
// allocation. A builder (no size asked) keeps a buffer of its own,
// since it grows.
static AvraArray* array_made(int64_t cap, void* ra) {
    AvraArray* a;
    if (cap > 0) {
        a = (AvraArray*)box_alloc(sizeof(AvraArray) + buf_bytes(cap), KIND_ARRAY);
        a->cap = cap;
        a->data = (int64_t*)(a + 1);
    } else {
        a = (AvraArray*)box_alloc(sizeof(AvraArray), KIND_ARRAY);
        a->cap = ARRAY_FIRST;
        a->data = buf_alloc(a->cap);
    }
    a->len = 0;
    array_marks(a);
    memset(a->marks, 0, (size_t)a->cap);
    a->site = NULL;
    if (__builtin_expect(g_acc_on > 0, 0)) sized_noted(a, ra);
    return a;
}

void* avra_array_sized(int64_t n) { return array_made(n, AVRA_CALLER()); }

void* avra_array_new(void) { return array_made(0, AVRA_CALLER()); }

// The guard's reclaim: children released as usual, the box kept and
// its cells poisoned, so a stale reader trips instead of finding a
// plausible value.
static void array_poison(void* p) {
    AvraArray* a = (AvraArray*)p;
    for (int64_t i = 0; i < a->len; i++) {
        if (a->marks[i] & MARK_OWNED) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    memset(a->data, 0xDD, (size_t)a->len * sizeof(int64_t));
}

// A BOX THE GUARD KEEPS IS FREED TO EVERY LEDGER: marked dead, and the
// bytes its reclaim would free — the box, a list's cells, a map's index —
// leave the live and mortal counts, so a guarded run's budget and leak
// line read what an unguarded run holds. Asked before the mark, while
// the header still says what the box is.
static void guard_kept(void* p, Header* h) {
    if (h->kind == KIND_ARRAY) {
        AvraArray* a = (AvraArray*)p;
        if (a->site) acc_site(a->site, -array_bytes(a), -1);
        if (!laid_out(a)) acc_add(ACC_BUF, -(int64_t)buf_bytes(a->cap));
    } else if (h->kind == KIND_MAP) {
        acc_add(ACC_INDEX, -index_words((AvraMap*)p) * (int64_t)sizeof(int64_t));
    }
    acc_box(h->kind, -(int64_t)(sizeof(Header) + box_bytes(h)));
    h->kind = KIND_DEAD;
    h->rc = 0;
}

static int64_t guard_len(void* p) {
    Header* h = hdr(p);
    return h == NULL ? -1 : ((AvraArray*)p)->len;
}

// Releases every owned slot, then the array itself.
static void array_reclaim(void* p) {
    AvraArray* a = (AvraArray*)p;
    for (int64_t i = 0; i < a->len; i++) {
        if (a->marks[i] & MARK_OWNED) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    if (a->site) acc_site(a->site, -array_bytes(a), -1);
    if (!laid_out(a)) buf_free(a->data, a->cap);
    box_free(a);
}

// No list holds more cells than this: a capacity past it is a
// corrupted box, and the program stops rather than asking the
// machine for the memory.
#define CELL_CEILING ((int64_t)1 << 31)

// Doubles the capacity: a classed buffer moves to the next class, a
// big one grows in place; the marks follow the cells to their new
// place, the new marks zero.
// A LAID-OUT BOX'S CELLS LIE INSIDE THE BOX ITSELF — static data (the
// backend lays the buffer right after the AvraArray) and every sized
// box — so that buffer is never the allocator's to free or realloc: a
// grow moves the cells out and leaves the laid-out ones where they
// are, and the box frees them with itself.
static int laid_out(AvraArray* a) {
    return a->data == (int64_t*)(a + 1);
}

static void array_grow(AvraArray* a) {
    int64_t old_cap = a->cap;
    int64_t cap = old_cap < ARRAY_FIRST ? ARRAY_FIRST : old_cap * 2;
    int64_t* buf;
    int fixed = laid_out(a);
    int64_t before = a->site ? array_bytes(a) : 0;
    if (fixed || buf_class(old_cap) >= 0) {
        buf = buf_alloc(cap);
        memcpy(buf, a->data, (size_t)old_cap * sizeof(int64_t));
        memcpy((uint8_t*)(buf + cap), a->marks, (size_t)old_cap);
        if (!fixed) buf_free(a->data, old_cap);
    } else {
        mem_ceiling_check();
        buf = (int64_t*)realloc(a->data, buf_bytes(cap));
        acc_add(ACC_BUF, (int64_t)(buf_bytes(cap) - buf_bytes(old_cap)));
        if (g_acc_on > 0) { acc_buf(old_cap, -(int64_t)buf_bytes(old_cap), -1); acc_buf(cap, (int64_t)buf_bytes(cap), 1); }
        memmove((uint8_t*)(buf + cap), (uint8_t*)(buf + old_cap), (size_t)old_cap);
    }
    a->data = buf;
    a->cap = cap;
    array_marks(a);
    memset(a->marks + a->len, 0, (size_t)(cap - a->len));
    if (a->site) acc_site(a->site, array_bytes(a) - before, 0);
}

// A FULL LIST'S WRITE, whole and out of line, so the common write
// TAIL-calls it and keeps no frame of its own.
__attribute__((noinline))
static void push_grown(AvraArray* a, int64_t v) {
    if (a->cap >= CELL_CEILING || a->cap <= 0) avra_trap("a list grew past any possible size — a corrupted box");
    array_grow(a);
    a->data[a->len] = v;
    a->marks[a->len] = 0;
    a->len++;
}

void avra_array_reserve(void* arr, int64_t spare) {
    AvraArray* a = (AvraArray*)arr;
    while (a->cap - a->len < spare) {
        if (a->cap >= CELL_CEILING || a->cap < 0) avra_trap("a list grew past any possible size — a corrupted box");
        array_grow(a);
    }
}

void avra_array_push(void* arr, int64_t v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    AvraArray* a = (AvraArray*)arr;
    if (__builtin_expect(a->len == a->cap, 0)) { push_grown(a, v); return; }
    a->data[a->len] = v;
    a->marks[a->len] = 0;
    a->len++;
}

// RETAIN-AT-PACK: the array takes its own reference to a managed
// value and remembers the slot, so reclaim releases it.
void avra_array_push_owned(void* arr, void* v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    avra_array_push(arr, (int64_t)(uintptr_t)v);
    AvraArray* a = (AvraArray*)arr;
    a->marks[a->len - 1] = MARK_OWNED;
    avra_rc_retain(v);
}

// The push twin of `avra_slot_set_moved`: the caller's reference moves
// into the new slot.
void avra_array_push_moved(void* arr, void* v) {
    CENSUS(g_list_pushes++);
    CENSUS(note_push(AVRA_CALLER()));
    avra_array_push(arr, (int64_t)(uintptr_t)v);
    AvraArray* a = (AvraArray*)arr;
    a->marks[a->len - 1] = MARK_OWNED;
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

// ONE STILL-MORTAL BOX'S FOOTPRINT, walked the way `array_reclaim`
// and `map_reclaim` would free it — box, buffer and every OWNED slot,
// recursively — except nothing here is freed. Called from
// `avra_once_set` BEFORE the kind is flipped, so `h->kind` is still
// its true shape and `h->kind < 0` unambiguously means "never added
// to the mortal ledger": a STATIC aggregate (a const's, baked by the
// backend at compile time) never touched `acc_box`/`acc_add` to
// begin with, and neither did a string literal reached as a map key,
// so both are credited as nothing rather than walked — crediting a
// box the ledger never counted is the over-credit this guard exists
// to refuse. A KIND_PLAIN box (a record, an enum) has no
// runtime-visible owned fields — the compiler releases those by
// name, never by a mark the runtime can walk — so only its own
// header and payload are credited here; a `once fn` answering a
// record or enum with a managed field is undercredited, a recorded
// trigger for the day one exists.
static int64_t once_box_credit(void* p) {
    Header* h = hdr(p);
    if (h == NULL || h->kind < 0) return 0;
    switch (h->kind) {
        case KIND_ARRAY: {
            AvraArray* a = (AvraArray*)p;
            int64_t total = array_bytes(a);
            for (int64_t i = 0; i < a->len; i++) {
                if (a->marks[i] & MARK_OWNED) total += once_box_credit((void*)(uintptr_t)a->data[i]);
            }
            return total;
        }
        case KIND_MAP: {
            AvraMap* m = (AvraMap*)p;
            int64_t total = (int64_t)(sizeof(Header) + sizeof(AvraMap)) + index_words(m) * (int64_t)sizeof(int64_t);
            return total + once_box_credit(m->keys) + once_box_credit(m->vals);
        }
        case KIND_STR:
        case KIND_BYTES:
            return (int64_t)(sizeof(Header) + h->len + 1);
        default:
            return (int64_t)(sizeof(Header) + h->len);
    }
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
    // kind reflects the fact rather than the intention. Credited out
    // of the mortal ledger in the same breath, while `kind` still
    // names its true shape — a cache held for the process's life is
    // not a leak, so it must not read as bytes still owed.
    Header* vh = hdr(value);
    if (vh != NULL && vh->kind >= 0) {
        g_mortal_live -= once_box_credit(value);
        vh->kind = KIND_IMMORTAL(vh->kind);
    }
    g_once[g_once_count].key = key;
    g_once[g_once_count].value = value;
    once_index(key, g_once_count);
    g_once_count++;
}

// THE NATIVE FAST PATH'S COLD HALF. A compiled `once fn` keeps its
// own answer in a process-lifetime GLOBAL SLOT (one word, null until
// set) so every REPEAT call is a load and a null test, no call at
// all — this runs once, the first time the slot is still null, and
// settles both tables together: the keyed one (`avra_once_set`,
// unchanged — the credit and the immortal flip happen exactly there)
// and this fn's own slot, which the table's winner fills either way.
// A second caller racing the first still calls this — `avra_once_set`
// is the dedup, so the LOSER's slot is written the WINNER's value,
// never its own; only the loser's own local answer (this call's
// `value`, unused here after) differs from what the slot now holds.
void avra_once_slot_commit(void* key, void* value, void** slot) {
    avra_once_set(key, value);
    *slot = avra_once_get(key);
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
    avra_fmt(msg, sizeof msg,
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
void avra_trap_bounds(int64_t i, int64_t len) {
    char msg[80];
    avra_fmt(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
           (long long)i, (long long)len);
    avra_trap(msg);
    abort();
}

__attribute__((noinline, cold, noreturn))
static void trap_slice(int64_t lo, int64_t hi, int64_t len) {
    char msg[96];
    avra_fmt(msg, sizeof msg, "slice %lld..%lld is out of bounds (length %lld)",
           (long long)lo, (long long)hi, (long long)len);
    avra_trap(msg);
    abort();
}

// THE GUARDED READ, whole and out of line. The guard is a BRANCH on
// the read's path, never a call — a call there would cost the read a
// frame it does not otherwise need.
__attribute__((noinline, cold))
int64_t avra_get_guarded(void* arr, int64_t i) {
    avra_rc_dead_check(arr, "array_get");
    AvraArray* a = (AvraArray*)arr;
    if (i < 0 || i >= a->len) avra_trap_bounds(i, a->len);
    return a->data[i];
}

// The guarded read plus its retain, whole: the composition an
// inlined avra_array_get_owned would otherwise pay for is here
// instead, once, out of line.
__attribute__((noinline, cold))
void* avra_get_owned_guarded(void* arr, int64_t i) {
    void* v = (void*)(uintptr_t)avra_get_guarded(arr, i);
    Header* h = hdr(v);
    if (h != 0 && h->kind >= 0) avra_retain_noted(v, h);
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
        c->marks[i] = a->marks[i];
        if (a->marks[i] & MARK_OWNED) {
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

// AVRA_ALIAS_LOG: one stderr line per ACTUAL uniquify clone (never
// per call — is_shared already gates this branch to the rare case),
// naming the caller's return address and the cloned box's ELEMENT
// COUNT. A list, a record and an enum's payload are ALL the same
// AvraArray shape (array_clone treats every non-map box so, box_clone
// above), so `n` here is `a->len` — the field count for a record, the
// element count for a list — never the header's `len`, which is the
// WRAPPER struct's own fixed byte size (40, sizeof(AvraArray)) and
// says nothing about what the box holds. The flag is read once, in a
// constructor, so a shipping run pays no getenv; the log fn is its
// own out-of-line, cold body so the two hot leaves below carry no
// extra frame for it — only the clone branch they already pay for
// gains one more call.
#if AVRA_INSTRUMENTS
static int g_alias_log = 0;

__attribute__((constructor))
static void alias_log_init(void) {
    g_alias_log = getenv("AVRA_ALIAS_LOG") != NULL;
}
#else
enum { g_alias_log = 0 };
#endif

__attribute__((noinline, cold))
static void alias_log_clone(void* site, void* box) {
    if (!g_alias_log) return;
    Header* h = hdr(box);
    int64_t n = -1;
    if (h) {
        n = (KIND_SHAPE(h->kind) == KIND_MAP) ? ((AvraMap*)box)->keys->len : ((AvraArray*)box)->len;
    }
    // UNSLID: `atos -o <binary> <addr>` reads a file offset, not a
    // live ASLR address — subtract the image's own slide so the
    // printed address is directly symbolicatable after the fact.
    intptr_t slide = image_slide();
    avra_say("ALIAS_CLONE site=%p kind=%d n=%lld\n", (void*)((char*)site - slide), h ? (int)KIND_SHAPE(h->kind) : -999, (long long)n);
}

// Empties a cell WITHOUT releasing what it held: the cell's reference
// moves to the value loaded from it, which a reusing twin consumes
// before the store that refills the cell.
void avra_cell_forget(void* slot) {
    *(void**)slot = NULL;
}

// Opens a mut cell's box for writing: itself when nothing else
// holds it, else a clone stored into the cell (the old reference
// released). The answer is BORROWED from the cell.
void* avra_cell_unique(void* slot) {
    void* p = *(void**)slot;
    if (!is_shared(p)) return p;
    CENSUS(note_copy(AVRA_CALLER()));
    g_clone_site = AVRA_CALLER();
    void* c = box_clone(p);
    alias_log_clone(g_clone_site, c);
    g_clone_site = NULL;
    *(void**)slot = c;
    avra_rc_release(p);
    return c;
}

// Opens a mut cell's box only when it is the binary's own data: a
// clone stored into the cell. A counted box stands, whoever else holds
// it — a fresh local is its own, and an identity its hooks capture
// stays one. The answer is BORROWED from the cell.
void* avra_cell_thawed(void* slot) {
    void* p = *(void**)slot;
    Header* h = hdr(p);
    if (h == NULL || !IS_IMMORTAL(h->kind)) return p;
    return avra_cell_unique(slot);
}

// avra_box_thawed's rare tail: `p` IS the binary's own data, so a
// fresh clone answers instead of `p` itself — already counted. OWNED
// either way, so the memory pass releases what it gets back exactly
// once. `ra` is the ORIGINAL call site, carried in from the hot leaf
// so the clone log names the write, not this out-of-line half.
void* avra_box_thawed_cloned(void* p, void* ra) {
    g_clone_site = ra;
    void* c = box_clone(p);
    alias_log_clone(g_clone_site, c);
    g_clone_site = NULL;
    return c;
}

// A value enum's TAGGED BOX: its tag, then its word — owned, and
// counted, when bit `tag` of `counted` says the variant carries a
// pointer. The shape a boxed enum has, so every reader reads it alike.
// A nullable's absent tag (-1) is the null pointer.
void* avra_enum_boxed(int64_t tag, int64_t word, int64_t counted) {
    if (tag < 0) return NULL;
    void* box = array_made(2, AVRA_CALLER());
    avra_array_push(box, tag);
    if ((counted >> tag) & 1) avra_array_push_owned(box, (void*)(uintptr_t)word);
    else avra_array_push(box, word);
    return box;
}

// A tagged box's tag: -1, a nullable's absence, for the null pointer.
int64_t avra_enum_tag(void* box) {
    return box ? ((AvraArray*)box)->data[0] : -1;
}

// A tagged box's word, borrowed from it: 0 for a variant laid out with
// no payload slot, and for the null pointer.
int64_t avra_enum_word(void* box) {
    AvraArray* a = (AvraArray*)box;
    return a && a->len > 1 ? a->data[1] : 0;
}

// The same one level down: the box in a slot, made unique in place.
void* avra_slot_unique(void* arr, int64_t i) {
    void* p = (void*)(uintptr_t)avra_array_get(arr, i);
    if (!is_shared(p)) return p;
    AvraArray* a = (AvraArray*)arr;
    g_clone_site = AVRA_CALLER();
    void* c = box_clone(p);
    alias_log_clone(g_clone_site, c);
    g_clone_site = NULL;
    a->data[i] = (int64_t)(uintptr_t)c;
    a->marks[i] = MARK_OWNED;
    avra_rc_release(p);
    return c;
}

// The same, for a slot whose word may be a scalar: only a slot that
// OWNS a box is opened; any other word is answered as it stands.
void* avra_owned_slot_unique(void* arr, int64_t i) {
    AvraArray* a = (AvraArray*)arr;
    int64_t w = avra_array_get(arr, i);
    if (!(a->marks[i] & MARK_OWNED)) return (void*)(uintptr_t)w;
    return avra_slot_unique(arr, i);
}

// A write into a slot: the old owned content is released.
void avra_slot_set(void* arr, int64_t i, int64_t v) {
    AvraArray* a = (AvraArray*)arr;
    avra_array_get(arr, i);
    if (a->marks[i] & MARK_OWNED) avra_rc_release((void*)(uintptr_t)a->data[i]);
    a->data[i] = v;
    a->marks[i] = 0;
}

// RETAIN-AT-PACK for a slot write: the incoming value is retained
// FIRST (a self-store must not free what it keeps), then the old
// content goes.
void avra_slot_set_owned(void* arr, int64_t i, void* v) {
    avra_rc_retain(v);
    avra_slot_set(arr, i, (int64_t)(uintptr_t)v);
    ((AvraArray*)arr)->marks[i] = MARK_OWNED;
}

// A value enum's word pushed: owned, and counted, when bit `tag` of
// `counted` says the variant carries a pointer.
void avra_array_push_tagged(void* arr, int64_t word, int64_t tag, int64_t counted) {
    if (tag >= 0 && ((counted >> tag) & 1)) { avra_array_push_owned(arr, (void*)(uintptr_t)word); return; }
    avra_array_push(arr, word);
}

// A value enum's word written into slot `i`, the same way.
void avra_slot_set_tagged(void* arr, int64_t i, int64_t word, int64_t tag, int64_t counted) {
    if (tag >= 0 && ((counted >> tag) & 1)) { avra_slot_set_owned(arr, i, (void*)(uintptr_t)word); return; }
    avra_slot_set(arr, i, word);
}

// A MOVE into a slot: the caller hands over the reference it owns, so
// the slot keeps it without a retain — the pack of a value that dies
// there, which the caller then never releases.
void avra_slot_set_moved(void* arr, int64_t i, void* v) {
    avra_slot_set(arr, i, (int64_t)(uintptr_t)v);
    ((AvraArray*)arr)->marks[i] = MARK_OWNED;
}

// A NULLABLE SCALAR IN A SLOT is its word and one mark bit: absent,
// the word is zero and `MARK_ABSENT` set. No box — the mark byte is
// already there, beside every cell.
void avra_array_push_maybe(void* arr, int64_t present, int64_t v) {
    avra_array_push(arr, present ? v : 0);
    AvraArray* a = (AvraArray*)arr;
    a->marks[a->len - 1] = present ? 0 : MARK_ABSENT;
}

void avra_slot_set_maybe(void* arr, int64_t i, int64_t present, int64_t v) {
    avra_slot_set(arr, i, present ? v : 0);
    ((AvraArray*)arr)->marks[i] = present ? 0 : MARK_ABSENT;
}

// The twins for a nullable over a MANAGED value: present, the slot
// keeps its own reference (its word may be a null pointer); absent,
// there is nothing to keep.
void avra_array_push_maybe_owned(void* arr, int64_t present, void* v) {
    if (present) avra_array_push_owned(arr, v);
    else avra_array_push_maybe(arr, 0, 0);
}

void avra_slot_set_maybe_owned(void* arr, int64_t i, int64_t present, void* v) {
    if (present) avra_slot_set_owned(arr, i, v);
    else avra_slot_set_maybe(arr, i, 0, 0);
}

// Whether the slot a pop is about to hand over is present; an empty
// list traps as the pop would.
int64_t avra_array_last_present(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == 0) avra_trap("pop on an empty list");
    return !(a->marks[a->len - 1] & MARK_ABSENT);
}

int64_t avra_slot_present(void* arr, int64_t i) {
    AvraArray* a = (AvraArray*)arr;
    avra_array_get(arr, i);
    return !(a->marks[i] & MARK_ABSENT);
}

// ── Maps: string-keyed, insertion-ordered ───────────────────────

// Two arrays keep the written order (keys owned — the map holds
// its own reference to every key; values marked owned at set) and
// an open-addressing index over key hashes finds a slot. Kind 2.
//
// KEYS ARE REQUEST DATA — headers, query parameters, JSON object keys —
// so a hash an adversary can predict is a probe chain an adversary can
// build. Three laws hold the cost of a map to the number of its keys:
// - THE HASH READS THE WHOLE KEY, by its header length, as equality
//   does: a NUL is a character, and a hash that stopped at one filed
//   every key sharing the prefix before it on one chain.
// - THE HASH IS KEYED, by secrets drawn from the OS once per process,
//   so no collision can be computed ahead of time. A fork INHERITS
//   them: a core's maps were indexed before it was forked, and a
//   reseed would strand every one.
// - A PROBE PAST THE TRIPWIRE REKEYS THE MAP under SipHash-1-3 —
//   a seed-independent weakness in the fast hash, or a leaked seed,
//   costs that one map a slower hash, never a quadratic one.
// A probe steps by growing strides (1, 2, 3, …), which visits every
// word of a power-of-two index and keeps runs short where a step of one
// lets them merge. An index word holds the slot + 1 in its low half
// (0 is empty) and the key's hash in its high half, so a probe passing
// another key's word rarely reads that key's text. The word before the
// index says which hash filed it.

enum { PROBE_TRIPWIRE = 128 };

// The fast hash's seed and secret; then SipHash's key.
static uint64_t g_text_key[2];
static uint64_t g_sip_key[2];

static uint64_t splitmix(uint64_t* x) {
    uint64_t z = (*x += 0x9e3779b97f4a7c15ull);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ull;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebull;
    return z ^ (z >> 31);
}

// n words of the kernel's entropy; the clock and the address space
// when it has none to give, which the tripwire still bounds.
static void os_entropy(uint64_t* w, size_t n) {
#ifdef __APPLE__
    arc4random_buf(w, n * sizeof *w);
#elif defined(__wasm32__)
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    uint64_t x = (uint64_t)t.tv_nsec ^ ((uint64_t)t.tv_sec << 32) ^ (uint64_t)(uintptr_t)&t ^ (uint64_t)getpid();
    for (size_t i = 0; i < n; i++) w[i] = splitmix(&x);
#else
    size_t got = 0;
    while (got < n * sizeof *w) {
        ssize_t r = getrandom((char*)w + got, n * sizeof *w - got, 0);
        if (r > 0) { got += (size_t)r; continue; }
        if (r < 0 && errno == EINTR) continue;
        struct timespec t;
        clock_gettime(CLOCK_MONOTONIC, &t);
        uint64_t x = (uint64_t)t.tv_nsec ^ ((uint64_t)t.tv_sec << 32) ^ (uint64_t)(uintptr_t)&t ^ (uint64_t)getpid();
        for (size_t i = 0; i < n; i++) w[i] = splitmix(&x);
        return;
    }
#endif
}

static inline uint64_t wide_mix(uint64_t a, uint64_t b) {
    __uint128_t r = (__uint128_t)a * b;
    return (uint64_t)r ^ (uint64_t)(r >> 64);
}

// Drawn before any program code runs; `AVRA_HASH_SEED` pins them, so a
// run can be replayed. The seed never reaches output: a map iterates
// in written order.
__attribute__((constructor(101)))
static void hash_seeded(void) {
    uint64_t w[4];
#if AVRA_INSTRUMENTS
    const char* pinned = getenv("AVRA_HASH_SEED");
#else
    const char* pinned = NULL;
#endif
    if (pinned) {
        uint64_t x = avra_number(pinned, 0);
        for (int i = 0; i < 4; i++) w[i] = splitmix(&x);
    } else {
        os_entropy(w, 4);
    }
    g_text_key[0] = w[0];
    g_text_key[1] = w[1] | 1;
    g_sip_key[0] = w[2];
    g_sip_key[1] = w[3];
}

static inline uint64_t read8(const uint8_t* p) { uint64_t v; memcpy(&v, p, 8); return v; }
static inline uint64_t read4(const uint8_t* p) { uint32_t v; memcpy(&v, p, 4); return v; }

// The fast hash: wyhash's shape, every secret the process's own.
__attribute__((always_inline))
static inline uint64_t fast_hash(const char* s, size_t n) {
    const uint8_t* p = (const uint8_t*)s;
    const uint64_t* k = g_text_key;
    uint64_t seed = k[0], a, b;
    if (__builtin_expect(n <= 16, 1)) {
        if (n >= 4) {
            size_t q = (n >> 3) << 2;
            a = (read4(p) << 32) | read4(p + q);
            b = (read4(p + n - 4) << 32) | read4(p + n - 4 - q);
        } else if (n > 0) {
            a = ((uint64_t)p[0] << 16) | ((uint64_t)p[n >> 1] << 8) | p[n - 1];
            b = 0;
        } else {
            a = b = 0;
        }
    } else {
        size_t i = n;
        for (; i > 16; i -= 16, p += 16) seed = wide_mix(read8(p) ^ k[1], read8(p + 8) ^ seed);
        a = read8(p + i - 16);
        b = read8(p + i - 8);
    }
    __uint128_t r = (__uint128_t)(a ^ k[1]) * (b ^ seed);
    return wide_mix((uint64_t)r ^ k[0] ^ n, (uint64_t)(r >> 64) ^ k[1]);
}

#define SIP_ROTL(x, b) (uint64_t)(((x) << (b)) | ((x) >> (64 - (b))))
#define SIP_ROUND do { \
    v0 += v1; v1 = SIP_ROTL(v1, 13); v1 ^= v0; v0 = SIP_ROTL(v0, 32); \
    v2 += v3; v3 = SIP_ROTL(v3, 16); v3 ^= v2; \
    v0 += v3; v3 = SIP_ROTL(v3, 21); v3 ^= v0; \
    v2 += v1; v1 = SIP_ROTL(v1, 17); v1 ^= v2; v2 = SIP_ROTL(v2, 32); \
} while (0)

// SipHash-1-3 under the process's key: what a rekeyed map files by.
// Out of line, so the fast path carries none of it.
__attribute__((noinline, cold))
static uint64_t sip_hash(uint64_t k0, uint64_t k1, const char* s, size_t n) {
    const uint8_t* p = (const uint8_t*)s;
    uint64_t v0 = 0x736f6d6570736575ull ^ k0, v1 = 0x646f72616e646f6dull ^ k1;
    uint64_t v2 = 0x6c7967656e657261ull ^ k0, v3 = 0x7465646279746573ull ^ k1;
    for (const uint8_t* end = p + (n & ~(size_t)7); p != end; p += 8) {
        uint64_t m = read8(p);
        v3 ^= m;
        SIP_ROUND;
        v0 ^= m;
    }
    uint64_t last = (uint64_t)n << 56;
    for (size_t i = 0; i < (n & 7); i++) last |= (uint64_t)p[i] << (8 * i);
    v3 ^= last;
    SIP_ROUND;
    v0 ^= last;
    v2 ^= 0xff;
    SIP_ROUND;
    SIP_ROUND;
    SIP_ROUND;
    return v0 ^ v1 ^ v2 ^ v3;
}

// THE WORD BEFORE A BUILT INDEX: bit 0 says which hash filed it (set:
// the keyed fallback); the rest is the index's GENERATION — a number no
// other building of any index is given, so a probe's word can say which
// index it walked. The last number is SPENT: an index that wears it
// hands out no word at all.
enum { GEN_BITS = 36 };
static const uint64_t GEN_SPENT = ((uint64_t)1 << GEN_BITS) - 1;
static uint64_t g_index_gen;

static inline int map_keyed(AvraMap* m) { return (int)(m->index[-1] & 1); }
static inline uint64_t map_gen(AvraMap* m) { return (uint64_t)m->index[-1] >> 1; }

static uint64_t gen_minted(void) {
    uint64_t gen = __atomic_add_fetch(&g_index_gen, 1, __ATOMIC_RELAXED);
    return gen < GEN_SPENT ? gen : GEN_SPENT;
}

__attribute__((always_inline))
static inline uint64_t key_hash(int keyed, const char* key) {
    size_t n = str_len(key);
    return __builtin_expect(keyed, 0) ? sip_hash(g_sip_key[0], g_sip_key[1], key, n) : fast_hash(key, n);
}

static inline int64_t index_word(uint64_t hash, int64_t slot) {
    return (int64_t)((hash & 0xffffffff00000000ull) | (uint64_t)(slot + 1));
}

// The index's words, the keying word included; none while unbuilt.
static inline int64_t index_words(AvraMap* m) { return m->index ? m->icap + 1 : 0; }

static void index_free(AvraMap* m) {
    acc_add(ACC_INDEX, -index_words(m) * (int64_t)sizeof(int64_t));
    if (m->index) free(m->index - 1);
    m->index = NULL;
    m->icap = 0;
}

// Every key filed afresh in `icap` words under the hash `keyed` names. A
// key placed past the tripwire by the fast hash files them all again,
// keyed.
static void map_index_rebuild(AvraMap* m, int64_t icap, int keyed) {
    if (icap >= CELL_CEILING || icap <= 0) avra_trap("a map grew past any possible size — a corrupted box");
    index_free(m);
    int64_t* words = (int64_t*)calloc((size_t)icap + 1, sizeof(int64_t));
    words[0] = (int64_t)((gen_minted() << 1) | (keyed ? 1 : 0));
    m->index = words + 1;
    m->icap = icap;
    acc_add(ACC_INDEX, index_words(m) * (int64_t)sizeof(int64_t));
    mem_ceiling_check();
    uint64_t mask = (uint64_t)icap - 1;
    for (int64_t s = 0; s < m->keys->len; s++) {
        uint64_t h = key_hash(keyed, (const char*)(uintptr_t)m->keys->data[s]);
        uint64_t i = h & mask;
        int64_t walked = 0;
        for (; m->index[i] != 0; i = (i + ++walked) & mask) {}
        if (walked > PROBE_TRIPWIRE && !keyed) { map_index_rebuild(m, icap, 1); return; }
        m->index[i] = index_word(h, s);
    }
}

// A map whose probe passed the tripwire: every key filed again, keyed.
__attribute__((noinline, cold))
static void map_rekeyed(AvraMap* m) {
    map_index_rebuild(m, m->icap, 1);
}

void* avra_map_new(void) {
    AvraMap* m = (AvraMap*)box_alloc(sizeof(AvraMap), KIND_MAP);
    m->keys = (AvraArray*)avra_array_new();
    m->vals = (AvraArray*)avra_array_new();
    m->index = NULL;
    m->icap = 0;
    map_index_rebuild(m, 16, 0);
    return m;
}

// Releases both arrays (their owned slots follow), then the map.
static void map_reclaim(void* p) {
    AvraMap* m = (AvraMap*)p;
    avra_rc_release(m->keys);
    avra_rc_release(m->vals);
    index_free(m);
    box_free(m);
}

// A STATIC map arrives with no index: the backend lays out its keys
// and values and leaves the hash to the runtime, so there is ONE
// hash and not a copy of it in the compiler. Built on the first
// lookup, out of line — a hot lookup pays one predictable compare —
// and SIZED FOR ITS KEYS under the load factor a set keeps: a table
// too small for them has no empty slot and a probe never ends.
__attribute__((noinline, cold))
static void map_index_first(AvraMap* m) {
    int64_t icap = 16;
    while (m->keys->len * 10 >= icap * 7) icap *= 2;
    map_index_rebuild(m, icap, 0);
}

static inline void map_indexed(AvraMap* m) {
    if (__builtin_expect(m->icap == 0, 0)) map_index_first(m);
}

// THE PROBES, COUNTED (AVRA_MAP_STATS=1): every walk of an index, said
// at exit — how a fused read-then-write is held to one.
static int g_map_stats;
static int64_t g_map_probes;

static void map_stats_report(void) {
    avra_say("map: %lld probes\n", (long long)g_map_probes);
}

__attribute__((constructor))
static void map_stats_settled(void) {
#if AVRA_INSTRUMENTS
    g_map_stats = getenv("AVRA_MAP_STATS") != NULL;
#endif
    if (g_map_stats) atexit(map_stats_report);
}

// Where a key's probe ended: its slot or -1, and for a miss the empty
// word it stopped at, the key's hash and how far it walked.
typedef struct { int64_t slot; uint64_t hash; uint64_t at; int64_t walked; } Probe;

__attribute__((always_inline))
static inline Probe map_probe(AvraMap* m, const char* key) {
    map_indexed(m);
    if (__builtin_expect(g_map_stats, 0)) g_map_probes++;
    uint64_t mask = (uint64_t)m->icap - 1;
    uint64_t h = key_hash(map_keyed(m), key);
    uint64_t i = h & mask;
    int64_t walked = 0;
    for (int64_t w; (w = m->index[i]) != 0; i = (i + ++walked) & mask) {
        if (((uint64_t)w ^ h) >> 32) continue;
        int64_t s = (int64_t)((uint64_t)w & 0xffffffffu) - 1;
        if (avra_streq((const char*)(uintptr_t)m->keys->data[s], key)) return (Probe){ s, h, i, walked };
    }
    return (Probe){ -1, h, i, walked };
}

// The slot a key names, or -1.
static inline int64_t map_find(AvraMap* m, const char* key) {
    return map_probe(m, key).slot;
}

// The slot a key names — a NEW key appended in written order and
// filed, the map taking its own reference to it. `*fresh` says which;
// a fresh slot's value is the caller's to push.
static int64_t map_claim(AvraMap* m, const char* key, int* fresh) {
    Probe p = map_probe(m, key);
    *fresh = p.slot < 0;
    if (p.slot >= 0) return p.slot;
    avra_array_push_owned(m->keys, (void*)key);
    int64_t s = m->keys->len - 1;
    if (m->keys->len * 10 >= m->icap * 7) map_index_rebuild(m, m->icap * 2, map_keyed(m));
    else if (__builtin_expect(p.walked > PROBE_TRIPWIRE && !map_keyed(m), 0)) map_rekeyed(m);
    else m->index[p.at] = index_word(p.hash, s);
    return s;
}

// A PROBE AS ONE WORD, so the write that follows a read walks nothing:
// a hit is its slot; a miss is negative — the sign bit, the generation
// of the index it walked, the empty word the walk stopped at. A miss
// past the tripwire, past what the word can hold, or in an index whose
// generation is spent is -1 and says nothing.
enum { TOKEN_AT_BITS = 27 };
static const uint64_t TOKEN_AT_MASK = ((uint64_t)1 << TOKEN_AT_BITS) - 1;

static inline int64_t probe_token(AvraMap* m, Probe p) {
    if (p.slot >= 0) return p.slot;
    uint64_t gen = map_gen(m);
    if (p.walked > PROBE_TRIPWIRE || p.at >> TOKEN_AT_BITS || gen == GEN_SPENT) return -1;
    return (int64_t)(((uint64_t)1 << 63) | (gen << TOKEN_AT_BITS) | p.at);
}

// `map_claim` for a key whose probe a word may still hold. THE WORD IS
// BELIEVED ONLY WHERE THE MAP ITSELF CONFIRMS IT, whatever the caller
// proved: a hit's slot must hold this very key; a miss's empty word
// must be in the index the probe walked — the same generation — and
// still empty, since within one building words only fill, and this
// key's own arrival would have filled that one. Anything else is
// probed afresh.
static int64_t map_claim_at(AvraMap* m, const char* key, int64_t token, int* fresh) {
    if (token >= 0) {
        if (token < m->keys->len) {
            const char* held = (const char*)(uintptr_t)m->keys->data[token];
            if (held == key || avra_streq(held, key)) { *fresh = 0; return token; }
        }
        return map_claim(m, key, fresh);
    }
    uint64_t at = (uint64_t)token & TOKEN_AT_MASK;
    uint64_t gen = ((uint64_t)token >> TOKEN_AT_BITS) & GEN_SPENT;
    if (token == -1 || m->icap == 0 || gen != map_gen(m) || at >= (uint64_t)m->icap || m->index[at] != 0) {
        return map_claim(m, key, fresh);
    }
    *fresh = 1;
    avra_array_push_owned(m->keys, (void*)key);
    int64_t s = m->keys->len - 1;
    if (m->keys->len * 10 >= m->icap * 7) map_index_rebuild(m, m->icap * 2, map_keyed(m));
    else m->index[at] = index_word(key_hash(map_keyed(m), key), s);
    return s;
}

int64_t avra_map_len(void* map) {
    return ((AvraMap*)map)->keys->len;
}

// The map's keys in insertion order, as a fresh list — the map keeps
// its own reference to each, so the copy retains them.
void* avra_map_keys(void* map) {
    return array_clone(((AvraMap*)map)->keys);
}

// The map's values in insertion order, as a fresh list.
void* avra_map_vals(void* map) {
    return array_clone(((AvraMap*)map)->vals);
}

// The slot at `at` dropped: an owned element released, the rest
// moved down, the length one shorter.
static void array_drop(AvraArray* a, int64_t at) {
    if (a->marks[at] & MARK_OWNED) avra_rc_release((void*)(uintptr_t)a->data[at]);
    int64_t n = a->len - at - 1;
    if (n > 0) {
        memmove(a->data + at, a->data + at + 1, (size_t)n * sizeof(int64_t));
        memmove(a->marks + at, a->marks + at + 1, (size_t)n);
    }
    a->len--;
    a->marks[a->len] = 0;
}

// A key removed: its key and value drop, the rest keep their
// insertion order, and the index is rebuilt since every later slot
// moved. A key that is not there removes nothing.
void avra_map_remove(void* map, const char* key) {
    AvraMap* m = (AvraMap*)map;
    int64_t s = map_find(m, key);
    if (s < 0) return;
    array_drop(m->keys, s);
    array_drop(m->vals, s);
    map_index_rebuild(m, m->icap, map_keyed(m));
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

// A key's ONE probe: the slot it names, or a negative word for a key
// that is not there. The reads below take that slot, so `get` hashes
// once whatever it asks after — and a write handed the word back
// (`avra_map_set_at`) walks nothing where the map confirms it.
int64_t avra_map_slot(void* map, const char* key) {
    AvraMap* m = (AvraMap*)map;
    return probe_token(m, map_probe(m, key));
}

// The value in a slot `avra_map_slot` named.
int64_t avra_map_value_at(void* map, int64_t slot) {
    return avra_array_get(((AvraMap*)map)->vals, slot);
}

void* avra_map_value_at_owned(void* map, int64_t slot) {
    void* v = (void*)(uintptr_t)avra_map_value_at(map, slot);
    avra_rc_retain(v);
    return v;
}

// Whether the value in a slot `avra_map_slot` named is there.
int64_t avra_map_present_at(void* map, int64_t slot) {
    return avra_slot_present(((AvraMap*)map)->vals, slot);
}

// A write under a key: an existing slot is overwritten (the old
// owned value released), a new key appends in written order and
// the map takes its own reference to the key. Answers the slot.
static int64_t map_put_at(AvraMap* m, const char* key, int64_t token, int64_t v) {
    int fresh;
    int64_t s = map_claim_at(m, key, token, &fresh);
    if (fresh) avra_array_push(m->vals, v);
    else avra_slot_set(m->vals, s, v);
    return s;
}

static int64_t map_put(AvraMap* m, const char* key, int64_t v) {
    return map_put_at(m, key, -1, v);
}

void avra_map_set(void* map, const char* key, int64_t v) {
    map_put((AvraMap*)map, key, v);
}

// A nullable scalar under a key: its word, its absence in the value
// cell's mark — the slots' own law, one table over.
void avra_map_set_maybe(void* map, const char* key, int64_t present, int64_t v) {
    AvraMap* m = (AvraMap*)map;
    m->vals->marks[map_put(m, key, present ? v : 0)] = present ? 0 : MARK_ABSENT;
}

// Whether the value under a key is there — 0 for a key that is not.
int64_t avra_map_value_present(void* map, const char* key) {
    AvraMap* m = (AvraMap*)map;
    int64_t s = map_find(m, key);
    return s >= 0 && !(m->vals->marks[s] & MARK_ABSENT);
}

void avra_map_set_owned(void* map, const char* key, void* v) {
    AvraMap* m = (AvraMap*)map;
    int fresh;
    int64_t s = map_claim(m, key, &fresh);
    if (fresh) avra_array_push_owned(m->vals, v);
    else avra_slot_set_owned(m->vals, s, v);
}

void avra_map_set_maybe_owned(void* map, const char* key, int64_t present, void* v) {
    if (present) avra_map_set_owned(map, key, v);
    else avra_map_set_maybe(map, key, 0, 0);
}

// THE SET FAMILY UNDER A TOKEN: the write `avra_map_slot`'s word
// already found the place for. Each is its twin above, less the probe.
void avra_map_set_at(void* map, const char* key, int64_t token, int64_t v) {
    map_put_at((AvraMap*)map, key, token, v);
}

void avra_map_set_at_maybe(void* map, const char* key, int64_t token, int64_t present, int64_t v) {
    AvraMap* m = (AvraMap*)map;
    m->vals->marks[map_put_at(m, key, token, present ? v : 0)] = present ? 0 : MARK_ABSENT;
}

void avra_map_set_at_owned(void* map, const char* key, int64_t token, void* v) {
    AvraMap* m = (AvraMap*)map;
    int fresh;
    int64_t s = map_claim_at(m, key, token, &fresh);
    if (fresh) avra_array_push_owned(m->vals, v);
    else avra_slot_set_owned(m->vals, s, v);
}

void avra_map_set_at_maybe_owned(void* map, const char* key, int64_t token, int64_t present, void* v) {
    if (present) avra_map_set_at_owned(map, key, token, v);
    else avra_map_set_at_maybe(map, key, token, 0, 0);
}

// The index walks so far, counted from the first ask — for the
// runtime's own tests.
int64_t avra_map_probes(void) {
    g_map_stats = 1;
    return g_map_probes;
}

// THE INDEX, MEASURED — for the runtime's own tests, never a hot path:
// the longest walk any present key takes from its home, whether the map
// fell back to its keyed hash, and the fast hash a fresh map files text by.
int64_t avra_map_worst_probe(void* map) {
    AvraMap* m = (AvraMap*)map;
    map_indexed(m);
    uint64_t mask = (uint64_t)m->icap - 1;
    int64_t worst = 0;
    for (int64_t s = 0; s < m->keys->len; s++) {
        uint64_t i = key_hash(map_keyed(m), (const char*)(uintptr_t)m->keys->data[s]) & mask;
        int64_t walked = 0;
        for (; ((uint64_t)m->index[i] & 0xffffffffu) != (uint64_t)(s + 1); i = (i + ++walked) & mask) {}
        if (walked > worst) worst = walked;
    }
    return worst;
}

int64_t avra_map_keyed(void* map) {
    AvraMap* m = (AvraMap*)map;
    map_indexed(m);
    return map_keyed(m);
}

uint64_t avra_text_hash(const char* s) { return fast_hash(s, str_len(s)); }

// SipHash-1-3 under a given key, for the runtime's own tests to hold to
// a reference vector.
uint64_t avra_sip_hash_keyed(uint64_t k0, uint64_t k1, const char* s, int64_t n) {
    return sip_hash(k0, k1, s, (size_t)n);
}

// A map's shallow clone: both arrays cloned (their owned slots
// retained), the index rebuilt under the same keying. A fresh box, rc 1.
static void* map_clone(AvraMap* m) {
    map_indexed(m);
    AvraMap* c = (AvraMap*)box_alloc(sizeof(AvraMap), KIND_MAP);
    c->keys = (AvraArray*)array_clone(m->keys);
    c->vals = (AvraArray*)array_clone(m->vals);
    c->index = NULL;
    c->icap = 0;
    map_index_rebuild(c, m->icap, map_keyed(m));
    return c;
}

// The clone a place opens — by the box's kind.
static void* box_clone(void* p) {
    CENSUS(note_copy(AVRA_CALLER()));
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
    if (a->marks[a->len] & MARK_OWNED) avra_trap("a managed slot popped as a scalar");
    return a->data[a->len];
}

void* avra_array_pop_owned(void* arr) {
    AvraArray* a = (AvraArray*)arr;
    if (a->len == 0) avra_trap("pop on an empty list");
    a->len--;
    void* v = (void*)(uintptr_t)a->data[a->len];
    if (a->marks[a->len] & MARK_OWNED) {
        a->marks[a->len] = 0;
    } else {
        avra_rc_retain(v);
    }
    return v;
}

// `src`'s slots from lo up to hi appended to `out`, owned ones
// retained — a copy holds its own references.
static void array_append(void* out, AvraArray* src, int64_t lo, int64_t hi) {
    for (int64_t i = lo; i < hi; i++) {
        if (src->marks[i] & MARK_OWNED) {
            avra_array_push_owned(out, (void*)(uintptr_t)src->data[i]);
        } else {
            avra_array_push(out, src->data[i]);
            ((AvraArray*)out)->marks[((AvraArray*)out)->len - 1] = src->marks[i];
        }
    }
}

// A fresh list: `a`'s slots, then `b`'s. Owned.
void* avra_array_concat(void* a, void* b) {
    CENSUS(note_copy(AVRA_CALLER()));
    void* site = g_clone_site ? g_clone_site : AVRA_CALLER();
    g_clone_site = site;
    void* out = avra_array_new();
    g_clone_site = NULL;
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
    void* out = array_made(lo < hi ? hi - lo : 0, g_clone_site ? g_clone_site : AVRA_CALLER());
    if (lo < hi) array_append(out, a, lo, hi);
    return out;
}

// A list box the handed reference holds alone — never an immortal one.
static inline int sole_array(void* p) {
    Header* h = hdr(p);
    return h && h->kind == KIND_ARRAY && h->rc == 1;
}

// `arr` cut to the slots from lo up to hi, in place when it is held
// alone: the slots cut away released, the kept ones moved down.
void* avra_array_slice_reusing(void* arr, int64_t lo, int64_t hi) {
    if (!sole_array(arr)) {
        g_clone_site = AVRA_CALLER();
        void* out = avra_array_slice(arr, lo, hi);
        g_clone_site = NULL;
        avra_rc_release(arr);
        return out;
    }
    AvraArray* a = (AvraArray*)arr;
    if (lo < 0) lo = 0;
    if (hi > a->len) hi = a->len;
    if (hi < lo) hi = lo;
    for (int64_t i = 0; i < a->len; i++) {
        if ((i < lo || i >= hi) && (a->marks[i] & MARK_OWNED)) avra_rc_release((void*)(uintptr_t)a->data[i]);
    }
    int64_t n = hi - lo;
    if (lo > 0) {
        memmove(a->data, a->data + lo, (size_t)n * sizeof(int64_t));
        memmove(a->marks, a->marks + lo, (size_t)n);
    }
    memset(a->marks + n, 0, (size_t)(a->len - n));
    a->len = n;
    return arr;
}

// `a`'s slots then `b`'s, onto `a` when it is held alone.
void* avra_array_concat_reusing(void* a, void* b) {
    if (a == b || !sole_array(a)) {
        g_clone_site = AVRA_CALLER();
        void* out = avra_array_concat(a, b);
        g_clone_site = NULL;
        avra_rc_release(a);
        return out;
    }
    AvraArray* src = (AvraArray*)b;
    avra_array_reserve(a, src->len);
    array_append(a, src, 0, src->len);
    return a;
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
   so the shortest faithful DIGITS are found by trying. They are then
   laid out positionally for a decimal exponent in [-6, 21) — `100.0`,
   never `1e+02` — and as `d.ddde±x` outside it, the range JavaScript
   and JSON writers share. A `.0` is kept on an integral positional
   value, because a float that prints as `3` is a float wearing an
   int's clothes. Infinity and NaN keep `%g`'s words. */
static const char* float_text(double d) {
    char sci[40];
    char out[64];
    if (!isfinite(d)) {
        snprintf(out, sizeof out, "%g", d);
        return str_owned(out, strlen(out));
    }
    for (int prec = 1; prec <= 17; prec++) {
        snprintf(sci, sizeof sci, "%.*e", prec - 1, d);
        if (strtod(sci, NULL) == d) break;
    }
    char digits[20] = {0};
    size_t n = 0;
    const char* c = sci;
    int negative = *c == '-';
    if (negative) c++;
    for (; *c && *c != 'e'; c++) {
        if (*c != '.') digits[n++] = *c;
    }
    int e10 = atoi(c + 1);
    size_t o = 0;
    if (negative) out[o++] = '-';
    if (e10 >= -6 && e10 < 21) {
        if (e10 < 0) {
            out[o++] = '0';
            out[o++] = '.';
            for (int z = 0; z < -e10 - 1; z++) out[o++] = '0';
            memcpy(out + o, digits, n);
            o += n;
        } else {
            size_t whole = (size_t)e10 + 1;
            for (size_t k = 0; k < whole; k++) out[o++] = k < n ? digits[k] : '0';
            out[o++] = '.';
            if (n > whole) {
                memcpy(out + o, digits + whole, n - whole);
                o += n - whole;
            } else {
                out[o++] = '0';
            }
        }
    } else {
        out[o++] = digits[0];
        if (n > 1) {
            out[o++] = '.';
            memcpy(out + o, digits + 1, n - 1);
            o += n - 1;
        }
        o += (size_t)snprintf(out + o, sizeof out - o, "e%c%d", e10 < 0 ? '-' : '+', e10 < 0 ? -e10 : e10);
    }
    return str_owned(out, o);
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

/* THE ONE DOOR A FOREIGN BUFFER ENTERS BY, and the only place the
   runtime dereferences a pointer the PROGRAM supplied rather than one
   it allocated or the compiler emitted. A caller hands an address and
   a LENGTH — the length is the whole contract, because a foreign
   buffer has no header to ask and no terminator anyone may trust.

   THE EMPTY CASE IS THE FIRST CASE. C spends the null pointer on
   "nothing to point at"; Avra spends it on "no value". A door that
   answered nothing for an empty buffer would spend that value twice,
   and an empty blob would arrive indistinguishable from SQL NULL. So
   (NULL, 0) is the EMPTY BOX, and only the caller's own absence is
   absence.

   A NULL WITH A LENGTH IS A CALLER CONTRADICTING ITSELF, and so is a
   negative one. Both trap here rather than being read: this door
   cannot tell a wrong length from a right one by looking, so the only
   lengths it refuses are the ones that cannot be true. */
const char* avra_bytes_adopted(const void* p, int64_t n) {
    if (n < 0) avra_trap("a foreign buffer is shorter than nothing");
    if (p == NULL) {
        if (n > 0) avra_trap("a foreign buffer claims octets and no address");
        return bytes_box(0);
    }
    return bytes_owned(p, (size_t)n);
}

// AN EMPTY BUFFER WITH ROOM: its block sized for `n` octets and its
// length zero, so appends fill the block in place until the room is
// spent — `sized_moved` asks the block before it moves anything.
const char* avra_bytes_with_room(int64_t n) {
    if (n < 0) avra_trap("a buffer's room is less than nothing");
    char* b = bytes_box((size_t)n);
    sized_resized((Header*)b - 1, 0);
    return b;
}

int64_t avra_bytes_len(const char* b) { return (int64_t)bytes_len(b); }

// Equality is the reason the kind exists: lengths, then every byte.
int64_t avra_bytes_eq(const char* a, const char* b) {
    if (a == b) return 1;
    size_t n = bytes_len(a);
    return n == bytes_len(b) && memcmp(a, b, n) == 0;
}

// One octet, 0..255. A bad index traps: -1 is not a byte.
int64_t avra_bytes_at(const char* b, int64_t i) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(i < 0 || i >= n, 0)) avra_trap_bounds(i, n);
    return (unsigned char)b[i];
}

// The octets from lo up to hi, owned. Bounds are a precondition: a
// slice traps and never clamps, because a short answer parses.
// A WHOLE slice is the value itself: octets never change, so sharing
// the box answers the same bytes a copy would.
const char* avra_bytes_slice(const char* b, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    if (lo == 0 && hi == n) return shared(b);
    return bytes_owned(b + lo, (size_t)(hi - lo));
}

// An EMPTY side answers the other, shared.
const char* avra_bytes_concat(const char* a, const char* b) {
    size_t n = bytes_len(a), m = bytes_len(b);
    if (m == 0) return shared(a);
    if (n == 0) return shared(b);
    char* out = bytes_box(n + m);
    memcpy(out, a, n);
    memcpy(out + n, b, m);
    return out;
}

const char* avra_bytes_concat_reusing(const char* a, const char* b) {
    size_t m = bytes_len(b);
    if (m == 0) return a;
    if (a == b || !sole_sized(a)) {
        const char* out = avra_bytes_concat(a, b);
        avra_rc_release((void*)a);
        return out;
    }
    return appended(a, b, m);
}

const char* avra_bytes_slice_reusing(const char* b, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    if (!sole_sized(b)) {
        const char* out = avra_bytes_slice(b, lo, hi);
        avra_rc_release((void*)b);
        return out;
    }
    if (lo > 0) memmove((char*)b, b + lo, (size_t)(hi - lo));
    sized_resized((Header*)b - 1, (size_t)(hi - lo));
    return b;
}

// Where `needle` first lies wholly inside lo..hi, or -1; an empty
// needle is found at lo. The search reads no octet at or past hi.
static inline int64_t index_within(const char* b, const char* needle, int64_t lo, int64_t hi) {
    int64_t m = (int64_t)bytes_len(needle);
    if (m == 0) return lo;
    if (m > hi - lo) return -1;
    const char* end = b + hi - m + 1;
    for (const char* p = b + lo; (p = (const char*)memchr(p, needle[0], (size_t)(end - p))) != NULL; p++)
        if (memcmp(p, needle, (size_t)m) == 0) return (int64_t)(p - b);
    return -1;
}

// Where `needle` first begins at or after `from`, or -1. `from` may
// equal the length, and an empty needle is found there.
int64_t avra_bytes_index_of(const char* b, const char* needle, int64_t from) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(from < 0 || from > n, 0)) avra_trap_bounds(from, n);
    return index_within(b, needle, from, n);
}

// `index_of` over lo..hi alone: a needle crossing hi is not found.
int64_t avra_bytes_index_in(const char* b, const char* needle, int64_t lo, int64_t hi) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(lo < 0 || hi < lo || hi > n, 0)) trap_slice(lo, hi, n);
    return index_within(b, needle, lo, hi);
}

// Text to octets: total, and FREE — text and octets are one layout
// (length in the header, a spare NUL after), so the answer is the
// same box. A pointer that is not a box is copied in.
const char* avra_bytes_of_str(const char* s) {
    return hdr((void*)s) ? shared(s) : bytes_owned(s, strlen(s));
}

const char* avra_bytes_of_str_reusing(const char* s) {
    if (hdr((void*)s)) return s;
    return bytes_owned(s, strlen(s));
}

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
// The same box when they are: one layout, as above.
const char* avra_str_of_bytes(const char* b) {
    return utf8_bad_at(b, bytes_len(b)) < 0 ? shared(b) : NULL;
}

const char* avra_str_of_bytes_reusing(const char* b) {
    if (utf8_bad_at(b, bytes_len(b)) < 0) return b;
    avra_rc_release((void*)b);
    return NULL;
}

int64_t avra_utf8_bad_at(const char* b) { return utf8_bad_at(b, bytes_len(b)); }

// The longest prefix that is whole UTF-8, as text: every octet when
// they all are (the same box), the empty text when the first is not.
// Never null — what follows the prefix is the caller's to slice.
const char* avra_str_of_bytes_prefix(const char* b) {
    int64_t bad = utf8_bad_at(b, bytes_len(b));
    return bad < 0 ? shared(b) : str_owned(b, (size_t)bad);
}

// How many octets at `b` (the place `utf8_bad_at` named) one U+FFFD
// stands for: the lead and every continuation that could still follow
// it — the maximal subpart — and a byte that leads nothing alone.
static size_t utf8_ill_formed(const unsigned char* b, size_t n) {
    unsigned char c = b[0], lo = 0x80, hi = 0xBF;
    size_t need;
    if (c >= 0xC2 && c <= 0xDF)                               need = 1;
    else if (c == 0xE0)                                       { need = 2; lo = 0xA0; }
    else if ((c >= 0xE1 && c <= 0xEC) || c == 0xEE || c == 0xEF) need = 2;
    else if (c == 0xED)                                       { need = 2; hi = 0x9F; }
    else if (c == 0xF0)                                       { need = 3; lo = 0x90; }
    else if (c >= 0xF1 && c <= 0xF3)                          need = 3;
    else if (c == 0xF4)                                       { need = 3; hi = 0x8F; }
    else return 1;
    if (n < 2 || b[1] < lo || b[1] > hi) return 1;
    size_t k = 2;
    while (k <= need && k < n && b[k] >= 0x80 && b[k] <= 0xBF) k++;
    return k;
}

// One pass over the octets as LOSSY text: each whole run is handed to
// `out` (when there is one) and each ill-formed subpart counts three
// octets, U+FFFD's. The size it answers is the text's.
static size_t utf8_lossy(const char* b, size_t n, char* out) {
    size_t i = 0, w = 0;
    while (i < n) {
        int64_t bad = utf8_bad_at(b + i, n - i);
        size_t run = bad < 0 ? n - i : (size_t)bad;
        if (out) memcpy(out + w, b + i, run);
        w += run;
        i += run;
        if (bad < 0) break;
        if (out) memcpy(out + w, "\xEF\xBF\xBD", 3);
        w += 3;
        i += utf8_ill_formed((const unsigned char*)b + i, n - i);
    }
    return w;
}

// The octets as text whatever they hold: each ill-formed subpart reads
// as one U+FFFD. Whole UTF-8 is the same box.
const char* avra_str_of_bytes_lossy(const char* b) {
    size_t n = bytes_len(b);
    if (utf8_bad_at(b, n) < 0) return shared(b);
    size_t size = utf8_lossy(b, n, NULL);
    char* out = sized_box(size, KIND_STR);
    utf8_lossy(b, n, out);
    out[size] = '\0';
    return out;
}

__attribute__((noinline, cold, noreturn))
static void trap_table(int64_t len) {
    char msg[80];
    avra_fmt(msg, sizeof msg, "a class table holds 256 bytes (length %lld)", (long long)len);
    avra_trap(msg);
    abort();
}

// The end of the run of bytes at or after `from` that `table` admits —
// a 256-byte table whose non-zero entry says "in the class". The
// caller asks where a token ENDS, never what each byte is: one scan
// in C is what makes a byte-at-a-time parser fast.
int64_t avra_bytes_run(const char* b, int64_t from, const char* table) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(from < 0 || from > n, 0)) avra_trap_bounds(from, n);
    if (__builtin_expect(bytes_len(table) != 256, 0)) trap_table((int64_t)bytes_len(table));
    const unsigned char* t = (const unsigned char*)table;
    const unsigned char* p = (const unsigned char*)b;
    int64_t i = from;
    while (i < n && t[p[i]]) i++;
    return i;
}

// Where the run of octets `table` admits ends, walking BACK from `from`:
// the least i with every byte of i..from admitted — `from` itself when
// the byte before it is refused. `avra_bytes_run`'s mirror, for a tail
// (trailing whitespace) read without a counter loop.
int64_t avra_bytes_run_back(const char* b, int64_t from, const char* table) {
    int64_t n = (int64_t)bytes_len(b);
    if (__builtin_expect(from < 0 || from > n, 0)) avra_trap_bounds(from, n);
    if (__builtin_expect(bytes_len(table) != 256, 0)) trap_table((int64_t)bytes_len(table));
    const unsigned char* t = (const unsigned char*)table;
    const unsigned char* p = (const unsigned char*)b;
    int64_t i = from;
    while (i > 0 && t[p[i - 1]]) i--;
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

// ── Memory-mapped files ──────────────────────────────────────────
// A READ-ONLY VIEW OF A FILE, HANDED TO AVRA AS AN UNMANAGED HANDLE —
// a small malloc'd record (base address, byte length), answered as a
// raw `ptr` rather than one of our headered boxes, because nothing
// here is reference-counted: `avra_rc_release` must never touch it.
// Closing it is the caller's own act, as closing any other native
// handle is.
//
// THE EMPTY CASE IS THE FIRST CASE: a zero-byte file maps to a valid
// handle whose length is zero (`mmap` itself refuses a zero-length
// request, so that call is skipped for it) — only a missing,
// unreadable or non-regular path answers ABSENT, as the null pointer.
// A path carrying a NUL is neither: `open` would resolve a PREFIX of
// it and touch a different file than the one named, so it is REFUSED
// (the two-hats law), checked by comparing the header's length
// against `strlen` — the same fact `avra_str_crossing` reads, a scan
// skipped for a pointer with no header, which by definition has no
// interior NUL to find.
//
// A read never answers a pointer INTO the mapping: `avra_mmap_slice`
// copies its range into an owned, headered Bytes box, and
// `avra_mmap_word_at` reads eight bytes as one big-endian word —
// `avra_str_word_at`'s reader, over a mapping's own bytes instead of
// a text header. Bounds are the mapping's own recorded length, never
// the mapped file's CURRENT size, so a file that changes size after
// opening cannot move where this trap fires.

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

typedef struct {
    const char* base;  // NULL only when len == 0
    int64_t len;
} AvraMmap;

static AvraMmap* mmap_handle(void* h) {
    if (h == NULL) avra_trap("a memory-mapped file's handle is null");
    return (AvraMmap*)h;
}

// A read-only mapping of `path`, or null for a missing, unreadable or
// non-regular file (a directory included — it is not a file this
// door can map). Absent is the null pointer; nothing else answers it.
void* avra_mmap_open(const char* path) {
    Header* ph = hdr((void*)path);
    if (ph != NULL && strlen(path) != (size_t)ph->len) avra_trap("a mapped path holds an embedded NUL");
    int fd = open(path, O_RDONLY);
    if (fd < 0) return NULL;
    struct stat st;
    if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode)) { close(fd); return NULL; }
    const char* base = NULL;
    if (st.st_size > 0) {
        void* m = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (m == MAP_FAILED) { close(fd); return NULL; }
        base = (const char*)m;
    }
    close(fd);  // the mapping outlives the descriptor that made it
    AvraMmap* out = (AvraMmap*)malloc(sizeof(AvraMmap));
    if (out == NULL) avra_trap("out of memory mapping a file");
    out->base = base;
    out->len = (int64_t)st.st_size;
    return out;
}

// The mapping's byte length.
int64_t avra_mmap_len(void* h) {
    return mmap_handle(h)->len;
}

// The bytes from lo up to hi, copied into an owned Bytes box —
// `avra_bytes_slice`'s bound and its trap, over a mapping instead of
// an already-boxed value.
const char* avra_mmap_slice(void* h, int64_t lo, int64_t hi) {
    AvraMmap* m = mmap_handle(h);
    if (__builtin_expect(lo < 0 || hi < lo || hi > m->len, 0)) trap_slice(lo, hi, m->len);
    if (hi == lo) return bytes_box(0);
    return bytes_owned(m->base + lo, (size_t)(hi - lo));
}

// Eight bytes at `i`, as one big-endian word.
int64_t avra_mmap_word_at(void* h, int64_t i) {
    AvraMmap* m = mmap_handle(h);
    if (i < 0 || i + 8 > m->len) avra_trap_bounds(i < 0 ? i : m->len, m->len);
    uint64_t w = 0;
    for (int j = 0; j < 8; j++) w = (w << 8) | (unsigned char)m->base[i + j];
    return (int64_t)w;
}

// Unmaps and frees the handle. Using `h`, or closing it, again after
// this call is the caller's own defect — the same contract any other
// native handle carries.
void avra_mmap_close(void* h) {
    AvraMmap* m = mmap_handle(h);
    if (m->base != NULL) munmap((void*)m->base, (size_t)m->len);
    free(m);
}

// Whether a process by this id is running, by asking the process table
// (signal 0 sends nothing) rather than trusting a cached liveness the
// process itself could never update. A permission-denied answer (a pid
// reused by another user) still means something stands there.
#include <signal.h>
#if defined(__wasm32__)
int64_t avra_pid_alive(int64_t pid) { return 0; }
#else
int64_t avra_pid_alive(int64_t pid) {
    if (kill((pid_t)pid, 0) == 0) return 1;
    return errno == EPERM ? 1 : 0;
}
#endif

// This process's own id, OS-assigned at birth.
int64_t avra_own_pid(void) {
    return (int64_t)getpid();
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
        avra_fmt(msg, sizeof msg, "a take at EOF — `read` answered 0, which names no bytes");
    else if (token < 0)
        avra_fmt(msg, sizeof msg, "a take of an error — `read` answered %lld, not a token", (long long)token);
    else
        avra_fmt(msg, sizeof msg, "a take of read %lld, but read %lld has landed since", (long long)token, (long long)g_fd_gen);
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

// Up to `max` bytes (capped at 1 MiB) into the scratch: the token of
// what landed, 0 at EOF, -EAGAIN when nothing is ready, -errno
// otherwise.
//
// THE EMPTY CASE IS THE FIRST CASE. `max` is the caller's arithmetic
// — `read(want - have)` reaches zero the turn a frame is complete —
// and this answer encoding already spends 0 on EOF, so a zero-length
// landing has no code of its own. Clamping the ASK to one instead
// bought a byte off the wire that nobody requested: the next message's
// first byte, taken and never reported as taken. A zero ask lands zero
// bytes and presents its token like any other, so the empty answer is
// an empty box and 0 still means EOF alone. A NEGATIVE ask is a bound,
// not a question, and answers -EINVAL rather than reading anything.
void (*avra_fd_drained_hook)(int64_t fd) = NULL;

// ── What a task carries ─────────────────────────────────────────

AvraTaskLocal avra_main_local;
AvraTaskLocal* avra_task_local = &avra_main_local;
_Static_assert(AVRA_SLOT_ASKER < AVRA_TASK_SLOTS && AVRA_SLOT_FLOW < AVRA_TASK_SLOTS, "a slot key outside the table");

__attribute__((noinline, cold, noreturn))
static void slot_refused(void) { avra_trap("a task has four slots, and this is none of them"); }

__attribute__((noinline))
static void* slot_retained(void* v) {
    avra_rc_retain(v);
    return v;
}

// An empty slot answers from a load and a test.
void* avra_task_slot(int64_t key) {
    if (__builtin_expect((uint64_t)key >= AVRA_TASK_SLOTS, 0)) slot_refused();
    void* v = avra_task_local->slot[key];
    if (!v) return NULL;
    return slot_retained(v);
}

void avra_task_slot_set(int64_t key, void* v) {
    if (__builtin_expect((uint64_t)key >= AVRA_TASK_SLOTS, 0)) slot_refused();
    void* old = avra_task_local->slot[key];
    avra_rc_retain(v);
    avra_task_local->slot[key] = v;
    avra_rc_release(old);
}

int64_t avra_task_id(void) { return avra_task_local->id; }

int64_t avra_fd_read(int64_t fd, int64_t max) {
    if (__builtin_expect(max < 0, 0)) return -EINVAL;
    if (max == 0) return fd_landed(0);
    size_t n = max > FD_SCRATCH ? FD_SCRATCH : (size_t)max;
    for (;;) {
        ssize_t got = read((int)fd, g_fd_buf, n);
        if (got > 0) {
            if ((size_t)got < n && avra_fd_drained_hook) avra_fd_drained_hook(fd);
            return fd_landed(got);
        }
        if (got == 0) return 0;
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            if (avra_fd_drained_hook) avra_fd_drained_hook(fd);
            return -EAGAIN;
        }
        if (errno != EINTR) return -errno;
    }
}

// The errno a nonblocking descriptor answers when it has nothing to
// give or take — the platform's, asked rather than assumed.
int64_t avra_errno_again(void) { return EAGAIN; }

// The errno for an argument that names nothing — the platform's word.
int64_t avra_errno_invalid(void) { return EINVAL; }

// The errno for a wait whose budget ran out — the platform's word.
int64_t avra_errno_timed_out(void) { return ETIMEDOUT; }

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
    if (__builtin_expect(from < 0 || from > n, 0)) avra_trap_bounds(from, n);
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
    a->marks[a->len - 1] = MARK_OWNED;
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

// AT EQUAL LENGTH A PREFIX IS EQUALITY, so this and `avra_streq` are
// answering the same question and may never disagree. `strncmp` made
// them disagree: it stops at a NUL in either side, so two five-byte
// texts that differ only past one read as a prefix while `==` reads
// them as unequal, and a prefix LONGER than the text read as a prefix
// too. The walk is the length's, as its sibling below already had it.
int64_t avra_str_starts_with(const char* s, const char* prefix) {
    size_t m = str_len(prefix);
    return m <= str_len(s) && memcmp(s, prefix, m) == 0;
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
    if (__builtin_expect(i < 0 || i >= n, 0)) avra_trap_bounds(i, n);
    return (unsigned char)s[i];
}

// EIGHT BYTES AS ONE BIG-ENDIAN WORD — the eight `avra_str_char_code` calls a
// digest word costs, made one. It reads the SAME bytes through the SAME header,
// so a fold that gathers its words here answers the same digest it always did.
//
// THE PROPER FIX IS NOT A FASTER ROW: it is a text byte window the COMPILER
// lowers inline, so no call is needed per byte at all — the backend already
// mirrors `avra_box.h` and static-asserts that the two agree, so it built the box
// and should look inside one. This row is the interim that removes seven calls in
// eight; the lexer still pays one per byte. See the roadmap.
//
// The bound mirrors the byte reader it replaces: the Avra loop this stands in for
// traps at the FIRST index out of range, so a caller that ran off the end hears
// the same words about the same index.
int64_t avra_str_word_at(const char* s, int64_t i) {
    int64_t n = (int64_t)str_len(s);
    if (i < 0 || i + 8 > n) {
        int64_t bad = i < 0 ? i : n;
        char msg[80];
        avra_fmt(msg, sizeof msg, "index %lld is out of bounds (length %lld)",
               (long long)bad, (long long)n);
        avra_trap(msg);
    }
    uint64_t w = 0;
    for (int j = 0; j < 8; j++) w = (w << 8) | (unsigned char)s[i + j];
    return (int64_t)w;
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

// `a + b` on text — one fresh string, or an empty side's other
// side, shared. Owned.
const char* avra_str_concat(const char* a, const char* b) {
    size_t n = str_len(a);
    size_t m = str_len(b);
    if (m == 0 && hdr((void*)a)) return shared(a);
    if (n == 0 && hdr((void*)b)) return shared(b);
    char* buf = sized_box(n + m, KIND_STR);
    memcpy(buf, a, n);
    memcpy(buf + n, b, m + 1);
    return buf;
}

const char* avra_str_concat_reusing(const char* a, const char* b) {
    size_t m = str_len(b);
    if (m == 0 && hdr((void*)a)) return a;
    if (a == b || !sole_sized(a)) {
        const char* out = avra_str_concat(a, b);
        avra_rc_release((void*)a);
        return out;
    }
    return appended(a, b, m);
}

// ── The host: what a program declares `extern` and the CLI leans on ──
// Each answers as the CLI reads it: files as text ("" when unreadable),
// verdicts and statuses as words, listings as newline-joined names.

#include <sys/stat.h>
#if !defined(__wasm32__)
#include <sys/wait.h>
#include <spawn.h>
#endif
#include <poll.h>
#include <signal.h>
#include <fcntl.h>

#if !defined(__wasm32__)
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
#endif
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

// ── The clock ───────────────────────────────────────────────────
//
// One clock for the process. FLOWING it is the monotonic clock plus a
// skew; FROZEN it is one reading that only a jump moves. A virtual
// clock is frozen unless the world is held, and each change of state
// keeps the present reading — so it never goes back.
typedef struct {
    int64_t skew;       // flowing: what is added to the monotonic clock
    int64_t at;         // frozen: the reading
    int32_t virtual;
    int32_t frozen;     // virtual and not held
    int32_t held;
    int64_t asked;      // reads since the clock last moved, while frozen
} Clock;

static Clock g_clock;
static int64_t g_clock_jumps = 0;

static int64_t clock_real(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}

// The state follows `virtual` and `held`, the reading kept across it.
static void clock_settled(void) {
    int frozen = g_clock.virtual && g_clock.held <= 0;
    if (frozen == g_clock.frozen) return;
    if (frozen) g_clock.at = clock_real() + g_clock.skew;
    else g_clock.skew = g_clock.at - clock_real();
    g_clock.frozen = frozen;
    g_clock.asked = 0;
}

// A FROZEN CLOCK MOVES ONLY WHEN EVERY TASK WAITS, so a task that reads
// it again and again without waiting is waiting on something that
// cannot come: it yields, or computes, until a time that never arrives.
// That is a hang, and a hang is spoken.
enum { CLOCK_ASKED_MOST = 1 << 24 };

__attribute__((noinline, cold, noreturn))
static void clock_never_comes(void) {
    char words[160];
    avra_fmt(words, sizeof words, "a task is waiting on the clock without sleeping — the clock is virtual and moves only when every task waits (task %lld)", (long long)avra_task_local->id);
    avra_trap(words);
    abort();
}

__attribute__((noinline, cold))
static int64_t clock_asked(void) {
    if (++g_clock.asked > CLOCK_ASKED_MOST) clock_never_comes();
    return g_clock.at;
}

int64_t avra_now_ns(void) {
    if (__builtin_expect(g_clock.frozen, 0)) return clock_asked();
    return clock_real() + g_clock.skew;
}

int64_t avra_clock_read(void) {
    if (__builtin_expect(g_clock.frozen, 0)) return g_clock.at;
    return clock_real() + g_clock.skew;
}

void avra_clock_virtual(int64_t on) {
    g_clock.virtual = on != 0;
    clock_settled();
}

int64_t avra_clock_jumped(int64_t at) {
    if (!g_clock.frozen) return 0;
    if (at > g_clock.at) g_clock.at = at;
    g_clock.asked = 0;
    g_clock_jumps++;
    return 1;
}

void avra_clock_hold(int64_t by) {
    g_clock.held += (int32_t)by;
    clock_settled();
}

int64_t avra_clock_holds_dropped(void) {
    int64_t held = g_clock.held;
    g_clock.held = 0;
    clock_settled();
    return held;
}

// A run inside a run keeps the outer clock whole, to put it back.
enum { CLOCK_RUNS_MOST = 16 };
static Clock g_clock_outer[CLOCK_RUNS_MOST];
static int g_clock_runs = 0;

void avra_clock_run_begins(void) {
    if (g_clock_runs == CLOCK_RUNS_MOST) avra_trap("runs under a virtual clock are nested too deep");
    g_clock_outer[g_clock_runs++] = g_clock;
    g_clock.held = 0;
    g_clock.virtual = 1;
    clock_settled();
}

void avra_clock_run_ends(void) {
    if (g_clock_runs == 0) avra_trap("defect: a run's clock ended that never began");
    g_clock = g_clock_outer[--g_clock_runs];
    g_clock.asked = 0;
}

int64_t avra_clock_jumps(void) { return g_clock_jumps; }

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
    if (got == (size_t)size) return buf;
    // the file shrank between its size and its read: the box is made
    // again at the length it holds, never relabelled
    const char* exact = str_owned(buf, got);
    box_free(buf);
    return exact;
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
    avra_fmt(tmp + n, 32, ".tmpav%lld", (long long)getpid());
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

// A line to stderr keeps the program's order against stdout's buffer.
void avra_eputs(const char* s) {
    fflush(stdout);
    if (s) fwrite(s, 1, str_len(s), stderr);
    fputc('\n', stderr);
    fflush(stderr);
}

// A DEBUG LINE, only under AVRA_DEBUG — the compiler's own instrument.
// A no-op otherwise, so a probe can stand in any pass without breaking
// the self-compile, whose environment has no such flag.
void avra_debug(const char* s) {
    if (s && getenv("AVRA_DEBUG")) fputs(s, stderr);
}

// A QUERY-KERNEL TRACE LINE, only under AVRA_QTRACE — its own flag,
// separate from AVRA_DEBUG, for a gen-N vs gen-N+1 differential
// (CLAUDE.md, Working discipline). A no-op otherwise.
void avra_qtrace(const char* s) {
    if (s && getenv("AVRA_QTRACE")) fputs(s, stderr);
}

/* `embed` is answered by the compiler, at compile time, under the
   const's own directory; a program that reaches this body called it
   outside a const. */
const char* avra_embed(const char* path) {
    (void)path;
    avra_trap("`embed` reads a file at compile time, into a const — this program reached it at run time");
    return "";
}

/* `type_named` is answered by the compiler's own declaration table,
   which a running program does not carry; the interpreter's arm
   never calls this body at all. */
void* avra_type_named(const char* name) {
    (void)name;
    avra_trap("`type_named` resolves a declaration at compile time — this program reached it at run time");
    return NULL;
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

#if defined(__wasm32__)

// A WebAssembly module has no processes: spawning, replacing the
// image and capturing a child are refused the way a refused cwd is,
// rather than linked.
int64_t avra_spawn_status(const char* prog, void* args) { return 127; }
int64_t avra_spawn_in(const char* dir, const char* prog, void* args) { return 127; }
const char* avra_self_dir(void) { return str_static(""); }
int64_t avra_exec_self(void* args) { return 127; }

#else

// THE SEED'S SHIM: the seed that predates @std/process links this;
// nothing in Avra declares it. Deleted once a refreshed seed has
// landed (ROADMAP, lane B slice C).
int64_t avra_spawn_status(const char* prog, void* args) {
    AvraArray* a = (AvraArray*)args;
    char** argv = (char**)malloc((size_t)(a->len + 2) * sizeof(char*));
    argv[0] = (char*)prog;
    /* EVERY WORD IS CHECKED, because the host RESOLVES each one and
       the seam's per-SEAT check cannot see inside a list: the seat is
       a pointer to a box, so a NUL in a word would cross unexamined.
       That is why neither row is `inert` — the flag says a NUL is data
       to the body, and to these bodies it is two words. */
    for (int64_t i = 0; i < a->len; i++)
        argv[i + 1] = (char*)(uintptr_t)avra_str_crossing((const char*)(uintptr_t)a->data[i]);
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

/* THE SAME, RUN IN A DIRECTORY — because a CHILD'S OUTPUT PATHS ARE RELATIVE TO WHERE IT
   STARTS, and that is not a detail a caller can work around: an invocation handed many
   inputs (which is what makes a batch cheap) writes each output beside its own working
   directory rather than beside its input. The chdir happens IN THE CHILD, between fork and
   exec, so the compiler's own working directory never moves — a process that chdir'd
   would change the meaning of every relative path it touched afterwards. */
int64_t avra_spawn_in(const char* dir, const char* prog, void* args) {
    AvraArray* a = (AvraArray*)args;
    char** argv = (char**)malloc((size_t)(a->len + 2) * sizeof(char*));
    argv[0] = (char*)prog;
    for (int64_t i = 0; i < a->len; i++)
        argv[i + 1] = (char*)(uintptr_t)avra_str_crossing((const char*)(uintptr_t)a->data[i]);
    argv[a->len + 1] = NULL;
    fflush(NULL);
    posix_spawn_file_actions_t acts;
    if (posix_spawn_file_actions_init(&acts) != 0) { free(argv); return 127; }
    if (AVRA_ADDCHDIR(&acts, dir) != 0) { posix_spawn_file_actions_destroy(&acts); free(argv); return 127; }
    pid_t pid;
    int started = posix_spawnp(&pid, prog, &acts, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&acts);
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

// The directory this image stands in — immortal, minted once.
const char* avra_self_dir(void) {
    static const char* dir = NULL;
    if (dir) return dir;
    char self[4096];
    if (!self_path(self, sizeof self)) return str_static("");
    char* slash = strrchr(self, '/');
    if (slash) *slash = 0;
    dir = str_static(self);
    return dir;
}

int64_t avra_exec_self(void* args) {
    AvraArray* a = (AvraArray*)args;
    char self[4096];
    if (!self_path(self, sizeof self)) return 127;
    char** argv = (char**)malloc((size_t)(a->len + 2) * sizeof(char*));
    argv[0] = self;
    /* EVERY WORD IS CHECKED, because the host RESOLVES each one and
       the seam's per-SEAT check cannot see inside a list: the seat is
       a pointer to a box, so a NUL in a word would cross unexamined.
       That is why neither row is `inert` — the flag says a NUL is data
       to the body, and to these bodies it is two words. */
    for (int64_t i = 0; i < a->len; i++)
        argv[i + 1] = (char*)(uintptr_t)avra_str_crossing((const char*)(uintptr_t)a->data[i]);
    argv[a->len + 1] = NULL;
    if (accounting()) acc_report();
    fflush(NULL);
    execv(self, argv);
    free(argv);
    return 127;
}

#endif

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

#if defined(__wasm32__)

// A wasm module has one process and no descriptor table to redirect.
void avra_capture_begin(void) { avra_trap("capture is not available on wasm32"); }
const char* avra_capture_end(void) { avra_trap("capture is not available on wasm32"); }

#else

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

#endif

// THE ROWS CLAIM THE RUNTIME. `runtime/avra_rt.h` is generated from
// `rt_sigs()` and asserts, in the C compiler, that every body answers
// the width its row names and takes the seats it names — the bodies
// above, and the other objects' through their headers, which their
// own definitions must match. Included LAST, so all are declared.
#include "avra_fiber.h"
#include "avra_cores.h"
#include "avra_rt.h"

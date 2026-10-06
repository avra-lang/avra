// A MAP'S COST IS SET BY HOW MANY KEYS IT HOLDS, NEVER BY WHO CHOSE
// THEM. Each attack below builds keys an adversary could send — a
// shared prefix before a NUL, a precomputed collision of an unkeyed
// hash, and collisions under the process's own hash as if its seed had
// leaked — and holds the map to a probe bound and a time bound. A
// quadratic map fails both, and fails fast: an insert loop gives up at
// its time budget.
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "../avra_runtime.h"

void* avra_map_new(void);
void avra_map_set(void* map, const char* key, int64_t v);
int64_t avra_map_has(void* map, const char* key);
int64_t avra_map_get(void* map, const char* key);
int64_t avra_map_len(void* map);
void* avra_cell_unique(void* slot);
const char* avra_bytes_adopted(const void* p, int64_t n);
const char* avra_str_of_bytes(const char* b);
int64_t avra_map_worst_probe(void* map);
int64_t avra_map_slot(void* map, const char* key);
int64_t avra_map_value_at(void* map, int64_t slot);
void avra_map_set_at(void* map, const char* key, int64_t token, int64_t v);
void avra_map_remove(void* map, const char* key);
int64_t avra_map_probes(void);
int64_t avra_map_keyed(void* map);
uint64_t avra_text_hash(const char* s);
uint64_t avra_sip_hash_keyed(uint64_t k0, uint64_t k1, const char* s, int64_t n);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "map_hash_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

enum { N = 100000, PROBE_BOUND = 128 };
static const double BUDGET_S = 2.0;

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

// n octets as a text box of ours — NULs and all.
static const char* text(const void* p, size_t n) {
    const char* b = avra_bytes_adopted(p, (int64_t)n);
    const char* s = avra_str_of_bytes(b);
    avra_rc_release((void*)b);
    return s;
}

static const char* text_z(const char* s) { return text(s, strlen(s)); }

// Every key in, under its own index, within the budget; how many made it.
static int64_t filled(void* m, const char** keys, int64_t n) {
    double t0 = now_s();
    for (int64_t i = 0; i < n; i++) {
        avra_map_set(m, keys[i], i);
        if ((i & 1023) == 0 && now_s() - t0 > BUDGET_S) return i;
    }
    return n;
}

// Every key found, each answering its own index.
static int found_all(void* m, const char** keys, int64_t n) {
    for (int64_t i = 0; i < n; i++) {
        if (!avra_map_has(m, keys[i]) || avra_map_get(m, keys[i]) != i) return 0;
    }
    return 1;
}

static void release_all(const char** keys, int64_t n) {
    for (int64_t i = 0; i < n; i++) avra_rc_release((void*)keys[i]);
}

// One attack: fill, look up, measure. `what` names the key set.
static void attack(const char* what, const char** keys, int64_t n) {
    int64_t live = avra_mem_live();
    void* m = avra_map_new();
    double t0 = now_s();
    int64_t in = filled(m, keys, n);
    char msg[160];
    snprintf(msg, sizeof msg, "%s: all %lld keys insert within %.1fs (%lld did)", what, (long long)n, BUDGET_S, (long long)in);
    CHECK(in == n, msg);
    if (in == n) {
        snprintf(msg, sizeof msg, "%s: every key answers its own value", what);
        CHECK(found_all(m, keys, n) && avra_map_len(m) == n, msg);
        double spent = now_s() - t0;
        snprintf(msg, sizeof msg, "%s: inserts and lookups take %.3fs, under %.1fs", what, spent, BUDGET_S);
        CHECK(spent < BUDGET_S, msg);
        int64_t worst = avra_map_worst_probe(m);
        snprintf(msg, sizeof msg, "%s: the longest probe is %lld, at most %d", what, (long long)worst, PROBE_BOUND);
        CHECK(worst <= PROBE_BOUND, msg);
    }
    avra_rc_release(m);
    snprintf(msg, sizeof msg, "%s: the map, released, leaves the live count where it began", what);
    CHECK(avra_mem_live() == live, msg);
}

// A READ THEN A WRITE OF ONE KEY IS ONE PROBE: the slot row's word
// carries a hit's slot or a miss's empty index word, and the write
// under it walks nothing — through every growth of the index. A word
// the map has since outgrown is probed afresh.
static void token_writes(void) {
    enum { COUNT = 5000 };
    static const char* keys[COUNT];
    for (int64_t i = 0; i < COUNT; i++) {
        char buf[24];
        int len = snprintf(buf, sizeof buf, "t%lld", (long long)i);
        keys[i] = text(buf, (size_t)len);
    }
    void* m = avra_map_new();
    (void)avra_map_probes();
    int64_t before = avra_map_probes();
    for (int64_t i = 0; i < COUNT; i++) {
        int64_t token = avra_map_slot(m, keys[i]);
        if (token >= 0) break;
        avra_map_set_at(m, keys[i], token, i);
    }
    CHECK(avra_map_probes() - before == COUNT, "a miss then its write is one probe a key, through every rebuild");
    CHECK(avra_map_len(m) == COUNT && found_all(m, keys, COUNT), "every key written under a miss's word answers its value");
    before = avra_map_probes();
    int64_t hits = 0;
    for (int64_t i = 0; i < COUNT; i++) {
        int64_t token = avra_map_slot(m, keys[i]);
        if (token >= 0) hits++;
        avra_map_set_at(m, keys[i], token, avra_map_value_at(m, token) + 1);
    }
    CHECK(hits == COUNT && avra_map_probes() - before == COUNT, "a hit then its write is one probe a key");
    CHECK(avra_map_len(m) == COUNT && avra_map_get(m, keys[7]) == 8, "a write under a hit's word overwrites in place");

    const char* late = text("late", 4);
    int64_t stale_miss = avra_map_slot(m, late);
    avra_map_set(m, late, 1);
    avra_map_set_at(m, late, stale_miss, 2);
    CHECK(avra_map_len(m) == COUNT + 1 && avra_map_get(m, late) == 2, "a miss's word for a key since written overwrites, never doubles");
    int64_t stale_hit = avra_map_slot(m, late);
    avra_map_remove(m, late);
    avra_map_set_at(m, late, stale_hit, 3);
    CHECK(avra_map_len(m) == COUNT + 1 && avra_map_get(m, late) == 3 && avra_map_get(m, keys[COUNT - 1]) == COUNT, "a hit's word past the map's end is probed afresh");
    avra_map_set_at(m, keys[0], -1, 40);
    CHECK(avra_map_get(m, keys[0]) == 40, "a word that says nothing is an ordinary write");
    avra_rc_release(m);
    avra_rc_release((void*)late);
    release_all(keys, COUNT);
}

// "k", a NUL, then i: one prefix before the NUL, distinct after it.
static void nul_prefixed(const char** keys, int64_t n) {
    for (int64_t i = 0; i < n; i++) {
        char buf[32];
        buf[0] = 'k';
        buf[1] = '\0';
        int len = snprintf(buf + 2, sizeof buf - 2, "%lld", (long long)i);
        keys[i] = text(buf, (size_t)len + 2);
    }
}

// FNV-1a's low bits depend only on the low bits before them, so a pair
// of blocks that collide there, chained LEVELS deep, makes 2^LEVELS keys
// that share the low BITS of an unkeyed FNV-1a (Joux's multicollision).
enum { BITS = 18, LEVELS = 17, BLOCK = 3 };
static const uint64_t FNV_PRIME = 1099511628211ull, FNV_BASIS = 1469598103934665603ull;
static const char ALPHABET[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

static uint64_t fnv_step(uint64_t h, const char* p, size_t n) {
    for (size_t i = 0; i < n; i++) { h ^= (unsigned char)p[i]; h *= FNV_PRIME; }
    return h;
}

static void block_of(int64_t c, char* out) {
    for (int j = 0; j < BLOCK; j++) { out[j] = ALPHABET[c % 62]; c /= 62; }
}

static int32_t g_seen[1 << BITS];

static void fnv_colliding(const char** keys, int64_t n) {
    char pairs[LEVELS][2][BLOCK];
    uint64_t mask = (1ull << BITS) - 1, s = FNV_BASIS;
    for (int lv = 0; lv < LEVELS; lv++) {
        memset(g_seen, 0xff, sizeof g_seen);
        for (int64_t c = 0;; c++) {
            char b[BLOCK];
            block_of(c, b);
            uint64_t low = fnv_step(s, b, BLOCK) & mask;
            if (g_seen[low] < 0) { g_seen[low] = (int32_t)c; continue; }
            block_of(g_seen[low], pairs[lv][0]);
            memcpy(pairs[lv][1], b, BLOCK);
            s = fnv_step(s, b, BLOCK);
            break;
        }
    }
    for (int64_t i = 0; i < n; i++) {
        char buf[LEVELS * BLOCK];
        for (int lv = 0; lv < LEVELS; lv++) memcpy(buf + lv * BLOCK, pairs[lv][(i >> lv) & 1], BLOCK);
        keys[i] = text(buf, sizeof buf);
    }
}

// Keys that collide in the low BITS of THIS process's own hash, as an
// adversary who learned the seed would build them.
static void seed_colliding(const char** keys, int64_t n, int bits) {
    uint64_t mask = (1ull << bits) - 1, want = 0;
    int64_t got = 0;
    // candidates are hashed unboxed (a pointer with no header of ours
    // is measured by its terminator); only the winners become boxes
    static char room[64];
    char* buf = room + 32;
    for (int64_t c = 0; got < n; c++) {
        snprintf(buf, 32, "t%lld", (long long)c);
        uint64_t low = avra_text_hash(buf) & mask;
        if (got == 0) want = low;
        if (low == want) keys[got++] = text_z(buf);
    }
}

static const char* g_keys[1 << LEVELS];

int main(void) {
    // Python's bytes hash under PYTHONHASHSEED=0: SipHash-1-3, zero key
    CHECK(avra_sip_hash_keyed(0, 0, "abc", 3) == 13851880170939887858ull, "SipHash-1-3 answers the reference vector for \"abc\"");
    CHECK(avra_sip_hash_keyed(0, 0, "abcdefghijklmnopq", 17) == 7044894726457044172ull, "SipHash-1-3 answers the reference vector across a word boundary");

    nul_prefixed(g_keys, N);
    attack("NUL-prefixed keys", g_keys, N);
    release_all(g_keys, N);

    fnv_colliding(g_keys, N);
    int same = 1;
    uint64_t first = fnv_step(FNV_BASIS, g_keys[0], 51) & ((1ull << BITS) - 1);
    for (int64_t i = 1; i < N; i++) same &= (fnv_step(FNV_BASIS, g_keys[i], 51) & ((1ull << BITS) - 1)) == first;
    CHECK(same, "the FNV attack builds what it claims: every key shares its low 18 bits");
    attack("FNV-1a collisions", g_keys, N);
    release_all(g_keys, N);

    enum { SEEDED = 4000 };
    seed_colliding(g_keys, SEEDED, 13);
    attack("collisions under a leaked seed", g_keys, SEEDED);
    void* m = avra_map_new();
    filled(m, g_keys, SEEDED);
    CHECK(avra_map_keyed(m), "a map whose probes pass the bound rekeys itself");
    avra_rc_retain(m);
    void* cell = m;
    void* c = avra_cell_unique(&cell);
    CHECK(c != m && avra_map_keyed(c) && found_all(c, g_keys, SEEDED), "a rekeyed map's clone keeps its keying and its keys");
    avra_rc_release(c);
    avra_rc_release(m);
    release_all(g_keys, SEEDED);

    const char* twins[] = { text_z("a"), text("a\0b", 3), text("a\0c", 3), text("a\0", 2), text("\0", 1), text_z("") };
    void* t = avra_map_new();
    for (int i = 0; i < 6; i++) avra_map_set(t, twins[i], i);
    CHECK(avra_map_len(t) == 6 && found_all(t, twins, 6), "keys that differ only after a NUL are six keys, each its own");
    avra_map_set(t, twins[5], 60);
    CHECK(avra_map_len(t) == 6 && avra_map_get(t, twins[5]) == 60 && avra_map_get(t, twins[4]) == 4, "the empty key is one key, overwritten in place");
    avra_rc_release(t);
    release_all(twins, 6);

    // every length across the hash's branches (0, 1-3, 4-16, the 16-byte
    // rounds), each prefix of one NUL-studded text and its twin that
    // differs only in its last octet: 129 keys, each its own
    enum { LONGEST = 64 };
    const char* sizes[2 * LONGEST + 1];
    char stud[LONGEST];
    for (int i = 0; i < LONGEST; i++) stud[i] = (i % 5 == 1) ? '\0' : (char)('a' + i % 26);
    int64_t made = 0;
    sizes[made++] = text_z("");
    for (int n = 1; n <= LONGEST; n++) {
        sizes[made++] = text(stud, (size_t)n);
        char twin[LONGEST];
        memcpy(twin, stud, (size_t)n);
        twin[n - 1] ^= 0x40;
        sizes[made++] = text(twin, (size_t)n);
    }
    void* z = avra_map_new();
    for (int64_t i = 0; i < made; i++) avra_map_set(z, sizes[i], i);
    CHECK(avra_map_len(z) == made && found_all(z, sizes, made), "every length's prefix and its last-octet twin are distinct keys");
    avra_rc_release(z);
    release_all(sizes, made);

    void* e = avra_map_new();
    const char* empty = text_z("");
    CHECK(!avra_map_has(e, empty), "an empty map holds no empty key");
    avra_map_set(e, empty, 7);
    CHECK(avra_map_has(e, empty) && avra_map_get(e, empty) == 7 && avra_map_len(e) == 1, "an empty key stores and reads");
    avra_rc_release(e);
    avra_rc_release((void*)empty);

    token_writes();

    printf("map hash: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

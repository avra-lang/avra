// STRING-KEYED MAP in C, the floor: an open-addressing table of cached
// hashes, key pointers and values, linear probing at most half full,
// tombstones on remove.
// Prints build, hit, miss, walk and remove per operation at three sizes,
// the sum of one pass of hits and the entries left after removing all.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec * 1e9 + (double)t.tv_nsec;
}

static int env_int(const char* name, int fallback) {
    const char* v = getenv(name);
    return v && *v ? atoi(v) : fallback;
}

static uint64_t mix(uint64_t a, uint64_t b) {
    __uint128_t r = (__uint128_t)a * b;
    return (uint64_t)r ^ (uint64_t)(r >> 64);
}

// wyhash's mix over 8-byte words; the tail zero-padded
static uint64_t text_hash(const char* s, size_t n) {
    uint64_t h = 0x9e3779b97f4a7c15ull ^ n;
    size_t i = 0;
    for (; i + 8 <= n; i += 8) { uint64_t w; memcpy(&w, s + i, 8); h = mix(h ^ w, 0xa0761d6478bd642full); }
    uint64_t w = 0;
    memcpy(&w, s + i, n - i);
    return mix(h ^ w, 0xe7037ed1a0b428dbull);
}

enum { EMPTY = 0, TOMB = 1 };
typedef struct { uint64_t hash; const char* key; size_t len; long val; } Slot;
typedef struct { Slot* s; size_t cap, used, live; } Map;

static void map_init(Map* m, size_t cap) { m->s = calloc(cap, sizeof(Slot)); m->cap = cap; m->used = m->live = 0; }

static void map_grow(Map* m);

static Slot* map_find(Map* m, const char* k, size_t n, uint64_t h) {
    size_t i = h & (m->cap - 1);
    for (;;) {
        Slot* s = &m->s[i];
        if (s->hash == EMPTY) return NULL;
        if (s->hash == h && s->len == n && memcmp(s->key, k, n) == 0) return s;
        i = (i + 1) & (m->cap - 1);
    }
}

static uint64_t hash_of(const char* k, size_t n) { uint64_t h = text_hash(k, n); return h < 2 ? h + 2 : h; }

static void map_put(Map* m, const char* k, size_t n, long v) {
    if ((m->used + 1) * 2 > m->cap) map_grow(m);
    uint64_t h = hash_of(k, n);
    size_t i = h & (m->cap - 1);
    Slot* tomb = NULL;
    for (;;) {
        Slot* s = &m->s[i];
        if (s->hash == EMPTY) break;
        if (s->hash == TOMB) { if (!tomb) tomb = s; }
        else if (s->hash == h && s->len == n && memcmp(s->key, k, n) == 0) { s->val = v; return; }
        i = (i + 1) & (m->cap - 1);
    }
    Slot* s = tomb ? tomb : &m->s[i];
    if (!tomb) m->used++;
    *s = (Slot){ h, k, n, v };
    m->live++;
}

static void map_grow(Map* m) {
    Slot* old = m->s;
    size_t cap = m->cap;
    map_init(m, m->live * 4 > cap ? cap * 2 : cap);
    for (size_t i = 0; i < cap; i++) if (old[i].hash >= 2) map_put(m, old[i].key, old[i].len, old[i].val);
    free(old);
}

static void map_remove(Map* m, const char* k, size_t n) {
    Slot* s = map_find(m, k, n, hash_of(k, n));
    if (s) { s->hash = TOMB; m->live--; }
}

typedef struct { char** k; size_t* n; } Keys;

static Keys keys_of(const char* prefix, int count) {
    Keys ks = { malloc(sizeof(char*) * count), malloc(sizeof(size_t) * count) };
    for (int i = 0; i < count; i++) {
        char buf[32];
        int len = snprintf(buf, sizeof buf, "%s%d", prefix, i);
        ks.k[i] = strdup(buf);
        ks.n[i] = (size_t)len;
    }
    return ks;
}

static long g_sum, g_left;

static void one_size(int n, int ops, int rounds, const char* tag) {
    Keys hit = keys_of("key", n), miss = keys_of("nokey", n);
    int reps = ops / n > 0 ? ops / n : 1;
    double best[5] = { 1e300, 1e300, 1e300, 1e300, 1e300 };
    long sink = 0;
    Map* ms = malloc(sizeof(Map) * reps);
    for (int r = 0; r < rounds; r++) {
        double t = now_ns();
        for (int q = 0; q < reps; q++) {
            map_init(&ms[q], 16);
            for (int i = 0; i < n; i++) map_put(&ms[q], hit.k[i], hit.n[i], i);
        }
        t = now_ns() - t;
        if (t < best[0]) best[0] = t;
        Map* m = &ms[0];
        t = now_ns();
        long s = 0;
        for (int q = 0; q < reps; q++)
            for (int i = 0; i < n; i++) s += map_find(m, hit.k[i], hit.n[i], hash_of(hit.k[i], hit.n[i]))->val;
        t = now_ns() - t;
        if (t < best[1]) best[1] = t;
        if (n == 100000) g_sum = s / reps;
        t = now_ns();
        for (int q = 0; q < reps; q++)
            for (int i = 0; i < n; i++) sink += map_find(m, miss.k[i], miss.n[i], hash_of(miss.k[i], miss.n[i])) != NULL;
        t = now_ns() - t;
        if (t < best[2]) best[2] = t;
        t = now_ns();
        for (int q = 0; q < reps; q++)
            for (size_t i = 0; i < m->cap; i++) if (m->s[i].hash >= 2) sink += m->s[i].val;
        t = now_ns() - t;
        if (t < best[3]) best[3] = t;
        t = now_ns();
        for (int q = 0; q < reps; q++)
            for (int i = 0; i < n; i++) map_remove(&ms[q], hit.k[i], hit.n[i]);
        t = now_ns() - t;
        if (t < best[4]) best[4] = t;
        if (n == 100000) g_left = (long)ms[0].live;
        for (int q = 0; q < reps; q++) free(ms[q].s);
    }
    double per = (double)reps * n;
    const char* ops_names[5] = { "build", "hit", "miss", "walk", "remove" };
    for (int i = 0; i < 5; i++) printf("maps_%s_%s_ns_per_op\t%.1f\tns\t%d\n", ops_names[i], tag, best[i] / per, rounds);
    if (sink == 42) printf("# sink\n");
    free(ms);
}

int main(void) {
    int ops = env_int("BENCH_OPS", 100000), rounds = env_int("BENCH_ROUNDS", 5);
    one_size(8, ops, rounds, "8");
    one_size(1000, ops, rounds, "1k");
    one_size(100000, ops, rounds, "100k");
    printf("maps_hit_sum\t%ld\tops\t%d\n", g_sum, rounds);
    printf("maps_left\t%ld\tops\t%d\n", g_left, rounds);
    return 0;
}

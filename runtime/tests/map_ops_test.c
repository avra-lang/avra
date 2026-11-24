// A MAP ANSWERS WHAT A PLAIN MODEL ANSWERS, through every operation: a
// seeded walk of writes, removes, fused read-then-writes and
// read-then-removes (a slot's word handed to the write or the remove,
// sometimes across another remove), clones written after,
// walks held across writes, and maps emptied — on a map of six keys (the
// small index), of twenty (small to chunked and back through holes) and
// of three hundred. Every few steps the map is read whole: its length,
// its keys and values in insertion order through both `keys`/`values`
// and the walk's rows, and its lookups. A walk held across a write still
// reads the snapshot it began on.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../avra_runtime.h"

void* avra_map_new(void);
void avra_map_set(void* map, const char* key, int64_t v);
int64_t avra_map_has(void* map, const char* key);
int64_t avra_map_get(void* map, const char* key);
int64_t avra_map_len(void* map);
void avra_map_remove(void* map, const char* key);
int64_t avra_map_slot(void* map, const char* key);
void avra_map_set_at(void* map, const char* key, int64_t token, int64_t v);
void avra_map_remove_at(void* map, const char* key, int64_t token);
void* avra_map_keys(void* map);
void* avra_map_vals(void* map);
void* avra_map_walk_keys(void* map);
void* avra_map_walk_vals(void* map);
void* avra_cell_unique(void* slot);
int64_t avra_array_len(void* arr);
int64_t avra_array_get(void* arr, int64_t i);
const char* avra_bytes_adopted(const void* p, int64_t n);
const char* avra_str_of_bytes(const char* b);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what, step) do { g_checks++; if (!(cond)) { if (g_fails++ < 10) fprintf(stderr, "map_ops_test: FAILED %s at step %ld (%s:%d)\n", what, (long)(step), __FILE__, __LINE__); } } while (0)

enum { KEYS = 300, MAPS = 4, STEPS = 60000 };
static const char* g_keys[KEYS];

// The model: a map's keys and values in insertion order.
typedef struct { int n; int key[KEYS]; int64_t val[KEYS]; } Model;

static int model_find(const Model* o, int k) {
    for (int i = 0; i < o->n; i++) if (o->key[i] == k) return i;
    return -1;
}

static void model_set(Model* o, int k, int64_t v) {
    int i = model_find(o, k);
    if (i >= 0) { o->val[i] = v; return; }
    o->key[o->n] = k;
    o->val[o->n] = v;
    o->n++;
}

static void model_remove(Model* o, int k) {
    int i = model_find(o, k);
    if (i < 0) return;
    memmove(o->key + i, o->key + i + 1, (size_t)(o->n - i - 1) * sizeof(int));
    memmove(o->val + i, o->val + i + 1, (size_t)(o->n - i - 1) * sizeof(int64_t));
    o->n--;
}

// Whether two lists hold the model's keys and values, in its order.
static int lists_are(void* ks, void* vs, const Model* o) {
    if (avra_array_len(ks) != o->n || avra_array_len(vs) != o->n) return 0;
    for (int i = 0; i < o->n; i++) {
        if ((const char*)(uintptr_t)avra_array_get(ks, i) != g_keys[o->key[i]] || avra_array_get(vs, i) != o->val[i]) return 0;
    }
    return 1;
}

static void read_whole(void* m, const Model* o, long step) {
    CHECK(avra_map_len(m) == o->n, "the length is the model's", step);
    void* ks = avra_map_keys(m);
    void* vs = avra_map_vals(m);
    CHECK(lists_are(ks, vs, o), "keys and values read back in insertion order", step);
    avra_rc_release(ks);
    avra_rc_release(vs);
    ks = avra_map_walk_keys(m);
    vs = avra_map_walk_vals(m);
    CHECK(lists_are(ks, vs, o), "a walk reads the keys and values in insertion order", step);
    avra_rc_release(ks);
    avra_rc_release(vs);
    for (int k = 0; k < KEYS; k += 7) {
        int i = model_find(o, k);
        CHECK(avra_map_has(m, g_keys[k]) == (i >= 0) && (i < 0 || avra_map_get(m, g_keys[k]) == o->val[i]), "a lookup answers the model", step);
    }
}

// A seeded generator, the same walk on every platform.
static uint64_t g_seed = 0x9e3779b97f4a7c15ull;
static uint32_t next(void) {
    g_seed ^= g_seed << 13;
    g_seed ^= g_seed >> 7;
    g_seed ^= g_seed << 17;
    return (uint32_t)g_seed;
}

int main(void) {
    for (int i = 0; i < KEYS; i++) {
        char buf[16];
        int len = snprintf(buf, sizeof buf, "k%d", i);
        const char* b = avra_bytes_adopted(buf, len);
        g_keys[i] = avra_str_of_bytes(b);
        avra_rc_release((void*)b);
    }
    int64_t live = avra_mem_live();
    void* m[MAPS];
    static Model o[MAPS];
    for (int i = 0; i < MAPS; i++) m[i] = avra_map_new();
    for (long s = 0; s < STEPS; s++) {
        int j = (int)(next() % MAPS);
        int span = j == 0 ? 6 : j == 1 ? 20 : KEYS;
        int k = (int)(next() % (uint32_t)span);
        int op = (int)(next() % 100);
        int64_t v = next();
        if (op < 40) {
            avra_map_set(m[j], g_keys[k], v);
            model_set(&o[j], k, v);
        } else if (op < 65) {
            avra_map_remove(m[j], g_keys[k]);
            model_remove(&o[j], k);
        } else if (op < 75) {
            // a read's word, handed to the write — sometimes across a remove
            int64_t token = avra_map_slot(m[j], g_keys[k]);
            if (next() % 3 == 0) {
                int gone = (int)(next() % (uint32_t)span);
                avra_map_remove(m[j], g_keys[gone]);
                model_remove(&o[j], gone);
            }
            avra_map_set_at(m[j], g_keys[k], token, v);
            model_set(&o[j], k, v);
        } else if (op < 78) {
            // a read's word, handed to the remove — sometimes across another remove
            int64_t token = avra_map_slot(m[j], g_keys[k]);
            if (next() % 3 == 0) {
                int gone = (int)(next() % (uint32_t)span);
                avra_map_remove(m[j], g_keys[gone]);
                model_remove(&o[j], gone);
            }
            avra_map_remove_at(m[j], g_keys[k], token);
            model_remove(&o[j], k);
        } else if (op < 82) {
            // a clone, written after: neither sees the other's writes
            int d = (int)(next() % MAPS);
            if (d == j) continue;
            avra_rc_release(m[d]);
            avra_rc_retain(m[j]);
            void* cell = m[j];
            m[d] = avra_cell_unique(&cell);
            o[d] = o[j];
        } else if (op < 85) {
            // a walk held across a write and a remove reads its snapshot
            Model before = o[j];
            void* ks = avra_map_walk_keys(m[j]);
            void* vs = avra_map_walk_vals(m[j]);
            avra_map_set(m[j], g_keys[k], v);
            model_set(&o[j], k, v);
            int gone = (int)(next() % (uint32_t)span);
            avra_map_remove(m[j], g_keys[gone]);
            model_remove(&o[j], gone);
            CHECK(lists_are(ks, vs, &before), "a walk held across writes reads the snapshot it began on", s);
            avra_rc_release(ks);
            avra_rc_release(vs);
        } else if (op < 86) {
            while (o[j].n) {
                int first = o[j].key[0];
                avra_map_remove(m[j], g_keys[first]);
                model_remove(&o[j], first);
            }
        } else {
            read_whole(m[j], &o[j], s);
        }
    }
    for (int i = 0; i < MAPS; i++) {
        read_whole(m[i], &o[i], STEPS);
        avra_rc_release(m[i]);
    }
    CHECK(avra_mem_live() == live, "every map, released, leaves the live count where it began", STEPS);
    for (int i = 0; i < KEYS; i++) avra_rc_release((void*)g_keys[i]);
    printf("map ops: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

// A MAP ANSWERS WHAT A PLAIN MODEL ANSWERS, under text keys and under word
// keys alike (zero and negative words among them), through every operation: a
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
void* avra_map_w_new(void);
void avra_map_w_set(void* map, int64_t key, int64_t v);
int64_t avra_map_w_has(void* map, int64_t key);
int64_t avra_map_w_get(void* map, int64_t key);
void avra_map_w_remove(void* map, int64_t key);
int64_t avra_map_w_slot(void* map, int64_t key);
void avra_map_w_set_at(void* map, int64_t key, int64_t token, int64_t v);
void avra_map_w_remove_at(void* map, int64_t key, int64_t token);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what, step) do { g_checks++; if (!(cond)) { if (g_fails++ < 10) fprintf(stderr, "map_ops_test: FAILED %s at step %ld (%s:%d)\n", what, (long)(step), __FILE__, __LINE__); } } while (0)

enum { KEYS = 300, MAPS = 4, STEPS = 60000 };
static const char* g_keys[KEYS];

// Which class of key the walk writes under: text, or the word `k - 150`.
static int g_words;

static int64_t key_word(int k) { return (int64_t)k - 150; }

// The map's own word for key number `k`: its text's address, or the word itself.
static int64_t key_of(int k) { return g_words ? key_word(k) : (int64_t)(uintptr_t)g_keys[k]; }

static void* made(void) { return g_words ? avra_map_w_new() : avra_map_new(); }
static void set(void* m, int k, int64_t v) { if (g_words) avra_map_w_set(m, key_word(k), v); else avra_map_set(m, g_keys[k], v); }
static int64_t has(void* m, int k) { return g_words ? avra_map_w_has(m, key_word(k)) : avra_map_has(m, g_keys[k]); }
static int64_t get(void* m, int k) { return g_words ? avra_map_w_get(m, key_word(k)) : avra_map_get(m, g_keys[k]); }
static void removed(void* m, int k) { if (g_words) avra_map_w_remove(m, key_word(k)); else avra_map_remove(m, g_keys[k]); }
static int64_t slot(void* m, int k) { return g_words ? avra_map_w_slot(m, key_word(k)) : avra_map_slot(m, g_keys[k]); }
static void set_at(void* m, int k, int64_t token, int64_t v) {
    if (g_words) avra_map_w_set_at(m, key_word(k), token, v);
    else avra_map_set_at(m, g_keys[k], token, v);
}
static void removed_at(void* m, int k, int64_t token) {
    if (g_words) avra_map_w_remove_at(m, key_word(k), token);
    else avra_map_remove_at(m, g_keys[k], token);
}

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
        if (avra_array_get(ks, i) != key_of(o->key[i]) || avra_array_get(vs, i) != o->val[i]) return 0;
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
        CHECK(has(m, k) == (i >= 0) && (i < 0 || get(m, k) == o->val[i]), "a lookup answers the model", step);
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

static void walked(void);

int main(void) {
    for (int i = 0; i < KEYS; i++) {
        char buf[16];
        int len = snprintf(buf, sizeof buf, "k%d", i);
        const char* b = avra_bytes_adopted(buf, len);
        g_keys[i] = avra_str_of_bytes(b);
        avra_rc_release((void*)b);
    }
    for (g_words = 0; g_words < 2; g_words++) walked();
    for (int i = 0; i < KEYS; i++) avra_rc_release((void*)g_keys[i]);
    printf("map ops: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

// One seeded walk of every operation over MAPS maps of the walk's key class.
static void walked(void) {
    int64_t live = avra_mem_live();
    void* m[MAPS];
    static Model o[MAPS];
    memset(o, 0, sizeof o);
    for (int i = 0; i < MAPS; i++) m[i] = made();
    for (long s = 0; s < STEPS; s++) {
        int j = (int)(next() % MAPS);
        int span = j == 0 ? 6 : j == 1 ? 20 : KEYS;
        int k = (int)(next() % (uint32_t)span);
        int op = (int)(next() % 100);
        int64_t v = next();
        if (op < 40) {
            set(m[j], k, v);
            model_set(&o[j], k, v);
        } else if (op < 65) {
            removed(m[j], k);
            model_remove(&o[j], k);
        } else if (op < 75) {
            // a read's word, handed to the write — sometimes across a remove
            int64_t token = slot(m[j], k);
            if (next() % 3 == 0) {
                int gone = (int)(next() % (uint32_t)span);
                removed(m[j], gone);
                model_remove(&o[j], gone);
            }
            set_at(m[j], k, token, v);
            model_set(&o[j], k, v);
        } else if (op < 78) {
            // a read's word, handed to the remove — sometimes across another remove
            int64_t token = slot(m[j], k);
            if (next() % 3 == 0) {
                int gone = (int)(next() % (uint32_t)span);
                removed(m[j], gone);
                model_remove(&o[j], gone);
            }
            removed_at(m[j], k, token);
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
            set(m[j], k, v);
            model_set(&o[j], k, v);
            int gone = (int)(next() % (uint32_t)span);
            removed(m[j], gone);
            model_remove(&o[j], gone);
            CHECK(lists_are(ks, vs, &before), "a walk held across writes reads the snapshot it began on", s);
            avra_rc_release(ks);
            avra_rc_release(vs);
        } else if (op < 86) {
            while (o[j].n) {
                int first = o[j].key[0];
                removed(m[j], first);
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
}

// A PACKED LIST — the cells of a list of plain scalars, with no marks — answers every row a marked
// list answers, cell for cell: made empty, sized and filled; pushed past each buffer class and past
// the slab bar into a realloc'd buffer; written in place; popped; cloned when shared; concatenated
// and sliced with packed and marked lists on either side, held alone and shared; reserved and
// extended. Every list dies with the live count back where it began, and an owned or absent cell
// written into a packed list is refused as a defect rather than read later as garbage.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_runtime.h"
#include "../avra_box.h"

void* avra_array_new(void);
void* avra_array_new_words(void);
void* avra_array_sized_words(int64_t n);
void* avra_array_filled_words(int64_t n, int64_t w);
void* avra_array_empty_words(void);
void avra_array_push_owned(void* arr, void* v);
void avra_array_push_moved(void* arr, void* v);
void avra_array_push_maybe(void* arr, int64_t present, int64_t v);
int64_t avra_array_get(void* arr, int64_t i);
int64_t avra_array_len(void* arr);
void avra_slot_set(void* arr, int64_t i, int64_t v);
void avra_slot_put(void* arr, int64_t i, int64_t v);
void avra_slot_set_owned(void* arr, int64_t i, void* v);
void avra_slot_set_maybe(void* arr, int64_t i, int64_t present, int64_t v);
int64_t avra_slot_present(void* arr, int64_t i);
int64_t avra_array_last_present(void* arr);
int64_t avra_array_pop(void* arr);
void* avra_array_concat(void* a, void* b);
void* avra_array_concat_reusing(void* a, void* b);
void* avra_array_slice(void* arr, int64_t lo, int64_t hi);
void* avra_array_slice_reusing(void* arr, int64_t lo, int64_t hi);
void avra_array_extend(void* dst, void* src);
void avra_array_reserve(void* arr, int64_t spare);
void* avra_cell_unique(void* slot);
void avra_rc_retain(void* p);
const char* avra_int_text(int64_t v);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "packed_list_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static AvraArray* arr(void* p) { return (AvraArray*)p; }

// Whether list `p` holds exactly the cells `want[0..n)`.
static int holds(void* p, const int64_t* want, int64_t n) {
    if (avra_array_len(p) != n) return 0;
    for (int64_t i = 0; i < n; i++) if (avra_array_get(p, i) != want[i]) return 0;
    return 1;
}

// A packed list of `n` cells, cell `i` being `base + i`, pushed onto an empty one.
static void* counted(int64_t n, int64_t base) {
    void* xs = avra_array_new_words();
    for (int64_t i = 0; i < n; i++) avra_array_push(xs, base + i);
    return xs;
}

// A marked list of the same cells.
static void* counted_marked(int64_t n, int64_t base) {
    void* xs = avra_array_new();
    for (int64_t i = 0; i < n; i++) avra_array_push(xs, base + i);
    return xs;
}

static void made(void) {
    void* e = avra_array_new_words();
    CHECK(avra_packed(arr(e)) && avra_array_len(e) == 0, "an empty packed list holds nothing and no marks");
    avra_rc_release(e);
    void* s = avra_array_sized_words(5);
    CHECK(avra_packed(arr(s)) && avra_array_len(s) == 0 && arr(s)->cap == 5, "a sized one has its room and no marks");
    for (int64_t i = 0; i < 5; i++) avra_array_push(s, i * 3);
    int64_t want[5] = { 0, 3, 6, 9, 12 };
    CHECK(holds(s, want, 5) && arr(s)->data == (int64_t*)(arr(s) + 1), "filled to its room, its cells still in its box");
    avra_rc_release(s);
    void* f = avra_array_filled_words(7, -4);
    int64_t fours[7] = { -4, -4, -4, -4, -4, -4, -4 };
    CHECK(avra_packed(arr(f)) && holds(f, fours, 7), "a filled one holds its word in every cell");
    avra_rc_release(f);
    void* z = avra_array_filled_words(3, 0);
    int64_t zeros[3] = { 0, 0, 0 };
    CHECK(holds(z, zeros, 3), "a filled one of zero is zero throughout");
    avra_rc_release(z);
    void* none = avra_array_filled_words(-2, 9);
    CHECK(avra_array_len(none) == 0, "a fill below zero cells is empty");
    avra_rc_release(none);
}

// Pushes past every class (8, 16, 32), the slab bar and into realloc's growth; each cell read back.
static void grown(void) {
    int64_t sizes[] = { 1, 7, 8, 9, 16, 17, 32, 33, 128, 129, 200, 5000 };
    for (size_t k = 0; k < sizeof sizes / sizeof sizes[0]; k++) {
        int64_t n = sizes[k];
        void* xs = counted(n, 100);
        int ok = avra_packed(arr(xs)) && avra_array_len(xs) == n;
        for (int64_t i = 0; i < n; i++) ok = ok && avra_array_get(xs, i) == 100 + i;
        CHECK(ok, "a packed list grown by pushes holds every cell, still packed");
        avra_array_reserve(xs, 3 * n);
        ok = avra_packed(arr(xs)) && arr(xs)->cap - arr(xs)->len >= 3 * n;
        for (int64_t i = 0; i < n; i++) ok = ok && avra_array_get(xs, i) == 100 + i;
        CHECK(ok, "a reserve keeps its cells and its packing");
        avra_rc_release(xs);
    }
}

static void written(void) {
    void* xs = counted(20, 0);
    avra_slot_set(xs, 3, 33);
    avra_slot_put(xs, 19, 1919);
    avra_slot_set_maybe(xs, 4, 1, 44);
    CHECK(avra_array_get(xs, 3) == 33 && avra_array_get(xs, 19) == 1919 && avra_array_get(xs, 4) == 44,
          "a write in place lands in its cell");
    CHECK(avra_slot_present(xs, 4) && avra_array_last_present(xs), "every cell of a packed list is present");
    avra_array_push_maybe(xs, 1, 2020);
    CHECK(avra_array_len(xs) == 21 && avra_array_get(xs, 20) == 2020, "a present nullable pushed is its word");
    CHECK(avra_array_pop(xs) == 2020 && avra_array_pop(xs) == 1919 && avra_array_len(xs) == 19, "pops answer the last cells");
    avra_rc_release(xs);
}

// A shared packed list opened for a write is cloned, packed; the other holder reads it as it was.
static void cloned(void) {
    void* xs = counted(10, 50);
    avra_rc_retain(xs);
    void* slot = xs;
    void* mine = avra_cell_unique(&slot);
    CHECK(mine != xs && avra_packed(arr(mine)), "a shared packed list opens into a packed clone");
    avra_slot_set(mine, 0, -1);
    CHECK(avra_array_get(xs, 0) == 50 && avra_array_get(mine, 0) == -1, "the clone's write reaches only the clone");
    int ok = 1;
    for (int64_t i = 1; i < 10; i++) ok = ok && avra_array_get(mine, i) == 50 + i;
    CHECK(ok, "the clone holds the rest of the cells");
    avra_rc_release(mine);
    avra_rc_release(xs);
    void* empty = avra_array_empty_words();
    CHECK(avra_packed(arr(empty)) && avra_array_len(empty) == 0, "the empty packed list is empty and packed");
    void* held = empty;
    void* opened = avra_cell_unique(&held);
    CHECK(opened != empty && avra_packed(arr(opened)), "its first open is a packed clone of its own");
    for (int64_t i = 0; i < 40; i++) avra_array_push(opened, i);
    CHECK(avra_array_len(opened) == 40 && avra_array_get(opened, 39) == 39 && avra_array_len(empty) == 0,
          "pushes land in the clone, the empty list stands");
    avra_rc_release(opened);
}

static void joined(void) {
    for (int ap = 0; ap < 2; ap++) {
        for (int bp = 0; bp < 2; bp++) {
            void* a = ap ? counted(5, 0) : counted_marked(5, 0);
            void* b = bp ? counted(4, 10) : counted_marked(4, 10);
            void* c = avra_array_concat(a, b);
            int64_t want[9] = { 0, 1, 2, 3, 4, 10, 11, 12, 13 };
            CHECK(holds(c, want, 9), "a concat holds both lists' cells in order");
            CHECK(avra_packed(arr(c)) == (ap || bp), "a concat with a packed side is packed");
            void* s = avra_array_slice(c, 2, 7);
            CHECK(holds(s, want + 2, 5) && avra_packed(arr(s)) == avra_packed(arr(c)), "a slice keeps its source's packing");
            avra_rc_release(s);
            avra_rc_retain(c);
            void* cut = avra_array_slice_reusing(c, 1, 8);
            CHECK(cut != c && holds(cut, want + 1, 7) && holds(c, want, 9), "a shared list sliced is copied, the original standing");
            avra_rc_release(cut);
            void* alone = avra_array_slice_reusing(c, 3, 9);
            CHECK(holds(alone, want + 3, 6), "a list held alone is sliced in place");
            void* more = avra_array_concat_reusing(alone, b);
            int64_t want2[10] = { 3, 4, 10, 11, 12, 13, 10, 11, 12, 13 };
            CHECK(holds(more, want2, 10), "a concat onto a list held alone appends in place");
            avra_array_extend(more, a);
            CHECK(avra_array_len(more) == 15 && avra_array_get(more, 14) == 4, "an extend appends every cell");
            avra_rc_release(more);
            avra_rc_release(a);
            avra_rc_release(b);
        }
    }
    void* e = avra_array_new_words();
    void* p = counted(3, 7);
    void* c = avra_array_concat(e, p);
    int64_t want[3] = { 7, 8, 9 };
    CHECK(holds(c, want, 3) && avra_packed(arr(c)), "an empty packed list concatenated is its other side's cells");
    avra_rc_release(c);
    avra_rc_release(e);
    avra_rc_release(p);
}

// Runs `write` in a child; true when it stops with the packed list's law said.
#define LAW "an owned or absent cell written into a packed list"
static int refused(void (*write)(void)) {
    int err[2];
    if (pipe(err) != 0) return 0;
    fflush(stdout);
    fflush(stderr);
    pid_t child = fork();
    if (child == 0) {
        close(err[0]);
        dup2(err[1], 2);
        write();
        _exit(0);
    }
    close(err[1]);
    char said[512] = { 0 };
    ssize_t n = 0, got;
    while (n < (ssize_t)sizeof said - 1 && (got = read(err[0], said + n, sizeof said - 1 - (size_t)n)) > 0) n += got;
    close(err[0]);
    int status = 0;
    waitpid(child, &status, 0);
    return WIFEXITED(status) && WEXITSTATUS(status) != 0 && strstr(said, LAW) != NULL;
}

static void push_owned(void) { avra_array_push_owned(counted(2, 0), (void*)avra_int_text(5)); }
static void push_owned_full(void) { avra_array_push_owned(avra_array_filled_words(4, 1), (void*)avra_int_text(5)); }
static void push_moved(void) { avra_array_push_moved(counted(2, 0), (void*)avra_int_text(5)); }
static void push_absent(void) { avra_array_push_maybe(counted(2, 0), 0, 0); }
static void set_owned(void) { avra_slot_set_owned(counted(2, 0), 0, (void*)avra_int_text(5)); }
static void set_absent(void) { avra_slot_set_maybe(counted(2, 0), 0, 0, 0); }
static void concat_owned(void) {
    void* texts = avra_array_new();
    avra_array_push_owned(texts, (void*)avra_int_text(5));
    avra_array_concat(counted(2, 0), texts);
}

static void refusals(void) {
    CHECK(refused(push_owned), "an owned push into a packed list is refused");
    CHECK(refused(push_owned_full), "and into a full one, before it grows");
    CHECK(refused(push_moved), "a moved push alike");
    CHECK(refused(push_absent), "an absent nullable pushed alike");
    CHECK(refused(set_owned), "an owned slot write alike");
    CHECK(refused(set_absent), "an absent slot write alike");
    CHECK(refused(concat_owned), "an owned cell concatenated into a packed list alike");
}

int main(void) {
    int64_t live = avra_mem_live();
    made();
    grown();
    written();
    cloned();
    joined();
    CHECK(avra_mem_live() == live, "every packed list freed leaves the live count where it began");
    refusals();
    printf("packed_list_test: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

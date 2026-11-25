// A WRITE NEVER LANDS IN THE BINARY'S OWN DATA: a list laid out as the
// backend lays out a static one (an immortal kind, every flag set, its
// length its capacity) refuses a push, a slot write and an open that
// would clone into it — each in the law's words, exit 2. A box minted
// here and made immortal later (a `once` answer, which may be a Cell)
// is written as before, and so is a plain one.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#include "../avra_box.h"
#include "../avra_runtime.h"

void* avra_array_new(void);
void avra_array_push(void* arr, int64_t v);
void avra_array_push_owned(void* arr, void* v);
void avra_array_push_moved(void* arr, void* v);
void avra_slot_put(void* arr, int64_t i, int64_t v);
void avra_slot_set(void* arr, int64_t i, int64_t v);
void* avra_slot_unique(void* arr, int64_t i);
int64_t avra_array_len(void* arr);
int64_t avra_array_get(void* arr, int64_t i);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "static_write_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static const char* const LAW = "defect: a write landed in the binary's own data — a box never opened for writing";

// A static list of two cells, the second holding a static inner list:
// the header and the box exactly as backend/llvm_wrapper.c lays them out.
typedef struct {
    Header h;
    AvraArray a;
    int64_t cells[2];
    uint8_t marks[2];
} __attribute__((aligned(16))) StaticList;

static StaticList g_inner, g_outer;

static void laid_out(StaticList* s, int64_t first, int64_t second, uint8_t second_mark) {
    s->h = (Header){ AVRA_TAG, KIND_IMMORTAL(KIND_ARRAY), 0, (uint32_t)sizeof(AvraArray) };
    s->a = (AvraArray){ 2, 2, s->cells, s->marks, NULL };
    s->cells[0] = first;
    s->cells[1] = second;
    s->marks[0] = 0;
    s->marks[1] = second_mark;
}

static void* payload(StaticList* s) { return &s->a; }

// Runs `write` in a child; true when it exits 2 having said the law.
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
    return WIFEXITED(status) && WEXITSTATUS(status) == 2 && strstr(said, LAW) != NULL;
}

static void push_word(void) { avra_array_push(payload(&g_outer), 7); }
static void push_owned(void) { avra_array_push_owned(payload(&g_outer), payload(&g_inner)); }
static void push_moved(void) { avra_array_push_moved(payload(&g_outer), payload(&g_inner)); }
static void put_word(void) { avra_slot_put(payload(&g_outer), 0, 7); }
static void set_word(void) { avra_slot_set(payload(&g_outer), 0, 7); }
static void open_inner(void) { avra_slot_unique(payload(&g_outer), 1); }

int main(void) {
    laid_out(&g_inner, 1, 2, 0);
    laid_out(&g_outer, 3, (int64_t)(uintptr_t)payload(&g_inner), MARK_OWNED);

    CHECK(refused(push_word), "a push onto a static list is refused in the law's words, exit 2");
    CHECK(refused(push_owned), "an owned push onto a static list is refused");
    CHECK(refused(push_moved), "a moved push onto a static list is refused");
    CHECK(refused(put_word), "a slot put into a static list is refused");
    CHECK(refused(set_word), "a slot set into a static list is refused");
    CHECK(refused(open_inner), "an open that would clone into a static list is refused");
    CHECK(g_outer.cells[0] == 3 && g_outer.a.len == 2 && g_inner.a.len == 2, "the static lists are as laid out");

    // a box minted here, made immortal later — a `once` answer, possibly
    // a Cell — keeps its flags and is written as before
    void* held = avra_array_new();
    avra_array_push(held, 1);
    Header* h = (Header*)held - 1;
    avra_set_kind(h, KIND_IMMORTAL(avra_kind(h)));
    avra_slot_put(held, 0, 5);
    avra_array_push(held, 6);
    CHECK(avra_array_get(held, 0) == 5 && avra_array_len(held) == 2, "a box made immortal at run time is written in place");

    void* plain = avra_array_new();
    for (int i = 0; i < 100; i++) avra_array_push(plain, i);
    avra_slot_set(plain, 3, 30);
    CHECK(avra_array_len(plain) == 100 && avra_array_get(plain, 3) == 30, "a plain list is written as before");
    avra_rc_release(plain);

    if (g_fails) {
        fprintf(stderr, "static_write_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("static_write_test: %d checks hold\n", g_checks);
    return 0;
}

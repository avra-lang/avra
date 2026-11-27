// A TEXT BUILT IN ONE BOX spells each piece as its own row spells it: an
// int as `avra_int_text`, a float as `avra_float_text`, a truth as its
// keyword, a text whole by its header's length. Each build starts empty, a build
// inside another leaves the outer whole, and its one box is all it leaves live.
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "../avra_runtime.h"

const char* avra_int_text(int64_t v);
const char* avra_float_text(double d);
int64_t avra_str_len(const char* s);
void avra_text_begin(void);
void avra_text_add(const char* s);
void avra_text_add_int(int64_t v);
void avra_text_add_float(double d);
void avra_text_add_bool(int64_t b);
const char* avra_text_end(void);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "text_built_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

// Whether two texts hold the same bytes, by their headers' lengths.
static int same_text(const char* a, const char* b) {
    int64_t n = avra_str_len(a);
    return n == avra_str_len(b) && memcmp(a, b, (size_t)n) == 0;
}

// The int `v` built alone, against its row's own spelling.
static int int_alike(int64_t v) {
    avra_text_begin();
    avra_text_add_int(v);
    const char* built = avra_text_end();
    const char* row = avra_int_text(v);
    int alike = same_text(built, row);
    avra_rc_release((void*)built);
    avra_rc_release((void*)row);
    return alike;
}

// The float `d` built alone, against its row's own spelling.
static int float_alike(double d) {
    avra_text_begin();
    avra_text_add_float(d);
    const char* built = avra_text_end();
    const char* row = avra_float_text(d);
    int alike = same_text(built, row);
    avra_rc_release((void*)built);
    avra_rc_release((void*)row);
    return alike;
}

int main(void) {
    int64_t live = avra_mem_live();

    avra_text_begin();
    const char* empty = avra_text_end();
    CHECK(avra_str_len(empty) == 0 && empty[0] == '\0', "a build of nothing is the empty text");
    avra_rc_release((void*)empty);

    int64_t ints[] = { 0, 7, -7, 1000000, INT64_MAX, INT64_MIN };
    for (size_t i = 0; i < sizeof ints / sizeof ints[0]; i++) CHECK(int_alike(ints[i]), "an int is spelled as its row spells it");

    double floats[] = { 0.0, -0.0, 0.1, 3.0, -2.5, 1e21, 1e-7, 123456.789, INFINITY, -INFINITY, NAN };
    for (size_t i = 0; i < sizeof floats / sizeof floats[0]; i++) CHECK(float_alike(floats[i]), "a float is spelled as its row spells it");

    avra_text_begin();
    const char* nothing = avra_text_end();
    avra_text_begin();
    avra_text_add_bool(1);
    avra_text_add(nothing);
    avra_text_add_bool(0);
    const char* truths = avra_text_end();
    avra_rc_release((void*)nothing);
    CHECK(strcmp(truths, "truefalse") == 0 && avra_str_len(truths) == 9, "a truth is its keyword, and an empty text adds nothing");
    avra_rc_release((void*)truths);

    avra_text_begin();
    avra_text_add_int(41);
    avra_text_add_bool(1);
    const char* inner = avra_text_end();
    avra_text_begin();
    avra_text_add(inner);
    avra_text_add(inner);
    const char* twice = avra_text_end();
    CHECK(strcmp(twice, "41true41true") == 0, "a built text added to a build is whole");
    avra_rc_release((void*)inner);
    avra_rc_release((void*)twice);

    avra_text_begin();
    for (int i = 0; i < 1000; i++) avra_text_add_int(i % 10);
    const char* long_one = avra_text_end();
    int digits_ok = avra_str_len(long_one) == 1000;
    for (int i = 0; i < 1000 && digits_ok; i++) digits_ok = long_one[i] == (char)('0' + i % 10);
    CHECK(digits_ok, "a text longer than the scratch's first room is built whole");
    avra_rc_release((void*)long_one);

    avra_text_begin();
    avra_text_add_int(5);
    avra_text_begin();
    avra_text_add_int(6);
    const char* inner_built = avra_text_end();
    avra_text_add_int(7);
    const char* outer_built = avra_text_end();
    CHECK(strcmp(inner_built, "6") == 0, "a build begun inside another starts empty");
    CHECK(strcmp(outer_built, "57") == 0, "a build ended inside another leaves the outer one whole");
    avra_rc_release((void*)inner_built);
    avra_rc_release((void*)outer_built);

    CHECK(avra_mem_live() == live, "every built text, released, leaves the live count where it began");

    fprintf(stderr, "text_built_test: %d/%d checks passed\n", g_checks - g_fails, g_checks);
    return g_fails == 0 ? 0 : 1;
}

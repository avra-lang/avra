// A FLOAT'S BITS, BOTH WAYS: the pattern crosses whole — every NaN payload,
// either zero, either infinity, a subnormal — and a round trip over patterns
// nobody chose returns the pattern it began with.
#include <stdint.h>
#include <stdio.h>
#include <string.h>

int64_t avra_float_to_bits(double f);
double avra_float_of_bits(int64_t b);

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "float_bits_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static int64_t pattern(uint64_t u) { return (int64_t)u; }

// A pattern read as a float and back.
static int whole(uint64_t u) { return avra_float_to_bits(avra_float_of_bits(pattern(u))) == pattern(u); }

// xorshift64: patterns nobody chose.
static uint64_t g_state = 0x9E3779B97F4A7C15ull;
static uint64_t next_bits(void) {
    g_state ^= g_state << 13;
    g_state ^= g_state >> 7;
    g_state ^= g_state << 17;
    return g_state;
}

int main(void) {
    CHECK(avra_float_to_bits(1.0) == pattern(0x3FF0000000000000ull), "1.0 is 0x3FF0000000000000");
    CHECK(avra_float_to_bits(-2.5) == pattern(0xC004000000000000ull), "-2.5 is 0xC004000000000000");
    CHECK(avra_float_of_bits(pattern(0x3FF8000000000000ull)) == 1.5, "0x3FF8000000000000 is 1.5");

    CHECK(avra_float_to_bits(0.0) == 0 && avra_float_to_bits(-0.0) == pattern(0x8000000000000000ull), "the two zeros have two patterns");
    double negative_zero = avra_float_of_bits(pattern(0x8000000000000000ull));
    CHECK(negative_zero == 0.0 && memcmp(&negative_zero, &(uint64_t){0x8000000000000000ull}, 8) == 0, "-0.0 keeps its sign");

    CHECK(avra_float_to_bits(__builtin_inf()) == pattern(0x7FF0000000000000ull), "+inf");
    CHECK(avra_float_to_bits(-__builtin_inf()) == pattern(0xFFF0000000000000ull), "-inf");

    const uint64_t nans[] = {
        0x7FF8000000000000ull, 0xFFF8000000000000ull, 0x7FF8000000000001ull, 0x7FF0000000000001ull,
        0xFFF0000000000001ull, 0x7FFFFFFFFFFFFFFFull, 0xFFFFFFFFFFFFFFFFull, 0x7FF4000000000000ull,
        0x7FF123456789ABCDull,
    };
    for (size_t i = 0; i < sizeof nans / sizeof nans[0]; i++) CHECK(whole(nans[i]), "a NaN keeps its payload and its quiet bit");

    const uint64_t subnormals[] = { 1ull, 2ull, 0x000FFFFFFFFFFFFFull, 0x8000000000000001ull, 0x800FFFFFFFFFFFFFull, 0x0008000000000000ull };
    for (size_t i = 0; i < sizeof subnormals / sizeof subnormals[0]; i++) CHECK(whole(subnormals[i]), "a subnormal keeps every bit");
    CHECK(avra_float_of_bits(1) > 0.0 && avra_float_of_bits(1) < 1e-300, "the smallest subnormal is a tiny positive number");

    CHECK(whole(0x0010000000000000ull) && whole(0x7FEFFFFFFFFFFFFFull), "the smallest normal and the largest finite");

    int lost = 0;
    for (int i = 0; i < 1000000; i++) lost += !whole(next_bits());
    CHECK(lost == 0, "a million patterns nobody chose come back as they went");

    int drifted = 0;
    for (int i = 0; i < 1000; i++) {
        double d = (double)(int64_t)next_bits() / 3.0;
        drifted += avra_float_of_bits(avra_float_to_bits(d)) != d;
    }
    CHECK(drifted == 0, "a float comes back equal to itself");

    printf("float_bits: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}

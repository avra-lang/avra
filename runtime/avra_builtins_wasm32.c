// THE COMPILER-RT BUILTINS wasm32 needs and its sysroot does not carry:
// wasi-libc's integer scan multiplies in 128 bits, which clang lowers to
// a call to `__multi3`. Every other target takes it from its own
// compiler-rt, so this file compiles empty there.
#ifdef __wasm32__

#include <stdint.h>

typedef union { __int128 all; struct { uint64_t lo, hi; } half; } Wide;

// The high 64 bits of a 64 x 64 product, in 32-bit pieces.
static uint64_t product_high(uint64_t a, uint64_t b) {
    uint64_t a0 = a & 0xffffffffu, a1 = a >> 32, b0 = b & 0xffffffffu, b1 = b >> 32;
    uint64_t p01 = a0 * b1, p10 = a1 * b0;
    uint64_t mid = ((a0 * b0) >> 32) + (p01 & 0xffffffffu) + (p10 & 0xffffffffu);
    return a1 * b1 + (p01 >> 32) + (p10 >> 32) + (mid >> 32);
}

__int128 __multi3(__int128 a, __int128 b) {
    Wide x = { .all = a }, y = { .all = b }, r;
    r.half.lo = x.half.lo * y.half.lo;
    r.half.hi = product_high(x.half.lo, y.half.lo) + x.half.hi * y.half.lo + x.half.lo * y.half.hi;
    return r.all;
}

#endif

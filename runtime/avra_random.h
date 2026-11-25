// The draw behind `avra_random_bytes`, apart from where its bytes come from, so
// its laws can be tested against sources that fail. Included by
// avra_runtime.c, where `bytes_box`, `avra_trap`, `avra_fmt` and
// `avra_rc_release` stand; its test supplies stand-ins for them.
#ifndef AVRA_RANDOM_H
#define AVRA_RANDOM_H

// A source of entropy: up to `n` bytes at `out`, how many were written, or
// -1 when it has none to give (an interrupted read is `EINTR`).
typedef ssize_t (*RandomSource)(void* out, size_t n);

__attribute__((noinline, cold, noreturn))
static void trap_random_length(int64_t n) {
    char msg[96];
    avra_fmt(msg, sizeof msg, "random_bytes takes a length of 0 or more, found %lld", (long long)n);
    avra_trap(msg);
    abort();
}

// `n` bytes of `source` as a Bytes box: empty for none, NULL only when the
// source gives none, a trap for a negative `n` (the caller's own mistake). A
// short read is read on until the box is whole, and never answers a partly
// filled one.
static const char* random_from(int64_t n, RandomSource source) {
    if (n < 0) trap_random_length(n);
    char* out = bytes_box((size_t)n);
    for (size_t got = 0; got < (size_t)n;) {
        ssize_t r = source(out + got, (size_t)n - got);
        if (r > 0) { got += (size_t)r; continue; }
        if (r < 0 && errno == EINTR) continue;
        avra_rc_release(out);
        return NULL;
    }
    return out;
}

#endif

/* @std/hash's OWN C — BLAKE3 over the vendored reference, its SIMD
   units chosen at run time. No box is minted here: a call answers a
   pointer into this thread's own buffer, copied into a `Bytes` by the
   runtime's `avra_bytes_adopted` before the next call. A hasher's state
   is a VALUE the caller holds — its octets cross in, are checked, and
   cross back out — so nothing here is freed and a copy forks honestly. */
#include <stdint.h>
#include <string.h>
#include "blake3/blake3.h"

static _Thread_local union { blake3_hasher state; uint8_t out[BLAKE3_OUT_LEN]; } held;

/* A state's octets as a hasher, or 0 for octets no hasher holds. A
   state crosses as a value, so it may be forged: every index the hasher
   computes from it stays inside its arrays. The buffer and the stack
   fit theirs; the chunk count stays under 2^53, so a merged stack is
   short enough for a push, for any input a Bytes can hold; a nonempty
   stack follows a chunk, so a merge reads no CV below the first; and an
   empty chunk never stands over a single CV, which `finalize` would
   read below the first. */
static int restored(blake3_hasher* h, const uint8_t* b, int64_t n) {
    if (n != (int64_t)sizeof *h) return 0;
    memcpy(h, b, sizeof *h);
    uint64_t chunks = h->chunk.chunk_counter;
    size_t cvs = h->cv_stack_len;
    int empty = h->chunk.buf_len == 0 && h->chunk.blocks_compressed == 0;
    return h->chunk.buf_len <= BLAKE3_BLOCK_LEN
        && cvs <= BLAKE3_MAX_DEPTH + 1
        && chunks < ((uint64_t)1 << 53)
        && (cvs == 0 || chunks > 0)
        && !(cvs == 1 && empty);
}

/* A state's length in octets. */
int64_t avra_b3_state_len(void) { return (int64_t)sizeof(blake3_hasher); }

/* A fresh state. */
const void* avra_b3_fresh(void) {
    blake3_hasher_init(&held.state);
    return &held.state;
}

/* The state after `n` more octets, or null when `state` is none. */
const void* avra_b3_update(const uint8_t* state, int64_t sn, const uint8_t* in, int64_t n) {
    blake3_hasher h;
    if (n < 0 || !restored(&h, state, sn)) return NULL;
    blake3_hasher_update(&h, in, (size_t)n);
    held.state = h;
    return &held.state;
}

/* The 32-octet digest of everything the state has seen, or null when
   `state` is none. The state stands: more octets may follow. */
const void* avra_b3_digest(const uint8_t* state, int64_t sn) {
    blake3_hasher h;
    if (!restored(&h, state, sn)) return NULL;
    blake3_hasher_finalize(&h, held.out, BLAKE3_OUT_LEN);
    return held.out;
}

/* The 32-octet digest of `n` octets, in one call. */
const void* avra_b3_oneshot(const uint8_t* in, int64_t n) {
    if (n < 0) return NULL;
    blake3_hasher h;
    blake3_hasher_init(&h);
    blake3_hasher_update(&h, in, (size_t)n);
    blake3_hasher_finalize(&h, held.out, BLAKE3_OUT_LEN);
    return held.out;
}

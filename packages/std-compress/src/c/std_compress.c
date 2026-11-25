/* @std/compress's OWN C — one-shot encoding and BOUNDED decoding over
   the vendored zlib and brotli. No box is minted here: every call
   answers a JOB this file owns — its octets, or why there are none —
   read by the caller, copied into a `Bytes` by the runtime's
   `avra_bytes_adopted`, then freed. No job at all (0) answers only
   when memory ran out before one existed. */

#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "zlib/zlib.h"
#include <brotli/encode.h>
#include <brotli/decode.h>

enum { FORMAT_GZIP = 1, FORMAT_ZLIB = 2, FORMAT_BROTLI = 3 };

/* Why a job holds no octets: 0 it does, 1 the input is not that
   format, 2 it holds more than the ceiling, 3 it ends before its
   stream does, 4 memory ran out. */
enum { DONE = 0, FAIL_CORRUPT = 1, FAIL_TOO_LARGE = 2, FAIL_TRUNCATED = 3, FAIL_MEMORY = 4 };

typedef struct { unsigned char* data; size_t len; size_t cap; int64_t failure; } Job;

static Job* job_new(size_t cap) {
    Job* j = malloc(sizeof *j);
    if (!j) return NULL;
    j->len = 0;
    j->failure = DONE;
    j->cap = cap ? cap : 1;
    j->data = malloc(j->cap);
    if (!j->data) { free(j); return NULL; }
    return j;
}

static void job_free(Job* j) { if (j) { free(j->data); free(j); } }

/* The job emptied, carrying why. */
static Job* failed(Job* j, int64_t why) {
    j->len = 0;
    j->failure = why;
    return j;
}

/* Room for at least one more octet, never past `ceiling + 1`: the one
   octet past the ceiling is how an over-long output is seen without
   producing it. 0 when the ceiling leaves none, -1 when memory ran out. */
static int grown(Job* j, size_t ceiling) {
    if (j->len < j->cap) return 1;
    size_t want = j->cap * 2;
    if (want > ceiling + 1) want = ceiling + 1;
    if (want <= j->cap) return 0;
    unsigned char* d = realloc(j->data, want);
    if (!d) return -1;
    j->data = d;
    j->cap = want;
    return 1;
}

/* zlib counts in 32 bits; a larger run is handed over a window at a time. */
static uInt window32(size_t n) { return n > UINT_MAX ? UINT_MAX : (uInt)n; }

/* A decode's first buffer: twice its input, at least a page's worth,
   never past the one octet over the ceiling. */
static size_t first_cap(size_t n, size_t ceiling) {
    size_t c = n > SIZE_MAX / 2 ? SIZE_MAX : n * 2;
    if (c < 4096) c = 4096;
    return c > ceiling + 1 ? ceiling + 1 : c;
}

/* The smallest window, as a power of two between `lo` and `hi`, that
   holds `n` octets: a window past the input costs its allocation and
   its clearing on every call and finds nothing more to match. */
static int window_for(size_t n, int lo, int hi) {
    int bits = lo;
    while (bits < hi && ((size_t)1 << bits) < n) bits++;
    return bits;
}

/* zlib's wrapping: 15 bits for any reader, gzip's header asked by +16. */
static int window_bits(int64_t format) { return format == FORMAT_GZIP ? 15 + 16 : 15; }

static Job* zlib_encode(int64_t format, int level, const unsigned char* in, size_t n) {
    z_stream s;
    memset(&s, 0, sizeof s);
    int bits = window_for(n, 9, 15);
    int mem = bits - 6 < 1 ? 1 : (bits - 6 > 8 ? 8 : bits - 6);
    if (deflateInit2(&s, level, Z_DEFLATED, format == FORMAT_GZIP ? bits + 16 : bits, mem, Z_DEFAULT_STRATEGY) != Z_OK) return NULL;
    Job* j = job_new(deflateBound(&s, (uLong)n));
    if (!j) { deflateEnd(&s); return NULL; }
    s.next_in = (Bytef*)in;
    size_t left = n;
    int r = Z_OK;
    while (r == Z_OK) {
        s.avail_in = window32(left);
        left -= s.avail_in;
        s.next_out = j->data + j->len;
        s.avail_out = window32(j->cap - j->len);
        r = deflate(&s, left ? Z_NO_FLUSH : Z_FINISH);
        j->len = (size_t)((unsigned char*)s.next_out - j->data);
        left += s.avail_in;
    }
    deflateEnd(&s);
    return r == Z_STREAM_END ? j : failed(j, FAIL_MEMORY);
}

static Job* zlib_decode(int64_t format, const unsigned char* in, size_t n, size_t ceiling) {
    z_stream s;
    memset(&s, 0, sizeof s);
    if (inflateInit2(&s, window_bits(format)) != Z_OK) return NULL;
    Job* j = job_new(first_cap(n, ceiling));
    if (!j) { inflateEnd(&s); return NULL; }
    s.next_in = (Bytef*)in;
    size_t left = n;
    int64_t why = DONE;
    for (;;) {
        int g = grown(j, ceiling);
        if (g <= 0) { why = g < 0 ? FAIL_MEMORY : FAIL_TOO_LARGE; break; }
        s.avail_in = window32(left);
        left -= s.avail_in;
        s.next_out = j->data + j->len;
        s.avail_out = window32(j->cap - j->len);
        int r = inflate(&s, Z_NO_FLUSH);
        j->len = (size_t)((unsigned char*)s.next_out - j->data);
        left += s.avail_in;
        if (j->len > ceiling) { why = FAIL_TOO_LARGE; break; }
        if (r == Z_STREAM_END) { why = left ? FAIL_CORRUPT : DONE; break; }
        if (r == Z_BUF_ERROR && left == 0 && s.avail_out != 0) { why = FAIL_TRUNCATED; break; }
        if (r != Z_OK && r != Z_BUF_ERROR) { why = r == Z_MEM_ERROR ? FAIL_MEMORY : FAIL_CORRUPT; break; }
    }
    inflateEnd(&s);
    return why == DONE ? j : failed(j, why);
}

static Job* brotli_encode(int quality, const unsigned char* in, size_t n) {
    size_t cap = BrotliEncoderMaxCompressedSize(n);
    Job* j = job_new(cap ? cap : n + 1024);
    if (!j) return NULL;
    size_t out = j->cap;
    int lgwin = window_for(n, BROTLI_MIN_WINDOW_BITS, BROTLI_DEFAULT_WINDOW);
    if (!BrotliEncoderCompress(quality, lgwin, BROTLI_MODE_GENERIC, n, in, &out, j->data)) return failed(j, FAIL_MEMORY);
    j->len = out;
    return j;
}

static Job* brotli_decode(const unsigned char* in, size_t n, size_t ceiling) {
    BrotliDecoderState* s = BrotliDecoderCreateInstance(NULL, NULL, NULL);
    if (!s) return NULL;
    Job* j = job_new(first_cap(n, ceiling));
    if (!j) { BrotliDecoderDestroyInstance(s); return NULL; }
    const uint8_t* next_in = in;
    size_t avail_in = n;
    int64_t why = DONE;
    for (;;) {
        int g = grown(j, ceiling);
        if (g <= 0) { why = g < 0 ? FAIL_MEMORY : FAIL_TOO_LARGE; break; }
        uint8_t* next_out = j->data + j->len;
        size_t avail_out = j->cap - j->len;
        BrotliDecoderResult r = BrotliDecoderDecompressStream(s, &avail_in, &next_in, &avail_out, &next_out, NULL);
        j->len = j->cap - avail_out;
        if (j->len > ceiling) { why = FAIL_TOO_LARGE; break; }
        if (r == BROTLI_DECODER_RESULT_SUCCESS) { why = avail_in ? FAIL_CORRUPT : DONE; break; }
        if (r == BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT) { why = FAIL_TRUNCATED; break; }
        if (r == BROTLI_DECODER_RESULT_ERROR) { why = FAIL_CORRUPT; break; }
    }
    BrotliDecoderDestroyInstance(s);
    return why == DONE ? j : failed(j, why);
}

/* ── Incremental encoding ─────────────────────────────────────────
   A coder holds ONE stream's state and the octets it has produced
   since the caller last took them: `push` each piece with a flush,
   take what came out, `finish` for the trailer. Unlike a Job, a coder
   outlives a call — its state is the point — and is freed once. */

typedef struct {
    int format;
    z_stream zs;
    BrotliEncoderState* bs;
    unsigned char* data;
    size_t len, cap;
    int failure;
} Coder;

static int coder_room(Coder* c, size_t want) {
    if (c->len + want <= c->cap) return 1;
    size_t cap = c->cap ? c->cap : 4096;
    while (cap < c->len + want) cap *= 2;
    unsigned char* d = realloc(c->data, cap);
    if (!d) { c->failure = FAIL_MEMORY; return 0; }
    c->data = d;
    c->cap = cap;
    return 1;
}

static Coder* coder_new(int64_t format, int64_t level) {
    Coder* c = calloc(1, sizeof *c);
    if (!c) return NULL;
    c->format = (int)format;
    if (format == FORMAT_BROTLI) {
        c->bs = BrotliEncoderCreateInstance(NULL, NULL, NULL);
        if (!c->bs) { free(c); return NULL; }
        BrotliEncoderSetParameter(c->bs, BROTLI_PARAM_QUALITY, (uint32_t)level);
    } else if (deflateInit2(&c->zs, (int)level, Z_DEFLATED, format == FORMAT_GZIP ? 31 : 15, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        free(c);
        return NULL;
    }
    return c;
}

static void coder_free(Coder* c) {
    if (!c) return;
    if (c->format == FORMAT_BROTLI) { if (c->bs) BrotliEncoderDestroyInstance(c->bs); }
    else deflateEnd(&c->zs);
    free(c->data);
    free(c);
}

/* One run of the stream: `op` is zlib's flush (NO/SYNC/FINISH). 1 while
   the run holds or the stream ended, 0 on a failure.
   A BROTLI FLUSH IS AN OPERATION, NOT A ZLIB ONE. */
static int coder_run(Coder* c, const unsigned char* in, size_t n, int op) {
    if (c->format == FORMAT_BROTLI) {
        BrotliEncoderOperation bop = op == Z_FINISH ? BROTLI_OPERATION_FINISH : BROTLI_OPERATION_FLUSH;
        const uint8_t* next_in = in;
        size_t avail_in = n;
        for (;;) {
            if (!coder_room(c, 4096)) return 0;
            uint8_t* next_out = c->data + c->len;
            size_t avail_out = c->cap - c->len;
            if (!BrotliEncoderCompressStream(c->bs, bop, &avail_in, &next_in, &avail_out, &next_out, NULL)) {
                c->failure = FAIL_MEMORY;
                return 0;
            }
            c->len = c->cap - avail_out;
            if (BrotliEncoderIsFinished(c->bs)) return 1;
            if (avail_in == 0 && !BrotliEncoderHasMoreOutput(c->bs)) return 1;
        }
    }
    c->zs.next_in = (Bytef*)in;
    size_t left = n;
    for (;;) {
        c->zs.avail_in = window32(left);
        left -= c->zs.avail_in;
        if (!coder_room(c, 4096)) return 0;
        c->zs.next_out = c->data + c->len;
        c->zs.avail_out = window32(c->cap - c->len);
        int r = deflate(&c->zs, left ? Z_NO_FLUSH : op);
        c->len = (size_t)((unsigned char*)c->zs.next_out - c->data);
        left += c->zs.avail_in;
        if (r == Z_STREAM_END) return 1;
        if (r != Z_OK) { c->failure = r == Z_MEM_ERROR ? FAIL_MEMORY : FAIL_CORRUPT; return 0; }
        if (left == 0 && c->zs.avail_out != 0) return 1;
    }
}

/* A coder crosses as an int, as a Job does. */
static int64_t coder_handed(Coder* c) { return (int64_t)(intptr_t)c; }
static Coder* coder_held(int64_t c) { return (Coder*)(intptr_t)c; }

/* One stream's encoder for `format` at `level`. */
int64_t avra_cz_stream(int64_t format, int64_t level) { return coder_handed(coder_new(format, level)); }

/* `n` octets of `in` fed with a flush; 0 taken, else why. */
int64_t avra_cz_push(int64_t coder, const unsigned char* in, int64_t n) {
    if (n < 0) return FAIL_CORRUPT;
    Coder* c = coder_held(coder);
    return coder_run(c, in, (size_t)n, Z_SYNC_FLUSH) ? 0 : c->failure;
}

/* The stream ended: the trailer's octets, appended; 0 taken, else why. */
int64_t avra_cz_finish(int64_t coder) {
    Coder* c = coder_held(coder);
    return coder_run(c, NULL, 0, Z_FINISH) ? 0 : c->failure;
}

int64_t avra_cz_stream_len(int64_t coder) { return (int64_t)coder_held(coder)->len; }
void* avra_cz_stream_at(int64_t coder) { Coder* c = coder_held(coder); return c->len ? c->data : NULL; }

/* The octets taken: the buffer emptied, the stream's state untouched. */
int64_t avra_cz_stream_clear(int64_t coder) { coder_held(coder)->len = 0; return 0; }

int64_t avra_cz_stream_free(int64_t coder) { coder_free(coder_held(coder)); return 0; }

/* A job crosses as an int — its address, 0 for none — so Avra never
   holds a pointer that carries no header of ours. */
static int64_t handed(Job* j) { return (int64_t)(intptr_t)j; }
static Job* held(int64_t job) { return (Job*)(intptr_t)job; }

/* `n` octets of `in` encoded in `format` at `level` (zlib 0-9, brotli
   0-11). */
int64_t avra_cz_encode(int64_t format, int64_t level, const unsigned char* in, int64_t n) {
    if (n < 0) return 0;
    if (format == FORMAT_BROTLI) return handed(brotli_encode((int)level, in, (size_t)n));
    return handed(zlib_encode(format, (int)level, in, (size_t)n));
}

/* `n` octets of `in` decoded from `format`, holding at most `ceiling`. */
int64_t avra_cz_decode(int64_t format, const unsigned char* in, int64_t n, int64_t ceiling) {
    if (n < 0 || ceiling < 0) return 0;
    if (format == FORMAT_BROTLI) return handed(brotli_decode(in, (size_t)n, (size_t)ceiling));
    return handed(zlib_decode(format, in, (size_t)n, (size_t)ceiling));
}

int64_t avra_cz_failure(int64_t job) { return held(job)->failure; }
int64_t avra_cz_len(int64_t job) { return (int64_t)held(job)->len; }
void* avra_cz_at(int64_t job) { return held(job)->len ? held(job)->data : NULL; }
int64_t avra_cz_free(int64_t job) { job_free(held(job)); return 0; }

// THE C ROWS THE FRAMERS STAND ON, UNDER libFuzzer: every scan the
// framer spells as a class-table run, a search, a compare, a slice or
// a join is a runtime row over a headered box, and each is held here
// to a naive walk of the same bytes. A row that disagrees with the
// walk, or reads outside its box (AddressSanitizer), is the finding.
//
// Input: one selector octet, two offset octets, then the bytes — the
// first half the haystack, the rest the needle, and the class table
// drawn from the selector.
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

void* avra_array_new(void);
void avra_array_push(void* arr, int64_t v);
void avra_rc_release(void* p);
const char* avra_bytes_of_list(void* arr);
int64_t avra_bytes_len(const char* b);
int64_t avra_bytes_index_of(const char* b, const char* needle, int64_t from);
int64_t avra_bytes_run(const char* b, int64_t from, const char* table);
int64_t avra_bytes_eq_at(const char* b, int64_t lo, int64_t hi, const char* needle);
int64_t avra_bytes_ieq_at(const char* b, int64_t lo, int64_t hi, const char* needle);
const char* avra_bytes_slice(const char* b, int64_t lo, int64_t hi);
const char* avra_bytes_concat(const char* a, const char* b);
int64_t avra_utf8_bad_at(const char* b);

// A headered box holding exactly these octets.
static const char* boxed(const uint8_t* p, size_t n) {
    void* arr = avra_array_new();
    for (size_t i = 0; i < n; i++) avra_array_push(arr, p[i]);
    const char* b = avra_bytes_of_list(arr);
    avra_rc_release(arr);
    return b;
}

static int64_t naive_index_of(const uint8_t* h, int64_t n, const uint8_t* s, int64_t m, int64_t from) {
    if (m == 0) return from;
    for (int64_t i = from; i + m <= n; i++)
        if (memcmp(h + i, s, (size_t)m) == 0) return i;
    return -1;
}

static uint8_t lower(uint8_t c) { return c >= 'A' && c <= 'Z' ? c + 32 : c; }

// The first offset that is not UTF-8, decoding a code point at a time.
static int64_t naive_utf8_bad_at(const uint8_t* p, int64_t n) {
    int64_t i = 0;
    while (i < n) {
        uint32_t c = p[i];
        int need = c < 0x80 ? 0 : (c & 0xE0) == 0xC0 ? 1 : (c & 0xF0) == 0xE0 ? 2 : (c & 0xF8) == 0xF0 ? 3 : -1;
        if (need < 0 || i + need >= n) return i;
        uint32_t cp = need == 0 ? c : need == 1 ? c & 0x1F : need == 2 ? c & 0x0F : c & 0x07;
        for (int k = 1; k <= need; k++) {
            if ((p[i + k] & 0xC0) != 0x80) return i;
            cp = (cp << 6) | (p[i + k] & 0x3F);
        }
        uint32_t least = need == 1 ? 0x80 : need == 2 ? 0x800 : need == 3 ? 0x10000 : 0;
        if (cp < least || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) return i;
        i += need + 1;
    }
    return -1;
}

int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    if (size < 3) return 0;
    uint8_t sel = data[0];
    const uint8_t* rest = data + 3;
    int64_t len = (int64_t)size - 3;
    int64_t hn = len / 2 + (sel & 1) * (len % 2);
    const uint8_t* s = rest + hn;
    int64_t sn = len - hn;
    const char* h = boxed(rest, (size_t)hn);
    const char* nd = boxed(s, (size_t)sn);
    int64_t a = hn ? data[1] % (hn + 1) : 0, z = hn ? data[2] % (hn + 1) : 0;
    int64_t lo = a < z ? a : z, hi = a < z ? z : a;
    if (avra_bytes_len(h) != hn || avra_bytes_len(nd) != sn) abort();

    if (avra_bytes_index_of(h, nd, lo) != naive_index_of(rest, hn, s, sn, lo)) abort();

    uint8_t table[256];
    for (int c = 0; c < 256; c++) table[c] = (uint8_t)(((c * (sel | 1)) >> 3 ^ sel) & 1);
    const char* t = boxed(table, 256);
    int64_t run = lo;
    while (run < hn && table[rest[run]]) run++;
    if (avra_bytes_run(h, lo, t) != run) abort();

    int64_t eq = hi - lo == sn && memcmp(rest + lo, s, (size_t)sn) == 0;
    if (avra_bytes_eq_at(h, lo, hi, nd) != eq) abort();
    int64_t ieq = hi - lo == sn;
    for (int64_t i = 0; ieq && i < sn; i++) ieq = lower(rest[lo + i]) == lower(s[i]);
    if (avra_bytes_ieq_at(h, lo, hi, nd) != ieq) abort();

    const char* sl = avra_bytes_slice(h, lo, hi);
    if (avra_bytes_len(sl) != hi - lo || memcmp(sl, rest + lo, (size_t)(hi - lo)) != 0) abort();
    const char* joined = avra_bytes_concat(h, nd);
    if (avra_bytes_len(joined) != len || memcmp(joined, rest, (size_t)hn) != 0 || memcmp(joined + hn, s, (size_t)sn) != 0) abort();

    if (avra_utf8_bad_at(h) != naive_utf8_bad_at(rest, hn)) abort();

    avra_rc_release((void*)joined);
    avra_rc_release((void*)sl);
    avra_rc_release((void*)t);
    avra_rc_release((void*)nd);
    avra_rc_release((void*)h);
    return 0;
}

// THE CONTENT DIGEST ROW: SHA-256 over a Bytes box, against the
// published vectors. No Avra source declares the row yet — this is
// the only place it runs before that.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../avra_runtime.h"

const char* avra_sha256(const char* b);
const char* avra_bytes_adopted(const void* p, int64_t n);
int64_t avra_bytes_len(const char* b);

static int g_checks = 0, g_fails = 0;

static void hex(const char* d, char out[65]) {
    for (int i = 0; i < 32; i++) sprintf(out + 2 * i, "%02x", (unsigned char)d[i]);
}

static void digests(const char* what, const void* p, size_t n, const char* want) {
    const char* d = avra_sha256(avra_bytes_adopted(p, (int64_t)n));
    char got[65];
    hex(d, got);
    g_checks++;
    if (avra_bytes_len(d) != 32 || strcmp(got, want) != 0) {
        g_fails++;
        fprintf(stderr, "sha256_test: FAILED %s\n  got  %s\n  want %s\n", what, got, want);
    }
}

// The digest of `n` copies of one octet.
static void digests_run(const char* what, char c, size_t n, const char* want) {
    char* p = malloc(n ? n : 1);
    memset(p, c, n);
    digests(what, p, n, want);
    free(p);
}

int main(void) {
    digests("the empty input", "", 0, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    digests("abc", "abc", 3, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    digests("the 448-bit NIST vector", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56,
            "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    digests("the 896-bit NIST vector",
            "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", 112,
            "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1");
    digests("an interior NUL", "a\0b", 3, "59b271ae1bbcb1d31d41929817f4b16fb439eb4f31520b5ad1d5ce98920a7138");
    digests_run("a million a's", 'a', 1000000, "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0");
    digests_run("55 octets: one padded block", 'a', 55, "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318");
    digests_run("56 octets: the length spills into a second block", 'a', 56, "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a");
    digests_run("64 octets: a whole block and a padding block", 'a', 64, "ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb");
    if (g_fails) {
        fprintf(stderr, "sha256_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("sha256_test: %d checks\n", g_checks);
    return 0;
}

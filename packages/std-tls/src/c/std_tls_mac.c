/* @std/tls's message authentication: HMAC-SHA256 over the vendored
   engine's SHA-256, and a comparison whose time does not depend on
   where two MACs first differ. Its own translation unit, archived
   apart from the sessions, so a program that only signs links no
   handshake.  */

#include <stdint.h>
#include <stddef.h>

#include "psa/crypto.h"

enum { MAC_ERR_BOUNDS = -0x10003, MAC_ERR_CRYPTO = -0x10005 };

static unsigned char g_mac[32];

/* HMAC-SHA256 of `msg` under `key`, landed where `avra_tls_mac_at`
   points: its length, 32, or a negative code. An empty key is the key
   of one zero byte, which HMAC pads to the same block (RFC 2104 §2);
   the PSA core refuses to import an empty one. */
int64_t avra_tls_hmac_sha256(const unsigned char* key, int64_t key_n, const unsigned char* msg, int64_t msg_n) {
    static const unsigned char zero = 0;
    if (key_n < 0 || msg_n < 0) return MAC_ERR_BOUNDS;
    if (psa_crypto_init() != PSA_SUCCESS) return MAC_ERR_CRYPTO;
    psa_key_attributes_t at = PSA_KEY_ATTRIBUTES_INIT;
    psa_set_key_type(&at, PSA_KEY_TYPE_HMAC);
    psa_set_key_usage_flags(&at, PSA_KEY_USAGE_SIGN_MESSAGE);
    psa_set_key_algorithm(&at, PSA_ALG_HMAC(PSA_ALG_SHA_256));
    psa_key_id_t id;
    if (psa_import_key(&at, key_n ? key : &zero, key_n ? (size_t)key_n : 1, &id) != PSA_SUCCESS) return MAC_ERR_CRYPTO;
    size_t len = 0;
    psa_status_t st = psa_mac_compute(id, PSA_ALG_HMAC(PSA_ALG_SHA_256), msg, (size_t)msg_n, g_mac, sizeof g_mac, &len);
    psa_destroy_key(id);
    return st == PSA_SUCCESS ? (int64_t)len : MAC_ERR_CRYPTO;
}

const unsigned char* avra_tls_mac_at(void) { return g_mac; }

/* 1 when `a` and `b` hold the same bytes, else 0: every byte of equal
   lengths is read whatever it holds. A length is not secret. */
int64_t avra_tls_same(const unsigned char* a, int64_t a_n, const unsigned char* b, int64_t b_n) {
    if (a_n != b_n || a_n < 0) return 0;
    volatile unsigned char diff = 0;
    for (int64_t i = 0; i < a_n; i++) diff |= a[i] ^ b[i];
    return diff == 0;
}

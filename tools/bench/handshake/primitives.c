// The primitives a TLS 1.3 handshake spends, one at a time, through PSA:
// what each costs is where a faster driver would pay.
#include <psa/crypto.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static double now_us(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e6 + t.tv_nsec / 1e3;
}

#define TIMED(label, n, body) do { double t0 = now_us(); for (int i = 0; i < (n); i++) { body; } \
    printf("%-28s %9.1f us\n", label, (now_us() - t0) / (n)); } while (0)

static psa_key_id_t keypair(psa_key_type_t type, size_t bits, psa_algorithm_t alg, psa_key_usage_t usage) {
    psa_key_attributes_t a = PSA_KEY_ATTRIBUTES_INIT;
    psa_set_key_type(&a, type);
    psa_set_key_bits(&a, bits);
    psa_set_key_algorithm(&a, alg);
    psa_set_key_usage_flags(&a, usage);
    psa_key_id_t k = 0;
    if (psa_generate_key(&a, &k) != PSA_SUCCESS) { puts("generate failed"); return 0; }
    return k;
}

static void agree(const char* label, psa_ecc_family_t fam, size_t bits, int n) {
    psa_key_type_t t = PSA_KEY_TYPE_ECC_KEY_PAIR(fam);
    psa_key_id_t peer = keypair(t, bits, PSA_ALG_ECDH, PSA_KEY_USAGE_DERIVE);
    uint8_t pub[133], out[66];
    size_t pn = 0, on = 0;
    psa_export_public_key(peer, pub, sizeof(pub), &pn);
    char l1[64], l2[64];
    snprintf(l1, sizeof(l1), "%s keygen+public", label);
    snprintf(l2, sizeof(l2), "%s agree", label);
    TIMED(l1, n, { psa_key_id_t k = keypair(t, bits, PSA_ALG_ECDH, PSA_KEY_USAGE_DERIVE);
                   psa_export_public_key(k, pub, sizeof(pub), &pn); psa_destroy_key(k); });
    psa_export_public_key(peer, pub, sizeof(pub), &pn);
    psa_key_id_t mine = keypair(t, bits, PSA_ALG_ECDH, PSA_KEY_USAGE_DERIVE);
    TIMED(l2, n, { psa_raw_key_agreement(PSA_ALG_ECDH, mine, pub, pn, out, sizeof(out), &on); });
}

int main(void) {
    psa_crypto_init();
    int n = 200;
    agree("x25519", PSA_ECC_FAMILY_MONTGOMERY, 255, n);
    agree("p256 ecdh", PSA_ECC_FAMILY_SECP_R1, 256, n);
    psa_algorithm_t sig = PSA_ALG_ECDSA(PSA_ALG_SHA_256);
    psa_key_id_t k = keypair(PSA_KEY_TYPE_ECC_KEY_PAIR(PSA_ECC_FAMILY_SECP_R1), 256, sig,
                             PSA_KEY_USAGE_SIGN_HASH | PSA_KEY_USAGE_VERIFY_HASH);
    uint8_t hash[32] = {1}, s[64];
    size_t sn = 0;
    TIMED("p256 ecdsa sign", n, { psa_sign_hash(k, sig, hash, 32, s, sizeof(s), &sn); });
    TIMED("p256 ecdsa verify", n, { psa_verify_hash(k, sig, hash, 32, s, sn); });
    static uint8_t buf[16384], mac[32];
    size_t mn = 0;
    TIMED("sha256 16 KiB", n, { psa_hash_compute(PSA_ALG_SHA_256, buf, sizeof(buf), mac, 32, &mn); });
    psa_key_attributes_t a = PSA_KEY_ATTRIBUTES_INIT;
    psa_set_key_type(&a, PSA_KEY_TYPE_AES);
    psa_set_key_bits(&a, 128);
    psa_set_key_algorithm(&a, PSA_ALG_GCM);
    psa_set_key_usage_flags(&a, PSA_KEY_USAGE_ENCRYPT);
    psa_key_id_t aes = 0;
    uint8_t key[16] = {2}, nonce[12] = {3};
    psa_import_key(&a, key, 16, &aes);
    static uint8_t ct[16384 + 16];
    size_t cn = 0;
    TIMED("aes128-gcm seal 16 KiB", n, { psa_aead_encrypt(aes, PSA_ALG_GCM, nonce, 12, NULL, 0, buf, sizeof(buf), ct, sizeof(ct), &cn); });
    return 0;
}

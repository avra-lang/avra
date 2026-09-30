#!/bin/sh
# THE VENDORED mbedTLS, made from its release tarball and nothing else.
# Re-run to upgrade: it replaces vendor/mbedtls/ and every unit wrapper,
# so what is checked in is always this script's output.
#
#   sh packages/std-tls/vendor/import.sh mbedtls-4.1.1.tar.bz2
#
# ONE OBJECT PER UPSTREAM UNIT. Each wrapper includes one upstream .c
# and nothing else, so every unit compiles exactly as upstream compiles
# it — a unity build lets one unit's macros and header guards reach the
# next. The wrapper's name gives the object a stem unique tree-wide.
#
# THE UNITS ARE THE ONES THE CONFIG COMPILES: a unit src/c's two config
# headers leave empty is not vendored, except aesni.c, empty on arm64
# and the AES instructions on x86-64.
set -eu
tarball=$1
version=4.1.1
sha256=3359a349e23db3d5536fcee032ae7b2ecbfc08972fab643089b5cbf2a375c98c
here=$(cd "$(dirname "$0")" && pwd)

got=$(shasum -a 256 "$tarball" | cut -d' ' -f1)
if [ "$got" != "$sha256" ]; then
    echo "import: $tarball is not mbedtls-$version (sha256 $got)" >&2
    exit 1
fi

units="
    library/error.c
    library/mps_reader.c
    library/ssl_ciphersuites.c
    library/ssl_client.c
    library/ssl_msg.c
    library/ssl_ticket.c
    library/ssl_tls.c
    library/ssl_tls12_client.c
    library/ssl_tls12_server.c
    library/ssl_tls13_client.c
    library/ssl_tls13_generic.c
    library/ssl_tls13_keys.c
    library/ssl_tls13_server.c
    library/x509_crt.c
    library/x509_oid.c
    library/x509.c
    tf-psa-crypto/core/psa_crypto_client.c
    tf-psa-crypto/core/psa_crypto_driver_wrappers_no_static.c
    tf-psa-crypto/core/psa_crypto_random.c
    tf-psa-crypto/core/psa_crypto_slot_management.c
    tf-psa-crypto/core/psa_crypto.c
    tf-psa-crypto/core/psa_util.c
    tf-psa-crypto/drivers/builtin/src/aes.c
    tf-psa-crypto/drivers/builtin/src/aesce.c
    tf-psa-crypto/drivers/builtin/src/aesni.c
    tf-psa-crypto/drivers/builtin/src/bignum_core.c
    tf-psa-crypto/drivers/builtin/src/bignum.c
    tf-psa-crypto/drivers/builtin/src/block_cipher.c
    tf-psa-crypto/drivers/builtin/src/chacha20_neon.c
    tf-psa-crypto/drivers/builtin/src/chacha20.c
    tf-psa-crypto/drivers/builtin/src/chachapoly.c
    tf-psa-crypto/drivers/builtin/src/ctr_drbg.c
    tf-psa-crypto/drivers/builtin/src/ecdsa.c
    tf-psa-crypto/drivers/builtin/src/ecp_curves.c
    tf-psa-crypto/drivers/builtin/src/ecp.c
    tf-psa-crypto/drivers/builtin/src/entropy_poll.c
    tf-psa-crypto/drivers/builtin/src/entropy.c
    tf-psa-crypto/drivers/builtin/src/gcm.c
    tf-psa-crypto/drivers/builtin/src/hmac_drbg.c
    tf-psa-crypto/drivers/builtin/src/poly1305.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_aead.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_cipher.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_ecp.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_hash.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_mac.c
    tf-psa-crypto/drivers/builtin/src/psa_crypto_rsa.c
    tf-psa-crypto/drivers/builtin/src/psa_util_internal.c
    tf-psa-crypto/drivers/builtin/src/rsa_alt_helpers.c
    tf-psa-crypto/drivers/builtin/src/rsa.c
    tf-psa-crypto/drivers/builtin/src/sha256.c
    tf-psa-crypto/drivers/builtin/src/sha512.c
    tf-psa-crypto/extras/md.c
    tf-psa-crypto/extras/pk_ecc.c
    tf-psa-crypto/extras/pk_rsa.c
    tf-psa-crypto/extras/pk_wrap.c
    tf-psa-crypto/extras/pk.c
    tf-psa-crypto/extras/pkparse.c
    tf-psa-crypto/extras/pkwrite.c
    tf-psa-crypto/platform/platform_util.c
    tf-psa-crypto/platform/platform.c
    tf-psa-crypto/utilities/asn1parse.c
    tf-psa-crypto/utilities/asn1write.c
    tf-psa-crypto/utilities/base64.c
    tf-psa-crypto/utilities/constant_time.c
    tf-psa-crypto/utilities/oid.c
    tf-psa-crypto/utilities/pem.c
"

scratch=$(mktemp -d)
trap 'rm -r "$scratch"' EXIT
tar -xjf "$tarball" -C "$scratch"
src=$scratch/mbedtls-$version
out=$here/mbedtls

rm -rf "$out" "$here"/mbedtls_*.c
mkdir -p "$out"
cp "$src/LICENSE" "$out/LICENSE"
cp -R "$src/include" "$out/include"
mkdir -p "$out/tf-psa-crypto/drivers/builtin"
cp -R "$src/tf-psa-crypto/include" "$out/tf-psa-crypto/include"
cp -R "$src/tf-psa-crypto/drivers/builtin/include" "$out/tf-psa-crypto/drivers/builtin/include"
for d in library tf-psa-crypto/core tf-psa-crypto/dispatch tf-psa-crypto/drivers/builtin/src \
         tf-psa-crypto/extras tf-psa-crypto/platform tf-psa-crypto/utilities; do
    mkdir -p "$out/$d"
    cp "$src/$d"/*.h "$out/$d/"
done
for u in $units; do
    cp "$src/$u" "$out/$u"
    printf '#include "mbedtls/%s"\n' "$u" > "$here/mbedtls_$(basename "$u")"
done
echo "import: mbedtls-$version, $(echo $units | wc -w | tr -d ' ') units"

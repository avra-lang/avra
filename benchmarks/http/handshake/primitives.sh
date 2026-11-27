#!/bin/sh
# The TLS primitives, timed one by one through PSA against the vendored
# mbedTLS (build/std_tls.a): where a handshake's CPU goes.
#   sh benchmarks/http/handshake/primitives.sh
set -eu
cd "$(dirname "$0")/../../.."
make --no-print-directory -o avra build/std_tls.a > /dev/null
m=packages/std-tls/vendor/mbedtls
out=build/tls-primitives
cc -O2 -I$m/include -I$m/tf-psa-crypto/include -I$m/tf-psa-crypto/drivers/builtin/include \
    -Ipackages/std-tls/src/c '-DTF_PSA_CRYPTO_CONFIG_FILE="std_tls_crypto_config.h"' \
    '-DMBEDTLS_CONFIG_FILE="std_tls_ssl_config.h"' \
    benchmarks/http/handshake/primitives.c build/std_tls.a -o "$out"
"$out"

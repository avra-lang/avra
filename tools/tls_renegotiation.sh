#!/bin/sh
# A TLS 1.2 peer that asks to renegotiate fails the server's read, naming
# it — the signal HTTP/2 ends its connection on (RFC 9113 §9.2.1). The
# peer is `openssl s_client`; skips, saying so, when openssl is absent.
# The server is this script's child and is killed when it exits.
set -u
if ! command -v openssl > /dev/null 2>&1; then
    echo "renegotiation: openssl not on the PATH — skipped"
    exit 0
fi
out=build/tls_renegotiation
mkdir -p "$out"
build/avra build tools/tls_renegotiation > "$out/build.log" 2>&1 || { tail -20 "$out/build.log"; exit 1; }
pid=
stop() { [ -n "$pid" ] && kill "$pid" 2> /dev/null; }
trap stop EXIT
trap 'stop; exit 1' INT TERM
port=$((20000 + $$ % 20000))
RENEG_PORT=$port tools/tls_renegotiation/src/main > "$out/server.log" 2>&1 &
pid=$!
sleep 1
# `R` alone on a line asks s_client to renegotiate.
(sleep 1; printf 'R\n'; sleep 2) |
    openssl s_client -tls1_2 -connect "127.0.0.1:$port" -servername localhost > "$out/client.log" 2>&1
wait "$pid" 2> /dev/null
pid=
said=$(cat "$out/server.log")
echo "renegotiation: $said"
case "$said" in
    *"asked to renegotiate"*) exit 0 ;;
    *) exit 1 ;;
esac

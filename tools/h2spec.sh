#!/bin/sh
# h2spec (github.com/summerwind/h2spec) against std-http's HTTP/2 server,
# in the clear and over TLS, after the TLS renegotiation probe. Skips,
# saying so, when h2spec is not on the PATH. The server is this script's
# child and is killed when it exits, whatever ends it.
set -u
sh tools/tls_renegotiation.sh || exit 1
if ! command -v h2spec > /dev/null 2>&1; then
    echo "h2spec: not on the PATH — skipped (github.com/summerwind/h2spec/releases)"
    exit 0
fi
out=build/h2spec
mkdir -p "$out"
build/avra build tools/h2spec > "$out/build.log" 2>&1 || { tail -20 "$out/build.log"; exit 1; }
# The clear port speaks HTTP/1.1 AND h2c by prior knowledge, so the
# octets h2spec sends as an invalid preface (§3.5 #2) are a 1.1 request,
# answered 400. That one case is expected on h2c and no other.
only_preface() {
    [ "$(grep -c '^ *×' "$1")" = 2 ] && [ "$(grep '^ *×' "$1" | grep -vc 'invalid connection preface')" = 0 ]
}

pid=
stop() { [ -n "$pid" ] && kill "$pid" 2> /dev/null; }
trap stop EXIT
trap 'stop; exit 1' INT TERM
failed=0
port=$((20000 + $$ % 20000))
flags=
for mode in h2c tls; do
    if [ "$mode" = tls ]; then
        export H2SPEC_TLS=1
        flags="-t -k"
    fi
    H2SPEC_PORT=$port tools/h2spec/src/main > "$out/$mode.server" 2>&1 &
    pid=$!
    sleep 1
    h2spec -h 127.0.0.1 -p "$port" $flags -o 5 > "$out/$mode.log" 2>&1
    st=$?
    kill "$pid" 2> /dev/null
    wait "$pid" 2> /dev/null
    pid=
    port=$((port + 1))
    echo "h2spec $mode: $(grep -E '^[0-9]+ tests' "$out/$mode.log" | tail -1)"
    grep -E '^ *×' -A2 "$out/$mode.log" | head -6
    if [ $st -ne 0 ] && ! { [ "$mode" = h2c ] && only_preface "$out/$mode.log"; }; then failed=$((failed + 1)); fi
done
[ $failed -eq 0 ]

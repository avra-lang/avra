#!/bin/sh
# The wasm floor: build the smallest program and count what the target carries.
set -eu
. "$(dirname "$0")/lib/tree.sh"
command -v wasm-opt >/dev/null 2>&1 || { echo "wasm-size: wasm-opt (binaryen) not on PATH — skipped"; exit 0; }
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-size.XXXXXX")
cp -R "$here/wasm-min" "$work/min"
for mode in command reactor; do
    flag=""
    [ "$mode" = reactor ] && flag=--wasm_reactor
    w=$(sh "$here/capped.sh" --last "$avra" build --target wasm $flag "$work/min")
    echo "$mode: $(stat -c%s "$w") bytes  ($w)"
    wasm-objdump -h "$w" | awk '$2 ~ /^[0-9]+$/ || $1 ~ /^[A-Za-z]/ {print "  " $0}' | head -20
    echo "  printf-family funcs: $(wasm-objdump -x "$w" | grep -cE 'vfprintf|printf_core|__intscan|strtoull|__stdio')"
    echo "  custom (debug/name) bytes: $(wasm-objdump -h "$w" | awk '$1=="Custom"{s+=$5} END{print s+0}')"
done

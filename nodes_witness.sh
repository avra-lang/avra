#!/bin/sh
# nodes_witness.sh <bin> <out>: IR of every compiler feature's program test, each copied
# into one small package so a compile reads the program, not the compiler's own package;
# and the diagnostics index.
set -u
bin=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
out=$2
C=/tmp/nodes-corpus2
mkdir -p "$out/ir"
if [ ! -f "$C/.made" ]; then
    mkdir -p "$C/src"
    find packages/std-avrac/src -path '*/tests/*' -name '*.expected' | sort | while read -r e; do
        f=${e%.expected}.av
        k=$(printf %s "$f" | sed 's#packages/std-avrac/src/##' | tr / _ | sed 's/\.av$//')
        mkdir -p "$C/src/$k"
        printf '[package]\nname = "corpus"\nversion = "0.0.1"\n' > "$C/src/$k/avra.toml"
        cp "$f" "$C/src/$k/$k.av"
        cp "$e" "$C/src/$k/$k.expected"
    done
    touch "$C/.made"
fi
ls "$C/src" > "$out/programs.txt"
export BIN="$bin" OUT="$out" C
xargs -P "${WP:-3}" -I{} sh -c 'k={}; (cd "$C/src/$k" && timeout 60 "$BIN" ir "$k.av") > "$OUT/ir/$k" 2>&1; echo "exit $?" >> "$OUT/ir/$k"' < "$out/programs.txt"
timeout 600 "$bin" diagnostics > "$out/diagnostics.txt" 2> "$out/diagnostics.err"
echo "diagnostics exit $?" >> "$out/diagnostics.err"
ls "$out/ir" | wc -l

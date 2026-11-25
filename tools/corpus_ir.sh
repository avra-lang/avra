#!/bin/sh
# corpus_ir.sh <base-bin> <head-bin> [out]: the IR of every std-avrac program
# test, and the diagnostics index, under two compilers, compared.
#
# Each program is copied into a package of its own outside the tree, so a
# compile reads the program and never the compiler's package. Prints
# `IRDIFF <n> of <total>` and `DIAG-SAME` or the diagnostics diff; exits 0
# only when the IR agrees on every program.
set -u
[ $# -ge 2 ] || { echo "usage: sh tools/corpus_ir.sh <base-bin> <head-bin> [out]" >&2; exit 2; }
abs() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
base=$(abs "$1")
head=$(abs "$2")
out=${3:-build/corpus-ir}
corpus=$(mktemp -d "${TMPDIR:-/tmp}/avra-corpus.XXXXXX")

find packages/std-avrac/src -path '*/tests/*' -name '*.expected' | sort | while read -r e; do
    f=${e%.expected}.av
    k=$(printf %s "$f" | sed 's#packages/std-avrac/src/##' | tr / _ | sed 's/\.av$//')
    mkdir -p "$corpus/$k"
    printf '[package]\nname = "corpus"\nversion = "0.0.1"\n' > "$corpus/$k/avra.toml"
    cp "$f" "$corpus/$k/$k.av"
done
ls "$corpus" > "$corpus.list"

# side <bin> <dir>: one IR file per program, its exit status last; then the index.
side() {
    find "$2" -delete 2>/dev/null
    mkdir -p "$2/ir"
    BIN=$1 OUT=$2 C=$corpus xargs -P "${WP:-3}" -I{} sh -c \
        'cd "$C/{}" && { timeout 60 "$BIN" ir "{}.av"; echo "exit $?"; } > "$OUT/ir/{}" 2>&1' < "$corpus.list"
    timeout 600 "$1" diagnostics > "$2/diagnostics.txt" 2> "$2/diagnostics.err"
}
side "$base" "$out/base"
side "$head" "$out/head"

n=$(diff -rq "$out/base/ir" "$out/head/ir" | wc -l | tr -d ' ')
echo "IRDIFF $n of $(wc -l < "$corpus.list" | tr -d ' ')"
diff -rq "$out/base/ir" "$out/head/ir" | head -20
echo "nonzero exit — base: $(grep -l '^exit [1-9]' "$out"/base/ir/* | wc -l | tr -d ' ') head: $(grep -l '^exit [1-9]' "$out"/head/ir/* | wc -l | tr -d ' ')"
if cmp -s "$out/base/diagnostics.txt" "$out/head/diagnostics.txt"; then echo DIAG-SAME
else diff "$out/base/diagnostics.txt" "$out/head/diagnostics.txt" | head -60; fi
find "$corpus" "$corpus.list" -delete
[ "$n" = 0 ]

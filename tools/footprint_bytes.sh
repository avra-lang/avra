#!/bin/sh
# WHAT THE SMALLEST PROGRAMS WEIGH, as ledger rows: tools/footprint's `hello` and `data`, built as they
# ship (`--release`), each its stripped file and its code, keyed by the toolchain that decides them
# (tools/lib/toolchain.sh) and judged by `avra-tools cost` against tools/cost.baseline. STRIPPED, because
# a symbol spells the path its program was built at. A row is exact within its key; a toolchain the
# ledger holds no row of is measured and told, never gated.
#   sh tools/footprint_bytes.sh           measure and judge
#   sh tools/footprint_bytes.sh accept    measure and record: a row falls, a new key is seeded
set -eu
. "$(dirname "$0")/lib/tree.sh"
. "$here/lib/toolchain.sh"
verb=${1:-judge}
case $verb in judge | accept) ;; *) echo "footprint-bytes: judge or accept, never $verb" >&2; exit 2 ;; esac
[ -x "$avra" ] || { echo "footprint-bytes: no compiler at $avra — build it first" >&2; exit 1; }
out=$tree/build/ledger/footprint
mkdir -p "$out"
find "$out" -mindepth 1 -delete
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-fp.XXXXXX")
trap 'find "$work" -delete 2>/dev/null || :' EXIT
key=$(toolchain_key cc "${CC:-clang}")
echo "footprint-bytes: $key"
# Bytes of code: ELF's text column, Mach-O's `__text` section.
code_of() {
    if [ "$(uname -s)" = Darwin ]; then
        size -m "$1" | sed -n 's/.*Section __text: \([0-9]*\).*/\1/p' | head -1
    else
        size "$1" | awk 'NR == 2 { print $1 }'
    fi
}
for name in hello data; do
    mkdir -p "$work/$name"
    (cd "$here/footprint/$name" && find . -name .avra-cache -prune -o -type f ! -path ./src/main -print) |
        while read -r f; do mkdir -p "$work/$name/$(dirname "$f")" && cp "$here/footprint/$name/$f" "$work/$name/$f"; done
    "$avra" build --release "$work/$name" > "$work/$name.log" 2>&1 || { tail -20 "$work/$name.log"; echo "footprint-bytes: $name did not build" >&2; exit 1; }
    bin=$work/$name/src/main
    strip -o "$bin.stripped" "$bin" || { echo "footprint-bytes: \`strip\` refused $name" >&2; exit 1; }
    bytes=$(wc -c < "$bin.stripped" | tr -d ' ')
    code=$(code_of "$bin")
    [ -n "$code" ] && [ "$code" -gt 0 ] || { echo "footprint-bytes: \`size\` answered nothing for $name" >&2; exit 1; }
    echo "bytes:$key:footprint-$name stripped $bytes" >> "$out/rows"
    echo "bytes:$key:footprint-$name code $code" >> "$out/rows"
done
cat "$out/rows"
exec sh "$here/avra_tools.sh" cost "$verb" "$out"

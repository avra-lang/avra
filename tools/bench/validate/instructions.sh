#!/bin/sh
# THE SAME COMPARISON IN INSTRUCTIONS: each engine's row run N times
# under callgrind, less the same binary run zero times, over N — a
# count no neighbour's load moves. Needs valgrind; run.sh builds the
# three binaries first.
#   sh tools/bench/validate/instructions.sh [N]
set -eu
cd "$(dirname "$0")/../../.."
n="${1:-2000}"
here=tools/bench/validate
out="${TMPDIR:-/tmp}/validate-ir.$$"
trap 'rm -f "$out" "$out.0"' EXIT

count() {
    ROW="$1" N="$n" valgrind --tool=callgrind --callgrind-out-file="$out" "$2" "$3" > /dev/null 2>&1
    ROW="$1" N=0 valgrind --tool=callgrind --callgrind-out-file="$out.0" "$2" "$3" > /dev/null 2>&1
    a=$(sed -n 's/^summary: //p' "$out")
    b=$(sed -n 's/^summary: //p' "$out.0")
    echo $(( (a - b) / n ))
}

printf '| row | Avra | Rust | C |\n|---|---|---|---|\n'
for row in parse valid refused; do
    printf '| %s | %s | %s | %s |\n' "$row" \
        "$(count "$row" "$here/src/main" "")" \
        "$(count "$row" "$here/rust/target/release/validate-bench-rust" "")" \
        "$(count "$row" build/validate-bench-c "$here/payloads")"
done

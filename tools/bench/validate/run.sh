#!/bin/sh
# THE COMPARISON: Avra, Rust (serde_json + garde) and C (yyjson and
# hand-written rules) over the same Signup payloads, each a separate
# process, interleaved round by round so load drift lands on all three
# alike; the table is the median of the rounds, ns per payload.
#   sh tools/bench/validate/run.sh [rounds]
set -eu
cd "$(dirname "$0")/../../.."
rounds="${1:-5}"
here=tools/bench/validate
out="${TMPDIR:-/tmp}/validate-bench.$$"
trap 'rm -f "$out"' EXIT

build/avra build "$here" > /dev/null
(cd "$here/rust" && cargo build --release --quiet)
cc -O3 -o build/validate-bench-c "$here/c/bench.c" "$here/c/yyjson.c"

: > "$out"
r=1
while [ "$r" -le "$rounds" ]; do
    "$here/src/main" | sed -n 's/^\(.*\): \([0-9]*\) ns\/payload$/avra|\1|\2/p' >> "$out"
    "$here/rust/target/release/validate-bench-rust" 2> /dev/null | sed -n 's/^\(.*\): \([0-9]*\) ns\/payload$/rust|\1|\2/p' >> "$out"
    build/validate-bench-c "$here/payloads" 2> /dev/null | sed -n 's/^\(.*\): \([0-9]*\) ns\/payload$/c|\1|\2/p' >> "$out"
    r=$((r + 1))
done

# The median of each (engine, row), rows in first-seen order.
awk -F'|' '
    { k = $1 "|" $2; if (!(k in n)) order[++rows] = k; v[k, ++n[k]] = $3 }
    END {
        printf "| engine | row | ns/payload (median of %d) |\n|---|---|---|\n", n[order[1]]
        for (i = 1; i <= rows; i++) {
            k = order[i]; m = n[k]
            for (a = 1; a <= m; a++) for (b = a + 1; b <= m; b++) if (v[k, b] < v[k, a]) { t = v[k, a]; v[k, a] = v[k, b]; v[k, b] = t }
            split(k, p, "|")
            printf "| %s | %s | %d |\n", p[1], p[2], v[k, int((m + 1) / 2)]
        }
    }' "$out"

#!/bin/sh
# The collection bench (docs/2026_09_30_COLLECTIONS.md §3.8): each
# workload an Avra program and a Rust twin over one seeded input, run
# interleaved, the median of ROUNDS (5) printed as one markdown table.
# A checksum the two disagree on fails the run.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
out=$root/build/bench-collections
rounds=${ROUNDS:-5}
workloads="c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12"
[ "$rounds" -ge 1 ] || { echo "bench-collections: ROUNDS must be at least 1" >&2; exit 1; }
mkdir -p "$out"

for c in $workloads; do
    "$root/build/avra" build "$here/$c" > /dev/null 2> "$out/$c.build" || { cat "$out/$c.build"; exit 1; }
done
(cd "$here/rust" && RUSTFLAGS="-C target-cpu=native" cargo build -q --release --locked)

# One run of workload $2 under engine $1, its lines prefixed by the engine.
run() {
    case $1 in avra) bin=$here/$2/src/main ;; rust) bin=$here/rust/target/release/$2 ;; esac
    "$bin" > "$out/one" || { echo "bench-collections: $1 $2 exited $?" >&2; exit 1; }
    sed "s/^/$1 /" "$out/one" >> "$out/raw"
}

: > "$out/raw"
r=1
while [ "$r" -le "$rounds" ]; do
    for c in $workloads; do
        # Each round flips which engine runs first.
        if [ $((r % 2)) -eq 1 ]; then run avra "$c"; run rust "$c"; else run rust "$c"; run avra "$c"; fi
    done
    r=$((r + 1))
done

load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || sysctl -n vm.loadavg)
echo "$(hostname), $(nproc 2>/dev/null || sysctl -n hw.ncpu) cores, load $load after the runs, median of $rounds, $(rustc --version)"
echo
python3 "$here/table.py" "$out/raw"

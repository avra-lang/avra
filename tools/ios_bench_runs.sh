#!/bin/sh
# THE BENCH'S RUNS: `sh tools/ios_bench_runs.sh <label> <runs> avra|twin` runs
# one configuration <runs> times, one simulator boot each, and keeps each run's
# console in build/ios-spike/bench/<label>-<n>.out. The Avra app's mode and size
# come from AVRA_BOARD_MODE and AVRA_SPIKE_ROWS; build the app once first
# (`sh tools/ios_board_witness.sh`). Spike code.
set -u
tree=$(cd "$(dirname "$0")/.." && pwd)
label=$1; runs=$2; which=$3
dir=$tree/build/ios-spike/bench
mkdir -p "$dir"
for i in $(seq 1 "$runs"); do
    free=$(df -m /System/Volumes/Data | awk 'NR == 2 { print $4 }')
    [ "$free" -ge 3072 ] || { echo "ios-bench: STOP — ${free} MB free, under 3 GB"; exit 1; }
    if [ "$which" = twin ]; then
        sh "$tree/tools/ios_twin_bench.sh" "bench-$label" > /dev/null 2>&1
        cp "$tree/build/ios-spike/bench-$label.out" "$dir/$label-$i.out"
    else
        AVRA_BOARD_NOBUILD=1 AVRA_BOARD_FRAMES_OFF=X=1 AVRA_SPIKE_BENCH=1 AVRA_BOARD_SHOTS="${AVRA_BOARD_SHOTS:-200}" \
            sh "$tree/tools/ios_board_witness.sh" "bench-$label" > /dev/null 2>&1
        cp "$tree/build/ios-spike/board.out" "$dir/$label-$i.out"
    fi
    echo "ios-bench: $label run $i: $(tr -d '\r' < "$dir/$label-$i.out" | grep -c 'bench:') bench lines"
done

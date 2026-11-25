#!/bin/sh
# The post-fix ledger for one Avra channel drain: native per-op rows at
# the bounded cap and unbounded, then the census (allocs, rc, copies)
# for the same shapes. Same program and env as the perf-census lane's
# `/perf_census_measure.sh`; this one is trimmed to the rows the ring
# changes. Run under the watchdog, one heavy process at a time.
set -eu
cd "$(dirname "$0")/.."
prog=benchmarks/tasks/drain/avra/src/main
pkg=benchmarks/tasks/drain/avra

make -s libs
build/avra build "$pkg"

echo '===== NATIVE ====='
for spec in "10000 64 5" "1000 64 5" "1000 -1 3" "10000 -1 3" "20000 -1 3"; do
    set -- $spec
    echo "--- native n=$1 cap=$2 rounds=$3"
    BENCH_SMALL=1 BENCH_N=$1 BENCH_ROUNDS=$3 BENCH_CAP=$2 "$prog"
done

echo '===== CENSUS ====='
for spec in "1000 64" "10000 64" "1000 -1" "10000 -1" "20000 -1"; do
    set -- $spec
    echo "##### census n=$1 cap=$2"
    AVRA_CENSUS_SITES=1 \
        BENCH_SMALL=1 BENCH_N=$1 BENCH_ROUNDS=1 BENCH_CAP=$2 \
        make census-types PROGRAM="$prog.av"
done

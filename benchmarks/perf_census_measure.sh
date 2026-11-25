#!/bin/sh
# The perf-census lane's measurement batch. Not a gate and not a fix:
# it prints the native wall rows and the census ledger for one Avra
# bounded-channel drain, at a few capacities and sizes, plus the
# unbounded twin that the audit says is O(n^2).
set -eu
cd "$(dirname "$0")/.."
prog=benchmarks/tasks/drain/avra/src/main
pkg=benchmarks/tasks/drain/avra

make -s libs

echo '===== NATIVE (shipping runtime) ====='
build/avra build "$pkg"
for cap in 1 8 64; do
    for n in 1000 10000; do
        echo "--- native cap=$cap n=$n"
        BENCH_SMALL=1 BENCH_N=$n BENCH_ROUNDS=5 BENCH_CAP=$cap "$prog"
    done
done
for n in 1000 2000 5000 10000 20000; do
    echo "--- native UNBOUNDED n=$n"
    BENCH_SMALL=1 BENCH_N=$n BENCH_ROUNDS=3 BENCH_CAP=-1 "$prog"
done

echo '===== CENSUS (alloc / retain+release / copy / push) ====='
for spec in "1000 64" "10000 64" "1000 -1" "2000 -1" "4000 -1"; do
    set -- $spec
    echo "##### census n=$1 cap=$2"
    AVRA_CENSUS_SITES=1 AVRA_ALIAS_LOG=1 \
        BENCH_SMALL=1 BENCH_N=$1 BENCH_ROUNDS=1 BENCH_CAP=$2 \
        make census-types PROGRAM="$prog.av"
done

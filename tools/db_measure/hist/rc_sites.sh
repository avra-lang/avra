#!/bin/sh
# WHAT ONE RECORDED READ AND ONE ROW WRITTEN COST, COUNTED — and held to a budget.
#   sh tools/db_measure/read_cost.sh            print and check
#   sh tools/db_measure/read_cost.sh --accept   write what was counted as the budget
# From a tree's root, over its build/avra. The runtime is built with its
# census (exact retain, release and list read/write counts), the bench
# (tools/db_measure/readcost) is built against it and run per mode at N and
# at 2N reads; the difference is N reads and nothing else, so setup cancels.
# EVERY FIGURE IS (count at 2N − count at N) / N: per read, never per run.
# The counts are the same on every machine, which is what makes them a gate:
# a mode that costs MORE than its row in read_cost.budget refuses, and so
# does a mode with no row and a row with no mode. `--accept` rewrites the
# budget whole: the review of that diff is the only ratchet.
# THE CENSUS RUNTIME IS BUILT TO ITS OWN PLACE (build/census/), with a copy
# of the compiler beside it and links to the tree's packages and sources one
# up, where a compiler looks: the tree's own library and objects are never touched, so a run
# killed anywhere leaves the shipping runtime where every build expects it.
# Instructions per read are printed too where the machine can count them
# (macOS `/usr/bin/time -l`) — published, never gated: they are this
# machine's.
set -eu
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
cd "$(dirname "$0")/../../.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
[ -x build/avra ] || { echo "read_cost: no build/avra"; exit 1; }
N=${DBM_READS:-200000}
bench=tools/db_measure/readcost
budget=tools/db_measure/read_cost.budget
modes="kernel.last kernel.earlier kernel.new row.unheard row.repeat row.new ask.int ask.text write.unowned write.owned write.replaced write.over write.given write.heard"
census=build/census
trap 'rm -f "$bench/src/main" "$bench/src/main.av.ll"' EXIT INT TERM
mkdir -p "$census/build" "$census/obj"
# what a compiler reads from the tree it stands in: its packages and its own sources
for p in packages backend runtime Makefile; do
    [ -e "$census/$p" ] || ln -s "../../$p" "$census/$p"
done
probes=$([ "$(uname -s)" = Darwin ] || echo -fstack-clash-protection)
for c in runtime/*.c; do
    o=$census/obj/$(basename "$c" .c).o
    # shellcheck disable=SC2086
    cc -c -O2 -fPIC $probes -ffunction-sections -fdata-sections -Wall -Werror -DAVRA_CENSUS -o "$o" "$c"
done
rm -f "$census/build/libavra_runtime.a"
ar rcs "$census/build/libavra_runtime.a" "$census"/obj/*.o
cp build/avra "$census/build/avra"
AVRA_INLINE_RUNTIME=0 "$census/build/avra" build "$bench" > build/read-cost-build.out 2>&1 || {
    tail -n 20 build/read-cost-build.out
    echo "read_cost: the bench did not build"
    exit 1
}

for n in $N $((2 * N)); do
    DBM_MODE=write.heard DBM_N=$n AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 "$bench/src/main" 2> "$HOME/heard.$n" > /dev/null
    echo "== $n"
    grep -a '^rc:' "$HOME/heard.$n"
    grep -a ': site 0x' "$HOME/heard.$n" | while IFS= read -r line; do
        addr=$(echo "$line" | sed 's/.*site \(0x[0-9a-f]*\).*/\1/')
        echo "$line	$(addr2line -f -e "$bench/src/main" "$addr" 2>/dev/null | head -1)"
    done
done

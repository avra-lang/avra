#!/bin/sh
# WHAT ONE RECORDED READ COSTS, COUNTED — and held to a budget.
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
# of the compiler beside it and the tree's packages one up, where a compiler
# looks: the tree's own library and objects are never touched, so a run
# killed anywhere leaves the shipping runtime where every build expects it.
# Instructions per read are printed too where the machine can count them
# (macOS `/usr/bin/time -l`) — published, never gated: they are this
# machine's.
set -eu
cd "$(dirname "$0")/../.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX
[ -x build/avra ] || { echo "read_cost: no build/avra"; exit 1; }
N=${DBM_READS:-200000}
bench=tools/db_measure/readcost
budget=tools/db_measure/read_cost.budget
modes="kernel.last kernel.earlier kernel.new row.unheard row.repeat row.new ask.int ask.text"
census=build/census
trap 'rm -f "$bench/src/main" "$bench/src/main.av.ll"' EXIT INT TERM
mkdir -p "$census/build" "$census/obj"
[ -e "$census/packages" ] || ln -s ../../packages "$census/packages"
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
# The four counts of one run: retains, releases, list reads, list writes.
counted() {
    DBM_MODE=$1 DBM_N=$2 AVRA_MEM_STATS=1 "$bench/src/main" 2>&1 > /dev/null |
        awk '/^rc: .* retains/ { r = $2; l = $4 } /^rc: .* list reads/ { g = $2; w = $5 } END { print r + 0, l + 0, g + 0, w + 0 }'
}
instructions() {
    [ -x /usr/bin/time ] && /usr/bin/time -l true > /dev/null 2>&1 || { echo ""; return; }
    a=$( (DBM_MODE=$1 DBM_N=$N /usr/bin/time -l "$bench/src/main" > /dev/null) 2>&1 | awk '/instructions retired/ { print $1 }')
    b=$( (DBM_MODE=$1 DBM_N=$((2 * N)) /usr/bin/time -l "$bench/src/main" > /dev/null) 2>&1 | awk '/instructions retired/ { print $1 }')
    [ -n "$a" ] && [ -n "$b" ] && echo "$(((b - a) / N))" || echo ""
}
out=build/read-cost.out
: > "$out"
seen=0
for mode in $modes; do
    one=$(counted "$mode" "$N")
    two=$(counted "$mode" $((2 * N)))
    [ "$one" != "0 0 0 0" ] || { echo "read_cost: $mode printed no counts — the bench carries no census"; exit 1; }
    seen=$((seen + 1))
    # per read, in thousandths: a count that is not whole per read still shows
    echo "$mode $one $two" | awk -v n="$N" '{ printf "%s\t%.3f\t%.3f\t%.3f\t%.3f\n", $1, ($6 - $2) / n, ($7 - $3) / n, ($8 - $4) / n, ($9 - $5) / n }' >> "$out"
done
printf 'mode\tretains\treleases\tlist reads\tlist writes\tinstructions (this machine)\n'
while IFS="$(printf '\t')" read -r mode r l g w; do
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$mode" "$r" "$l" "$g" "$w" "$(instructions "$mode")"
done < "$out"
if [ "${1:-}" = --accept ]; then
    cp "$out" "$budget"
    echo "read_cost: $seen mode(s) counted, written as the budget"
    exit 0
fi
[ -f "$budget" ] || { echo "read_cost: no budget at $budget — run with --accept"; exit 1; }
over=$(awk -F'\t' 'NR == FNR { for (i = 2; i <= 5; i++) cap[$1, i] = $i; known[$1] = 1; next }
    { counted[$1] = 1 }
    !known[$1] { print $1 " has no budget row"; next }
    { for (i = 2; i <= 5; i++) if ($i > cap[$1, i] + 0.0005) print $1 " column " i - 1 ": " $i " over its budget of " cap[$1, i] }
    END { for (m in known) if (!counted[m]) print "budget row " m " names no mode this counts — drop the row or count the mode" }' "$budget" "$out")
[ -z "$over" ] || { echo "$over" | sed 's/^/read_cost: /'; exit 1; }
echo "read_cost: $seen mode(s) counted, each within its budget"

#!/bin/sh
# THE DETERMINISM SWEEP: every count the cost surface would judge exactly, measured twice over one tree on
# one machine, cold each time, and diffed. A count that moves names itself: `MOVED <row> <first> <second>`.
set -u
mkdir -p build/sweep
parts="all matrix-check-bare matrix-check-laid matrix-build-bare matrix-build-laid"
for i in 1 2; do
    t0=$(date +%s)
    COST_PART="$parts" sh tools/cost.sh > "build/sweep/cost-$i.log" 2>&1 || echo "SWEEP run $i: cost.sh exit $? (tail below)"
    tail -3 "build/sweep/cost-$i.log"
    sh ./wisp cost rows build/cost > "build/sweep/cost-$i.rows" 2> "build/sweep/rows-$i.err" || cat "build/sweep/rows-$i.err"
    sh tools/warm_edit_bench.sh > "build/sweep/warm-$i.stream" 2>&1 || echo "SWEEP run $i: warm bench exit $?"
    awk '$1 == "counts" && NF == 4 { print "warm-" $2 " " $3 " " $4 }' "build/sweep/warm-$i.stream" >> "build/sweep/cost-$i.rows"
    sh tools/footprint_bytes.sh > "build/sweep/foot-$i.log" 2>&1 || :
    cat build/ledger/footprint/rows >> "build/sweep/cost-$i.rows" 2>/dev/null || echo "SWEEP run $i: no footprint rows"
    grep -vE '^(#|snapshot )' "build/sweep/cost-$i.rows" | awk 'NF == 3' | sort -u > "build/sweep/cost-$i.sorted" && mv "build/sweep/cost-$i.sorted" "build/sweep/cost-$i.rows"
    echo "SWEEP run $i: $(wc -l < "build/sweep/cost-$i.rows") rows in $(( $(date +%s) - t0 ))s"
done
join -j1 -a1 -a2 -e MISSING -o 0,1.2,2.2 \
    <(awk '{ print $1 "|" $2, $3 }' build/sweep/cost-1.rows | sort) \
    <(awk '{ print $1 "|" $2, $3 }' build/sweep/cost-2.rows | sort) |
    awk '$2 != $3 { sub(/\|/, " ", $1); print "MOVED", $1, $2, $3 }'
echo "SWEEP done: $(join -j1 <(awk '{ print $1 "|" $2, $3 }' build/sweep/cost-1.rows | sort) <(awk '{ print $1 "|" $2, $3 }' build/sweep/cost-2.rows | sort) | awk '$2 != $3' | wc -l) moved"

#!/bin/bash
# <part> <workload>: the part measured twice over one tree, cold each time; the workload's counts and its
# census lines compared as SETS (equal counts sort in either order), each that differs said
set -u
part=$1; w=$2
mkdir -p build/det
for i in 1 2; do
    COST_PART=$part sh tools/cost.sh > build/det/cost-$i.log 2>&1 || { echo "DET run $i: cost.sh exit $?"; tail -5 build/det/cost-$i.log; }
    sort build/cost/$w.out > build/det/$w-$i.out 2>/dev/null || echo "DET run $i: no $w.out"
    sort build/cost/$w.sites > build/det/$w-$i.sites 2>/dev/null || :
    sh ./wisp cost rows build/cost 2>/dev/null | grep "^$w " > build/det/$w-$i.rows
    echo "DET run $i: $(wc -l < build/det/$w-$i.out) census lines, $(wc -l < build/det/$w-$i.rows) rows"
done
echo "DET rows that moved:"
diff build/det/$w-1.rows build/det/$w-2.rows | grep '^[<>]'
echo "DET census lines only one run holds (< run 1, > run 2):"
comm -3 build/det/$w-1.out build/det/$w-2.out | sed 's/^\t/> /; t; s/^/< /' | head -200
echo "DET site lines only one run holds:"
comm -3 build/det/$w-1.sites build/det/$w-2.sites | sed 's/^\t/> /; t; s/^/< /' | head -120
echo "DET done"

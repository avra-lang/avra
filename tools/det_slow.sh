#!/bin/bash
# <part> <workload>: the part measured at full speed, then with core 0 shared by a busy loop; counts and census sites compared as sets
set -u
part=$1; w=$2
mkdir -p build/det
for i in 1 2; do
    hog=
    if [ "$i" = 2 ]; then taskset -c 0 sh -c 'while :; do :; done' & hog=$!; fi
    t0=$(date +%s)
    COST_PART=$part sh tools/cost.sh > build/det/cost-$i.log 2>&1 || { echo "DET run $i: cost.sh exit $?"; tail -5 build/det/cost-$i.log; }
    [ -z "$hog" ] || kill "$hog"
    sort build/cost/$w.out > build/det/$w-$i.out 2>/dev/null
    sort build/cost/$w.sites > build/det/$w-$i.sites 2>/dev/null || :
    sh ./wisp cost rows build/cost 2>/dev/null | grep "^$w " > build/det/$w-$i.rows
    echo "DET run $i ($( [ $i = 1 ] && echo full || echo slowed )): $(( $(date +%s) - t0 ))s, $(wc -l < build/det/$w-$i.rows) rows"
done
echo "DET rows that moved (< full, > slowed):"
diff build/det/$w-1.rows build/det/$w-2.rows | grep '^[<>]'
echo "DET census lines only one run holds:"
comm -3 build/det/$w-1.out build/det/$w-2.out | sed 's/^\t/> /; t; s/^/< /' | grep -v memcap | head -150
echo "DET done"

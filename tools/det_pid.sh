#!/bin/bash
# <part> <workload>: measured, then again once the pid counter has gained a digit; counts compared
set -u
part=$1; w=$2
mkdir -p build/det
echo "DET pid_max $(cat /proc/sys/kernel/pid_max)"
for i in 1 2; do
    if [ "$i" = 2 ]; then
        now=$(sh -c 'echo $$'); want=$(( 10 ** ${#now} ))
        echo "DET burning pids from $now past $want"
        while [ "$(sh -c 'echo $$')" -lt "$want" ]; do for k in $(seq 1 200); do /bin/true; done; done
        echo "DET pid now $(sh -c 'echo $$')"
    fi
    echo "DET run $i starts at pid $(sh -c 'echo $$')"
    COST_PART=$part sh tools/cost.sh > build/det/cost-$i.log 2>&1 || { echo "DET run $i: cost.sh exit $?"; tail -5 build/det/cost-$i.log; }
    sh ./wisp cost rows build/cost 2>/dev/null | grep "^$w " > build/det/$w-$i.rows
done
echo "DET rows that moved (< short pids, > long pids):"
diff build/det/$w-1.rows build/det/$w-2.rows | grep '^[<>]'
echo "DET done"

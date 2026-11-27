#!/bin/bash
# <part> <workload>: one cold measurement, its machine, rows and every site line said in full, sorted
set -u
part=$1; w=$2
echo "ONE cpu $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | tr ' ' _) mem $(awk '/MemTotal/ {print $2}' /proc/meminfo) host ${#HOSTNAME} home ${#HOME} env $(env | wc -c)"
COST_PART=$part sh tools/cost.sh > build/one.log 2>&1 || { echo "ONE cost.sh exit $?"; tail -5 build/one.log; }
sh ./wisp cost rows build/cost 2>/dev/null | grep "^$w " | sed 's/^/ROW /'
sort build/cost/$w.sites | sed 's/^/SITE /'
grep -E '^(made|copy|rc|alloc|death):' build/cost/$w.out | sort | sed 's/^/CEN /'
echo "ONE done"

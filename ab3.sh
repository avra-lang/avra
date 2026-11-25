#!/bin/sh
# cold attribution: sh ab3.sh <bin>
set -u
B=$1
for c in build/cold1 build/cold2; do [ -d $c ] && find $c -delete; done
s=$(date +%s%N); AVRA_CACHE_DIR=build/cold1 $B check --time --counts packages/cli > build/cold1.out 2>&1; echo "cold wall_ms=$(( ($(date +%s%N)-s)/1000000 ))"
grep -aE '^(time|counts|whole)' build/cold1.out | cut -c1-1500
AVRA_CACHE_DIR=build/cold2 AVRA_QTRACE=1 $B check packages/cli > /dev/null 2> build/cold2.q
python3 tools/db_measure/graph.py --qtrace build/cold2.q packages/std-avrac/src/compiler/families/families.av | sort -k3 -n -r | head -25
awk -F'\t' '$1=="Q"{n[$2]++} END{for(k in n) print n[k], k}' build/cold2.q | sort -rn | head -15
awk -F'\t' '$1=="Q" && $2=="store"{n[$3]++} END{for(k in n) print n[k], "store", k}' build/cold2.q | sort -rn | head -8
awk -F'\t' '$1=="Q" && $2=="unit"{n[$3]++} END{for(k in n) print n[k], "unit", k}' build/cold2.q

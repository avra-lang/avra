#!/bin/sh
# true cold: the tree store removed before each run
set -u
for b in main tip; do
  [ -d .avra-cache ] && find .avra-cache -delete
  [ -d build/cold_$b ] && find build/cold_$b -delete
  s=$(date +%s%N); AVRA_CACHE_DIR=build/cold_$b build/avra.$b check --time --counts packages/cli > build/tcold_$b.out 2>&1
  echo "$b wall_ms=$(( ($(date +%s%N)-s)/1000000 ))"; grep -aE '^(time|counts)' build/tcold_$b.out | cut -c1-900; grep -a "hold was refused\|discarded:" build/tcold_$b.out | cut -c1-200
done

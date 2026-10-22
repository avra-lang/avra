#!/bin/sh
# Three cold `check packages/cli --time` rounds on the tree's compiler; the
# per-phase ms the check prints are summed into one total per round.
label=$1
for r in 1 2 3; do
  rm -rf .avra-cache
  build/avra check packages/cli --time > cold_$label_$r.out 2> cold_$r.err; rc=$?
  total=$(grep "time:" cold_$r.err | tail -1 | sed 's/time: //' | tr ',' '\n' | sed 's/^ *[a-z ]* \([0-9]*\)ms.*/\1/' | awk '/^[0-9]+$/ {s+=$1} END {print s+0}')
  echo "$label round $r rc=$rc total_ms=$total"
done

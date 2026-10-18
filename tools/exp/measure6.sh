#!/bin/sh
# Instructions, branches and branch-misses of a cold `check packages/cli`,
# base vs A vs B, and the census of B beside A's.
set -eu
cd "$(dirname "$0")/../.."
command -v perf >/dev/null 2>&1 || { echo "no perf on this machine"; exit 2; }
for i in 1 2 3; do
  for which in base A B; do
    rm -rf .avra-cache
    perf stat -x, -e instructions,branches,branch-misses -o "build/perf-$which-$i.txt" build/avra.$which check packages/cli > /dev/null 2>&1 || echo "$which rc=$?"
    echo "$which $(grep -a instructions build/perf-$which-$i.txt | cut -d, -f1) $(grep -a ',branches' build/perf-$which-$i.txt | cut -d, -f1) $(grep -a branch-misses build/perf-$which-$i.txt | cut -d, -f1)"
  done
done

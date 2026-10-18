#!/bin/sh
# Three clean rounds of instructions, branches and branch-misses on a cold cli
# check: base, A and B2, alternating. The output is the caller's to name.
set -eu
cd "$(dirname "$0")/../.."
for i in 1 2 3; do
  for which in base A B2; do
    rm -rf .avra-cache
    perf stat -x, -e instructions,branches,branch-misses -o "build/perf3-$which-$i.txt" build/avra.$which check packages/cli > /dev/null 2>&1 || echo "$which rc=$?"
    echo "$which $(grep -a instructions build/perf3-$which-$i.txt | cut -d, -f1) $(grep -a ',branches' build/perf3-$which-$i.txt | cut -d, -f1) $(grep -a branch-misses build/perf3-$which-$i.txt | cut -d, -f1)"
  done
done

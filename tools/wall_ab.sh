#!/bin/bash
# Warm one-line fmt.av edits under `check packages/cli`, main and branch
# interleaved on one machine. Each tree checks its own source with its own
# compiler; each starts cold once, then alternates edit / restore.
set -u
export LLVM_PREFIX=/usr/lib/llvm-22
B=/home/sprite/avra-build/avra-perf-hold-keys/tree
M=/home/sprite/avra-build/avra-perf-mainref/tree
f=packages/cli/src/commands/fmt.av
for T in $M $B; do
  ( cd $T && make -s avra > /tmp/w1.log 2>&1 && make -s avra > /tmp/w2.log 2>&1 ) || { echo "build failed in $T"; exit 2; }
  ( cd $T && find . -name .avra-cache -type d -prune -exec rm -rf {} + && cp $f /tmp/$(basename $(dirname $T)).fmt && build/avra check packages/cli > /dev/null 2>&1 )
done
ms() { local s=$(date +%s%N); build/avra check packages/cli > /dev/null 2>&1; local e=$(date +%s%N); echo $(( (e - s) / 1000000 )); }
# Every round writes text no earlier round wrote, so no check is a cache hit.
for i in 1 2 3 4 5 6; do
  for T in $M $B; do
    n=$(basename $(dirname $T))
    cd $T
    cp /tmp/$n.fmt $f
    sed -i "s/\"avra: \${path}: \${e.describe/\"avra $i-$RANDOM: \${path}: \${e.describe/" $f
    grep -c "avra $i-" $f > /dev/null || { echo "edit missed in $n"; exit 2; }
    echo "$i $n edit=$(ms)ms"
  done
done
for T in $M $B; do cp /tmp/$(basename $(dirname $T)).fmt $T/$f; done

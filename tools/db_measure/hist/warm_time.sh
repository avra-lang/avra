#!/bin/sh
# Warm one-edit `check packages/cli` timings: cold, then one comment line appended, three times.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
f=packages/cli/src/commands/explain.av
cp $f $HOME/wt.orig
build/avra check packages/cli > /dev/null 2>&1; echo "warm-time: cold check status=$?"
for i in 1 2 3; do
    printf '// edit %s\n' "$i" >> $f
    build/avra check --time packages/cli > $HOME/wt.$i.log 2>&1; st=$?
    echo "warm-time $i status=$st $(grep -aE '^(time|held|read|load|admit|analy)' $HOME/wt.$i.log | tr '\n' ' ' | cut -c1-400)"
done
cp $HOME/wt.orig $f

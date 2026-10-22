#!/bin/sh
# ab_time.sh save: keep this tree's compiler as $HOME/avra.base.  ab_time.sh run: A/B warm one-edit check cli, base vs this tree, alternating.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
if [ "$1" = save ]; then cp build/avra $HOME/avra.base; git rev-parse --short HEAD > $HOME/avra.base.sha 2>/dev/null; echo "saved base $(cat $HOME/avra.base.sha 2>/dev/null)"; exit 0; fi
f=packages/cli/src/commands/explain.av
cp $HOME/avra.base build/avra.base
cp $f $HOME/ab.orig
# each binary keeps its own store under its own print; start both from nothing
rm -rf .avra-cache packages/cli/.avra-cache
ls -d .avra-cache/* packages/cli/.avra-cache/* 2>/dev/null | head -n 3
for who in base this; do
    bin=$(pwd)/build/avra; [ $who = base ] && bin=$(pwd)/build/avra.base
    cp $HOME/ab.orig $f; "$bin" check packages/cli > /dev/null 2>&1
done
for i in 1 2 3 4; do
    for who in base this; do
        bin=$(pwd)/build/avra; [ $who = base ] && bin=$(pwd)/build/avra.base
        printf '// edit %s %s\n' "$i" "$who" >> $f
        "$bin" check --time packages/cli > $HOME/ab.log 2>&1
        [ $i = 1 ] && ls -d .avra-cache/*/ packages/cli/.avra-cache/*/ 2>/dev/null | wc -l | sed "s/^/stores: /"
        echo "$who $i status=$? $(grep -aoE 'held [0-9]+/[0-9]+|load [0-9]+ms|admit [0-9]+ms|analyze [0-9]+ms' $HOME/ab.log | tr '\n' ' ') $(grep -a '^error\|^avra:' $HOME/ab.log | head -n 2 | tr '\n' ' ' | cut -c1-200)"
    done
done
cp $HOME/ab.orig $f

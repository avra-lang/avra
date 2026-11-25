#!/bin/sh
# Two binaries alternating warm one-edit checks in one tree: what an exit 1 says.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
cp $HOME/avra.base build/avra.base
f=packages/cli/src/commands/explain.av; cp $f $HOME/tb.orig
rm -rf .avra-cache packages/cli/.avra-cache
for who in base this; do
    bin=$(pwd)/build/avra; [ $who = base ] && bin=$(pwd)/build/avra.base
    "$bin" check packages/cli > /dev/null 2>&1; echo "warm-up $who status=$?"
done
for i in 1 2; do
    for who in base this; do
        bin=$(pwd)/build/avra; [ $who = base ] && bin=$(pwd)/build/avra.base
        printf '// edit %s %s\n' "$i" "$who" >> $f
        "$bin" check --time packages/cli > $HOME/tb.$i.$who.log 2>&1; st=$?
        echo "$who $i status=$st lines=$(wc -l < $HOME/tb.$i.$who.log)"
        [ $st -ne 0 ] && grep -av '^watch:' $HOME/tb.$i.$who.log | grep -av '^ \|^[│·╭╰─]\|^$' | grep -av '^warning\|^help' | tail -n 8 | cut -c1-240
    done
done
echo "same binary twice:"
for i in 3 4; do printf '// edit %s\n' "$i" >> $f; build/avra check --time packages/cli > $HOME/tb.$i.log 2>&1; echo "this $i status=$?"; done
printf '// edit 5\n' >> $f; build/avra check packages/cli > $HOME/tb.5.log 2>&1; echo "this 5 no --time status=$?"
grep -ac "^error" $HOME/tb.2.this.log
cp $HOME/tb.orig $f

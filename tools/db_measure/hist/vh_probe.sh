#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
build/avra check packages/cli > $HOME/vp1.log 2>&1; echo "check cli status=$?"
AVRA_QTRACE=1 build/avra check --verify-held packages/cli > $HOME/vp2.log 2>&1; echo "verify-held cli status=$?"
grep -a "^avra:\|^error" $HOME/vp2.log | head -n 5
echo "dropped refs: $(grep -ac '^Q	ref-dropped' $HOME/vp2.log)"
grep -a "^Q	ref-dropped" $HOME/vp2.log | sed "s|$(pwd)/||g" | sort | uniq -c | sort -rn | head -n 40 | cut -c1-260
grep -a "PROBE" $HOME/vp2.log | sed "s|$(pwd)/||g" | cut -c1-900

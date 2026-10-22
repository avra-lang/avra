#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
echo "tree $(git rev-parse --short HEAD 2>/dev/null)"
build/avra check packages/std-avrac > $HOME/vh1.log 2>&1; echo "check std-avrac status=$?"
build/avra check --verify-held packages/std-avrac > $HOME/vh2.log 2>&1; echo "verify-held std-avrac status=$? $(grep -a 'verify-held:\|^avra:' $HOME/vh2.log | tail -n 1 | cut -c1-220)"
grep -a "	held=" $HOME/vh2.log | sed "s|$(pwd)/||" | head -n 40 | cut -c1-200

#!/bin/sh
export LLVM_PREFIX=/opt/homebrew/opt/llvm
cd "$(dirname "$0")/.."
for c in kinds chain after computed record fncall local cycle othermod; do
    echo "=== $c"
    (cd probes/$c && timeout 120 sh /Users/tristan/projects/tristanMatthias/avra/tools/slot.sh 3 sh /Users/tristan/projects/tristanMatthias/avra/tools/memcap.sh 4000 ../../build/avra run src/main.av 2>&1 | grep -v "^\s*$" | head -30)
done

#!/bin/sh
# Does an unmodified gen2 (base building the tree) work?
cd "$(dirname "$0")/../.."
cp build/avra.base build/avra
make avra > build/gen2-build.out 2>&1 || echo "gen2 build failed"
cp build/avra build/avra.gen2
cp build/avra.base build/avra
rm -rf .avra-cache
if build/avra.gen2 check packages/std-text > build/gen2.run 2>&1; then echo "gen2: ok"; else echo "gen2: rc=$?"; fi
cmp build/avra.base build/avra.gen2 && echo "gen2 identical to base"

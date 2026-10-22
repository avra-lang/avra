#!/bin/sh
# gen-2 peak: the post-#606 compiler on packages/cli, under the same watchdog.
echo "binary: $(sha256sum build/avra | cut -c1-12) (from $(cat build/.avra-compiler-hash 2>/dev/null | cut -c1-12))"
rm -rf .avra-cache
sh tools/watch.sh 6000 build/avra build packages/cli > peak2.out 2>&1; echo "rc=$?"
grep "watch: peak" peak2.out

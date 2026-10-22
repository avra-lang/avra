#!/bin/sh
# Peak of each self-build generation on the current tree, under the same watchdog CI uses.
rm -f build/.avra-compiler-hash
echo "gen-A starts from: $(sha256sum build/avra 2>/dev/null | cut -c1-12)"
sh tools/watch.sh 6000 make -s avra 2>&1 | grep "watch: peak\|error" ; echo "gen-A rc=$?"
echo "gen-B starts from: $(sha256sum build/avra 2>/dev/null | cut -c1-12)"
sh tools/watch.sh 6000 make -s avra 2>&1 | grep "watch: peak\|error" ; echo "gen-B done"

#!/bin/sh
# Both compilers over THIS tree's source: main's binaries (left in /home/sprite by
# a run in main's tree) beside build/avra, so each finds the same std root.
set -u
mkdir -p build/m3receipt
cp /home/sprite/m3-main.avra build/avra.main
cp /home/sprite/m3-main.census build/avra.main.census
echo "=== census: this tree's compiler over this tree's source"
sh tools/census.sh check packages/cli > build/m3receipt/census-m3.txt 2>&1
grep -v ': site ' build/m3receipt/census-m3.txt | head -40
echo "=== census: main's compiler over this tree's source"
[ -d .avra-cache ] && mv .avra-cache build/m3receipt/census-aside-$(date +%s)
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 sh tools/memcap.sh 4000 build/avra.main.census check packages/cli 2>&1 >/dev/null \
    | grep -Ev '^(mem:|memcap:)' > build/m3receipt/census-main.txt
grep -v ': site ' build/m3receipt/census-main.txt | head -40
echo "=== receipt"
sh tools/m3probe/receipt.sh main=build/avra.main m3=build/avra main2=build/avra.main m3b=build/avra

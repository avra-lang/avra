#!/bin/sh
# sites58.sh <id> <commit>: that tree's census compiler (built by its own compiler, from 57's), one cold
# build-cli over snap57 with the site tables on; made-sites by fn to /tmp/claude-0/s58/<sha8>.byfn
set -u
. /etc/profile.d/avra.sh
export AVRA_MEM_POOL_MB=12500
ID=$1; P=/tmp/claude-0/s58; mkdir -p $P
s=$(git -C /work/avra rev-parse --short=8 "$2")
wt=/work/s58-wt$ID
[ -e "$wt/.git" ] || git -C /work/avra worktree add -f --detach "$wt" "$s" > /dev/null 2>&1
cd "$wt" || exit 2
git checkout -q -f --detach "$s" && git clean -q -f -d -e build/ > /dev/null
mkdir -p build && find /work/fixA-wt/build -maxdepth 1 -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name '*.sha' -o -name '*.d' -o -name 'avra_hot.*' \) -exec cp -p {} build/ \;
cp /work/l57final-wt/build/avra.gen2 build/avra.next && mv -f build/avra.next build/avra
t=$(date +%s); make try > $P/$s.try.log 2>&1 || { echo "$s: try failed"; exit 1; }
cp build/avra-try build/avra.b.next && mv -f build/avra.b.next build/avra.builder
CENSUS_BUILDER=build/avra.builder sh tools/census_compiler.sh build/avra.census > $P/$s.census.log 2>&1 || { echo "$s: no census compiler: $(tail -2 $P/$s.census.log | tr '\n' ' ')"; exit 1; }
echo "$s census compiler $(($(date +%s)-t))s"
src=/work/s58-src$ID; cache=/work/s58-cache$ID
if [ ! -d "$src/packages" ]; then mkdir -p "$src/build"; git -C /work/avra archive a6d0d0a04724cfd000bcd9c4c0c3b46f61a36acc | tar -x -C "$src"; fi
cp build/avra.census "$src/build/avra"; cp build/avra.census $P/$s.bin
find build -maxdepth 1 -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name 'avra_hot.bc' -o -name 'avra_hot.inc' \) -exec cp {} "$src/build/" \;
find "$src" -path '*/.avra-cache*' -delete; find "$src/packages" \( -path '*/src/main' -o -name '*.av.ll' \) -type f -delete
mkdir -p "$cache"; find "$cache" -mindepth 1 -delete; mkdir -p "$cache/home"; sleep 3
t=$(date +%s)
(cd "$src" && HOME="$cache/home" AVRA_MACHINE_STORE=0 AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 AVRA_CENSUS_TOP=400 AVRA_WORK_AHEAD_OFF=1 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 \
   taskset -c $ID build/avra build packages/cli > $P/$s.stdout 2> $P/$s.out) || echo "$s: build-cli failed"
echo "$s build-cli $(($(date +%s)-t))s $(grep -o '^alloc: [0-9]* boxes' $P/$s.out)"
for kind in made retain; do
  grep "^$kind: site 0x" $P/$s.out | awk '{print $3, $4}' | while read -r a n; do echo "$(addr2line -f -e $P/$s.bin $a | head -1) $n"; done | awk '{s[$1]+=$2} END {for (k in s) print s[k], k}' | sort -rn > $P/$s.$kind.byfn
done
echo "$s DONE"

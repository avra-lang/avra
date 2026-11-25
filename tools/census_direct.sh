export LLVM_PREFIX=/usr/lib/llvm-22
set -x
test -x build/avra || make bootstrap > /tmp/boot.log 2>&1
make -o avra libs > /tmp/libs.log 2>&1
cc -O2 -DAVRA_CENSUS -c runtime/avra_runtime.c -o build/avra_runtime.o
cc -O2 -DAVRA_CENSUS -c runtime/avra_hot.c -o build/avra_hot.o
rm -f build/libavra_runtime.a; ar rcs build/libavra_runtime.a build/*.o
build/avra build packages/cli > /tmp/cb.log 2>&1 || { tail -30 /tmp/cb.log; exit 1; }
cp packages/cli/src/main /tmp/avra_census
rm -rf .avra-cache
AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 /tmp/avra_census check packages/cli 2>/tmp/census.raw >/dev/null
grep -E '^(rc|alloc):' /tmp/census.raw
grep -E '^retain:' /tmp/census.raw | while read l a b c; do
  n=$(addr2line -f -e /tmp/avra_census $b | head -1); echo "retain $c $n"; done
grep -E '^copy:' /tmp/census.raw | head -6 | while read l a b c; do
  n=$(addr2line -f -e /tmp/avra_census $b | head -1); echo "copy $c $n"; done

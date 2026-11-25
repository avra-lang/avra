#!/bin/sh
# Two census compilers — main's source and main's plus tools/branch.patch, each
# built by the same build/avra — run over main's own tree.
set -eu
: "${LLVM_PREFIX:=/usr/lib/llvm-22}"
export LLVM_PREFIX
flags="CFLAGS_avra_runtime=-DAVRA_CENSUS CFLAGS_avra_hot=-DAVRA_CENSUS"
make --no-print-directory $flags build/libavra_runtime.a > /dev/null
built() {
    AVRA_INLINE_RUNTIME=0 AVRA_CENSUS_TYPES=1 build/avra build packages/cli > "build/census-build-$1.out" 2>&1 || {
        tail -20 "build/census-build-$1.out"; echo "census_pair: $1 did not build"; exit 1; }
    mv packages/cli/src/main "build/avra.census.$1"
    rm -f packages/cli/src/main.av.ll
}
built main
patch -s -p1 < tools/branch.patch
built branch
patch -s -R -p1 < tools/branch.patch
make --no-print-directory build/libavra_runtime.a > /dev/null
for which in main branch main branch; do
    rm -rf .avra-cache
    start=$(date +%s%N)
    AVRA_MEM_STATS=1 AVRA_CENSUS_SITES=1 "build/avra.census.$which" check packages/cli 2>&1 >/dev/null \
        | grep -Ev '^(mem:|memcap:)' | grep -v ': site 0x' > "build/census-$which.txt" || true
    end=$(date +%s%N)
    echo "== $which ($(( (end - start) / 1000000 )) ms)"
    grep -E '^(rc|list|box|type|alloc|retain|release|writes|count)' "build/census-$which.txt" | head -30 || head -30 "build/census-$which.txt"
done

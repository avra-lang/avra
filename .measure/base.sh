#!/bin/sh
# Builds build/avra-base: this tree with the store changes reversed.
git apply -R .measure/store.diff || exit 1
./avra build packages/cli > build/base-build.out 2>&1; s=$?
cp packages/cli/src/main build/avra-base
git apply .measure/store.diff
[ $s = 0 ] || { tail -20 build/base-build.out; exit 1; }
echo "base: build/avra-base"

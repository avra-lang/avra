#!/bin/sh
# Does the header layout alone crash the compiler: the bitfield header with
# no bump, built by the standing compiler and run on a small check.
set -eu
cd "$(dirname "$0")/../.."
cp build/avra.base build/avra
git apply tools/exp/header_only.patch
make avra > build/bisect-header.out 2>&1 || echo "build failed"
cp build/avra build/avra.header_only
git apply -R tools/exp/header_only.patch
cp build/avra.base build/avra
if build/avra.header_only check packages/std-text > build/bisect-header.run 2>&1; then echo "header only: ok"; else echo "header only: rc=$?"; fi

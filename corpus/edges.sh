#!/bin/sh
# One cold check of the frozen input, its new kernel edges summarised.
set -u
cd "$(dirname "$0")/.."
make -o avra libs >/dev/null
rm -rf .avra-cache corpus/census-input/packages/cli/.avra-cache
build/avra check corpus/census-input/packages/cli 2>&1 >/dev/null | awk -f corpus/edges.awk

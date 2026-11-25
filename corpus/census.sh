#!/bin/sh
# The census over the frozen input, every cache it could read cleared first.
set -u
cd "$(dirname "$0")/.."
make -o avra libs >/dev/null
find corpus -name .avra-cache -type d -prune -exec rm -rf {} +
rm -rf .avra-cache
make census 'CMD=check corpus/census-input/packages/cli'

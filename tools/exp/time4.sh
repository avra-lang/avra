#!/bin/sh
# Cold `check packages/cli`, alternating the four compilers on identical input.
cd "$(dirname "$0")/../.."
for w in base A counter epoch; do [ -x build/avra.$w ] || echo "missing $w"; done
for i in 1 2 3 4 5; do
  for which in base A counter epoch; do
    rm -rf .avra-cache
    s=$(date +%s%N)
    build/avra.$which check packages/cli > /dev/null 2>&1 || echo "$which rc=$?"
    e=$(date +%s%N)
    echo "$which $(( (e - s) / 1000000 ))"
  done
done

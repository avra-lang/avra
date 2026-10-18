#!/bin/sh
# A cold check on each compiler variant that exists.
cd "$(dirname "$0")/../.."
for v in base header_only counter; do
  [ -x "build/avra.$v" ] || continue
  rm -rf .avra-cache
  if build/avra.$v check packages/std-text > "build/cold-$v.out" 2>&1; then echo "$v: ok"; else echo "$v: rc=$?"; fi
done

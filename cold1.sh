#!/bin/sh
# One cold `check packages/cli --time` round; prints the per-phase ms total.
label=$1
rm -rf .avra-cache
build/avra check packages/cli --time > cold1.out 2> cold1.err; rc=$?
total=$(grep "time:" cold1.err | tail -1 | sed 's/time: //' | tr ',' '\n' | sed 's/^ *[a-z ]* \([0-9]*\)ms.*/\1/' | awk '/^[0-9]+$/ {s+=$1} END {print s+0}')
echo "$label rc=$rc total_ms=$total"

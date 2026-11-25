#!/bin/sh
cp build/avra build/avra.builder; cp build/avra-try build/avra
CACHE_ATTACKS=tw sh tools/cache_attacks.sh > build/tw.out 2>&1
grep -a "FAIL" build/tw.out | head -3 | cut -c1-200
for d in build/cache-attacks/tw; do ls $d | head; done
build/avra build build/cache-attacks/tw 2>&1 | tail -25 | cut -c1-300
cp build/avra.builder build/avra

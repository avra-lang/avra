#!/bin/sh
for f in str_key int_key; do
  s=$(date +%s%N); build/avra run packages/std-relation/src/tests/bench_$f/bench_$f.av > b_$f.out 2>&1; rc=$?; e=$(date +%s%N)
  echo "$f rc=$rc ms=$(( (e - s) / 1000000 )) out=$(tail -1 b_$f.out | cut -c1-80)"
done

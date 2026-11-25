#!/bin/sh
for f in str_key int_key; do
  bin=packages/std-relation/src/tests/bench_$f/bench_$f
  valgrind --tool=callgrind --callgrind-out-file=cg_$f.out ./$bin > cg_run_$f.txt 2>&1; echo "$f callgrind rc=$?"
  callgrind_annotate cg_$f.out 2>/dev/null | head -45 > cg_$f.top
  grep "Collected" cg_run_$f.txt | cut -c1-120
done

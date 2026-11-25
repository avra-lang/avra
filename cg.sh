#!/bin/sh
# Native build of the string-keyed and int-keyed query benches, then callgrind's instruction counts.
for f in str_key int_key; do
  build/avra build packages/std-relation/src/tests/bench_$f/bench_$f.av > cg_build_$f.out 2>&1; echo "$f build rc=$?"
  bin=$(ls -t build/*/bench_$f 2>/dev/null | head -1); [ -z "$bin" ] && bin=$(find build -name "bench_$f" -type f 2>/dev/null | head -1)
  echo "$f bin=$bin"
  [ -n "$bin" ] && valgrind --tool=callgrind --callgrind-out-file=cg_$f.out "$bin" > cg_run_$f.txt 2>&1; echo "$f callgrind rc=$?"
  [ -f cg_$f.out ] && callgrind_annotate cg_$f.out 2>/dev/null | head -40 > cg_$f.top
done

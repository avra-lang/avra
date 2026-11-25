#!/bin/sh
# bench.sh <mode> <runs> <binary>...: cold timings, one line per run.
# mode fmt: fmt --check packages/std-avrac; mode check: check packages/cli
mode=$1; runs=$2; shift 2
export AVRA_CWD=$PWD
for i in $(seq 1 $runs); do
  for b in "$@"; do
    find .avra-cache -delete 2>/dev/null
    s=$(date +%s%N)
    if [ "$mode" = fmt ]; then
      out=$(build/$b fmt --check packages/std-avrac --time 2>&1 | grep '^time:')
    else
      out=$(build/$b check packages/cli --time 2>&1 | grep '^time:')
    fi
    e=$(date +%s%N)
    ast=$(echo "$out" | grep -oE 'ast [0-9.]+ms' | head -1)
    sub=$(echo "$out" | grep -oE 'sublang [0-9.]+ms' | head -1)
    echo "$b run$i wall $(( (e - s) / 1000000 ))ms $ast $sub"
  done
done

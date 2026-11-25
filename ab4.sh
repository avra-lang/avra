#!/bin/sh
set -u
cp build/avra build/avra.tip
sh tools/fetch_compiler.sh --key 36654d07ef803fd3bb703f8bdab96bf01388f3ab >/dev/null 2>&1 && cp build/avra build/avra.main
cp build/avra.tip build/avra
for b in main tip; do
  [ -d build/cold_$b ] && find build/cold_$b -delete
  s=$(date +%s%N); AVRA_CACHE_DIR=build/cold_$b build/avra.$b check --time packages/cli > build/cold_$b.out 2>&1
  echo "$b wall_ms=$(( ($(date +%s%N)-s)/1000000 )) $(grep -a '^time' build/cold_$b.out | grep -o 'refused [0-9]*') $(grep -a 'hold was refused' build/cold_$b.out | cut -c1-200)"
done

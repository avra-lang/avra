#!/bin/bash
for r in 1 2 3; do
  find . -maxdepth 4 -name .avra-cache -type d -prune -exec sh -c 'mv "$1" /tmp/avc.$$.$(date +%s%N)' _ {} \;
  s=$(date +%s%N); build/avra check packages/cli > /tmp/w.log 2>&1; st=$?; e=$(date +%s%N)
  echo "wall run $r: $(( (e - s) / 1000000 )) ms (exit $st) $(grep -o 'held [0-9]*/[0-9]*' /tmp/w.log | head -1)"
done

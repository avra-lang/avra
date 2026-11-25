#!/bin/sh
# usage: m.sh <binary>... — cli cold + 3 body edits per binary
F=packages/cli/src/commands/shared.av
for b in "$@"; do
  echo "=== $b"
  find .avra-cache -mindepth 1 -delete 2>/dev/null
  ./build/$b check --time packages/cli 2>&1 | grep "^time:" | cut -c1-400
  ./build/$b check --time packages/cli 2>&1 | grep "^time:" | cut -c1-200
  for i in 1 2 3; do
    sed -i "s/joined_path(\"build[0-9]*\", \"wasm32/joined_path(\"build$i\", \"wasm32/" $F
    AVRA_QTRACE=1 ./build/$b check --time packages/cli > /dev/null 2> .measure/q.err
    echo "edit $i: $(grep '^time:' .measure/q.err | cut -c1-400)"
    echo "  seals: $(grep -c 'Q	store	sealed' .measure/q.err) $(grep 'Q	store	sealed' .measure/q.err | tail -2 | tr '\t\n' '  ')"
  done
  git checkout -q -- $F
  cd .avra-cache/store
  for k in pack val log; do echo "$k $(ls -l *.$k 2>/dev/null | awk '{s+=$5; n++} END {print n+0, s+0}')"; done
  for f in $(ls body-*.pack | sort -t- -k2 -n); do python3 -I ../../.measure/bodystat.py $f 2>&1 | head -2; done
  python3 -I ../../.measure/bodystat.py --families $(ls -S body-*.pack | head -1)
  cd ../..
done

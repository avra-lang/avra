#!/bin/sh
# usage: probe_suspects.sh <file> <literal>
A=build/avra
f=$1; lit=$2
find . -name .avra-cache -type d -prune -exec rm -rf {} +
$A check packages/cli >/dev/null 2>&1
cp "$f" /tmp/probe.orig
for i in 1 2 3 4; do
  python3 - "$f" "$lit" "w$i$(date +%s%N)" <<'PY'
import sys
f,lit,w=sys.argv[1:4]
t=open(f).read(); open(f,'w').write(t.replace(lit,lit+" "+w,1))
PY
  AVRA_QTRACE=1 $A check --time packages/cli > /tmp/probe.out 2> /tmp/probe.err
  echo "round $i: $(grep -a '^Q.suspects' /tmp/probe.err | tail -1)"
  echo "  $(grep -a '^Q.holds' /tmp/probe.err | tail -1)"
  grep -a '^time:' /tmp/probe.out | cut -c1-260
done
cp /tmp/probe.orig "$f"

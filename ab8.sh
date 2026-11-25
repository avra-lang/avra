#!/bin/sh
# blocks, never alternating across one tree store: sh ab8.sh <bin>... ; each block starts cold
set -u
edit() { python3 -c "import sys,time;t=open(sys.argv[1]).read();open(sys.argv[1],'w').write(t.replace(sys.argv[2],sys.argv[2]+' e'+str(time.time_ns()),1))" "$1" "$2"; }
one() { cp "$3" build/ab.orig; edit "$3" "$4"; s=$(date +%s%N); $1 check --time --counts packages/cli > build/ab.out 2>&1; e=$(date +%s%N); cp build/ab.orig "$3"
  echo "$2 wall_ms=$(((e-s)/1000000)) $(grep -a '^time' build/ab.out | sed 's/.*load/load/') $(grep -a '^counts' build/ab.out | grep -oE 'rule_ms=[0-9]+|files_minted=[0-9]+')"; }
for B in "$@"; do
  [ -d .avra-cache ] && find .avra-cache -delete
  $B check packages/cli > /dev/null 2>&1; $B check packages/cli > /dev/null 2>&1
  for i in 1 2 3; do
    one $B "$(basename $B).receipt$i" packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'
    one $B "$(basename $B).cli$i" packages/cli/src/commands/shared.av '· memo'
    one $B "$(basename $B).avrac$i" packages/std-avrac/src/diagnostics/render.av '<source>'
  done
done

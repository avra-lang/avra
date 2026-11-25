#!/bin/sh
# traced edits with a pinned binary: sh ab2.sh <bin> <store>
set -u
BIN=$1; ST=$2
edit() { python3 -c "import sys,time;t=open(sys.argv[1]).read();open(sys.argv[1],'w').write(t.replace(sys.argv[2],sys.argv[2]+' q'+str(time.time_ns()),1))" "$1" "$2"; }
one() {
  cp "$2" build/ab.orig; edit "$2" "$3"
  AVRA_CACHE_DIR=$ST $BIN check --time packages/cli > /dev/null 2> build/ab2.$1.q
  cp build/ab.orig "$2"
  echo "== $1"; grep -aE '^Q	(holds|suspects)' build/ab2.$1.q; grep -a '^time' build/ab2.$1.q | cut -c1-400
  grep -a '^probe' build/ab2.$1.q | awk -F'\t' '{printf "%s=%s ",$2,$3} END{print ""}'
}
AVRA_CACHE_DIR=$ST $BIN check packages/cli > /dev/null 2>&1
for s in w1 w2; do one $s packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'; done
one receipt packages/std-avrac/src/compiler/format/receipt.av 'a token moved at position'
one cli packages/cli/src/commands/shared.av '· memo'
one avrac packages/std-avrac/src/diagnostics/render.av '<source>'

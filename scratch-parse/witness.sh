#!/bin/sh
# witness.sh BASE: the per-commit witnesses of build/avra against build/BASE.
base=$1
export AVRA_CWD=$PWD
build/$base diagnostics > /tmp/d.base 2>&1; build/avra diagnostics > /tmp/d.new 2>&1
if cmp -s /tmp/d.base /tmp/d.new; then echo "diagnostics: byte-identical, $(wc -l < /tmp/d.new) lines"; else echo "diagnostics: DIFFER"; diff /tmp/d.base /tmp/d.new | head; fi
find .avra-cache -delete 2>/dev/null
build/avra fmt --check packages 2>&1 | tail -1
sh scratch-parse/bench.sh check 3 $base avra

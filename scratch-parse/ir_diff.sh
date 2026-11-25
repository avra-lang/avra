#!/bin/bash
# ir_diff.sh A B: `avra ir` over every program test with both binaries, in parallel; counts and diffs.
export AVRA_CWD=$PWD A=$1 B=$2
mkdir -p /tmp/irdiff
find packages -path '*/tests/*' \( -name '*.expected' -o -name '*.refuses' -o -name '*.verdict' \) | sed 's/\.[a-z]*$/.av/' | sort -u > /tmp/irdiff/list
one() {
  f=$1; k=$(echo "$f" | tr '/' '_')
  [ -f "$f" ] || exit 0
  timeout 120 build/$A ir "$f" > /tmp/irdiff/$k.a 2>&1; ra=$?
  timeout 120 build/$B ir "$f" > /tmp/irdiff/$k.b 2>&1; rb=$?
  if [ $ra = $rb ] && cmp -s /tmp/irdiff/$k.a /tmp/irdiff/$k.b; then echo "SAME $ra $f"; else echo "DIFFER $ra $rb $f"; fi
}
export -f one
xargs -P 3 -I{} bash -c 'one "$1"' _ {} < /tmp/irdiff/list > /tmp/irdiff/results
grep ^DIFFER /tmp/irdiff/results | head -20
echo "ir: $(wc -l < /tmp/irdiff/results) programs, differing=$(grep -c ^DIFFER /tmp/irdiff/results), timed out=$(grep -c ' 124 ' /tmp/irdiff/results), lowered clean=$(grep -c '^SAME 0' /tmp/irdiff/results)"

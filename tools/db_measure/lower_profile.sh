#!/bin/sh
# follow-up on the warm one-edit `check packages/cli`: phases, then
# the edit's asks and settles per family (AVRA_QTRACE / AVRA_DB_GRAPH).
cd "$(dirname "$0")/../.." || exit 1
A=./avra
pkg=packages/cli
f=packages/cli/src/commands/shared.av
lit='· memo'
out=build/lp

echo "== cold (warms the store) =="
$A check --time $pkg > $out.0 2>&1
grep -E '^time:' $out.0 | tail -1

echo "== warm noop =="
$A check --time $pkg > $out.1 2>&1
grep -E '^time:' $out.1 | tail -1

cp "$f" $out.orig
python3 - "$f" "$lit" <<'PY'
import sys, time
p, lit = sys.argv[1], sys.argv[2]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace(lit, lit + " lp%d" % time.time_ns(), 1))
PY

echo "== warm edit (phases) =="
$A check --time $pkg > $out.3 2>&1
grep -E '^time:' $out.3 | tail -1

echo "== warm edit, asks per family =="
AVRA_QTRACE=1 $A check $pkg > $out.q 2>&1
python3 tools/db_measure/graph.py --qtrace $out.q packages/std-avrac/src/compiler/families/families.av 2>&1 | head -30

echo "== warm edit, settled cells per family =="
AVRA_DB_GRAPH=1 $A check $pkg > $out.g 2>&1
python3 tools/db_measure/graph.py --m1 $out.g packages/std-avrac/src/compiler/families/families.av 2>&1 | head -30

cp $out.orig "$f"
echo "== restored =="

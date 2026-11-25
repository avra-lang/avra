#!/bin/sh
# A fresh speed/memory reference of the daily loop on current origin/main:
# cold `build packages/cli --time` (keep, AVRA_MEM_STATS peak) and the warm
# one-edit `check packages/cli` phases (shared.av literal move).
cd "$(dirname "$0")/../.." || exit 1
P=packages/cli
R=build/loop-ref
mkdir -p "$R"
f=packages/cli/src/commands/shared.av
lit='· memo'

echo "== 1. cold build $P (AVRA_MEM_STATS) =="
AVRA_MEM_STATS=1 ./avra build "$P" --time > "$R/coldbuild.out" 2>&1
echo "exit $?"
grep -E "^time:" "$R/coldbuild.out" | tail -1
grep -E "^mem: peak|^mem: live" "$R/coldbuild.out" | head -3

echo "== 2. warm no-op build =="
./avra build "$P" --time > "$R/noopbuild.out" 2>&1
grep -E "^time:" "$R/noopbuild.out" | tail -1

echo "== 3. cold check $P =="
./avra check "$P" --time > "$R/coldcheck.out" 2>&1
grep -E "^time:" "$R/coldcheck.out" | tail -1

echo "== 4. warm no-op check =="
./avra check "$P" --time > "$R/noopcheck.out" 2>&1
grep -E "^time:" "$R/noopcheck.out" | tail -1

cp "$f" "$R/shared.orig"
python3 - "$f" "$lit" <<'PY'
import sys, time
p, lit = sys.argv[1], sys.argv[2]
t = open(p, encoding="utf-8").read()
assert lit in t, lit
open(p, "w", encoding="utf-8").write(t.replace(lit, lit + " ref%d" % time.time_ns(), 1))
PY

echo "== 5. warm one-edit check =="
./avra check "$P" --time > "$R/editcheck.out" 2>&1
grep -E "^time:" "$R/editcheck.out" | tail -1
cp "$R/shared.orig" "$f"
echo "== restored =="

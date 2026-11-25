#!/bin/sh
# ONE SIDE OF THE #503 A/B, on a Sprite:
#   # pre  = 08c5019 (5ef6c8a^)   post = 5ef6c8a (#503)
#   git checkout <commit>
#   sh tools/work run sh tools/db_measure/ab503.sh <pre|post>
# Cold build packages/cli --time (keep, AVRA_MEM_STATS peak), then the warm
# no-op and the shared.av one-edit check phases. Results in /tmp/ab503-<label>
# on the Sprite, so the other side can be compared there.
set -u
cd "$(dirname "$0")/../.." || exit 1
label=${1:-side}
out=/tmp/ab503-$label
mkdir -p "$out"
P=packages/cli
f=packages/cli/src/commands/shared.av
lit='· memo'

find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null

echo "== $label: cold build $P =="
AVRA_MEM_STATS=1 ./avra build "$P" --time > "$out/coldbuild.out" 2>&1
echo "cold exit $?"
grep -E '^time:' "$out/coldbuild.out" | tail -1
grep -E '^mem: peak|^mem: live' "$out/coldbuild.out" | head -3

echo "== $label: warm no-op check =="
./avra check "$P" --time > "$out/noopcheck.out" 2>&1
grep -E '^time:' "$out/noopcheck.out" | tail -1

cp "$f" "$out/shared.orig"
python3 - "$f" "$lit" "$label" <<'PY'
import sys, time
p, lit, label = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace(lit, lit + " %s%d" % (label, time.time_ns()), 1))
PY

echo "== $label: warm one-edit check =="
./avra check "$P" --time > "$out/editcheck.out" 2>&1
grep -E '^time:' "$out/editcheck.out" | tail -1

cp "$out/shared.orig" "$f"
echo "results in $out"
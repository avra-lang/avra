#!/bin/sh
# The warm one-edit `check packages/cli`, sampled, on the Mac.
cd "$(dirname "$0")/../.." || exit 1
f=packages/cli/src/commands/shared.av
lit='· memo'
prof=build/avra-sample-lower.txt

echo "== warm noop phases =="
sh tools/watch.sh 4000 ./avra check --time packages/cli > build/mm.noop 2>&1
grep -E '^time:' build/mm.noop | tail -1

cp "$f" build/mm.orig
python3 - "$f" "$lit" <<'PY'
import sys, time
p, lit = sys.argv[1], sys.argv[2]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace(lit, lit + " mm%d" % time.time_ns(), 1))
PY

echo "== warm edit phases =="
sh tools/watch.sh 4000 ./avra check --time packages/cli > build/mm.edit 2>&1
grep -E '^time:' build/mm.edit | tail -1

echo "== warm edit, sampled =="
AVRA_SAMPLE=${AVRA_SAMPLE:-25} AVRA_SAMPLE_AFTER=${AVRA_SAMPLE_AFTER:-1} AVRA_SAMPLE_FILE=$prof \
    sh tools/watch.sh 4000 ./avra check packages/cli > build/mm.sample 2>&1
head -1 "$prof" 2>/dev/null

cp build/mm.orig "$f"
echo "== restored =="

#!/bin/sh
# One warm one-edit `check packages/cli`, sampled. shared.av is always
# restored, even if this is killed.
cd "$(dirname "$0")/../.." || exit 1
f=packages/cli/src/commands/shared.av
lit='· memo'
prof=build/avra-sample-lower.txt
cp "$f" build/ms.orig
restore() { cp build/ms.orig "$f"; echo "restored"; }
trap restore EXIT INT TERM
python3 - "$f" "$lit" <<'PY'
import sys, time
p, lit = sys.argv[1], sys.argv[2]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace(lit, lit + " ms%d" % time.time_ns(), 1))
PY
AVRA_SAMPLE=${AVRA_SAMPLE:-40} AVRA_SAMPLE_AFTER=0 AVRA_SAMPLE_FILE=$prof \
    sh tools/watch.sh 4000 ./avra check --time packages/cli > build/ms.out 2>&1
grep -E '^time:' build/ms.out | tail -1
head -2 "$prof" 2>/dev/null

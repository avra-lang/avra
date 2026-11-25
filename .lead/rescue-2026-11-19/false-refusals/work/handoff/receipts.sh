#!/bin/sh
# The receipt run used for each bundle, as run in this lane. Usage: sh receipts.sh <base-ref> <log>
# Run from /work/avra after `source /etc/profile.d/avra.sh`. Never edit the tree while it runs.
base=${1:-batch53}; log=${2:-/tmp/receipts.log}
cd /work/avra || exit 1
make try > /dev/null 2>&1; echo "make try $? ($(git rev-parse --short HEAD))" > "$log"
build/avra fmt --check $(git diff --name-only "$base"..HEAD -- '*.av') | tail -1 >> "$log"
AVRA_MEM_CEILING_MB=12000 build/avra check packages/cli --baseline tools/idioms.baseline > /tmp/idioms.log 2>&1; echo "idioms $?" >> "$log"
for p in std-time std-task; do build/avra-try tapes packages/$p --program-runs > /tmp/runs-$p.log 2>&1; echo "runs $p: $(grep '^ran:' /tmp/runs-$p.log | cut -c1-200)" >> "$log"; done
for s in avrac-a avrac-b avrac-c avrac-d avrac-e avrac-f avrac-g; do sh tools/gate.sh $s > /tmp/gate-$s.log 2>&1; tail -1 /tmp/gate-$s.log >> "$log"; done
AVRA_PROGRAM=1 build/avra check packages/std-avrac > /tmp/check.log 2>&1; echo "check std-avrac exit $?" >> "$log"
AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 build/avra build packages/cli > /tmp/cli.log 2>&1; echo "cli $?" >> "$log"
sh tools/witness_program_refusal.sh build/avra > /tmp/wref.log 2>&1; tail -1 /tmp/wref.log >> "$log"
sh tools/witness_program_runs.sh > /tmp/wruns.log 2>&1; echo "witness_program_runs $? $(tail -1 /tmp/wruns.log)" >> "$log"
echo done >> "$log"

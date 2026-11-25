#!/bin/sh
# the receipt slices, one after another, each line of their verdicts into receipts.log
. /etc/profile.d/avra.sh
cd /work/avra
log=/work/probes/receipts.log
for s in "$@"; do
  echo "== $s start $(date +%H:%M:%S)" >> $log
  sh tools/gate.sh $s > /work/probes/gate-$s.out 2>&1
  tail -1 /work/probes/gate-$s.out >> $log
done
echo "== ALL DONE $(date +%H:%M:%S)" >> $log

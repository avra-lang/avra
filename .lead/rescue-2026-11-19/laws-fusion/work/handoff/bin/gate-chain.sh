#!/bin/sh
# Runs the receipts' gate slices one after another in /work/gate-wt; one GATE line each.
. /etc/profile.d/avra.sh
cd /work/gate-wt
log=/work/out/gate-chain.log
echo "start $(date +%T)" >> $log
sh tools/gate.sh seed > /work/out/gate-seed.log 2>&1; echo "seed exit $? $(tail -1 /work/out/gate-seed.log) $(date +%T)" >> $log
for s in "$@"; do
  sh tools/gate.sh $s $( [ "${s#idioms}" != "$s" ] && echo 912fc732 ) > /work/out/gate-$s.log 2>&1
  echo "$(tail -1 /work/out/gate-$s.log) $(date +%T)" >> $log
done
echo "DONE $(date +%T)" >> $log

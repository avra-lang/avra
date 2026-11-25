#!/bin/sh
# Runs each spec directory's suite, stopping once the cases have reported.
. /etc/profile.d/avra.sh
cd /work/avra; unset AVRA_SPEC_DIFFERENTIAL
mkdir -p /tmp/runsK
for d in $(awk '{print $2}' /tmp/inv/dirs.txt); do
  n=$(echo $d | tr '/' '_')
  log=/tmp/runsK/$n.log
  [ -s "$log.done" ] && continue
  build/avra test packages/std-avrac/$d > $log 2>&1 &
  pid=$!
  while kill -0 $pid 2>/dev/null; do
    if grep -q 'tests passed\|^avra: while running' $log; then sleep 3; kill $pid 2>/dev/null; pkill -P $pid 2>/dev/null; break; fi
    sleep 5
  done
  wait $pid 2>/dev/null
  echo "$d $(grep -c '✗' $log) $(grep 'tests passed' $log) $(grep -c '^avra: while running' $log)" > $log.done
  cat $log.done
done
echo ALLDONE

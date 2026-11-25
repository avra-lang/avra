#!/bin/sh
# guarded.sh <compiler> <out> : every program test under the features with early exits, errdefer,
# defers and loops built with <compiler>, its binary run under AVRA_RC_GUARD=1, and its output held
# to its .expected; one line a test
. /etc/profile.d/avra.sh; export AVRA_PROGRAM_NET=0 AVRA_STORE_KEPT_HERE=1
C=$1; out=$2; : > $out
for exp in $(find /work/avra/packages/std-avrac/src/features/fns/tests /work/avra/packages/std-avrac/src/features/defers/tests /work/avra/packages/std-avrac/src/features/loops/tests /work/avra/packages/std-avrac/src/features/results/tests /work/avra/packages/std-avrac/src/features/nullable/tests -name '*.expected' | sort); do
  d=$(dirname $exp); n=$(basename $exp .expected); src=$d/$n.av; [ -f $src ] || continue
  w=/tmp/guarded-run/$n; find $w -delete 2>/dev/null; mkdir -p $w; cp $d/*.av $w/ 2>/dev/null
  timeout 200 $C build $w/$n.av > $w/build.log 2>&1 || { echo "$n BUILD-FAIL" >> $out; continue; }
  got=$(cd $w && AVRA_RC_GUARD=1 timeout 30 ./$n 2>&1; echo "status=$?")
  want=$(cat $exp; echo "status=0")
  if [ "$got" = "$want" ]; then echo "$n ok" >> $out; else echo "$n DIFF $(printf '%s' "$got" | tail -2 | tr '\n' ' ' | cut -c1-120)" >> $out; fi
done

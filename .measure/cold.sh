#!/bin/sh
# cold cli check under the trace: phases, then every seal and its cost
for b in "$@"; do
  echo "=== $b"
  find .avra-cache -mindepth 1 -delete 2>/dev/null
  AVRA_QTRACE=1 ./build/$b check --time packages/cli > /dev/null 2> .measure/cold.err
  grep '^time:' .measure/cold.err | cut -c1-500
  grep -c 'Q	store	sealed' .measure/cold.err
  grep 'Q	store	sealed' .measure/cold.err | awk -F'\t' '{n++; us+=$7+0} END {print "seals", n, "total us", us}'
  grep 'Q	store	sealed' .measure/cold.err | tail -5 | tr '\t' ' '
  echo "puts $(grep -c 'Q	store	kind	has' .measure/cold.err) has, $(grep -c 'Q	store	kind	get' .measure/cold.err) get"
done

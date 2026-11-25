#!/bin/sh
for l in NP1; do
  for k in cold edit; do
    echo "$l $k $(grep 'time:' x_$l.$k.err | tail -1 | sed 's/time: //' | cut -c1-200)"
  done
done

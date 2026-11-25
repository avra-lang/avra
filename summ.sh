#!/bin/sh
for l in A2 B2 A3 B3; do
  for k in cold same edit; do
    f=x_$l.$k.err
    echo "$l $k $(grep 'time:' $f | tail -1 | sed 's/time: //' | cut -c1-200)"
  done
done

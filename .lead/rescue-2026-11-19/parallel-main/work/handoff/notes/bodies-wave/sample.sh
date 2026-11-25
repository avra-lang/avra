#!/bin/sh
# usage: sample.sh out cmd...   samples per-process cpu ticks every 0.25s
out=$1; shift
"$@" &
root=$!
t0=$(date +%s.%N)
while kill -0 $root 2>/dev/null; do
  now=$(date +%s.%N)
  for p in $(pgrep -g $(ps -o pgid= -p $root | tr -d ' ') 2>/dev/null); do
    [ -r /proc/$p/stat ] && awk -v t="$now" -v t0="$t0" '{n=split($0,a,") "); split(a[n],b," "); c=$0; sub(/^[0-9]+ \(/,"",c); sub(/\).*/,"",c); printf "%.2f %s %s %s %d %d\n", t-t0, $1, c, b[2], b[12]+b[13], b[1]=="R"}' /proc/$p/stat 2>/dev/null
  done
  sleep 0.25
done >> $out
wait $root

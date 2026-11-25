#!/bin/sh
for n in 2 4 8 16; do
  echo "== n=$n"; python3 ru.py build/cs.out build/cs.err build/avra check scratch_codec/n$n; grep -ac "^error" build/cs.out; head -c 300 build/cs.out
done

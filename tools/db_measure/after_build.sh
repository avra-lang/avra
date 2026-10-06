#!/bin/bash
# the first check after a build, one body-string edit in between: wall and the phase line, twice over
export AVRA_MEM_CEILING_MB=5000 LLVM_PREFIX=/usr/lib/llvm-22
make -s -o avra objects libs > /dev/null 2>&1
P=packages/cli; F=$P/src/commands/shared.av; cp $F /tmp/shared.orig
for n in 1 2; do
  find . -name .avra-cache -type d -prune -exec rm -rf {} +
  build/avra check $P > /dev/null 2>&1; ./avra build $P > /dev/null 2>&1
  sed "s/· memo/· memo r$n/" /tmp/shared.orig > $F
  s=$(date +%s%N); build/avra check --time $P > /tmp/ab.txt 2>&1; e=$(date +%s%N)
  echo "sample $n: wall_ms $(((e-s)/1000000)) $(grep -a '^time:' /tmp/ab.txt | grep -o 'held.*')"
  grep -a '^  discarded:' /tmp/ab.txt | cut -c1-160
  cp /tmp/shared.orig $F
done
echo FINISHED

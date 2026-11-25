AV=$PWD/build/avra-try
AVRA_QTRACE=1 $AV check packages/cli > /tmp/cli1.out 2>/tmp/cli1.trace; echo edit=$?
grep -a "PROBE" /tmp/cli1.trace | head -30 | cut -c1-200
grep -a "declaration 1" /tmp/cli1.trace | cut -c1-100

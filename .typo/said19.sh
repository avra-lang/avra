AV=$PWD/build/avra-try
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
grep -a "PROBE open" /tmp/c1.trace | cut -c1-100

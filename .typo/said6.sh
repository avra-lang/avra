AV=$PWD/build/avra-try
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
grep -a "^avra:" /tmp/c1.trace | cut -c1-120
grep -a "PROBE" /tmp/c1.trace | sort | uniq -c | sort -rn | head -14 | cut -c1-200

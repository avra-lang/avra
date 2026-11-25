AV=$PWD/build/avra-try
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
grep -a "^avra:" /tmp/c1.trace | cut -c1-120
grep -a "PROBE dw\|PROBE exp-run\|PROBE mwb\|PROBE gk" /tmp/c1.trace | head -30 | cut -c1-300

AV=$PWD/build/avra-try
$AV check packages/cli > /tmp/cli0.out 2>&1; echo cold=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
AVRA_QTRACE=1 $AV check packages/cli > /tmp/cli1.out 2>/tmp/cli1.trace; echo edit=$?
tail -3 /tmp/cli1.out | cut -c1-300
grep -a "PROBE" /tmp/cli1.trace | head -40

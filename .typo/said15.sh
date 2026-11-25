AV=$PWD/build/avra-try
$AV check packages/cli > /tmp/c0.out 2>&1; echo cold=$?
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
AVRA_DB_GRAPH=1 AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
tail -60 /tmp/c1.trace | cut -c1-200

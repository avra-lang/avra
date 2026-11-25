AV=$PWD/build/avra-try
git checkout -q -- packages/cli
mv .avra-cache .avra-cache.aside.$(date +%s) 2>/dev/null
$AV check packages/cli > /tmp/c0.out 2>&1; echo cold=$?
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
grep -a "PROBE open" /tmp/c1.trace | cut -c1-100

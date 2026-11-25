AV=$PWD/build/avra-try
printf '  // repro\n' >> packages/cli/src/commands/shared.av
s=$(date +%s); AVRA_QTRACE=1 $AV check packages/cli > /tmp/cli1.out 2>/tmp/cli1.trace; echo edit=$? $(( $(date +%s) - s ))s
grep -a "PROBE" /tmp/cli1.trace | head -20 | cut -c1-200
grep -a "^avra:" /tmp/cli1.trace | cut -c1-120
s=$(date +%s); $AV check packages/cli > /tmp/cli2.out 2>&1; echo unchanged=$? $(( $(date +%s) - s ))s
tail -2 /tmp/cli2.out | cut -c1-200

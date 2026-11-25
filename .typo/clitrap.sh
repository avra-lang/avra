AV=$PWD/build/avra-try
s=$(date +%s); $AV check packages/cli > /tmp/cli0.out 2>&1; echo cold=$? $(( $(date +%s) - s ))s
printf '  // repro\n' >> packages/cli/src/commands/shared.av
s=$(date +%s); AVRA_QTRACE=1 $AV check --counts packages/cli > /tmp/cli1.out 2>/tmp/cli1.trace; echo edit=$? $(( $(date +%s) - s ))s
tail -6 /tmp/cli1.out | cut -c1-300
grep -ac "^Q.parse" /tmp/cli1.trace | sed 's/^/parses: /'
s=$(date +%s); $AV check packages/cli > /tmp/cli2.out 2>&1; echo unchanged=$? $(( $(date +%s) - s ))s

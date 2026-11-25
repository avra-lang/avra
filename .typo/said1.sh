AV=$PWD/build/avra-try
$AV check packages/cli > /tmp/c0.out 2>&1; echo cold=$?
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
s=$(date +%s); AVRA_QTRACE=1 $AV check --counts packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$? $(( $(date +%s) - s ))s
grep -a "^avra:" /tmp/c1.trace | cut -c1-200
grep -a "^Q.said" /tmp/c1.trace | cut -f2 | sort | uniq -c
grep -a "^Q.said.false" /tmp/c1.trace | head -12 | cut -c1-160
grep -a "files_parsed" /tmp/c1.out | cut -c1-200

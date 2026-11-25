AV=$PWD/build/avra-try
git checkout -q -- packages/cli
mv .avra-cache .avra-cache.aside.$(date +%s) 2>/dev/null
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c0.out 2>/tmp/c0.trace; echo cold=$?
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
AVRA_QTRACE=1 $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.trace; echo edit=$?
grep -a "PROBE member" /tmp/c0.trace | sort -u > /tmp/m0.txt
grep -a "PROBE member" /tmp/c1.trace | sort -u > /tmp/m1.txt
wc -l /tmp/m0.txt /tmp/m1.txt
diff /tmp/m0.txt /tmp/m1.txt | head -20

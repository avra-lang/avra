AV=$PWD/build/avra-try
mv .avra-cache .avra-cache.aside.$(date +%s) 2>/dev/null
git checkout -q -- packages/cli
$AV check packages/cli > /tmp/c0.out 2>&1; echo cold=$?
$AV check packages/cli > /tmp/c0b.out 2>&1; echo again=$?
printf '  // repro\n' >> packages/cli/src/commands/shared.av
s=$(date +%s); $AV check packages/cli > /tmp/c1.out 2>/tmp/c1.err; echo edit=$? $(( $(date +%s) - s ))s
grep -a "^avra:" /tmp/c1.err | cut -c1-200
s=$(date +%s); $AV check packages/cli > /tmp/c2.out 2>/tmp/c2.err; echo unchanged=$? $(( $(date +%s) - s ))s
grep -a "^avra:" /tmp/c2.err | cut -c1-200

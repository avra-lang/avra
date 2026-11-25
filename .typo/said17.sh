AV=$PWD/build/avra-try
s=$(date +%s); $AV check packages/cli > /tmp/c3.out 2>/tmp/c3.err; echo notrace-edit=$? $(( $(date +%s) - s ))s
grep -a "^avra:" /tmp/c3.err | cut -c1-200

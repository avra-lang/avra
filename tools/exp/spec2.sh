#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for p in std-http std-https site; do
  build/avra test packages/$p > /tmp/s.$p.log 2>&1; echo "test $p status $?"
  grep -a "tests passed\|✗\|eval ==\|eval !=\|STOPPED\|refuses\|error\[" /tmp/s.$p.log | head -25 | cut -c1-260
done
build/avra check packages/cli > /tmp/s.cli.log 2>&1; echo "check cli status $?"; grep -a "error\[" /tmp/s.cli.log | head -10 | cut -c1-240

#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for p in std-validate std-db; do build/avra check packages/$p > /tmp/c.$p.log 2>&1; echo "check $p status $?"; grep -a "^error" -A7 /tmp/c.$p.log | head -30 | cut -c1-220; done
for p in std-validate std-db; do build/avra test packages/$p > /tmp/ct.$p.log 2>&1; echo "test $p status $?"; grep -a "tests passed\|✗\|STOPPED\|eval ==\|eval !=" /tmp/ct.$p.log | head -8 | cut -c1-220; done
build/avra check --baseline tools/idioms.baseline packages/std-db > /tmp/c.i.log 2>&1; echo "idioms std-db status $?"; grep -a "NEW violation" -A6 /tmp/c.i.log | head -10 | cut -c1-220

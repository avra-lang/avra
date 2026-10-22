#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra test packages/std-db > /tmp/b.log 2>&1; echo "test std-db status $?"; grep -a "tests passed\|✗\|eval ==\|STOPPED" /tmp/b.log | head -6
build/avra check --baseline tools/idioms.baseline packages/std-db > /tmp/b.i.log 2>&1; echo "idioms std-db status $?"; grep -a "NEW violation" -A6 /tmp/b.i.log | head -12 | cut -c1-220

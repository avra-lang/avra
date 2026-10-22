#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra test packages/std-http > /tmp/s.log 2>&1; echo "test std-http status $?"; grep -a "tests passed\|✗\|eval ==\|eval !=\|STOPPED\|refuses" /tmp/s.log | head -40 | cut -c1-260

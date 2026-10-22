#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra test packages/std-http > /tmp/s3.log 2>&1; echo "status $?"
grep -a "✗\|tests passed\|eval !=\|STOPPED" /tmp/s3.log | cut -c1-200 | head

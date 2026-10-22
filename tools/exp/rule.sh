#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra test packages/std-db > /tmp/r.db.log 2>&1; echo "test std-db status $?"; grep -a "tests passed\|✗" /tmp/r.db.log | head -5
build/avra check packages/std-avrac > /tmp/r.avrac.log 2>&1; echo "check std-avrac status $?"; grep -a "^error" -A6 /tmp/r.avrac.log | head -20 | cut -c1-200
make idioms > /tmp/r.idioms.log 2>&1; echo "make idioms status $?"; tail -15 /tmp/r.idioms.log | cut -c1-220

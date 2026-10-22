#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
ls -l build/avra | cut -c1-100
build/avra check packages/std-db > /tmp/rep.log 2>&1; echo "check std-db status $?"; cat /tmp/rep.log | cut -c1-240 | head -40

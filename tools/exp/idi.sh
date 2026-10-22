#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check --baseline tools/idioms.baseline packages/std-db 2>&1 | grep -a "^idioms\|NEW\|^  .*\[" | head -12 | cut -c1-220
echo "idioms status $?"

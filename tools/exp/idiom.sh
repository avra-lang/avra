#!/bin/sh
[ -d tools ] || exit 70
build/avra check --baseline tools/idioms.baseline packages/std-db > /tmp/idiom.log 2>&1; echo "idioms std-db status $?"
grep -a -B1 -A6 "^error\|NEW\|new site" /tmp/idiom.log | head -40 | cut -c1-220

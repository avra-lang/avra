#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
make rt-header > /tmp/l.hdr.log 2>&1 && echo "PASS make rt-header" || { echo "FAIL make rt-header"; tail -6 /tmp/l.hdr.log; }
build/avra test packages/std-assets > /tmp/l.a.log 2>&1; echo "test std-assets status $?"; grep -a "tests passed\|✗\|^error" /tmp/l.a.log | head -5
make bootstrap > /tmp/l.boot.log 2>&1; echo "make bootstrap status $?"; grep -a "gen\|generation\|fixed point\|PASS\|FAIL" /tmp/l.boot.log | tail -12 | cut -c1-200; tail -4 /tmp/l.boot.log | cut -c1-200

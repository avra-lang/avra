#!/bin/sh
[ -d tools ] || exit 70
build/avra test packages/std-http/src/tests/http_router > /tmp/r2.log 2>&1; echo "test http_router status $?"; grep -a "eval ==\|eval !=" /tmp/r2.log | head -2
build/avra test packages/std-http/src/tests/server_components_test.av > /tmp/r3.log 2>&1; echo "test server_components status $?"; grep -a "tests passed" /tmp/r3.log | head -1
for p in cli site std-http; do build/avra check packages/$p > /tmp/r.c.$p.log 2>&1; echo "check $p status $?"; grep -a "^error" -A5 /tmp/r.c.$p.log | head -8 | cut -c1-200; done
make bootstrap > /tmp/boot.log 2>&1; echo "make bootstrap status $?"; grep -a "bootstrap:" /tmp/boot.log | tail -4 | cut -c1-200

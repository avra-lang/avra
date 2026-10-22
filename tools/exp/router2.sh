#!/bin/sh
[ -d tools ] || exit 70
build/avra test packages/std-http/src/tests/http_router > /tmp/r2.log 2>&1; echo "test http_router status $?"; grep -a "eval ==\|eval !=" /tmp/r2.log | head -3; grep -a -v "^warning\|^ \|^[0-9]* │\|^─\|^$\|^help\|^proofs" /tmp/r2.log | tail -14 | cut -c1-200

#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for f in packages/std-http/src/tests/http_router packages/std-http/src/tests/http_server_decl packages/std-http/src/tests/server_components_test.av packages/std-http/src/tests/route_components_test.av packages/std-http/src/tests/route_test.av; do build/avra test $f > /tmp/r.log 2>&1; echo "test $f status $?"; grep -a "tests passed\|✗\|eval ==\|eval !=\|DIFFERS" /tmp/r.log | head -4 | cut -c1-200; grep -a -v "^warning\|^ \|^[0-9]* │\|^─\|^$\|^help\|^proofs" /tmp/r.log | tail -6 | cut -c1-200; done
for p in std-openapi site cli std-http; do build/avra check packages/$p > /tmp/r.c.$p.log 2>&1; echo "check $p status $?"; grep -a "^error" -A5 /tmp/r.c.$p.log | head -10 | cut -c1-200; done
build/avra check --baseline tools/idioms.baseline packages/std-http > /tmp/r.i.log 2>&1; echo "idioms std-http status $?"; grep -a "NEW violation" -A4 /tmp/r.i.log | head -8 | cut -c1-200

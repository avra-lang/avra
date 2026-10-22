#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for t in externs rt-header rt-ns inputs vocab; do make $t > /tmp/k.$t.log 2>&1 && v=PASS || v=FAIL; echo "$v make $t"; [ $v = FAIL ] && tail -8 /tmp/k.$t.log | cut -c1-240; done
for f in packages/std-avrac/src/features/asset/tests/hygiene packages/std-avrac/src/features/fns/tests/provided_test.av packages/std-avrac/src/core/tests/runtime_reach_test.av packages/std-avrac/src/core/tests/runtime_header_test.av; do build/avra test $f > /tmp/k.t.log 2>&1; echo "test $f status $?"; grep -a "tests passed\|✗\|!=\|differs\|const.reach" /tmp/k.t.log | head -5 | cut -c1-200; done

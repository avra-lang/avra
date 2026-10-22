#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for t in packages/std-ui/src/tree/tests/identity_test.av packages/std-ui/src/tree/tests/view_test.av packages/std-ui/src/tree/tests/url_test.av packages/std-ui/src/tests/vocabulary_test.av packages/std-ui/src/tests/keyed_list; do
  build/avra test $t > /tmp/p.log 2>&1; echo "$t status $?"; grep -a "✗\|passed\|error\[\|eval" /tmp/p.log | cut -c1-200 | head -4
done

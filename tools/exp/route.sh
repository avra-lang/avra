#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
T=packages/std-http/src/tests
for t in $T/route_test.av $T/route_adversarial_test.av $T/route_components_test.av $T/server_components_test.av $T/http_router $T/http_specificity $T/http_clash $T/http_server_decl; do
  build/avra test $t > /tmp/r.log 2>&1; echo "$t status $?"; grep -a "✗\|passed\|eval\|^error" /tmp/r.log | cut -c1-200 | head -5
done
build/avra check packages/cli > /tmp/r.cli 2>&1; echo "check cli $?"; grep -a "^error" /tmp/r.cli | head -3

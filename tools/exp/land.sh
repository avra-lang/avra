#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra test packages/std-db/src/tests/landing > /tmp/l.log 2>&1; echo "landing $?"; grep -a "eval\|FAILED" /tmp/l.log | cut -c1-160

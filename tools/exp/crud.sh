#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check packages/std-crud > /tmp/cr.c 2>&1; echo "check $?"; grep -a "^error" -A5 /tmp/cr.c | head -60 | cut -c1-220
build/avra test packages/std-crud/src/tests/crud_board > /tmp/cr.t 2>&1; echo "test $?"; head -40 /tmp/cr.t | cut -c1-300
grep -a -c "std-crud.*crud.av" /tmp/cr.t

build/avra check --baseline tools/idioms.baseline packages/std-crud 2>&1 | grep -a "NEW" -A4 | head -8 | cut -c1-220

#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check --baseline tools/idioms.baseline packages/std-db 2>&1 | grep -a "NEW" -A6 | head -10 | cut -c1-200; echo "idioms std-db done"
build/avra check --baseline tools/idioms.baseline packages/std-sqlite 2>&1 | grep -a "NEW" -A6 | head -10 | cut -c1-200
build/avra test packages/std-db > /tmp/sw.t1 2>&1; echo "test std-db $?"; grep -a "passed\|✗\|eval !=\|FAILED" /tmp/sw.t1 | head -8 | cut -c1-200
build/avra test packages/std-sqlite > /tmp/sw.t2 2>&1; echo "test std-sqlite $?"; grep -a "passed\|✗\|eval !=\|FAILED" /tmp/sw.t2 | head -8 | cut -c1-200

#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1; echo "make objs $?"
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check packages/std-db > /tmp/mig.check 2>&1; echo "check std-db status $?"; grep -a "^error" -A4 /tmp/mig.check | cut -c1-220 | head -40
for t in apply_test migrate_test; do
  build/avra test packages/std-db/src/tests/$t.av > /tmp/mig.log 2>&1; echo "$t status $?"; grep -a "✗\|passed\|^error" /tmp/mig.log | cut -c1-230 | head -8
done

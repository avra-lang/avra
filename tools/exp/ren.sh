#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check packages/std-db > /tmp/ren.c 2>&1; echo "check $?"; grep -a "^error" -A4 /tmp/ren.c | head -20 | cut -c1-220
for t in apply_test migrate_test db_test db_adversarial_test model_relations_test model_queries_test model_shape_test; do
  build/avra test packages/std-db/src/tests/$t.av > /tmp/ren.log 2>&1; echo "$t $?"; grep -a "✗\|passed" /tmp/ren.log | cut -c1-200 | head -3
done

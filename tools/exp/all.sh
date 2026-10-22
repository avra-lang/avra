#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
build/avra check packages/std-db > /tmp/all.c 2>&1; echo "check $?"; grep -a "^error" -A4 /tmp/all.c | head -24 | cut -c1-230
for t in db_collision_test two_packages migrate_all apply_test db_test db_adversarial_test model_relations_test model_queries_test model_shape_test model_checked_test landing; do
  p=packages/std-db/src/tests/$t; [ -d $p ] || p=$p.av
  build/avra test $p > /tmp/all.log 2>&1; echo "$t $?"; grep -a "✗\|passed\|eval\|FAILED\|^error" -A3 /tmp/all.log | cut -c1-260 | head -14
done

#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
f=packages/std-db/src/apply.av
cp $f /tmp/apply.good
try() {
  sed "$1" /tmp/apply.good > $f
  find .avra-cache.aside.* -delete 2>/dev/null
  [ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
  build/avra test packages/std-db/src/tests/apply_test.av > /tmp/m3.log 2>&1
  echo "== $2"; grep -a "✗\|passed" /tmp/m3.log | cut -c1-150 | head -4
}
try 's/    let _ = copied(db)?/    let _ = 0/' "no copy"
tail -3 /tmp/m3.log | cut -c1-200
try 's/^fn restamp_sql() -> string {.*/fn restamp_sql() -> string { "SELECT ?, ?" }/' "no restamp"
cp /tmp/apply.good $f
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
make libs > /tmp/libs.log 2>&1; echo "make libs $?"
build/avra test packages/std-db/src/tests/landing > /tmp/m3.log 2>&1; echo "landing $?"; grep -a "eval" /tmp/m3.log | cut -c1-120
build/avra check --baseline tools/idioms.baseline packages/std-db 2>&1 | grep -a -A3 "NEW" | head -8 | cut -c1-250

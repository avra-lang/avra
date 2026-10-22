#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for p in std-db std-sqlite site cli std-ui std-validate; do
  [ -d packages/$p ] || continue
  build/avra check --baseline tools/idioms.baseline packages/$p > /tmp/sw.$p 2>&1; echo "== $p $?"
  grep -a "NEW\|^  packages\|^  \.\./" /tmp/sw.$p | head -40 | cut -c1-200
  grep -a "^error" -A4 /tmp/sw.$p | head -20 | cut -c1-200
done

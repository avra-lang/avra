#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
mkdir -p /tmp/srvrun
find /tmp/srvrun -name '*.db' -delete 2>/dev/null
T=$PWD
build/avra build tools/ui-board/server > /tmp/srvbuild.log 2>&1; echo "build $?"; grep -av "^ *[│╭·─]\|^warning\|^help\|^$" /tmp/srvbuild.log | tail -4 | cut -c1-200
BIN=$T/tools/ui-board/server/src/main
ls -la $BIN | cut -c1-100
cd /tmp/srvrun
PORT=8099 $BIN > /tmp/srvrun/out.log 2>&1 &
for i in $(seq 1 20); do curl -s -o /dev/null http://127.0.0.1:8099/tasks/ && break; sleep 1; done
curl -s -i http://127.0.0.1:8099/tasks/ | head -5
curl -s -i -X POST -H 'content-type: application/json' -d '{"title":"x","done":false}' http://127.0.0.1:8099/tasks/ | head -12
curl -s -i http://127.0.0.1:8099/tasks/ | tail -3
head -8 /tmp/srvrun/out.log
kill %1 2>/dev/null

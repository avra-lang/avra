#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
which node firefox clang wasm-opt 2>&1 | head -5
make ui-board > /tmp/ub.log 2>&1; echo "ui-board $?"; tail -40 /tmp/ub.log | cut -c1-240

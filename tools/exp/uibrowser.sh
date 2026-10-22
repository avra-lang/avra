#!/bin/sh
[ -d tools ] || exit 70
make build/libavra_runtime.a build/std_io.o build/std_io_watch.o build/sqlite3.o build/sqlite_sentinel.o build/std_time.o build/std_process.o build/std_net.o > /tmp/mk.log 2>&1
make libs > /tmp/libs.log 2>&1
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$

sleep 20; make ui-browser > /tmp/ubr.log 2>&1; echo "ui-browser $?"; grep -a "FAILED\|ok  *the server\|ok  *Sync\|every claim\|claim(s)\|ran 0\|never\|error" /tmp/ubr.log | head -30 | cut -c1-260; tail -5 /tmp/ubr.log | cut -c1-260

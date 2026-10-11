#!/bin/sh
# Does an edit to an embedded file of a HELD source file reach the next build / run?
A=${AVRA_BIN:-$(pwd)/build/avra}
gap=${STALE_GAP:-0}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
for mode in build run; do
    d=$HOME/stale/$mode; d=$d.$$; mkdir -p "$d/src"
    printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
    printf 'use @std.meta.{embed}\n\nexport const TEXT: string = embed("data.txt")\n' > "$d/src/lib.av"
    printf 'use lib.{TEXT}\n\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
    printf 'one' > "$d/src/data.txt"
    said() {
        if [ "$mode" = build ]; then
            (cd "$d" && "$A" build . > "$HOME/stale/$mode.log" 2>&1; st=$?; bin=$(ls -t src/main build/app app 2>/dev/null | head -n 1); echo "$1	build status=$st	binary=$bin	prints: $( [ -n "$bin" ] && ./"$bin" 2>&1 | head -n 1)")
        else
            (cd "$d" && echo "$1	run prints: $("$A" run . 2>&1 | tail -n 1)")
        fi
    }
    echo "== $mode"
    said "1 cold (data=one)"
    said "2 warm, nothing touched"
    printf 'use lib.{TEXT}\n\n// touched\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
    said "3 main.av edited, lib.av held (data=one)"
    sleep "$gap"; printf 'two' > "$d/src/data.txt"
    said "4 data.txt edited to two"
    said "5 again, nothing touched"
    [ "$mode" = build ] && tail -n 3 "$HOME/stale/$mode.log" | cut -c1-200
done

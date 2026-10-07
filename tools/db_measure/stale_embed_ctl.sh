#!/bin/sh
# Control: the same edit to the embedded file with NO source edit before it (nothing held by an edit).
A=${AVRA_BIN:-$(pwd)/build/avra}
gap=${STALE_GAP:-0}
d=$HOME/stale/ctl; d=$d.$$; mkdir -p "$d/src"
printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
printf 'use @std.meta.{embed}\n\nexport const TEXT: string = embed("data.txt")\n' > "$d/src/lib.av"
printf 'use lib.{TEXT}\n\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
printf 'one' > "$d/src/data.txt"
said() { (cd "$d" && "$A" build . > "$HOME/stale/ctl.log" 2>&1; st=$?; echo "$1	build status=$st	prints: $(./src/main 2>&1 | head -n 1)	said: $(tail -n 1 "$HOME/stale/ctl.log" | cut -c1-120)"); }
said "1 cold (data=one)"
said "2 warm, nothing touched"
sleep "$gap"; printf 'two' > "$d/src/data.txt"
said "3 data.txt edited to two, no source edit"
printf 'use lib.{TEXT}\n\n// touched\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
said "4 then main.av edited (data still two)"
sleep "$gap"; printf 'three' > "$d/src/data.txt"
said "5 data.txt edited to three"

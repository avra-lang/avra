#!/bin/sh
A=$(pwd)/build/avra
d=$HOME/stale/trace.$$; mkdir -p "$d/src"
printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
printf 'use @std.meta.{embed}\n\nexport const TEXT: string = embed("data.txt")\n' > "$d/src/lib.av"
printf 'use lib.{TEXT}\n\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
printf 'one' > "$d/src/data.txt"
step() {
    (cd "$d" && AVRA_QTRACE=1 "$A" build . > "$HOME/stale/t.out" 2> "$HOME/stale/t.err"; echo "== $1	status=$?	prints: $(./src/main 2>&1 | head -n 1)")
    grep -a '^KEY	\|^KEEPEMBEDS	\|^KEPT-E	\|Q	ask	12	\|Q	settle	12	' "$HOME/stale/t.err" | cut -c1-260 | head -n 14
    echo "   trace lines: $(wc -l < "$HOME/stale/t.err"); asks computed: $(grep -ac 'compute$' "$HOME/stale/t.err"); reused: $(grep -ac 'reuse$' "$HOME/stale/t.err")"
}
step "1 cold, data=one"
step "2 warm, nothing touched"
sleep 2; printf 'two' > "$d/src/data.txt"
step "3 data.txt edited to two"
printf 'use lib.{TEXT}\n\n// touched\nprintln("text=${TEXT}")\n' > "$d/src/main.av"
step "4 main.av edited, data still two"
ls "$d/.avra-cache" 2>/dev/null | head -n 5

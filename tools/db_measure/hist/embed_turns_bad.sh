#!/bin/sh
# A recorded embed that LATER stops being readable: the same spoken refusal, never a trap.
A=${AVRA_BIN:-$(pwd)/build/avra}
for kase in blob dir gone; do
    d=$HOME/stale/bad.$kase.$$; mkdir -p "$d/src"
    printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
    printf 'use @std.meta.{embed}\n\nexport const T: string = embed("data.txt")\n' > "$d/src/lib.av"
    printf 'use lib.{T}\n\nprintln("t=${T}")\n' > "$d/src/main.av"
    printf 'one' > "$d/src/data.txt"
    (cd "$d" && "$A" build . > /dev/null 2>&1; echo "$kase	first build exit=$?	prints: $(./src/main 2>&1 | head -n 1)")
    case $kase in
        blob) printf '\377\376' > "$d/src/data.txt" ;;
        dir) mv "$d/src/data.txt" "$d/src/data.old"; mkdir "$d/src/data.txt" ;;
        gone) mv "$d/src/data.txt" "$d/src/data.old" ;;
    esac
    for verb in check check build build; do
        (cd "$d" && "$A" $verb . > "$HOME/stale/b.out" 2>&1; st=$?; echo "$kase	then $verb	exit=$st	$(grep -a -m1 '^error\|^avra:\|trap\|defect' "$HOME/stale/b.out" | cut -c1-220)")
    done
done

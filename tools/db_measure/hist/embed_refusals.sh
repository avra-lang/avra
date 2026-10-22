#!/bin/sh
# An embed the law refuses, checked and built twice: the same spoken refusal each time, never a trap.
A=$(pwd)/build/avra
for kase in blob dir gone; do
    d=$HOME/stale/ref.$kase.$$; mkdir -p "$d/src"
    printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
    case $kase in
        blob) printf '\377\376' > "$d/src/blob.bin"; rel=blob.bin ;;
        dir) mkdir -p "$d/src/dir"; rel=dir ;;
        gone) rel=gone.txt ;;
    esac
    printf 'use @std.meta.{embed}\n\nexport const T: string = embed("%s")\n\nprintln("t=${T}")\n' "$rel" > "$d/src/main.av"
    for verb in check check build build; do
        (cd "$d" && "$A" $verb . > "$HOME/stale/r.out" 2>&1; st=$?; echo "$kase	$verb	exit=$st	$(grep -a -m1 '^error\|^avra:\|trap\|defect' "$HOME/stale/r.out" | cut -c1-220)")
    done
done

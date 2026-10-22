#!/bin/sh
# Red-team: an embedded file read as an input cell, attacked cold and warm.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
A=$(pwd)/build/avra
d=$HOME/rt.$$; mkdir -p "$d/dep/src" "$d/dep/data" "$d/app/src"
printf '[package]\nname = "@rt/dep"\nversion = "0.1.0"\n' > "$d/dep/avra.toml"
printf 'export fn one() -> int { 1 }\n' > "$d/dep/src/dep.av"
printf 'dep-one' > "$d/dep/data/d.txt"
printf '[package]\nname = "rt-app"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/dep" = { path = "../dep" }\n' > "$d/app/avra.toml"
printf 'a' > "$d/app/src/a.txt"; printf 'elsewhere' > "$d/outside.txt"
printf 'export fn other() -> int { 7 }\n' > "$d/app/src/other.av"
printf 'use @std.meta.{embed}\nuse @rt.dep.{one}\nconst A: string = embed("a.txt")\nconst D: string = embed("@rt/dep/data/d.txt")\nconst S: string = embed("other.av")\nprintln("a=${A} d=${D} s=${S.length} ${one()}")\n' > "$d/app/src/main.av"
say() { # say <label> <verb>: status, first line, error kinds
    out=$(cd "$d/app" && "$A" $2 . 2>&1); st=$?
    printed=""; [ "$2" = build ] && [ $st -eq 0 ] && printed=$("$d/app/src/main" 2>&1 | head -n 1)
    echo "$1	$2	status=$st	$printed	$(printf '%s' "$out" | grep -aoE 'error\[[a-z_.]+\]|^avra:.*' | sort -u | tr '\n' ' ' | cut -c1-200)	$(printf '%s' "$out" | grep -a '`embed`' | head -n 1 | cut -c1-160)"
}
say "1 cold" build
say "2 warm no-op" build
printf 'a2' > "$d/app/src/a.txt"; say "3 a.txt edited" build
printf 'dep-two' > "$d/dep/data/d.txt"; say "4 dependency's embedded file edited" build
printf 'export fn other() -> int { 77 }\n' > "$d/app/src/other.av"; say "5 embedded .av edited" build
mv "$d/app/src/a.txt" "$d/a.real"; ln -s "$d/outside.txt" "$d/app/src/a.txt"; say "6 a.txt now a link, warm" build; say "6b link, check" check
rm "$d/app/src/a.txt"; mv "$d/a.real" "$d/app/src/a.txt"; say "7 a.txt back" build
chmod 000 "$d/app/src/a.txt"; say "8 a.txt unreadable, warm" build; chmod 644 "$d/app/src/a.txt"
say "9 readable again" build
printf 'a\377' > "$d/app/src/a.txt"; say "10 a.txt not UTF-8" build
printf 'a3' > "$d/app/src/a.txt"; printf '// moved\n' >> "$d/app/src/main.av"; say "11 main + a.txt edited" build
mkdir "$d/app/src/sub"; mv "$d/app/src/a.txt" "$d/a.keep"; ln -s "$d/app/src/sub" "$d/app/src/lnk"; printf 'x' > "$d/app/src/sub/a.txt"
sed -i 's|embed("a.txt")|embed("lnk/a.txt")|' "$d/app/src/main.av"; say "12 a link on the way, cold literal" check
# NO FILE ROW FOR AN EMBED: explain names a.txt as no file a check reads, and other.av
# (an embedded source) still as a file.
sed -i 's|embed("lnk/a.txt")|embed("a.txt")|' "$d/app/src/main.av"; mv "$d/a.keep" "$d/app/src/a.txt"
say "14 back to a.txt" check
(cd "$d/app" && "$A" explain src/a.txt 2>&1 | grep -v '^watch:' | head -n 6 | sed 's/^/14 explain a.txt: /' | cut -c1-200)
(cd "$d/app" && "$A" explain src/main.av 2>&1 | grep -a 'a\.txt\|Input\|embedded' | head -n 6 | sed 's/^/14 explain main.av: /' | cut -c1-200)

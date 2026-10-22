#!/bin/sh
# Does a CHECK see an embedded text's edit, and what does the record say the file's runs read?
A=$(pwd)/build/avra
d=$HOME/stale/chk.$$; mkdir -p "$d/src"
printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
printf 'use @std.meta.{embed}\n\nexport const TEXT: string = embed("data.txt")\nexport const N: int = TEXT.length\n' > "$d/src/lib.av"
printf 'use lib.{TEXT, N}\n\nprintln("text=${TEXT} n=${N}")\n' > "$d/src/main.av"
printf 'one' > "$d/src/data.txt"
runs() { grep -rah "$(printf '^file\t')" "$d/.avra-cache"/*/rows 2>/dev/null | awk -F'\t' '$2 ~ /lib.av$/ { print "   record: lib.av runs read = [" $4 "]" }' | sed "s#$d/##g" | sort -u; }
step() { (cd "$d" && "$A" $2 --time . > "$HOME/stale/c.out" 2>&1; echo "== $1	$2 status=$?	$(grep -ao 'held [0-9]*/[0-9]*' "$HOME/stale/c.out" | tail -n 1)	read: $(sed -n '/^read:/,$p' "$HOME/stale/c.out" | grep '^  ' | sed "s#$d/##g" | tr '\n' ';' | cut -c1-200)"); runs; }
step "1 cold" check
step "2 no-op" check
printf '// moved\n' >> "$d/src/main.av"
step "3 main.av edited" check
sleep 1; printf 'four' > "$d/src/data.txt"
step "4 data.txt edited to four (length 3 -> 4)" check
(cd "$d" && echo "   run prints: $("$A" run . 2>&1 | tail -n 1)")
step "5 no-op" check
step "6 first build" build
sleep 1; printf 'fives' > "$d/src/data.txt"
step "7 data.txt edited to fives, build" build
(cd "$d" && echo "   binary prints: $(./src/main 2>&1 | head -n 1)")

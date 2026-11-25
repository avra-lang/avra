#!/bin/sh
# Does every kept record name each embedded path, beside the remembered embeds list?
A=${AVRA_BIN:-$(pwd)/build/avra}
d=$HOME/embrec.$$; mkdir -p "$d/src/tests"
printf '[package]\nname = "app"\nversion = "0.1.0"\n' > "$d/avra.toml"
printf 'use @std.meta.{embed}\n\nexport const TEXT: string = embed("a.txt")\n' > "$d/src/lib.av"
printf 'use @std.meta.{embed}\n\nexport fn g() -> string { embed("b.txt") }\n' > "$d/src/util.av"
printf 'use lib.{TEXT}\nuse util.{g}\n\nconst B: string = g()\nprintln("a=${TEXT} b=${B}")\n' > "$d/src/main.av"
printf 'use @std.meta.{embed}\n\nconst C: string = embed("../c.txt")\n\nspec "c" { then "reads" { C == "c" } }\n' > "$d/src/tests/c_test.av"
printf 'a' > "$d/src/a.txt"; printf 'b' > "$d/src/b.txt"; printf 'c' > "$d/src/c.txt"
show() {
    echo "== $1"
    for n in a.txt b.txt c.txt; do
        echo "-- $n in:"
        grep -rIh "^file	.*$n\|^embeds\|^[a-z/.]*$n$" "$d/.avra-cache" 2>/dev/null | sed "s|/home/sprite/avra-build/avra-db-a3/tree/|T/|g; s|$d/||g" | awk -F'\t' '{print $1"\t"$2"\t...\t"$4}' | sort -u | head -n 8
    done
}
(cd "$d" && "$A" build . > "$d/b1.log" 2>&1; echo "build1 status=$? prints: $(./src/main 2>&1 | head -n 1)")
show "after cold build"
printf 'use lib.{TEXT}\nuse util.{g}\n\n// touched\nconst B: string = g()\nprintln("a=${TEXT} b=${B}")\n' > "$d/src/main.av"
(cd "$d" && "$A" build . > "$d/b2.log" 2>&1; echo "build2 (main edited) status=$?"; grep -a "^avra:\|^error" "$d/b2.log" | head -n 5)
show "after warm build, main edited"
(cd "$d" && "$A" test . > "$d/t1.log" 2>&1; echo "test status=$? $(tail -n 1 "$d/t1.log")")
show "after test"
ls -R "$d/.avra-cache" 2>/dev/null | head -n 5

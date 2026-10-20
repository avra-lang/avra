#!/bin/sh
# A CACHE ENTRY IS ALWAYS DROPPABLE. A held file's object is the store's, and a build used to
# refuse (`build.object_gone`) when one was missing. A missing object is a MISS now: the file is
# read again and its object rebuilt, so the build passes — and counted: the second build
# rebuilds objects, the third rebuilds none; and a ceiling that evicts them leaves builds passing. It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/obj-gone; fails=0
find "$R" .avra-cache -type f -delete 2>/dev/null
mkdir -p $R/app/src $R/lib/src
printf '[package]\nname = "@rt/oglib"\nversion = "0.1.0"\n\n[lib]\nname = "rt-oglib"\npath = "src/lib.av"\n' > $R/lib/avra.toml
printf '[package]\nname = "og"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/oglib" = { path = "../lib" }\n' > $R/app/avra.toml
printf 'export fn one() -> int { 1 }\nexport fn two() -> int { one() + 1 }\n' > $R/lib/src/lib.av
printf 'use @rt.oglib.{two}\n\nprintln("n ${two()}")\n' > $R/app/src/main.av
B() { # B <label> <want>: build and run, the output held to <want>
    AVRA_QTRACE=1 ./avra build $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails + 1)); echo "FAIL  $1: status $st"; tail -n 12 $R/err | grep -v '^Q' | cut -c1-200; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails + 1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
    owed=$(grep -P '^Q\tobjects\t' $R/err | tail -1 | cut -f3)
    echo "$1: ${owed:-0} object(s) owed"
}
B "cold" "n 2"
printf 'use @rt.oglib.{two}\n\nprintln("m ${two()}")\n' > $R/app/src/main.av
B "main edited, lib held" "m 2"
held_owed=$owed
find .avra-cache/obj -mindepth 2 -type f ! -name '*.deps' -delete
printf 'use @rt.oglib.{two}\n\nprintln("k ${two()}")\n' > $R/app/src/main.av
B "every object deleted, main edited" "k 2"
[ "${owed:-0}" -gt "${held_owed:-0}" ] || { fails=$((fails + 1)); echo "FAIL  the deleted objects were not rebuilt (owed $owed, was $held_owed)"; }
B "again, nothing changed" "k 2"
[ "${owed:-0}" -eq 0 ] || { fails=$((fails + 1)); echo "FAIL  a rebuilt store still owed $owed object(s)"; }
# THE CEILING EVICTS, AND NOTHING BREAKS: under a one-byte ceiling every seal drops every object
# but the newest, and each edit-build still passes, the dropped files read again.
i=0
while [ $i -lt 4 ]; do
    i=$((i + 1))
    printf 'use @rt.oglib.{two}\n\nprintln("e%s ${two()}")\n' $i > $R/app/src/main.av
    AVRA_OBJ_MAX_BYTES=1 AVRA_STORE_SEAL_FRAMES=1 B "ceiling cycle $i" "e$i 2" || break
done
count=$(find .avra-cache/obj -mindepth 2 -type f ! -name '*.deps' | wc -l | tr -d ' ')
echo "objects left under a one-byte ceiling: $count"
[ "$count" -le 3 ] || { fails=$((fails + 1)); echo "FAIL  $count objects stand under a one-byte ceiling"; }
echo "obj-gone-attack: $fails failed"
[ "$fails" -eq 0 ]

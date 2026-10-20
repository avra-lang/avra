#!/bin/sh
# A NAME ADDED, REMOVED OR SHADOWED IN A SIBLING MODULE STILL RE-READS ITS READERS. A module's
# record says what it exports; the load walk reads that record for its names, imports, placed
# files and re-exports, so a reader of a name must follow the name through each edit warm:
# the answer after the edit is the cold answer. It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/names-attack; fails=0; steps=0
find "$R" .avra-cache -type f -delete 2>/dev/null
mkdir -p $R/app/src/lib $R/app/src/use
printf '[package]\nname = "na-app"\nversion = "0.1.0"\n' > $R/app/avra.toml
put() { printf '%s\n' "$2" > "$1"; }
A=$R/app/src/lib/a.av; Bf=$R/app/src/lib/b.av
put $R/app/src/use/c.av 'use lib.{pick}

export fn answer() -> int { pick() }'
put $R/app/src/main.av 'use use.{answer}

println("${answer()}")'
B() { # B <label> <wanted>
    steps=$((steps + 1))
    ./avra build $R/app > $R/out 2>&1; st=$?
    [ $st -eq 0 ] || { fails=$((fails + 1)); echo "FAIL  $1: status $st: $(grep -v '^watch' $R/out | tail -n 4 | cut -c1-200 | tr '\n' ' ')"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails + 1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
    echo "$1: $got"
}
put $A 'export fn pick() -> int { 1 }'
put $Bf 'export fn other() -> int { 10 }'
B "cold" 1
put $Bf 'export fn other() -> int { 10 }
export fn extra() -> int { 5 }'
B "a name added to a sibling file" 1
put $A 'export fn pick() -> int { extra() + 1 }'
B "the reader's file now reads the added sibling name" 6
put $Bf 'export fn other() -> int { 10 }'
./avra build $R/app > $R/out 2>&1 && { fails=$((fails + 1)); echo "FAIL  a removed name was still served: $(cat $R/app/src/main >/dev/null 2>&1; $R/app/src/main 2>&1)"; }
steps=$((steps + 1)); grep -q "extra" $R/out || { fails=$((fails + 1)); echo "FAIL  removing a name a reader reads said nothing about it: $(grep -v '^watch' $R/out | tail -n 3 | cut -c1-160 | tr '\n' ' ')"; }
put $A 'export fn pick() -> int { 2 }'
B "the reader stops reading it, the name is gone" 2
put $A 'export fn pick() -> int { 3 }
export fn other() -> int { 7 }'
put $Bf 'export fn other() -> int { 10 }'
steps=$((steps + 1)); ./avra build $R/app > $R/out 2>&1 && { fails=$((fails + 1)); echo "FAIL  a name defined twice in a module built"; }
put $A 'export fn pick() -> int { 3 }'
B "the duplicate removed" 3
echo "names-attack: $steps edit(s) built warm, $fails failed"
[ "$fails" -eq 0 ]

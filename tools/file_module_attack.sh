#!/bin/sh
# A FILE-LEVEL MODULE IS SEEN THROUGH ITS DIRECTORY'S RECORD, the root package's own root
# included. `use model` names `src/model.av`, a file the ROOT module's record places, so a
# reader in another module keys on the root's record: insert a field before the one it
# reads and the reader must lower again, or its kept object reads the old slot.
set -u
cd "$(dirname "$0")/.."

R=build/file-module; fails=0
T=build/aside/fm.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/file-module
P=$R/fm
mkdir -p $P/src/reader
fail() { fails=$((fails + 1)); echo "FAIL  $1"; }
printf '[package]\nname = "fm"\nversion = "0.1.0"\n\n[bin]\nname = "fm"\npath = "src/main.av"\n' > $P/avra.toml
printf 'export type Frame = { name: string, speakers: List<string> }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
printf 'use model.{made}\nexport fn first() -> string { made().speakers[0] }\n' > $P/src/reader/reader.av
printf 'use reader.{first}\nprintln(first())\n' > $P/src/main.av

built() { ./avra build $P > $T/out 2>&1 || { fail "$1: the build refused: $(tail -3 $T/out)"; return; }; got=$($P/src/main 2>&1); [ "$got" = "x" ] || fail "$1: printed '$got', not 'x'"; }

built "first build"
printf 'export type Frame = { name: string, audience: List<string>? = null, speakers: List<string> }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
built "a field inserted before the one the reader reads"
printf 'export type Frame = { speakers: List<string>, name: string }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
built "the fields reordered"

if [ $fails -gt 0 ]; then echo "file-module attack: $fails failed"; exit 1; fi
echo "file-module attack: 3 builds held to the program"

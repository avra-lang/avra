#!/bin/sh
# A FILE-LEVEL MODULE IS SEEN THROUGH ITS DIRECTORY'S RECORD, the root package's own root
# included. `use model` names `src/model.av`, a file the ROOT module's record places, so a
# reader in another module keys on the root's record: insert a field before the one it
# reads and the reader must lower again, or its kept object reads the old slot.
set -u
. "$(dirname "$0")/lib/attack.sh"

R=build/file-module
who=file-module-attack
. tools/lib/steps.sh
T=build/aside/fm.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/file-module
P=$R/fm
mkdir -p $P/src/reader
printf '[package]\nname = "fm"\nversion = "0.1.0"\n\n[bin]\nname = "fm"\npath = "src/main.av"\n' > $P/avra.toml
printf 'export type Frame = { name: string, speakers: List<string> }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
printf 'use model.{made}\nexport fn first() -> string { made().speakers[0] }\n' > $P/src/reader/reader.av
printf 'use reader.{first}\nprintln(first())\n' > $P/src/main.av

built() {
    ./avra build $P > $T/out 2>&1 || { fail "$1: the build refused: $(tail -3 $T/out)"; return; }
    got=$($P/src/main 2>&1)
    if [ "$got" = "x" ]; then say "$1: the program reads its field"; else fail "$1: printed '$got', not 'x'"; fi
}

built "first build"
printf 'export type Frame = { name: string, audience: List<string>? = null, speakers: List<string> }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
built "a field inserted before the one the reader reads"
printf 'export type Frame = { speakers: List<string>, name: string }\nexport fn made() -> Frame { Frame { name: "a", speakers: ["x"] } }\n' > $P/src/model.av
built "the fields reordered"

verdict "every build held to the program"

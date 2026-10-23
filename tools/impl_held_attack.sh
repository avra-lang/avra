#!/bin/sh
# A HELD TYPE'S METHOD TABLE, ATTACKED: the type, its trait and its impl stand in three
# files of one module the entry never edits, so a warm run answers them from the record. The
# table must follow the impl wherever it stands — edited, moved to another file, or gone.
set -u
cd "$(dirname "$0")/.."
T=$(pwd); B=build/impl-held-attack; R=$B/app; fails=0; steps=0
rm -rf "$B" && mkdir -p $R/src/shapes
: > $B/.git
printf '[package]\nname = "impl-held-attack"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'export type Box = { side: int }\n' > $R/src/shapes/box.av
printf 'export trait Say {\n    fn say() -> string\n}\n' > $R/src/shapes/say.av
printf 'impl Say for Box {\n    fn say() -> string { "box${self.side}" }\n}\n' > $R/src/shapes/impl.av
printf 'use shapes.{Box, Say}\n\nlet b = Box { side: 3 }\nb.say()\n' > $R/src/main.av
ran() { (cd $R && "$T/build/avra" run . 2>&1 | grep -v '^watch:' | tail -1); }
want() { steps=$((steps+1)); got=$(ran); [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  $1: got '$got', want '$2'"; }; }
want "cold build" "box3"
printf '\n// edited\n' >> $R/src/main.av
want "an edit of the entry alone" "box3"
printf 'impl Say for Box {\n    fn say() -> string { "crate${self.side}" }\n}\n' > $R/src/shapes/impl.av
want "the impl's body edited" "crate3"
: > $R/src/shapes/impl.av
printf 'impl Say for Box {\n    fn say() -> string { "moved${self.side}" }\n}\n' > $R/src/shapes/more.av
want "the impl moved to another file" "moved3"
rm $R/src/shapes/more.av
steps=$((steps+1)); gone=$(cd $R && "$T/build/avra" check . 2>&1 | grep -c 'error')
[ "$gone" -gt 0 ] || { fails=$((fails+1)); echo "FAIL  the impl removed: the call still checks"; }
echo "impl-held-attack: $steps runs through one store, $fails failed"
[ $fails -eq 0 ]

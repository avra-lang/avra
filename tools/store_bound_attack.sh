#!/bin/sh
# A DEVELOPER'S STORE BOUNDS ITSELF. Every edit makes a program objects its earlier builds never
# let go of: a session of edits grows `<package>/.avra-cache/tapes-build/obj` without end. The kept
# objects now stand under a ceiling (`AVRA_OBJ_MAX_BYTES`, two gigabytes by default), oldest out
# first, the build's own always kept. N edit-build cycles under a ceiling smaller than one build
# must leave no more objects than one build links; a build that changed nothing makes none and
# prints the newest text; a text an evicted object was made for builds again.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=store-bound-attack
. tools/lib/steps.sh
R=build/store-bound; N=6; CAP=${CAP:-1}
find "$R" -delete 2>/dev/null
mkdir -p $R/app/src
own_store $R
printf '[package]\nname = "sb"\nversion = "0.1.0"\n' > $R/app/avra.toml
O=$R/app/.avra-cache/tapes-build/obj
objects() { find $O -type f 2>/dev/null | wc -l | tr -d ' '; }
cycle() { printf 'fn shown(n: int) -> string { "cycle ${n}" }\nprintln(shown(%s))\n' "$1" > $R/app/src/main.av; }
built() { # built <label> <want>: the build passes under the ceiling and prints <want>
    touch $R/mark
    AVRA_OBJ_MAX_BYTES=$CAP ./avra build $R/app > $R/out 2>&1 || { fail "$1: the build failed: $(tail -n 3 $R/out | tr '\n' ' ' | cut -c1-200)"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fail "$1: printed '$got', wanted '$2'"; return 1; }
}
cycle 1; built "cycle 1" "cycle 1" || exit 1
one=$(objects)
say "cycle 1: $one objects"
i=1
while [ $i -lt $N ]; do
    i=$((i + 1))
    cycle $i; built "cycle $i" "cycle $i" || break
done
n=$(objects)
[ "$n" -le "$one" ] && say "after $N cycles: $n objects, no more than one build links ($one)" || fail "after $N cycles $n objects stand, where one build links $one"
built "nothing changed" "cycle $N" && {
    made=$(find $O -type f -newer $R/mark | wc -l | tr -d ' ')
    [ "$made" = 0 ] && say "nothing changed: made none" || fail "nothing changed, and $made objects were made"
}
cycle 1; built "the first text again, its objects evicted" "cycle 1" && say "the first text again: built and printed"
verdict

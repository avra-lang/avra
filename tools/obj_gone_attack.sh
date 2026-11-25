#!/bin/sh
# A KEPT OBJECT IS ALWAYS DROPPABLE. A program's objects are kept in its package's
# `.avra-cache/tapes-build/obj`, each by its key; a build owes the ones it can't find there and
# makes them again. Held to each step: the build passes, its binary prints what the source says,
# and the objects it made are counted — an edit makes few, an edit after every object was deleted
# makes them all, and a build after that makes none. A build that changed nothing stands on its
# kept binary whatever was deleted beside it, and a deleted binary is put back.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=obj-gone-attack
. tools/lib/steps.sh
R=build/obj-gone
find "$R" -delete 2>/dev/null
mkdir -p $R/app/src $R/lib/src
own_store $R
printf '[package]\nname = "@rt/oglib"\nversion = "0.1.0"\n\n[lib]\nname = "rt-oglib"\npath = "src/lib.av"\n' > $R/lib/avra.toml
printf '[package]\nname = "og"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/oglib" = { path = "../lib" }\n' > $R/app/avra.toml
printf 'export fn one() -> int { 1 }\nexport fn two() -> int { one() + 1 }\n' > $R/lib/src/lib.av
O=$R/app/.avra-cache/tapes-build/obj
main() { printf 'use @rt.oglib.{two}\n\nprintln("%s ${two()}")\n' "$1" > $R/app/src/main.av; }
# build <label> <want> <made>: the build passes, prints <want>, and made <made> objects
# ("some": at least one, fewer than all; "all": every object it keeps)
build() {
    touch $R/mark
    ./avra build $R/app > $R/out 2> $R/err || { fail "$1: the build failed: $(grep -v '^Q' $R/err | head -3 | tr '\n' ' ')"; return; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fail "$1: printed '$got', the source says '$2'"; return; }
    made=$(find $O -type f -newer $R/mark | wc -l | tr -d ' ')
    kept=$(find $O -type f | wc -l | tr -d ' ')
    case $3 in
        some) [ "$made" -gt 0 ] && [ "$made" -lt "$kept" ] || { fail "$1: made $made of $kept objects, where an edit makes some"; return; } ;;
        all) [ "$made" -gt 0 ] && [ "$made" = "$kept" ] || { fail "$1: made $made of $kept objects, where every one was deleted"; return; } ;;
        *) [ "$made" = "$3" ] || { fail "$1: made $made objects, wanted $3"; return; } ;;
    esac
    say "$1: made $made of $kept objects, printed '$got'"
}
main n; build "cold" "n 2" all
main m; build "main edited, the library's objects kept" "m 2" some
build "nothing changed" "m 2" 0
find $O -type f -delete
build "every object deleted, nothing changed: the kept binary stands" "m 2" 0
find $O -type f -delete; find $R/app/src/main -delete
build "every object and the binary deleted, nothing changed" "m 2" 0
find $O -type f -delete; main k
build "every object deleted, main edited: each made again" "k 2" all
build "again, nothing changed" "k 2" 0
main j; build "edited once more" "j 2" some
printf 'export fn one() -> int { 3 }\nexport fn two() -> int { one() + 1 }\n' > $R/lib/src/lib.av
build "the library edited" "j 4" some
verdict

#!/bin/sh
# TWO COMPILERS, ONE MACHINE CACHE, NO ANSWER SHARED. A compiler reads only what it, or a compiler
# of its own print, kept: a store, a machine segment, a stamp or a shared blob another compiler wrote
# never answers it. Held with two compiler binaries over one package and one `AVRA_CACHE_DIR`: the
# first tests the package, then the second; the second must work out exactly what it works out on a
# cache of its own (`worked:` counted alike, under the program layer, the net forking the old
# path's check beside it as a build does by default) and say exactly the same.
#   TWO_A=<compiler> TWO_B=<compiler> sh tools/two_compilers_attack.sh
# A compiler stands in its own tree, which holds the std it reads. Defaults: build/avra-standing,
# then build/avra; where the two are one binary, the attack names it and holds nothing.
# A COMPILER'S IDENTITY IS ITS OWN IMAGE'S, HOWEVER IT IS STARTED: the second compiler run through a
# link named as the first, and as a copy at another path that no record stands beside (what `make
# recover` leaves), must print the identity it prints run directly — never the first's, never none.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=two-compilers-attack
. tools/lib/steps.sh
A=${TWO_A:-$PWD/build/avra-standing}
B=${TWO_B:-$PWD/build/avra}
[ -x "$A" ] && [ -x "$B" ] || { echo "$who: no compiler at $A or $B — nothing held"; exit 0; }
cmp -s "$A" "$B" && { echo "$who: $A and $B are one binary — nothing held"; exit 0; }
R=build/two-compilers-attack
find "$R" -delete 2>/dev/null
for w in shared alone; do mkdir -p "$R/$w/m"; cp -R tools/program-suites/suited "$R/$w/"; done
# tested <where> <compiler> <name>: the suites fixture tested in $R/<where> on that cache
tested() { (cd "$R/$1" && AVRA_CACHE_DIR="$PWD/m" AVRA_QUERY_TIMES=1 "$2" test suited >"$3.out" 2>"$3.err"; echo $? >"$3.code"); }
tested shared "$A" a
tested shared "$B" b
tested alone "$B" b
worked() { grep -o '^worked: [0-9]* answers here' "$R/$1/b.err"; }
said() { sed "s#$PWD/$R/$1#<w>#g" "$R/$1/b.out"; }
[ "$(worked shared)" = "$(worked alone)" ] && say "the second compiler worked out on the shared cache what it does alone: $(worked alone)" ||
    fail "the second compiler reused the first's answers: $(worked shared) on the shared cache, $(worked alone) alone"
[ "$(cat "$R/shared/b.code")" = "$(cat "$R/alone/b.code")" ] && [ "$(said shared)" = "$(said alone)" ] && say "and said the same" ||
    fail "the second compiler says otherwise after the first: exit $(cat "$R/shared/b.code") vs $(cat "$R/alone/b.code")"
# the print `$1` runs under, started as `$1`, building a program of one line
mkdir -p "$R/one/src"
printf '[package]\nname = "one"\nversion = "0.1.0"\n' > "$R/one/avra.toml"
printf 'println("1")\n' > "$R/one/src/main.av"
print_of() { (cd "$R/one" && AVRA_QTRACE=1 AVRA_CACHE_DIR="$PWD/m" "$1" build . 2>&1 >/dev/null | grep -P '^Q\tprint' | head -1 | cut -f4); }
mkdir -p "$R/link"
ln -sf "$B" "$R/link/$(basename "$A")"
copy="$(dirname "$B")/.two-compilers-copy"
cp "$B" "$copy"
own=$(print_of "$B")
linked=$(print_of "$PWD/$R/link/$(basename "$A")")
copied=$(print_of "$copy")
find "$copy" "$(dirname "$B")/..two-compilers-copy.print" -delete 2>/dev/null
[ -n "$own" ] && say "the second compiler's own print: $own" || fail "the second compiler prints no identity"
[ "$linked" = "$own" ] && say "started through a link named $(basename "$A"): its own print" || fail "started through a link named $(basename "$A"), it prints '$linked', not its own '$own'"
[ "$copied" = "$own" ] && say "copied to another path, no record beside it: its own print" || fail "copied to another path, it prints '$copied', not its own '$own'"
verdict

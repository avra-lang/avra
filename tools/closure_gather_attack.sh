#!/bin/sh
# A CLOSURE COLLECT'S MEMBERS, ATTACKED — two programs of one library built
# through the SAME `.avra-cache` across separate `avra` invocations. The
# library holds `rows`, a collect gathered over the closure of whatever program
# imports it; program B declares a member in its ENTRY file, program A none.
# Each program must read its own members, whichever built first and however
# often: a held library must never serve one program the set another gathered.
# Program C keeps its members PRIVATE: the closure is the root's, so the library
# gathers them, while a dependency's private member (`@t/far`) stays unseen; a
# member C adds re-lowers the collect and never a module that does not read it.
set -u
cd "$(dirname "$0")/.."
T=$(pwd); B=build/closure-gather-attack; fails=0; steps=0
AVRA=${AVRA_BIN:-$T/build/avra}
[ -d "$B" ] && find "$B" -depth -delete
mkdir -p $B/lib/src/other $B/far/src $B/a/src $B/b/src $B/c/src
# a store stands at the nearest checkout root ABOVE a package, so the fixtures'
# directory is marked as one: their store is their own, cold here, never the tree's
: > $B/.git
cat > $B/lib/avra.toml <<TOML
[package]
name = "@t/libx"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "$T/packages/std-meta" }
TOML
cat > $B/lib/src/libx.av <<'AV'
use @std.meta.{Named, Marker}

export fn seat(_d: Named) -> Marker { Marker {} }

export type Row = { owner: string }

export type Gathered = { row: Row }

export collect rows: List<Gathered> = @seat in closure as Gathered { row: it } by it.name

export fn owners() -> string { [g.row.owner for g in rows].join(",") }
AV
cat > $B/lib/src/other/other.av <<'AV'
export fn other_id() -> int { 7 }
AV
cat > $B/far/avra.toml <<TOML
[package]
name = "@t/far"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "$T/packages/std-meta" }
"@t/libx" = { path = "../lib" }
TOML
cat > $B/far/src/far.av <<'AV'
use @t.libx.{Row, seat}

@seat
const hidden: Row = Row { owner: "hidden" }

export fn far() -> int { 1 }
AV
cat > $B/c/avra.toml <<TOML
[package]
name = "prog_c"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "$T/packages/std-meta" }
"@t/libx" = { path = "../lib" }
"@t/far" = { path = "../far" }
TOML
cat > $B/c/src/main.av <<'AV'
use @t.libx.{owners, Row, seat}
use @t.libx.other.{other_id}
use @t.far.{far}

@seat
const knob: Row = Row { owner: "knob" }

println("[${owners()}] ${far()} ${other_id()}")
AV
for p in a b; do
    cat > $B/$p/avra.toml <<TOML
[package]
name = "prog_$p"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "$T/packages/std-meta" }
"@t/libx" = { path = "../lib" }
TOML
done
cat > $B/a/src/main.av <<'AV'
use @t.libx.{owners}

println("[${owners()}]")
AV
cat > $B/b/src/main.av <<'AV'
use @t.libx.{owners, Row, seat}

@seat
export const knob: Row = Row { owner: "knob" }

println("[${owners()}]")
AV
S() { # S <program> <want output>
    steps=$((steps+1))
    $AVRA build $B/$1/src/main.av > $B/out 2> $B/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $1: did not build (status $st)"; tail -5 $B/err; return; fi
    got=$($B/$1/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  program $1 printed '$got', wanted '$2'"; }
}
S a "[]";       S b "[knob]"
S a "[]";       S b "[knob]"
S c "[knob] 1 7"
# C adds a private member, twice — the second edit meets a derivation that kept its rows
L() { # L <want output>: built, and the units it lowered afresh hold `rows` and nothing of `other`
    steps=$((steps+1))
    AVRA_QTRACE=1 $AVRA build $B/c/src/main.av > $B/out 2> $B/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  c: did not build (status $st)"; tail -5 $B/err; return; fi
    got=$($B/c/src/main 2>&1)
    [ "$got" = "$1" ] || { fails=$((fails+1)); echo "FAIL  program c printed '$got', wanted '$1'"; }
    fresh=$(awk -F'\t' '$1 == "Q" && $2 == "unit" && $3 == "lowered" { print $4 }' $B/err | tr '\n' ' ')
    case " $fresh" in *" @t.libx.rows "*) ;; *) fails=$((fails+1)); echo "FAIL  c: a member arrived and \`rows\` was not lowered afresh: $fresh" ;; esac
    case " $fresh" in *"other"*) fails=$((fails+1)); echo "FAIL  c: a module that reads no collect was lowered afresh: $fresh" ;; esac
}
printf '\n@seat\nconst lamp: Row = Row { owner: "lamp" }\n' >> $B/c/src/main.av
L "[knob,lamp] 1 7"
printf '\n@seat\nconst mop: Row = Row { owner: "mop" }\n' >> $B/c/src/main.av
L "[knob,lamp,mop] 1 7"
S b "[knob]";   S a "[]"
# the library checked alone is its own root: it gathers its own closure, and says nothing
steps=$((steps+1))
$AVRA check $B/lib > $B/out 2>&1 || { fails=$((fails+1)); echo "FAIL  the library alone did not check clean"; tail -5 $B/out; }
grep -qE '(error|warning)\[' $B/out && { fails=$((fails+1)); echo "FAIL  the library alone spoke:"; head -5 $B/out; }
echo "closure-gather-attack: $steps builds through one store, $fails failed"
[ "$fails" -eq 0 ]

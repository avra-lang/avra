#!/bin/sh
# A CLOSURE COLLECT'S MEMBERS, ATTACKED — two programs of one library built
# through the SAME `.avra-cache` across separate `avra` invocations. The
# library holds `rows`, a collect gathered over the closure of whatever program
# imports it; program B declares a member in its ENTRY file, program A none.
# Each program must read its own members, whichever built first and however
# often: a held library must never serve one program the set another gathered.
# Program C declares its member in a second file and edits that file's CONTENT
# between builds, the member's name unchanged: the row must follow the edit.
set -u
cd "$(dirname "$0")/.."
T=$(pwd); B=build/closure-gather-attack; fails=0; steps=0
AVRA=${AVRA_BIN:-$T/build/avra}
[ -d "$B" ] && find "$B" -depth -delete
mkdir -p $B/lib/src $B/a/src $B/b/src $B/c/src
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
for p in a b c; do
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
cat > $B/c/src/main.av <<'AV'
use @t.libx.{owners}
use knob.{knob}

println("[${owners()}]")
AV
member() { # member <owner>
    cat > $B/c/src/knob.av <<AV
use @t.libx.{Row, seat}

@seat
export const knob: Row = Row { owner: "$1" }
AV
}
S() { # S <program> <want output> <program> <want output>
    steps=$((steps+1))
    $AVRA build $B/$1/src/main.av > $B/out 2> $B/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $1: did not build (status $st)"; tail -5 $B/err; return; fi
    got=$($B/$1/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  program $1 printed '$got', wanted '$2'"; }
}
S a "[]";       S b "[knob]"
S a "[]";       S b "[knob]"
member one;     S c "[one]"
member two;     S c "[two]"
member one;     S c "[one]"
echo "closure-gather-attack: $steps builds through one store, $fails failed"
[ "$fails" -eq 0 ]

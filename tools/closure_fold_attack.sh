#!/bin/sh
# A FOLDED CLOSURE COLLECT, ATTACKED — two programs of one library built through
# the SAME `.avra-cache` across separate `avra` invocations. The library folds
# its closure collect `rows` into a const, once in the collector's own file and
# once in a sibling module; program B declares members, program A none. A fold
# settles per root: each program must read the count of its own members,
# whichever built first, the evaluator must agree, and a kept verdict must
# never serve one program the count another gathered. The library checked
# alone folds its own closure and says nothing.
set -u
cd "$(dirname "$0")/.."
T=$(pwd); B=build/closure-fold-attack; fails=0; steps=0
AVRA=${AVRA_BIN:-$T/build/avra}
[ -d "$B" ] && find "$B" -depth -delete
mkdir -p $B/lib/src/other $B/a/src $B/b/src
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

export const count: int = rows.length

export fn owners() -> string { [g.row.owner for g in rows].join(",") }

export fn here() -> int { count }
AV
cat > $B/lib/src/other/other.av <<'AV'
use libx.{rows}

export const far_count: int = rows.length * 10

export fn far() -> int { far_count }
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
use @t.libx.{owners, here}
use @t.libx.other.{far}

println("[${owners()}] ${here()} ${far()}")
AV
cat > $B/b/src/main.av <<'AV'
use @t.libx.{owners, here, rows, Row, seat}
use @t.libx.other.{far}

@seat
export const knob: Row = Row { owner: "knob" }

const own: int = rows.length + 100

println("[${owners()}] ${here()} ${far()} ${own}")
AV
S() { # S <program> <want output>: built and run natively, then run by the evaluator
    steps=$((steps+1))
    $AVRA build $B/$1/src/main.av > $B/out 2> $B/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $1: did not build (status $st)"; tail -5 $B/err; return; fi
    got=$($B/$1/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  program $1 printed '$got' natively, wanted '$2'"; }
    ran=$($AVRA run $B/$1 2>&1 | grep -v '^watch:')
    [ "$ran" = "$2" ] || { fails=$((fails+1)); echo "FAIL  program $1 printed '$ran' evaluated, wanted '$2'"; }
}
S b "[knob] 1 10 101";              S a "[] 0 0"
S b "[knob] 1 10 101";              S a "[] 0 0"
printf '\n@seat\nexport const lamp: Row = Row { owner: "lamp" }\n' >> $B/b/src/main.av
S b "[knob,lamp] 2 20 102";         S a "[] 0 0"
S b "[knob,lamp] 2 20 102"
steps=$((steps+1))
$AVRA check $B/lib > $B/out 2>&1 || { fails=$((fails+1)); echo "FAIL  the library alone did not check clean"; tail -5 $B/out; }
grep -qE '(error|warning)\[' $B/out && { fails=$((fails+1)); echo "FAIL  the library alone spoke:"; head -5 $B/out; }
echo "closure-fold-attack: $steps steps through one store, $fails failed"
[ "$fails" -eq 0 ]

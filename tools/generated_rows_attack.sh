#!/bin/sh
# A MEMBER FILE'S GENERATED ROWS FOLLOW THE ENUM'S FILE. A package gathers its members into a
# `collect enum` that derives a trait over them, so each member's file carries a generated `impl`;
# an edit to the enum's file expands it again, and a row read at a statement the new parse never
# wrote traps ("index N is out of bounds"). The rebuild must answer what a cold build answers. It
# CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
. tools/lib/failed_tail.sh
AVRA=${AVRA:-./avra}
R=build/generated-rows-attack; fails=0
rm -rf "$R" .avra-cache && mkdir -p $R/lib/src/shapes $R/app/src
cat > $R/lib/avra.toml <<'TOML'
[package]
name = "@hg/lib"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "../../../packages/std-meta" }
TOML
cat > $R/lib/src/sized.av <<'AV'
use @std.meta.{Type, Directive}

export trait Size {
    fn size() -> int
    static fn derive(t: Type) -> List<Directive> {
        [
            Directive {
                twin: "",
                name: t.name,
                at: t.at,
                source: quote {
                    impl Size for ${t} { fn size() -> int { ${t.fields.length} } }
                },
            },
        ]
    }
}
AV
cat > $R/lib/src/shapes/types.av <<'AV'
use @std.meta.{Named}

export fn node(_t: Named) {}

@node
export type Dot = {}

@node
export type Line = { from: int, to: int }
AV
cat > $R/lib/src/shapes/shape.av <<'AV'
use @hg.lib.sized.{Size}

export collect enum Shape: Size = @node in package by it.name

export fn shown(s: Shape) -> int { s.size() }
AV
cat > $R/app/avra.toml <<'TOML'
[package]
name = "hg-app"
version = "0.1.0"

[dependencies]
"@std/meta" = { path = "../../../packages/std-meta" }
"@hg/lib" = { path = "../lib" }
TOML
cat > $R/app/src/main.av <<'AV'
use @hg.lib.shapes.{Shape, shown}

println("size ${shown(Shape.Line(1, 2))}")
AV
B() { # B <label>: build through the store and run it
    $AVRA build --time $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  $1: status $st"; failed_tail $R/out $R/err; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "size 2" ] || { fails=$((fails+1)); echo "FAIL  $1: printed '$got', wanted 'size 2'"; }
}
B "cold" || { echo "generated-rows-attack: the cold build failed"; exit 1; }
echo "// edited" >> $R/lib/src/shapes/shape.av
B "the enum's file edited" || :
echo "generated-rows-attack: the members' generated rows after an edit to the enum's file, $fails failed"
[ "$fails" -eq 0 ]

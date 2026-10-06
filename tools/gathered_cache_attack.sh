#!/bin/sh
# A GATHERED ENUM'S DEPENDENCIES, ATTACKED — the same shape as
# tools/type_named_cache_attack.sh: one package built through the SAME
# `.avra-cache` across separate `avra` invocations. `Shape` is declared
# in one module and its members stand in another; its signature reads
# what the members WRITE. Editing a member's field type must move the
# variant's payload and what a derive is handed; a new member in a new
# file must become a variant; an edit nothing reads must change nothing.
set -u
cd "$(dirname "$0")/.."
T=$(pwd); R=build/gathered-cache-attack; W=build/gathered-cache-attack-recursive; fails=0; steps=0
rm -rf "$R" "$W" && mkdir -p $R/src/shapes $W/src/shapes
cat > $R/avra.toml <<'TOML'
[package]
name = "gathered-cache-attack"
version = "0.1.0"
TOML
cat > $R/src/said.av <<'AV'
use @std.meta.{Type, Directive, Variant, literal}
export trait Said {
    static fn derive(t: Type) -> List<Directive> {
        [Directive { twin: "", name: t.name, at: t.at, source: quote { impl ${t} { static fn said() -> string { ${literal([one(v) for v in t.variants].join(" "))} } } } }]
    }
}
fn one(v: Variant) -> string { v.name + "(" + [f.ty + "/" + f.kind.name for f in v.fields].join(",") + ")" }
AV
cat > $R/src/main.av <<'AV'
use @std.meta.{derive}
use said.{Said}
use shapes.{shape, width}

@derive(Said)
export collect enum Shape = @shape in package by it.mark.args[0] dense

"${Shape.said()} ${width(Shape.Dot)}"
AV
cat > $R/src/shapes/shapes.av <<'AV'
use @std.meta.{Named}
use main.{Shape}

export fn shape(_t: Named, _rank: int) {}

@shape(0)
type Dot = {}

@shape(1)
type Line = { to: int }

export fn width(s: Shape) -> int {
    match s { .Line(to) -> wide(to), rest -> 0 }
}

fn wide(n: int) -> int { n }
AV
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
# each fixture is run from its own directory, so its store is its own
ran() { (cd ${1:-$R} && "$T/build/avra" run . 2>&1 | grep -v '^watch:' | tail -1); }

steps=$((steps+1)); cold=$(ran)
[ "$cold" = "Dot() Line(int/Int) 0" ] || { fails=$((fails+1)); echo "FAIL  cold build: got '$cold'"; }

# the member's field changes TYPE in a module the enum's file does not hold
ed $R/src/shapes/shapes.av 'type Line = { to: int }' 'type Line = { to: string }'
ed $R/src/shapes/shapes.av 'fn wide(n: int) -> int { n }' 'fn wide(n: string) -> int { n.length }'
steps=$((steps+1)); moved=$(ran)
[ "$moved" = "Dot() Line(string/Str) 0" ] || { fails=$((fails+1)); echo "FAIL  after a member's field changed type: got '$moved' (a held enum signature would still carry int)"; }

# a member arrives in a file nothing imports
cat > $R/src/shapes/more.av <<'AV'
use shapes.{shape}

@shape(2)
type Box = { side: int, deep: bool }
AV
steps=$((steps+1)); grown=$(ran)
[ "$grown" = "Dot() Line(string/Str) Box(int/Int,bool/Bool) 0" ] || { fails=$((fails+1)); echo "FAIL  after a member arrived in a new file: got '$grown'"; }

# a member's field changes type in a file NOTHING IMPORTS — no `use` line
# carries the edit to the enum's module
ed $R/src/shapes/more.av 'deep: bool' 'deep: string'
steps=$((steps+1)); far=$(ran)
[ "$far" = "Dot() Line(string/Str) Box(int/Int,string/Str) 0" ] || { fails=$((fails+1)); echo "FAIL  after an unimported member's field changed type: got '$far' (a held enum signature would still carry bool)"; }
grown=$far

ed $R/src/shapes/shapes.av 'fn wide(n: string) -> int { n.length }' 'fn wide(n: string) -> int { n.length }
fn nobody_calls_this() -> int { 42 }'
steps=$((steps+1)); unrelated=$(ran)
[ "$unrelated" = "$grown" ] || { fails=$((fails+1)); echo "FAIL  an unrelated edit changed the answer: got '$unrelated', want '$grown'"; }

# A MEMBER THAT NAMES ITS OWN ENUM, and nothing asking the enum first: the
# member's signature and the enum's each read the other, so a warm run that
# verifies the member first must still move the enum's payload.
cat > $W/avra.toml <<'TOML'
[package]
name = "gathered-cache-attack-recursive"
version = "0.1.0"
TOML
cat > $W/src/main.av <<'AV'
use shapes.{shape, made}

export collect enum Shape = @shape in package by it.mark.args[0] dense

fn seen(s: Shape) -> string {
    match s {
        .Dot -> "dot"
        .Line(to, next) -> "${to}${if next == null { "." } else { "+" }}"
        .Both(_, right) -> "${right.length}"
    }
}

seen(made())
AV
cat > $W/src/shapes/shapes.av <<'AV'
use @std.meta.{Named}
use main.{Shape}

export fn shape(_t: Named, _rank: int) {}

@shape(0)
type Dot = {}

@shape(1)
type Line = { to: int, next: Shape? }

@shape(2)
type Both = { left: Shape, right: List<Shape> }

export fn made() -> Shape { Shape.Line(7, null) }
AV
steps=$((steps+1)); first=$(ran $W)
[ "$first" = "7." ] || { fails=$((fails+1)); echo "FAIL  recursive, cold build: got '$first'"; }

ed $W/src/shapes/shapes.av 'type Line = { to: int, next: Shape? }' 'type Line = { to: string, next: Shape? }'
ed $W/src/shapes/shapes.av 'Shape.Line(7, null)' 'Shape.Line("seven", null)'
steps=$((steps+1)); turned=$(ran $W)
[ "$turned" = "seven." ] || { fails=$((fails+1)); echo "FAIL  recursive, after the member's field changed type: got '$turned' (a held enum signature would still carry int)"; }

echo "gathered-cache-attack: $steps runs through one store, $fails failed"
[ $fails -eq 0 ]

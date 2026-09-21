#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/.."
R=build/cache-attacks; fails=0; steps=0; holds=0
rm -rf "$R" .avra-cache && mkdir -p $R/lib/src/inner $R/a/src $R/b/src
cat > $R/lib/avra.toml <<'TOML'
[package]
name = "@rt/lib"
version = "0.1.0"

[lib]
name = "rt-lib"
path = "src/lib.av"
TOML
for p in a b; do cat > $R/$p/avra.toml <<TOML
[package]
name = "rt-$p"
version = "0.1.0"

[dependencies]
"@rt/lib" = { path = "../lib" }
TOML
done
cat > $R/lib/src/leaf.av <<'AV'
export fn one() -> int { 1 }
export fn two() -> int { 2 }
export fn label(n: int) -> string { "n=${n}" }
export const K: int = 5
AV
cat > $R/lib/src/gen.av <<'AV'
export fn pick<T>(a: T, b: T, first: bool) -> T { if first { a } else { b } }
AV
cat > $R/lib/src/inner/bar.av <<'AV'
export type Bar = { x: int }
AV
cat > $R/lib/src/shapes.av <<'AV'
use inner.{Bar}
export type Foo = { b: Bar, tag: string }
export fn foo() -> Foo { Foo { b: Bar { x: 7 }, tag: "t" } }
export fn bar_x(f: Foo) -> int { f.b.x }
AV
cat > $R/lib/src/shape.av <<'AV'
export trait Shape { fn area() -> int }
export type Sq = { s: int }
impl Shape for Sq { fn area() -> int { self.s * self.s } }
AV
cat > $R/lib/src/lib.av <<'AV'
export fn mid() -> int { one() + pick(10, 20, true) }
AV
cat > $R/a/src/main.av <<'AV'
use @rt.lib.{mid, one, pick, foo, bar_x, label, K, Shape, Sq, two}
// a held impl must still say what it implements, and a settled const runs a held body
const TWICE: int = two() + two()
fn apply(f: fn(int) -> string, n: int) -> string { f(n) }
let f = foo()
let held = [f, f]
let sh: dyn Shape = Sq { s: 3 }
println("a ${sh.area()} ${TWICE} ${mid()} ${one()} ${pick(3, 4, false)} ${bar_x(held[1])} ${apply(label, 3)} ${K}")
AV
cat > $R/b/src/main.av <<'AV'
use @rt.lib.{two, pick}
println("b ${two()} ${pick("x", "y", true)}")
AV
S() { # S <label> <app>
    steps=$((steps+1))
    out=$(./avra build --time $R/$2 2>$R/$2.err); st=$?; bin=$(printf '%s\n' "$out" | tail -1)
    held=$(grep -oE "held [0-9]+/[0-9]+" $R/$2.err | tail -1)
    case "$held" in "held 0/"*|"") ;; *) holds=$((holds+1)) ;; esac
    if [ ! -x "$bin" ]; then fails=$((fails+1)); echo "FAIL  $1 [$2] did not build (status $st): $(printf '%s\n' "$out" | cat - $R/$2.err | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')"; return; fi
    # A REFUSED HOLD IS A FINDING HERE: the build is right and the hold was wrong.
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep -A1 'the hold was refused' $R/$2.err | tail -1 | cut -c1-160)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | grep -v '^watch:')
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}
ed() { python3 - "$@" <<'PY'
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
S "cold a" a; S "b after a (shared leaf, other bodies + other instantiation)" b
S "no-op a" a; S "no-op b" b
ed $R/lib/src/leaf.av "{ 1 }" "{ 100 }";                       S "leaf body edit" a; S "leaf body edit" b
ed $R/lib/src/lib.av "one() +" "one() + two() +";              S "mid now calls a fn a never reached" a
ed $R/a/src/main.av '${K}' '${K} ${pick("p", "q", false)}';    S "new instantiation, home may be held" a
ed $R/lib/src/gen.av "{ a } else { b }" "{ b } else { a }";    S "generic body edit" a; S "generic body edit" b
ed $R/lib/src/inner/bar.av "Bar = { x: int }" "Bar = { x: int, y: int }"
ed $R/lib/src/shapes.av "Bar { x: 7 }" "Bar { x: 7, y: 9 }";   S "layout: a module a never imports moves Bar flat -> boxed, a holds Foo" a
ed $R/lib/src/leaf.av 'fn one() -> int { 100 }' 'fn one(k: int) -> int { 100 + k }'
ed $R/lib/src/lib.av "one() +" "one(1) +"
ed $R/a/src/main.av '${one()}' '${one(2)}';                    S "signature change" a; S "b untouched by it" b
ed $R/lib/src/leaf.av '"n=${n}"' '"N:${n}"';                   S "body of a fn taken as a VALUE (wrapper)" a
ed $R/lib/src/leaf.av "K: int = 5" "K: int = 6";               S "exported const edit" a
ed $R/lib/src/leaf.av "fn two() -> int { 2 }" "fn two() -> int { 20 }"; S "a held body a settled const RUNS" a
ed $R/lib/src/shape.av "self.s * self.s" "self.s + self.s";      S "a held impl a dyn box dispatches through" a
printf 'export fn extra() -> int { 40 }\n' > $R/lib/src/extra.av
ed $R/lib/src/lib.av "one(1) +" "one(1) + extra() +";          S "file added" a
ed $R/lib/src/lib.av "one(1) + extra() +" "one(1) +"; rm $R/lib/src/extra.av; S "file deleted" a; S "b after delete" b
ed $R/a/src/main.av 'println("a ' 'println("A ';                     S "entry-only edit" a
ed $R/a/src/main.av ' ${pick("p", "q", false)}' '';            S "instantiation removed" a
ud=$(find .avra-cache -type d -iname 'unit*' | head -1)
[ -n "$ud" ] || { echo "FAIL  no Unit family directory under .avra-cache: $(ls .avra-cache)"; fails=$((fails+1)); }
rm -rf "$ud"; S "every Unit row deleted (asks, homes, consts)" a; S "same, b" b
S "final no-op a" a
echo "cache-attacks: $steps builds through one store, $holds under a hold, $fails failed"
# A RUN THAT NEVER HELD ATTACKED NOTHING: every step above is green on the no-hold path.
[ "$holds" -gt 0 ] || { echo "cache-attacks: no step ran under a hold — the attacks examined nothing"; exit 1; }
[ "$fails" -eq 0 ]

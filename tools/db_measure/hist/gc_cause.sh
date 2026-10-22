#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/../../.."
# The shim's own lines are no program's output: its `watch:` reports, and the
# warning a shell with no terminal prints when the watchdog asks for job control.
unwatched() { grep -v -e '^watch:' -e 'job control turned off'; }

R=build/cache-attacks; fails=0; steps=0; holds=0
rm -rf "$R" .avra-cache && mkdir -p $R/lib/src/inner $R/a/src $R/b/src $R/c/src
cat > $R/lib/avra.toml <<'TOML'
[package]
name = "@rt/lib"
version = "0.1.0"

[lib]
name = "rt-lib"
path = "src/lib.av"
TOML
for p in a b c; do cat > $R/$p/avra.toml <<TOML
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
# one-field records of every word: a layout is ONE law's answer, held or parsed
cat > $R/lib/src/words.av <<'AV'
export type Word = { text: string }
export type Ratio = { r: float }
export type Tick = { n: int }
export type Line = { head: Word?, at: Tick }
export const HEAD: Line = Line { head: Word { text: "hi" }, at: Tick { n: 4 } }
export fn ratio() -> Ratio { Ratio { r: 0.5 } }
export fn word(w: Word) -> string { w.text }
export fn tick() -> Tick { Tick { n: 8 } }
AV
# a SIBLING FILE'S signature names Word by TYPE, never edited itself — the
# wire it was recorded with must still name Word after words.av reorders.
cat > $R/lib/src/wordcall.av <<'AV'
export fn word_upper(w: Word) -> string { w.text }
AV
# a QUOTED fn wears a real fn's name and another signature: it is no symbol
cat > $R/lib/src/made.av <<'AV'
use @std.meta.{Decls}
export fn quoted() -> Decls { quote { fn two(s: string) -> string { s } } }
AV
# a SIBLING's signature moves and its caller is never edited: a file sees its own module
cat > $R/lib/src/sib.av <<'AV'
export fn sized() -> int { 3 }
AV
cat > $R/lib/src/sibcall.av <<'AV'
export fn shown() -> string { "${sized()}" }
AV
# a const that RUNS a fn that READS a const: the value three files away is baked in
printf 'export const J: int = 7\n' > $R/lib/src/deep.av
printf 'export fn beyond() -> int { J + 1 }\n' > $R/lib/src/reach.av
cat > $R/lib/src/lib.av <<'AV'
export fn mid() -> int { one() + pick(10, 20, true) }
AV
cat > $R/a/src/main.av <<'AV'
use @rt.lib.{mid, one, pick, foo, bar_x, label, K, Shape, Sq, two, HEAD, Word, ratio, word, tick, shown, beyond, word_upper}
// a held impl must still say what it implements, and a settled const runs a held body
const TWICE: int = two() + two()
const FAR: int = beyond()
fn apply(f: fn(int) -> string, n: int) -> string { f(n) }
let f = foo()
let held = [f, f]
let sh: dyn Shape = Sq { s: 3 }
let big = if ratio().r > 0.4 { "big" } else { "small" }
println("a ${FAR} ${shown()} ${HEAD.head?.text ?? "-"} ${HEAD.at.n} ${big} ${word(Word { text: "w" })} ${word_upper(Word { text: "u" })} ${tick().n} ${sh.area()} ${TWICE} ${mid()} ${one()} ${pick(3, 4, false)} ${bar_x(held[1])} ${apply(label, 3)} ${K}")
AV
cat > $R/b/src/main.av <<'AV'
use @rt.lib.{two, pick}
println("b ${two()} ${pick("x", "y", true)}")
AV
# c SEALS a record the library declares flat: that layout is c's alone
cat > $R/c/src/main.av <<'AV'
use @rt.lib.{Tick, tick, two}
fn bump(mut t: Tick) { t.n = t.n + two() }
mut t = tick()
bump(t)
println("c ${t.n}")
AV
S() { # S <label> <app>
    steps=$((steps+1))
    out=$(./avra build --time $R/$2 2>$R/$2.err); st=$?; bin=$(printf '%s\n' "$out" | tail -1)
    held=$(grep -oE "held [0-9]+/[0-9]+" $R/$2.err | tail -1)
    case "$held" in "held 0/"*|"") ;; *) holds=$((holds+1)) ;; esac
    if [ ! -x "$bin" ]; then fails=$((fails+1)); echo "FAIL  $1 [$2] did not build (status $st): $(printf '%s\n' "$out" | cat - $R/$2.err | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')"; return; fi
    # A REFUSED HOLD IS A FINDING HERE: the build is right and the hold was wrong.
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep 'the hold was refused' $R/$2.err | head -1 | cut -c1-200)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | unwatched)
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}

# A READ STATES ITS CAUSE, NEVER ITS CONSEQUENCE. A collector in its package's ROOT module,
# whose key covers every module under it: a member module added moves that key, so the walk
# sees only a key with nothing kept under it — the read must still name what moved it, the set
# its collect gathers. In a store of its own.
gc=$(mktemp -d); mkdir -p $gc/gk/src/m $gc/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $gc/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $gc/gk/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $gc/gk/src/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $gc/gk/src/m/m.av
printf '[package]\nname = "rt-gc"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $gc/app/avra.toml
printf 'use @rt.gk.lib.{a_at}\nprintln("a=${a_at()}")\n' > $gc/app/src/main.av
steps=$((steps+1)); ./avra build $gc/app > /dev/null 2>&1
mkdir -p $gc/gk/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $gc/gk/src/n/n.av
steps=$((steps+1)); gc_out=$(./avra build --time $gc/app 2>&1); gc_got=$($gc/app/src/main 2>&1)
[ "$gc_got" = "a=1" ] || { fails=$((fails+1)); echo "FAIL  gc: a member module added: the binary printed '$gc_got', wanted 'a=1'"; }
case "$gc_out" in *"gk/src/lib.av — what its collect gathers"*) ;; *) fails=$((fails+1)); echo "FAIL  gc: a member module added: lib.av's read names its key, not the set that moved it: $(printf '%s' "$gc_out" | sed -n '/^read:/,$p' | grep 'lib.av' | cut -c1-200)" ;; esac
rm -rf $gc

echo "gc: $steps steps, $fails failed"

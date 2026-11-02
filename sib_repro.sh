#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")"
. tools/lib/failed_tail.sh
# The shim's own lines are no program's output: its `watch:` reports, and the
# warning a shell with no terminal prints when the watchdog asks for job control.
unwatched() { grep -v -e '^watch:' -e 'job control turned off'; }

R=build/cache-attacks; fails=0; steps=0; holds=0
# CACHE_ATTACKS names the sections to run, comma-separated (`kr,kv`); unset runs all.
section() { [ -z "${CACHE_ATTACKS:-}" ] || case ",$CACHE_ATTACKS," in *",$1,"*) ;; *) false ;; esac; }
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
    if [ ! -x "$bin" ]; then fails=$((fails+1)); echo "FAIL  $1 [$2] did not build (status $st)"; { printf '%s\n' "$out"; cat $R/$2.err; } | failed_words; return; fi
    # A REFUSED HOLD IS A FINDING HERE: the build is right and the hold was wrong.
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep 'the hold was refused' $R/$2.err | head -1 | cut -c1-200)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | unwatched)
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}

HR() { # HR <label> <build|check> <pkg> <exit> [<path-substr> <held|read>]...
    steps=$((steps+1))
    label=$1; verb=$2; pkg=$3; want_st=$4; shift 4
    out=$(./avra $verb --time $R/$pkg 2>&1); st=$?
    case "$out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; esac
    if [ $st -ne "$want_st" ]; then fails=$((fails+1)); echo "FAIL  $label: exit $st, wanted $want_st"; printf '%s\n' "$out" | failed_words; return; fi
    read_list=$(printf '%s\n' "$out" | sed -n '/^read:/,$p' | grep '^  ')
    while [ $# -ge 2 ]; do
        case "$read_list" in *"$1"*) got=read ;; *) got=held ;; esac
        if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $label: $1 -> $got"; else fails=$((fails+1)); echo "FAIL  $label: $1 wanted $2, got $got: $(printf '%s' "$read_list" | tr '\n' ' ')"; fi
        shift 2
    done
}

S "cold a" a; S "b after a (shared leaf, other bodies + other instantiation)" b
S "no-op a" a; S "no-op b" b
S "c seals a record the store's objects hold flat" c
ed $R/c/src/main.av 'println("c ' 'println("cc ';                   S "c again: its own records keep the sealed layout" c
ed $R/lib/src/leaf.av "{ 1 }" "{ 100 }";                       S "leaf body edit" a; S "leaf body edit" b
ed $R/lib/src/lib.av "one() +" "one() + two() +";              S "mid now calls a fn a never reached" a
ed $R/a/src/main.av '${K}' '${K} ${pick("p", "q", false)}';    S "new instantiation, home may be held" a
ed $R/lib/src/gen.av "{ a } else { b }" "{ b } else { a }";    S "generic body edit" a; S "generic body edit" b
ed $R/lib/src/gen.av "{ b } else { a }" "{ a } else { b }"
printf '// moved\n' >> $R/lib/src/leaf.av;                       S "a home back to a text the store knows, a file moved beside it" a; S "same, b" b
ed $R/lib/src/inner/bar.av "Bar = { x: int }" "Bar = { x: int, y: int }"
ed $R/lib/src/shapes.av "Bar { x: 7 }" "Bar { x: 7, y: 9 }";   S "layout: a module a never imports moves Bar flat -> boxed, a holds Foo" a
ed $R/lib/src/leaf.av 'fn one() -> int { 100 }' 'fn one(k: int) -> int { 100 + k }'
ed $R/lib/src/lib.av "one() +" "one(1) +"
ed $R/a/src/main.av '${one()}' '${one(2)}';                    S "signature change" a; S "b untouched by it" b
ed $R/lib/src/leaf.av '"n=${n}"' '"N:${n}"';                   S "body of a fn taken as a VALUE (wrapper)" a
ed $R/lib/src/leaf.av "K: int = 5" "K: int = 6";               S "exported const edit" a
ed $R/lib/src/leaf.av "fn two() -> int { 2 }" "fn two() -> int { 20 }"; S "a held body a settled const RUNS" a
ed $R/lib/src/deep.av "J: int = 7" "J: int = 70";                 S "a const a RUN read, two files from the const that ran it" a
ed $R/lib/src/shape.av "self.s * self.s" "self.s + self.s";      S "a held impl a dyn box dispatches through" a
ed $R/lib/src/sib.av "fn sized() -> int { 3 }" "fn sized() -> string { \"three\" }"
AVRA_QTRACE=1 ./avra build --time $R/a > /tmp/sib.out 2> /tmp/sib.trace; echo "build $?"
grep -a "^time\|held\|^read:\|^  " /tmp/sib.trace | grep -av "^Q" | cut -c1-200 | head -40
echo "native: $($R/a/src/main 2>&1)"
grep -a "sibcall\|sib.av" /tmp/sib.trace | grep -av "Q.ask\|Q.settle" | cut -c1-200 | sort | uniq -c | sort -rn | head -40
grep -a "PROBE" /tmp/sib.trace | cut -c1-300 | head -20
grep -a "^Q.attempt" /tmp/sib.trace | head

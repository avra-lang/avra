#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/.."
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
use @rt.lib.{mid, one, pick, foo, bar_x, label, K, Shape, Sq, two, HEAD, Word, ratio, word, tick, shown, beyond}
// a held impl must still say what it implements, and a settled const runs a held body
const TWICE: int = two() + two()
const FAR: int = beyond()
fn apply(f: fn(int) -> string, n: int) -> string { f(n) }
let f = foo()
let held = [f, f]
let sh: dyn Shape = Sq { s: 3 }
let big = if ratio().r > 0.4 { "big" } else { "small" }
println("a ${FAR} ${shown()} ${HEAD.head?.text ?? "-"} ${HEAD.at.n} ${big} ${word(Word { text: "w" })} ${tick().n} ${sh.area()} ${TWICE} ${mid()} ${one()} ${pick(3, 4, false)} ${bar_x(held[1])} ${apply(label, 3)} ${K}")
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
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep -A1 'the hold was refused' $R/$2.err | tail -1 | cut -c1-160)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | grep -v '^watch:')
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
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
ed $R/lib/src/sib.av "fn sized() -> int { 3 }" "fn sized() -> string { \"three\" }"; S "a sibling's answer type moves, its caller unedited" a
ed $R/b/src/main.av 'println("b ' 'fn bump(mut t: Tick) { t.n = t.n + 1 }
mut bt = tick()
bump(bt)
println("b ${bt.n} '
ed $R/b/src/main.av "use @rt.lib.{two, pick}" "use @rt.lib.{two, pick, Tick, tick}"; S "a seal arrives from a file that does not declare the record" b
# A HELD CALLEE'S CONSUMED SEAT (R3): wrapped(s) packs s into a fresh list it
# answers — the callee never retains it itself, so the CALLER must hand s
# over already retained. (.66 hole 3: a held callee's record never carried
# `consumed`, so a fresh caller reading it back defaulted every seat plain,
# skipped the retain, and s's second use read what the callee's own,
# never-happened release should have kept alive.)
printf 'export fn wrapped(s: string) -> List<string> { [s] }\n' >> $R/lib/src/leaf.av
ed $R/b/src/main.av "use @rt.lib.{two, pick, Tick, tick}" "use @rt.lib.{two, pick, Tick, tick, wrapped}"
ed $R/b/src/main.av 'println("b ${bt.n} ${two()} ${pick("x", "y", true)}")' 'let s = "s-${bt.n}"
let w = wrapped(s)
println("b ${bt.n} ${two()} ${pick("x", "y", true)} ${s} ${w[0]}")'
S "a held callee's consumed seat: the caller retains s before wrapped(s) takes it" b
ed $R/a/src/main.av 'println("a ' 'println("a. ';                   S "a, whose objects read it flat" a
printf 'export fn extra() -> int { 40 }\n' > $R/lib/src/extra.av
ed $R/lib/src/lib.av "one(1) +" "one(1) + extra() +";          S "file added" a
ed $R/lib/src/lib.av "one(1) + extra() +" "one(1) +"; rm $R/lib/src/extra.av; S "file deleted" a; S "b after delete" b
ed $R/a/src/main.av 'println("a. ' 'println("A ';                     S "entry-only edit" a
ed $R/a/src/main.av ' ${pick("p", "q", false)}' '';            S "instantiation removed" a
ud=$(find .avra-cache -type d -iname 'unit*' | head -1)
[ -n "$ud" ] || { echo "FAIL  no Unit family directory under .avra-cache: $(ls .avra-cache)"; fails=$((fails+1)); }
rm -rf "$ud"; S "every Unit row deleted (asks, homes, consts)" a; S "same, b" b
ed $R/c/src/main.av 'println("cc ' 'println("C ';                     S "c again, over a's objects" c
S "final no-op a" a
# A GENERIC REACHED WITH NO SUBSTITUTION IS STILL AN INSTANTIATION, and the caller's.
# `st` holds @std/relation reaching only stable.av; `rel`'s derive then calls db.av's
# `stores<R>` with R pinned by nothing but the answer, from a home `st` never lowered.
# The held generic's stub and that roaming instance share one NAME, declared once:
# signatures that disagreed would be an "invalid redefinition" at emit, not at link.
mkdir -p $R/st/src $R/rel/src
printf '[package]\nname = "rt-st"\nversion = "0.1.0"\n' > $R/st/avra.toml
printf '[package]\nname = "rt-rel"\nversion = "0.1.0"\n' > $R/rel/avra.toml
printf 'use @std.relation.stable.{stable_hasher}\nprintln("st ${stable_hasher(1).finish() != 0}")\n' > $R/st/src/main.av
cat > $R/rel/src/main.av <<'AV'
use @std.relation.{relation}
use @std.relation.db.{new_db}
@relation
type Todo = { id: int, @index owner: string }
let db = new_db()
let _ = Todo.insert(db, owner: "a")
println("rel ${Todo.all(db).length}")
AV
S "a program holds @std/relation, reaching only stable.av" st
S "a @relation's generic, reached with no substitution, from a home never lowered" rel

# THE SUITE THROUGH THE SAME STORE: a verdict must follow a body a held test calls
mkdir -p $R/t/src/tests/shown
cat > $R/t/avra.toml <<'TOML'
[package]
name = "@rt/t"
version = "0.1.0"

[lib]
name = "rt-t"
path = "src/lib.av"
TOML
printf 'export fn three() -> int { 3 }\n' > $R/t/src/lib.av
cat > $R/t/src/tests/lib_test.av <<'AV'
use @rt.t.{three}
spec "three" { given "the fn" { then "it answers three" { three() == 3 } } }
AV
printf 'use @rt.t.{three}\nprintln("three is ${three()}")\n' > $R/t/src/tests/shown/shown.av
printf 'three is 3\n' > $R/t/src/tests/shown/shown.expected
T() { # T <label> <want: green|red>
    steps=$((steps+1)); out=$(./avra test --time $R/t 2>&1); st=$?
    case "$out" in *"held 0/"*|*"cache hit"*) ;; *"held "*) holds=$((holds+1)) ;; esac
    got=green; [ "$st" -ne 0 ] && got=red
    if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [t] -> $got"; else fails=$((fails+1)); echo "FAIL  $1 [t] wanted $2, got $got: $(printf '%s' "$out" | grep -vE '^watch:|^time:' | tail -3 | tr '\n' ' ')"; fi
}
T "suite cold" green; T "suite no-op" green
ed $R/t/src/lib.av "{ 3 }" "{ 4 }";                           T "a body a HELD case calls moves: the verdict follows" red
ed $R/t/src/lib.av "{ 4 }" "{ 3 }";                           T "and back" green
ed $R/t/src/tests/shown/shown.expected "three is 3" "three is 4"; T "the text a program must print moves" red
ed $R/t/src/tests/shown/shown.expected "three is 4" "three is 3"; T "and back" green
ed $R/t/src/tests/lib_test.av "three() == 3" "three() == 3 && true"; T "a case's own body moves" green

# ONE FILE'S CASES, WITH EVERY FILE HELD: nothing is read, so no module is minted and
# no type interned — the entry declares the cases it calls and is built over the
# registry that links it, or the module is refused.
steps=$((steps+1)); out=$(./avra test --time $R/t/src/tests/lib_test.av 2>&1); st=$?
case "$out" in *"held 0/"*|*"cache hit"*) ;; *"held "*) holds=$((holds+1)) ;; esac
if [ "$st" -eq 0 ]; then [ -n "${VERBOSE:-}" ] && echo "ok    one file's cases under a whole hold [t]"; else fails=$((fails+1)); echo "FAIL  one file's cases under a whole hold [t]: $(printf '%s' "$out" | grep -vE '^watch:|^time:' | tail -3 | tr '\n' ' ')"; fi

# A HELD ENUM'S PAYLOAD NAMES A SIBLING STRUCT: filling it asks that struct's
# signature, which asks its own file's VISIBLE namespace — this module's, already
# open while the sibling that carries it is being minted from the same record. A
# re-entry here must be a smaller view, never a trap (avra-8sb5.25.52/.54: a stale
# hold once traps "memo family N reused missing key M", and once silently drops a
# native rule finding for a file the mixed hold never re-examines).
mkdir -p $R/cyc/src
cat > $R/cyc/avra.toml <<'TOML'
[package]
name = "rt-cyc"
version = "0.1.0"
TOML
cat > $R/cyc/src/cyc_b.av <<'AV'
export type CycB = { n: int }
AV
cat > $R/cyc/src/cyc_a.av <<'AV'
export enum CycA { Payload(v: CycB) }
export fn cyc_n(c: CycA) -> int { match c { .Payload(v) -> v.n } }
AV
cat > $R/cyc/src/main.av <<'AV'
println("cyc ${cyc_n(CycA.Payload(CycB { n: 9 }))}")
AV
C() { # C <label> <want: ok|trap>
    steps=$((steps+1)); out=$(./avra check $R/cyc 2>&1); st=$?
    got=ok; [ "$st" -ne 0 ] && got=trap
    if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [cyc] -> $got"; else fails=$((fails+1)); echo "FAIL  $1 [cyc] wanted $2, got $got: $(printf '%s' "$out" | grep -vE '^watch:' | tail -3 | tr '\n' ' ')"; fi
}
C "cold cyc" ok
C "no-op cyc" ok
ed $R/cyc/src/cyc_b.av "CycB = { n: int }" "CycB = { n: int, m: int = 0 }"
C "cyc_b moves alone — cyc_a stays held, its enum payload re-enters cyc_b's own visible namespace mid-mint" ok

# A NAME A HELD FILE REACHES WITHOUT AN IMPORT LEAVES ITS MODULE: the file did not
# move and is refused all the same — a hold that kept it would hide the refusal
cp $R/lib/src/sib.av $R/sib.kept
mkdir -p $R/lib/src/away && mv $R/lib/src/sib.av $R/lib/src/away/sib.av
steps=$((steps+1)); out=$(./avra build $R/a 2>&1); st=$?
if [ "$st" -eq 0 ] || ! printf '%s' "$out" | grep -q "sized"; then fails=$((fails+1)); echo "FAIL  a sibling left the module and its caller still built (status $st)"; fi
mv $R/lib/src/away/sib.av $R/lib/src/sib.av; rmdir $R/lib/src/away; S "and back" a

# THE BINARY'S KEY COVERS WHAT THE PROGRAM REACHES, and nothing else: a toolchain
# package is admitted only as a `use` reaches for it, so the closure is remembered.
# The toolchain's own files are touched with a comment and put back, whatever ends the run.
mkdir -p $R/d/src
printf '[package]\nname = "rt-d"\nversion = "0.1.0"\n' > $R/d/avra.toml
printf 'use @std.path.{stem_of}\nprintln("d ${stem_of("x/y.av")}")\n' > $R/d/src/main.av
reached=$(ls packages/std-path/src/*.av | head -1); later=$(ls packages/std-text/src/*.av | head -1); never=$(ls packages/std-json/src/*.av | head -1)
for f in $reached $later $never; do cp $f $R/$(basename $(dirname $(dirname $f))).kept; done
back() { cp $R/std-path.kept $reached; cp $R/std-text.kept $later; cp $R/std-json.kept $never; }
trap back EXIT INT TERM
K() { # K <label> <want: hit|built>
    steps=$((steps+1)); out=$(./avra build --time $R/d 2>&1); got=built
    case "$out" in *"cache hit"*) got=hit ;; esac
    if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [d] -> $got"; else fails=$((fails+1)); echo "FAIL  $1 [d] wanted $2, got $got"; fi
}
K "cold d" built; K "no-op d" hit
printf '\n// moved\n' >> $reached;  K "a toolchain package d reaches moves" built
cp $R/std-path.kept $reached;         K "and back, to a key the store knows" hit
printf '\n// moved\n' >> $never;    K "a toolchain package d never reaches moves" hit
cp $R/std-json.kept $never
printf '\n// moved\n' >> $later;    K "one d does not reach YET moves" hit
cp $R/std-text.kept $later
ed $R/d/src/main.av 'use @std.path.{stem_of}' 'use @std.path.{stem_of}
use @std.text.{from_codepoint}'
ed $R/d/src/main.av 'println("d ' 'println("d ${from_codepoint(65)} '
S "a use reaches a package the closure has not met" d;  K "no-op d" hit
printf '\n// moved\n' >> $later;    K "and that package moves" built
back; trap - EXIT INT TERM

# A STORE IS ONE COMPILER'S, named by the compiler's BYTES: the same compiler
# from another path reads its own rows, and one of other bytes reads none of them.
# Both stand beside `build/avra`, where a compiler finds its toolchain.
W() { # W <label> <compiler> <want: hit|built>
    steps=$((steps+1)); out=$(AVRA_CWD=$PWD $2 build --time $R/d 2>&1); got=built
    case "$out" in *"cache hit"*) got=hit ;; esac
    if [ "$got" = "$3" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [d] -> $got"; else fails=$((fails+1)); echo "FAIL  $1 [d] wanted $3, got $got"; fi
}
K "d, by the compiler itself" hit; stores=$(ls .avra-cache | grep -vc compilers)
cp build/avra build/avra.twin;                 W "the same bytes from another path" build/avra.twin hit
strip -x build/avra -o build/avra.other 2>/dev/null && { codesign -f -s - build/avra.other 2>/dev/null || true; }
W "a compiler of other bytes" build/avra.other built
steps=$((steps+1)); [ "$(ls .avra-cache | grep -vc compilers)" -gt "$stores" ] || { fails=$((fails+1)); echo "FAIL  a compiler of other bytes wrote into another's store"; }
W "and its own store serves it" build/avra.other hit
K "while the first compiler's still serves the first" hit
rm -f build/avra.twin build/avra.other

# CHECK SPEAKS THE SAME under a hold as from the sources
for app in a b c; do
    held_says=$(./avra check $R/$app 2>&1 | grep -v '^watch:')
    rm -rf .avra-cache; plain_says=$(./avra check $R/$app 2>&1 | grep -v '^watch:')
    steps=$((steps+1)); [ "$held_says" = "$plain_says" ] || { fails=$((fails+1)); echo "FAIL  check [$app] speaks otherwise under the hold"; }
done
echo "cache-attacks: $steps builds through one store, $holds under a hold, $fails failed"
# A RUN THAT NEVER HELD ATTACKED NOTHING: every step above is green on the no-hold path.
[ "$holds" -gt 0 ] || { echo "cache-attacks: no step ran under a hold — the attacks examined nothing"; exit 1; }
[ "$fails" -eq 0 ]

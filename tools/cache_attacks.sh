#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/.."
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
# A DECLARATION INSERTED ABOVE ANOTHER SHIFTS ITS ORDINAL WITHIN THE FILE: a
# caller held across the edit reads every shifted name's WIRE, and the wire
# must still name the shape it named before — never the newcomer sharing its
# old ordinal.
ed $R/lib/src/words.av 'export type Word = { text: string }' 'export enum Sizing { Fixed, Auto }
export type Word = { text: string }'
S "a type inserted above Word/Ratio/Tick/Line: a's held wire must not read the newcomer" a
ed $R/lib/src/words.av 'export enum Sizing { Fixed, Auto }
export type Word = { text: string }' 'export type Word = { text: string }'
S "and back" a
# A FREE FN BECOMES A METHOD: the impl block it joins is a NEW declaration of
# its own, so every later ordinal in the file moves again, differently than a
# plain insertion does. wordcall.av (a SIBLING FILE, never edited) keeps
# reading Word by the wire words.av wrote it under; the wire must still
# name Word, never whatever now sits at Word's old ordinal.
ed $R/lib/src/words.av 'export type Word = { text: string }' 'fn decoy_one() -> int { 1 }
fn decoy_two() -> int { 2 }
fn decoy_three() -> int { 3 }
fn decoy_four() -> int { 4 }
export type Word = { text: string }'
S "four free fns inserted above Word" a
ed $R/lib/src/words.av 'fn decoy_one() -> int { 1 }
fn decoy_two() -> int { 2 }
fn decoy_three() -> int { 3 }
fn decoy_four() -> int { 4 }
export type Word = { text: string }' 'export type Word = { text: string }
impl Word {
    static fn decoy_one() -> int { 1 }
    static fn decoy_two() -> int { 2 }
    static fn decoy_three() -> int { 3 }
    static fn decoy_four() -> int { 4 }
}'
S "the same four fns moved into impl Word: wordcall.av's held wire to Word must not read a decoy method" a
ed $R/lib/src/words.av 'export type Word = { text: string }
impl Word {
    static fn decoy_one() -> int { 1 }
    static fn decoy_two() -> int { 2 }
    static fn decoy_three() -> int { 3 }
    static fn decoy_four() -> int { 4 }
}' 'export type Word = { text: string }'
S "and back, again" a
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
# A HOME THE TREE NO LONGER HAS: a case lowers `twice` from twice.av, then stops
# asking for it and the file goes. The kept home list still names it, and the
# suite's print must never ask the gone text for a digest.
printf 'export fn twice<T>(x: T) -> List<T> { [x, x] }\n' > $R/t/src/twice.av
ed $R/t/src/tests/lib_test.av "use @rt.t.{three}" "use @rt.t.{three, twice}"
ed $R/t/src/tests/lib_test.av "three() == 3 && true" "twice(three()).length == 2"; T "a case lowers from a new home" green
ed $R/t/src/tests/lib_test.av "use @rt.t.{three, twice}" "use @rt.t.{three}"
ed $R/t/src/tests/lib_test.av "twice(three()).length == 2" "three() == 3 && true"; rm $R/t/src/twice.av; T "the home is deleted" green

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
    held_says=$(./avra check $R/$app 2>&1 | unwatched)
    rm -rf .avra-cache; plain_says=$(./avra check $R/$app 2>&1 | unwatched)
    steps=$((steps+1)); [ "$held_says" = "$plain_says" ] || { fails=$((fails+1)); echo "FAIL  check [$app] speaks otherwise under the hold"; }
done

# `--verify-held` OVER A WARM `a`: every held declaration this build just kept
# decodes back to what a fresh reading of the same file produces, and a run
# that compared nothing is a failure, never a clean pass.
steps=$((steps+1)); ./avra check $R/a >/dev/null 2>&1
vh=$(./avra check $R/a --verify-held 2>&1 | unwatched)
case "$vh" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over a compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over a -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over a: $(printf '%s' "$vh" | tail -5 | tr '\n' ' ')" ;;
esac

# A CALLER'S CONST FOLLOWS ITS CALLEE'S BODY EVEN WHEN THE CALLER'S OWN FILE IS
# HELD, NEVER THE ENTRY: `hcl/src/lib.av` declares `const M` and is a library
# file, so it is never forced fresh by the entry law — `a`'s own held consts
# above (TWICE, FAR) all live in the entry and never exercise this. Editing
# only `seed()`'s body, in a sibling file `lib.av` never touches, must still
# move `M`: `avra run` holds nothing, so a native/eval split here means a
# stale held object, not a mistyped fixture (avra-8sb5.57.85).
mkdir -p $R/hcl/src $R/hc/src
printf '[package]\nname = "@rt/hcl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-hcl"\npath = "src/lib.av"\n' > $R/hcl/avra.toml
printf 'export fn seed() -> int { 41 }\n' > $R/hcl/src/seed.av
printf 'export const M: int = seed()\n' > $R/hcl/src/lib.av
printf '[package]\nname = "rt-hc"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/hcl" = { path = "../hcl" }\n' > $R/hc/avra.toml
printf 'use @rt.hcl.{M}\nprintln("hc ${M}")\n' > $R/hc/src/main.av
S "cold hc: a const in a non-entry file settles from a callee" hc
got=$($R/hc/src/main 2>&1)
[ "$got" = "hc 41" ] || { fails=$((fails+1)); echo "FAIL  cold hc printed '$got', wanted 'hc 41'"; }
ed $R/hcl/src/seed.av "{ 41 }" "{ 42 }"
S "hc: the callee's body moves, the held caller's const must follow" hc
got=$($R/hc/src/main 2>&1)
[ "$got" = "hc 42" ] || { fails=$((fails+1)); echo "FAIL  warm hc printed '$got', wanted 'hc 42' — a held const did not follow its callee's body"; }
vh_hc=$(./avra check $R/hc --verify-held 2>&1 | unwatched)
steps=$((steps+1))
case "$vh_hc" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over hc compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over hc -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over hc: $(printf '%s' "$vh_hc" | tail -5 | tr '\n' ' ')" ;;
esac

# A BARE INTRA-PACKAGE MODULE KEYS ON ITS OWN INTERFACE, NEVER THE PACKAGE'S
# RAW TEXT: `lib.av` reaches `pad.av`'s exported `pad` through a `use` and its
# non-exported `priv` through no `use` at all — a sibling file's bare name
# reaches a declaration a cross-package `use` never could. A body-only edit
# must hold; a signature edit — exported or not — never may, or a sibling
# keeps compiling against a signature that moved (avra-8sb5.57's
# perf/module-hold). AND AN IMPORTER IN ANOTHER PACKAGE KEYS ON THE FILES ITS
# USES REACH, NEVER THE PACKAGE WHOLE: `show.av` names `host` alone, so a
# signature edit to `pad` holds it and one to `host` never may.
# AND AN IMPL IS REACHED THROUGH ITS TYPE: `dyn.av` names `Pt` and `Say`, never
# `pt_say.av`, yet the `dyn Say` box it builds carries that file's impl.
MH() { # MH <label> <path-substr> <want: held|read> [<path-substr> <want>]...
    steps=$((steps+1))
    label=$1; shift
    out=$(./avra build --time $R/mh 2>&1); st=$?
    case "$out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; esac
    # a build that failed read nothing, and says nothing a hold could be judged by
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $label did not build (status $st): $(printf '%s' "$out" | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')"; return; fi
    while [ $# -ge 2 ]; do
        case "$out" in *"read:"*"$1"*) got=read ;; *) got=held ;; esac
        if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $label: $1 -> $got"; else fails=$((fails+1)); echo "FAIL  $label: $1 wanted $2, got $got: $(printf '%s' "$out" | grep -A6 '^read:' | tr '\n' ' ')"; fi
        shift 2
    done
}
mkdir -p $R/mhl/src $R/mh/src
printf '[package]\nname = "@rt/mhl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-mhl"\npath = "src/lib.av"\n' > $R/mhl/avra.toml
cat > $R/mhl/src/pad.av <<'AV'
export fn pad() -> int { 3 }
fn priv() -> int { 5 }
AV
cat > $R/mhl/src/lib.av <<'AV'
use pad.{pad}
export fn host() -> int { pad() + priv() }
AV
printf '[package]\nname = "rt-mh"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/mhl" = { path = "../mhl" }\n"@rt/mht" = { path = "../mht" }\n' > $R/mh/avra.toml
mkdir -p $R/mht/src
printf '[package]\nname = "@rt/mht"\nversion = "0.1.0"\n\n[lib]\nname = "rt-mht"\npath = "src/lib.av"\n\n[dependencies]\n"@rt/mhl" = { path = "../mhl" }\n' > $R/mht/avra.toml
printf 'export trait Tell { fn tell() -> int }\n' > $R/mht/src/lib.av
cat > $R/mht/src/tell_pt.av <<'AV'
use @rt.mhl.{Pt}
fn tbase() -> int { 100 }
impl Tell for Pt { fn tell() -> int { self.v + tbase() } }
AV
printf 'use @rt.mht.{Tell}\nuse @rt.mhl.{Pt}\nexport fn told() -> int {\n    let s: dyn Tell = Pt { v: 5 }\n    s.tell()\n}\n' > $R/mh/src/third.av
printf 'use @rt.mhl.{host}\nexport fn shown() -> int { host() }\n' > $R/mh/src/show.av
cat > $R/mhl/src/pt.av <<'AV'
export trait Say { fn say() -> int }
export type Pt = { v: int }
AV
cat > $R/mhl/src/pt_say.av <<'AV'
use pt.{Say, Pt}
fn base() -> int { 1 }
impl Say for Pt { fn say() -> int { self.v + base() } }
AV
printf 'use @rt.mhl.{Say, Pt}\nexport fn said() -> int {\n    let s: dyn Say = Pt { v: 4 }\n    s.say()\n}\n' > $R/mh/src/dyn.av
printf 'println("mh ${shown()} ${said()} ${told()}")\n' > $R/mh/src/main.av
S "cold mh: a sibling reaches one file by use, another by no use at all" mh
S "mh: warm no-op" mh
ed $R/mhl/src/pad.av "{ 3 }" "{ 30 }"
MH "mh: pad's body only moves — lib.av stays held" lib.av held
ed $R/mhl/src/pad.av "{ 30 }" "{ 3 }"
MH "mh: and back" lib.av held
ed $R/mhl/src/pad.av "export fn pad() -> int { 3 }" "export fn pad(n: int = 0) -> int { 3 }"
MH "mh: pad's EXPORTED signature moves (reached through a use) — lib.av re-reads, show.av never named it" lib.av read show.av held
ed $R/mhl/src/pad.av "export fn pad(n: int = 0) -> int { 3 }" "export fn pad() -> int { 3 }"
MH "mh: and back" lib.av held show.av held
ed $R/mhl/src/lib.av "export fn host() -> int" "export fn host(n: int = 0) -> int"
MH "mh: host's signature moves — show.av names it, and re-reads" show.av read
ed $R/mhl/src/lib.av "export fn host(n: int = 0) -> int" "export fn host() -> int"
MH "mh: and back" show.av held
ed $R/mhl/src/pad.av "fn priv() -> int { 5 }" "fn priv(n: int = 0) -> int { 5 }"
MH "mh: priv's NON-exported signature moves (reached with no use at all) — lib.av re-reads" lib.av read show.av held
ed $R/mhl/src/pad.av "fn priv(n: int = 0) -> int { 5 }" "fn priv() -> int { 5 }"
MH "mh: and back, cold no more" lib.av held
ed $R/mhl/src/pt_say.av "self.v + base() }" "self.v + base() + 1 }"
MH "mh: the unnamed impl's body only moves — dyn.av stays held" dyn.av held
ed $R/mhl/src/pt_say.av "self.v + base() + 1 }" "self.v + base() }"
MH "mh: and back" dyn.av held
ed $R/mhl/src/pt_say.av "fn base() -> int" "fn base(n: int = 0) -> int"
MH "mh: the impl's file moves a signature — dyn.av boxes Pt as dyn Say, and re-reads" dyn.av read
ed $R/mhl/src/pt_say.av "fn base(n: int = 0) -> int" "fn base() -> int"
MH "mh: and back" dyn.av held
# AN IMPL IN THE TRAIT'S PACKAGE IS REACHED THROUGH THE TYPE IT AIMS AT, in another.
ed $R/mht/src/tell_pt.av "fn tbase() -> int" "fn tbase(n: int = 0) -> int"
MH "mh: the trait's package moves its impl's file — third.av re-reads" third.av read
ed $R/mht/src/tell_pt.av "fn tbase(n: int = 0) -> int" "fn tbase() -> int"
MH "mh: and back" third.av held
# THE IMPL LEAVES A FILE THAT STAYS FOR ONE NOBODY NAMES: dyn.av re-reads, and dispatches to it.
ed $R/mhl/src/pt_say.av "impl Say for Pt { fn say() -> int { self.v + base() } }" ""
printf 'use pt.{Say, Pt}\nfn tag() -> int { 0 }\nimpl Say for Pt { fn say() -> int { self.v * 1000 + tag() } }\n' > $R/mhl/src/pt_moved.av
MH "mh: the impl moves to a new file — dyn.av re-reads" dyn.av read
S "mh: and the box dispatches to the moved impl" mh
# AND GONE, A BOX OF Pt HAS NO VTABLE: the importer is refused by typing, never held into a link.
rm $R/mhl/src/pt_moved.av
steps=$((steps+1)); out=$(./avra build $R/mh 2>&1)
case "$out" in *"error[type."*) [ -n "${VERBOSE:-}" ] && echo "ok    mh: an impl gone -> refused" ;; *) fails=$((fails+1)); echo "FAIL  mh: an impl gone must refuse the box at typing: $(printf '%s' "$out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac
ed $R/mhl/src/pt_say.av "fn base() -> int { 1 }" "fn base() -> int { 1 }
impl Say for Pt { fn say() -> int { self.v + base() } }"
S "mh: the impl back home" mh

# A NAME REACHED THROUGH A RE-EXPORT KEYS ON THE RE-EXPORTING FILE TOO: `show.av`
# names `twice` from `@rt/rxl`, whose `lib.av` re-exports it, so the importer's
# reference lands on the ORIGINAL declaration's file. Re-pointing the re-export at
# another declaration never moves that file, and must still re-read `show.av` —
# or it stays held against a name that now means something else. A body edit to
# the original holds it (avra-8sb5.64.10.1).
RX() { # RX <label> <path-substr> <want: held|read> <printed>
    steps=$((steps+1))
    out=$(./avra build --time $R/rx 2>&1)
    case "$out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; esac
    case "$out" in *"read:"*"$2"*) got=read ;; *) got=held ;; esac
    if [ "$got" = "$3" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 -> $got"; else fails=$((fails+1)); echo "FAIL  $1 wanted $3, got $got: $(printf '%s' "$out" | grep -A5 '^read:' | tr '\n' ' ')"; fi
    printed=$("$(printf '%s\n' "$out" | tail -1)" 2>&1)
    [ "$printed" = "$4" ] || { fails=$((fails+1)); echo "FAIL  $1 printed '$printed', wanted '$4'"; }
}
mkdir -p $R/rxl/src/util $R/rxl/src/other $R/rx/src
printf '[package]\nname = "@rt/rxl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-rxl"\npath = "src/lib.av"\n' > $R/rxl/avra.toml
printf 'export fn twice() -> int { 2 }\n' > $R/rxl/src/util/u.av
printf 'export fn twice() -> int { 20 }\n' > $R/rxl/src/other/o.av
printf 'export use util.{twice}\n' > $R/rxl/src/lib.av
printf '[package]\nname = "rt-rx"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/rxl" = { path = "../rxl" }\n' > $R/rx/avra.toml
printf 'use @rt.rxl.{twice}\nexport fn shown() -> int { twice() }\n' > $R/rx/src/show.av
printf 'println("rx ${shown()}")\n' > $R/rx/src/main.av
S "cold rx: an importer reaches a name through a re-export" rx
ed $R/rxl/src/util/u.av "{ 2 }" "{ 4 }"
RX "rx: the original's body only moves — show.av stays held" show.av held "rx 4"
ed $R/rxl/src/util/u.av "{ 4 }" "{ 2 }"
RX "rx: and back" show.av held "rx 2"
ed $R/rxl/src/lib.av "util.{twice}" "other.{twice}"
RX "rx: the re-export is re-pointed — show.av re-reads" show.av read "rx 20"
ed $R/rxl/src/lib.av "other.{twice}" "util.{twice}"
RX "rx: and back — the store still keeps the first build's importer" show.av held "rx 2"

# `--verify-held` OVER A HELD `collect enum` (avra-8sb5.57.109): its record line's
# shape is `enum`, and its KIND column is what says a collect made it — read the
# shape alone and the held declaration is a plain enum, so the decl wire naming
# it (`…~collect_enum~~Command`) resolves to nothing: its references vanish and
# `describe`'s seat reads as an error type.
mkdir -p $R/ce/src/lib
printf '[package]\nname = "rt-ce"\nversion = "0.1.0"\n' > $R/ce/avra.toml
printf 'use lib.{describe, Command}\nprintln(describe(Command.init))\n' > $R/ce/src/main.av
cat > $R/ce/src/lib/a.av <<'AV'
use @std.meta.{Named}
fn command(_what: Named) {}
@command
fn build() {}
@command
fn init() {}
export collect enum Command = @command in self by it.name
export fn describe(c: Command) -> string {
    match c { .build -> "build", .init -> "init" }
}
AV
S "cold ce: a collect enum in a library module" ce
S "warm ce: the collect enum's file is held" ce
vh_ce=$(./avra check $R/ce --verify-held 2>&1 | unwatched)
steps=$((steps+1))
case "$vh_ce" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over ce compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over ce -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over ce: $(printf '%s' "$vh_ce" | tail -5 | tr '\n' ' ')" ;;
esac

# `--verify-held` COVERS AN IMPL'S TARGET (avra-8sb5.57.86): the target lives in
# Decls' own table, filled through ensure_target/fill_aims, never through `sig()`
# — a held file with no OTHER declaration worth diffing would pass this suite
# clean while the one fact an impl carries went unchecked. `vtlib/src/lib.av` is
# held both times (never the entry); the impl lands in it exactly once, so the
# SAME run's before/after declaration count proves it joined what was compared,
# never just an absolute total that a run examining nothing could still print.
mkdir -p $R/vtlib/src $R/vt/src
cat > $R/vtlib/avra.toml <<'TOML'
[package]
name = "@rt/vtlib"
version = "0.1.0"

[lib]
name = "rt-vtlib"
path = "src/lib.av"
TOML
printf '[package]\nname = "rt-vt"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/vtlib" = { path = "../vtlib" }\n' > $R/vt/avra.toml
cat > $R/vtlib/src/lib.av <<'AV'
export trait Shape { fn area() -> int }
export type Sq = { s: int }
AV
printf 'use @rt.vtlib.{Sq}\nprintln("vt ${Sq { s: 3 }.s}")\n' > $R/vt/src/main.av
S "cold vt: a trait/type pair, no impl yet" vt
vh_vt0=$(./avra check $R/vt --verify-held 2>&1 | unwatched)
n_vt0=$(printf '%s' "$vh_vt0" | sed -n 's/^verify-held: \([0-9]*\).*/\1/p')
steps=$((steps+1))
case "$vh_vt0" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over vt (no impl) compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over vt (no impl) -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over vt (no impl): $(printf '%s' "$vh_vt0" | tail -5 | tr '\n' ' ')" ;;
esac
ed $R/vtlib/src/lib.av 'export type Sq = { s: int }' 'export type Sq = { s: int }
impl Shape for Sq { fn area() -> int { self.s * self.s } }'
ed $R/vt/src/main.av 'use @rt.vtlib.{Sq}
println("vt ${Sq { s: 3 }.s}")' 'use @rt.vtlib.{Shape, Sq}
let sh: dyn Shape = Sq { s: 3 }
println("vt ${sh.area()}")'
S "vt: the impl lands in the same held file — a held impl is now present" vt
vh_vt1=$(./avra check $R/vt --verify-held 2>&1 | unwatched)
n_vt1=$(printf '%s' "$vh_vt1" | sed -n 's/^verify-held: \([0-9]*\).*/\1/p')
steps=$((steps+1))
case "$vh_vt1" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over vt (with impl) compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over vt (with impl) -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over vt (with impl): $(printf '%s' "$vh_vt1" | tail -5 | tr '\n' ' ')" ;;
esac
# THE DELTA IS THE PROOF: +2 is the impl block's own declaration and its one
# method, measured (avra-8sb5.57.86) against this exact fixture shape — a run
# that walked the file but skipped the impl (a kind filter dropping it, say)
# would still pass every case above while this alone catches it.
steps=$((steps+1))
if [ -z "$n_vt0" ] || [ -z "$n_vt1" ] || [ "$n_vt1" -ne "$((n_vt0 + 2))" ]; then
    fails=$((fails+1))
    echo "FAIL  the impl's own declarations never joined the held count: no-impl=$n_vt0 with-impl=$n_vt1, wanted with-impl=no-impl+2"
fi

# A BODY EDIT MUST NOT COST A DEPENDENT ITS HOLD: `wrap` alone takes `leaf`'s
# `helper` as a value, and a whole-program reference read answers the same
# whether `wrap` is held or read. Each part is its own module, so the
# reference crosses a module boundary a hold can stand on either side of.
mkdir -p $R/vh2/src/shape $R/vh2/src/leaf $R/vh2/src/wrap
cat > $R/vh2/avra.toml <<TOML
[package]
name = "rt-vh2"
version = "0.1.0"
TOML
cat > $R/vh2/src/shape/mod.av <<'AV'
export type Sq = { s: int }
impl Sq { fn area() -> int { self.s * self.s } }
AV
cat > $R/vh2/src/leaf/mod.av <<'AV'
use shape.{Sq}
export fn helper(cx: Sq) -> int { cx.area() }
AV
cat > $R/vh2/src/wrap/mod.av <<'AV'
use shape.{Sq}
use leaf.{helper}
export fn get_helper() -> fn(Sq) -> int { helper }
AV
cat > $R/vh2/src/main.av <<'AV'
use wrap.{get_helper}
use shape.{Sq}
let f = get_helper()
println("vh2 ${f(Sq { s: 3 })}")
AV
S "cold vh2: helper taken as a value from a non-entry module" vh2
ed $R/vh2/src/leaf/mod.av 'cx.area() }' 'cx.area() + 0 }'
S "vh2: a body-only edit in leaf/mod.av — no signature, no new declaration" vh2
held_vh2=$(grep -oE "held [0-9]+/[0-9]+" $R/vh2.err | tail -1 | sed 's/^held //')
h2=${held_vh2%/*}; m2=${held_vh2#*/}
steps=$((steps+1))
if [ -z "$h2" ] || [ -z "$m2" ] || [ "$h2" -lt "$((m2 - 2))" ]; then
    fails=$((fails+1))
    echo "FAIL  a body edit in leaf/mod.av cost the package its holds: held $held_vh2, wanted >= $((m2 - 2))/$m2 (only leaf/mod.av's own file need move)"
fi
# leaf/mod.av settles as a hold candidate now that nothing further edits it —
# `--verify-held` then compares `helper`'s OWN kept marks (written the run
# above, while `wrap/mod.av` was held) against a fresh reading: a wrongly-set
# `consumed` bit from that run is a MISMATCH here, never a clean pass.
S "vh2: no-op rebuild — leaf/mod.av is now itself a hold candidate" vh2
vh_vh2=$(./avra check $R/vh2 --verify-held 2>&1 | unwatched)
steps=$((steps+1))
case "$vh_vh2" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over vh2 compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over vh2 -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over vh2: $(printf '%s' "$vh_vh2" | tail -5 | tr '\n' ' ')" ;;
esac

# A HELD `_`-DECLARED CALLEE MUST NOT LOSE ITS ERROR UNION: `helper/mod.av`
# declares `raise_thing`, whose `Result<int, _>` infers `SomeErr` from its
# own `fail`; `leaf/mod.av` declares `wrapper`, whose OWN `Result<int, _>`
# infers ONLY through a `?` into `raise_thing` — nothing else in
# `wrapper`'s body can fail. A body-only edit to `leaf/mod.av` leaves
# `helper/mod.av` held; if the held callee's inferred set is read from the
# fixpoint's own (unfilled) table instead of its already-settled
# signature, `wrapper`'s answer collapses to "nothing here can fail" and
# the hold is refused whole — `S` itself catches that refusal as a FAIL.
mkdir -p $R/vh3/src/helper $R/vh3/src/leaf
cat > $R/vh3/avra.toml <<TOML
[package]
name = "rt-vh3"
version = "0.1.0"
TOML
cat > $R/vh3/src/helper/mod.av <<'AV'
export type SomeErr = { msg: string }
export fn raise_thing(n: int) -> Result<int, _> {
    if n < 0 { fail SomeErr { msg: "neg" } }
    n
}
AV
cat > $R/vh3/src/leaf/mod.av <<'AV'
use helper.{raise_thing}
export fn wrapper(n: int) -> Result<int, _> {
    raise_thing(n)?
}
AV
cat > $R/vh3/src/main.av <<'AV'
use leaf.{wrapper}
match wrapper(3) {
    .Ok(v) -> println("ok ${v}"),
    .Err(e) -> println("err ${e.msg}"),
}
match wrapper(-1) {
    .Ok(v) -> println("ok ${v}"),
    .Err(e) -> println("err ${e.msg}"),
}
AV
S "cold vh3: a fn's inferred error union flows through a call" vh3
ed $R/vh3/src/leaf/mod.av 'raise_thing(n)?' 'let m = n + 0
    raise_thing(m)?'
S "vh3: a body-only edit in leaf/mod.av — helper/mod.av stays held" vh3

# RULE FINDINGS ARE A CHECK'S WANT: a build keeps none and prints none; a check
# after that build reads no rule row, so it runs the rules over the file (a miss,
# never a wrong answer) and speaks what a cold check speaks; a check held on a
# check's rows speaks the same again.
mkdir -p $R/rw/src
printf '[package]\nname = "rt-rw"\nversion = "0.1.0"\n' > $R/rw/avra.toml
printf 'mut n = 1\nprintln("${n}")\n' > $R/rw/src/main.av
rm -rf .avra-cache; rw_cold=$(./avra check $R/rw 2>&1 | unwatched)
steps=$((steps+1)); case "$rw_cold" in *unmutated_mut*) ;; *) fails=$((fails+1)); echo "FAIL  the rule fixture draws no finding cold, so it attacks nothing" ;; esac
rm -rf .avra-cache; rw_build=$(./avra build $R/rw 2>&1)
steps=$((steps+1)); case "$rw_build" in *unmutated_mut*) fails=$((fails+1)); echo "FAIL  a build printed a rule finding" ;; esac
rw_after=$(./avra check $R/rw 2>&1 | unwatched)
steps=$((steps+1)); [ "$rw_after" = "$rw_cold" ] || { fails=$((fails+1)); echo "FAIL  a check after a build speaks otherwise than a cold check"; }
rw_held=$(./avra check $R/rw 2>&1 | unwatched)
steps=$((steps+1)); [ "$rw_held" = "$rw_cold" ] || { fails=$((fails+1)); echo "FAIL  a check held on a check's rows speaks otherwise than a cold check"; }

# THE RATCHET JUDGES EVERY FILE, HELD OR READ: an edit to module `y` alone
# holds module `x`, and `x/a.av`'s site — new against an empty baseline — must
# still refuse the warm check, or a held file's new site slips the gate.
mkdir -p $R/rf/src/x $R/rf/src/y
printf '[package]\nname = "rt-rf"\nversion = "0.1.0"\n' > $R/rf/avra.toml
printf 'export fn a() -> int {\n    mut n = 1\n    n\n}\n' > $R/rf/src/x/a.av
printf 'export fn b() -> int { 2 }\n' > $R/rf/src/y/b.av
printf 'use x.{a}\nuse y.{b}\nprintln("${a()} ${b()}")\n' > $R/rf/src/main.av
: > $R/rf.baseline
rm -rf .avra-cache; rf_cold=$(./avra check $R/rf --baseline $R/rf.baseline 2>&1 | unwatched)
steps=$((steps+1)); case "$rf_cold" in *"NEW violation"*"x/a.av"*) ;; *) fails=$((fails+1)); echo "FAIL  the ratchet fixture draws no new site cold, so it attacks nothing" ;; esac
ed $R/rf/src/y/b.av "{ 2 }" "{ 3 }"
rf_st=0; rf_warm=$(./avra check $R/rf --baseline $R/rf.baseline 2>&1) || rf_st=$?
steps=$((steps+1)); case "$rf_st:$rf_warm" in 1:*"NEW violation"*"x/a.av"*) ;; *) fails=$((fails+1)); echo "FAIL  a warm check after an edit elsewhere let a held file's new site through the ratchet (exit $rf_st)" ;; esac

# A CHECK THAT HOLDS SOME FILES AND READS OTHERS AFTER A BUILD: the held ones
# with no rule row are read again (a miss), and the check stands.
rm -rf .avra-cache; lib_cold=$(./avra check $R/lib 2>&1 | unwatched)
rm -rf .avra-cache; ./avra build $R/a >/dev/null 2>&1; ./avra check $R/a >/dev/null 2>&1
lib_after=$(./avra check $R/lib 2>&1 | unwatched)
steps=$((steps+1)); [ "$lib_after" = "$lib_cold" ] || { fails=$((fails+1)); echo "FAIL  a library check after an app's build and check speaks otherwise than a cold one"; }

# `Visible`/`Resolved`/`Typed`/`Folded`/`Analysis`/`Lowered`
# settle on a CONTENT fingerprint now, never `db.revision()` — a build-wide
# counter that read every edit anywhere as "changed" through them. These pin
# two of the fields the fold covers: a lambda's CAPTURE (NameFacts/TypeFacts)
# and a WARNING'S OWN PRESENCE (voices) — an edit to either must still reach
# a caller held across the edit, whether that caller is the program's own
# printed answer or the check output the file itself earns.
mkdir -p $R/cutfp/src
printf '[package]\nname = "rt-cutfp"\nversion = "0.1.0"\n' > $R/cutfp/avra.toml
cat > $R/cutfp/src/main.av <<'AV'
fn make_adder(n: int) -> fn(int) -> int {
    (x: int) -> x + n
}
mut unused = 1
let add = make_adder(5)
println("cutfp ${add(10)}")
AV
S "cold cutfp: a closure capture and an unmutated mut sit in one file" cutfp
got=$($R/cutfp/src/main 2>&1)
[ "$got" = "cutfp 15" ] || { fails=$((fails+1)); echo "FAIL  cold cutfp printed '$got', wanted 'cutfp 15'"; }
cutfp_warn0=$(./avra check $R/cutfp 2>&1 | grep -c 'unmutated_mut')
[ "$cutfp_warn0" = "1" ] || { fails=$((fails+1)); echo "FAIL  cutfp's cold check did not find the unmutated_mut warning it was written to earn"; }

# THE CAPTURE MOVES: the closure now closes over a DIFFERENT computation —
# its TypeFacts/NameFacts captures column changes though the file's declared
# NAMES do not, so a Namespace-level cache alone would miss it.
ed $R/cutfp/src/main.av 'x + n' 'x + n + 1'
S "cutfp: the closure's capture computation moves" cutfp
got=$($R/cutfp/src/main 2>&1)
[ "$got" = "cutfp 16" ] || { fails=$((fails+1)); echo "FAIL  warm cutfp printed '$got', wanted 'cutfp 16' — a captured value's edit did not propagate"; }

# THE WARNING MOVES, THE PROGRAM'S OWN VALUE ALSO MOVES: `mut unused`
# becomes read, so the unmutated_mut voice must vanish from a held file's
# own check — voices ride no program output, so only the diagnostic text
# can catch a dropped fold.
ed $R/cutfp/src/main.av 'mut unused = 1' 'mut unused = 1
unused = unused + 1'
ed $R/cutfp/src/main.av 'println("cutfp ${add(10)}")' 'println("cutfp ${add(10)} ${unused}")'
S "cutfp: a voice-only edit — the warning is earned no longer, the closure is untouched" cutfp
got=$($R/cutfp/src/main 2>&1)
[ "$got" = "cutfp 16 2" ] || { fails=$((fails+1)); echo "FAIL  warm cutfp printed '$got', wanted 'cutfp 16 2'"; }
cutfp_warn1=$(./avra check $R/cutfp 2>&1 | grep -c 'unmutated_mut')
[ "$cutfp_warn1" = "0" ] || { fails=$((fails+1)); echo "FAIL  cutfp's warm check still finds unmutated_mut after the local was written — a stale voices fold"; }

# A NON-STRUCTURAL SETTLEMENT REFUSAL RE-SPEAKS ON EVERY WARM BUILD: only a
# STRUCTURAL one (Reach) is persisted as ready; a const that traps while
# settling never is, so its file never holds and the trap never goes quiet.
mkdir -p $R/rs/src
printf '[package]\nname = "rt-rs"\nversion = "0.1.0"\n' > $R/rs/avra.toml
printf 'export const x: int = x + 1\n' > $R/rs/src/bad.av
cat > $R/rs/src/main.av <<'AV'
use bad.{x}
println("${x}")
AV
rm -rf .avra-cache; rs_cold=$(./avra build $R/rs 2>&1 | unwatched)
steps=$((steps+1)); case "$rs_cold" in *const.trap*) ;; *) fails=$((fails+1)); echo "FAIL  the trap fixture draws no diagnostic cold, so it attacks nothing" ;; esac
printf '// moved\n' >> $R/rs/src/main.av
rs_warm=$(./avra build $R/rs 2>&1 | unwatched)
steps=$((steps+1)); case "$rs_warm" in *const.trap*) ;; *) fails=$((fails+1)); echo "FAIL  a non-structural refusal went silent on a warm build" ;; esac

# A DURABLE WITNESS, PINNED — under AVRA_WITNESS_PIN=1 only: the
# `--time` field reads `witnessed 0/N` BOTH when the compile-time
# switch is off (nothing ever attempted) and when it is on and the
# Sig-hash bug makes every attempt fail, so the text alone cannot
# tell vacuous apart from broken. AVRA_WITNESS_PIN names which this
# binary is — set it only when `build/avra` was built with
# `witness_enabled: bool = true` — and unset (the gate's own runs)
# it skips the step outright rather than guess from the count.
# A LEAF edit — one file nothing else imports — must not cost every
# OTHER file its witness: `witnessed` must cover every file but the
# one edited. A `Sig`/`Methods` edge hashed from a `TypeId`/`DeclId`'s
# raw registry index (core/types.av's and core/nodes.av's own "means
# nothing outside this process") drifts between processes though the
# declaration's own text never changed, refusing every unrelated
# file's witness; a `rules_key` no witnessed path ever writes
# collapses `held` the same way.
mkdir -p $R/wr/src
printf '[package]\nname = "rt-wr"\nversion = "0.1.0"\n' > $R/wr/avra.toml
cat > $R/wr/src/leaf.av <<'AV'
export fn leaf_only() -> int { 1 }
AV
for n in 1 2 3 4 5 6; do
cat > $R/wr/src/other$n.av <<AV
export fn other_fn_$n() -> int { $n }
AV
done
cat > $R/wr/src/main.av <<'AV'
use other1.{other_fn_1}
use other2.{other_fn_2}
use other3.{other_fn_3}
use other4.{other_fn_4}
use other5.{other_fn_5}
use other6.{other_fn_6}
export fn two(a: int) -> int { a + other_fn_1() + other_fn_2() + other_fn_3() + other_fn_4() + other_fn_5() + other_fn_6() }
println("${two(1)}")
AV
if [ "${AVRA_WITNESS_PIN:-}" = "1" ]; then
    rm -rf .avra-cache
    ./avra check $R/wr >$R/wr.first.log 2>&1
    printf '\nexport fn leaf_only_added() -> int { 2 }\n' >> $R/wr/src/leaf.av
    wr_line=$(./avra check --time $R/wr 2>&1 | grep '^time:')
    steps=$((steps+1))
    wn=$(printf '%s\n' "$wr_line" | grep -oE 'witnessed [0-9]+/[0-9]+' | head -1)
    got=$(printf '%s\n' "$wn" | sed -E 's#witnessed ([0-9]+)/([0-9]+)#\1#')
    total=$(printf '%s\n' "$wn" | sed -E 's#witnessed ([0-9]+)/([0-9]+)#\2#')
    # N-2: the edited leaf (its own Parsed edge legitimately moved) and
    # `main.av` (the entry) are the only files this fixture's shape
    # ever costs a witness — six unrelated files and the prelude must
    # all still answer `Reused`.
    want=$((total - 2))
    [ "$got" -ge "$want" ] || { fails=$((fails+1)); echo "FAIL  a leaf edit did not reuse every unrelated file's witness: $wn (wanted >= $want)"; }
fi
# A COLLECT'S FRESH BODY REFERENCES A HELD MEMBER'S CLOSURE AS AN EXTERN,
# NEVER AS A GAP: `members.av` declares two exported named
# instances of `widget` (a component whose one field is `run: fn(int) ->
# int`, the same shape `rule`'s `run: fn(Code) -> Fix?` is) — each an
# `is_instance` const. `table.av`'s `collect` reads `it.run` for each,
# calling it by its `instance_unit` symbol. Editing `table.av` ALONE forces
# the collect fresh while `widget.av`/`members.av` stay held; without a
# declaration for a held member's symbol the link traps "nothing declares
# ... — the program is not closed" (witnessed: packages/std-avrac/src/
# compiler/interface.av's `Workspace.stub_of`/`instance_stub`, reused by
# `held_stubs`, is what a held FN's own symbol already goes through — the
# fix is keeping a gathered member's structural refusal the same way).
mkdir -p $R/cl/src
printf '[package]\nname = "rt-cl"\nversion = "0.1.0"\n' > $R/cl/avra.toml
cat > $R/cl/src/widget.av <<'AV'
export component widget {
    run: fn(int) -> int
}
AV
cat > $R/cl/src/members.av <<'AV'
use widget.{widget}

export widget one { n -> n + 1 }
export widget two { n -> n + 2 }
AV
cat > $R/cl/src/table.av <<'AV'
use widget.{widget}
type Entry = { name: string, ran: fn(int) -> int }
export collect entries: List<Entry> = widget in closure as Entry { name: it.name, ran: it.run } by it.name
AV
cat > $R/cl/src/main.av <<'AV'
use table.{entries}
println("cl ${entries.length} ${entries[0].name}=${entries[0].ran(10)} ${entries[1].name}=${entries[1].ran(10)}")
AV
S "cold cl: a fresh collect reads two members' closures" cl
S "no-op cl" cl
ed $R/cl/src/table.av 'type Entry = { name: string, ran: fn(int) -> int }' 'type Entry = { name: string, ran: fn(int) -> int }
// moved'
S "cl: table.av alone moves — widget.av/members.av stay held, the fresh collect body must reference their closures as externs" cl
got_cl1=$($R/cl/src/main 2>&1)
[ "$got_cl1" = "cl 2 one=11 two=12" ] || { fails=$((fails+1)); echo "FAIL  cl (collect fresh, members held) printed '$got_cl1', wanted 'cl 2 one=11 two=12'"; }
# A MEMBER'S OWN BODY EDIT, while the collect's own file stays held, is NOT
# pinned here: on a brand-new tiny package it trips a pre-existing, GENERAL
# held-collect/held-instance gap (a stale interface read that the "hold was
# refused, rebuilt from sources" safety net catches and self-heals — right
# answer, wasted work — reproduced with a plain DATA-only component too, no
# `run: fn`/structural-refusal involved, so it is not this ticket's exclusion
# and not touched here). The REAL requirement this scenario stands for —
# editing a rule's actual match logic and rebuilding the compiler warm
# re-derives that rule's finding, cleanly, no refusal — was witnessed
# directly against compiler/features/enums/idioms.av's `bool_variant_match`
# itself, not against a synthetic fixture here.

# A HELD RECORD'S SEAT-WRITTEN BIT (interface.av's `record_line`):
# `relay`'s `mut` seat is written only through a FLOW EDGE —
# `maybe_bump`'s own body — and a warm build over the edit must answer
# the write, with `pair[1]`, `pair[0]`'s alias, left unwritten. This
# asserts the warm answer only: the receivers fixpoint settles before
# any record is written, so a record reading its table mid-computation
# cannot be built here, and `record_line` reads the recorded door so it
# stays right the day that ordering moves.
printf 'export fn maybe_bump(mut xs: List<int>) {}\nexport fn relay(mut xs: List<int>) -> int {\n    maybe_bump(xs)\n    xs[0]\n}\n' > $R/lib/src/writeflow.av
mkdir -p $R/w/src
printf '[package]\nname = "rt-w"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/lib" = { path = "../lib" }\n' > $R/w/avra.toml
cat > $R/w/src/main.av <<'AV'
use @rt.lib.{relay}
mut base = [5]
mut pair = [base, base]
let r = relay(pair[0])
println("w ${pair[1][0]} ${r}")
AV
S "cold w: relay's seat is not written yet — no copy owed, both read 5" w
ed $R/lib/src/writeflow.av 'export fn maybe_bump(mut xs: List<int>) {}' 'export fn maybe_bump(mut xs: List<int>) { xs.set(0, xs[0] + 1) }'
S "maybe_bump now writes; relay's flow edge carries it into lib's held record, and the aliased path opens unique" w
got_w=$($R/w/src/main 2>&1)
[ "$got_w" = "w 5 6" ] || { fails=$((fails+1)); echo "FAIL  w (relay's inferred write, read back from lib's held record) printed '$got_w', wanted 'w 5 6' — pair[1] must stay unaliased"; }

# `Decls.decl(d)` fetches its row through the pinned row storage, never
# the relation's own recorded `get` — so it must still call `rows_read(x.file)`, the SAME
# file-grain edge the hand table's read always fed the kernel. `drm`'s
# held const `M` reads `drl`'s `seed` — a Const it runs — through a
# fresh query frame every settle; editing `seed`'s body alone, warm,
# must still move `M`. A lost edge would leave `drm` reusing the value
# it settled before the edit.
mkdir -p $R/drl/src $R/drm/src
printf '[package]\nname = "@rt/drl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-drl"\npath = "src/lib.av"\n' > $R/drl/avra.toml
printf 'export fn seed() -> int { 21 }\n' > $R/drl/src/seed.av
printf 'export const M: int = seed()\n' > $R/drl/src/lib.av
printf '[package]\nname = "rt-drm"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/drl" = { path = "../drl" }\n' > $R/drm/avra.toml
printf 'use @rt.drl.{M}\nprintln("drm ${M}")\n' > $R/drm/src/main.av
S "cold drm: a held const reads its callee's Decl row through the pinned handle" drm
got_drm1=$($R/drm/src/main 2>&1)
[ "$got_drm1" = "drm 21" ] || { fails=$((fails+1)); echo "FAIL  cold drm printed '$got_drm1', wanted 'drm 21'"; }
ed $R/drl/src/seed.av "{ 21 }" "{ 22 }"
S "drm: the callee's body moves — decl()'s file edge must still force a fresh frame" drm
got_drm2=$($R/drm/src/main 2>&1)
[ "$got_drm2" = "drm 22" ] || { fails=$((fails+1)); echo "FAIL  warm drm printed '$got_drm2', wanted 'drm 22' — decl()'s pinned-handle read lost the file-grain edge"; }

echo "cache-attacks: $steps builds through one store, $holds under a hold, $fails failed"
# A RUN THAT NEVER HELD ATTACKED NOTHING: every step above is green on the no-hold path.
[ "$holds" -gt 0 ] || { echo "cache-attacks: no step ran under a hold — the attacks examined nothing"; exit 1; }
[ "$fails" -eq 0 ]

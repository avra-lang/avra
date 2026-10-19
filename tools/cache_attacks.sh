#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/.."
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

if section kr; then
# A CONST THAT STANDS ON ANOTHER CONST FOLLOWS IT. `kr`'s K reads J in another module,
# and J settles by running a body in a third. A build that finds K's verdict kept does
# not run it again, and K's file's record lists the files its run read all the same,
# exactly as the cold check listed them. From there the body is edited: J moves, and
# K's file is read in the first attempt, none thrown away, in a check and in the binary.
mkdir -p $R/kr/src/f $R/kr/src/x $R/kr/src/y
printf '[package]\nname = "rt-kr"\nversion = "0.1.0"\n' > $R/kr/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\n' > $R/kr/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/kr/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\nfn scaled(const n: int, factor: int) -> int { n * factor }\nexport fn seated() -> int { scaled(J, 10) }\n' > $R/kr/src/f/held.av
printf 'use f.{shown, seated}\nprintln("${shown()} ${seated()}")\n' > $R/kr/src/main.av
# THE READ SET IS THE KEPT VERDICT'S OWN: the build below keeps K, the body its run
# entered then moves, and held.av must be read in the FIRST attempt with the value
# following. A verdict that had dropped its reads would stand, and the binary would
# print the body that ran before. The record's read set moved into the packed store,
# so the claim is held where the tool states it rather than in a row file.
HR "cold kr" check kr 0
S "kr: built with K's verdict kept" kr
printf '// moved\n' >> $R/kr/src/main.av
S "kr: an edit elsewhere, held.av held" kr
ed $R/kr/src/y/calc.av "n * 2" "n * 3"
steps=$((steps+1)); kr_out=$(./avra check --time $R/kr 2>&1)
case "$kr_out" in *"discarded 0, refused 0"*"f/held.av"*|*"f/held.av"*"discarded 0, refused 0"*) [ -n "${VERBOSE:-}" ] && echo "ok    kr: the body J ran moved -> held.av read in the first attempt" ;; *) fails=$((fails+1)); echo "FAIL  kr: the body J ran moved, and held.av was not read in the first attempt: $(printf '%s' "$kr_out" | grep -E '^time:|discarded:|held.av' | cut -c1-260 | tr '\n' ' ')" ;; esac
S "kr: and the binary follows" kr
steps=$((steps+1)); kr_out=$($R/kr/src/main 2>&1)
[ "$kr_out" = "18 90" ] || { fails=$((fails+1)); echo "FAIL  kr: K or the seat it feeds kept the value of the body J ran before: printed '$kr_out', wanted '18 90'"; }
fi
if section kq; then
# A CONST'S VALUE IS READ BY NAME. `kq`'s V reads B in another module and a plain fn
# inlines C at lowering, while A is read by nobody. Moving A's value must leave every
# kept verdict but A's own standing; moving B must rerun exactly its own and V's;
# moving C must rerun only its own but re-lower the fn that inlined it, so the binary
# follows. Verdicts are counted by what the query kernel says it ran.
mkdir -p $R/kq/src/f $R/kq/src/x
printf '[package]\nname = "rt-kq"\nversion = "0.1.0"\n' > $R/kq/avra.toml
printf 'export const A: int = 1\nexport const B: int = 2\nexport const C: int = 3\n' > $R/kq/src/x/vals.av
printf 'use x.{B, C}\nexport const V: int = B * 10\nexport fn shows() -> int { C }\n' > $R/kq/src/f/readers.av
printf 'use f.{V, shows}\nprintln("${V} ${shows()}")\n' > $R/kq/src/main.av
kq_ran() { # kq_ran <label> <want>: the verdicts the next check ran, counted
    steps=$((steps+1)); n=$(AVRA_QTRACE=1 ./avra check $R/kq 2>&1 | grep -c 'const_verdict.*ran')
    if [ "$n" -eq "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    kq: $1 -> $n verdicts ran"; else fails=$((fails+1)); echo "FAIL  kq: $1 ran $n verdicts, wanted $2"; fi
}
kq_prints() { # kq_prints <label> <want>: the native binary's line
    steps=$((steps+1)); out=$(./avra build $R/kq 2>/dev/null); bin=$(printf '%s\n' "$out" | tail -1); got=$("$bin" 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  kq: $1 printed '$got', wanted '$2'"; }
}
HR "cold kq" check kq 0
S "kq: built with every verdict kept" kq
kq_prints "cold" "20 3"
printf '// moved\n' >> $R/kq/src/main.av
kq_ran "an edit elsewhere" 0
ed $R/kq/src/x/vals.av "A: int = 1" "A: int = 9"
kq_ran "an unread const's value moved" 1
kq_prints "after A" "20 3"
ed $R/kq/src/x/vals.av "C: int = 3" "C: int = 4"
kq_ran "a const only a fn body inlines moved" 1
kq_prints "after C: the inlining fn follows" "20 4"
ed $R/kq/src/x/vals.av "B: int = 2" "B: int = 5"
kq_ran "a const a verdict read moved" 2
kq_prints "after B: V follows" "50 4"
fi
if section kv; then
# A KEPT VERDICT CARRIES THE READS OF THE RUN THAT MADE IT. `kv`'s L stands on K, K on
# J, and J settles by running a body in a fourth file; E beside them reads nothing.
# A build that finds every verdict kept runs none of them — and each file's record
# must list what its runs read exactly as the cold check listed it, three consts deep
# and for the one that read nothing. Then the body moves: every file on the chain is
# read in the FIRST attempt, none thrown away, and the values follow.
mkdir -p $R/kv/src/f $R/kv/src/g $R/kv/src/x $R/kv/src/y $R/kv/src/e
printf '[package]\nname = "rt-kv"\nversion = "0.1.0"\n' > $R/kv/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\n' > $R/kv/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/kv/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/kv/src/f/held.av
printf 'use f.{K}\nexport const L: int = K + 1\nexport fn topped() -> int { L }\n' > $R/kv/src/g/top.av
printf 'export const E: int = 5\nexport fn alone() -> int { E }\n' > $R/kv/src/e/alone.av
printf 'use f.{shown}\nuse g.{topped}\nuse e.{alone}\nprintln("${shown()} ${topped()} ${alone()}")\n' > $R/kv/src/main.av
# The chain's record read sets ride the packed store; the same claim is held where the
# tool states it — every file on the chain read in the FIRST attempt after the body
# moves, and the binary following. `alone.av`'s "records nothing" has no shell projection
# of its own any more.
HR "cold kv" check kv 0
S "kv: built with every verdict kept" kv
printf '// moved\n' >> $R/kv/src/main.av
S "kv: an edit elsewhere, the chain held" kv
ed $R/kv/src/y/calc.av "n * 2" "n * 3"
steps=$((steps+1)); kv_out=$(./avra check --time $R/kv 2>&1)
case "$kv_out" in *"discarded 0, refused 0"*) ;; *) fails=$((fails+1)); echo "FAIL  kv: the body moved and an attempt was thrown away before the chain was read: $(printf '%s' "$kv_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$kv_out" in *"f/held.av"*"g/top.av"*|*"g/top.av"*"f/held.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    kv: the body moved -> held.av and top.av read at once" ;; *) fails=$((fails+1)); echo "FAIL  kv: the body moved and the chain was not read: $(printf '%s' "$kv_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "kv: and the binary follows" kv
steps=$((steps+1)); kv_out=$($R/kv/src/main 2>&1)
[ "$kv_out" = "18 19 5" ] || { fails=$((fails+1)); echo "FAIL  kv: a const on the chain kept the value of the body J ran before: printed '$kv_out', wanted '18 19 5'"; }

fi

if section tw; then
# TWO EDITS, ONE READ FILE. A run reads a DECLARATION of a file, never the file: editing a
# body ELSEWHERE in that file leaves its readers held, while editing the declaration the run
# read reads them in the FIRST attempt, none thrown away.
mkdir -p $R/tw/src/f $R/tw/src/x $R/tw/src/y
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/tw/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/tw/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/tw/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/tw/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/tw/src/main.av
HR "cold tw" check tw 0
S "tw: built with K's verdict kept" tw
ed $R/tw/src/y/calc.av "n + 1" "n + 7"
steps=$((steps+1)); tw_out=$(./avra check --time $R/tw 2>&1)
case "$tw_out" in *"discarded 0, refused 0"*|*"cache hit"*) ;; *) fails=$((fails+1)); echo "FAIL  tw: an unreached body moved and an attempt was thrown away: $(printf '%s' "$tw_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$tw_out" in *"f/held.av"*) fails=$((fails+1)); echo "FAIL  tw: an unreached body moved and its reader was read all the same: $(printf '%s' "$tw_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    tw: an unreached body moved -> the reader held" ;; esac
ed $R/tw/src/y/calc.av "n * 2" "n * 3"
steps=$((steps+1)); tw_out=$(./avra check --time $R/tw 2>&1)
case "$tw_out" in *"discarded 0, refused 0"*) ;; *) fails=$((fails+1)); echo "FAIL  tw: the read declaration moved and an attempt was thrown away: $(printf '%s' "$tw_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$tw_out" in *"f/held.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    tw: the read declaration moved -> the reader read in the first attempt" ;; *) fails=$((fails+1)); echo "FAIL  tw: the read declaration moved and the reader was not read: $(printf '%s' "$tw_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "tw: and the binary follows" tw
steps=$((steps+1)); tw_out=$($R/tw/src/main 2>&1)
[ "$tw_out" = "18" ] || { fails=$((fails+1)); echo "FAIL  tw: the published value did not follow the declaration the run read: printed '$tw_out', wanted '18'"; }

fi

if section lm; then
# A RUN'S READ OF A LIFTED LAMBDA OR A FN TAKEN AS A VALUE RIDES ITS DECLARATION. `lm`'s J
# runs a fn that maps a lambda and one that maps a named fn (a wrapper), both in calc.av.
# Editing a fn of calc.av that J never reaches leaves mid.av held and no attempt thrown
# away; editing the fn the lambda sits in reads mid.av in the first attempt.
mkdir -p $R/lm/src/f $R/lm/src/x $R/lm/src/y
printf '[package]\nname = "rt-lm"\nversion = "0.1.0"\n' > $R/lm/avra.toml
printf 'export fn dbl(n: int) -> int { n * 2 }\nexport fn via_lambda(n: int) -> int { [n].map((x) -> x + 1).first() ?? 0 }\nexport fn via_fn(n: int) -> int { [n].map(dbl).first() ?? 0 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/lm/src/y/calc.av
printf 'use y.{via_lambda, via_fn}\nexport const J: int = via_lambda(3) + via_fn(4)\n' > $R/lm/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/lm/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/lm/src/main.av
HR "cold lm" check lm 0
S "lm: built with J's verdict kept" lm
ed $R/lm/src/y/calc.av "n + 1 }
" "n + 7 }
"
steps=$((steps+1)); lm_out=$(./avra check --time $R/lm 2>&1)
case "$lm_out" in *"discarded 0, refused 0"*|*"cache hit"*) ;; *) fails=$((fails+1)); echo "FAIL  lm: an unreached fn moved and an attempt was thrown away: $(printf '%s' "$lm_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$lm_out" in *"x/mid.av"*|*"f/held.av"*) fails=$((fails+1)); echo "FAIL  lm: an unreached fn moved and a reader of a lambda or a wrapper in its file was read all the same: $(printf '%s' "$lm_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    lm: an unreached fn moved -> the readers held" ;; esac
ed $R/lm/src/y/calc.av "x + 1" "x + 2"
steps=$((steps+1)); lm_out=$(./avra check --time $R/lm 2>&1)
case "$lm_out" in *"x/mid.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    lm: the lambda's fn moved -> the reader read" ;; *) fails=$((fails+1)); echo "FAIL  lm: the fn holding the lambda moved and its reader was not read: $(printf '%s' "$lm_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "lm: and the binary follows" lm
steps=$((steps+1)); lm_out=$($R/lm/src/main 2>&1)
[ "$lm_out" = "26" ] || { fails=$((fails+1)); echo "FAIL  lm: the published value did not follow the lambda: printed '$lm_out', wanted '26'"; }

fi

if section pk; then
# A READER WHOSE KEY MOVED IS READ BEFORE THE ATTEMPT STARTS, though one of its reads is
# still pending. `pk`'s mid.av runs a fn of calc.av (a declaration read, pending while
# calc.av's text has moved) and embeds a file (a read of the file's whole text). Both move at
# once: the declaration stands and the embedded text does not, so nothing kept stands in for
# mid.av under its new key. Held for a pending read, it would be found without rule findings
# only after the attempt ran, and the attempt thrown away.
mkdir -p $R/pk/src/f $R/pk/src/x $R/pk/src/y
printf '[package]\nname = "rt-pk"\nversion = "0.1.0"\n' > $R/pk/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/pk/src/y/calc.av
printf 'one' > $R/pk/src/x/data.txt
printf 'use @std.meta.{embed}\nuse y.{twice}\nexport const J: int = twice(3)\nexport const TEXT: string = embed("data.txt")\n' > $R/pk/src/x/mid.av
printf 'use x.{J, TEXT}\nexport fn shown() -> string { "${TEXT} ${J}" }\n' > $R/pk/src/f/held.av
printf 'use f.{shown}\nprintln(shown())\n' > $R/pk/src/main.av
HR "cold pk" check pk 0
S "pk: built with J's verdict kept" pk
ed $R/pk/src/y/calc.av "n + 1" "n + 7"
printf 'two' > $R/pk/src/x/data.txt
steps=$((steps+1)); pk_out=$(./avra check --time $R/pk 2>&1)
case "$pk_out" in *"none were kept"*) fails=$((fails+1)); echo "FAIL  pk: a reader's key moved under a pending read and it was held until its rule findings were found missing: $(printf '%s' "$pk_out" | grep -E 'discarded:' | cut -c1-260 | tr '\n' ' ')" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    pk: the key moved -> the reader read, never held for its findings" ;; esac
case "$pk_out" in *"x/mid.av"*) ;; *) fails=$((fails+1)); echo "FAIL  pk: the embedded text moved and the reader was not read: $(printf '%s' "$pk_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "pk: and the binary follows" pk
steps=$((steps+1)); pk_out=$($R/pk/src/main 2>&1)
[ "$pk_out" = "two 6" ] || { fails=$((fails+1)); echo "FAIL  pk: the published value did not follow the embedded text: printed '$pk_out', wanted 'two 6'"; }

fi

if section rp; then
# A PENDING READ IS JUDGED BY PARSING THE READ FILE ALONE. `rp`'s mid.av runs a fn of calc.av,
# and calc.av sees base.av. Editing a fn of calc.av that mid.av never reaches leaves calc.av
# to be read while mid.av waits on whether its declaration stands; judging that must not ask
# calc.av's resolution, which asks the items of every file it sees — parsing base.av and
# mid.av, held files the holds have not yet settled.
mkdir -p $R/rp/src/f $R/rp/src/x $R/rp/src/y $R/rp/src/w
printf '[package]\nname = "rt-rp"\nversion = "0.1.0"\n' > $R/rp/avra.toml
printf 'use w.{base}\nexport fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + base() }\n' > $R/rp/src/y/calc.av
printf 'export fn base() -> int { 10 }\n' > $R/rp/src/w/base.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/rp/src/x/mid.av
printf 'use x.{J}\nexport fn shown() -> int { J }\n' > $R/rp/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/rp/src/main.av
HR "cold rp" check rp 0
S "rp: built with J's verdict kept" rp
ed $R/rp/src/y/calc.av "n + base()" "n + base() + 1"
steps=$((steps+1)); rp_parsed=$(AVRA_QTRACE=1 ./avra check $R/rp 2>&1 >/dev/null | awk -F'\t' '$1 == "Q" && $2 == "parse" { print $3 }')
case "$rp_parsed" in *"y/calc.av"*) ;; *) fails=$((fails+1)); echo "FAIL  rp: the edited file was not parsed, so the trace read nothing: '$rp_parsed'" ;; esac
case "$rp_parsed" in *"w/base.av"*|*"x/mid.av"*|*"f/held.av"*) fails=$((fails+1)); echo "FAIL  rp: a held file was parsed to judge a pending read: $(printf '%s' "$rp_parsed" | tr '\n' ' ' | cut -c1-260)" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    rp: the read file alone was parsed" ;; esac
S "rp: and the binary follows" rp
steps=$((steps+1)); rp_out=$($R/rp/src/main 2>&1)
[ "$rp_out" = "6" ] || { fails=$((fails+1)); echo "FAIL  rp: the published value drifted: printed '$rp_out', wanted '6'"; }

fi

if section ur; then
# A LOWERED UNIT IS KEPT BY DECLARATION. After one derivation has kept its rows, a body
# edit lowers that body alone; an edit to anything its file shows its bodies (a
# default argument, a const's value, a record's layout) lowers the file's bodies
# afresh. Every step builds the binary and holds its output to the value the edit
# asked for, so a unit served from a row that no longer stands is a wrong number here.
mkdir -p $R/ur/src/y $R/ur/src/z
printf '[package]\nname = "rt-ur"\nversion = "0.1.0"\n' > $R/ur/avra.toml
printf 'export const BASE: int = 10\nexport type Pt = { x: int, y: int }\nexport fn alpha(n: int) -> int { n + 1 }\nexport fn beta(n: int) -> int { alpha(n) * 2 }\nexport fn gamma(n: int) -> int { n - 1 }\nexport fn delta() -> int { BASE + 5 }\nexport fn mk() -> Pt { Pt { x: 1, y: 2 } }\nexport fn epsilon(p: Pt) -> int { p.x + p.y }\n' > $R/ur/src/y/calc.av
printf 'use y.{gamma}\nexport fn zeta() -> int { gamma(3) }\n' > $R/ur/src/z/user.av
printf 'use y.{beta, gamma, delta, epsilon, mk}\nuse z.{zeta}\nprintln("${beta(1)} ${gamma(5)} ${delta()} ${epsilon(mk())} ${zeta()}")\n' > $R/ur/src/main.av
ur_lowered() { AVRA_QTRACE=1 ./avra check $R/ur 2>&1 | grep -a "unit.lowered" | awk -F'\t' '{print $4}' | tr '\n' ' '; } # the units a check lowered afresh
ur_expect() { # ur_expect <label> <words that must be lowered> -- <words that must not>
    steps=$((steps+1)); label=$1; shift; got=$(ur_lowered); side=have
    for w in "$@"; do
        if [ "$w" = "--" ]; then side=lack; continue; fi
        case " $got" in *" y.$w "*) seen=yes ;; *) seen=no ;; esac
        if [ "$side" = have ] && [ "$seen" = no ]; then fails=$((fails+1)); echo "FAIL  ur: $label: $w was not lowered afresh: $got"; fi
        if [ "$side" = lack ] && [ "$seen" = yes ]; then fails=$((fails+1)); echo "FAIL  ur: $label: $w was lowered afresh though nothing it shows moved: $got"; fi
    done
}
ur_prints() { # ur_prints <label> <value>
    steps=$((steps+1)); S "ur: $1" ur; ur_out=$($R/ur/src/main 2>&1)
    [ "$ur_out" = "$2" ] || { fails=$((fails+1)); echo "FAIL  ur: $1: printed '$ur_out', wanted '$2'"; }
}
HR "cold ur" check ur 0
ur_prints "built cold" "4 4 15 3 2"
ed $R/ur/src/y/calc.av "BASE + 5" "BASE + 6"
HR "ur: first edit, rows made" check ur 0
ur_prints "a body edit" "4 4 16 3 2"
ed $R/ur/src/y/calc.av "n - 1" "n - 2"
ur_expect "a body edit lowers that body alone" gamma -- alpha beta delta mk epsilon
ur_prints "and the binary follows" "4 3 16 3 1"
ed $R/ur/src/y/calc.av "fn alpha(n: int) -> int" "fn alpha(n: int, k: int = 1) -> int"
ur_expect "a default argument moves what the file shows" alpha beta gamma delta epsilon
ur_prints "a default argument" "4 3 16 3 1"
ed $R/ur/src/y/calc.av "n - 2" "n - 3"
ur_expect "a body edit after a surface edit lowers that body alone" gamma -- alpha beta delta mk epsilon
ed $R/ur/src/y/calc.av "const BASE: int = 10" "const BASE: int = 11"
ur_expect "a const's value moves what the file shows" delta alpha beta gamma epsilon
ur_prints "a const's value" "4 2 17 3 0"
ed $R/ur/src/y/calc.av "x: int, y: int }" "y: int, x: int }"
ur_expect "a record's layout moves what the file shows" epsilon mk
ur_prints "a record's layout" "4 2 17 3 0"
ed $R/ur/src/y/calc.av "p.x + p.y" "p.x * 10 + p.y"
ur_expect "a body edit lowers that body alone, again" epsilon -- alpha beta gamma delta mk
ur_prints "and the last edit" "4 2 17 12 0"

fi

if section rb; then
# A READER INHERITS THE RUNS BEHIND WHAT IT READ, NOT BEHIND THE FILE. lib.av's const C runs
# zbase from data.av. fnread.av runs only a FN of lib.av, constread.av runs the CONST C.
# data.av is rewritten to the same answer: fnread.av stays held, since nothing it ran reads
# data.av. Then the answer moves: constread.av is read and the values follow.
mkdir -p $R/rb/src/z $R/rb/src/x $R/rb/src/r
printf '[package]\nname = "rt-rb"\nversion = "0.1.0"\n' > $R/rb/avra.toml
printf 'export fn zbase() -> int { 5 }\n' > $R/rb/src/z/data.av
printf 'use z.{zbase}\nexport fn plain(n: int) -> int { n * 2 }\nexport const C: int = zbase()\n' > $R/rb/src/x/lib.av
printf 'use x.{plain}\nexport const J: int = plain(3)\nexport fn shown() -> int { J }\n' > $R/rb/src/r/fnread.av
printf 'use x.{C}\nexport const K: int = C + 1\nexport fn topped() -> int { K }\n' > $R/rb/src/r/constread.av
printf 'use r.{shown, topped}\nprintln("${shown()} ${topped()}")\n' > $R/rb/src/main.av
HR "cold rb" check rb 0
S "rb: built with every verdict kept" rb
ed $R/rb/src/z/data.av "{ 5 }" "{ 2 + 3 }"
steps=$((steps+1)); rb_out=$(./avra check --time $R/rb 2>&1)
case "$rb_out" in *"r/fnread.av"*) fails=$((fails+1)); echo "FAIL  rb: a file only a const of a fn's file runs was rewritten to the same answer and a reader of the fn was read: $(printf '%s' "$rb_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    rb: a fn's reader held while a const's run file moved" ;; esac
ed $R/rb/src/z/data.av "2 + 3" "2 + 5"
steps=$((steps+1)); rb_out=$(./avra check --time $R/rb 2>&1)
case "$rb_out" in *"r/constread.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    rb: the file a const's run read moved -> its reader read" ;; *) fails=$((fails+1)); echo "FAIL  rb: the file a const's run read moved and its reader was not read: $(printf '%s' "$rb_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "rb: and the binary follows" rb
steps=$((steps+1)); rb_out=$($R/rb/src/main 2>&1)
[ "$rb_out" = "6 8" ] || { fails=$((fails+1)); echo "FAIL  rb: the published values did not follow: printed '$rb_out', wanted '6 8'"; }

fi

if section hc; then
# A PLAIN UNIT'S ROW KEEPS THE CONSTS IT READ. fn.av reads a const of another module; the const is
# edited beside an edit that reads fn.av again, and the unit is lowered afresh rather than served from
# a row that baked the old value. (A cold derivation keeps no rows: the first warm one does.)
mkdir -p $R/hc/src/ga $R/hc/src/gb
printf '[package]\nname = "rt-hc"\nversion = "0.1.0"\n' > $R/hc/avra.toml
printf 'export const K: int = 7\nexport fn quiet() -> int { 1 }\n' > $R/hc/src/gb/k.av
printf 'use gb.{K, quiet}\nexport fn reads_k() -> int { K + 1 }\nexport fn plain() -> int { quiet() + 2 }\n' > $R/hc/src/ga/fn.av
printf 'use ga.{reads_k, plain}\nprintln("${reads_k()} ${plain()}")\n' > $R/hc/src/main.av
hc_run() { AVRA_QTRACE=1 ./avra check $R/hc 2>&1 >/dev/null | awk -F'\t' '$1 == "Q" && $2 == "unit" && $3 == "lowered" { print $4 }' | sort -u > $R/hc.lowered; }
hc_count() { grep -c "$1" $R/hc.lowered | tr -d ' '; }
HR "cold hc" check hc 0
ed $R/hc/src/ga/fn.av "K + 1" "K + 2"; hc_run
ed $R/hc/src/ga/fn.av "K + 2" "K + 3"; hc_run
steps=$((steps+1)); [ "$(hc_count reads_k)" = 1 ] && [ "$(hc_count plain)" = 0 ] || { fails=$((fails+1)); echo "FAIL  hc: after editing reads_k's own body, lowered afresh reads_k=$(hc_count reads_k) plain=$(hc_count plain), wanted 1/0"; }
ed $R/hc/src/gb/k.av "K: int = 7" "K: int = 8"
ed $R/hc/src/ga/fn.av "quiet() + 2" "quiet() + 3"; hc_run
steps=$((steps+1)); [ "$(hc_count reads_k)" = 1 ] || { fails=$((fails+1)); echo "FAIL  hc: a const a plain fn reads moved and the fn's unit was served from a row that baked the old value (lowered afresh: $(hc_count reads_k))"; }

fi

if section gi; then
# A SPECIALIZATION'S READ NAMES THE GENERIC IT WAS MADE FROM. A const's run that reaches
# `first<int>` reads the declaration of `first`, never the file that holds it: editing a
# body ELSEWHERE in that file leaves the run's reader held, while editing `first` reads
# the reader in the FIRST attempt, none thrown away, and the value follows.
mkdir -p $R/gi/src/f $R/gi/src/x $R/gi/src/y
printf '[package]\nname = "rt-gi"\nversion = "0.1.0"\n' > $R/gi/avra.toml
printf 'export fn first<T>(a: T, b: T) -> T { a }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/gi/src/y/calc.av
printf 'use y.{first}\nexport const J: int = first(3, 4)\n' > $R/gi/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/gi/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/gi/src/main.av
HR "cold gi" check gi 0
S "gi: built with K's verdict kept" gi
ed $R/gi/src/y/calc.av "n + 1" "n + 7"
steps=$((steps+1)); gi_out=$(./avra check --time $R/gi 2>&1)
case "$gi_out" in *"discarded 0, refused 0"*|*"cache hit"*) ;; *) fails=$((fails+1)); echo "FAIL  gi: an unreached body moved and an attempt was thrown away: $(printf '%s' "$gi_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$gi_out" in *"f/held.av"*|*"x/mid.av"*) fails=$((fails+1)); echo "FAIL  gi: a body the specialization never reads moved and its reader was read all the same: $(printf '%s' "$gi_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; *) [ -n "${VERBOSE:-}" ] && echo "ok    gi: an unreached body moved -> the readers held" ;; esac
ed $R/gi/src/y/calc.av "{ a }" "{ b }"
steps=$((steps+1)); gi_out=$(./avra check --time $R/gi 2>&1)
case "$gi_out" in *"discarded 0, refused 0"*) ;; *) fails=$((fails+1)); echo "FAIL  gi: the generic moved and an attempt was thrown away: $(printf '%s' "$gi_out" | grep -E '^time:|discarded:' | cut -c1-260 | tr '\n' ' ')" ;; esac
case "$gi_out" in *"x/mid.av"*|*"f/held.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    gi: the generic moved -> the reader read in the first attempt" ;; *) fails=$((fails+1)); echo "FAIL  gi: the generic moved and no reader was read: $(printf '%s' "$gi_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-260)" ;; esac
S "gi: and the binary follows" gi
steps=$((steps+1)); gi_out=$($R/gi/src/main 2>&1)
[ "$gi_out" = "8" ] || { fails=$((fails+1)); echo "FAIL  gi: the published value did not follow the generic: printed '$gi_out', wanted '8'"; }

fi

if section sl; then
# A SEAL A HELD DECLARATION KEEPS STANDS. `Cnt` is sealed boxed by `own/s.av` (a `mut` seat and
# a writing method), which stays held while `rec/r.av`, where `Cnt` is declared, is read: no
# attempt may give up the hold. Once the sealer is edited away and `Cnt` is read, nothing keeps
# it boxed, and only the sources whole can say what its layout is — the hold is given up.
mkdir -p $R/sl/src/rec $R/sl/src/own $R/sl/src/use
printf '[package]\nname = "rt-sl"\nversion = "0.1.0"\n' > $R/sl/avra.toml
printf 'export type Cnt = { n: int }\n' > $R/sl/src/rec/r.av
printf 'use rec.{Cnt}\nexport fn bump(mut c: Cnt) { c.n = c.n + 1 }\nimpl Cnt {\n    mut fn up() { self.n = self.n + 10 }\n}\n' > $R/sl/src/own/s.av
printf 'use rec.{Cnt}\nuse own.{bump}\nexport fn total() -> int {\n    mut c = Cnt { n: 1 }\n    bump(c)\n    c.up()\n    c.n\n}\n' > $R/sl/src/use/u.av
printf 'use use.{total}\nprintln("${total()}")\n' > $R/sl/src/main.av
sl_n=0
sl_touch() { sl_n=$((sl_n+1)); printf '// moved %s\n' "$sl_n" >> $R/sl/src/rec/r.av; }
sl_held() { AVRA_QTRACE=1 ./avra check $R/sl 2>&1 >/dev/null | awk -F'\t' '$1 == "Q" && $2 == "attempt" { split($4, w, " "); print w[2] }' | tr '\n' ' '; }
S "cold sl" sl
sl_touch; sl_got=$(sl_held)
steps=$((steps+1)); case "$sl_got" in *false*) fails=$((fails+1)); echo "FAIL  sl: reading the file a held seal's record is declared in gave up the hold (attempts: '$sl_got')" ;; "true "|"true true ") [ -n "${VERBOSE:-}" ] && echo "ok    sl: the declaring file read, the hold kept" ;; *) fails=$((fails+1)); echo "FAIL  sl: reading the file a held seal's record is declared in gave up the hold (attempts: '$sl_got')" ;; esac
S "sl: the declaring file read" sl
steps=$((steps+1)); [ "$($R/sl/src/main 2>&1)" = "12" ] || { fails=$((fails+1)); echo "FAIL  sl: bump and up lost a write through the held seal: '$($R/sl/src/main 2>&1)', wanted '12'"; }
printf 'use rec.{Cnt}\nexport fn bump(c: Cnt) -> int { c.n + 1 }\nexport fn up(c: Cnt) -> int { c.n + 10 }\n' > $R/sl/src/own/s.av
printf 'use rec.{Cnt}\nuse own.{bump, up}\nexport fn total() -> int {\n    let c = Cnt { n: 1 }\n    bump(c) + up(c)\n}\n' > $R/sl/src/use/u.av
sl_touch; sl_got=$(sl_held)
steps=$((steps+1)); case "$sl_got" in *"false"*) [ -n "${VERBOSE:-}" ] && echo "ok    sl: the sealer gone, the hold given up" ;; *) fails=$((fails+1)); echo "FAIL  sl: a record nothing seals any more stayed boxed under the hold (attempts: '$sl_got')" ;; esac
S "sl: the sealer edited away" sl
steps=$((steps+1)); [ "$($R/sl/src/main 2>&1)" = "13" ] || { fails=$((fails+1)); echo "FAIL  sl: after the seal left, the program printed '$($R/sl/src/main 2>&1)', wanted '13'"; }
# a NEW sealing site in a read file seals as it is typed, and the record it boxes follows; when
# that site goes and nothing held seals the record, the hold is given up again
printf 'use rec.{Cnt}\nuse own.{bump, up}\nfn grow(mut c: Cnt) { c.n = c.n + 5 }\nexport fn total() -> int {\n    mut c = Cnt { n: 1 }\n    grow(c)\n    bump(c) + up(c) + c.n\n}\n' > $R/sl/src/use/u.av
sl_touch
S "sl: a new sealing site in a read file" sl
steps=$((steps+1)); [ "$($R/sl/src/main 2>&1)" = "29" ] || { fails=$((fails+1)); echo "FAIL  sl: with a new seal the program printed '$($R/sl/src/main 2>&1)', wanted '29'"; }
printf 'use rec.{Cnt}\nuse own.{bump, up}\nexport fn total() -> int {\n    let c = Cnt { n: 1 }\n    bump(c) + up(c)\n}\n' > $R/sl/src/use/u.av
sl_touch; sl_got=$(sl_held)
steps=$((steps+1)); case "$sl_got" in *false*) [ -n "${VERBOSE:-}" ] && echo "ok    sl: the new site gone, the hold given up" ;; *) fails=$((fails+1)); echo "FAIL  sl: a record whose only sealer left a read file stayed boxed under the hold (attempts: '$sl_got')" ;; esac
S "sl: the new sealing site removed" sl
steps=$((steps+1)); [ "$($R/sl/src/main 2>&1)" = "13" ] || { fails=$((fails+1)); echo "FAIL  sl: after the site left, the program printed '$($R/sl/src/main 2>&1)', wanted '13'"; }
# the held sealer's FILE deleted: nothing held seals the record any more
printf 'use rec.{Cnt}\nexport fn bump(mut c: Cnt) { c.n = c.n + 1 }\nimpl Cnt {\n    mut fn up() { self.n = self.n + 10 }\n}\n' > $R/sl/src/own/s.av
printf 'use rec.{Cnt}\nuse own.{bump}\nexport fn total() -> int {\n    mut c = Cnt { n: 1 }\n    bump(c)\n    c.up()\n    c.n\n}\n' > $R/sl/src/use/u.av
sl_touch
S "sl: the sealer restored" sl
sl_touch; sl_got=$(sl_held)
steps=$((steps+1)); case "$sl_got" in *false*) fails=$((fails+1)); echo "FAIL  sl: the restored held seal gave up the hold (attempts: '$sl_got')" ;; esac
rm $R/sl/src/own/s.av
printf 'use rec.{Cnt}\nexport fn total() -> int {\n    let c = Cnt { n: 1 }\n    c.n + 12\n}\n' > $R/sl/src/use/u.av
sl_touch; sl_got=$(sl_held)
steps=$((steps+1)); case "$sl_got" in *false*) [ -n "${VERBOSE:-}" ] && echo "ok    sl: the sealing file deleted, the hold given up" ;; *) fails=$((fails+1)); echo "FAIL  sl: a record whose held sealer's file was deleted stayed boxed under the hold (attempts: '$sl_got')" ;; esac
S "sl: the sealing file deleted" sl
steps=$((steps+1)); [ "$($R/sl/src/main 2>&1)" = "13" ] || { fails=$((fails+1)); echo "FAIL  sl: after the file left, the program printed '$($R/sl/src/main 2>&1)', wanted '13'"; }

fi

if section bk; then
# THE PROGRAM'S OWN BODIES ARE COMPILED IN BUCKETS, each keyed by its bytes: a build that moves one
# generic's instantiations compiles the buckets they fall in and places the rest from the store, and
# the program still prints what the edited source says. `Q objects` names, per build, the objects
# owed and the program buckets among them (owed, linked, buckets owed, buckets linked).
mkdir -p $R/bk/src/g
printf '[package]\nname = "rt-bk"\nversion = "0.1.0"\n' > $R/bk/avra.toml
{ printf 'export fn gid<T>(x: T) -> T { x }\nexport fn gtwo<T>(a: T, b: T) -> List<T> { [a, b] }\n'
  for n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do printf 'export type R%s = { v%s: int }\nexport fn mk%s() -> R%s { R%s { v%s: %s } }\n' $n $n $n $n $n $n $n; done; } > $R/bk/src/g/gen.av
{ printf 'use g.{gid, gtwo'; for n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do printf ', mk%s' $n; done; printf '}\n'
  printf 'mut total = 0\n'
  for n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do printf 'total = total + gid(mk%s()).v%s + gtwo(mk%s(), mk%s()).length\n' $n $n $n $n; done
  printf 'println("${total}")\n'; } > $R/bk/src/main.av
bk_run() { AVRA_QTRACE=1 ./avra build --time $R/bk 2>$R/bk.q >/dev/null; }
bk_objects() { awk -F'\t' '$1 == "Q" && $2 == "objects" { print $3, $4, $5, $6 }' $R/bk.q | tail -1; }
bk_keys() { awk -F'\t' '$1 == "Q" && $2 == "bucket" { print $3, $4 }' $R/bk.q | sort -n; }
bk_changed() { awk 'NR == FNR { a[$1] = $2; next } a[$1] != $2 { print $1 }' $R/bk.prev - | sort -n | tr '\n' ' '; }
bk_placed() { awk -F'\t' -v pat="$1" '$1 == "Q" && $2 == "placed" && index($3, pat) { print $4 }' $R/bk.q | sort -un | tr '\n' ' '; }
S "cold bk" bk
# the baseline keys come from a build that lowers the whole program (a held build lists no keys)
rm -rf .avra-cache; bk_run; bk_keys > $R/bk.prev
set -- $(bk_objects); bk_linked=${4:-0}
steps=$((steps+1)); [ "${bk_linked:-0}" -gt 3 ] || { fails=$((fails+1)); echo "FAIL  bk: the program's bodies fell in $bk_linked bucket(s) only, so the fixture splits nothing"; }
# MOVING ONE GENERIC compiles the buckets ITS instantiations fall in, exactly: the expected set is read from where
# the build placed every gtwo instantiation, the observed one from which bucket keys moved.
ed $R/bk/src/g/gen.av "-> List<T> { [a, b] }" "-> List<T> { [a, b, a] }"
bk_run; want=$(bk_placed 'gtwo$'); got=$(bk_keys | bk_changed); set -- $(bk_objects)
steps=$((steps+1)); [ -n "$want" ] && [ "$got" = "$want" ] && [ "$3" = "$(printf '%s' "$want" | wc -w | tr -d ' ')" ] || { fails=$((fails+1)); echo "FAIL  bk: gtwo moved: buckets whose key moved '$got', its instantiations fall in '$want', compiled $3 (owed/linked/buckets/of '$*')"; }
bk_keys > $R/bk.prev
S "bk: and the program follows" bk
steps=$((steps+1)); bk_out=$($R/bk/src/main 2>&1)
[ "$bk_out" = "270" ] || { fails=$((fails+1)); echo "FAIL  bk: the program printed '$bk_out' after gtwo grew, wanted 270"; }
# ONE NEW INSTANTIATION DIRTIES ITS BUCKET AND NO OTHER: a bucket is a function of its own members' names, not of
# their order or number, so adding gid<R21> moves exactly the bucket the new body falls in.
printf 'export type R21 = { v21: int }\nexport fn mk21() -> R21 { R21 { v21: 21 } }\n' >> $R/bk/src/g/gen.av
ed $R/bk/src/main.av 'use g.{gid, gtwo' 'use g.{gid, gtwo, mk21'
printf 'println("${gid(mk21()).v21}")\n' >> $R/bk/src/main.av
bk_run; want=$(bk_placed 'R21'); got=$(bk_keys | bk_changed); set -- $(bk_objects)
steps=$((steps+1)); [ -n "$want" ] && [ "$got" = "$want" ] && [ "$3" = 1 ] || { fails=$((fails+1)); echo "FAIL  bk: one new instantiation: buckets whose key moved '$got', the new bodies fall in '$want', compiled $3 (owed/linked/buckets/of '$*')"; }
# TWO COLD BUILDS OF ONE TREE KEY EVERY BUCKET ALIKE: a bucket's bytes are a function of its source alone.
rm -rf .avra-cache; bk_run; bk_keys > $R/bk.k1; rm -rf .avra-cache; bk_run; bk_keys > $R/bk.k2
steps=$((steps+1)); [ -s $R/bk.k1 ] && cmp -s $R/bk.k1 $R/bk.k2 || { fails=$((fails+1)); echo "FAIL  bk: two cold builds of one tree keyed their buckets differently ($(wc -l < $R/bk.k1 | tr -d ' ') vs $(wc -l < $R/bk.k2 | tr -d ' ') buckets, first difference: $(diff $R/bk.k1 $R/bk.k2 | head -2 | tr '\n' ' '))"; }
fi

if section lk; then
# A KEPT BINARY IS REUSED ONLY WHILE WHAT LINKED IT STANDS: the C compiler that linked it (by its word
# `CC`), the runtime archive and the package objects it linked. A wrapper script stands for the C
# compiler, so its bytes can be changed and its word can be pointed elsewhere.
mkdir -p $R/lk/src
printf '[package]\nname = "rt-lk"\nversion = "0.1.0"\n' > $R/lk/avra.toml
printf 'println("lk")\n' > $R/lk/src/main.av
lk_cc=$(command -v clang)
printf '#!/bin/sh\nexec %s "$@"\n' "$lk_cc" > $R/cc1; chmod +x $R/cc1
printf '#!/bin/sh\nexec %s "$@"\n' "$lk_cc" > $R/cc2; chmod +x $R/cc2
LK() { # LK <label> <want: hit|built> -- the env is the caller's
    steps=$((steps+1)); out=$(./avra build --time $R/lk 2>&1); got=built
    case "$out" in *"cache hit"*) got=hit ;; esac
    if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [lk] -> $got"; else fails=$((fails+1)); echo "FAIL  $1 [lk] wanted $2, got $got"; fi
}
# a file written in the last two seconds has no stamp (two writes can wear one time), so a tool is aged first
sleep 3
export CC=$R/cc1
LK "cold lk" built; LK "nothing touched" hit
# A HIT LEAVES THE BINARY WHERE IT STANDS: the file keeps its inode (a replacement would not).
lk_bin=$R/lk/src/main; lk_i1=$(ls -i $lk_bin | awk '{print $1}'); LK "and again" hit; lk_i2=$(ls -i $lk_bin | awk '{print $1}')
steps=$((steps+1)); [ -n "$lk_i1" ] && [ "$lk_i1" = "$lk_i2" ] || { fails=$((fails+1)); echo "FAIL  lk: a cache hit replaced the binary it answered with (inode $lk_i1 -> $lk_i2)"; }
printf '# a new revision of the C compiler\n' >> $R/cc1; sleep 3
LK "the C compiler's bytes moved" built; LK "and again nothing touched" hit
export CC=$R/cc2
LK "CC names another C compiler" built; LK "and that one again" hit
unset CC
LK "CC back to the default word" built; LK "and nothing touched" hit
lk_rt=build/libavra_runtime.a
cp $lk_rt $R/lk.rt.kept
# a member added through `ar` moves the archive's bytes and leaves it a valid one: bytes appended
# raw make a malformed archive, which a strict linker (lld) refuses where GNU ld forgave it
printf 'int lk_pad;\n' > $R/lk_pad.c; $lk_cc -c $R/lk_pad.c -o $R/lk_pad.o; ar q $lk_rt $R/lk_pad.o 2>/dev/null
LK "the runtime archive moved" built
cp $R/lk.rt.kept $lk_rt
LK "and put back" built
mv $lk_rt $R/lk.rt.away
steps=$((steps+1)); out=$(./avra build --time $R/lk 2>&1)
mv $R/lk.rt.away $lk_rt
case "$out" in *"cache hit"*) fails=$((fails+1)); echo "FAIL  lk: the runtime archive was gone and the kept binary was served" ;; esac
LK "and back again" hit
fi

if section dp; then
# A KEPT VERDICT NEVER READS A FILE THAT IS GONE. held.av's const read z/add.av's body; the file is deleted and
# held.av no longer uses it. The next build is clean and says nothing of the deleted path, and so is the one after.
mkdir -p $R/dp/src/f $R/dp/src/z
printf '[package]\nname = "rt-dp"\nversion = "0.1.0"\n' > $R/dp/avra.toml
printf 'export fn plus(n: int) -> int { n + 1 }\n' > $R/dp/src/z/add.av
printf 'use z.{plus}\nexport const K: int = plus(1)\nexport fn shown() -> int { K }\n' > $R/dp/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/dp/src/main.av
S "cold dp" dp
rm $R/dp/src/z/add.av; rmdir $R/dp/src/z
printf 'export const K: int = 2\nexport fn shown() -> int { K }\n' > $R/dp/src/f/held.av
S "dp: the file a kept verdict read is deleted" dp
steps=$((steps+1)); [ "$($R/dp/src/main 2>&1)" = "2" ] || { fails=$((fails+1)); echo "FAIL  dp: the program printed '$($R/dp/src/main 2>&1)', wanted '2'"; }
printf '// moved\n' >> $R/dp/src/main.av
S "dp: and the build after it" dp

fi

if section gg; then
# A GUESS ONLY PRE-ADMITS. Editing held.av's const to need calc.av's body turns the attempt once (calc.av
# is held and a compile-time run asks for its body); the same edit again starts with calc.av read and
# stands on its first attempt. Whatever the guess holds — a file the next edit no longer needs — the
# answer is the one a store with no guess gives: the same exit, the same binary output.
mkdir -p $R/gg/src/f $R/gg/src/y
printf '[package]\nname = "rt-gg"\nversion = "0.1.0"\n' > $R/gg/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\n' > $R/gg/src/y/calc.av
printf 'use y.{twice}\nexport const K: int = twice(3)\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/gg/src/main.av
gg_attempts() { AVRA_QTRACE=1 ./avra check $R/gg 2>&1 >/dev/null | grep -ac -P '^Q\tattempt'; }
S "cold gg" gg
printf 'use y.{twice}\nexport const K: int = twice(4)\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
gg_first=$(gg_attempts)
S "gg: the const needs calc.av's body" gg
steps=$((steps+1)); [ "$gg_first" = 2 ] || { fails=$((fails+1)); echo "FAIL  gg: a const that needs a held body turned $gg_first attempts, wanted 2 (the turn that reads calc.av)"; }
printf 'use y.{twice}\nexport const K: int = twice(5)\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
gg_again=$(gg_attempts)
steps=$((steps+1)); [ "$gg_again" = 1 ] || { fails=$((fails+1)); echo "FAIL  gg: the same edit again turned $gg_again attempts, wanted 1 (calc.av is remembered)"; }
S "gg: the remembered read stands" gg
steps=$((steps+1)); [ "$($R/gg/src/main 2>&1)" = "10" ] || { fails=$((fails+1)); echo "FAIL  gg: the program printed '$($R/gg/src/main 2>&1)', wanted '10'"; }
printf 'export const K: int = 7\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
S "gg: the guess names a file the edit no longer needs" gg
steps=$((steps+1)); [ "$($R/gg/src/main 2>&1)" = "7" ] || { fails=$((fails+1)); echo "FAIL  gg: with an unneeded remembered read the program printed '$($R/gg/src/main 2>&1)', wanted '7'"; }
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/gg/src/main.av
rm $R/gg/src/y/calc.av; rmdir $R/gg/src/y
printf 'export const K: int = 8\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
S "gg: the remembered file is gone" gg
steps=$((steps+1)); [ "$($R/gg/src/main 2>&1)" = "8" ] || { fails=$((fails+1)); echo "FAIL  gg: with the remembered file deleted the program printed '$($R/gg/src/main 2>&1)', wanted '8'"; }
printf 'export const K: int = 9\nexport fn shown() -> int { K }\n' > $R/gg/src/f/held.av
gg_third=$(gg_attempts)
steps=$((steps+1)); [ "$gg_third" = 1 ] || { fails=$((fails+1)); echo "FAIL  gg: a body edit after another edit of the same file turned $gg_third attempts, wanted 1"; }
gg_warm=$(./avra check $R/gg 2>&1 | grep -v '^watch:' | grep -ac -e 'warning' -e 'error')
rm -rf .avra-cache; gg_cold=$(./avra check $R/gg 2>&1 | grep -v '^watch:' | grep -ac -e 'warning' -e 'error')
steps=$((steps+1)); [ "$gg_warm" = "$gg_cold" ] || { fails=$((fails+1)); echo "FAIL  gg: a guess changed what a check says: $gg_warm lines warm, $gg_cold with no store"; }
fi

if section dp; then
# A KEPT VERDICT NEVER READS A FILE THAT IS GONE. held.av's const read z/add.av's body; the file is deleted and
# held.av no longer uses it. The next build is clean and says nothing of the deleted path, and so is the one after.
mkdir -p $R/dp/src/f $R/dp/src/z
printf '[package]\nname = "rt-dp"\nversion = "0.1.0"\n' > $R/dp/avra.toml
printf 'export fn plus(n: int) -> int { n + 1 }\n' > $R/dp/src/z/add.av
printf 'use z.{plus}\nexport const K: int = plus(1)\nexport fn shown() -> int { K }\n' > $R/dp/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/dp/src/main.av
S "cold dp" dp
rm $R/dp/src/z/add.av; rmdir $R/dp/src/z
printf 'export const K: int = 2\nexport fn shown() -> int { K }\n' > $R/dp/src/f/held.av
S "dp: the file a kept verdict read is deleted" dp
steps=$((steps+1)); [ "$($R/dp/src/main 2>&1)" = "2" ] || { fails=$((fails+1)); echo "FAIL  dp: the program printed '$($R/dp/src/main 2>&1)', wanted '2'"; }
printf '// moved\n' >> $R/dp/src/main.av
S "dp: and the build after it" dp

fi

if section vd; then
# THE VERDICT KEY, STALENESS. A kept const verdict recomputes when what it reads moves: a
# named type its expressions carry, or one its reached fns' bodies carry, a fn it reaches,
# or a name a seen module declares. A declaration it never reaches leaves it standing.
# Each const is traced by its module, from a store of its own: each case is its own repo,
# and the store sits beside it, at the nearest `.git` above the package's parent.
vd_fixture() {
  rm -rf $R/vdc; mkdir -p $R/vdc/vd/src/f $R/vdc/vd/src/x $R/vdc/vd/src/y; git -C $R/vdc init -q
  printf '[package]\nname = "rt-vd"\nversion = "0.1.0"\n' > $R/vdc/vd/avra.toml
  printf 'export type Deep = { q: int }\nexport type Cfg = { a: int, d: Deep }\nexport fn dflt() -> Deep { Deep { q: 1 } }\nexport type Other = { z: int }\nexport fn twice(n: int) -> int { n * 2 }\nexport fn g() -> int { Cfg { a: 3, d: dflt() }.a }\nexport enum E { V(int) }\nexport fn unwrap(e: E) -> int { match e { .V(n) -> n, _ -> 0 } }\nexport type S = { s: int }\nimpl S { fn m() -> int { self.s } }\n' > $R/vdc/vd/src/y/calc.av
  printf 'use y.{twice, Cfg, dflt}\nexport const J: int = Entry { key: "a", value: twice(Cfg { a: 3, d: dflt() }.a) }.value\n' > $R/vdc/vd/src/x/mid.av
  printf 'use y.{twice, g}\nexport const F: int = twice(g())\n' > $R/vdc/vd/src/x/fg.av
  printf 'use y.{E, unwrap}\nexport const G: int = unwrap(E.V(3))\n' > $R/vdc/vd/src/x/gg.av
  printf 'use y.{S}\nexport const H: int = S { s: 3 }.m()\n' > $R/vdc/vd/src/x/hh.av
  printf 'export type P = { p: int }\nexport trait Tl { fn tl() -> int }\nimpl Tl for P { fn tl() -> int { self.p + 1 } }\nimpl P { static fn z() -> int { 4 } }\nexport fn viatl() -> int {\n    let d: dyn Tl = P { p: 1 }\n    d.tl()\n}\nexport type Q = { n: int }\nimpl Q { fn bump() -> int { self.n } }\n' >> $R/vdc/vd/src/y/calc.av
  printf 'use y.{P}\nexport const N: int = P.z()\n' > $R/vdc/vd/src/x/nn.av
  printf 'use y.{viatl}\nexport const D: int = viatl()\n' > $R/vdc/vd/src/x/dd.av
  printf 'use y.{Q}\nexport fn callq() -> int {\n    let q = Q { n: 1 }\n    q.bump()\n}\n' > $R/vdc/vd/src/x/cc.av
  printf 'use x.{J, F, G, H, N, D}\nexport const K: int = J * 2 + F + G + H + N + D\nexport fn shown() -> int { K }\n' > $R/vdc/vd/src/f/held.av
  printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/vdc/vd/src/main.av
}
vd_case() { # vd_case <label> <ran|stood> <const module> <edit command>: warm, edit, then that const's verdict
  vd_fixture
  ./avra check $R/vdc/vd > /dev/null 2>&1; ./avra check $R/vdc/vd > /dev/null 2>&1
  eval "$4"
  steps=$((steps+1))
  AVRA_QTRACE=1 ./avra check $R/vdc/vd > $R/vd.out 2>&1; st=$?
  got=$(awk -F'\t' -v m="^x\\.$3" '$1 == "Q" && $2 == "const_verdict" && $3 ~ m { if (v != "ran") v = $4 } END { print v }' $R/vd.out)
  if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  vd: $1: the check failed (status $st)"; failed_tail $R/vd.out
  elif [ "$got" != "$2" ]; then fails=$((fails+1)); echo "FAIL  vd: $1: the $3 verdict was '$got', wanted '$2'"
  elif [ -n "${5:-}" ] && [ "$(./avra run $R/vdc/vd 2>/dev/null | tail -1)" != "$5" ]; then fails=$((fails+1)); echo "FAIL  vd: $1: the program printed '$(./avra run $R/vdc/vd 2>/dev/null | tail -1)', wanted '$5'"
  else [ -n "${VERBOSE:-}" ] && echo "ok    vd: $1 -> $got"; fi
}
vd_case "a: a field of a type the const reads is added" ran mid 'ed $R/vdc/vd/src/y/calc.av "export type Cfg = { a: int, d: Deep }" "export type Cfg = { a: int, d: Deep, b: int = 0 }"'
vd_case "b: a fn the const reaches changes its signature" ran mid 'ed $R/vdc/vd/src/y/calc.av "export fn twice(n: int) -> int { n * 2 }" "export fn twice(n: int, m: int = 1) -> int { n * 2 * m }"'
vd_case "c: a new declaration takes a name the const resolves" ran mid 'printf "export type Entry = { key: string, value: int }\n" > $R/vdc/vd/src/x/local.av'
vd_case "d: a type the const never reaches changes a field" stood mid 'ed $R/vdc/vd/src/y/calc.av "export type Other = { z: int }" "export type Other = { z: int, w: int }"'
vd_case "e: a type reached only through a field of a type it reads gains a field" ran mid 'ed $R/vdc/vd/src/y/calc.av "export type Deep = { q: int }" "export type Deep = { q: int, r: int = 0 }"'
vd_case "f: a fn the const calls reads a type's field, which changes type" ran fg 'ed $R/vdc/vd/src/y/calc.av "export type Cfg = { a: int, d: Deep }" "export type Cfg = { a: int, d: Deep, b: int = 0 }"'
vd_case "g: a variant of an enum the const builds gains a variant" ran gg 'ed $R/vdc/vd/src/y/calc.av "export enum E { V(int) }" "export enum E { V(int), W }"'
vd_case "h: a method the const calls on a type gains a field the receiver shows" ran hh 'ed $R/vdc/vd/src/y/calc.av "export type S = { s: int }" "export type S = { s: int, t: int = 0 }"'
vd_case "i: a method body no run of the const enters changes" stood mid 'ed $R/vdc/vd/src/y/calc.av "fn m() -> int { self.s }" "fn m() -> int { self.s + 0 }"'
vd_case "j: a method body the const's run enters changes" ran hh 'ed $R/vdc/vd/src/y/calc.av "fn m() -> int { self.s }" "fn m() -> int { self.s + 0 }"'
vd_case "k: a method signature changes" ran mid 'ed $R/vdc/vd/src/y/calc.av "fn m() -> int { self.s }" "fn m(k: int = 0) -> int { self.s }"'
NL='
'
vd_case "l: a method is added to an impl" ran mid 'ed $R/vdc/vd/src/y/calc.av "fn m() -> int { self.s }" "fn m() -> int { self.s }${NL}    fn n() -> int { self.s }"'
vd_case "m: a method reached only through dyn dispatch changes its body" ran dd 'ed $R/vdc/vd/src/y/calc.av "fn tl() -> int { self.p + 1 }" "fn tl() -> int { self.p + 2 }"' 31
vd_case "n: a static fn of an impl a const calls changes its body" ran nn 'ed $R/vdc/vd/src/y/calc.av "static fn z() -> int { 4 }" "static fn z() -> int { 5 }"' 31
# o: a body edit flips an INFERRED fact (the method now writes through self) that a fn elsewhere reads without entering the body
wb_case() {
  vd_fixture
  ./avra check $R/vdc/vd > $R/wb0.out 2>&1; ./avra check $R/vdc/vd > /dev/null 2>&1
  steps=$((steps+1))
  ed $R/vdc/vd/src/y/calc.av "fn bump() -> int { self.n }" "fn bump() -> int {${NL}        self.n = self.n + 1${NL}        self.n${NL}    }"
  ./avra check $R/vdc/vd > $R/wb1.out 2>&1
  if grep -q "bump" $R/wb0.out; then fails=$((fails+1)); echo "FAIL  vd: o: the fixture already speaks of bump before the edit"
  elif ! grep -q "bump" $R/wb1.out; then fails=$((fails+1)); echo "FAIL  vd: o: a method starts writing through self and a caller's warning did not follow"
  else [ -n "${VERBOSE:-}" ] && echo "ok    vd: o: the caller's warning followed the inferred write bit"; fi
}
wb_case
fi

# A HOST FN IS THE LINK'S, HELD OR FRESH. A module a build holds still defines its
# symbol for the whole program: the bare name and the program's own are both in
# the binary, and the build lists the host fn, exactly as the cold build did.
if section lh; then
lh=$R/lh; mkdir -p $lh/src/x
printf '[package]\nname = "lh"\nversion = "0.1.0"\n' > $lh/avra.toml
printf 'extern fn avra_lh_event(who: int) -> int { who + 1 }\n' > $lh/src/x/host.av
printf 'println("lh")\n' > $lh/src/main.av
lh_state() { # lh_state <label>: the host symbols and the build's host fn lines
    steps=$((steps+1)); lh_out=$(./avra build --time $lh 2>&1)
    nm $lh/src/main 2>/dev/null | grep -E 'avra_lh_event' | sed 's/^[0-9a-f ]*//' | sort > $R/lh.$1.nm
    printf '%s\n' "$lh_out" | grep -a '^host fn:' | sort > $R/lh.$1.fns
}
lh_state cold
printf '// edited\n' >> $lh/src/main.av
lh_state warm
for k in nm fns; do
    if [ -s $R/lh.cold.$k ] && cmp -s $R/lh.cold.$k $R/lh.warm.$k; then :; else
        fails=$((fails+1)); echo "FAIL  lh: a held module's host fn ($k) differs warm from cold: cold [$(tr '\n' ' ' < $R/lh.cold.$k)] warm [$(tr '\n' ' ' < $R/lh.warm.$k)]"
    fi
done
rm -rf $lh
fi

# A HELD FN THAT PARKS STILL LINKS THE SCHEDULER, REACHED ONLY THROUGH A VALUE. No call
# by name leads to it, so only its interface's word says the program links: the build
# that holds its module must check the loop's back-edge exactly as the cold build did.
# THE WARM BUILD MUST HOLD: an edit to main.av alone leaves the module's interface
# unmoved, so its file is held — a warm build that held nothing attacks nothing.
if section lv; then
lv=$R/lv; mkdir -p $lv/src/x
printf '[package]\nname = "lv"\nversion = "0.1.0"\n\n[bin]\nname = "lv"\npath = "src/main.av"\n' > $lv/avra.toml
printf 'extern fn avra_fiber_sleep(ms: int)\nexport fn napped(n: int) -> int {\n    avra_fiber_sleep(0)\n    n + 1\n}\n' > $lv/src/x/nap.av
printf 'use x.{napped}\nfn looped(g: fn(int) -> int) -> int {\n    mut i = 0\n    while i < 3 { i = g(i) }\n    i\n}\nlet g = napped\nprintln("${looped(g)}")\n' > $lv/src/main.av
lv_state() { # lv_state <label>: how many back-edge checks the program's own code makes
    steps=$((steps+1)); lv_out=$(./avra build --time $lv 2>&1)
    objdump -d $lv/src/main 2>/dev/null | grep -c '<_\{0,1\}avra_tick_cold>$' > $R/lv.$1.ticks
}
lv_state cold
printf '// edited\n' >> $lv/src/main.av
lv_state warm
case "$lv_out" in
    *"held "[1-9]*"/"*) holds=$((holds+1)) ;;
    *) fails=$((fails+1)); echo "FAIL  lv: the warm build held nothing, so no held fn's word was read: $(printf '%s' "$lv_out" | grep -a '^time:' | cut -c1-200)" ;;
esac
if [ "$(cat $R/lv.cold.ticks)" -gt 0 ] 2>/dev/null && cmp -s $R/lv.cold.ticks $R/lv.warm.ticks; then :; else
    fails=$((fails+1)); echo "FAIL  lv: a held fn that parks, reached only through a value: the loop's check differs warm from cold: cold [$(cat $R/lv.cold.ticks)] warm [$(cat $R/lv.warm.ticks)]"
fi
rm -rf $lv
fi

# EXTERNS AND EXPORTS ARE ANSWERED BY NAME, HELD OR READ. A held module answers "what
# does it export", "which externs does it declare" and "which of them have bodies" from
# its record, so a reader names the one thing it wants and mints at most the module that
# has it. Each step is an edit the index must follow while a sibling file stays held: an
# export renamed (the importer fresh), an import left stale, a host fn added beside held
# files, a dependency's host fn the program never imports, a host fn answering another
# package's bodiless extern. Every verdict is the one a cold build speaks.
if section ex; then
ex=$R/ex; xl=$R/exl; x2=$R/exl2; mkdir -p $ex/src/x $xl/src $x2/src
printf '[package]\nname = "ex"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/exl" = { path = "../exl" }\n"@rt/exl2" = { path = "../exl2" }\n' > $ex/avra.toml
printf '[package]\nname = "@rt/exl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-exl"\npath = "src/lib.av"\n\n[dependencies]\n"@rt/exl2" = { path = "../exl2" }\n' > $xl/avra.toml
printf '[package]\nname = "@rt/exl2"\nversion = "0.1.0"\n\n[lib]\nname = "rt-exl2"\npath = "src/lib.av"\n' > $x2/avra.toml
printf 'extern fn avra_exl2_event(who: int) -> int { who + 7 }\nexport fn exl2_one() -> int { 2 }\n' > $x2/src/lib.av
printf 'use @rt.exl2.{exl2_one}\nextern fn avra_exl_event(who: int) -> int { who + 5 }\nexport fn exl_one() -> int { exl2_one() - 1 }\n' > $xl/src/lib.av
printf 'export fn one() -> int { 1 }\n' > $ex/src/x/a.av
printf 'export fn two() -> int { 2 }\n' > $ex/src/x/b.av
printf 'extern fn avra_ex_event(who: int) -> int { who + 1 }\n' > $ex/src/x/host.av
printf 'use x.{one, two}\nuse @rt.exl.{exl_one}\nuse @rt.exl2.{exl2_one}\nprintln("ex ${one()} ${two()} ${exl_one()} ${exl2_one()}")\n' > $ex/src/main.av
EXC() { # EXC <label> <want exit> <phrase the refusal speaks, or ->: a check of ex
    steps=$((steps+1)); ex_out=$(./avra check --time $ex 2>&1); ex_st=$?
    case "$ex_out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; esac
    if [ $ex_st -ne "$2" ]; then fails=$((fails+1)); echo "FAIL  ex: $1: exit $ex_st, wanted $2"; printf '%s\n' "$ex_out" | failed_words; return; fi
    case "$3" in -) ;; *) case "$ex_out" in *"$3"*) ;; *) fails=$((fails+1)); echo "FAIL  ex: $1: the refusal did not speak '$3': $(printf '%s' "$ex_out" | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')" ;; esac ;; esac
}
EXH() { # EXH <label> <symbol>: the build names the host fn and the binary defines it
    steps=$((steps+1)); ex_b=$(./avra build --time $ex 2>&1)
    case "$ex_b" in *"host fn: "*"$2"*) ;; *) fails=$((fails+1)); echo "FAIL  ex: $1: the build does not list the host fn $2: $(printf '%s' "$ex_b" | grep -a '^host fn' | tr '\n' ' ')" ;; esac
    nm $ex/src/main 2>/dev/null | grep -q "$2" || { fails=$((fails+1)); echo "FAIL  ex: $1: the binary does not define $2"; }
}
S "ex: cold" ex
EXH "cold lists the program's host fns" avra_ex_event
EXH "cold lists a dependency's host fn it imports" avra_exl_event
EXH "cold lists a dependency's own dependency's host fn it imports" avra_exl2_event
printf '// moved\n' >> $ex/src/main.av
S "ex: an edit elsewhere, every module held" ex
EXH "a held module's host fn is listed" avra_ex_event
# an export renamed in a module whose sibling stays held, the importer fresh
ed $ex/src/x/a.av "fn one()" "fn uno()"
EXC "the importer still names the old export" 1 "does not export \`one\`"
ed $ex/src/main.av "use x.{one, two}" "use x.{uno, two}"
ed $ex/src/main.av '${one()}' '${uno()}'
S "ex: the importer follows the renamed export" ex
# a host fn added in one file of a module whose other files stay held
printf 'extern fn avra_ex_b(n: int) -> int { n + 2 }\nexport fn two() -> int { 2 }\n' > $ex/src/x/b.av
S "ex: a host fn added beside held files" ex
EXH "the added host fn is listed and defined" avra_ex_b
EXH "the held host fns are still listed" avra_ex_event
# the same file loses its body: the extern is bodiless now, and no host fn
printf 'extern fn avra_ex_b(n: int) -> int\nexport fn two() -> int { 2 }\n' > $ex/src/x/b.av
steps=$((steps+1)); ex_b=$(./avra build --time $ex 2>&1)
case "$ex_b" in *"host fn: "*"avra_ex_b"*) fails=$((fails+1)); echo "FAIL  ex: a host fn that lost its body is still listed" ;; esac
printf 'export fn two() -> int { 2 }\n' > $ex/src/x/b.av
# a dependency's host fn the program's own sources no longer import
printf 'use x.{uno, two}\nuse @rt.exl.{exl_one}\nprintln("ex ${uno()} ${two()} ${exl_one()}")\n' > $ex/src/main.av
EXC "a dependency's host fn nothing in the program's own sources imports" 1 "never import"
printf 'use x.{uno, two}\nuse @rt.exl.{exl_one}\nuse @rt.exl2.{exl2_one}\nprintln("ex ${uno()} ${two()} ${exl_one()} ${exl2_one()}")\n' > $ex/src/main.av
EXC "importing it again lifts the refusal" 0 -
# a dependency's host fn answering a bodiless extern of another package
printf 'extern fn avra_exl_event(who: int) -> int\n' > $ex/src/x/claim.av
EXC "a host fn answering another package's bodiless extern" 1 "to name"
rm -f $ex/src/x/claim.av
EXC "and the claim gone" 0 -
rm -rf $ex $xl $x2
fi

# A REFERENCE BETWEEN TWO HELD FILES IS NOT RESTORED UNTIL ASKED. `user.av` is the only
# reader of `target`, and both stay held: the relation holds no row for the edge, yet
# `refs_of` on the held target answers it on demand, so `--verify-held` finds the warm
# count equal to a fresh reading. Then the target is renamed with `user.av` untouched:
# the edge must surface as the refusal a cold check speaks, never a stale held answer.
if section hh; then
hh=$R/hh; mkdir -p $hh/src/t $hh/src/u
printf '[package]\nname = "hh"\nversion = "0.1.0"\n' > $hh/avra.toml
printf 'export fn target() -> int { 7 }\n' > $hh/src/t/target.av
printf 'use t.{target}\nexport fn user() -> int { target() }\n' > $hh/src/u/user.av
printf 'use u.{user}\nprintln("hh ${user()}")\n' > $hh/src/main.av
S "hh: cold" hh
printf '// moved\n' >> $hh/src/main.av
S "hh: an edit elsewhere, both ends of the edge held" hh
steps=$((steps+1)); hh_vh=$(./avra check $hh --verify-held 2>&1 | unwatched)
case "$hh_vh" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  hh: verify-held compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    hh: verify-held over a held-to-held edge -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  hh: verify-held: $(printf '%s' "$hh_vh" | tail -5 | tr '\n' ' ')" ;;
esac
ed $hh/src/t/target.av "fn target()" "fn goal()"
steps=$((steps+1)); hh_out=$(./avra check $hh 2>&1); hh_st=$?
if [ $hh_st -ne 1 ]; then fails=$((fails+1)); echo "FAIL  hh: a rename the only reader never followed exited $hh_st, wanted 1"
else case "$hh_out" in *"does not export \`target\`"*) [ -n "${VERBOSE:-}" ] && echo "ok    hh: the held reader's edge surfaced as a refusal" ;; *) fails=$((fails+1)); echo "FAIL  hh: the rename was not refused where the held reader imports it: $(printf '%s' "$hh_out" | grep -vE '^watch:|^time:' | head -3 | tr '\n' ' ')" ;; esac; fi
rm -rf $hh
fi

if section rx; then
# A NAME REACHED THROUGH A RE-EXPORT KEYS ON THE RE-EXPORTING FILE TOO: `show.av`
# names `twice` from `@rt/rxl`, whose `lib.av` re-exports it, so the importer's
# reference lands on the ORIGINAL declaration's file. Re-pointing the re-export at
# another declaration never moves that file, and must still re-read `show.av` —
# or it stays held against a name that now means something else. A body edit to
# the original holds it (avra-8sb5.64.10.1).
RX() { # RX <label> <path-substr> <want: held|read> <printed>
    steps=$((steps+1))
    out=$(./avra build --time $R/rx 2>&1)
    case "$out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; *"held 0/"*) [ "$3" = held ] && { fails=$((fails+1)); echo "FAIL  $1: a derivation held nothing, so a file staying held was never examined"; } ;; esac
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
fi

if section vw; then
# A FILE'S KEPT ROWS ARE JUDGED AGAINST THE PROGRAM THAT ASKS. A library tested as the root and
# the same library read by an app see its files through different views, so after the suite
# wrote last, an edit to the app must still find its own rows standing: no file falls back to
# rebuilding.
VW() { # VW <label> <max fallbacks>
    steps=$((steps+1))
    out=$(./avra check --counts $R/vwa 2>&1)
    n=$(printf '%s\n' "$out" | grep -oE 'judge_fallbacks=[0-9]+' | tail -1 | cut -d= -f2)
    case "$out" in *"held "[1-9]*"/"*) holds=$((holds+1)) ;; esac
    if [ -z "$n" ]; then fails=$((fails+1)); echo "FAIL  $1: no judge_fallbacks count printed"; return; fi
    if [ "$n" -le "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 -> $n"; else fails=$((fails+1)); echo "FAIL  $1: judge_fallbacks=$n, wanted at most $2"; fi
}
mkdir -p $R/vwl/src/tests $R/vwa/src
printf '[package]\nname = "@rt/vwl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-vwl"\npath = "src/lib.av"\n' > $R/vwl/avra.toml
printf 'export fn three() -> int { 3 }\n' > $R/vwl/src/lib.av
printf 'use @rt.vwl.{three}\nspec "three" { given "the fn" { then "it answers three" { three() == 3 } } }\n' > $R/vwl/src/tests/lib_test.av
printf '[package]\nname = "rt-vwa"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/vwl" = { path = "../vwl" }\n' > $R/vwa/avra.toml
printf 'use @rt.vwl.{three}\nexport fn shown() -> int { three() }\n' > $R/vwa/src/show.av
printf 'use show.{shown}\nprintln("vw ${shown()}")\n' > $R/vwa/src/main.av
./avra check $R/vwa >/dev/null 2>&1
./avra test $R/vwl >/dev/null 2>&1
printf '// edited\n' >> $R/vwa/src/main.av
VW "vw: an app edit after the library's own suite wrote last judges by stamps" 0
fi

# CACHE_ATTACKS set: the sections named above are the whole run.
if [ -n "${CACHE_ATTACKS:-}" ]; then
    # THE COMPILER'S OWN BINARY is identified by a stamp-keyed record of its bytes' digest:
# a stamp that holds reuses it, anything else reads the bytes, and the digest is the
# bytes' either way. Each step wants how the print was settled and which bytes it named.
bi=build/avra.bi
mkdir -p $R/bi/src; printf 'export fn one() -> int { 1 }\n' > $R/bi/src/m.av
printf '[package]\nname = "bi"\nversion = "0.1.0"\n' > $R/bi/avra.toml
Pr() { # Pr <binary>: "<how> <digest prefix>"
    AVRA_CWD=$PWD AVRA_QTRACE=1 $1 check $R/bi 2>&1 | grep "^Q.print" | head -1 | cut -f3,4 | tr '\t' ' '
}
BI() { # BI <label> <binary> <want how> <want same|other as the first digest>
    steps=$((steps+1)); got=$(Pr $2); how=${got%% *}; dig=${got#* }
    [ -z "${bi_first:-}" ] && bi_first=$dig
    same=other; [ "$dig" = "$bi_first" ] && same=same
    if [ "$how" = "$3" ] && [ "$same" = "$4" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [bi] -> $how/$same"; else fails=$((fails+1)); echo "FAIL  $1 [bi] wanted $3/$4, got $how/$same"; fi
}
rm -f $bi build/.avra.bi.print; cp build/avra $bi; sleep 3; bi_first=
BI "first sight reads the bytes" $bi bytes same
BI "the same binary again is trusted" $bi stamp same
touch $bi; sleep 3
BI "touched with no change reads once" $bi bytes same
BI "and is trusted again" $bi stamp same
cp $bi $R/bi.orig; strip -x $bi -o $R/bi.other 2>/dev/null && { codesign -f -s - $R/bi.other 2>/dev/null || true; }
if [ -x $R/bi.other ]; then
    touch -r $bi $R/bi.other; cp -p $R/bi.other $bi; sleep 3
    BI "other bytes copied over the path with its mtime kept" $bi bytes other
    cp -p $R/bi.orig $bi; sleep 3
    BI "and the first bytes back" $bi bytes same
fi
rm -f $bi build/.avra.bi.print $R/bi.orig $R/bi.other

echo "cache-attacks: $steps builds through one store, $holds under a hold, $fails failed"
    [ "$holds" -gt 0 ] || { echo "cache-attacks: no step ran under a hold — the sections named examined nothing"; exit 1; }
    [ "$fails" -eq 0 ]; exit $?
fi
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
# EVERY PACKED ROW DELETED, THE OBJECTS KEPT: the value families (sig, fp, unit,
# warn, rows) ride `store/`, so removing it drops every ask, home and const row while
# `obj/` and `bin/` stand — the same claim the file layout's unit directory held.
[ -d .avra-cache/store ] || { echo "FAIL  no packed store under .avra-cache: $(ls .avra-cache)"; fails=$((fails+1)); }
rm -rf .avra-cache/store
S "every packed row deleted (asks, homes, consts; objects kept)" a; S "same, b" b
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
K "d, by the compiler itself" hit
cp build/avra build/avra.twin;                 W "the same bytes from another path" build/avra.twin hit
strip -x build/avra -o build/avra.other 2>/dev/null && { codesign -f -s - build/avra.other 2>/dev/null || true; }
W "a compiler of other bytes" build/avra.other built
# ONE STORE FOR EVERY COMPILER: a row's family carries the stamp it stands under — the
# writing compiler's print, or a shared producer's hash — so a second compiler's rows
# neither hide nor displace the first's, and no directory of its own is needed. The
# behaviour below — each compiler reading its own rows — is the claim.
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
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $label did not build (status $st)"; printf '%s\n' "$out" | failed_words; return; fi
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

# RULE FINDINGS ARE KEPT BY EVERY WANT AND SPOKEN BY A CHECK: a build keeps the
# rows and prints none; a check after that build holds them and speaks what a
# cold check speaks; a check held on a check's rows speaks the same again.
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
cutfp_warn0=$(./avra check $R/cutfp 2>&1 | grep -c '^warning\[[a-z_.]*unmutated_mut\]')
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
cutfp_warn1=$(./avra check $R/cutfp 2>&1 | grep -c '^warning\[[a-z_.]*unmutated_mut\]')
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

# THE DURABLE WITNESS IS THE HOLD'S KEY: a file's text and the interface digest of
# every module it sees. HR runs one command over a package and judges it: its exit,
# and for each named file whether the run read it or held it.


# A HELD FILE IS NEVER PARSED: every parse a warm check makes names a file it read.
# A body edit to `m1` reads `m1` and the entry; `m2`, `m3` and the prelude are held,
# and AVRA_QTRACE's parse lines must name exactly the two read files.
mkdir -p $R/zp/src/m1 $R/zp/src/m2 $R/zp/src/m3
printf '[package]\nname = "rt-zp"\nversion = "0.1.0"\n' > $R/zp/avra.toml
printf 'export fn f1() -> int { 1 }\n' > $R/zp/src/m1/mod.av
printf 'use m1.{f1}\nexport fn f2() -> int { f1() + 1 }\n' > $R/zp/src/m2/mod.av
printf 'use m2.{f2}\nexport fn f3() -> int { f2() + 1 }\n' > $R/zp/src/m3/mod.av
printf 'use m3.{f3}\nprintln("${f3()}")\n' > $R/zp/src/main.av
HR "cold zp" check zp 0
ed $R/zp/src/m1/mod.av "{ 1 }" "{ 10 }"
steps=$((steps+1))
zp_out=$(AVRA_QTRACE=1 ./avra check --time $R/zp 2>&1)
zp_held=$(printf '%s\n' "$zp_out" | grep -oE 'held [0-9]+/[0-9]+' | tail -1)
zp_parsed=$(printf '%s\n' "$zp_out" | grep "$(printf '^Q\tparse\t')" | cut -f3 | grep '/cache-attacks/zp/' | sed 's|.*/cache-attacks/zp/||' | sort -u | tr '\n' ' ')
case "$zp_held" in "held 0/"*|"") fails=$((fails+1)); echo "FAIL  zp: a body edit held nothing ($zp_held), so the parse count attacks nothing" ;; *) holds=$((holds+1)) ;; esac
[ "$zp_parsed" = "src/m1/mod.av src/main.av " ] || { fails=$((fails+1)); echo "FAIL  zp: a warm check parsed '$zp_parsed' ($zp_held), wanted m1/mod.av and main.av alone"; }

# A DELETED IMPORT TARGET NEVER READS AS HELD: the store still keeps `leaf`'s record,
# and a record that places a file the host no longer has keys on the module's bytes,
# so `mid` re-reads and refuses the `use` a cold check refuses.
mkdir -p $R/dt/src/mid $R/dt/src/leaf
printf '[package]\nname = "rt-dt"\nversion = "0.1.0"\n' > $R/dt/avra.toml
printf 'export fn f() -> int { 1 }\n' > $R/dt/src/leaf/mod.av
printf 'use leaf.{f}\nexport fn g() -> int { f() + 1 }\n' > $R/dt/src/mid/mod.av
printf 'use mid.{g}\nprintln("${g()}")\n' > $R/dt/src/main.av
HR "cold dt" check dt 0
printf '// moved\n' >> $R/dt/src/main.av
HR "dt: an entry edit holds mid" check dt 0 mid/mod.av held
rm $R/dt/src/leaf/mod.av; rmdir $R/dt/src/leaf
steps=$((steps+1)); dt_out=$(./avra check $R/dt 2>&1)
case "$dt_out" in *"resolve.no_module"*"mid/mod.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    dt: the import target gone -> refused" ;; *) fails=$((fails+1)); echo "FAIL  dt: mid's import target is gone and the check did not refuse it: $(printf '%s' "$dt_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac

# A DELETED HELD SIBLING NEVER READS AS HELD: `a` calls `b`'s `h` by no `use`, and
# with `b` gone its module's record names a file the module no longer has.
mkdir -p $R/ds/src/mid
printf '[package]\nname = "rt-ds"\nversion = "0.1.0"\n' > $R/ds/avra.toml
printf 'export fn h() -> int { 2 }\n' > $R/ds/src/mid/b.av
printf 'export fn g() -> int { h() + 1 }\n' > $R/ds/src/mid/a.av
printf 'use mid.{g}\nprintln("${g()}")\n' > $R/ds/src/main.av
HR "cold ds" check ds 0
printf '// moved\n' >> $R/ds/src/main.av
HR "ds: an entry edit holds both siblings" check ds 0 mid/a.av held mid/b.av held
rm $R/ds/src/mid/b.av
steps=$((steps+1)); ds_out=$(./avra check $R/ds 2>&1)
case "$ds_out" in *"resolve.unresolved"*"mid/a.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    ds: the sibling gone -> refused" ;; *) fails=$((fails+1)); echo "FAIL  ds: a's sibling is gone and the check did not refuse h(): $(printf '%s' "$ds_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac

# A MODULE WITH NO RECORD KEYS ON ITS BYTES, NEVER ON NOTHING: with `nrl`'s record
# gone, `user`'s key rides `nrl`'s bytes, so removing the import target re-reads the
# importer and a WARM check REFUSES where a stale hold would have passed over it. The
# packed store holds no per-row file to remove, so the target's own removal is the
# trigger — the same defect, witnessed by the verdict a cold check gives.
mkdir -p $R/nrl/src $R/nr/src
printf '[package]\nname = "@rt/nrl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-nrl"\npath = "src/lib.av"\n' > $R/nrl/avra.toml
printf 'export fn lf() -> int { 3 }\n' > $R/nrl/src/lib.av
printf '[package]\nname = "rt-nr"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/nrl" = { path = "../nrl" }\n' > $R/nr/avra.toml
printf 'use @rt.nrl.{lf}\nexport fn u() -> int { lf() + 1 }\n' > $R/nr/src/user.av
printf 'use user.{u}\nprintln("${u()}")\n' > $R/nr/src/main.av
HR "cold nr" check nr 0
printf '// moved\n' >> $R/nr/src/main.av
HR "nr: an entry edit holds user" check nr 0 user.av held
rm $R/nrl/src/lib.av
printf '// moved again\n' >> $R/nr/src/main.av
steps=$((steps+1)); nr_out=$(./avra check $R/nr 2>&1); nr_st=$?
case "$nr_st:$nr_out" in 1:*"nrl"*) [ -n "${VERBOSE:-}" ] && echo "ok    nr: nrl's file gone -> user re-read and the check refused" ;; *) fails=$((fails+1)); echo "FAIL  nr: nrl's file gone — a warm check did not refuse (exit $nr_st): $(printf '%s' "$nr_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac
printf 'export fn lf() -> int { 3 }\n' > $R/nrl/src/lib.av
printf '// and again\n' >> $R/nr/src/main.av
HR "nr: the target is back — the run after holds user again" check nr 0 user.av held

# A CALLEE'S ERROR TYPE IS PART OF ITS INTERFACE, ACROSS TWO PROCESSES: `user` reads
# `e.code` from `errs`' `risky` and `inferred`, whose `E` moves under it. Every move
# re-reads `user` and the binary follows the new `E` (`code` turns from a number to
# text, one flat field either way, so only the interface can tell); a body edit that
# leaves `E` alone holds `user`; an `E` with no `code` is refused where it is read.
mkdir -p $R/ee/src/errs $R/ee/src/user
printf '[package]\nname = "rt-ee"\nversion = "0.1.0"\n' > $R/ee/avra.toml
cat > $R/ee/src/errs/mod.av <<'AV'
export type Bad = { code: int }
export type Said = { code: string }
export type Other = { why: string }
export fn risky(n: int) -> Result<int, Bad> {
    if n < 0 { fail Bad { code: n } }
    n
}
export fn inferred(n: int) -> Result<int, _> {
    if n < 0 { fail Bad { code: n * 10 } }
    n
}
AV
cat > $R/ee/src/user/mod.av <<'AV'
use errs.{risky, inferred}
export fn shown(n: int) -> string {
    match risky(n) {
        .Ok(v) -> "ok ${v}",
        .Err(e) -> "err ${e.code}",
    }
}
export fn shown2(n: int) -> string {
    match inferred(n) {
        .Ok(v) -> "ok ${v}",
        .Err(e) -> "err ${e.code}",
    }
}
AV
printf 'use user.{shown, shown2}\nprintln("ee ${shown(1)} ${shown(-2)} ${shown2(-3)}")\n' > $R/ee/src/main.av
S "cold ee" ee
printf '// moved\n' >> $R/ee/src/main.av
HR "ee: an entry edit holds user" build ee 0 user/mod.av held
ed $R/ee/src/errs/mod.av "fail Bad { code: n } }" "fail Bad { code: n - 1 } }"
HR "ee: risky's body moves, its E does not — user stays held" build ee 0 user/mod.av held
ed $R/ee/src/errs/mod.av "Result<int, Bad> {
    if n < 0 { fail Bad { code: n - 1 } }" "Result<int, Said> {
    if n < 0 { fail Said { code: \"neg\" } }"
HR "ee: risky's written E moves — user's stale row is refused" build ee 0 user/mod.av read
S "ee: and the binary reads the new E" ee
ee_got=$($R/ee/src/main 2>&1); steps=$((steps+1))
[ "$ee_got" = "ee ok 1 err neg err -30" ] || { fails=$((fails+1)); echo "FAIL  ee printed '$ee_got', wanted 'ee ok 1 err neg err -30'"; }
ed $R/ee/src/errs/mod.av "fail Bad { code: n * 10 } }" "fail Said { code: \"inferred\" } }"
HR "ee: what inferred fails moves its inferred E — user's stale row is refused" build ee 0 user/mod.av read
S "ee: and the binary reads the inferred E" ee
ee_got=$($R/ee/src/main 2>&1); steps=$((steps+1))
[ "$ee_got" = "ee ok 1 err neg err inferred" ] || { fails=$((fails+1)); echo "FAIL  ee printed '$ee_got', wanted 'ee ok 1 err neg err inferred'"; }
HR "ee: a check holds user, whose rule findings the build kept" check ee 0 user/mod.av held
printf '// checked\n' >> $R/ee/src/main.av
HR "ee: and the next check holds it" check ee 0 user/mod.av held
ed $R/ee/src/errs/mod.av "Result<int, Said> {
    if n < 0 { fail Said { code: \"neg\" } }" "Result<int, Other> {
    if n < 0 { fail Other { why: \"neg\" } }"
steps=$((steps+1)); ee_out=$(./avra check $R/ee 2>&1)
case "$ee_out" in *"type.unknown_prop"*"user/mod.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    ee: an E with no code -> refused in user" ;; *) fails=$((fails+1)); echo "FAIL  ee: risky's E has no code and the check did not refuse user's e.code: $(printf '%s' "$ee_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac
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

# A TYPE ADDED, INSERTED OR REMOVED MOVES ITS MODULE'S INTERFACE, AND THE
# HOLD TAKES IT, while a fn `b` never names moves nothing (both pinned): `b` names
# `a` and a collect in `coll`, so an interface move in `a` re-reads `b` while `coll`
# stays held — and `b` types `entries.length`
# against the held collect's recorded type. ND judges one warm check (held,
# never refused, `coll` held and `b` read) and holds its words to a cold one.
mkdir -p $R/nd/src/a $R/nd/src/b $R/nd/src/coll
printf '[package]\nname = "rt-nd"\nversion = "0.1.0"\n' > $R/nd/avra.toml
printf 'export fn fa() -> int { 1 }\nexport fn fz() -> int { 2 }\n' > $R/nd/src/a/mod.av
printf 'export component widget {\n    run: fn(int) -> int\n}\n' > $R/nd/src/coll/widget.av
printf 'export widget one { n -> n + 1 }\nexport widget two { n -> n + 2 }\n' > $R/nd/src/coll/members.av
printf 'type Entry = { name: string, ran: fn(int) -> int }\nexport collect entries: List<Entry> = widget in closure as Entry { name: it.name, ran: it.run } by it.name\n' > $R/nd/src/coll/table.av
printf 'use a.{fa}\nuse coll.{entries}\nexport fn fb() -> int { entries.length + fa() }\n' > $R/nd/src/b/mod.av
printf 'use b.{fb}\nprintln("nd ${fb()}")\n' > $R/nd/src/main.av
ND() { # ND <label> [read|held]: whether b re-reads (default read)
    want_b=${2:-read}
    steps=$((steps+1))
    rm -rf $R/nd.warm; cp -R .avra-cache $R/nd.warm
    out=$(./avra check --time $R/nd 2>&1); st=$?
    read_list=$(printf '%s\n' "$out" | sed -n '/^read:/,$p' | grep '^  ')
    case "$out" in
        *"the hold was refused"*) fails=$((fails+1)); echo "FAIL  $1: the hold was refused: $(printf '%s\n' "$out" | grep -m1 'the hold was refused' | cut -c1-200)" ;;
        *"held "[1-9]*"/"*) holds=$((holds+1)) ;;
        *) fails=$((fails+1)); echo "FAIL  $1: held nothing (exit $st)" ;;
    esac
    case "$read_list" in *coll/*) fails=$((fails+1)); echo "FAIL  $1: coll was read, wanted held: $(printf '%s' "$read_list" | tr '\n' ' ')" ;; esac
    case "$read_list" in
        *b/mod.av*) [ "$want_b" = read ] || { fails=$((fails+1)); echo "FAIL  $1: b was read, wanted held: $(printf '%s' "$read_list" | tr '\n' ' ')"; } ;;
        *) [ "$want_b" = held ] || { fails=$((fails+1)); echo "FAIL  $1: b was held, wanted read: $(printf '%s' "$read_list" | tr '\n' ' ')"; } ;;
    esac
    rm -rf .avra-cache; cp -R $R/nd.warm .avra-cache
    held_says=$(./avra check $R/nd 2>&1 | unwatched)
    rm -rf .avra-cache; plain_says=$(./avra check $R/nd 2>&1 | unwatched)
    steps=$((steps+1)); [ "$held_says" = "$plain_says" ] || { fails=$((fails+1)); echo "FAIL  $1: a warm check speaks otherwise than a cold one: $(printf '%s' "$held_says" | head -3 | tr '\n' ' ')"; }
}
rm -rf .avra-cache; ./avra check $R/nd >/dev/null 2>&1
printf 'export fn fnew() -> int { 3 }\n' >> $R/nd/src/a/mod.av
ND "nd: a fn nobody in b names, appended to a" held
ed $R/nd/src/a/mod.av 'export fn fz()' 'fn fmid() -> int { 4 }
export fn fz()'
ND "nd: a fn nobody in b names, inserted between two in a" held
ed $R/nd/src/a/mod.av 'export fn fnew() -> int { 3 }
' ''
ND "nd: a fn nobody in b names, removed from a" held
printf 'export type Fnew = { n: int }\n' >> $R/nd/src/a/mod.av
ND "nd: a type appended to a" read
ed $R/nd/src/a/mod.av 'export fn fz()' 'type Fmid = { n: int }
export fn fz()'
ND "nd: a type inserted between two in a" read
ed $R/nd/src/a/mod.av 'export type Fnew = { n: int }
' ''
ND "nd: a type nobody uses removed from a" read
vh_nd=$(./avra check $R/nd --verify-held 2>&1 | unwatched)
steps=$((steps+1))
case "$vh_nd" in
    *" 0 held declaration(s)"*) fails=$((fails+1)); echo "FAIL  verify-held over nd compared nothing" ;;
    *" 0 mismatch(es)"*) [ -n "${VERBOSE:-}" ] && echo "ok    verify-held over nd -> clean" ;;
    *) fails=$((fails+1)); echo "FAIL  verify-held over nd: $(printf '%s' "$vh_nd" | tail -5 | tr '\n' ' ')" ;;
esac

# `avra explain` IS ITS OWN PROCESS, reading what an earlier check kept — and an
# INSPECTION KEEPS NOTHING. A check, then ONE edit, then every form in a process of
# its own: each names the edited input, `--why` twice says the same move, and
# after them still reads the file, and the store's bytes are what the check left. A
# check after them keeps as it always did, and only then has nothing moved.
mkdir -p $R/cw/src/lib
printf '[package]\nname = "rt-cw"\nversion = "0.1.0"\n' > $R/cw/avra.toml
printf 'use lib.{one}\none()\n' > $R/cw/src/main.av
printf 'export fn one() -> int { 1 }\n' > $R/cw/src/lib/a.av
./avra check $R/cw >/dev/null 2>&1
tree=$(pwd)
printf 'export fn one(p: int = 0) -> int { 1 }\n' > $R/cw/src/lib/a.av
# the store's bytes, each file's checksum by path — a process's own `.users` mark aside
store_print() { (cd .avra-cache && find . -path '*/.users' -prune -o -type f -print | LC_ALL=C sort | xargs cksum); }
inspected() { (cd $R/cw && "$tree/avra" explain "$@" 2>&1); }
explain_says() { # explain_says <a line the answer holds> <the answer> <the form's words...>
    steps=$((steps+1)); want=$1; said=$2; shift 2
    printf '%s\n' "$said" | grep -qF -- "$want" ||
        { fails=$((fails+1)); echo "FAIL  avra explain $* never said '$want': $(printf '%s\n' "$said" | head -4 | tr '\n' ' ')"; }
}
kept_before=$(store_print)
first=$(inspected --why); second=$(inspected --why)
explain_says "  src/lib/a.av: its text " "$first" --why
explain_says "1 input moved since the kept state" "$first" --why
explain_says "src/lib/a.av — read" "$second" "--why, a second time"
steps=$((steps+1)); [ "$first" = "$second" ] ||
    { fails=$((fails+1)); echo "FAIL  a second avra explain --why answered otherwise: $(printf '%s\n' "$second" | head -2 | tr '\n' ' ')"; }
explain_says "src/lib/a.av — read" "$(inspected src/lib/a.av --why)" src/lib/a.av --why
why_main=$(inspected src/main.av --why)
explain_says "  moved    src/lib/a.av, read by way of:" "$why_main" src/main.av --why
readers=$(inspected src/lib/a.av)
explain_says "    src/main.av" "$readers" src/lib/a.av
stats=$(inspected --stats)
explain_says "total " "$stats" --stats
steps=$((steps+1)); [ "$stats" = "$(inspected --stats)" ] ||
    { fails=$((fails+1)); echo "FAIL  a second avra explain --stats answered otherwise"; }
steps=$((steps+1)); [ "$kept_before" = "$(store_print)" ] ||
    { fails=$((fails+1)); echo "FAIL  avra explain moved the store:"; printf '%s\n' "$kept_before" > $R/cw.before; store_print | diff $R/cw.before - | head -8; }
./avra check $R/cw >/dev/null 2>&1
steps=$((steps+1)); [ "$kept_before" != "$(store_print)" ] ||
    { fails=$((fails+1)); echo "FAIL  a check after the edit kept nothing"; }
explain_says "no input moved since the kept state" "$(inspected --why)" "--why, after a check"
# WHAT COMPOSES A COMPONENT IS NEVER SERVED STALE. `note` holds a body, composed by
# the trait its file names (`kit`'s `Says`, wearing `@composes`); `card` is made of
# `note`, a sibling it names by no `use`. An entry edit holds both. Then the mark is
# dropped from the trait with no edit to either component — `note` has no composer
# and must be refused — and put back; then the sibling's component is renamed with
# no edit to `card`, whose body names a word its module no longer declares.
mkdir -p $R/cb/src/kit $R/cb/src/part
printf '[package]\nname = "rt-cb"\nversion = "0.1.0"\n' > $R/cb/avra.toml
cat > $R/cb/src/kit/kit.av <<'AV'
use @std.meta.{Type, Directive, Declared, composes}

export type Tagged = { tag: string = "" }

export component words {
    items: List<string> = []
}

@composes(Tagged)
export trait Says {
    fn says() -> string

    static fn derive(t: Type) -> Declared {
        let body? = t.body else { return Declared { made: [] } }
        Declared {
            made: [
                Directive {
                    twin: "",
                    name: t.name,
                    at: t.at,
                    source: quote {
                        impl Says for ${t} {
                            fn says() -> string {
                                words made {
                                    ${body}
                                }
                                made.items.join(" ")
                            }
                        }
                    },
                },
            ],
        }
    }
}

export fn said_by(s: dyn Says) -> string { s.says() }
AV
printf 'use kit.{said_by}\n\nexport component note(name: string) {\n    "note"\n    self.name\n}\n\nexport fn noted(n: note) -> string { said_by(n) }\n' > $R/cb/src/part/note.av
printf 'use kit.{said_by}\n\nexport component card(name: string) {\n    said_by(note self.name)\n}\n' > $R/cb/src/part/card.av
printf 'use kit.{said_by}\nuse part.{card}\nprintln(said_by(card "a"))\n' > $R/cb/src/main.av
HR "cold cb" check cb 0
printf '// moved\n' >> $R/cb/src/main.av
HR "cb: an entry edit holds the components" check cb 0 part/note.av held part/card.av held
cp $R/cb/src/kit/kit.av $R/cb/kit.kept
grep -v '^@composes' $R/cb/kit.kept > $R/cb/src/kit/kit.av
steps=$((steps+1)); cb_out=$(./avra check $R/cb 2>&1)
case "$cb_out" in *"type.component_body"*"nothing here says"*) [ -n "${VERBOSE:-}" ] && echo "ok    cb: the mark gone -> the body is refused" ;; *) fails=$((fails+1)); echo "FAIL  cb: the trait lost @composes and a body was still composed: $(printf '%s' "$cb_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac
cp $R/cb/kit.kept $R/cb/src/kit/kit.av
HR "cb: the mark back composes again" check cb 0
sed 's/component note(/component memo(/; s/n: note/n: memo/' $R/cb/src/part/note.av > $R/cb/note.new && cp $R/cb/note.new $R/cb/src/part/note.av
steps=$((steps+1)); cb_out=$(./avra check $R/cb 2>&1)
case "$cb_out" in *"card.av"*) [ -n "${VERBOSE:-}" ] && echo "ok    cb: the sibling's word gone -> card refused" ;; *) fails=$((fails+1)); echo "FAIL  cb: card names a sibling component that was renamed and the check did not refuse it: $(printf '%s' "$cb_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac

# A FILE NOTHING REACHES IS HELD LIKE ANY OTHER. `ur` names ONE file of `@rt/url`'s
# root module; its siblings are registered with it — a module is one namespace — and
# a sibling no `use` names must be held by its record, never parsed again on every
# run. It is still the module's: its edit, its parse error, its clash, its impl and
# its removal each reach the next check as they reach a cold one.
mkdir -p $R/url/src $R/ur/src
printf '[package]\nname = "@rt/url"\nversion = "0.1.0"\n\n[lib]\nname = "rt-url"\npath = "src/lib.av"\n' > $R/url/avra.toml
printf '[package]\nname = "rt-ur"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/url" = { path = "../url" }\n' > $R/ur/avra.toml
printf 'export fn base() -> int { 1 }\n' > $R/url/src/lib.av
printf 'export trait Say { fn say() -> int }\nexport type Pt = { v: int }\nexport fn r() -> int { 2 }\n' > $R/url/src/reach.av
printf 'use reach.{Say, Pt}\nexport fn lone() -> int { 3 }\nimpl Say for Pt { fn say() -> int { self.v + 1 } }\n' > $R/url/src/lone.av
printf 'use @rt.url.reach.{r, Say, Pt}\nlet s: dyn Say = Pt { v: 1 }\nprintln("${r()} ${s.say()}")\n' > $R/ur/src/main.av
up=ur
ur_parsed() { # the files of the fixture `up` a warm check parses, sorted
    AVRA_QTRACE=1 ./avra check $R/$up 2>&1 | grep "$(printf '^Q\tparse\t')" | cut -f3 | grep "/cache-attacks/$up" | sed 's|.*/cache-attacks/||' | sort -u | tr '\n' ' '
}
UR() { # UR <label> <the files parsed>
    steps=$((steps+1)); holds=$((holds+1)); got=$(ur_parsed)
    if [ "$got" = "$2" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 -> $got"; else fails=$((fails+1)); echo "FAIL  $1: a warm check parsed '$got', wanted '$2'"; fi
}
URX() { # URX <label> <a word the refusal carries> <the file it names>
    steps=$((steps+1)); out=$(./avra check $R/$up 2>&1); st=$?
    case "$st:$out" in 1:*"$2"*"$3"*|1:*"$3"*"$2"*) [ -n "${VERBOSE:-}" ] && echo "ok    $1 -> refused" ;; *) fails=$((fails+1)); echo "FAIL  $1: exit $st, wanted a refusal carrying '$2' and '$3': $(printf '%s' "$out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac
}
S "cold ur: an impl in a file nothing names is dispatched" ur
HR "ur checks clean" check ur 0
printf '// moved\n' >> $R/ur/src/main.av
UR "ur: an entry edit parses the entry alone" "ur/src/main.av "
ed $R/url/src/lone.av "self.v + 1" "self.v + 100"
S "ur: the unnamed file's impl body moved" ur
HR "ur checks clean after it" check ur 0
printf '// moved\n' >> $R/ur/src/main.av
UR "ur: the edited sibling is held again" "ur/src/main.av "
cp $R/url/src/lone.av $R/url/lone.kept
printf 'export fn lone( -> int { 3 }\n' >> $R/url/src/lone.av
URX "ur: the unnamed file gains a parse error" "parse." "lone.av"
cp $R/url/lone.kept $R/url/src/lone.av
printf 'export fn r() -> int { 9 }\n' >> $R/url/src/lone.av
URX "ur: the unnamed file gains a name its sibling exports" "duplicate_in_module" "lone.av"
cp $R/url/lone.kept $R/url/src/lone.av
ed $R/url/src/lone.av "{ 3 }" "{ 30 }"
ed $R/ur/src/main.av 'use @rt.url.reach.{r, Say, Pt}' "$(printf 'use @rt.url.reach.{r, Say, Pt}\nuse @rt.url.lone.{lone}')"
ed $R/ur/src/main.av '${r()} ' '${r()} ${lone()} '
S "ur: the unnamed file becomes named by an edit elsewhere" ur
printf 'export fn fresh( -> int { 4 }\n' > $R/url/src/fresh.av
URX "ur: a new file nothing names arrives broken" "parse." "fresh.av"
printf 'export fn fresh() -> int { 4 }\n' > $R/url/src/fresh.av
HR "ur: the new file mended" check ur 0
printf '// moved\n' >> $R/ur/src/main.av
UR "ur: the new file is held from its first clean check" "ur/src/main.av "
rm $R/url/src/fresh.av
S "ur: the new file removed" ur
ed $R/ur/src/main.av "$(printf 'use @rt.url.reach.{r, Say, Pt}\nuse @rt.url.lone.{lone}')" 'use @rt.url.reach.{r, Say, Pt}'
ed $R/ur/src/main.av '${r()} ${lone()} ' '${r()} '
printf 'export fn lone() -> int { 3 }\n' > $R/url/src/lone.av
URX "ur: the file that held the impl loses it" "Say" "main.av"

# A HELD SIBLING STANDS ON ITS OWN MODULE. `us` names one file of `@rt/usl`; the
# sibling nothing names implements that file's trait and calls its PRIVATE fn with
# no `use` line — a module is one namespace. Held, it must still dispatch; and a
# signature it leans on, moved in the named file, must refuse at the sibling as a
# cold check does. A const in the named file that starts running the sibling's
# body reads the sibling.
mkdir -p $R/usl/src $R/us/src
printf '[package]\nname = "@rt/usl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-usl"\npath = "src/lib.av"\n' > $R/usl/avra.toml
printf '[package]\nname = "rt-us"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/usl" = { path = "../usl" }\n' > $R/us/avra.toml
printf 'export fn base() -> int { 1 }\n' > $R/usl/src/lib.av
printf 'export trait Say { fn say() -> int }\nexport type Pt = { v: int }\nfn hidden() -> int { 4 }\nexport fn r() -> int { 2 }\n' > $R/usl/src/reach.av
printf 'use reach.{Say, Pt}\nimpl Say for Pt { fn say() -> int { self.v + hidden() } }\nfn seven() -> int { 7 }\n' > $R/usl/src/lone.av
printf 'use @rt.usl.reach.{r, Say, Pt}\nlet s: dyn Say = Pt { v: 1 }\nprintln("${r()} ${s.say()}")\n' > $R/us/src/main.av
up=us
S "cold us" us
HR "us checks clean" check us 0
printf '// moved\n' >> $R/us/src/main.av
UR "us: an entry edit parses the entry alone" "us/src/main.av "
printf '// moved\n' >> $R/us/src/main.av
S "us: the held sibling's impl is dispatched" us
cp $R/usl/src/reach.av $R/usl/reach.kept
ed $R/usl/src/reach.av "fn say() -> int" "fn say() -> string"
URX "us: the trait's answer moved under the held sibling's impl" "say" "lone.av"
cp $R/usl/reach.kept $R/usl/src/reach.av
HR "us: the trait back" check us 0
ed $R/usl/src/reach.av "fn hidden() -> int { 4 }" 'fn hidden() -> string { "4" }'
URX "us: a private fn the held sibling calls with no use changed its answer" "hidden" "lone.av"
cp $R/usl/reach.kept $R/usl/src/reach.av
HR "us: the private fn back" check us 0
ed $R/usl/src/reach.av "fn hidden() -> int { 4 }
" ""
URX "us: a private fn the held sibling calls with no use is gone" "hidden" "lone.av"
cp $R/usl/reach.kept $R/usl/src/reach.av
HR "us: the private fn restored" check us 0
ed $R/usl/src/reach.av "export fn r() -> int { 2 }" "$(printf 'const K: int = seven()\nexport fn r() -> int { K }')"
S "us: a const in the named file starts running the held sibling's body" us
HR "us checks clean after it" check us 0

# A HELD FILE'S ASKS READ BACK WHEN ONE AIMS AT A BUILTIN. An impl over `List<T>`
# asks for an instantiation whose target is the language's own declaration; that
# target's wire names whichever file was first in the process that wrote it, and a
# row that cannot be read back turns the attempt and reads the file on every build.
# `abx` reads the rows `ab` wrote from ANOTHER ENTRY, so the two processes meet
# different first files whatever order a package lists its own.
mkdir -p $R/abl/src $R/ab/src $R/abx/src
printf '[package]\nname = "@rt/abl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-abl"\npath = "src/lib.av"\n' > $R/abl/avra.toml
for p in ab abx; do printf '[package]\nname = "rt-%s"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/abl" = { path = "../abl" }\n' $p > $R/$p/avra.toml; done
printf 'export fn base() -> int { 1 }\n' > $R/abl/src/lib.av
cat > $R/abl/src/shows.av <<'AV'
export trait Show { fn show() -> string }
impl Show for List<T> { fn show() -> string { "list" } }
impl Show for Result<T, E> { fn show() -> string { "result" } }
impl Show for string { fn show() -> string { "text" } }
export type Box<T> = { held: T }
impl Box<T> { fn peek() -> T { self.held } }
export fn shown() -> string {
    let xs: List<int> = [1, 2]
    let ok: Result<int, string> = .Ok(1)
    let b: Box<List<int>> = Box { held: xs }
    xs.show() + " " + ok.show() + " " + "s".show() + " " + b.peek().show()
}
export fn count(m: Map<string, List<int>>) -> int { m.length }
AV
printf 'export fn other() -> int { 1 }\n' > $R/abl/src/other.av
printf 'use @rt.abl.shows.{shown, count}\nuse @rt.abl.other.{other}\nlet m: Map<string, List<int>> = {"a": [1]}\nprintln("${shown()} ${count(m)} ${other()}")\n' > $R/ab/src/main.av
printf 'export fn first() -> int { 0 }\n' > $R/abx/src/aaa.av
printf 'use aaa.{first}\nuse @rt.abl.shows.{shown}\nprintln("${first()} ${shown()}")\n' > $R/abx/src/main.av
AB() { # AB <label> <build|check> <pkg>: no file is read because its asks could not be read back
    steps=$((steps+1)); ab_out=$(./avra $2 --time $R/$3 2>&1)
    case "$ab_out" in *"could not be read back"*) fails=$((fails+1)); echo "FAIL  $1: a held file's asks did not read back: $(printf '%s' "$ab_out" | grep -E '^time:|discarded:|read back' | cut -c1-300 | tr '\n' ' ')" ;; *"held "[1-9]*"/"*) holds=$((holds+1)); [ -n "${VERBOSE:-}" ] && echo "ok    $1" ;; *) fails=$((fails+1)); echo "FAIL  $1: nothing was held, so no asks row was read: $(printf '%s' "$ab_out" | grep -E '^time:' | cut -c1-200)" ;; esac
}
S "cold ab: impls over builtin generics, a scalar, a user generic over one" ab
HR "ab checks clean" check ab 0
ed $R/abl/src/other.av "{ 1 }" "{ 10 }"
HR "ab: an edit elsewhere holds the file whose asks aim at a builtin" check ab 0 shows.av held
ed $R/abl/src/other.av "{ 10 }" "{ 100 }"
AB "ab: a build after an edit elsewhere" build ab
S "ab: the binary after it" ab
HR "abx: another entry checks clean over ab's rows" check abx 0 shows.av held
printf '// moved\n' >> $R/abx/src/aaa.av
AB "abx: a check from another entry" check abx
printf '// moved\n' >> $R/abx/src/aaa.av
AB "abx: a build from another entry" build abx
S "abx: the binary from another entry" abx

# ONE DECLARATION, ONE SPELLING. A builtin's wire names the language, never the file
# a process happened to meet first — so a body edit under impls over builtins leaves
# the module's interface where it was, its importer held, and the same package
# inspected with no entry (`avra explain --why`) sees no interface moved. And
# an impl over a builtin that an importer dispatches through, in a file the importer
# never names, is still the importer's: removed, the warm check refuses as a cold one.
mkdir -p $R/bwl/src $R/bw/src
printf '[package]\nname = "@rt/bwl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-bwl"\npath = "src/lib.av"\n' > $R/bwl/avra.toml
printf '[package]\nname = "rt-bw"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/bwl" = { path = "../bwl" }\n' > $R/bw/avra.toml
printf 'export fn base() -> int { 1 }\n' > $R/bwl/src/lib.av
printf 'export trait Show { fn show() -> string }\nimpl Show for List<T> { fn show() -> string { "list" } }\nimpl Show for string { fn show() -> string { "text" } }\nexport fn shown() -> string {\n    let xs: List<int> = [1]\n    xs.show() + "s".show()\n}\n' > $R/bwl/src/shows.av
printf 'use @rt.bwl.shows.{shown}\nexport fn used() -> string { shown() }\n' > $R/bw/src/user.av
printf 'use user.{used}\nprintln(used())\n' > $R/bw/src/main.av
HR "cold bw" check bw 0
ed $R/bwl/src/shows.av '"list"' '"lst"'
HR "bw: a body edit under impls over builtins holds the importer" check bw 0 user.av held
ed $R/bwl/src/shows.av '"lst"' '"l"'
HR "bw: and again" check bw 0 user.av held
steps=$((steps+1)); bw_moved=$( (cd $R/bw && "$tree/avra" explain --why 2>&1) | grep -c 'moved module')
[ "$bw_moved" -eq 0 ] || { fails=$((fails+1)); echo "FAIL  bw: inspected with no entry, $bw_moved interfaces read as moved since the entry's own check"; }
mkdir -p $R/bil/src $R/bi/src
printf '[package]\nname = "@rt/bil"\nversion = "0.1.0"\n\n[lib]\nname = "rt-bil"\npath = "src/lib.av"\n' > $R/bil/avra.toml
printf '[package]\nname = "rt-bi"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/bil" = { path = "../bil" }\n' > $R/bi/avra.toml
printf 'export fn base() -> int { 1 }\n' > $R/bil/src/lib.av
printf 'export trait Tell { fn tell() -> string }\n' > $R/bil/src/tell.av
printf 'use tell.{Tell}\nimpl Tell for List<T> { fn tell() -> string { "list" } }\nexport fn pad() -> int { 0 }\n' > $R/bil/src/list_tell.av
printf 'export fn other() -> int { 1 }\n' > $R/bi/src/other.av
printf 'use @rt.bil.tell.{Tell}\nuse other.{other}\nlet xs: List<int> = [1]\nprintln("${xs.tell()} ${other()}")\n' > $R/bi/src/main.av
S "cold bi: an impl over a builtin in a file the app never names" bi
HR "bi checks clean" check bi 0
ed $R/bi/src/other.av "{ 1 }" "{ 2 }"
HR "bi: an edit elsewhere checks clean" check bi 0
printf 'export fn pad() -> int { 0 }\n' > $R/bil/src/list_tell.av
steps=$((steps+1)); bi_out=$(./avra check $R/bi 2>&1); bi_st=$?
case "$bi_st:$bi_out" in 1:*"tell"*) [ -n "${VERBOSE:-}" ] && echo "ok    bi: the impl gone -> refused" ;; *) fails=$((fails+1)); echo "FAIL  bi: the impl over List is gone and the warm check did not refuse the call (exit $bi_st): $(printf '%s' "$bi_out" | grep -vE '^watch:' | head -3 | tr '\n' ' ')" ;; esac

# A FILE IS HELD ONLY WHILE EVERY INPUT ITS COMPILE-TIME RUNS READ STANDS. `ke`'s TEXT is
# an `embed` of a text file beside the file that declares it. The embedded text is
# edited and nothing else: the declaring file's own text never moves, so a hold that
# stands on its text alone keeps the const's old value — in the binary, with the key
# missing and a derivation running. The file must be read again, in a check and in a
# build, twice over, and with another file edited first so the declaring file is held;
# a const derived from the embedded text moves with it.
mkdir -p $R/ke/src/f
printf '[package]\nname = "rt-ke"\nversion = "0.1.0"\n' > $R/ke/avra.toml
printf 'one' > $R/ke/src/f/data.txt
printf 'use @std.meta.{embed}\nexport const TEXT: string = embed("data.txt")\nexport const N: int = TEXT.length\nexport fn shown() -> string { "${TEXT} n=${N}" }\n' > $R/ke/src/f/held.av
printf 'use f.{shown}\nprintln("text=${shown()}")\n' > $R/ke/src/main.av
ke_says() { # ke_says <label> <wanted>: the built binary prints the embedded text as it stands
    steps=$((steps+1)); ke_out=$($R/ke/src/main 2>&1)
    [ "$ke_out" = "text=$2" ] || { fails=$((fails+1)); echo "FAIL  ke: $1: the binary printed '$ke_out', wanted 'text=$2'"; }
}
S "cold ke" ke; ke_says "cold" "one n=3"
printf '// moved\n' >> $R/ke/src/main.av
S "ke: an edit elsewhere, held.av held" ke; ke_says "an edit elsewhere" "one n=3"
printf 'two' > $R/ke/src/f/data.txt
HR "ke: the embedded text moved -> its file is read, not held" check ke 0 "f/held.av" read
S "ke: and the binary follows the embedded text" ke; ke_says "the embedded text moved under a held file" "two n=3"
printf 'three' > $R/ke/src/f/data.txt
S "ke: moved again, nothing else touched" ke; ke_says "the embedded text moved again" "three n=5"
S "ke: no-op after it" ke; ke_says "a no-op build" "three n=5"
printf 'fourth' > $R/ke/src/f/data.txt
HR "ke: moved a third time -> a check reads its file with no build between" check ke 0 "f/held.av" read
S "ke: and the const derived from it follows" ke; ke_says "a derived const after a check" "fourth n=6"
# A TEXT A RUN READ THAT THE HOST WILL NO LONGER GIVE IS A DIFFERENT ANSWER, NEVER THE END OF
# THE RUN. The file's record names the embedded text, so the next key reads it again:
# turned to octets that are no text, to a directory, or gone, a check and a build each
# refuse in the embed law's own words, exit 1 — no host's refusal, no trap, and no build
# that succeeds on the text that stood before.
ke_refuses() { # ke_refuses <label> <the law's words>
    for ke_verb in check build; do
        steps=$((steps+1)); ke_out=$(./avra $ke_verb $R/ke 2>&1 | unwatched)
        case "$ke_out" in *"error[type.embed_file]"*"$2"*) [ -n "${VERBOSE:-}" ] && echo "ok    ke: $1 -> $ke_verb refuses" ;; *) fails=$((fails+1)); echo "FAIL  ke: $1: $ke_verb did not refuse in the embed law's words ('$2'): $(printf '%s' "$ke_out" | grep -vE '^watch:|^time:' | head -2 | tr '\n' ' ' | cut -c1-220)" ;; esac
    done
}
mv $R/ke/src/f/data.txt $R/ke/src/f/data.was; printf '\377\376' > $R/ke/src/f/data.txt
ke_refuses "the embedded text turned into octets that are no text" "is not UTF-8"
mv $R/ke/src/f/data.txt $R/ke/src/f/data.octets; mkdir $R/ke/src/f/data.txt
ke_refuses "the embedded text turned into a directory" "could not read its file"
mv $R/ke/src/f/data.txt $R/ke/src/f/data.dir
ke_refuses "the embedded text is gone" "finds no"
printf 'back' > $R/ke/src/f/data.txt
S "ke: the text stands again" ke; ke_says "the embedded text back" "back n=4"

# AN EMBED REACHED THROUGH A HELD FILE IS NO FILE MINTED MID-QUERY. `kw`'s const runs fns
# that `util.av` declares, and the `embed` literals stand in their bodies. Only main.av
# is edited, so `util.av` is held and its literals are never scanned: the embedded texts
# are first met inside the const's own settlement. A warm build and a warm test must run,
# and the binary print the embedded texts, never trap on a row written after it was read.
# THEN THE KEY ALONE: an embedded text edited while every source is held moves the
# program's key through the records' runs — one named `a|b.txt` too, whose name holds
# the character a record once spent between runs.
mkdir -p $R/kw/src/tests
printf '[package]\nname = "rt-kw"\nversion = "0.1.0"\n' > $R/kw/avra.toml
printf 'b' > $R/kw/src/b.txt
printf 'p' > "$R/kw/src/a|b.txt"
printf 'use @std.meta.{embed}\nexport fn g() -> string { embed("b.txt") }\nexport fn h() -> string { embed("a|b.txt") }\n' > $R/kw/src/util.av
printf 'use util.{g, h}\nconst B: string = g()\nconst P: string = h()\nprintln("b=${B} p=${P}")\n' > $R/kw/src/main.av
printf 'use util.{g}\nconst T: string = g()\nspec "kw" { then "reads the embed" { T == "b" } }\n' > $R/kw/src/tests/kw_test.av
kw_tested() { # kw_tested <label>: the package's tests run and pass
    steps=$((steps+1)); out=$(./avra test $R/kw 2>&1); st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  kw: $1: test exit $st"; printf '%s\n' "$out" | failed_words; }
}
kw_says() { # kw_says <label> <wanted>: the built binary prints the embedded texts as they stand
    steps=$((steps+1)); kw_out=$($R/kw/src/main 2>&1)
    [ "$kw_out" = "$2" ] || { fails=$((fails+1)); echo "FAIL  kw: $1: the binary printed '$kw_out', wanted '$2'"; }
}
S "cold kw" kw; kw_says "cold" "b=b p=p"; kw_tested "cold"
printf '// moved\n' >> $R/kw/src/main.av
S "kw: main.av edited, util.av held" kw; kw_says "main.av edited" "b=b p=p"
printf '// moved\n' >> $R/kw/src/tests/kw_test.av
kw_tested "the test file edited, util.av held"
S "kw: no-op, every source held" kw; kw_says "a no-op build" "b=b p=p"
printf 'b2' > $R/kw/src/b.txt
S "kw: b.txt edited, every source held" kw; kw_says "b.txt edited under held sources" "b=b2 p=p"
printf 'p2' > "$R/kw/src/a|b.txt"
S "kw: a|b.txt edited, every source held" kw; kw_says "a|b.txt edited under held sources" "b=b2 p=p2"

# A COLLECT GATHERS WHAT ITS SCOPE HOLDS NOW, HELD OR NOT. `kg` depends on `@rt/gk`, whose
# c/lib.av collects every `@kind` in its package, in a module of its own; its members stand in files nothing imports, so
# only the collect reaches them, and the mark they wear is declared in a file of its own, so a
# member's compile-time run never reads the collecting file. A member is added, removed, a member file added and deleted —
# each edit touching no file the collect stands in, so lib.av is held — and A's ordinal follows
# every time. The root package's own `in package` collect follows the same edits, and `@rt/kc`'s
# `in closure` list stands with no package collect beside it. After every step a held reading
# answers what a fresh one does (`--verify-held`), and the evaluator agrees with the binary.
mkdir -p $R/gk/src/m $R/gk/src/c $R/kc/src/z $R/kg/src/m
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $R/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $R/gk/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $R/gk/src/c/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $R/gk/src/m/m.av
printf '[package]\nname = "@rt/kc"\nversion = "0.1.0"\n' > $R/kc/avra.toml
printf 'use @std.meta.{Named}\nexport fn mark(_t: Named) {}\n' > $R/kc/src/mk.av
printf 'use mk.{mark}\ntype Entry = { name: string }\ncollect near: List<Entry> = @mark in closure as Entry { name: it.name } by it.name\nexport fn c_at() -> int { near.length }\n' > $R/kc/src/kc.av
printf 'use mk.{mark}\n@mark\nexport type Z = {}\n' > $R/kc/src/z/z.av
printf '[package]\nname = "rt-kg"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n"@rt/kc" = { path = "../kc" }\n' > $R/kg/avra.toml
printf 'use @std.meta.{Named}\nexport fn rank(_t: Named, _r: int) {}\n' > $R/kg/src/rm.av
printf 'use rm.{rank}\nexport collect enum Rk = @rank in package by it.mark.args[0]\nexport fn r_at() -> int { Rk.P.ordinal }\n' > $R/kg/src/rk.av
printf 'use rm.{rank}\n@rank(5)\nexport type P = {}\n' > $R/kg/src/m/m.av
printf 'use @rt.gk.c.{a_at}\nuse @rt.kc.kc.{c_at}\nuse rk.{r_at}\nprintln("a=${a_at()} r=${r_at()} c=${c_at()}")\n' > $R/kg/src/main.av
kg_step() { # kg_step <label> <wanted a=… r=…>: built, the binary agrees with the evaluator and prints it, a held reading agrees with a fresh one
    S "kg: $1" kg
    steps=$((steps+1)); kg_out=$($R/kg/src/main 2>&1)
    case "$kg_out" in "$2 c="*) ;; *) fails=$((fails+1)); echo "FAIL  kg: $1: the binary printed '$kg_out', wanted '$2 c=…'" ;; esac
    steps=$((steps+1)); kg_v=$(./avra check --verify-held $R/kg 2>&1); kg_st=$?
    [ $kg_st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  kg: $1: --verify-held exit $kg_st: $(printf '%s' "$kg_v" | grep -aE 'held=|verify-held:|^avra:' | head -3 | tr '\n' ' ' | cut -c1-260)"; }
}
kg_step "cold" "a=0 r=0"
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\n' > $R/gk/src/m/m.av
kg_step "a member added in the dependency, lib.av held" "a=1 r=0"
printf 'use k.{kind}\n// B removed\n@kind(5)\nexport type A = {}\n' > $R/gk/src/m/m.av
kg_step "the member removed" "a=0 r=0"
# a member file in a module of its own: no key of lib.av reaches it, so what it gathers is
# the first reason lib.av is read
mkdir -p $R/gk/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $R/gk/src/n/n.av
kg_step "a member file added in a module of its own" "a=1 r=0"
rm -rf $R/gk/src/n
printf 'use k.{kind}\n// n removed\n@kind(5)\nexport type A = {}\n' > $R/gk/src/m/m.av
kg_step "the member file deleted, another edited beside it" "a=0 r=0"
printf 'use rm.{rank}\n@rank(5)\nexport type P = {}\n@rank(1)\nexport type Q = {}\n' > $R/kg/src/m/m.av
kg_step "a member added to the root's own collect, rk.av held" "a=0 r=1"
printf 'use rm.{rank}\n// Q removed\n@rank(5)\nexport type P = {}\n' > $R/kg/src/m/m.av
kg_step "the root's member removed" "a=0 r=0"
printf 'use mk.{mark}\n@mark\nexport type Z = {}\n@mark\nexport type Y = {}\n' > $R/kc/src/z/z.av
kg_step "an exported member added where only a closure list could gather it" "a=0 r=0"

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

# AND A COLLECTOR IS HELD TO THE SET IT GATHERED, never to its package's bytes. In a store of
# its own, so no other attack's history decides which reason a read is given first: a member's
# BODY edit leaves the set and holds the collector; two members swapping their marks' arguments
# move it; a member module added under a collector in a module of its own reaches no key of it,
# so what it gathers is the first reason it is read.
gw=$(mktemp -d); mkdir -p $gw/gk/src/m $gw/gk/src/c $gw/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $gw/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $gw/gk/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $gw/gk/src/c/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\nexport fn help() -> int { 1 }\n' > $gw/gk/src/m/m.av
printf '[package]\nname = "rt-gw"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $gw/app/avra.toml
printf 'use @rt.gk.c.{a_at}\nprintln("a=${a_at()}")\n' > $gw/app/src/main.av
gw_step() { # gw_step <label> <wanted a=…> <collector read: yes|no>
    steps=$((steps+1)); gw_out=$(./avra build --time $gw/app 2>&1)
    gw_got=$($gw/app/src/main 2>&1)
    [ "$gw_got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  gw: $1: the binary printed '$gw_got', wanted '$2'"; }
    case "$gw_out" in *"gk/src/c/lib.av — what its collect gathers"*) gw_read=yes ;; *) gw_read=no ;; esac
    [ "$gw_read" = "$3" ] || { fails=$((fails+1)); echo "FAIL  gw: $1: lib.av read for what it gathers: $gw_read, wanted $3: $(printf '%s' "$gw_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-240)"; }
}
gw_step "cold" "a=1" no
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\nexport fn help() -> int { 2 }\n' > $gw/gk/src/m/m.av
gw_step "a member's file edited, its marks and shapes unmoved" "a=1" no
printf 'use k.{kind}\n@kind(1)\nexport type A = {}\n@kind(5)\nexport type B = {}\nexport fn help() -> int { 2 }\n' > $gw/gk/src/m/m.av
steps=$((steps+1)); ./avra build $gw/app > /dev/null 2>&1; gw_got=$($gw/app/src/main 2>&1)
[ "$gw_got" = "a=0" ] || { fails=$((fails+1)); echo "FAIL  gw: two members swap their marks' arguments: the binary printed '$gw_got', wanted 'a=0'"; }
mkdir -p $gw/gk/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $gw/gk/src/n/n.av
gw_step "a member module added under the collector" "a=1" yes
rm -rf $gw

# A LIST COLLECT'S TIE IS ORDERED BY QUALIFIED NAME, never by the order files were read in: two
# members whose `by` keys tie, in p/ and q/, and p/ moved to z/ — the move moves the order
# (z.X now after q.Y), and a warm build answers as a fresh one.
gt=$(mktemp -d); mkdir -p $gt/gk/src/c $gt/gk/src/p $gt/gk/src/q $gt/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $gt/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn seq(_t: Named, _rank: int) {}\n' > $gt/gk/src/k.av
printf 'use k.{seq}\ntype Entry = { name: string }\ncollect xs: List<Entry> = @seq in package as Entry { name: it.name } by it.mark.args[0]\nexport fn x_at() -> int { [e.name for e in xs].index_of("X") }\n' > $gt/gk/src/c/lib.av
printf 'use k.{seq}\n@seq(0)\nexport type X = {}\n' > $gt/gk/src/p/p.av
printf 'use k.{seq}\n@seq(0)\nexport type Y = {}\n' > $gt/gk/src/q/q.av
printf '[package]\nname = "rt-gt"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $gt/app/avra.toml
printf 'use @rt.gk.c.{x_at}\nprintln("x=${x_at()}")\n' > $gt/app/src/main.av
steps=$((steps+1)); ./avra build $gt/app > /dev/null 2>&1; gt_cold=$($gt/app/src/main 2>&1)
mkdir -p $gt/gk/src/z; mv $gt/gk/src/p/p.av $gt/gk/src/z/z.av; rmdir $gt/gk/src/p
steps=$((steps+1)); ./avra build $gt/app > /dev/null 2>&1; gt_warm=$($gt/app/src/main 2>&1)
rm -rf $gt/app/.avra-cache
steps=$((steps+1)); ./avra build $gt/app > /dev/null 2>&1; gt_fresh=$($gt/app/src/main 2>&1)
[ "$gt_cold" = "x=0" ] && [ "$gt_warm" = "x=1" ] && [ "$gt_fresh" = "x=1" ] || { fails=$((fails+1)); echo "FAIL  gt: a list collect's tie: cold '$gt_cold' (wanted x=0), warm '$gt_warm' and fresh '$gt_fresh' after the move (both wanted x=1)"; }
rm -rf $gt

# AND ORDER IS PART OF THE SET: a list's members whose `by` keys tie are gathered in their own
# order, so two member files whose order flips change what the collector gathered, with no
# member's print moved — and the collector is read for it.
go=$(mktemp -d); mkdir -p $go/gk/src/c $go/gk/src/p $go/gk/src/q $go/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $go/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn seq(_t: Named, _rank: int) {}\n' > $go/gk/src/k.av
printf 'use k.{seq}\ntype Entry = { name: string }\ncollect xs: List<Entry> = @seq in package as Entry { name: it.name } by it.mark.args[0]\nexport fn x_at() -> int { [e.name for e in xs].index_of("X") }\n' > $go/gk/src/c/lib.av
printf 'use k.{seq}\n@seq(0)\nexport type X = {}\n' > $go/gk/src/p/p.av
printf 'use k.{seq}\n@seq(0)\nexport type Y = {}\n' > $go/gk/src/q/q.av
printf '[package]\nname = "rt-go"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $go/app/avra.toml
printf 'use @rt.gk.c.{x_at}\nprintln("x=${x_at()}")\n' > $go/app/src/main.av
steps=$((steps+1)); ./avra build $go/app > /dev/null 2>&1
mkdir -p $go/gk/src/z; mv $go/gk/src/p/p.av $go/gk/src/z/z.av; rmdir $go/gk/src/p
steps=$((steps+1)); go_out=$(./avra build --time $go/app 2>&1)
case "$go_out" in *"gk/src/c/lib.av — what its collect gathers"*) ;; *) fails=$((fails+1)); echo "FAIL  go: member files whose order flipped: lib.av was not read for what it gathers: $(printf '%s' "$go_out" | sed -n '/^read:/,$p' | tr '\n' ' ' | cut -c1-240)" ;; esac
printf '// again\n' >> $go/app/src/main.av
steps=$((steps+1)); go_again=$(./avra build --time $go/app 2>&1)
case "$go_again" in *"gk/src/c/lib.av — what its collect gathers"*) fails=$((fails+1)); echo "FAIL  go: the next build read lib.av for what it gathers again — a held collector must stand on the set it was read for" ;; esac
rm -rf $go

# AND A COLLECTOR IS HELD TO WHAT IT BAKES OF EACH MEMBER, not only to the members' names and
# shapes: a list projecting a member's module, its doc and the member itself as a fn value. A
# member moved to another module and a member's `///` edited each move what the held
# collector's object holds, so each must be read again — in a store of its own.
gm=$(mktemp -d); mkdir -p $gm/gk/src/c $gm/gk/src/p $gm/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $gm/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn seq(_t: Named, _rank: int) {}\n' > $gm/gk/src/k.av
printf 'use k.{seq}\ntype Entry = { name: string, module: string, doc: string, call: fn() -> int }\ncollect xs: List<Entry> = @seq in package as Entry { name: it.name, module: it.module, doc: it.doc, call: it } by it.mark.args[0]\nexport fn shown() -> string { "${xs[0].module} ${xs[0].doc} ${xs[0].call()}" }\n' > $gm/gk/src/c/lib.av
printf 'use k.{seq}\n/// one\n@seq(5)\nexport fn uno() -> int { 1 }\n' > $gm/gk/src/p/p.av
printf '[package]\nname = "rt-gm"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $gm/app/avra.toml
printf 'use @rt.gk.c.{shown}\nprintln(shown())\n' > $gm/app/src/main.av
gm_step() { # gm_step <label> <wanted>
    steps=$((steps+1)); gm_out=$(./avra build $gm/app 2>&1); gm_got=$($gm/app/src/main 2>&1)
    [ "$gm_got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  gm: $1: the binary printed '$gm_got', wanted '$2': $(printf '%s' "$gm_out" | grep -aE '^error|^avra:' | head -2 | tr '\n' ' ' | cut -c1-200)"; }
}
gm_step "cold" "p one 1"
mkdir -p $gm/gk/src/z; mv $gm/gk/src/p/p.av $gm/gk/src/z/z.av; rmdir $gm/gk/src/p
gm_step "the member moved to another module" "z one 1"
printf 'use k.{seq}\n/// uno\n@seq(5)\nexport fn uno() -> int { 1 }\n' > $gm/gk/src/z/z.av
gm_step "the member's doc edited" "z uno 1"
rm -rf $gm

# A BUILD'S BYTES ARE ITS SOURCE'S ALONE. A check leaves records and no objects, so
# the build after it reads every file again — met through those records, in another
# order than a cold build meets them. The binary must be the cold one's, byte for
# byte. The store is cleared for each side: it is the one thing that differs. The
# program is the tree's own soak driver — a fixture of a few files meets its files
# in one order either way and attacks nothing.
eo=packages/std-http-soak
eo_built() { # eo_built <label>: the program built, its binary kept under the label
    out=$(./avra build $eo 2>/dev/null); bin=$(printf '%s\n' "$out" | tail -1)
    if [ -x "$bin" ]; then cp "$bin" $R/eo.$1; rm -f "$bin" "$bin.av.ll"; fi
}
steps=$((steps+1)); rm -rf .avra-cache $R/eo.cold $R/eo.warm; eo_built cold
steps=$((steps+1)); rm -rf .avra-cache; ./avra check $eo >/dev/null 2>&1; eo_built warm
if [ -s $R/eo.cold ] && [ -s $R/eo.warm ] && cmp -s $R/eo.cold $R/eo.warm; then [ -n "${VERBOSE:-}" ] && echo "ok    eo: a build after a check is the cold build's bytes"; else fails=$((fails+1)); echo "FAIL  eo: $eo built after a check differs from its cold build in $(cmp -l $R/eo.cold $R/eo.warm 2>/dev/null | wc -l | tr -d ' ') bytes (0 means one side did not build)"; fi

echo "cache-attacks: $steps builds through one store, $holds under a hold, $fails failed"
# A RUN THAT NEVER HELD ATTACKED NOTHING: every step above is green on the no-hold path.
[ "$holds" -gt 0 ] || { echo "cache-attacks: no step ran under a hold — the attacks examined nothing"; exit 1; }
[ "$fails" -eq 0 ]

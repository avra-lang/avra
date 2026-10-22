#!/bin/sh
# A DECLARATION ADDED TO A FILE MOVES ONLY WHAT CAN OBSERVE IT. Files in a module see each
# other's names; an importer sees the names it imports. A file's hold stands on the NAMES it
# mentions, so an added fn nobody mentions reads no other file, while a name a file already
# resolved (prelude, import, sibling), a rename, a name that was undefined, a method added to a
# type and a private name two files keep apart each move exactly the files that mention them —
# and every answer is held to what the program says, never to the hold's own report.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0

R=build/fn-add
T=build/aside/fa.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/fn-add
[ -e .avra-cache ] && mv .avra-cache $T/cache
P=$R/fa
mkdir -p $P/src/m/tests $P/src/n $P/src/w
who=fn-add-attack
. tools/lib/steps.sh
printf '[package]\nname = "fa"\nversion = "0.1.0"\n' > $P/avra.toml
printf 'export fn f() -> int { 1 }\nfn p() -> int { 2 }\nexport type T = { n: int }\n' > $P/src/m/a.av
printf 'export fn gb() -> int { f() + 1 }\n' > $P/src/m/b.av
printf 'export fn gc() -> int {\n    println("c")\n    10\n}\n' > $P/src/m/c.av
printf 'use m.{f}\nexport fn gu() -> int { f() * 2 }\n' > $P/src/n/user.av
printf 'use m.{gc, f}\nexport fn go() -> int { gc() + f() }\n' > $P/src/n/other.av
printf 'export fn gt() -> int { 3 }\n' > $P/src/n/third.av
printf 'export component widget {\n    run: fn(int) -> int\n}\n' > $P/src/w/widget.av
printf 'export widget one { n -> n + 1 }\nexport widget two { n -> n + 2 }\n' > $P/src/w/members.av
printf 'type Entry = { name: string, ran: fn(int) -> int }\nexport collect entries: List<Entry> = widget in closure as Entry { name: it.name, ran: it.run } by it.name\n' > $P/src/w/table.av
printf 'use w.{entries}\nexport fn gcount() -> int { entries.length }\n' > $P/src/n/count.av
printf 'use n.{gu, go, gcount}\nuse m.{gb}\nprintln("${gu()} ${go()} ${gb()} ${gcount()}")\n' > $P/src/main.av
for f in m/a m/b m/c n/user n/other n/third n/count w/widget w/members w/table main; do cp $P/src/$f.av $P/$(echo $f | tr / _).orig; done

chk() { steps=$((steps + 1)); OUT=$(./avra check --time $P 2>&1); ST=$?; }
back() { for f in m/a m/b m/c n/user n/other n/third n/count w/widget w/members w/table main; do cp $P/$(echo $f | tr / _).orig $P/src/$f.av; done; for t in $P/src/m/tests/*.av; do [ -e "$t" ] && mv "$t" $T/; done; }
add() { printf '\n%s\n' "$2" >> $P/src/$1.av; }
read_list() { printf '%s\n' "$OUT" | sed -n '/^read:/,$p' | grep '^  ' | awk '{print $1}'; }

not_read() { l=$1; shift; for f in "$@"; do read_list | grep -q "$f" && fail "$l: $f was read"; done; }
was_read() { l=$1; shift; for f in "$@"; do read_list | grep -q "$f" || fail "$l: $f was not read ($(read_list | tr '\n' ' '))"; done; }
no_discard() { case "$OUT" in *"discarded 0,"*) ;; *) fail "$1: an attempt was thrown away: $(printf '%s' "$OUT" | grep -E '^time:' | cut -c1-200)" ;; esac; }
ran() { steps=$((steps + 1)); ./avra run $P 2>&1 | grep -v '^watch:' | tr '\n' ' '; }

chk; [ $ST = 0 ] || { fail "the fixture does not check: $OUT"; exit 1; }
BASE=$(ran)
[ "$BASE" = "c 2 c 11 2 " ] || [ "$BASE" = "c c 2 11 2 " ] || echo "note  baseline prints: $BASE"

# 1. an unreferenced private fn: nobody else reads
chk; add m/a 'fn zz_private() -> int { 9 }'; chk
[ $ST = 0 ] || fail "private add: refused: $OUT"
not_read "an unreferenced private fn" m/b.av m/c.av n/user.av n/other.av n/third.av; no_discard "an unreferenced private fn"
back; chk

# 2. an unreferenced exported fn: importers that do not name it stay held
add m/a 'export fn zz_exported() -> int { 9 }'; chk
[ $ST = 0 ] || fail "exported add: refused: $OUT"
not_read "an unreferenced exported fn" m/b.av m/c.av n/user.av n/other.av n/third.av; no_discard "an unreferenced exported fn"
back; chk

# 3. a name a sibling already resolved to the PRELUDE: the sibling is read and the answer changes
add m/a 'fn println(s: string) {}'; chk
was_read "a fn shadowing the prelude's println" m/c.av
[ "$(ran)" != "$BASE" ] || fail "a fn shadowing println left the program's output unchanged: $BASE"
back; chk

# 4. a name a sibling already IMPORTED: the importer is read, and the collision is said or the answer moves
add n/third 'fn f() -> int { 7 }'; chk
was_read "a fn colliding with a sibling's import" n/other.av
[ "$ST" != 0 ] || [ "$(ran)" = "$BASE" ] || fail "a fn named like a sibling's import moved the output: the import must win"
back; chk

# 5. a rename: its users are read, and the program no longer checks
sed 's/export fn f()/export fn f2()/' $P/src/m/a.av > $T/a.new && mv $T/a.new $P/src/m/a.av; chk
[ $ST != 0 ] || fail "a renamed fn left its users checking clean"
case "$OUT" in *"f"*) ;; *) fail "a renamed fn: the refusal names nothing" ;; esac
back; chk

# 6. a name that was undefined: the refusal goes
printf 'export fn gb() -> int { later() }\n' > $P/src/m/b.av; chk
[ $ST != 0 ] || fail "an undefined name checked clean"
add m/a 'export fn later() -> int { 4 }'; chk
[ $ST = 0 ] || fail "a name defined later is still refused: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
back; chk

# 7. a method added to a type: the file that called it re-checks
printf 'export fn gb() -> int {\n    let t = T { n: 1 }\n    t.go()\n}\n' > $P/src/m/b.av; chk
[ $ST != 0 ] || fail "a missing method checked clean"
add m/a 'impl T {
    fn go() -> int { self.n }
}'; chk
[ $ST = 0 ] || fail "a method added to its type is still refused: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
back; chk

# 8. a private name two files keep apart: a third file reading it is refused; with one declaration gone it resolves
add m/a 'fn helper() -> int { 1 }'
printf 'export fn gb() -> int { f() + 1 }\nfn helper() -> int { 2 }\n' > $P/src/m/b.av
printf 'export fn gc() -> int {\n    println("c")\n    helper()\n}\n' > $P/src/m/c.av; chk
[ $ST != 0 ] || fail "a private name kept by two files resolved for a third"
printf 'export fn f() -> int { 1 }\nfn p() -> int { 2 }\nexport type T = { n: int }\n' > $P/src/m/a.av; chk
[ $ST = 0 ] || fail "a private name kept by one file is refused for its sibling: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
back; chk

# 9. a test file reading a private name of its module by an explicit use
printf 'use m.{p}\nspec "p" { given "the private fn" { then "answers two" { p() == 2 } } }\n' > $P/src/m/tests/priv_test.av; chk
[ $ST = 0 ] || fail "a test could not read its module's private name: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
sed 's/^fn p()/fn q()/' $P/src/m/a.av > $T/a.new && mv $T/a.new $P/src/m/a.av; chk
[ $ST != 0 ] || fail "a renamed private fn left the test that read it checking clean"
back; chk

# 10. an unrelated fn beside a collect's members moves neither the table nor its reader; a member added to a
# collect gives the table's reader the new answer
# one build beside the members first, so the check's own rule findings are kept before the steady state is judged
add w/members 'fn zz_prime() -> int { 3 }'; chk
back; chk
add w/members 'fn zz_beside_members() -> int { 1 }'; chk
not_read "an unrelated fn beside a collect's members" n/count.av w/table.av; no_discard "an unrelated fn beside a collect's members"
back; chk
add w/members 'export widget three { n -> n + 3 }'; chk
[ $ST = 0 ] || fail "a member added to a collect is refused: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
case "$(ran)" in *" 3 "*) ;; *) fail "a member added to a collect left the count unchanged: $(ran)" ;; esac
back; chk
# a held collector is held to the set its record last read, and a revert to an older member set is a cache hit
# that leaves the newer set's record standing: one build that reads the collector writes the current one
add w/members 'fn zz_settle() -> int { 2 }'; chk
back; chk

# 11. a const settled from a fn: an fn added beside it that nothing spells leaves its verdict standing; one it spells re-runs it
printf 'export fn gt() -> int { 3 }\nexport const k3: int = gt() * 2\nexport fn gk() -> int { k3 }\n' > $P/src/n/third.av
verdict() { AVRA_QTRACE=1 ./avra check $P 2>&1 | grep "const_verdict" | awk '{print $NF}' | sort -u | tr '\n' ' '; }
chk; steps=$((steps + 1))
add n/third 'fn zz_beside_const() -> int { 1 }'
[ "$(verdict)" = "stood " ] || fail "an unspelled fn added beside a const re-ran its verdict"
printf 'export fn gt() -> int { 3 }\nexport const k3: int = gt() * 2\nexport fn gk() -> int { k3 }\nfn zz_beside_const() -> int { 1 }\nexport fn gz() -> int { zz_beside_const() }\n' > $P/src/n/third.av
case "$(verdict)" in *ran*) ;; *) fail "a fn the file now spells did not re-run the const verdict" ;; esac
back; chk

# 12. the narrowed names digest: what it must NOT miss. A verdict is read as "stood"/"ran" per const.
VOUT=
vstate() { VOUT=$(AVRA_QTRACE=1 ./avra check $P 2>&1); V=$(printf '%s\n' "$VOUT" | grep "const_verdict" | grep "m.c.const" | awk '{print $NF}' | sort -u | tr '\n' ' '); }
# a) a fn that SHADOWS the prelude's println in the module a const's run resolves through
printf 'export fn gc() -> int {\n    println("c")\n    10\n}\nexport const kc: int = gc() + 1\nexport fn gk() -> int { kc }\n' > $P/src/m/c.av; chk; steps=$((steps + 1))
add m/a 'fn println(s: string) {}'
vstate
case "$V" in *ran*) ;; *) fail "a fn shadowing println left a const verdict standing: [$V] $(printf '%s' "$VOUT" | grep -v '^Q' | head -4 | tr '\n' ' ' | cut -c1-500)" ;; esac
back; chk
# b) a name only a comment of the const's file spells: counted (tokens read comments), which only widens
printf 'export fn gc() -> int { 10 }\n// zz_commented\nexport const kc: int = gc() + 1\nexport fn gk() -> int { kc }\n' > $P/src/m/c.av; chk; steps=$((steps + 1))
add m/a 'fn zz_commented() -> int { 1 }'
vstate; case "$V" in *stood*|*ran*) ;; *) fail "a fn named in a comment: no verdict read" ;; esac
back; chk
# c) a module holding generated code: every name counts, so even an unspelled fn re-runs the verdict
printf 'use @std.meta.{Directive, Type}\nexport trait Gen {\n    static fn derive(t: Type) -> List<Directive> {\n        [Directive { twin: "", name: t.name, at: t.at, source: quote { fn gen_made() -> int { 1 } } }]\n    }\n}\n' > $P/src/m/gen.av
printf 'use @std.meta.{derive}\nuse m.{Gen}\n@derive(Gen)\nexport type G = { n: int }\n' > $P/src/m/g.av
printf 'export fn gc() -> int { 10 }\nexport const kc: int = gc() + 1\nexport fn gk() -> int { kc }\n' > $P/src/m/c.av; chk; steps=$((steps + 1))
[ $ST = 0 ] || fail "the generated-code fixture does not check: $(printf '%s' "$OUT" | head -3 | tr '\n' ' ')"
add m/a 'fn zz_unspelled() -> int { 1 }'
vstate
case "$V" in *stood*) fail "a fn added beside generated code left a const verdict standing: [$V]" ;; esac
mv $P/src/m/gen.av $P/src/m/g.av $T/; back; chk
# d) a rename of a spelled fn: the const that calls it re-runs, and the program no longer checks
printf 'export fn gc() -> int { f() }\nexport const kc: int = gc() + 1\nexport fn gk() -> int { kc }\n' > $P/src/m/c.av; chk; steps=$((steps + 1))
sed 's/export fn f()/export fn f2()/' $P/src/m/a.av > $T/a.new && mv $T/a.new $P/src/m/a.av
vstate; [ "$V" != "stood " ] || fail "a renamed fn left the verdict of a const calling it standing"
back; chk

verdict

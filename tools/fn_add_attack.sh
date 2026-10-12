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

R=build/fn-add; fails=0; steps=0
rm -rf "$R" .avra-cache
P=$R/fa
mkdir -p $P/src/m/tests $P/src/n
fail() { fails=$((fails + 1)); echo "FAIL  $1"; }
printf '[package]\nname = "fa"\nversion = "0.1.0"\n' > $P/avra.toml
printf 'export fn f() -> int { 1 }\nfn p() -> int { 2 }\nexport type T = { n: int }\n' > $P/src/m/a.av
printf 'export fn gb() -> int { f() + 1 }\n' > $P/src/m/b.av
printf 'export fn gc() -> int {\n    println("c")\n    10\n}\n' > $P/src/m/c.av
printf 'use m.{f}\nexport fn gu() -> int { f() * 2 }\n' > $P/src/n/user.av
printf 'use m.{gc, f}\nexport fn go() -> int { gc() + f() }\n' > $P/src/n/other.av
printf 'export fn gt() -> int { 3 }\n' > $P/src/n/third.av
printf 'use n.{gu, go}\nuse m.{gb}\nprintln("${gu()} ${go()} ${gb()}")\n' > $P/src/main.av
for f in m/a m/b m/c n/user n/other n/third main; do cp $P/src/$f.av $P/$(echo $f | tr / _).orig; done

chk() { steps=$((steps + 1)); OUT=$(./avra check --time $P 2>&1); ST=$?; }
back() { for f in m/a m/b m/c n/user n/other n/third main; do cp $P/$(echo $f | tr / _).orig $P/src/$f.av; done; rm -f $P/src/m/tests/*.av; }
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
sed -i.bak 's/export fn f()/export fn f2()/' $P/src/m/a.av; rm -f $P/src/m/a.av.bak; chk
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
sed -i.bak 's/^fn p()/fn q()/' $P/src/m/a.av; rm -f $P/src/m/a.av.bak; chk
[ $ST != 0 ] || fail "a renamed private fn left the test that read it checking clean"
back; chk

echo "fn-add-attack: $steps checks, $fails failed"
[ "$fails" = 0 ]

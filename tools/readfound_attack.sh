#!/bin/sh
# AN ENTRY'S OWN BODY MOVES ITS OWN UNIT. A program's entry has no declaration whose
# `Syntax` answers, so its reads carry the FILE's own `Parsed` beside `Analysis`: a value
# use added to the entry's body (here a fn first taken as a value) re-lowers the entry's
# one unit and no other file's, and an edit to another fn's signature in another file
# leaves the entry standing. The entry stands on its own body, never on the whole-program
# references relation; the fn's read bit reaches its consumers through `Consumed`, not
# through a Lowered unit's own reads.
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
export AVRA_MAX_COMPILES=0
R=build/readfound-attack
T=build/aside/rf.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/rf
P=$R/rf; mkdir -p $P/src/lib
printf '[package]\nname = "rf"\nversion = "0.1.0"\n' > $P/avra.toml
who=readfound-attack
. tools/lib/steps.sh
for i in 1 2 3; do
    printf 'export fn f%s(s: string) -> string { s }\nexport fn c%s(s: string) -> string { f%s(s) }\n' $i $i $i > $P/src/lib/m$i.av
done
printf 'use lib.{c1, c2, c3}\nprintln("${c1("a")}${c2("b")}${c3("c")}")\n' > $P/src/main.av
judged() { AVRA_DB_VERIFY=1 $A check $P 2>&1 | grep -a '^loweredsaid' | tail -n 1; }
recomputed_of() { printf '%s' "$1" | sed -n 's/.*recomputed \([0-9]*\),.*/\1/p'; }
judged > /dev/null
printf 'use lib.{c1, c2, c3}\nuse lib.m3.{f3}\nlet taken = f3\nprintln("${c1("a")}${c2("b")}${c3("c")}")\n' > $P/src/main.av
first=$(judged)
n=$(recomputed_of "$first")
printf '%s' "$first" | grep -q "mismatched 0" || fail "a valid kept unit differs from a fresh lowering after the first value use: $first"
printf '%s' "$first" | grep -q "Parsed moved" || fail "the entry's own body edit moved no read of its own unit: $first"
printf '%s' "$first" | grep -q "References moved" && fail "the entry re-lowered on the whole-program references relation: $first"
[ "${n:-99}" -le 4 ] || fail "the first value use of one fn re-lowered $n units: $first"
sed 's/export fn f2(s: string) -> string { s }/export fn f2(s: string, n: int = 0) -> string { s }/' $P/src/lib/m2.av > $T/m2 && cp $T/m2 $P/src/lib/m2.av
second=$(judged)
n=$(recomputed_of "$second")
printf '%s' "$second" | grep -q "mismatched 0" || fail "a valid kept unit differs from a fresh lowering after a signature edit: $second"
printf '%s' "$second" | grep -q "ReadFound" && fail "an unrelated signature edit moved a ReadFound answer: $second"
printf '%s' "$second" | grep -q "References moved" && fail "a signature edit re-lowered on the whole-program references relation: $second"
[ "${n:-99}" -le 5 ] || fail "a signature edit in one file re-lowered $n units: $second"
verdict "an entry's own body edit re-lowers it, another file's signature edit leaves it standing"

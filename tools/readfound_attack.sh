#!/bin/sh
# A FN'S "TAKEN AS A VALUE" BIT MOVES EXACTLY ITS READERS. Taking a fn as a value for the first
# time is heard by the units that read that fn's bit and by no other; an edit to another fn's
# signature in another file leaves them standing. A reader stands on the one fn's answer, never
# on the whole relation of uses.
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
export AVRA_MAX_COMPILES=0
R=build/readfound-attack; fails=0
T=build/aside/rf.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/rf
P=$R/rf; mkdir -p $P/src/lib
printf '[package]\nname = "rf"\nversion = "0.1.0"\n' > $P/avra.toml
fail() { fails=$((fails + 1)); echo "FAIL  $1"; }
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
printf '%s' "$first" | grep -q "ReadFound moved" || fail "the first value use of f3 moved no ReadFound answer: $first"
[ "${n:-99}" -le 4 ] || fail "the first value use of one fn re-lowered $n units: $first"
sed 's/export fn f2(s: string) -> string { s }/export fn f2(s: string, n: int = 0) -> string { s }/' $P/src/lib/m2.av > $T/m2 && cp $T/m2 $P/src/lib/m2.av
second=$(judged)
n=$(recomputed_of "$second")
printf '%s' "$second" | grep -q "mismatched 0" || fail "a valid kept unit differs from a fresh lowering after a signature edit: $second"
printf '%s' "$second" | grep -q "ReadFound" && fail "an unrelated signature edit moved a ReadFound answer: $second"
[ "${n:-99}" -le 4 ] || fail "a signature edit in one file re-lowered $n units: $second"
echo "readfound-attack: one fn first taken as a value, then another's signature edited, $fails failed"
[ "$fails" = 0 ]

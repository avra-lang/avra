#!/bin/sh
# A SAME-FILE SIGNATURE EDIT MUST NOT RENAME A LIFTED BODY OR A STATIC LITERAL.
# m.av declares `decl_unnamed` ABOVE a lambda and a list literal. Adding a defaulted
# param inserts parse nodes and shifts every later node's arena index; a symbol named for
# that index moves with it, so a unit kept across the edit reads a name the fresh lowering
# no longer writes — `AVRA_DB_VERIFY=lowered` reports `mismatched` and wrecks. The symbol
# must be durable: the same before and after, and `mismatched 0`. A BARE STRING LITERAL IS
# NOT ENOUGH FOR THE SECOND HALF: it lowers to an inline constant, never a `$lit` global,
# so the static half would exercise nothing — a list spells a laid-out static.
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
export AVRA_MAX_COMPILES=0
R=build/durable-symbol-attack
T=build/aside/ds.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/ds
P=$R/ds; mkdir -p $P/src/lib
printf '[package]\nname = "ds"\nversion = "0.1.0"\n' > $P/avra.toml
printf 'export fn decl_unnamed(word: string) -> string { word }\nexport fn holds_a_lambda(n: int) -> int {\n    let f = (x: int) -> x + n\n    f(1)\n}\nexport fn holds_a_literal() -> List<int> { [1, 2] }\n' > $P/src/lib/m.av
printf 'use lib.{holds_a_lambda, holds_a_literal}\nprintln("${holds_a_lambda(2)} ${holds_a_literal().length}")\n' > $P/src/main.av
who=durable-symbol-attack
. tools/lib/steps.sh
judged() { AVRA_DB_VERIFY=lowered $A check $P 2>&1; }
syms() { $A emit $P > /dev/null 2>&1; grep -hoE '@"[^"]*"' $P/build/*.ll 2>/dev/null | sort -u | tr '\n' ' '; }
judged > $R/cold.log; cold=$?
colds=$(syms)
[ "$cold" -eq 0 ] || fail "the cold verify check exited $cold: $(grep -avE '^watch:' $R/cold.log | head -2 | tr '\n' ' ')"
[ -n "$colds" ] || fail "the fixture lowered no lifted or static symbol — the attack exercises nothing"
printf '%s' "$colds" | grep -q '\$lit' || fail "the fixture lowered no static literal — only the lifted body is exercised: [$colds]"
printf '%s' "$colds" | grep -q '\$24l' || fail "the fixture lowered no lifted body — only the static literal is exercised: [$colds]"
sed 's/export fn decl_unnamed(word: string) -> string {/export fn decl_unnamed(word: string, extra: string = "") -> string {/' $P/src/lib/m.av > $T/m.av && cp $T/m.av $P/src/lib/m.av
sigout=$(judged); sig=$?
sigs=$(syms)
printf '%s' "$sigout" | grep -q 'mismatched 0' || fail "the sig edit moved a kept lower without a mover: $(printf '%s' "$sigout" | grep -a '^loweredsaid' | tail -n 1 | cut -c1-260)"
printf '%s' "$sigout" | grep -q 'Q loweredsaid mismatch' && fail "a unit mismatched after the sig edit: $(printf '%s' "$sigout" | grep -a 'Q loweredsaid mismatch' | head -1)"
[ "$colds" = "$sigs" ] || fail "a lifted/static symbol moved with the sig edit: cold [$colds] sig [$sigs]"
[ "$sig" -eq 0 ] || fail "the sig verify check exited $sig: $(printf '%s' "$sigout" | grep -avE '^watch:' | head -2 | tr '\n' ' ')"
verdict "a same-file signature edit left every lifted/static symbol standing"

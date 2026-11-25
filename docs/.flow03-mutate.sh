#!/bin/sh
# Temporary: the test file green, then each named break, each run alone
# and restored. A break the file does not fail is printed SURVIVED.
set -u
t=packages/std-avrac/src/compiler/tests/cancel_reach_test.av
run() { AVRA_MEM_CEILING_MB=5000 build/avra test "$t" > build/m.out 2>&1; grep -E 'tests passed|✗' build/m.out | sed 's/@.*//' | head -6; }
echo "== green"; run
broke() {
    f=$1; from=$2; to=$3; label=$4
    cp "$f" build/m.keep
    python3 - "$f" "$from" "$to" <<'PY'
import sys
p, a, b = sys.argv[1:4]
t = open(p).read()
assert t.count(a) == 1, a
open(p, 'w').write(t.replace(a, b))
PY
    echo "== break: $label"; run
    grep -q '✗' build/m.out || echo "SURVIVED: $label"
    cp build/m.keep "$f"
}
c=packages/std-avrac/src/compiler/cancel_reach.av
for m in ${MUTANTS:-1 2 3 4 5 6 7 8 9 10 11 12}; do
    case $m in
    1) broke $c "own: s.spins() ||" "own: false ||" "a while is no cancel point" ;;
    2) broke $c ".Spawn(_) -> [CallAnswer.Known(true)]," ".Spawn(_) -> [CallAnswer.Known(false)]," "a spawn joins nothing" ;;
    3) broke $c ".Prop(subject, name) -> [CallAnswer.Known(self.row_waits(self.facts.type_at(subject), name.of))]," ".Prop(subject, name) -> [CallAnswer.Known(false)]," "an await waits for nothing" ;;
    4) broke $c ".CallValue(_, _) -> [CallAnswer.Known(true)]," ".CallValue(_, _) -> [CallAnswer.Known(false)]," "a call on a call's answer reaches nothing" ;;
    5) broke $c ".Bounded(_, _, _) or .Contract(_, _) or .FnField(_, _) -> CallAnswer.Known(true)," ".Bounded(_, _, _) or .Contract(_, _) or .FnField(_, _) -> CallAnswer.Known(false)," "a contract's call reaches nothing" ;;
    6) broke $c "if !(self.cancel_bit(c) ?? false) {" "if false {" "a callee's answer never reaches its callers" ;;
    7) broke $c "x.external -> rt_waits(x.name)" "x.external -> false" "no row waits" ;;
    8) broke packages/std-avrac/src/compiler/record.av ".concat(p.slice(17, 19))" ".concat(p.slice(17, 18))" "the bit leaves the contract" ;;
    9) broke packages/std-avrac/src/compiler/interface.av "self.decls.record_cancel(id, row.waits())" "self.decls.record_cancel(id, true)" "a held row forgets its bit" ;;
    10) broke $c "let g? = bound_decl_of(self.names, e) else { return CallAnswer.Known(true) }" "let g? = bound_decl_of(self.names, e) else { return CallAnswer.Known(false) }" "a named value's call reaches nothing" ;;
    11) broke $c ".Chain(subject, name) -> [CallAnswer.Known(self.chain_waits(subject, name.of))]," ".Chain(subject, name) -> [CallAnswer.Known(false)]," "a chain's read waits for nothing" ;;
    12) broke $c ".Call(_, _, _) -> [self.named_call(e)].concat(self.defaults_of_call(e))," ".Call(_, _, _) -> [self.named_call(e)]," "a call's defaults are not its caller's" ;;
    esac
done

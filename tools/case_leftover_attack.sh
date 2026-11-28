#!/bin/sh
# A LEFTOVER IS NO CASE. A case of the refusal witness is a package; a directory beside them that
# holds only a build's `.avra-cache` — what a branch switch leaves where a case's sources went — was
# dealt and judged as a case, and failed as "declares no entry point", far from its cause. Held here:
# with such a directory and one holding a case's sources but no manifest planted among the cases,
# `--cases` (what the gate deals) lists neither and every real case; a run over every case names
# each as a leftover and judges neither; and naming one is refused as no case, in those words.
. "$(dirname "$0")/lib/scratch.sh"
set -u
. "$(dirname "$0")/lib/attack.sh"
who=case-leftover-attack
. tools/lib/steps.sh
C=tools/program-refusals
stale=$C/zz-leftover-cache
bare=$C/zz-leftover-bare
scratch_also 'find "$stale" "$bare" -delete 2>/dev/null'
mkdir -p "$stale/.avra-cache/tapes" "$bare/src"
: > "$stale/.avra-cache/tapes/inputs.stamps"
printf 'println("x")\n' > "$bare/src/main.av"
listed=$(sh tools/witness_program_refusal.sh --cases)
case "$listed" in
    *zz-leftover*) fail "--cases lists a leftover: $(echo "$listed" | grep zz-leftover | tr '\n' ' ')" ;;
    *) say "--cases lists no leftover" ;;
esac
want=$(find $C -mindepth 2 -maxdepth 2 -name avra.toml | wc -l | tr -d ' ')
got=$(echo "$listed" | grep -c .)
[ "$got" = "$want" ] && say "--cases lists every case ($got)" || fail "--cases lists $got cases, where $want hold a manifest"
named=$(sh tools/witness_program_refusal.sh build/avra zz-leftover-cache zz-leftover-bare 2>&1); status=$?
[ "$status" = 1 ] && say "naming a leftover is refused (exit 1)" || fail "naming a leftover exited $status"
for d in zz-leftover-cache zz-leftover-bare; do
    echo "$named" | grep -q "^$d: no case — $C/$d holds no avra.toml" && say "$d named as no case" || fail "$d: not named as no case: $(echo "$named" | head -2 | tr '\n' ' ')"
done
echo "$named" | grep -q "declares no entry point" && fail "a leftover was judged: declares no entry point" || say "no leftover was judged"
. tools/lib/cases.sh
lo=$(leftovers_in $C)
echo "$lo" | grep -q "^zz-leftover-cache — no avra.toml, so no case; it holds: .avra-cache" && echo "$lo" | grep -q "^zz-leftover-bare — " &&
    say "a whole run names both as leftovers" || fail "the leftovers aren't named: $lo"
verdict

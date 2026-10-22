#!/bin/sh
# THE STEPS LIB'S WITNESS (tools/lib/steps.sh): `say` and `fail` count, the
# verdict's status is 0 iff nothing failed, and no tool keeps a counting
# `say`/`fail` of its own — a second definition of the one voice.
cd "$(dirname "$0")/.." || exit 1
bad=0
no() { bad=$((bad + 1)); echo "steps_test: FAIL — $1"; }

out=$(who=w; . tools/lib/steps.sh; say a; say b; verdict "claim"); rc=$?
[ "$rc" = 0 ] || no "a run with no failure answered $rc"
case "$out" in *"w: 2 held — claim"*) ;; *) no "two held said: $out" ;; esac
out=$(who=w; . tools/lib/steps.sh; say a; fail b; verdict); rc=$?
[ "$rc" = 1 ] || no "a run with a failure answered $rc"
case "$out" in *"w: FAILED — b"*"w: 1 FAILED, 1 held"*) ;; *) no "a failure said: $out" ;; esac
out=$(who=w; . tools/lib/steps.sh; verdict "claim")
[ "$out" = "w: held — claim" ] || no "a fail-only run said: $out"

copies=$(grep -lE '^[[:space:]]*(say|fail)\(\) *\{ *(steps|fails)=' tools/*.sh 2>/dev/null)
for f in $copies; do no "$f counts its own say/fail — source tools/lib/steps.sh"; done

[ "$bad" = 0 ] || exit 1
echo "steps_test: 4 checks — say and fail count, the verdict's status, no tool keeps its own copy"

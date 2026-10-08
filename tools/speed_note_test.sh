#!/bin/sh
# Fixture test for tools/speed_note.sh: run by hand, not by CI.
set -u
here=$(cd "$(dirname "$0")" && pwd)
fx="$here/speed_note_fixtures"
out=$(mktemp)
fail=0
check() { if [ "$2" = 0 ]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

warn=$(mktemp)
GITHUB_STEP_SUMMARY="$out" sh "$here/speed_note.sh" compare "$fx/pr.metrics" "$fx/main.metrics" > "$warn"
rc=$?
check "always exits 0" "$rc"
grep -q "::warning::speed: keeper.attack is 54% slower" "$warn" ; check "a >25% slower metric warns" $?
grep -q "::warning::speed: suite.cli" "$warn" ; r=$?; [ "$r" != 0 ]; check "an 8% slower metric does not warn" $?
grep -q "| suite.std-avrac | no baseline | 310s" "$out" ; check "a metric with no main baseline prints, never warns" $?
grep -q "::warning::speed: suite.std-avrac" "$warn" ; r=$?; [ "$r" != 0 ]; check "a missing baseline never warns" $?
grep -q "| speed.compiler | 600s | 615s | 2% |" "$out" ; check "the change column is a whole percentage" $?
GITHUB_STEP_SUMMARY="$out" sh "$here/speed_note.sh" compare /nonexistent /nonexistent > /dev/null 2>&1; check "missing files still exit 0" $?
sh "$here/speed_note.sh" bogus > /dev/null 2>&1; check "an unknown mode still exits 0" $?
rm -f "$out" "$warn"
exit $fail

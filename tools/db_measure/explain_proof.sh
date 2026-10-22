#!/bin/sh
# The explain lane's proof before a push: its three test files, then the idiom
# gate over the two packages it touches. One line a step; exit 1 if any failed.
set -u
out=build/explain_proof
mkdir -p "$out"
failed=0
step() {
    name=$1
    shift
    if "$@" >"$out/$name.log" 2>&1; then verdict=ok; else verdict="FAILED $?"; failed=1; fi
    echo "== $name: $verdict — $(grep -aE 'tests passed|NEW violation' "$out/$name.log" | tail -1)"
    if [ "$verdict" != ok ]; then grep -aE -A8 'actual:|^error|NEW violation' "$out/$name.log" | head -40; fi
}
step cache_walk_test build/avra test packages/std-avrac/src/compiler/tests/cache_walk_test.av
step explain_test build/avra test packages/cli/src/commands/tests/explain_test.av
step cache_test build/avra test packages/cli/src/commands/tests/cache_test.av
step idioms_cli build/avra check packages/cli --baseline tools/idioms.baseline
step idioms_std_avrac build/avra check packages/std-avrac --baseline tools/idioms.baseline
exit $failed

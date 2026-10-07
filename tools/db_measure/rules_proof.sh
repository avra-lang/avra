#!/bin/sh
# The rules command's proof: its tests, the doc keeper, the digests of its
# two machine forms, its wall from inside a package, and the cli's idiom gate.
set -u
out=build/rules_proof
mkdir -p "$out"
failed=0
step() {
    name=$1
    shift
    if "$@" >"$out/$name.log" 2>&1; then verdict=ok; else verdict="FAILED $?"; failed=1; fi
    echo "== $name: $verdict — $(grep -aE 'tests passed|NEW violation|matches the rule table' "$out/$name.log" | tail -1)"
    if [ "$verdict" != ok ]; then grep -aE -A8 'actual:|^error|NEW violation' "$out/$name.log" | head -40; fi
}
step rules_test build/avra test packages/cli/src/commands/tests/rules_test.av
step check_markdown build/avra rules --check-markdown DOGFOODING.md
echo "== json: $(cd packages/cli && ../../build/avra rules --json | shasum | cut -c1-40)"
echo "== markdown: $(cd packages/cli && ../../build/avra rules --markdown | shasum | cut -c1-40)"
echo "== header: $(cd packages/cli && ../../build/avra rules | head -1)"
began=$(date +%s.%N)
(cd packages/cli && ../../build/avra rules >/dev/null)
echo "== wall inside packages/cli: $(echo "$(date +%s.%N) - $began" | bc) s"
step idioms_cli build/avra check packages/cli --baseline tools/idioms.baseline
exit $failed

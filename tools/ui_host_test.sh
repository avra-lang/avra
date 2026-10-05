#!/bin/sh
# THE JS HOST'S OWN PROOF: runtime/dom/bootstrap_test.js applies every patch
# op to a stub document and checks the echo. It needs `node`; where node is
# absent this SKIPS, spoken, so a machine without it is not falsely green.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
if ! command -v node >/dev/null 2>&1; then
    echo "ui-host-test: SKIPPED — no \`node\` on this machine; runtime/dom/bootstrap_test.js did not run"
    exit 0
fi
out=$(node "$here/runtime/dom/bootstrap_test.js") || { echo "$out" | grep -v '^✓' ; echo "ui-host-test: the host's tests failed"; exit 1; }
echo "ui-host-test: $(echo "$out" | tail -1)"

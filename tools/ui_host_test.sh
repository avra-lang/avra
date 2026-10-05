#!/bin/sh
# THE JS HOST'S OWN PROOF: runtime/dom/bootstrap_test.js applies every patch
# op to a stub document and checks the echo, and runtime/dom/dev_test.js
# runs the dev server's client over one. It needs `node`; where node is
# absent this SKIPS, spoken, so a machine without it is not falsely green.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
if ! command -v node >/dev/null 2>&1; then
    echo "ui-host-test: SKIPPED — no \`node\` on this machine; runtime/dom/bootstrap_test.js did not run"
    exit 0
fi
said=""
for suite in bootstrap dev; do
    out=$(node "$here/runtime/dom/${suite}_test.js") || { echo "$out" | grep -v '^✓' ; echo "ui-host-test: the host's ${suite} tests failed"; exit 1; }
    said="$said $(echo "$out" | tail -1)"
done
echo "ui-host-test:$said"

#!/bin/sh
# A box owes half a solver unit plus half the engine's quantum on every number, even one that
# shares nothing. WebKit's cell-face seed 3 holds a tree (case 17) whose widths stand 0.009 px
# apart: it agrees with the term and is refused without it. Skips where WebKit is absent.
set -u
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
bad() { echo "layout-oracle own-term self-test: $1"; exit 1; }
. "$here/ui-board/playwright.sh"
log=$(mktemp "${TMPDIR:-/tmp}/avra-layout-playwright.XXXXXX")
playwright_ready "$tree" "$log" || { echo "layout-oracle own-term self-test: SKIPPED: no WebKit"; exit 0; }
run() { node "$here/layout-oracle/oracle.mjs" --browser webkit --face cell --seed 3 --cases 20 --show 0 "$@" 2>&1; }
run | grep -q "25 of 25 trees agree" || bad "the term did not make the tree agree"
run --without-own-term 1 | grep -q "24 of 25 trees agree" || bad "without the term the tree was not refused"
echo "layout-oracle own-term self-test: case 17 agrees with the term and is refused without it"

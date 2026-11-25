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
playwright_ready "$tree" "$log" || {
    # a checks' machine without WebKit is broken, and a gate that skips there runs nothing
    [ "${CI:-}" = true ] && bad "ran 0 trees — FAILED: Playwright's WebKit did not install: $(tail -1 "$log")"
    echo "layout-oracle own-term self-test: ran 0 trees — SKIPPED: Playwright's WebKit did not install: $(tail -1 "$log")"
    exit 0
}
run() { node "$here/layout-oracle/oracle.mjs" --browser webkit --face cell --seed 3 --cases 20 --show 0 "$@" 2>&1; }
# what an assertion compared: the engine, the tree count and the oracle's own words, never a bare line
saw() {
    echo "layout-oracle own-term self-test: $1" >&2
    echo "  engine: $(node -e 'import("'"$PLAYWRIGHT_DIR"'/node_modules/playwright/index.mjs").then((m) => console.log(m.webkit.executablePath()))' 2>&1 | tail -1)" >&2
    printf '%s\n' "$2" | tail -25 | cut -c1-300 | sed 's/^/  | /' >&2
    exit 1
}
with=$(run)
printf '%s\n' "$with" | grep -q "25 of 25 trees agree" || saw "the term did not make the tree agree (wanted: 25 of 25 trees agree)" "$with"
without=$(run --without-own-term 1)
printf '%s\n' "$without" | grep -q "24 of 25 trees agree" || saw "without the term the tree was not refused (wanted: 24 of 25 trees agree)" "$without"
echo "layout-oracle own-term self-test: case 17 agrees with the term and is refused without it"

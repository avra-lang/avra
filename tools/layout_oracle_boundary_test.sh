#!/bin/sh
# A line whose run stands within the combined quantum of its room breaks either way in two correct
# engines. WebKit's prop-face seed 2 holds a tree (case 64) whose text fits its 60px box in WebKit by a
# hair the solver counts over: it agrees with the boundary term and is refused without it. Skips,
# spoken, where WebKit is absent (a failure on the checks' machine).
set -u
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
bad() { echo "layout-oracle boundary self-test: $1"; exit 1; }
. "$here/ui-board/playwright.sh"
log=$(mktemp "${TMPDIR:-/tmp}/avra-layout-playwright.XXXXXX")
playwright_ready "$tree" "$log" || {
    [ "${CI:-}" = true ] && bad "ran 0 trees — FAILED: Playwright's WebKit did not install: $(tail -1 "$log")"
    echo "layout-oracle boundary self-test: ran 0 trees — SKIPPED: Playwright's WebKit did not install: $(tail -1 "$log")"
    exit 0
}
run() { AVRA="${AVRA:-$tree/build/avra}" node "$here/layout-oracle/oracle.mjs" --browser webkit --face prop --seed 2 --cases 70 --show 0 "$@" 2>&1; }
# what an assertion compared: the engine, the tree count and the oracle's own words, never a bare line
saw() {
    echo "layout-oracle boundary self-test: $1" >&2
    echo "  engine: $(node -e 'import("'"$PLAYWRIGHT_DIR"'/node_modules/playwright/index.mjs").then((m) => console.log(m.webkit.executablePath()))' 2>&1 | tail -1)" >&2
    printf '%s\n' "$2" | tail -25 | cut -c1-300 | sed 's/^/  | /' >&2
    exit 1
}
with=$(run)
printf '%s\n' "$with" | grep -q "76 of 76 trees agree" || saw "the term did not make the tree agree (wanted: 76 of 76 trees agree)" "$with"
without=$(run --without-boundary-term 1)
printf '%s\n' "$without" | grep -q "75 of 76 trees agree" || saw "without the term the tree was not refused (wanted: 75 of 76 trees agree)" "$without"
echo "layout-oracle boundary self-test: case 64 agrees with the boundary term and is refused without it"

#!/bin/sh
# THE LAYOUT SOLVER AGAINST THE WEB TARGET, in a real browser: random trees are
# placed by std-ui's `place` and by Firefox running the page the real html
# realizer writes, and every box must agree (tools/layout-oracle/oracle.mjs).
# Fixed seed, so a run is the same trees every time (LAYOUT_ORACLE_SEEDS and
# LAYOUT_ORACLE_CASES widen the sweep); a failing tree is shrunk
# and printed with both answers.
#
# It needs the compiler and Firefox (FIREFOX names one that is not in a usual
# place). Where one is absent the run FAILS, naming what is missing: a run that
# compared nothing has not passed. LAYOUT_ORACLE_SKIP=<reason> stands it down by
# name off the checks' machine (CI=true), where a missing browser is a broken machine.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
seeds=${LAYOUT_ORACLE_SEEDS:-1}
cases=${LAYOUT_ORACLE_CASES:-300}

# A run that compared nothing has not passed: it FAILS unless stood down by name,
# LAYOUT_ORACLE_SKIP=<reason>, which says so aloud.
skip() {
    if [ "${CI:-}" != true ] && [ -n "${LAYOUT_ORACLE_SKIP:-}" ]; then
        echo "layout-oracle: ran 0 trees — STOOD DOWN ($LAYOUT_ORACLE_SKIP): $* ; the solver did not meet a browser"
        exit 0
    fi
    echo "layout-oracle: ran 0 trees — FAILED: $* ; install the browser (.github/ci/install_firefox.sh) or stand it down here with LAYOUT_ORACLE_SKIP=<reason>"
    exit 1
}

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
node -e 'process.exit(typeof WebSocket === "function" ? 0 : 1)' || skip "this \`node\` has no WebSocket of its own (22 or later has)"
case " ${LAYOUT_ORACLE_BROWSERS:-firefox} " in *" firefox "*) node --input-type=module -e "import { firefoxBinary } from '$here/ui-board/firefox.mjs'; process.exit(firefoxBinary() ? 0 : 1)" || skip "no Firefox on this machine (FIREFOX names one)" ;; esac

. "$here/ui-board/playwright.sh"
browsers=${LAYOUT_ORACLE_BROWSERS:-firefox}
total=0
for browser in $browsers; do
    if [ "$browser" = webkit ]; then
        log=$(mktemp "${TMPDIR:-/tmp}/avra-layout-playwright.XXXXXX")
        playwright_ready "$tree" "$log" || skip "Playwright's WebKit did not install: $(tail -1 "$log")"
    fi
    for face in cell prop; do
        for seed in $seeds; do
            out=$(AVRA="$avra" node "$here/layout-oracle/oracle.mjs" --browser "$browser" --face "$face" --cases "$cases" --seed "$seed" --show 2 2>&1) || { echo "$out"; echo "layout-oracle: the solver and $browser disagree (face $face, seed $seed)"; exit 1; }
            echo "$out" | tail -1
            n=$(echo "$out" | tail -1 | sed -n 's/^layout-oracle: \([0-9]*\) of.*/\1/p')
            total=$((total + ${n:-0}))
        done
    done
done
[ "$total" -gt 0 ] || { echo "layout-oracle: ran 0 trees — FAILED: no seed compared a single tree"; exit 1; }
echo "layout-oracle: $total trees agree between std-ui's solver and the real html target in: $browsers"

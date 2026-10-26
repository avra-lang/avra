#!/bin/sh
# THE LAYOUT SOLVER AGAINST THE WEB TARGET, in a real browser: random trees are
# placed by std-ui's `place` and by Firefox running the page the real html
# realizer writes, and every box must agree (tools/layout-oracle/oracle.mjs).
# Fixed seed, so a run is the same trees every time (LAYOUT_ORACLE_SEEDS and
# LAYOUT_ORACLE_CASES widen the sweep); a failing tree is shrunk and printed
# with both answers (LAYOUT_ORACLE_SHOW 0 counts without shrinking, for a wide
# sweep whose failures are read elsewhere). Every face runs on every browser
# (LAYOUT_ORACLE_BROWSERS, LAYOUT_ORACLE_FACES): the counts all print, and the
# status is a failure if any face in any browser disagreed.
# Every box is judged against a bound derived from its own tree and the engine's layout
# quantum (oracle.mjs); a line count is exact. WebKit alone holds licences (oracle.mjs: a family
# for a word wider than its box, and named trees); where Firefox and the solver disagree the solver is wrong.
#
# It needs the compiler and Firefox (FIREFOX names one that is not in a usual
# place). Where one is absent the run FAILS, naming what is missing: a run that
# compared nothing has not passed. LAYOUT_ORACLE_SKIP=<reason> stands it down by
# name off the checks' machine (CI=true), where a missing browser is a broken machine.
set -eu

. "$(dirname "$0")/lib/tree.sh"
seeds=${LAYOUT_ORACLE_SEEDS:-1}
cases=${LAYOUT_ORACLE_CASES:-300}
show=${LAYOUT_ORACLE_SHOW:-2}

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
faces=${LAYOUT_ORACLE_FACES:-cell prop}
total=0
failed=
summary=
licensed_total=0
# EVERY face runs on EVERY browser, and every count is printed: a run that
# stopped at the first failing face would report one count and hide the rest,
# and cannot be read as green. The status is the run's verdict, the table its
# evidence.
for browser in $browsers; do
    if [ "$browser" = webkit ]; then
        log=$(mktemp "${TMPDIR:-/tmp}/avra-layout-playwright.XXXXXX")
        playwright_ready "$tree" "$log" || skip "Playwright's WebKit did not install: $(tail -1 "$log")"
    fi
    for face in $faces; do
        for seed in $seeds; do
            out=$(AVRA="$avra" node "$here/layout-oracle/oracle.mjs" --browser "$browser" --face "$face" --cases "$cases" --seed "$seed" --show "$show" 2>&1) && st=0 || st=$?
            echo "$out"
            counts=$(printf '%s\n' "$out" | sed -n 's/^layout-oracle: \([0-9]*\) of \([0-9]*\) trees agree.*/\1 \2/p' | tail -1)
            licensed=$(printf '%s\n' "$out" | sed -n 's/^layout-oracle: licensed \([0-9]*\) .*/\1/p' | tail -1)
            agree=0 of=0
            [ -z "$counts" ] || { agree=${counts% *}; of=${counts#* }; }
            said=
            [ -z "$licensed" ] || said=", ${licensed} licensed"
            summary="${summary}layout-oracle: ${browser} ${face} seed ${seed} — ${agree} of ${of} trees agree${said}
"
            total=$((total + agree))
            licensed_total=$((licensed_total + ${licensed:-0}))
            [ "$st" = 0 ] || failed="${failed} ${browser}/${face}/seed ${seed}"
        done
    done
done
printf '%s' "$summary"
if [ -n "$failed" ]; then
    echo "layout-oracle: FAILED — the solver and the browser disagree in:${failed}"
    exit 1
fi
[ "$total" -gt 0 ] || { echo "layout-oracle: ran 0 trees — FAILED: no seed compared a single tree"; exit 1; }
if [ "$licensed_total" = 0 ]; then
    echo "layout-oracle: $total trees agree between std-ui's solver and the real html target in: $browsers"
else
    echo "layout-oracle: $total of $((total + licensed_total)) trees agree between std-ui's solver and the real html target in: $browsers; $licensed_total licensed by name, and the count is exact in every other tree"
fi

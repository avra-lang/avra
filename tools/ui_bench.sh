#!/bin/sh
# WHAT A PAINT OF A LONG KEYED LIST COSTS (tools/ui-bench), natively and in a
# real browser, at 1,000 / 10,000 / 100,000 rows: the walk, the diff, the
# page's elements, the frame, the memory. A MEASUREMENT, not a gate: it
# prints the numbers a windowed list is to be held to.
#
#   sh tools/ui_bench.sh [native|browser|all]     ROWS="1000 10000" to choose sizes
#
# The browser half needs Firefox (FIREFOX names one) and a wasm toolchain; it
# SKIPS, spoken, without them.
set -eu

. "$(dirname "$0")/lib/tree.sh"
which=${1:-all}
sizes=${ROWS:-"1000 10000 100000"}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-bench.XXXXXX")
trap 'kill $(jobs -p) 2>/dev/null || true' EXIT

native() {
    cp -R "$tree/tools/ui-bench" "$work/native"
    "$avra" build "$work/native/native" >"$work/n.out" 2>"$work/n.err" || { cat "$work/n.err"; echo "ui-bench: the native bench did not build"; return 1; }
    bin=$(tail -1 "$work/n.out")
    for n in $sizes; do
        echo "=== native, $n rows"
        ROWS=$n "$bin"
        echo "peak memory: $(ROWS=$n AVRA_MEM_STATS=1 "$bin" 2>&1 >/dev/null | sed -n 's/^mem: peak \(.*\)$/\1/p' | head -1)"
    done
}

browser() {
    command -v node >/dev/null 2>&1 || { echo "ui-bench: SKIPPED the browser half — no node"; return 0; }
    node --input-type=module -e "import { firefoxBinary } from '$here/ui-board/firefox.mjs'; process.exit(firefoxBinary() ? 0 : 1)" \
        || { echo "ui-bench: SKIPPED the browser half — no Firefox (FIREFOX names one)"; return 0; }
    for n in $sizes; do
        d="$work/web_$n"; mkdir -p "$d"; cp -R "$tree/tools/ui-bench" "$d/ui-bench"
        sed "s/^fill([0-9]*)\$/fill($n)/" "$tree/tools/ui-bench/src/main.av" > "$d/ui-bench/src/main.av"
        if [ "${MODE:-}" = windowed ]; then
            sed "s/^mount(view)\$/mount(view_windowed)/; s/^use @ui.bench.{\(.*\)}\$/use @ui.bench.{\1, view_windowed}/" "$d/ui-bench/src/main.av" > "$d/ui-bench/src/m.av" && mv "$d/ui-bench/src/m.av" "$d/ui-bench/src/main.av"
        fi
        "$avra" build --target wasm --wasm_reactor "$d/ui-bench" >"$d/out.txt" 2>"$d/err.txt" || { cat "$d/err.txt"; echo "ui-bench: the web bench did not build"; return 1; }
        wasm=$(tail -1 "$d/out.txt")
        node "$tree/tools/ui-bench/serve.mjs" "$wasm" "$tree/runtime/dom" >"$d/serve.txt" 2>&1 &
        tries=0
        until grep -q '^serving http' "$d/serve.txt" 2>/dev/null; do tries=$((tries + 1)); [ "$tries" -lt 50 ] || { echo "ui-bench: the page never came up"; return 1; }; sleep 0.1; done
        url=$(sed -n 's/^serving \(http[^ ]*\).*$/\1/p' "$d/serve.txt")
        echo "=== Firefox, $n rows"
        node "$tree/tools/ui-bench/measure.mjs" "$url" "${MODE:-}"
    done
}

case "$which" in
    native) native ;;
    browser) browser ;;
    all) native; browser ;;
    *) echo "usage: ui_bench.sh [native|browser|all]"; exit 2 ;;
esac

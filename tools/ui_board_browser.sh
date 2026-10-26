#!/bin/sh
# THE BOARD IN A REAL BROWSER: tools/ui-board served by `avra dev` and
# driven in headless Firefox by
# tools/ui-board/browser.mjs, which checks each claim and exits 1 on the
# first that fails. `make ui-board` proves the wire over a stub document;
# this proves what only an engine can — and the dev loop: the view's file is
# edited and the running page must follow.
#
# It needs what `make ui-board` needs, Firefox (and, where it is asked for, Playwright's WebKit) (FIREFOX names one that is
# not in a usual place). Where one is absent this FAILS, naming what is
# missing: a run that examined nothing is no pass. Only a hand-set
# UI_BROWSER_SKIP=<reason> stands it down on a local machine, loudly; on the
# checks' machine (CI=true) nothing does. UI_BOARD_TARGET names one wasm triple (default `wasm`);
# UI_BROWSER_SHOTS names a directory the run leaves screenshots in. UI_BROWSER_ENGINES names the engines
# to run, in order (default `firefox`; the checks name `firefox webkit`); UI_BROWSER_DEVICE names a Playwright device
# ("iPhone 15") for the WebKit run: a touch screen and a phone's window.
set -eu

# Whether a browser stands at the path `$1`.
webkit_stands() { [ -e "$1" ]; }

# THE PATH THE LAUNCHER RUNS, as Playwright's own module names it: the guard
# and the launch read one answer, so no cache can stand for a browser it lacks.
webkit_exe() {
    PW_PREFIX=$1 node --input-type=module -e 'const { webkit } = await import(process.env.PW_PREFIX + "/node_modules/playwright/index.mjs"); process.stdout.write(webkit.executablePath());'
}

# `--self-test`: both surfaces of the skip contract, run against a compiler that
# is not there (the first thing a run needs), so no browser is touched.
if [ "${1:-}" = --self-test ]; then
    me=$0
    ran() { env -u CI -u UI_BROWSER_SKIP AVRA=/nonexistent "$@" sh "$me" 2>&1; }
    out=$(ran) && { echo "ui-browser self-test: a missing machine passed"; exit 1; }
    case $out in *UI_BROWSER_SKIP*) ;; *) echo "ui-browser self-test: the refusal does not name its opt-out"; exit 1;; esac
    out=$(ran UI_BROWSER_SKIP=no-firefox-here) || { echo "ui-browser self-test: UI_BROWSER_SKIP did not stand it down"; exit 1; }
    case $out in *"STOOD DOWN"*no-firefox-here*) ;; *) echo "ui-browser self-test: a stand-down is not spoken with its reason"; exit 1;; esac
    out=$(env CI=true UI_BROWSER_SKIP=no-firefox-here AVRA=/nonexistent sh "$me" 2>&1) && { echo "ui-browser self-test: CI stood down"; exit 1; }
    # BOTH SURFACES OF THE GUARD, asked of a Playwright module that names its
    # own executable: a path with a browser is read as standing, and a path
    # with none is read as missing — the case a restored cache used to pass at
    # once, and the reason a cache is validated rather than assumed.
    command -v node >/dev/null 2>&1 || { echo "ui-browser self-test: no \`node\` to ask Playwright's module"; exit 1; }
    d=$(mktemp -d "${TMPDIR:-/tmp}/avra-webkit-guard.XXXXXX")
    mkdir -p "$d/module/node_modules/playwright" "$d/standing"
    printf '%s\n' 'export const webkit = { executablePath: () => process.env.PW_ANSWER };' >"$d/module/node_modules/playwright/index.mjs"
    : >"$d/standing/pw_run.sh"
    if [ "$(PW_ANSWER="$d/standing/pw_run.sh" webkit_exe "$d/module")" != "$d/standing/pw_run.sh" ]; then
        echo "ui-browser self-test: the guard did not read the launcher's own answer"
        find "$d" -delete
        exit 1
    fi
    if webkit_stands "$(PW_ANSWER="$d/gone/pw_run.sh" webkit_exe "$d/module")"; then
        echo "ui-browser self-test: a path with no browser was read as standing"
        find "$d" -delete
        exit 1
    fi
    find "$d" -delete
    echo "ui-browser self-test: a missing machine fails, only UI_BROWSER_SKIP stands it down, CI never does; the guard reads the path the launcher names"
    exit 0
fi

here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
target=${UI_BOARD_TARGET:-wasm}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-ui-browser.XXXXXX")

# A RUN THAT CANNOT JUDGE FAILS. On the checks' machine (CI=true) a missing browser,
# node or toolchain is a broken machine. A local machine may stand the keeper
# down by name: UI_BROWSER_SKIP=<reason>.
skip() {
    if [ "${CI:-}" = true ]; then
        echo "ui-browser: ran 0 claims — $* ; the checks' machine must carry them (.github/ci/install_firefox.sh installs the browser)"
        exit 1
    fi
    if [ -n "${UI_BROWSER_SKIP:-}" ]; then
        echo "ui-browser: ran 0 claims — STOOD DOWN ($UI_BROWSER_SKIP): $* ; the board did not run in a browser"
        exit 0
    fi
    echo "ui-browser: ran 0 claims — $* ; set UI_BROWSER_SKIP=<reason> to stand it down here, or install Firefox (.github/ci/install_firefox.sh)"
    exit 1
}

[ -x "$avra" ] || skip "no compiler at $avra"
command -v node >/dev/null 2>&1 || skip "no \`node\` on this machine"
node -e 'process.exit(typeof WebSocket === "function" ? 0 : 1)' || skip "this \`node\` has no WebSocket of its own (22 or later has)"
node --input-type=module -e "import { firefoxBinary } from '$here/ui-board/firefox.mjs'; process.exit(firefoxBinary() ? 0 : 1)" || skip "no Firefox on this machine (FIREFOX names one)"
. "$here/lib/wasm_ready.sh"
wasm_ready || skip "the wasm runtime archive did not build"

# A COPY is served, so the run edits no file of the tree's.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
# The board's server keeps its tasks in a file, so a run names its own.
export BOARD_DB="$work/board.db"
"$avra" dev --target "$target" --port 0 "$work/tools/ui-board" >"$work/dev.out" 2>"$work/dev.err" &
dev=$!
servers=""
trap 'kill "$dev" 2>/dev/null || true' EXIT
tries=0
until grep -q '^dev: .* at http' "$work/dev.out" 2>/dev/null; do
    if ! kill -0 "$dev" 2>/dev/null; then
        wait "$dev" || ended=$?
        [ "${ended:-0}" -ne 2 ] || skip "$(sed 's/^avra: //' "$work/dev.err" | head -1)"
        echo "ui-browser: \`avra dev\` ended before it served"; cat "$work/dev.err" "$work/dev.out"; exit 1
    fi
    tries=$((tries + 1))
    [ "$tries" -lt 600 ] || { echo "ui-browser: \`avra dev\` never said where it serves"; cat "$work/dev.err"; exit 1; }
    sleep 0.1
done
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/dev.out" | head -1)

# THE SERVER'S PAGE, drawn natively from the board's own package, served with
# the module and the glue — once as drawn, once with an element gone before the
# module runs. The module is built from a copy of its own.
mkdir -p "$work/server/tools" "$work/served/tools"
cp -R "$tree/tools/ui-board" "$work/server/tools/ui-board"
cp "$tree/tools/ui-board/hydrate/main.av" "$work/server/tools/ui-board/src/main.av"
"$avra" run "$work/server/tools/ui-board" 2>"$work/hydrate.err" | sed -n '4,$p' > "$work/document.html"
grep -q "^<!doctype html>" "$work/document.html" || { cat "$work/hydrate.err"; echo "ui-browser: the server's page did not draw"; exit 1; }
cp -R "$tree/tools/ui-board" "$work/served/tools/ui-board"
"$avra" build --target "$target" --wasm_reactor "$work/served/tools/ui-board" >"$work/served.out" 2>"$work/served.err" || { cat "$work/served.err"; echo "ui-browser: the board did not build for the served page"; exit 1; }
served=$(tail -1 "$work/served.out")
for mode in "" "--tampered"; do
    node "$here/ui-board/serve_hydrated.mjs" "$work/document.html" "$served" "$tree/runtime/dom" $mode --backend "$url" >"$work/serve$mode.out" 2>&1 &
    servers="$servers $!"
done
trap 'kill "$dev" $servers 2>/dev/null || true' EXIT
for mode in "" "--tampered"; do
    tries=0
    until grep -q '^serving http' "$work/serve$mode.out" 2>/dev/null; do
        tries=$((tries + 1)); [ "$tries" -lt 100 ] || { cat "$work/serve$mode.out"; echo "ui-browser: the served page never came up"; exit 1; }
        sleep 0.1
    done
done
hydrated=$(sed -n 's/^serving \(http[^ ]*\).*$/\1/p' "$work/serve.out" | head -1)
torn=$(sed -n 's/^serving \(http[^ ]*\).*$/\1/p' "$work/serve--tampered.out" | head -1)

# THE ENGINES: Firefox, and WebKit — the engine every iOS browser is, which reads what Firefox
# tolerates differently (a `showModal` on a dialog already open, an import encoding Firefox
# reads and WebKit does not). A lane's own run proves Firefox; the checks' job names both
# (UI_BROWSER_ENGINES="firefox webkit webkit-iphone", the last being WebKit on a phone profile). WebKit comes from Playwright, pinned, installed on first
# use; one that cannot launch is a missing browser like any other: it fails unless stood down by
# name (`skip`), and says where its libraries come from.
engines=${UI_BROWSER_ENGINES:-firefox}
playwright_version=1.64.1
case " $engines " in
    *" webkit "* | *" webkit-iphone "*)
        playwright=${PLAYWRIGHT_DIR:-$tree/build/playwright}
        # THE BROWSER STANDS WHERE THIS GUARD LOOKS. `playwright install`
        # honours PLAYWRIGHT_BROWSERS_PATH, so the directory the checks cache
        # holds the browser too, and a restored cache is VALIDATED rather than
        # assumed: one that carries the node module and no browser installs it
        # instead of failing at launch.
        browsers=$playwright/browsers
        export PLAYWRIGHT_BROWSERS_PATH="$browsers"
        if [ ! -d "$playwright/node_modules/playwright" ]; then
            mkdir -p "$playwright"
            # a machine with no npm (the checks' image) takes the one in the pinned Node (.github/ci/install_node.sh)
            command -v npm >/dev/null 2>&1 || PATH=/opt/node-jspi/bin:$PATH
            npm install --prefix "$playwright" --no-audit --no-fund "playwright@$playwright_version" >"$work/npm.out" 2>&1 ||
                skip "Playwright did not install: $(tail -1 "$work/npm.out")"
        fi
        exe=$(webkit_exe "$playwright") || skip "Playwright's module named no WebKit executable"
        if ! webkit_stands "$exe"; then
            "$playwright/node_modules/.bin/playwright" install webkit >>"$work/npm.out" 2>&1 ||
                skip "Playwright's WebKit did not install: $(tail -1 "$work/npm.out")"
            exe=$(webkit_exe "$playwright") || skip "Playwright's module named no WebKit executable after install"
            webkit_stands "$exe" || skip "Playwright's WebKit is not at $exe after install"
        fi
        export PLAYWRIGHT_DIR="$playwright"
        ;;
esac

# WHAT THE PAGE SAYS REACHES THE DEVELOPER: a second, tiny page whose walk warns (two unkeyed
# instances of a stateful component) is served by `avra dev` and opened in Firefox; dev's own
# output must carry the page's words, once.
cp -R "$tree/tools/ui-warns" "$work/ui-warns"
"$avra" dev --target "$target" --port 0 "$work/ui-warns" >"$work/warns.out" 2>"$work/warns.err" &
warns=$!
trap 'kill "$dev" "$warns" $servers 2>/dev/null || true' EXIT
tries=0
until grep -q '^dev: .* at http' "$work/warns.out" 2>/dev/null; do
    kill -0 "$warns" 2>/dev/null || { cat "$work/warns.err" "$work/warns.out"; echo "ui-browser: \`avra dev\` ended before it served the warning page"; exit 1; }
    tries=$((tries + 1))
    [ "$tries" -lt 600 ] || { cat "$work/warns.err"; echo "ui-browser: \`avra dev\` never served the warning page"; exit 1; }
    sleep 0.1
done
warns_url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/warns.out" | head -1)
node "$here/ui-board/warned.mjs" "$warns_url" >"$work/warned.out" 2>&1 || { cat "$work/warned.out" "$work/warns.out"; echo "ui-browser: the warning page did not draw in Firefox"; exit 1; }
said=$(grep -c '^dev: the page said: ui: .*keeps state' "$work/warns.out" || :)
[ "$said" = 1 ] || { cat "$work/warns.out"; echo "ui-browser: dev's output carried the page's warning $said times, wanted once"; exit 1; }
echo "ui-browser: a page whose walk warns is told in \`avra dev\`'s output, once"

shots=${UI_BROWSER_SHOTS:+--shots "$UI_BROWSER_SHOTS"}
for engine in $engines; do
    status=0
    began=$(date +%s)
    # `webkit-iphone` is WebKit under a phone's touch screen and window: the owner's real target
    device=${UI_BROWSER_DEVICE:-}
    run_engine=$engine
    if [ "$engine" = webkit-iphone ]; then run_engine=webkit; device="iPhone 15"; fi
    out=$(UI_BROWSER_DEVICE=$device node "$here/ui-board/browser.mjs" "$url" --engine "$run_engine" --source "$work/tools/ui-board/src/board.av" --hydrated "$hydrated" --tampered "$torn" $shots 2>&1) || status=$?
    [ "$status" -ne 3 ] || skip "$(echo "$out" | tail -1) — WebKit's host libraries are .github/ci/packages-browser.txt; on a Sprite, \`sh tools/work run --browser …\` installs them"
    if [ "$status" -ne 0 ]; then
        echo "$out" | grep -v '^ok '; echo "ui-browser: the board failed in $engine"; exit 1
    fi
    echo "$out" | grep '^skipped in ' || :
    left=$(echo "$out" | grep -c '^skipped in ' || :)
    echo "ui-browser: ran $(echo "$out" | grep -c '^ok ') claims, all hold, in $engine$([ -z "$device" ] || echo " ($device)")$([ "$left" = 0 ] || echo ", $left skipped by name above"), $(($(date +%s) - began))s, served by \`avra dev\` at $url"
done

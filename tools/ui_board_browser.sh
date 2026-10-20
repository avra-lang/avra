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

# A WebKit build stands under `$1` when the `pw_run.sh` the launcher runs is
# there; the glob is Playwright's own `webkit-<revision>` directory.
webkit_stands() {
    for f in "$1"/webkit-*/pw_run.sh; do
        [ -e "$f" ] && return 0
    done
    return 1
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
    # BOTH SURFACES OF THE GUARD, on the launcher's own file: a standing WebKit is
    # read as standing, and Playwright's node module with no browser under it is
    # read as missing — the case a restored cache used to pass at once.
    d=$(mktemp -d "${TMPDIR:-/tmp}/avra-webkit-guard.XXXXXX")
    mkdir -p "$d/standing/webkit-2370" "$d/module-only/node_modules/playwright"
    : >"$d/standing/webkit-2370/pw_run.sh"
    if ! webkit_stands "$d/standing"; then
        echo "ui-browser self-test: a standing WebKit was read as missing"
        find "$d" -delete
        exit 1
    fi
    if webkit_stands "$d/module-only"; then
        echo "ui-browser self-test: a module and no browser was read as standing"
        find "$d" -delete
        exit 1
    fi
    find "$d" -delete
    echo "ui-browser self-test: a missing machine fails, only UI_BROWSER_SKIP stands it down, CI never does; the guard reads the launcher's own pw_run.sh"
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
if [ ! -f "$tree/build/wasm32/libavra_runtime.a" ]; then
    ( cd "$tree" && make -s wasm-runtime wasm-packages ) >/dev/null 2>&1 || skip "the wasm runtime archive did not build"
fi

# A COPY is served, so the run edits no file of the tree's.
mkdir -p "$work/tools"
cp -R "$tree/tools/ui-board" "$work/tools/ui-board"
"$avra" dev --target "$target" --port 0 "$work/tools/ui-board" >"$work/dev.out" 2>"$work/dev.err" &
dev=$!
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

# THE ENGINES: Firefox, and WebKit — the engine every iOS browser is, which reads what Firefox
# tolerates differently (a `showModal` on a dialog already open, an import encoding Firefox
# reads and WebKit does not). A lane's own run proves Firefox; the checks' job names both
# (UI_BROWSER_ENGINES="firefox webkit"). WebKit comes from Playwright, pinned, installed on first
# use; one that cannot launch is a missing browser like any other: it fails unless stood down by
# name (`skip`), and says where its libraries come from.
engines=${UI_BROWSER_ENGINES:-firefox}
playwright_version=1.64.1
case " $engines " in
    *" webkit "*)
        playwright=${PLAYWRIGHT_DIR:-$tree/build/playwright}
        # THE BROWSER STANDS WHERE THIS GUARD LOOKS. `playwright install`
        # honours PLAYWRIGHT_BROWSERS_PATH, so the directory the checks cache
        # holds the browser too, and a restored cache is VALIDATED rather than
        # assumed: one that carries the node module and no `pw_run.sh` installs
        # the browser instead of failing at launch. Guard and launcher read one
        # path, so no cache hit can be greener than a cache miss.
        browsers=$playwright/browsers
        export PLAYWRIGHT_BROWSERS_PATH="$browsers"
        if [ ! -d "$playwright/node_modules/playwright" ]; then
            mkdir -p "$playwright"
            # a machine with no npm (the checks' image) takes the one in the pinned Node (.github/ci/install_node.sh)
            command -v npm >/dev/null 2>&1 || PATH=/opt/node-jspi/bin:$PATH
            npm install --prefix "$playwright" --no-audit --no-fund "playwright@$playwright_version" >"$work/npm.out" 2>&1 ||
                skip "Playwright did not install: $(tail -1 "$work/npm.out")"
        fi
        if ! webkit_stands "$browsers"; then
            "$playwright/node_modules/.bin/playwright" install webkit >>"$work/npm.out" 2>&1 ||
                skip "Playwright's WebKit did not install: $(tail -1 "$work/npm.out")"
        fi
        export PLAYWRIGHT_DIR="$playwright"
        ;;
esac

shots=${UI_BROWSER_SHOTS:+--shots "$UI_BROWSER_SHOTS"}
for engine in $engines; do
    status=0
    out=$(node "$here/ui-board/browser.mjs" "$url" --engine "$engine" --source "$work/tools/ui-board/src/board.av" $shots 2>&1) || status=$?
    [ "$status" -ne 3 ] || skip "$(echo "$out" | tail -1) — WebKit's host libraries are .github/ci/packages-browser.txt; on a Sprite, \`sh tools/work run --browser …\` installs them"
    if [ "$status" -ne 0 ]; then
        echo "$out" | grep -v '^ok '; echo "ui-browser: the board failed in $engine"; exit 1
    fi
    echo "ui-browser: ran $(echo "$out" | grep -c '^ok ') claims, all hold, in $engine, served by \`avra dev\` at $url"
done

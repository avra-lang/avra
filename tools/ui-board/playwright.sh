# Playwright's WebKit for the browser keepers, pinned and installed on first use. Sourced by
# tools/ui_board_browser.sh and tools/layout_oracle.sh so the two share one setup.
playwright_version=1.64.1

# Whether a browser stands at the path `$1`.
webkit_stands() { [ -e "$1" ]; }

# THE PATH THE LAUNCHER RUNS, as Playwright's own module names it: the guard and the launch read
# one answer, so no cache can stand for a browser it lacks.
webkit_exe() {
    PW_PREFIX=$1 node --input-type=module -e 'const { webkit } = await import(process.env.PW_PREFIX + "/node_modules/playwright/index.mjs"); process.stdout.write(webkit.executablePath());'
}

# playwright_ready <tree> <log>: PLAYWRIGHT_DIR names a directory holding the pinned Playwright
# and its WebKit (`<tree>/build/playwright` unless set). Fails, leaving the reason in <log>.
# THE BROWSER STANDS WHERE THIS GUARD LOOKS. `playwright install` honours PLAYWRIGHT_BROWSERS_PATH,
# so the directory the checks cache holds the browser too, and a restored cache is VALIDATED rather
# than assumed: one that carries the node module and no browser installs it instead of failing at
# launch.
playwright_ready() {
    playwright=${PLAYWRIGHT_DIR:-$1/build/playwright}
    browsers=$playwright/browsers
    export PLAYWRIGHT_BROWSERS_PATH="$browsers"
    if [ ! -d "$playwright/node_modules/playwright" ]; then
        mkdir -p "$playwright"
        # a machine with no npm (the checks' image) takes the one in the pinned Node (.github/ci/install_node.sh)
        command -v npm >/dev/null 2>&1 || PATH=/opt/node-jspi/bin:$PATH
        npm install --prefix "$playwright" --no-audit --no-fund "playwright@$playwright_version" >"$2" 2>&1 || return 1
    fi
    exe=$(webkit_exe "$playwright") || return 1
    if ! webkit_stands "$exe"; then
        "$playwright/node_modules/.bin/playwright" install webkit >>"$2" 2>&1 || return 1
        exe=$(webkit_exe "$playwright") || return 1
        webkit_stands "$exe" || return 1
    fi
    export PLAYWRIGHT_DIR="$playwright"
}

#!/bin/sh
# A machine without the engine FAILS the oracle, spoken, and `--skip-if-absent` stands it down
# aloud with status 0; either way the words say 0 trees ran.
set -u
here=$(cd "$(dirname "$0")" && pwd)
bad() { echo "layout-oracle absent self-test: $1"; exit 1; }
none=$(mktemp -d "${TMPDIR:-/tmp}/avra-no-playwright.XXXXXX")
out=$(PLAYWRIGHT_DIR="$none" node "$here/layout-oracle/oracle.mjs" --browser webkit --cases 1 2>&1) && bad "a run with no WebKit exited 0"
echo "$out" | grep -q "ran 0 trees — FAILED: WebKit could not launch" || bad "the failure did not say it ran 0 trees: $out"
out=$(PLAYWRIGHT_DIR="$none" node "$here/layout-oracle/oracle.mjs" --browser webkit --cases 1 --skip-if-absent 2>&1) || bad "--skip-if-absent exited non-zero"
echo "$out" | grep -q "ran 0 trees — SKIPPED" || bad "the skip was silent: $out"
echo "layout-oracle absent self-test: no engine fails the run, --skip-if-absent says SKIPPED"

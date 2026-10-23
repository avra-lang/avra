#!/bin/sh
# A DEPENDENCY'S TESTS ARE NO INPUT, AND NO LISTING OF THEM IS ONE. The check's
# manifest confirms each covered directory's file listing without walking a
# dependency's `tests/`: adding a test file there must still hit, adding a source
# file must not. It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/dep-tests-listing-attack; fails=0
rm -rf "$R" .avra-cache && mkdir -p $R/lib/src/tests $R/app/src
cat > $R/lib/avra.toml <<'TOML'
[package]
name = "@rt/deplist"
version = "0.1.0"

[lib]
name = "rt-deplist"
path = "src/lib.av"
TOML
cat > $R/app/avra.toml <<'TOML'
[package]
name = "dep-tests-listing-attack"
version = "0.1.0"

[dependencies]
"@rt/deplist" = { path = "../lib" }
TOML
printf 'export fn one() -> int { 1 }\n' > $R/lib/src/lib.av
printf 'use @rt.deplist.{one}\n\nprintln("one ${one()}")\n' > $R/app/src/main.av
verdict() { ./avra check --time $R/app 2>&1 | grep '^time:' | head -1; }
[ -n "$(verdict)" ] || { echo "dep-tests-listing-attack: the cold check said nothing"; exit 1; }
hit="$(verdict)"
case "$hit" in *"cache hit"*) ;; *) fails=$((fails+1)); echo "FAIL  an unchanged check did not hit: $hit" ;; esac
printf 'export fn two() -> int { 2 }\n' > $R/lib/src/tests/extra.av
got="$(verdict)"
case "$got" in *"cache hit"*) ;; *) fails=$((fails+1)); echo "FAIL  a test file added to a dependency missed the cache: $got" ;; esac
printf 'export fn three() -> int { 3 }\n' > $R/lib/src/more.av
got="$(verdict)"
case "$got" in *"cache hit"*) fails=$((fails+1)); echo "FAIL  a source file added to a dependency still hit: $got" ;; esac
echo "dep-tests-listing-attack: a dependency's listing, $fails failed"
[ "$fails" -eq 0 ]

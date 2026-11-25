#!/bin/sh
set -u
cd "$(dirname "$0")/.."
R=build/cw-witness; fails=0; steps=0; holds=0
rm -rf "$R" .avra-cache && mkdir -p $R
# `avra cache` IS ITS OWN PROCESS, reading what an earlier check kept — and an
# INSPECTION KEEPS NOTHING. A check, then ONE edit, then every mode in a process of
# its own: each names the edited input, `changed` twice says the same move, `held`
# after them still reads the file, and the store's bytes are what the check left.
# A check after them keeps as it always did, and only then has nothing moved.
mkdir -p $R/cw/src/lib
printf '[package]\nname = "rt-cw"\nversion = "0.1.0"\n' > $R/cw/avra.toml
printf 'use lib.{one}\none()\n' > $R/cw/src/main.av
printf 'export fn one() -> int { 1 }\n' > $R/cw/src/lib/a.av
./avra check $R/cw >/dev/null 2>&1
tree=$(pwd)
printf 'export fn one(p: int = 0) -> int { 1 }\n' > $R/cw/src/lib/a.av
# the store's bytes, each file's checksum by path — a process's own `.users` mark aside
store_print() { (cd .avra-cache && find . -path '*/.users' -prune -o -type f -print | LC_ALL=C sort | xargs cksum); }
inspected() { (cd $R/cw && "$tree/avra" cache "$@" 2>&1); }
cache_says() { # cache_says <a line the answer holds> <the answer> <mode words...>
    steps=$((steps+1)); want=$1; said=$2; shift 2
    printf '%s\n' "$said" | grep -qF "$want" ||
        { fails=$((fails+1)); echo "FAIL  avra cache $* never said '$want': $(printf '%s\n' "$said" | head -4 | tr '\n' ' ')"; }
}
kept_before=$(store_print)
echo "store before cache: $(printf "%s\n" "$kept_before" | wc -l) files, listing cksum $(printf "%s\n" "$kept_before" | cksum)"
first=$(inspected changed); second=$(inspected changed)
cache_says "changed:   src/lib/a.av: its text " "$first" changed
cache_says "changed:   src/lib/a.av: its text " "$second" "changed, a second time"
steps=$((steps+1)); [ "$first" = "$second" ] ||
    { fails=$((fails+1)); echo "FAIL  a second avra cache changed answered otherwise: $(printf '%s\n' "$second" | head -2 | tr '\n' ' ')"; }
cache_says "held: src/lib/a.av — read" "$(inspected held)" held
cache_says "cache:   src/lib/a.av" "$(inspected)" summary
cache_says "why:   down to src/lib/a.av, whose text moved:" "$(inspected why src/main.av)" why src/main.av
cache_says "dependents:     src/main.av" "$(inspected dependents src/lib/a.av)" dependents src/lib/a.av
cache_says "held: src/lib/a.av — read" "$(inspected held src/lib/a.av)" held src/lib/a.av
steps=$((steps+1)); [ "$kept_before" = "$(store_print)" ] ||
    { fails=$((fails+1)); echo "FAIL  avra cache moved the store:"; printf '%s\n' "$kept_before" > $R/cw.before; store_print | diff $R/cw.before - | head -8; }
echo "store after cache:  $(store_print | wc -l) files, listing cksum $(store_print | cksum)"
./avra check $R/cw >/dev/null 2>&1
echo "store after check:  $(store_print | wc -l) files, listing cksum $(store_print | cksum)"
steps=$((steps+1)); [ "$kept_before" != "$(store_print)" ] ||
    { fails=$((fails+1)); echo "FAIL  a check after the edit kept nothing"; }
cache_says "changed: no input's text moved since the kept state" "$(inspected changed)" "changed, after a check"
echo "cw-witness: $steps steps, $fails failed"
printf '%s\n' "--- first changed:" "$first" "--- second changed:" "$second"

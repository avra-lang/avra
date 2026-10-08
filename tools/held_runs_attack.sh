#!/bin/sh
# A KEPT VERDICT THAT WILL NOT STAND READS ITS RUNS IN THE FIRST ATTEMPT. A
# const runs a chain of three files, each calling the next; the cold build
# records the chain as the const's runs. An edit to the chain's last file moves
# a unit the kept verdict lowered, so the verdict cannot stand and the const
# runs again — and the whole recorded chain is read at once, never learned one
# link an attempt. It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/held-runs-attack; fails=0
rm -rf "$R" .avra-cache && mkdir -p $R/app/src/s0 $R/app/src/s1 $R/app/src/s2
cat > $R/app/avra.toml <<'TOML'
[package]
name = "held-runs-attack"
version = "0.1.0"
TOML
printf 'use s1.{f1}\n\nexport fn f0() -> int { f1() + 1 }\n' > $R/app/src/s0/link.av
printf 'use s2.{f2}\n\nexport fn f1() -> int { f2() + 1 }\n' > $R/app/src/s1/link.av
printf 'export fn f2() -> int { 1 }\n' > $R/app/src/s2/link.av
printf 'use s0.{f0}\n\nconst K: int = f0()\n\nprintln("k ${K}")\n' > $R/app/src/main.av
B() { # B <label> <wanted output>: build through the store and run it
    ./avra build --time $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  $1: status $st: $(grep -vE '^watch:|^time:' $R/err | head -2 | tr '\n' ' ')"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
}
turned() { grep -oE 'discarded [0-9]+' $R/err | tail -1 | grep -oE '[0-9]+'; }
held() { grep -oE 'held [0-9]+/[0-9]+' $R/err | tail -1; }
B "cold" "k 3" || { echo "held-runs-attack: the cold build failed"; exit 1; }
printf 'export fn f2() -> int { 10 }\n' > $R/app/src/s2/link.av
if B "the chain's last link moved" "k 12"; then
    # learned link by link, the rebuild turns once for each held link: twice
    [ "$(turned)" = 0 ] || { fails=$((fails+1)); echo "FAIL  the rebuild turned $(turned) time(s): the recorded chain was learned link by link"; }
fi
echo "held-runs-attack: the moved chain rebuilt with $(turned) turned attempt(s), $(held), $fails failed"
[ "$fails" -eq 0 ]

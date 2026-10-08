#!/bin/sh
# A KEPT VERDICT THAT WILL NOT STAND ASKS ALL IT READ AT ONCE. A const runs a
# chain of files, each calling the next; the cold build keeps the const's
# verdict and the chain as what its run read. An edit to the chain's last
# link moves a body the verdict's run entered, so the verdict cannot stand
# and the const runs again — and the held links it read are asked together,
# so the rebuild turns once however long the chain, never once a link. It
# CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/held-runs-attack; fails=0; LINKS=${HELD_LINKS:-5}
rm -rf "$R" .avra-cache && mkdir -p $R/app/src
cat > $R/app/avra.toml <<'TOML'
[package]
name = "held-runs-attack"
version = "0.1.0"
TOML
last() { printf 'export fn f%s() -> int { %s }\n' $((LINKS - 1)) "$1" > $R/app/src/s$((LINKS - 1))/link.av; }
i=0
while [ $i -lt $LINKS ]; do
    mkdir -p $R/app/src/s$i
    next=$((i + 1))
    [ $next -lt $LINKS ] && printf 'use s%s.{f%s}\n\nexport fn f%s() -> int { f%s() + 1 }\n' $next $next $i $next > $R/app/src/s$i/link.av
    i=$next
done
last 1
printf 'use s0.{f0}\n\nconst K: int = f0()\n\nprintln("k ${K}")\n' > $R/app/src/main.av
B() { # B <label> <wanted output>: build through the store and run it
    ./avra build --time $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  $1: status $st: $(grep -vE '^watch:|^time:' $R/err | head -2 | tr '\n' ' ')"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
}
turned() { grep -oE 'discarded [0-9]+' $R/err | tail -1 | grep -oE '[0-9]+'; }
B "cold" "k $LINKS" || { echo "held-runs-attack: the cold build failed"; exit 1; }
last 10
if B "the chain's last link moved" "k $((LINKS + 9))"; then
    # learned link by link, the rebuild turns once for each held link
    [ "$(turned)" -le 1 ] || { fails=$((fails+1)); echo "FAIL  the rebuild turned $(turned) time(s) over a $LINKS-link chain: the verdict's reads were learned link by link"; }
fi
echo "held-runs-attack: a $LINKS-link chain's last link moved, rebuilt with $(turned) turned attempt(s), $fails failed"
[ "$fails" -eq 0 ]

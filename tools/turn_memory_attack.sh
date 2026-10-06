#!/bin/sh
# ONE DERIVATION ALIVE AT A TIME, ATTACKED BY MEMORY. A const that runs a chain
# of held bodies turns the derivation once per link: each attempt learns of one
# more file it must read, and a fresh workspace reads it. Every turned attempt
# must be let go before the next begins — kept, they stand side by side and the
# build's peak is their SUM. So the rebuild runs under a ceiling a few times
# the cold build's own peak: one attempt at a time clears it, the sum trips it.
set -u
cd "$(dirname "$0")/.."
R=build/turn-memory-attack; fails=0
LINKS=${TURN_LINKS:-12}; PAD=${TURN_PAD:-120}
rm -rf "$R" .avra-cache && mkdir -p $R/app/src
cat > $R/app/avra.toml <<'TOML'
[package]
name = "turn-memory-attack"
version = "0.1.0"
TOML
# link i: one fn the chain runs, and bulk an attempt that reads the file carries
i=0
while [ $i -lt $LINKS ]; do
    mkdir -p $R/app/src/s$i
    next=$((i+1))
    {
        if [ $next -lt $LINKS ]; then
            printf 'use s%s.{f%s}\n\nexport fn f%s() -> int { f%s() + 1 }\n' $next $next $i $next
        else
            printf 'export fn f%s() -> int { 1 }\n' $i
        fi
        j=0
        while [ $j -lt $PAD ]; do
            printf 'export fn pad%s_%s(x: int) -> int { if x > %s { x * %s + 1 } else { x - %s } }\n' $i $j $j $j $j
            j=$((j+1))
        done
    } > $R/app/src/s$i/link.av
    i=$((i+1))
done
printf 'use s0.{f0}\n\nprintln("v ${f0()}")\n' > $R/app/src/main.av
# the peak a build reports, in MB — the runtime's own accounting, the largest
# of the processes that spoke
peak() { grep -oE 'peak +[0-9]+ MB in all' "$1" | grep -oE '[0-9]+' | sort -n | tail -1; }
B() { # B <label> <ceiling MB>: build through the store under a ceiling
    AVRA_MEM_CEILING_MB=$2 AVRA_MEM_STATS=1 ./avra build --time $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] && return 0
    fails=$((fails+1)); echo "FAIL  $1: status $st under a ${2} MB ceiling: $(grep -vE '^watch:|^mem:|^time:' $R/err | head -2 | tr '\n' ' ')"
    return 1
}
B "cold" 4000 || { echo "turn-memory-attack: the cold build failed"; exit 1; }
cold=$(peak $R/err)
# the const runs the chain at compile time, and every link's body is held
printf 'use s0.{f0}\n\nconst K: int = f0()\n\nprintln("k ${K}")\n' > $R/app/src/main.av
ceiling=$((cold * 3))
if B "the chain turns the derivation" $ceiling; then
    turned=$(grep -oE 'discarded [0-9]+' $R/err | tail -1 | grep -oE '[0-9]+')
    got=$($R/app/src/main 2>&1)
    [ "$got" = "k $LINKS" ] || { fails=$((fails+1)); echo "FAIL  the rebuilt program printed '$got', wanted 'k $LINKS'"; }
    # A RUN THAT NEVER TURNED ATTACKED NOTHING: one attempt clears any ceiling.
    [ "${turned:-0}" -ge $((LINKS / 2)) ] || { fails=$((fails+1)); echo "FAIL  the derivation turned ${turned:-0} time(s), under $((LINKS / 2)) — the attack examined nothing"; }
    echo "turn-memory-attack: cold peak ${cold} MB, ${turned:-0} turned attempts peaked at $(peak $R/err) MB under a ${ceiling} MB ceiling, $fails failed"
else
    echo "turn-memory-attack: cold peak ${cold} MB, the turned rebuild did not clear a ${ceiling} MB ceiling, $fails failed"
fi
[ "$fails" -eq 0 ]

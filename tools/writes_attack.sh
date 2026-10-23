#!/bin/sh
# A FN'S WRITE BIT MOVES EXACTLY ITS READERS. A method whose body starts writing through
# `self` is heard by the callers that read that fn's bit and by no other body: a reader
# stands on the one fn's answer, never on the whole survey of which seats are written.
set -u
cd "$(dirname "$0")/.."
A=${AVRA_BIN:-build/avra}
export AVRA_MAX_COMPILES=0
R=build/writes-attack
T=build/aside/wa.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/wa
P=$R/wr; mkdir -p $P/src
printf '[package]\nname = "wr"\nversion = "0.1.0"\n' > $P/avra.toml
who=writes-attack
. tools/lib/steps.sh
{
    printf 'export type C = { n: int }\nimpl C {\n'
    for i in 1 2 3 4 5 6; do printf '    export fn m%s() -> int { self.n + %s }\n' $i $i; done
    printf '}\n'
    for i in 1 2 3 4 5 6; do printf 'export fn r%s(c: C) -> int { c.m%s() }\n' $i $i; done
} > $P/src/lib.av
printf 'use lib.{C, r1}\nlet c = C { n: 1 }\nprintln("${r1(c)}")\n' > $P/src/main.av
$A check $P > /dev/null 2>&1
cp $P/src/lib.av $T/lib.orig
sed 's/export fn m3() -> int { self.n + 3 }/export fn m3() -> int {\n        self.n = 3\n        3\n    }/' $T/lib.orig > $P/src/lib.av
$A check $P > $T/after 2>&1
grep -q "r3" $T/after || fail "the reader of the fn that began writing was not told"
for i in 1 2 4 5 6; do grep -q "r$i" $T/after && fail "a reader of a fn that did not move was told: r$i"; done
verdict "one fn began writing, only its reader was told"

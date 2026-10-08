#!/bin/sh
# A CALLEE THAT STARTS TO WAIT RE-CHECKS ITS CALLERS. Whether a call may reach
# a cancel point is part of the callee's interface (its record's two bits,
# parks and spins), so an edit that changes either moves the key of every file
# that calls it, though no signature moved; an edit that moves neither leaves
# the caller held. Each step edits the callee, asks the caller's hold, then
# checks so the next step starts from a kept state.
set -u
cd "$(dirname "$0")/.."

R=build/cancel-cache-attack; fails=0; steps=0
rm -rf "$R" .avra-cache && mkdir -p $R/src/lib
printf '[package]\nname = "rt-cc"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'use lib.{work}\nfn handle() -> int { work() }\nhandle()\n' > $R/src/main.av
printf 'export fn work() -> int { 1 }\n' > $R/src/lib/a.av
./avra check $R >/dev/null 2>&1
tree=$(pwd)
inspected() { (cd $R && "$tree/avra" explain "$@" 2>&1); }
says() { # says <label> <a line the answer holds> <the answer>
    steps=$((steps+1))
    printf '%s\n' "$3" | grep -qF -- "$2" ||
        { fails=$((fails+1)); echo "FAIL  $1: never said '$2': $(printf '%s\n' "$3" | head -3 | tr '\n' ' ')"; }
}
callee() { printf '%s\n' "$1" > $R/src/lib/a.av; }
kept() { ./avra check $R >/dev/null 2>&1; }

callee 'export fn work() -> int { 2 }'
says "a body edit that moves no bit" "src/main.av — held" "$(inspected src/main.av --why)"
kept

callee 'extern fn avra_fiber_sleep(ms: int)
export fn work() -> int {
    avra_fiber_sleep(0)
    2
}'
says "the callee starts to park" "src/main.av — read" "$(inspected src/main.av --why)"
kept
said=$(inspected @handle)
says "the caller now parks" "\`handle\` may reach a cancel point" "$said"
says "the caller's parks bit names its callee" "  parks — calls \`work\`" "$said"

callee 'export fn work() -> int {
    mut i = 0
    while i < 2 { i = i + 1 }
    i
}'
says "the callee stops parking and starts to spin" "src/main.av — read" "$(inspected src/main.av --why)"
kept
said=$(inspected @handle)
says "the caller now spins and does not park" "  spins — calls \`work\`" "$said"
says "the caller's parks bit fell" "  parks — no" "$said"

callee 'export fn work() -> int {
    mut i = 0
    while i < 3 { i = i + 1 }
    i
}'
says "a spinning body edit that moves no bit" "src/main.av — held" "$(inspected src/main.av --why)"

echo "cancel cache attack: $steps step(s), $fails failed"
[ "$fails" -eq 0 ]

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
# `inspected` runs in a command substitution, so the file it was asked
# about is noted on disk, not in a variable the subshell would drop.
inspected() {
    case "$1" in *.av) printf '%s\n' "$1" >> $R/.inspected ;; esac
    (cd $R && "$tree/avra" explain "$@" 2>&1)
}
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

callee 'export fn work() -> int {
    mut i = 0
    while i < 2 { i = i + 1 }
    i
}'
says "the callee starts to spin, moving the spins bit alone" "src/main.av — read" "$(inspected src/main.av --why)"
kept
said=$(inspected @handle)
says "the caller now spins" "  spins — calls \`work\`" "$said"
says "the caller's parks bit stays clear" "  parks — no" "$said"
says "the caller may reach a cancel point" "\`handle\` may reach a cancel point" "$said"

callee 'extern fn avra_fiber_sleep(ms: int)
export fn work() -> int {
    avra_fiber_sleep(0)
    2
}'
says "the callee stops spinning and starts to park" "src/main.av — read" "$(inspected src/main.av --why)"
kept
said=$(inspected @handle)
says "the caller now parks" "\`handle\` may reach a cancel point" "$said"
says "the caller's parks bit names its callee" "  parks — calls \`work\`" "$said"
says "the caller's spins bit fell" "  spins — no" "$said"

callee 'extern fn avra_fiber_sleep(ms: int)
export fn work() -> int {
    avra_fiber_sleep(0)
    3
}'
says "a parking body edit that moves no bit" "src/main.av — held" "$(inspected src/main.av --why)"

files=$(sort -u $R/.inspected 2>/dev/null | grep -c .)
echo "cancel cache attack: $steps step(s), $fails failed, $files file(s) inspected"
[ "$fails" -eq 0 ]

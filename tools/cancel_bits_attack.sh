#!/bin/sh
# A FN'S CANCEL BITS MOVE EXACTLY ITS READERS. A body that starts reaching a cancel
# point is heard by the caller that reads that fn's `CancelBits` answer, and by no
# other body: a reader stands on the one fn's answer, never on the whole survey.
# Each caller is its own module, so `explain <file> --why` says whether that module's
# answer was recomputed (read) or stood (held).
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${AVRA_BIN:-build/avra}
export AVRA_MAX_COMPILES=0
R=build/cancel-bits-attack
T=build/aside/cba.$$; mkdir -p "$T"
[ -e "$R" ] && mv "$R" "$T/cba"
P=$R/cb
for d in lib byst mid idle cyc link uselink; do mkdir -p "$P/src/$d"; done
printf '[package]\nname = "cb"\nversion = "0.1.0"\n' > "$P/avra.toml"
printf 'export fn work() -> int { 1 }\n' > "$P/src/lib/a.av"
printf 'export fn quiet() -> int { 9 }\n' > "$P/src/byst/a.av"
printf 'use lib.{work}\nexport fn handle() -> int { work() }\n' > "$P/src/mid/a.av"
printf 'use byst.{quiet}\nexport fn idle() -> int { quiet() }\n' > "$P/src/idle/a.av"
printf 'export fn cyc_a() -> int { cyc_b() }\nexport fn cyc_b() -> int { cyc_a() }\n' > "$P/src/cyc/a.av"
printf 'use mid.{handle}\nuse idle.{idle}\nfn entry() -> int { handle() + idle() }\nentry()\n' > "$P/src/main.av"
$A check "$P" >/dev/null 2>&1
tree=$(pwd)
# `inspected` runs in a command substitution, so the file it was asked about is noted
# on disk, not in a variable the subshell would drop.
inspected() {
    case "$1" in *.av) printf '%s\n' "$1" >> "$R/.inspected" ;; esac
    (cd "$P" && "$tree/avra" explain "$@" 2>&1)
}
says() { # says <label> <a line the answer holds> <the answer>
    steps=$((steps + 1))
    printf '%s\n' "$3" | grep -qF -- "$2" ||
        { fail "$1: never said '$2': $(printf '%s\n' "$3" | head -3 | tr '\n' ' ')"; }
}
kept() { $A check "$P" >/dev/null 2>&1; }

# a body edit that moves no bit leaves both callers held
printf 'export fn work() -> int { 2 }\n' > "$P/src/lib/a.av"
says "a body edit that moves no bit leaves the caller held" "src/mid/a.av — held" "$(inspected src/mid/a.av --why)"
kept

# work starts to spin: only mid (its reader) moves; idle is a bystander
printf 'export fn work() -> int {\n    mut i = 0\n    while i < 2 { i = i + 1 }\n    i\n}\n' > "$P/src/lib/a.av"
says "the moved fn's reader is recomputed" "src/mid/a.av — read" "$(inspected src/mid/a.av --why)"
says "a bystander stays held" "src/idle/a.av — held" "$(inspected src/idle/a.av --why)"
kept
said=$(inspected @handle)
says "the reader now spins" "  spins — calls \`work\`" "$said"
says "the reader may reach a cancel point" "\`handle\` may reach a cancel point" "$said"
byst=$(inspected @idle)
says "the bystander reaches no cancel point" "\`idle\` reaches no cancel point" "$byst"

# a cycle settles both: cyc_b starts to spin, cyc_a reaches it through the cycle
printf 'export fn cyc_a() -> int { cyc_b() }\nexport fn cyc_b() -> int {\n    mut i = 0\n    while i < 2 { i = i + 1 }\n    i\n}\n' > "$P/src/cyc/a.av"
a=$(inspected @cyc_a)
says "a cycle's caller settles to may-reach" "\`cyc_a\` may reach a cancel point" "$a"
says "a cycle's caller names its spinning callee" "  spins — calls \`cyc_b\`" "$a"
b=$(inspected @cyc_b)
says "a cycle's spinner settles to may-reach" "\`cyc_b\` may reach a cancel point" "$b"
says "a cycle's spinner spins of its own" "  spins — a \`while\` here" "$b"

# the #705 links bit rides along: an edit that moves ONLY `links` must recompute the
# reader. `relay` calls through a value — it PARKS and SPINS but links nothing — and
# `calls_it` calls it by name; the edit adds a spawn of a named fn while KEEPING the
# value call, so parks and spins stand while the links bit turns on. A digest over the
# 2-bit word would not move and the reader would keep a stale answer; only the 3-bit
# word moves it.
printf 'fn helper() -> int { 1 }\nexport fn relay(f: fn() -> int) -> int { f() }\n' > "$P/src/link/a.av"
printf 'use link.{relay}\nexport fn calls_it() -> int { relay(() -> 1) }\n' > "$P/src/uselink/a.av"
kept
says "the value-caller parks and spins" "  parks — calls through a value" "$(inspected @relay)"
says "the links-standstill leaves the reader held" "src/uselink/a.av — held" "$(inspected src/uselink/a.av --why)"
printf 'fn helper() -> int { 1 }\nexport fn relay(f: fn() -> int) -> int {\n    let t = spawn helper()\n    t.await\n    f()\n}\n' > "$P/src/link/a.av"
says "a links-only move recomputes the reader" "src/uselink/a.av — read" "$(inspected src/uselink/a.av --why)"
says "a links-only move leaves a bystander held" "src/idle/a.av — held" "$(inspected src/idle/a.av --why)"

files=$(sort -u "$R/.inspected" 2>/dev/null | grep -c .)
echo "cancel-bits attack: $steps step(s), $fails failed, $files file(s) inspected"
[ "$fails" -eq 0 ]

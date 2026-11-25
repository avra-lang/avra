#!/bin/sh
# WHAT A WAVE'S PROCESSES SHARE NEVER COSTS AN ANSWER. The processes of a wave keep what they learn
# in one table as they learn it, and each claims there the question it is working out. One package
# whose files all read one module, so every process needs what another is working out, built cold:
# sharing; each working alone (`AVRA_WAVE_ALONE`); with the holder of a claim killed holding it
# (`AVRA_SHARED_KILL_AT`); with the holder of a claim trapped holding it (`AVRA_SHARED_TRAP_AT`);
# and across one, two and three processes. Each binary must be the first one's, and a build after
# each must stand on the store it left. A killed or trapped holder must have ended a process, or
# the case met no claim; holders of several claims are ended in turn, since which process holds
# one and which waits for it differs, and every build is bounded: a waiter must go on once the
# holder has ended, reaped or not.
#
#   sh tools/wave_share_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${WAVE_ATTACK_AVRA:-$(pwd)/avra}
R=build/wave-share-attack
find "$R" -delete 2>/dev/null; mkdir -p "$R"
unset AVRA_WAVE_ALONE AVRA_SHARED_KILL_AT AVRA_SHARED_TRAP_AT AVRA_WORK_AHEAD_CORES

# The package: forty files, each calling a fn of one shared module, and an entry summing them.
package() {
    p=$R/pkg
    find "$p" -delete 2>/dev/null; mkdir -p "$p/src"
    printf '[package]\nname = "wave"\nversion = "0.1.0"\n' > "$p/avra.toml"
    printf 'export fn base(n: int) -> int { n + 1 }\n' > "$p/src/shared.av"
    uses=""; sum="0"
    for k in $(seq 0 39); do
        printf 'use shared.{base}\nexport fn f%s() -> int { base(%s) }\n' "$k" "$k" > "$p/src/f$k.av"
        uses="${uses}use f$k.{f$k}\n"; sum="$sum + f$k()"
    done
    printf "${uses}\nprintln(\"\${$sum}\")\n" > "$p/src/main.av"
    own_store "$p"
}

# The package built cold under the settings `$@`, then built again: its binary's digest, whether the
# second build stood, what the binary says, and whether a process of the first build did not finish.
built() {
    package
    sh tools/bounded.sh 120 env "$@" "$A" build "$R/pkg" > "$R/pkg.build" 2>&1 || { echo "BUILD FAILED OR OUTLASTED 120s"; return; }
    ended=$(grep -c "working ahead didn't finish" "$R/pkg.build")
    stood=$(env "$@" "$A" build "$R/pkg" --time 2>&1 >/dev/null | grep -c 'cache hit')
    echo "$(cksum < "$R/pkg/src/main") stood=$stood ended=$ended said=$("$R/pkg/src/main")"
}
binary() { echo "$1" | sed 's/ stood=.*//'; }
field() { echo "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2; }
# `$2` held to the first build `$1`: one binary, and a store the next build stands on.
alike() {
    [ "$(binary "$2")" = "$(binary "$1")" ] || fail "$3: the binary is not the shared build's: $2"
    [ "$(field "$2" stood)" = 1 ] || fail "$3: the build after did not stand"
}

steps=$((steps + 1)); shared=$(built)
[ "$(field "$shared" said)" = 820 ] || fail "sharing, the build says: $shared"
[ "$(field "$shared" stood)" = 1 ] || fail "sharing, the build after did not stand"
steps=$((steps + 1)); alone=$(built AVRA_WAVE_ALONE=1); alike "$shared" "$alone" "each alone"
for nth in 3 5 7 9 11 13; do
    steps=$((steps + 1)); killed=$(built AVRA_SHARED_KILL_AT=$nth); alike "$shared" "$killed" "the holder of claim $nth killed"
    [ "$(field "$killed" ended)" -ge 1 ] || fail "the holder of claim $nth killed: no process ended, so no claim was met"
done
for nth in 4 8 12; do
    steps=$((steps + 1)); trapped=$(built AVRA_SHARED_TRAP_AT=$nth); alike "$shared" "$trapped" "the holder of claim $nth trapped"
    [ "$(field "$trapped" ended)" -ge 1 ] || fail "the holder of claim $nth trapped: no process ended, so no claim was met"
done
for n in 1 2 3; do
    steps=$((steps + 1)); across=$(built AVRA_WORK_AHEAD_CORES=$n); alike "$shared" "$across" "across $n process(es)"
done
verdict "wave-share-attack: $steps step(s)" "sharing, alone, a holder killed, a holder trapped, across 1 2 3"

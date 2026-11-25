#!/bin/sh
# THE CODE HASHES ANSWERED BESIDE THE REFUSALS ARE THE ONES ANSWERED AFTER THEM. Once a program's
# bodies are placed, one process answers its code hashes while the asking process answers its
# refusals, and the asking process takes them. One package, built cold: beside; with nothing
# forked (`AVRA_WORK_AHEAD_OFF`); with the process ended as soon as it is forked
# (`AVRA_BESIDE=killed`); and with the asking process wanting nothing of it
# (`AVRA_BESIDE=unwanted`). Each binary must be the first one's and a build after each must stand.
# Then the package refused: the build must say what a build forking nothing says, exit as it
# does, and leave no process and none of the process's answers behind.
#
#   sh tools/beside_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${BESIDE_ATTACK_AVRA:-$(pwd)/avra}
R=build/beside-attack
find "$R" -delete 2>/dev/null; mkdir -p "$R"
unset AVRA_BESIDE AVRA_WORK_AHEAD_OFF AVRA_QUERY_TIMES

# The package at `$R/pkg`: an entry printing the sum of enough files that every wave forks; with
# `$1` set, one file answers a string where it says an int.
package() {
    p=$R/pkg
    find "$p" -delete 2>/dev/null; mkdir -p "$p/src"
    printf '[package]\nname = "beside"\nversion = "0.1.0"\n' > "$p/avra.toml"
    uses=""; sum="0"
    for k in $(seq 0 39); do
        printf 'export fn f%s() -> int { %s }\n' "$k" "$k" > "$p/src/f$k.av"
        uses="${uses}use f$k.{f$k}\n"; sum="$sum + f$k()"
    done
    [ -z "${1:-}" ] || printf 'export fn f7() -> int { "seven" }\n' > "$p/src/f7.av"
    printf "${uses}\nprintln(\"\${$sum}\")\n" > "$p/src/main.av"
    own_store "$p"
}

# The package built cold under the settings `$@`, then built again: its binary's digest, whether a
# process answered beside, whether one didn't finish, and whether the second build stood.
built() {
    package
    env AVRA_QUERY_TIMES=1 "$@" "$A" build "$R/pkg" > "$R/pkg.build" 2>&1 || { echo "BUILD FAILED"; return; }
    beside=$(grep -c "^beside: 1 cores' answers taken" "$R/pkg.build")
    short=$(grep -c "cores working ahead didn't finish" "$R/pkg.build")
    ended=$(grep -c "^beside: the process ended, nothing of it taken" "$R/pkg.build")
    stood=$(env "$@" "$A" build "$R/pkg" --time 2>&1 >/dev/null | grep -c 'cache hit')
    echo "$(cksum < "$R/pkg/src/main") beside=$beside short=$short ended=$ended stood=$stood said=$("$R/pkg/src/main")"
}
binary() { echo "$1" | sed 's/ beside=.*//'; }
field() { echo "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2; }

# The refused package built cold under the settings `$@`: its exit status, then what it said.
refused() {
    package refused
    env "$@" "$A" build "$R/pkg" > "$R/refused.out" 2>&1
    echo "exit=$?"
    cat "$R/refused.out"
}

steps=$((steps + 1)); beside=$(built)
[ "$(field "$beside" said)" = 780 ] || fail "beside, the build says: $beside"
[ "$(field "$beside" beside)" = 1 ] || fail "no process answered beside the asking one: $(cat "$R/pkg.build" | tail -5)"
[ "$(field "$beside" stood)" = 1 ] || fail "beside, the build after did not stand"
steps=$((steps + 1)); alone=$(built AVRA_WORK_AHEAD_OFF=1)
[ "$(binary "$alone")" = "$(binary "$beside")" ] || fail "with nothing forked, the binary is not the one built beside: $alone"
[ "$(field "$alone" beside)" = 0 ] || fail "with nothing forked, a process answered beside"
steps=$((steps + 1)); killed=$(built AVRA_BESIDE=killed)
[ "$(binary "$killed")" = "$(binary "$beside")" ] || fail "with the process ended, the binary is not the one built beside: $killed"
[ "$(field "$killed" short)" = 1 ] || fail "with the process ended, the build does not say it did not finish: $killed"
[ "$(field "$killed" stood)" = 1 ] || fail "with the process ended, the build after did not stand"
steps=$((steps + 1)); unwanted=$(built AVRA_BESIDE=unwanted)
[ "$(binary "$unwanted")" = "$(binary "$beside")" ] || fail "with nothing wanted of the process, the binary is not the one built beside: $unwanted"
[ "$(field "$unwanted" beside)" = 0 ] || fail "with nothing wanted of the process, its answers were taken"
[ "$(field "$unwanted" ended)" = 1 ] || fail "with nothing wanted of the process, it was not ended: $unwanted"
[ "$(field "$unwanted" stood)" = 1 ] || fail "with nothing wanted of the process, the build after did not stand"
steps=$((steps + 1)); serial=$(refused AVRA_WORK_AHEAD_OFF=1); forked=$(refused)
[ "$(echo "$serial" | head -1)" != "exit=0" ] || fail "the refused package built"
[ "$forked" = "$serial" ] || fail "refused, the build says other than one forking nothing: $(echo "$forked" | head -3)"
timed=$(refused AVRA_QUERY_TIMES=1)
echo "$timed" | grep -q "^beside: the process ended, nothing of it taken" || fail "refused, no process was ended beside the refusals"
sleep 1
[ -z "$(pgrep -f "build $R/pkg")" ] || fail "refused, a process of the build is left"
left=$(ls "$R/pkg/.avra-cache/tapes-ahead" 2>/dev/null | grep -c '^[0-9][0-9]*-[0-9][0-9]*$')
[ "$left" = 0 ] || fail "refused, $left of the processes' answers are left"
verdict "beside-attack: $steps step(s)" "beside, nothing forked, ended, unwanted, refused"

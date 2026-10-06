#!/bin/sh
# FIXTURES FOR tools/sprite-remote.sh's runs — the supervisor, attach at an
# offset, the status a run leaves, its bound, stop. They need Linux (/proc,
# setsid) and no Sprite: AVRA_SPRITE_HOME moves every run record under
# this run's scratch. On a lane: `sh tools/work run sh tools/sprite_remote_test.sh`.
#
# `sh tools/sprite_remote_test.sh` prints a summary; a non-zero exit is a failure.
set -u
[ "$(uname -s)" = Linux ] || { echo "sprite_remote_test: SKIPPED — a run's supervisor needs Linux"; exit 0; }

here="$(cd "$(dirname "$0")" && pwd)"
script=$(cat "$here/sprite-remote.sh")
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-remote-test.XXXXXX")
export AVRA_SPRITE_HOME="$scratch/home"
mkdir -p "$scratch/tree"
trap 'rm -rf "$scratch"' EXIT
# The fixtures' own runs are not the lane's run that carries them.
unset AVRA_RUN

total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }
check() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (got '$1', wanted '$2')" "${4:-}"; fi; }

remote() { sh -c 'AVRA_REMOTE_SCRIPT=$1; shift; eval "$AVRA_REMOTE_SCRIPT"' avra-remote "$script" "$@"; }
begin() { id=$1 cmd_s=$2; shift 2; remote start "$id" "fixture 0 0" 60 "$cmd_s" "$scratch/tree" - "$@"; }
# How many processes still carry the run's mark.
left() {
    n=0
    for e in /proc/[0-9]*/environ; do
        tr '\0' '\n' 2>/dev/null < "$e" | grep -qx "AVRA_RUN=$1" && n=$((n + 1))
    done
    echo "$n"
}
# Waits up to $2 seconds for the run to answer, then up to ten more for its last process to go.
settled() {
    i=0
    while [ "$i" -lt "$2" ] && [ "$(remote result "$1")" = running ]; do sleep 1; i=$((i + 1)); done
    i=0
    while [ "$i" -lt 10 ] && [ "$(left "$1")" != 0 ]; do sleep 1; i=$((i + 1)); done
}

# ══ A DROP MID-RUN: the client asks again from its offset, and has every byte once
begin drop 60 sh -c 'i=0; while [ $i -lt 8 ]; do i=$((i + 1)); echo "line $i"; sleep 1; done; exit 7' > /dev/null
# The first attach dies as a dropped session does: the whole of it, at once.
setsid sh -c 'AVRA_REMOTE_SCRIPT=$1; shift; eval "$AVRA_REMOTE_SCRIPT"' avra-remote "$script" attach drop 0 > "$scratch/got" &
a=$!
sleep 3
kill -KILL "-$a" 2>/dev/null
wait "$a" 2>/dev/null
first=$(wc -c < "$scratch/got")
during=$(remote result drop)
remote attach drop "$first" >> "$scratch/got"
settled drop 20
check "$during|$(grep -c '^line' "$scratch/got")|$(grep '^line' "$scratch/got" | tr '\n' ' ')|$(remote result drop)|$(left drop)" \
    "running|8|line 1 line 2 line 3 line 4 line 5 line 6 line 7 line 8 |status 7|0" \
    "a client dropped mid-run attaches again at its offset: every line once, the command's status, nothing left running" "$scratch/got"
[ "$first" -gt 0 ] && [ "$first" -lt "$(wc -c < "$scratch/got")" ] && ok "the drop fell inside the output (byte $first of $(wc -c < "$scratch/got" | tr -d ' '))" || bad "the drop did not fall mid-output (first=$first) — the case above proved nothing"

# ══ A DROP AFTER THE END: the status and the output are still there ════
begin after 60 sh -c 'echo only; exit 5' > /dev/null
settled after 20
check "$(remote result after)|$(remote attach after 0 | grep -c '^only$')|$(left after)" "status 5|1|0" "a run nobody was attached to keeps its status and its output"

# ══ ONE RUN AT A TIME, and a stop reaches a child in its own session ══
begin long 60 sh -c 'setsid sleep 4242 & sleep 4243' > /dev/null
sleep 2
begin second 60 true > "$scratch/busy" 2>&1
st=$?
check "$st $(grep -c '^busy=long ' "$scratch/busy") $([ -d "$AVRA_SPRITE_HOME/avra-runs/second" ] && echo made || echo none)" "76 1 none" "a second run is refused with 76 and the first's name" "$scratch/busy"
before=$(left long)
remote stop long
settled long 5
check "$([ "$before" -ge 3 ] && echo ran) $(left long) $(pgrep -fc '^sleep 424[23]$') $(remote result long)" "ran 0 0 status 143" "a stop ends every process of the run, the one in its own session too, and the run answers 143"

# ══ THE BOUND: a command past it is ended, and the status says so ═════
begin bound 3 sh -c 'echo begun; sleep 4244' > /dev/null
settled bound 30
check "$(remote result bound)|$(remote attach bound 0 | grep -c 'passed its 3s bound')|$(left bound)|$(pgrep -fc '^sleep 4244$')" "status 124|1|0|0" "a command past its bound is stopped: 124, the reason in its output, nothing left running"

# ══ THE SUPERVISOR KILLED: its keeper ends the rest and settles the status
begin killed 60 sh -c 'sleep 4245' > /dev/null
sleep 2
kill -KILL "$(cat "$AVRA_SPRITE_HOME/avra-runs/killed/pid")"
settled killed 20
check "$(remote result killed)|$(left killed)|$(pgrep -fc '^sleep 4245$')" "status 143|0|0" "with its supervisor killed outright, the keeper ends what is left and the run still answers"

# ══ A NEW RUN CLEARS THE OLD RECORDS, and a record that never was is `gone`
begin fresh 60 true > /dev/null
settled fresh 20
check "$(remote result fresh)|$(remote result bound)|$(remote result nobody)" "status 0|gone|gone" "a new run clears the ended ones; a run with no record is gone"

echo "----------------------------------------"
echo "sprite_remote_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]

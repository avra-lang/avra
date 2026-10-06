#!/bin/sh
# FIXTURES FOR tools/sprite-remote.sh's runs — the supervisor, attach at an
# offset, the status a run leaves, its bound, stop. They need Linux (/proc,
# setsid) and no Sprite: AVRA_SPRITE_HOME moves every run record under
# this run's scratch. On a lane: `sh tools/work run sh tools/sprite_remote_test.sh`.
#
# `sh tools/sprite_remote_test.sh` prints a summary; a non-zero exit is a
# failure. Every wait here is bounded, so a behaviour that is gone reads
# as a FAIL line and never as a hang.
set -u
[ "$(uname -s)" = Linux ] || { echo "sprite_remote_test: SKIPPED, 0 checks — a run's supervisor needs Linux (/proc, setsid); \`sh tools/work run sh tools/work_test.sh\` runs them"; exit 0; }

here="$(cd "$(dirname "$0")" && pwd)"
script=$(cat "$here/sprite-remote.sh")
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-remote-test.XXXXXX")
export AVRA_SPRITE_HOME="$scratch/home"
mkdir -p "$scratch/tree"
# The fixtures' own runs are not the lane's run that carries them.
unset AVRA_RUN
# No attach here follows a run longer than this: one that should have ended and did not is a FAIL, never a wait.
export AVRA_ATTACH_S=30

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
# A run's state without its byte count.
res() { remote result "$1" | awk '{ print ($1 == "status") ? $1 " " $2 : $1 }'; }
# Waits up to $2 seconds for the run to answer, then up to ten more for
# its last process to go. A run still going then is a failure of its
# own, and is ended here so the next case starts on a free Sprite.
settled() {
    i=0
    while [ "$i" -lt "$2" ] && [ "$(res "$1")" = running ]; do sleep 1; i=$((i + 1)); done
    if [ "$(res "$1")" = running ]; then
        bad "$1 was still running after ${2}s — ended by the fixture, whose stop is not the run's own end"
        remote stop "$1"
    fi
    i=0
    while [ "$i" -lt 10 ] && [ "$(left "$1")" != 0 ]; do sleep 1; i=$((i + 1)); done
}
# Nothing a fixture started outlives the fixtures, pass or fail.
swept() {
    for d in "$AVRA_SPRITE_HOME"/avra-runs/*/; do
        [ -d "$d" ] && remote stop "$(basename "$d")" 2>/dev/null
    done
    rm -rf "$scratch"
}
trap swept EXIT
pid_of() { cat "$AVRA_SPRITE_HOME/avra-runs/$1/pid"; }
# The run's keeper: the supervisor's child that is the script's `keeper`.
keeper_of() { pgrep -P "$(pid_of "$1")" -f "remote.sh keeper $1 " | head -n 1; }

# ══ A DROP MID-RUN: the client asks again from its offset, and has every byte once
begin drop 60 sh -c 'i=0; while [ $i -lt 8 ]; do i=$((i + 1)); echo "line $i"; sleep 1; done; exit 7' > /dev/null
# The first attach dies as a dropped session does: the whole of it, at once.
setsid sh -c 'AVRA_REMOTE_SCRIPT=$1; shift; eval "$AVRA_REMOTE_SCRIPT"' avra-remote "$script" attach drop 0 > "$scratch/got" &
a=$!
sleep 3
kill -KILL "-$a" 2>/dev/null
wait "$a" 2>/dev/null
first=$(wc -c < "$scratch/got")
during=$(res drop)
remote attach drop "$first" >> "$scratch/got"
settled drop 20
check "$during|$(grep -c '^line' "$scratch/got")|$(grep '^line' "$scratch/got" | tr '\n' ' ')|$(res drop)|$(left drop)" \
    "running|8|line 1 line 2 line 3 line 4 line 5 line 6 line 7 line 8 |status 7|0" \
    "a client dropped mid-run attaches again at its offset: every line once, the command's status, nothing left running" "$scratch/got"
[ "$first" -gt 0 ] && [ "$first" -lt "$(wc -c < "$scratch/got")" ] && ok "the drop fell inside the output (byte $first of $(wc -c < "$scratch/got" | tr -d ' '))" || bad "the drop did not fall mid-output (first=$first) — the case above proved nothing"

# ══ A DROP AFTER THE END: the status and the output are still there ════
begin after 60 sh -c 'echo only; exit 5' > /dev/null
settled after 20
check "$(remote result after)" "status 5 $(wc -c < "$AVRA_SPRITE_HOME/avra-runs/after/out" | tr -d ' ')" "a run's answer carries how many bytes it wrote, so a follower knows when it has them all"
check "$(res after)|$(remote attach after 0 | grep -c '^only$')|$(left after)" "status 5|1|0" "a run nobody was attached to keeps its status and its output"

# ══ ONE RUN AT A TIME, and a stop reaches a child in its own session ══
begin long 60 sh -c 'setsid sleep 4242 & sleep 4243' > /dev/null
sleep 2
begin second 60 true > "$scratch/busy" 2>&1
st=$?
check "$st $(grep -c '^busy=long ' "$scratch/busy") $([ -d "$AVRA_SPRITE_HOME/avra-runs/second" ] && echo made || echo none)" "76 1 none" "a second run is refused with 76 and the first's name" "$scratch/busy"
before=$(left long)
remote stop long
settled long 5
check "$([ "$before" -ge 3 ] && echo ran) $(left long) $(pgrep -fc '^sleep 424[23]$') $(res long)" "ran 0 0 status 143" "a stop ends every process of the run, the one in its own session too, and the run answers 143"

# ══ THE BOUND: a command past it is ended, and the status says so ═════
begin bound 3 sh -c 'echo begun; setsid sleep 4246 & sleep 4244' > /dev/null
sleep 2
before=$(pgrep -fc '^sleep 424[46]$')
settled bound 30
check "$before|$(res bound)|$(remote attach bound 0 | grep -c 'passed its 3s bound')|$(left bound)|$(pgrep -fc '^sleep 424[46]$')" "2|status 124|1|0|0" "a command past its bound is stopped, its child in another session too: 124, the reason in its output, nothing left running"

# ══ THE SUPERVISOR KILLED: its keeper ends the rest and settles the status
begin killed 60 sh -c 'sleep 4245' > /dev/null
sleep 2
kill -KILL "$(cat "$AVRA_SPRITE_HOME/avra-runs/killed/pid")"
settled killed 20
check "$(res killed)|$(left killed)|$(pgrep -fc '^sleep 4245$')" "status 143|0|0" "with its supervisor killed outright, the keeper ends what is left and the run still answers"

# ══ THE KEEPER KILLED: the supervisor ends the run nobody bounds ═══════
begin unkept 60 sh -c 'setsid sleep 4248 & sleep 4247' > /dev/null
sleep 2
k=$(keeper_of unkept)
[ -n "$k" ] && kill -KILL "$k"
settled unkept 20
check "${k:+found}|$(res unkept)|$(remote attach unkept 0 | grep -c 'its keeper died')|$(left unkept)|$(pgrep -fc '^sleep 424[78]$')" "found|status 143|1|0|0" "with its keeper killed outright, the supervisor ends the run and says why; nothing is left running"

# ══ BOTH KILLED AT ONCE: the next question asked of the Sprite ends the rest
begin orphan 60 sh -c 'setsid sleep 4250 & sleep 4249' > /dev/null
sleep 2
k=$(keeper_of orphan)
kill -KILL "$(pid_of orphan)" $k
sleep 1
orphans=$(left orphan)
remote status > "$scratch/status" 2>&1
check "$([ "$orphans" -ge 2 ] && echo orphaned)|$(res orphan)|$(left orphan)|$(pgrep -fc '^sleep 42(49|50)$')|$(grep -c '^run=orphan ended' "$scratch/status")" "orphaned|status 143|0|0|1" "with supervisor and keeper both killed, a status asked of the Sprite ends what they left and settles the run" "$scratch/status"
begin orphan2 60 sh -c 'sleep 4251' > /dev/null
sleep 2
kill -KILL "$(pid_of orphan2)" $(keeper_of orphan2)
begin next 60 true > "$scratch/busy" 2>&1
st=$?
settled next 20
check "$st|$(res next)|$(pgrep -fc '^sleep 4251$')" "0|status 0|0" "a run whose supervisor and keeper are gone does not hold the Sprite BUSY: the next start ends it and runs" "$scratch/busy"

# ══ THE SPRITE RESTARTED UNDER A RUN: it is the Sprite's failure, and said so
begin reboot 60 sh -c 'echo before; sleep 4252' > /dev/null
sleep 2
kill -KILL "$(pid_of reboot)" $(keeper_of reboot) $(pgrep -f '^sleep 4252$')
echo another-boot > "$AVRA_SPRITE_HOME/avra-runs/reboot/boot"
# A pid the run once had now belongs to a stranger.
echo $$ > "$AVRA_SPRITE_HOME/avra-runs/reboot/pid"
remote status > /dev/null 2>&1
check "$(res reboot)|$(remote attach reboot 0 | grep -c '^before$\|the Sprite restarted under this run')" "status 75|2" "a run whose Sprite restarted under it answers 75, keeps what it printed and says what happened — a stranger wearing its pid is not its supervisor"

# ══ FROZEN: a run that stood still says for how long, in its output and its status line
AVRA_FROZEN_S=3 begin frozen 60 sh -c 'echo first; sleep 4253' > /dev/null
sleep 2
k=$(keeper_of frozen)
kill -STOP "$k"
sleep 5
kill -CONT "$k"
sleep 3
remote status > "$scratch/status" 2>&1
check "$(grep -c '^sprite-run: this run made no progress for [0-9]*s' "$AVRA_SPRITE_HOME/avra-runs/frozen/out")|$(sed -n 's/^run=frozen live .* quiet=[0-9]* frozen=\([0-9]*\)$/\1/p' "$scratch/status" | awk '{ print ($1 >= 4 && $1 <= 9) ? "counted" : $1 }')" "1|counted" "a run whose keeper stood still five seconds says so in its output, and its status line counts them" "$scratch/status"
remote stop frozen
settled frozen 10

# ══ THE HOLD: the Sprite is asked to stay awake before start answers, and released at the end
if [ -S /.sprite/api.sock ]; then
    tasks() { curl -s -m 5 --unix-socket /.sprite/api.sock http://sprite/v1/tasks | grep -c "\"$1\""; }
    # A run is named after the machine that began it, capitals and all; the Sprite takes no capital.
    begin Held-Mac_1 60 sh -c 'sleep 4' > /dev/null
    during=$(tasks avra-held-mac-1)
    settled Held-Mac_1 20
    sleep 3
    check "$during|$(tasks avra-held-mac-1)|$(grep -c 'would not be held' "$AVRA_SPRITE_HOME/avra-runs/Held-Mac_1/out")" "1|0|0" "a run holds its Sprite awake from the moment start answers, under a name the Sprite takes, and lets go when it ends"
    # The Sprite refusing: a curl that answers 400 stands in for it.
    mkdir -p "$scratch/deaf"
    printf '#!/bin/sh\nprintf "no such thing\\n400"\n' > "$scratch/deaf/curl"
    chmod +x "$scratch/deaf/curl"
    PATH="$scratch/deaf:$PATH" begin unheld 60 sh -c 'sleep 2' > /dev/null
    settled unheld 20
    check "$(grep -c '^sprite-run: the Sprite would not be held awake (no such thing 400) — this run stands still' "$AVRA_SPRITE_HOME/avra-runs/unheld/out" | awk '{ print ($1 >= 1) ? "said" : "silent" }')" "said" "a run the Sprite refuses to hold says so in its own output"
else
    echo "skip  the hold: no Sprite socket here (/.sprite/api.sock)"
fi

# ══ A NEW RUN CLEARS THE OLD RECORDS, and a record that never was is `gone`
begin fresh 60 true > /dev/null
settled fresh 20
check "$(res fresh)|$(res bound)|$(res nobody)" "status 0|gone|gone" "a new run clears the ended ones; a run with no record is gone"

echo "----------------------------------------"
echo "sprite_remote_test: $total checks, $failed failed"
[ "$failed" -eq 0 ]

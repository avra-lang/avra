#!/bin/sh
# tool-witness: run by work_test.sh
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
# LICENSED scratch_law: the Sprite half, deleted with the Sprites
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-remote-test.XXXXXX")
export AVRA_SPRITE_HOME="$scratch/home"
mkdir -p "$scratch/tree"
# The fixtures' own runs are not the lane's run that carries them.
unset AVRA_RUN
# No attach here follows a run longer than this: one that should have ended and did not is a FAIL, never a wait.
export AVRA_ATTACH_S=30

. "$here/lib/checks.sh"

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
# LICENSED scratch_law: the Sprite half, deleted with the Sprites
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

# ══ THE COMPILER ROUTE: a merge-base compiler is installed, then the tree is
# built once by `make compiler` (the one build verb, whose seed fallback is the
# Makefile's own). The tree holds a fake fetch tool and a Makefile whose
# `compiler` records its generation count, so the route runs with no compiler
# and no network.
route_tree="$scratch/route-tree"
mkdir -p "$route_tree/tools"
cat > "$route_tree/wisp" <<'FETCH'
echo "compiler_release: installed (fixture)"
FETCH
cat > "$route_tree/Makefile" <<'MK'
compiler:
	@mkdir -p build
	@printf 'fixture compiler\n' > build/avra
	@echo "gens=$(GENS)" > compiled
MK
remote start route "fixture 0 0" 60 route "$route_tree" 'routehash@mergebase:mk' echo route-ran > "$scratch/start"
settled route 20
check "$(res route)|$(grep -c '^route-ran$' "$AVRA_SPRITE_HOME/avra-runs/route/out")|$(grep -c 'built once' "$AVRA_SPRITE_HOME/avra-runs/route/out")|$(cat "$route_tree/compiled" 2>/dev/null)|$(left route)" \
      "status 0|1|1|gens=1|0" "a merge-base compiler builds the tree once, through make compiler" "$AVRA_SPRITE_HOME/avra-runs/route/out"

# ══ A TREE OF PROGRAM'S STANDS ON THE GATE-BUILDER RELEASE: where the release's stamp is the tree's
# compiler source it stands and nothing builds; where it is another, generations 1 and 2 build from it;
# where they do not build, the run says so and ends 70 before the command. `curl` is a stub handing
# over a pack made here.
gb_pack() {
    rm -rf "$scratch/gb-pack" && mkdir -p "$scratch/gb-pack/build"
    printf 'release compiler\n' > "$scratch/gb-pack/build/avra" && chmod +x "$scratch/gb-pack/build/avra"
    echo "$1 releaseat 2" > "$scratch/gb-pack/build/.avra-built-from"
    tar -czf "$scratch/gb.tar.gz" -C "$scratch/gb-pack" build
}
mkdir -p "$scratch/gbcurl"
printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && { cp "$GB_PACK" "$2"; exit 0; }; shift; done\nexit 22\n' > "$scratch/gbcurl/curl"
chmod +x "$scratch/gbcurl/curl"
gb_tree() {
    rm -rf "$scratch/gb-$1" && mkdir -p "$scratch/gb-$1"
    printf 'avra:\n\t@%s\n\t@echo gen >> made\ncompiler-files:\n\t@echo build/avra\n' "$2" > "$scratch/gb-$1/Makefile"
}
gb_pack gbhash
gb_tree stand true
GB_PACK=$scratch/gb.tar.gz PATH="$scratch/gbcurl:$PATH" remote start gbstand "fixture 0 0" 60 gbstand "$scratch/gb-stand" 'gbhash@gatebuilder' echo gb-ran > "$scratch/start"
settled gbstand 20
check "$(res gbstand)|$(grep -c '^gb-ran$' "$AVRA_SPRITE_HOME/avra-runs/gbstand/out")|$(cat "$scratch/gb-stand/made" 2>/dev/null)|$(cat "$scratch/gb-stand/build/avra")|$(cat "$AVRA_SPRITE_HOME/avra-compilers/gbhash/avra" 2>/dev/null)" \
      "status 0|1||release compiler|release compiler" "a tree of program's whose source is the gate-builder release's stands on it, builds nothing, and keeps it" "$AVRA_SPRITE_HOME/avra-runs/gbstand/out"
gb_pack otherhash
gb_tree build true
GB_PACK=$scratch/gb.tar.gz PATH="$scratch/gbcurl:$PATH" remote start gbbuild "fixture 0 0" 60 gbbuild "$scratch/gb-build" 'treehash@gatebuilder' echo gb-ran > "$scratch/start"
settled gbbuild 20
check "$(res gbbuild)|$(grep -c '^gb-ran$' "$AVRA_SPRITE_HOME/avra-runs/gbbuild/out")|$(tr '\n' ' ' < "$scratch/gb-build/made" 2>/dev/null)|$(grep -c 'generations 1 and 2 built from it' "$AVRA_SPRITE_HOME/avra-runs/gbbuild/out")" \
      "status 0|1|gen gen |1" "a tree of program's whose source is another builds generations 1 and 2 from the gate-builder release" "$AVRA_SPRITE_HOME/avra-runs/gbbuild/out"
gb_tree fail false
GB_PACK=$scratch/gb.tar.gz PATH="$scratch/gbcurl:$PATH" remote start gbfail "fixture 0 0" 60 gbfail "$scratch/gb-fail" 'failhash@gatebuilder' echo gb-ran > "$scratch/start"
settled gbfail 20
check "$(res gbfail)|$(grep -c '^gb-ran$' "$AVRA_SPRITE_HOME/avra-runs/gbfail/out")|$(grep -c 'generation 1 of this compiler source did not build from the gate-builder release' "$AVRA_SPRITE_HOME/avra-runs/gbfail/out")" \
      "status 70|0|1" "a tree of program's that does not build from the gate-builder release is refused at once, 70, its command never run" "$AVRA_SPRITE_HOME/avra-runs/gbfail/out"
GB_PACK=$scratch/nothing PATH="$scratch/gbcurl:$PATH" remote start gbgone "fixture 0 0" 60 gbgone "$scratch/gb-fail" 'gonehash@gatebuilder' echo gb-ran > "$scratch/start"
settled gbgone 20
check "$(res gbgone)|$(grep -c '^gb-ran$' "$AVRA_SPRITE_HOME/avra-runs/gbgone/out")|$(grep -c 'the gate-builder release did not download whole' "$AVRA_SPRITE_HOME/avra-runs/gbgone/out")" \
      "status 70|0|1" "a tree of program's whose release does not download is refused at once, 70, saying so" "$AVRA_SPRITE_HOME/avra-runs/gbgone/out"

# ══ A BRANCH WITH RUNGS IS BUILT BY THE LADDER, as CI builds it: make compiler gets RUNGS and
# LADDER_BASE, and tools/ladder.sh is pointed at the repository shipped beside the tree.
ladder_tree="$scratch/ladder-tree"
mkdir -p "$ladder_tree"
cat > "$ladder_tree/Makefile" <<'MK'
compiler:
	@mkdir -p build
	@printf 'fixture compiler\n' > build/avra && chmod +x build/avra
	@echo "rungs=$(RUNGS)|base=$(LADDER_BASE)|repo=$$AVRA_LADDER_REPO|dir=$$AVRA_LADDER_DIR" > compiled
compiler-files:
	@echo build/avra
MK
remote start ladder "fixture 0 0" 60 ladder "$ladder_tree" 'ladderhash@build%k1:basec:r1,r2' echo ladder-ran > "$scratch/start"
settled ladder 20
check "$(res ladder)|$(cat "$ladder_tree/compiled" 2>/dev/null)" \
      "status 0|rungs=r1 r2|base=basec|repo=$AVRA_SPRITE_HOME/avra-ladder/k1/repo|dir=$AVRA_SPRITE_HOME/avra-ladder/k1/work" "a branch with rungs builds through make compiler with RUNGS and LADDER_BASE" "$AVRA_SPRITE_HOME/avra-runs/ladder/out"

# ══ A NEW RUN CLEARS THE OLD RECORDS, and a record that never was is `gone`
begin fresh 60 true > /dev/null
settled fresh 20
check "$(res fresh)|$(res bound)|$(res nobody)" "status 0|gone|gone" "a new run clears the ended ones; a run with no record is gone"

# ══ THE HASH A SPRITE WAS PROVISIONED FROM is recorded only by a provisioning, and status reports it
st() { remote status - | sed -n 's/^provision_hash=//p'; }
check "$(st)" "none" "a Sprite never provisioned reports no hash"
check "$(remote reprovision abc123 "$scratch/tree")|$(st)" "reprovisioned=abc123|abc123" "a provisioning records the hash it came from, and status reports it"
check "$(remote reprovision def456 "$scratch/tree" >/dev/null; st)" "def456" "a later provisioning replaces the record"

checks_done sprite_remote_test

#!/bin/sh
# THE SPRITE'S HALF of tools/work. It never
# lives on the Sprite: each call carries it whole as an argument of one
# `sprite exec` (AVRA_REMOTE_SCRIPT, sprite-lib.sh's `remote`), so there
# is no file to push and no stale copy.
#
#   status [<hash> <package...>]  the machine as `key=value` lines
#   ready <hash> <package...>     provision, prune a filling disk, then status
#   provision <package...>        install what is missing, point the tree at LLVM
#   prune <compilers> <days>      drop old compilers, trees and scratch, detached
#   start <id> <owner> <build_s> <cmd_s> <tree> <hash> <cmd...>   begin a run; 76 when one stands
#   attach <id> <offset>          the run's output from that byte on, until it ends or a turn passes
#   result <id>                   `status <n> <bytes>`, `running <bytes>`, or `gone`
#   stop <run...>                 end each run, however its processes scattered
#   reap                          end every run whose supervisor is gone
#   manifest <tree> <root...>     the tree's identity: `path<TAB>hash` of every file and link, sorted
#   unlink <tree> <path...>       remove those files of the tree
#
# A RUN IS ITS ENVIRONMENT MARK: every process a run starts inherits
# AVRA_RUN=<id>, so a stop finds them all by reading /proc — a child that
# took its own session or group (the watchdog's does) is still found.
#
# A RUN BELONGS TO THE SPRITE, NOT TO THE CONNECTION THAT BEGAN IT. Its
# supervisor stands outside every exec session and writes the run's
# output and its exit status to the run's own directory; a client only
# attaches, at a byte offset, and a dropped connection loses nothing.
#
# AND A RUN IS NEVER LEFT TO THE PROVIDER'S MERCY: a Sprite with no
# session attached is suspended, mid-write if need be, so a run's keeper
# HOLDS THE SPRITE AWAKE for as long as the run lives (the Sprite's own
# tasks, refreshed each minute) and no longer. The keeper also ends a run
# past its time bound, and one that takes the machine under its memory
# floor — a Sprite has no swap, and one out of memory answers nobody —
# so a run with no client left still ends, and says how.
#
# THE FLOOR IS READ AGAINST WHAT IS AVAILABLE, NEVER AGAINST MemTotal: a
# Sprite says 16 GB and a balloon holds half of it, more while it idles
# (3.3 to 7.3 GB were free to a run, measured). Under about 250 MB the
# whole machine stops answering for minutes, so the keeper ends the run
# above that, and the command — never its supervisor — is what the
# kernel takes first if the keeper is too slow.
#
# NOTHING A RUN STARTED OUTLIVES ITS SUPERVISOR. Supervisor and keeper
# watch each other: whichever is killed, the other ends every process
# carrying the run's mark within seconds and writes its status. Both
# killed at once, the next `start`, `status` or `reap` finds a run with
# no supervisor and ends it the same way.
set -eu

home=${AVRA_SPRITE_HOME:-/home/sprite}
runs=$home/avra-runs
compilers=$home/avra-compilers
trees=$home/avra-build
floor_mb=${AVRA_RUN_FLOOR_MB:-600}
# Under this much available memory a Sprite answers nobody.
stall_mb=250

avail_mb() { awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo; }

# The pids carrying a run's mark, this shell's own excluded.
members() {
    for e in /proc/[0-9]*/environ; do
        p=${e#/proc/}
        p=${p%/environ}
        [ "$p" = "$$" ] && continue
        tr '\0' '\n' 2>/dev/null < "$e" | grep -qx "AVRA_RUN=$1" && echo "$p"
    done
    return 0
}

# Ends a run's processes, sparing the pids in $2..; its record stays, for
# whoever asks how it ended.
stop_run() {
    r=$1
    shift
    for sig in TERM KILL; do
        left=
        for p in $(members "$r"); do
            case " $* " in *" $p "*) continue ;; esac
            kill -"$sig" "$p" 2>/dev/null && left=1
        done
        [ -n "$left" ] || break
        [ "$sig" = KILL ] || sleep 2
    done
    [ ! -d "$runs/$r" ] || [ -f "$runs/$r/status" ] || settle "$r" 143
}
# A run's status is written once, whole.
settle() {
    [ -f "$runs/$1/status" ] || { echo "$2" > "$runs/$1/status.new" && mv "$runs/$1/status.new" "$runs/$1/status"; }
}

# The Sprite's own promise to stay awake, by the run's name, for five
# minutes. THE ANSWER IS READ: the Sprite takes a name of lowercase
# letters, digits and dashes only and refuses any other, and a run it
# refused to hold stands still whenever nobody is attached — so the
# name is made one it takes, and a refusal is the run's own output.
hold() {
    [ -S /.sprite/api.sock ] || return 0
    task=avra-$(printf '%s' "$2" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9-' '-')
    ask() { curl -s -m 5 -w '\n%{http_code}' --unix-socket /.sprite/api.sock -H 'Content-Type: application/json' "$@" 2>/dev/null || :; }
    case $1 in
        on) said=$(ask -X POST http://sprite/v1/tasks -d "{\"name\":\"$task\",\"expire\":\"5m\"}") ;;
        again)
            said=$(ask -X PUT "http://sprite/v1/tasks/$task" -d '{"expire":"5m"}')
            # A hold that lapsed while the Sprite stood still is asked for again.
            case $said in *200) ;; *) said=$(ask -X POST http://sprite/v1/tasks -d "{\"name\":\"$task\",\"expire\":\"5m\"}") ;; esac
            ;;
        off)
            ask -X DELETE "http://sprite/v1/tasks/$task" >/dev/null
            return 0
            ;;
    esac
    case $said in
        *200 | *201 | *409) ;;
        *) [ ! -d "$runs/$2" ] || echo "sprite-run: the Sprite would not be held awake ($(printf '%s' "$said" | tr '\n' ' ')) — this run stands still whenever nobody is attached" >> "$runs/$2/out" ;;
    esac
}

lacking() {
    for p in "$@"; do
        dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'ok installed' || printf '%s ' "$p"
    done
}

status() {
    hash=${1:--}
    [ "$#" -eq 0 ] || shift
    [ "$#" -eq 0 ] || echo "missing=$(lacking "$@")"
    echo "pruning=$(flock -n /tmp/.avra-prune.lock true 2>/dev/null && echo no || echo yes)"
    set -- $(cat /proc/loadavg)
    echo "load=$1"
    echo "cores=$(nproc)"
    echo "boot_s=$(cut -d. -f1 /proc/uptime)"
    echo "mem_total_mb=$(awk '/^MemTotal:/ { print int($2 / 1024) }' /proc/meminfo)"
    echo "mem_avail_mb=$(avail_mb)"
    df -Pm "$home" /tmp 2>/dev/null | awk 'NR == 2 { print "disk_free_mb=" $4; print "disk_used_pct=" $5 + 0 }
                                           NR == 3 { print "tmp_free_mb=" $4; print "tmp_used_pct=" $5 + 0 }'
    [ -d "$home" ] && [ -w "$home" ] && echo "home=yes" || echo "home=no"
    echo "compilers=$(find "$compilers" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | wc -l)"
    echo "trees=$(find "$trees" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)"
    [ -x "$compilers/$hash/avra" ] && echo "holds=yes" || echo "holds=no"
    reap
    for o in "$runs"/*/owner; do
        [ -f "$o" ] || continue
        r=$(basename "$(dirname "$o")")
        [ ! -f "$runs/$r/status" ] && [ -n "$(members "$r")" ] && state=live || state=ended
        # How long since the run last wrote, and how long it has stood frozen in all.
        echo "run=$r $state $(cat "$o") quiet=$(($(date +%s) - $(stat -c %Y "$runs/$r/out" 2>/dev/null || date +%s))) frozen=$(cat "$runs/$r/frozen" 2>/dev/null || echo 0)"
    done
}

provision() {
    llvm=/usr/lib/llvm-22
    # A home that was moved is a fixture's: the system is not touched.
    if [ -n "${AVRA_SPRITE_HOME:-}" ]; then
        mkdir -p "$runs" "$compilers" "$trees"
        echo "provisioned=yes"
        return 0
    fi
    missing=$(lacking "$@")
    if [ -n "$missing" ]; then
        # One installer at a time; apt's own lock would fail the second.
        exec 9> /tmp/.avra-provision.lock
        flock 9
        # An install cut off mid-way leaves dpkg refusing every later one, so
        # it is healed first — and this one leaves the session, which may drop.
        setsid -w sh -c '
            export DEBIAN_FRONTEND=noninteractive
            sudo -E dpkg --configure -a
            sudo -E apt-get -y -qq -f install
            sudo apt-get update -qq
            sudo -E apt-get install -y -qq --no-install-recommends -o DPkg::Lock::Timeout=120 "$@"
        ' avra-provision $missing > /tmp/.avra-provision.log 2>&1 || :
        still=$(lacking $missing)
        [ -z "$still" ] || { echo "unprovisioned=$still"; tail -n 5 /tmp/.avra-provision.log >&2; return 1; }
        echo "installed=$missing"
    fi
    if [ "$(readlink /opt/homebrew/opt/llvm 2>/dev/null)" != "$llvm" ] || [ ! -f /etc/profile.d/avra-llvm.sh ]; then
        sudo install -d /opt/homebrew/opt /usr/local/bin
        sudo ln -sfn "$llvm" /opt/homebrew/opt/llvm
        sudo ln -sf "$llvm/bin/clang" /usr/local/bin/clang
        sudo ln -sf "$llvm/bin/clang" /usr/local/bin/cc
        sudo ln -sf "$llvm/bin/llvm-config" /usr/local/bin/llvm-config
        printf '%s\n' "export LLVM_PREFIX=$llvm" "export CC=$llvm/bin/clang" | sudo tee /etc/profile.d/avra-llvm.sh >/dev/null
    fi
    mkdir -p "$runs" "$compilers" "$trees"
    test -e "$llvm/lib/libLLVM.so" || { echo "unprovisioned=libLLVM.so"; return 1; }
    echo "provisioned=yes"
}

# Keeps the newest compilers, and the trees and scratch used within the
# given days; a tree a live run stands in is never touched.
prune() {
    setsid sh -c "$AVRA_REMOTE_SCRIPT" avra-remote prune-now "$@" </dev/null > "$home/.avra-prune.log" 2>&1 &
}
prune_now() {
    exec 8> /tmp/.avra-prune.lock
    flock -n 8 || exit 0
    keep=$1
    days=$2
    before=$(df -Pm "$home" | awk 'NR == 2 { print $4 }')
    busy=$(cat "$runs"/*/tree 2>/dev/null || :)
    find "$compilers" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -rn |
        awk -v keep="$keep" 'NR > keep { print $2 }' | while IFS= read -r d; do rm -rf "$d"; done
    find "$trees" -mindepth 1 -maxdepth 1 -type d -mtime +"$days" 2>/dev/null | while IFS= read -r d; do
        case "$busy" in *"$d/"*) continue ;; esac
        rm -rf "$d"
    done
    find /tmp -mindepth 1 -maxdepth 1 -user "$(id -un)" -mtime +"$days" ! -name '.avra-*' -exec rm -rf {} + 2>/dev/null || :
    rm -f "$home"/.avra-info-*.sh "$home"/.avra-run-*.sh "$home"/.avra-provision.sh
    after=$(df -Pm "$home" | awk 'NR == 2 { print $4 }')
    echo "freed_mb=$((after - before))"
    echo "disk_free_mb=$after"
}

# Beside the run's supervisor: holds the Sprite awake while the run
# lives, ends the run when its time is up or the machine nears its
# memory floor (the reason it writes is the run's last word), and when
# the supervisor is gone ends whatever the run left standing and sees
# that its status is written.
keeper() {
    r=$1 main=$2 build_s=$3 cmd_s=$4
    rd=$runs/$r
    t0=$(cut -d. -f1 /proc/uptime)
    held=$t0
    hold on "$r"
    was=$(avail_mb)
    low=$was
    wall=$(date +%s)
    while [ -d "$rd" ] && kill -0 "$main" 2>/dev/null; do
        why=
        now=$(cut -d. -f1 /proc/uptime)
        # A turn is a second or two; one that took far longer is time the
        # run did not have, and the run says so where its output is read.
        turn=$(($(date +%s) - wall))
        wall=$((wall + turn))
        [ "$turn" -lt "${AVRA_FROZEN_S:-20}" ] || {
            echo "sprite-run: this run made no progress for ${turn}s — the Sprite was suspended, or stalled, with nobody attached" >> "$rd/out"
            echo $(($(cat "$rd/frozen" 2>/dev/null || echo 0) + turn)) > "$rd/frozen"
        }
        # The floor rises with the fall: one more turn like the last must
        # leave the Sprite above where it stalls.
        have=$(avail_mb)
        need=$((was - have + stall_mb))
        [ "$need" -gt "$floor_mb" ] || need=$floor_mb
        was=$have
        [ "$have" -ge "$low" ] || { low=$have; echo "$low" > "$rd/low"; }
        [ $((now - held)) -lt 60 ] || { hold again "$r"; held=$now; }
        if at=$(cat "$rd/cmd_at" 2>/dev/null) && [ -n "$at" ]; then
            [ $((now - at)) -lt "$cmd_s" ] || why="124 the command passed its ${cmd_s}s bound"
        else
            [ $((now - t0)) -lt "$build_s" ] || why="125 the compiler build passed its ${build_s}s bound"
        fi
        [ -n "$why" ] || [ "$have" -ge "$need" ] || why="137 the Sprite was down to ${have} MB of available memory, under its floor of ${need}"
        if [ -n "$why" ]; then
            echo "$why" > "$rd/stopped"
            for sig in TERM KILL; do
                for p in $(members "$r"); do
                    [ "$p" = "$main" ] || [ "$p" = "$$" ] || kill -"$sig" "$p" 2>/dev/null || :
                done
                sleep 2
            done
            kill -TERM "$main" 2>/dev/null || :
            sleep 2
            break
        fi
        sleep 1
    done
    stop_run "$r" $$
    hold off "$r"
}

# The compiler's own objects, as the Makefile's COMPILER_OBJS names them.
compiler_objs() {
    echo build/avra build/libavra_runtime.a build/avra_hot.bc build/avra_hot.inc
    for f in runtime/*.c; do
        [ -f "$f" ] || continue
        s=$(basename "$f" .c)
        echo "build/$s.o build/$s.sha build/$s.d"
    done
    for s in llvm_wrapper ffi std_io std_io_watch std_process std_time std_net std_hash; do
        echo "build/$s.o build/$s.sha build/$s.d"
    done
    echo build/std_hash.a
    for f in build/b3_*.o; do
        [ -f "$f" ] || continue
        s=$(basename "$f" .o)
        echo "build/$s.o build/$s.sha build/$s.d"
    done
}

# ONLY A FIXED POINT IS CACHED: two `make avra` from a standing compiler
# (or `make bootstrap` from none) reach the generation `make bootstrap`
# does. Never verified by diffing binaries — the linker's build id
# differs between two builds of one source.
advance_and_cache() {
    log=/tmp/.avra-adv-$$
    # A build's cap leaves the machine its floor; the shim's default is the laptop's.
    export AVRA_CAP_MB="${AVRA_BUILD_CAP_MB:-$(awk '/^MemTotal:/ { print int($2 / 1024) - 1200 }' /proc/meminfo)}"
    ok=0
    # Each step says how long it took: a build's time is read, never guessed.
    step() {
        s0=$(date +%s)
        "$@" >> "$log" 2>&1
        s1=$?
        echo "sprite-run: $* — $(($(date +%s) - s0))s$([ "$s1" = 0 ] || echo ", FAILED")" >&2
        return "$s1"
    }
    : > "$log"
    if [ -x build/avra ] && step make -s avra && step make -s avra; then
        ok=1
    elif step make bootstrap; then
        ok=1
    fi
    if [ "$ok" = 1 ] && [ -x build/avra ]; then
        tmp="$compilers/.tmp-$chash-$$"
        rm -rf "$tmp"
        mkdir -p "$tmp"
        for f in $(compiler_objs); do
            [ ! -e "$f" ] || cp -p "$f" "$tmp/$(basename "$f")"
        done
        rm -rf "${compilers:?}/$chash"
        mv "$tmp" "$compilers/$chash"
        printf '%s' "$chash" > build/.avra-compiler-hash
        store_result=built
    else
        store_result=unverified
        echo "sprite-build: this tree's compiler does not build:" >&2
        grep -aE 'error|Error|Killed|refus' "$log" | head -20 >&2
    fi
    rm -f "$log"
}

# A run with no status whose supervisor is gone has nobody to end it:
# what it left is ended here, and it answers 143 — or 75 when the Sprite
# itself restarted under it, which is the Sprite's failure and is said in
# the run's output. A supervisor is its pid AND the run's mark: a pid
# alone is another process after a restart. Under the runs' lock, so a
# run being started is never read as one abandoned; a lock held
# elsewhere is left to its holder.
reap() {
    [ -d "$runs" ] || return 0
    (
        flock -w 5 6 || exit 0
        for o in "$runs"/*/owner; do
            [ -f "$o" ] || continue
            r=$(basename "$(dirname "$o")")
            [ ! -f "$runs/$r/status" ] || continue
            p=$(cat "$runs/$r/pid" 2>/dev/null) || p=
            [ -n "$p" ] && members "$r" | grep -qx "$p" && continue
            if [ "$(cat "$runs/$r/boot" 2>/dev/null)" != "$(cat /proc/sys/kernel/random/boot_id)" ]; then
                echo "sprite-run: the Sprite restarted under this run — one out of memory does; what it printed up to then is above" >> "$runs/$r/out"
                settle "$r" 75
            fi
            stop_run "$r"
            hold off "$r"
        done
    ) 6> "$runs/.lock"
}

# ONE RUN ON A SPRITE AT A TIME: a second is refused with 76 and the
# first's name. The run's supervisor leaves this session before `start`
# answers, so the caller's connection is nothing to it.
start() {
    id=$1
    owner=$2 tree=$5
    mkdir -p "$runs"
    reap
    exec 7> "$runs/.lock"
    flock 7
    for o in "$runs"/*/owner; do
        [ -f "$o" ] || continue
        r=$(basename "$(dirname "$o")")
        # A run that has written its status is over, whatever its keeper is still tidying.
        [ -f "$runs/$r/status" ] || [ -z "$(members "$r")" ] || { echo "busy=$r $(cat "$o")"; exit 76; }
        rm -rf "${runs:?}/$r"
    done
    rd=$runs/$id
    mkdir -p "$rd"
    printf '%s\n' "$owner" > "$rd/owner"
    printf '%s/\n' "$tree" > "$rd/tree"
    cat /proc/sys/kernel/random/boot_id > "$rd/boot"
    : > "$rd/out"
    AVRA_RUN=$id
    export AVRA_RUN
    shift 2
    # The supervisor outlives this call, so it runs from the run's own copy.
    printf '%s\n' "$AVRA_REMOTE_SCRIPT" > "$rd/remote.sh"
    # Held before this call answers: the session that carried it may be the Sprite's last.
    hold on "$id"
    setsid sh "$rd/remote.sh" supervise "$id" "$@" </dev/null >> "$rd/out" 2>&1 7>&- &
    echo $! > "$rd/pid"
    echo "started=$id"
}

# The run itself, on the compiler it is testing: build/avra is kept in
# place between runs, restored from this Sprite's cache when the source
# hash moved to one it holds, and built and cached otherwise — a source
# that does not build gets no command (70), since an older compiler
# would answer about a different program.
supervise() {
    id=$1 build_s=$2 cmd_s=$3 remote=$4 chash=$5
    shift 5
    rd=$runs/$id
    echo $$ > "$rd/pid"
    sh "$rd/remote.sh" keeper "$id" $$ "$build_s" "$cmd_s" </dev/null >/dev/null 2>&1 &
    keeper=$!
    # The keeper's reason, when it ended this run, is the run's status.
    ended() {
        trap - EXIT TERM
        st=$1
        if [ -f "$rd/stopped" ]; then
            read -r st why < "$rd/stopped"
            echo "sprite-run: stopped — ${why}" >&2
        fi
        # A run's memory is read, never guessed: the least the Sprite had left.
        [ ! -f "$rd/low" ] || echo "sprite-run: ended $st; the Sprite's available memory was never under $(cat "$rd/low") MB" >&2
        settle "$id" "$st"
        exit "$st"
    }
    trap 'ended 143' TERM
    trap 'ended $?' EXIT

    (
        trap - EXIT TERM
        export LLVM_PREFIX=/usr/lib/llvm-22 CC=/usr/lib/llvm-22/bin/clang
        mkdir -p "$remote/build" "$compilers"
        cd "$remote"
        t0=$(date +%s)
        if [ "$chash" = - ]; then
            compiler=unasked
        elif [ -x build/avra ] && [ "$(cat build/.avra-compiler-hash 2>/dev/null)" = "$chash" ]; then
            compiler=warm
        elif [ -x "$compilers/$chash/avra" ]; then
            for f in $(compiler_objs); do
                b=$(basename "$f")
                [ -e "$compilers/$chash/$b" ] || continue
                cp -p "$compilers/$chash/$b" "$f"
                touch "$f"
            done
            touch "$compilers/$chash"
            printf '%s' "$chash" > build/.avra-compiler-hash
            compiler=restored
        else
            echo "sprite-run: building this tree's compiler; $(avail_mb) MB of memory available" >&2
            advance_and_cache
            [ "$store_result" = built ] || exit 70
            compiler=built
        fi
        echo "sprite-run: compiler $compiler in $(($(date +%s) - t0))s; $(avail_mb) MB of memory available to the command" >&2
        cut -d. -f1 /proc/uptime > "$rd/cmd_at"
        # Out of memory, the kernel ends the command and what it started first.
        echo 800 > /proc/self/oom_score_adj 2>/dev/null || :
        exec "$@"
    ) &
    body=$!
    # The body is waited for a second at a time, so a keeper that died is
    # noticed: a run nobody bounds and nobody holds awake is ended.
    while kill -0 "$body" 2>/dev/null; do
        if ! kill -0 "$keeper" 2>/dev/null && [ ! -f "$rd/stopped" ]; then
            echo "143 its keeper died" > "$rd/stopped"
            stop_run "$id" $$
            hold off "$id"
            break
        fi
        sleep 1
    done
    status=0
    wait "$body" || status=$?
    ended "$status"
}

# A TREE'S IDENTITY IS ITS MANIFEST: every file and link under the given
# roots as `path<TAB>hash`, sorted — outside the directories a sync never
# carries (build, .avra-cache, .claude, .git). The worktree's side is this
# same fn run where the worktree stands, so the two are one definition.
manifest() {
    cd "$1"
    shift
    sum=sha256sum
    command -v sha256sum >/dev/null 2>&1 || sum='shasum -a 256'
    unsynced() { find "$@" -type d \( -name build -o -name .avra-cache -o -name .claude -o -name .git \) -prune -o "$kind" "$what" -print0; }
    {
        kind=-type what=f
        unsynced "$@" | xargs -0 -r $sum | awk '{ print substr($0, 67) "\t" substr($0, 1, 64) }'
        what=l
        unsynced "$@" | xargs -0 -r -n 1 sh -c 'printf "%s\tlink:%s\n" "$1" "$(readlink "$1")"' link
    } | LC_ALL=C sort
}

# Removes files of a tree by name; a path that leaves the tree is not one.
unlink_() {
    cd "$1"
    shift
    for p in "$@"; do
        case $p in /* | ../* | */../* | */..) continue ;; esac
        rm -f -- "$p"
    done
}

# The run's output from byte $2 on, as it is written, until the run has
# ended or a turn of AVRA_ATTACH_S (540) seconds has passed — a client
# asks again from where it stands, so no one connection has to last.
attach() {
    rd=$runs/$1
    [ -f "$rd/out" ] || exit 3
    if [ -f "$rd/status" ]; then
        tail -c +$(($2 + 1)) "$rd/out"
        return 0
    fi
    tail -c +$(($2 + 1)) -f -s 1 "$rd/out" &
    tl=$!
    trap 'kill "$tl" 2>/dev/null' EXIT
    n=0
    while [ ! -f "$rd/status" ] && [ "$n" -lt "${AVRA_ATTACH_S:-540}" ]; do
        sleep 1
        n=$((n + 1))
    done
    # The tail reads each second: two, and it has the run's last line.
    [ ! -f "$rd/status" ] || sleep 2
}

# How a run stands, and how many bytes of output it has written: a
# follower has the whole of it when it holds that many.
result() {
    if [ -f "$runs/$1/status" ]; then
        echo "status $(cat "$runs/$1/status") $(wc -c < "$runs/$1/out")"
    elif [ -d "$runs/$1" ] && [ -n "$(members "$1")" ]; then
        echo "running $(wc -c < "$runs/$1/out")"
    else
        echo gone
    fi
}

verb=$1
shift
case $verb in
    status) status "$@" ;;
    ready)
        hash=$1
        shift
        provision "$@" || :
        [ "$(df -P "$home" | awk 'NR == 2 { print $5 + 0 }')" -lt "${AVRA_PRUNE_PCT:-70}" ] || prune 6 2
        status "$hash" "$@"
        ;;
    stop) for r in "$@"; do stop_run "$r"; hold off "$r"; done ;;
    reap) reap ;;
    start) start "$@" ;;
    supervise) supervise "$@" ;;
    attach) attach "$@" ;;
    result) result "$@" ;;
    manifest) manifest "$@" ;;
    unlink) unlink_ "$@" ;;
    provision) provision "$@" ;;
    prune) prune "$@" ;;
    prune-now) prune_now "$@" ;;
    keeper) keeper "$@" ;;
    *) echo "sprite-remote: unknown verb $verb" >&2; exit 2 ;;
esac

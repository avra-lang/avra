#!/bin/sh
# THE SPRITE'S HALF of tools/work. It never
# lives on the Sprite: each call carries it whole as an argument of one
# `sprite exec` (AVRA_REMOTE_SCRIPT, sprite-lib.sh's `remote`), so there
# is no file to push and no stale copy.
#
#   status [<hash> <package...>]  the machine as `key=value` lines
#   ready <hash> <package...>     provision, prune a filling disk, then status
#   stop <run...>              stop each run, however its processes scattered
#   provision <package...>     install what is missing, point the tree at LLVM
#   prune <compilers> <days>   drop old compilers, trees and scratch, detached
#   run <id> <owner> <build_s> <cmd_s> <tree> <hash> <cmd...>
#
# A RUN IS ITS ENVIRONMENT MARK: every process a run starts inherits
# AVRA_RUN=<id>, so a stop finds them all by reading /proc — a child that
# took its own session or group (the watchdog's does) is still found.
#
# A RUN NEVER OUTLIVES ITS CALLER. The Sprite ends an exec session whose
# client is gone, and each run keeps a keeper outside that session: when
# the run's own shell is gone before it finished, the keeper stops what
# is left. The keeper also ends a run past its time bound, and one that
# takes the machine under its memory floor — a Sprite has no swap, and
# one out of memory answers nobody.
set -eu

home=/home/sprite
runs=$home/avra-runs
compilers=$home/avra-compilers
trees=$home/avra-build
floor_mb=${AVRA_RUN_FLOOR_MB:-350}

avail_mb() { awk '/^MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo; }

# The pids carrying a run's mark, this shell's own excluded.
members() {
    for e in /proc/[0-9]*/environ; do
        p=${e#/proc/}
        p=${p%/environ}
        [ "$p" = "$$" ] && continue
        tr '\0' '\n' < "$e" 2>/dev/null | grep -qx "AVRA_RUN=$1" && echo "$p"
    done
    return 0
}

# Ends a run's processes, sparing the pids in $2.., and removes its record.
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
    rm -rf "${runs:?}/$r"
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
    for o in "$runs"/*/owner; do
        [ -f "$o" ] || continue
        r=$(basename "$(dirname "$o")")
        [ -n "$(members "$r")" ] && state=live || state=ended
        echo "run=$r $state $(cat "$o")"
    done
}

provision() {
    llvm=/usr/lib/llvm-22
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

# Outside the run's session: ends the run when its shell is gone, when
# its time is up, or when the machine nears its memory floor (the reason
# it writes is the run's last word) — and whatever a run left standing
# when it ended.
keeper() {
    r=$1 main=$2 build_s=$3 cmd_s=$4
    rd=$runs/$r
    t0=$(cut -d. -f1 /proc/uptime)
    while [ -d "$rd" ] && kill -0 "$main" 2>/dev/null; do
        why=
        now=$(cut -d. -f1 /proc/uptime)
        if at=$(cat "$rd/cmd_at" 2>/dev/null) && [ -n "$at" ]; then
            [ $((now - at)) -lt "$cmd_s" ] || why="124 the command passed its ${cmd_s}s bound"
        else
            [ $((now - t0)) -lt "$build_s" ] || why="125 the compiler build passed its ${build_s}s bound"
        fi
        [ -n "$why" ] || [ "$(avail_mb)" -ge "$floor_mb" ] || why="137 the Sprite fell under ${floor_mb} MB free"
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
}

# The compiler's own objects, as the Makefile's COMPILER_OBJS names them.
compiler_objs() {
    echo build/avra build/libavra_runtime.a build/avra_hot.bc build/avra_hot.inc
    for f in runtime/*.c; do
        [ -f "$f" ] || continue
        s=$(basename "$f" .c)
        echo "build/$s.o build/$s.sha build/$s.d"
    done
    for s in llvm_wrapper ffi std_io std_io_watch std_process std_time std_net; do
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

# ONE RUN ON A SPRITE AT A TIME, and it runs on the compiler it is
# testing: build/avra is kept in place between runs, restored from this
# Sprite's cache when the source hash moved to one it holds, and built
# and cached otherwise — a source that does not build gets no command
# (70), since an older compiler would answer about a different program.
run() {
    AVRA_RUN=$1
    owner=$2 build_s=$3 cmd_s=$4 remote=$5 chash=$6
    shift 6
    for o in "$runs"/*/owner; do
        [ -f "$o" ] || continue
        r=$(basename "$(dirname "$o")")
        [ -z "$(members "$r")" ] || { echo "sprite-run: busy with $r, begun by $(cat "$o")" >&2; exit 76; }
        rm -rf "${runs:?}/$r"
    done
    export AVRA_RUN
    rd=$runs/$AVRA_RUN
    mkdir -p "$rd" "$remote/build" "$compilers"
    printf '%s\n' "$owner" > "$rd/owner"
    printf '%s/\n' "$remote" > "$rd/tree"
    echo $$ > "$rd/pid"
    setsid sh -c "$AVRA_REMOTE_SCRIPT" avra-remote keeper "$AVRA_RUN" $$ "$build_s" "$cmd_s" </dev/null >/dev/null 2>&1 &
    # The keeper's reason, when it ended this run, is the run's status.
    ended() {
        st=$1
        if [ -f "$rd/stopped" ]; then
            read -r st why < "$rd/stopped"
            echo "sprite-run: stopped — ${why}" >&2
        fi
        rm -rf "$rd"
        exit "$st"
    }
    trap 'ended 143' TERM
    trap 'ended $?' EXIT

    export LLVM_PREFIX=/usr/lib/llvm-22 CC=/usr/lib/llvm-22/bin/clang
    cd "$remote"
    t0=$(date +%s)
    if [ -x build/avra ] && [ "$(cat build/.avra-compiler-hash 2>/dev/null)" = "$chash" ]; then
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
        echo "sprite-run: building this tree's compiler" >&2
        advance_and_cache
        [ "$store_result" = built ] || exit 70
        compiler=built
    fi
    echo "sprite-run: compiler $compiler in $(($(date +%s) - t0))s" >&2
    cut -d. -f1 /proc/uptime > "$rd/cmd_at"
    set +e
    "$@"
    status=$?
    set -e
    exit "$status"
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
    stop) for r in "$@"; do stop_run "$r"; done ;;
    provision) provision "$@" ;;
    prune) prune "$@" ;;
    prune-now) prune_now "$@" ;;
    keeper) keeper "$@" ;;
    run) run "$@" ;;
    *) echo "sprite-remote: unknown verb $verb" >&2; exit 2 ;;
esac

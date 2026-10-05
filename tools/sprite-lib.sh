# How tools/work reaches a Sprite and names a local process. Sourced;
# `here` is the tools directory.
#
# EVERY EXEC IS BOUNDED AND READS NO STDIN. An exec with stdin attached is
# not reconnected when its connection drops, and an unbounded one waits
# out a Sprite that will never answer. AVRA_SPRITE_CLI stands in for the
# `sprite` CLI.
sprite_cli=${AVRA_SPRITE_CLI:-sprite}
remote_script=$(cat "$here/sprite-remote.sh")
ci_packages=$(grep -v '^#' "$here/../.github/ci/packages.txt" | tr '\n' ' ')

# sx <sprite> <seconds> <command...>
sx() {
    sx_s=$1 sx_b=$2
    shift 2
    timeout -k 2 "$sx_b" "$sprite_cli" -s "$sx_s" exec --no-port-forward --no-stdin -- "$@"
}

# remote <sprite> <seconds> <verb> <args...>: tools/sprite-remote.sh there.
remote() {
    rm_s=$1 rm_b=$2
    shift 2
    sx "$rm_s" "$rm_b" sh -c 'AVRA_REMOTE_SCRIPT=$1; shift; eval "$AVRA_REMOTE_SCRIPT"' avra-remote "$remote_script" "$@"
}

# A WAKING SPRITE IS WAITED FOR, WITH A BOUND: answers within seconds when
# warm, a minute or more from cold. woken <sprite> <seconds> <verb...>
# asks until it answers or the bound passes; each ask is at most 30 s,
# since an ask that began before the machine stood can outlast it.
woken() {
    wk_s=$1 wk_end=$(($(date +%s) + $2))
    shift 2
    while :; do
        wk_left=$((wk_end - $(date +%s)))
        [ "$wk_left" -gt 0 ] || return 1
        [ "$wk_left" -le 30 ] || wk_left=30
        remote "$wk_s" "$wk_left" "$@" 2>/dev/null && return 0
        sleep 1
    done
}

# A PROCESS IS ITS PID AND ITS BIRTH: a pid alone is reused once its
# process exits, and a lease read by pid alone is then held by a stranger.
born() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' '_'; }
# owner_live <pid> <born>
owner_live() {
    [ -n "${1:-}" ] && [ -n "${2:-}" ] && [ "$(born "$1")" = "$2" ]
}

# Reads a Sprite's `run=` rows ("<run> <live|ended> <host> <pid> [<born>]")
# and prints the runs to stop: one whose processes ended, and one this
# host began whose owner is gone. Another host's run is its keeper's.
orphaned() {
    while read -r or_r or_state or_h or_p or_b; do
        if [ "$or_state" = ended ]; then
            printf '%s ' "$or_r"
        elif [ "$or_h" = "$(hostname -s)" ]; then
            if [ -n "$or_b" ]; then owner_live "$or_p" "$or_b"; else kill -0 "$or_p" 2>/dev/null; fi || printf '%s ' "$or_r"
        fi
    done
}

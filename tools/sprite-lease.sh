#!/bin/sh
# THE LEASES tools/sp hands out: which caller holds which slot of which
# Sprite, and which worktree's tree. Always run under the leases' kernel
# lock (sprite-lib.sh's `leases`), so no two callers ever read and write
# them at once — and a lock the kernel holds dies with its holder.
#
#   take <dir> <pid>                          the lease, or exit 1
#   claim <pid> <jobs> <slug> <sprites> <avoid>   "<sprite> <slot> <tree>"
#   lease <max> <pid> <sprite...>             a slot among 1..max: its dir
#   sweep                                     drop every lease whose owner is gone
#   table                                     "<sprite> <lease> <pid> <live|gone>"
#
# A LEASE IS A DIRECTORY NAMING ITS OWNER: `owner` holds the pid and its
# birth, `pid` the pid alone. An owner that is gone holds nothing — the
# next taker has the lease, whoever it is.
set -eu
slots=${AVRA_SP_SLOTS:-/tmp/avra-sp-slots}

born() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' '_'; }

# Whether the lease's owner still runs. A lease with a pid and no birth
# is judged by the pid alone.
held() {
    if { read -r hp hb < "$1/owner"; } 2>/dev/null; then
        [ -n "$hp" ] && [ "$(born "$hp")" = "$hb" ]
    else
        hp=$(cat "$1/pid" 2>/dev/null) && [ -n "$hp" ] && kill -0 "$hp" 2>/dev/null
    fi
}

take() {
    [ ! -d "$1" ] || ! held "$1" || return 1
    rm -rf "$1"
    mkdir -p "$1"
    echo "$2" > "$1/pid"
    echo "$2 $(born "$2")" > "$1/owner"
}

# The first Sprite with this worktree's tree free and a slot free; the
# Sprites in $5 only once no other has room.
claim() {
    owner=$1 jobs=$2 slug=$3
    for avoid in "$5" ""; do
        for s in $4; do
            case " $avoid " in *" $s "*) continue ;; esac
            [ ! -d "$slots/$s/tree-$slug" ] || ! held "$slots/$s/tree-$slug" || continue
            n=1
            while [ "$n" -le "$jobs" ]; do
                if take "$slots/$s/slot-$n" "$owner"; then
                    take "$slots/$s/tree-$slug" "$owner"
                    echo "$s $slots/$s/slot-$n $slots/$s/tree-$slug"
                    return 0
                fi
                n=$((n + 1))
            done
        done
    done
    return 1
}

# Slot level by level across the Sprites in their given order, so work
# spreads before it stacks.
lease() {
    max=$1 owner=$2
    shift 2
    n=1
    while [ "$n" -le "$max" ]; do
        for s in "$@"; do
            take "$slots/$s/slot-$n" "$owner" && { echo "$slots/$s/slot-$n"; return 0; }
        done
        n=$((n + 1))
    done
    return 1
}

each() {
    for d in "$slots"/*/slot-* "$slots"/*/tree-*; do
        [ -d "$d" ] && "$@" "$d"
    done
    return 0
}
swept() { held "$1" || { echo "reaped ${1#"$slots"/}"; rm -rf "$1"; }; }
row() {
    held "$1" && state=live || state=gone
    s=${1#"$slots"/}
    echo "${s%%/*} ${s#*/} $(cat "$1/pid" 2>/dev/null || echo -) $state"
}

verb=$1
shift
case $verb in
    take) take "$@" ;;
    claim) claim "$@" ;;
    lease) lease "$@" ;;
    sweep) each swept ;;
    table) each row ;;
    *) echo "sprite-lease: unknown verb $verb" >&2; exit 2 ;;
esac

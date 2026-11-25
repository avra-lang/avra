# How tools/work reaches a Sprite and names a local process. Sourced;
# `here` is the tools directory.
#
# EVERY EXEC IS BOUNDED AND READS NO STDIN. An exec with stdin attached is
# not reconnected when its connection drops, and an unbounded one waits
# out a Sprite that will never answer. AVRA_SPRITE_CLI stands in for the
# `sprite` CLI.
sprite_cli=${AVRA_SPRITE_CLI:-sprite}
remote_script=$(cat "$here/sprite-remote.sh")
# WHAT A SPRITE MUST CARRY IS MAIN'S ANSWER, never only the caller's checkout: a lane branched before a
# package joined `.github/ci/packages.txt` has the older list, and a Sprite provisioned from it (or
# judged healthy by it) lacks a package every newer tree needs (libzstd-dev: `-lzstd` unfound).
# `packages_of <file>` is one list, a package a line.
packages_of() { grep -v '^#' | tr '\n' ' '; }

# main's list: origin/main refreshed best-effort (a bounded fetch, once per process, only where a list is
# asked for), else the ref as it stands, else the checkout's own file (a tree with no origin, a fixture).
main_packages() {
    root=$(cd "$here/.." && pwd)
    if [ -z "${main_fetched:-}" ]; then
        main_fetched=1
        timeout -k 2 15 git -C "$root" fetch -q origin main 2>/dev/null || :
    fi
    git -C "$root" show "origin/main:$1" 2>/dev/null || cat "$root/$1" 2>/dev/null
}

# What a RUN installs: main's list plus the checkout's own (a branch that adds a package needs it for
# its own run before main has it), plus the profilers. What HEALTH judges: main's list and the
# profilers, never a branch's.
local_list() { cat "$here/../$1" 2>/dev/null; }
unioned() { tr ' ' '\n' | awk 'NF && !seen[$0]++' | tr '\n' ' '; }
health_packages_list() { { main_packages .github/ci/packages.txt; main_packages .github/ci/packages-dev.txt; } | packages_of | unioned; }
sprite_packages_list() { { health_packages_list; local_list .github/ci/packages.txt | packages_of; local_list .github/ci/packages-dev.txt | packages_of; } | unioned; }

# WHAT A SPRITE IS PROVISIONED FROM, as one hash: the provisioning script, the package lists and the
# pinned installers it runs. A Sprite records the hash it was provisioned from, and a run whose tree
# hashes differently provisions again before anything starts.
provision_hash() {
    root=$(cd "$here/.." && pwd)
    ( cd "$root" && for f in tools/sprite-provision.sh .github/ci/packages*.txt .github/ci/install_*.sh; do
        [ ! -f "$f" ] || printf '%s\n' "$f"
    done | LC_ALL=C sort | xargs shasum -a 256 ) | shasum -a 256 | cut -d' ' -f1
}

# What a run that drives a browser adds (`work run --browser`): the browser leg's host libraries, which
# no other run installs.
browser_packages_list() { { main_packages .github/ci/packages-browser.txt; local_list .github/ci/packages-browser.txt; } | packages_of | unioned; }

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

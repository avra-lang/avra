#!/bin/sh
# `sh tools/reclaim.sh [--now] [--dry-run]` — retires worktrees when
# the disk runs low. The branch is always kept; only the checkout goes.
#
# A worktree is retired only when ALL hold:
#   - its branch is merged into main;
#   - `git status --porcelain` is empty;
#   - no process has its cwd inside it (lsof, or /proc);
#   - it is not main's checkout, the repo's own tree, the land batch
#     tree, or the tree of a branch a land.sh ticket names.
# A detached worktree has no branch to keep, so it is never retired.
#
# Runs when free space is under AVRA_RECLAIM_FREE_GB (default 20), or
# always with `--now`. `--dry-run` prints what it would retire.
#
# Paths are overridable so a fixture never touches the real ones:
#   AVRA_LAND_LOCK      land.sh's ticket queue (/tmp/avra-land.lock)
#   AVRA_LAND_BATCH_WT  the batch tree (<main's parent>/avra-land-batch-wt)
set -u

now=0
dry_run=0
for a in "$@"; do
    case "$a" in
        --now) now=1 ;;
        --dry-run) dry_run=1 ;;
        *) echo "usage: sh tools/reclaim.sh [--now] [--dry-run]" >&2; exit 2 ;;
    esac
done

threshold="${AVRA_RECLAIM_FREE_GB:-20}"
lock_dir="${AVRA_LAND_LOCK:-/tmp/avra-land.lock}"

real() { (cd "$1" 2>/dev/null && pwd -P); }

# Free gigabytes on the volume holding the repo.
free_gb() { df -k . | awk 'NR == 2 { print int($4 / 1048576) }'; }

# One `<path>\t<branch>` line per worktree; a detached one has an empty branch.
worktrees() {
    git worktree list --porcelain | awk '
        /^worktree / { wt = substr($0, 10); br = "" }
        /^branch /   { br = substr($0, 19) }
        /^$/         { print wt "\t" br }
        END          { if (wt != "") print wt "\t" br }
    ' | awk -F '\t' '!seen[$1]++'
}

# Branches a land.sh ticket names, one per line.
ticketed() {
    for info in "$lock_dir"/tickets/*/info; do
        [ -f "$info" ] && sed -n 's/^branch=\(..*\)$/\1/p' "$info"
    done
}

# Every process's cwd, one real path per line: `lsof` where it stands, the
# kernel's own table where it does not — a machine with neither answers
# nothing, and nothing is retired there.
cwds() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'
    elif [ -d /proc/self ]; then
        for c in /proc/[0-9]*/cwd; do readlink "$c" 2>/dev/null; done
    else
        echo "reclaim: no way to read a process's directory here — retiring nothing" >&2
        exit 1
    fi
}

# Whether `$1` is `$2` or lies below it.
inside() {
    case "$1" in
        "$2"|"$2"/*) return 0 ;;
    esac
    return 1
}

merged() { git merge-base --is-ancestor "refs/heads/$1" refs/heads/main 2>/dev/null; }

busy() {
    printf '%s\n' "$cwds_now" | while IFS= read -r c; do
        inside "$c" "$1" && echo yes && break
    done | grep -q yes
}

# Why `$1` (a real path, branch `$2`) stays, or nothing when it may go.
kept_because() {
    [ -z "$2" ] && { echo "detached"; return; }
    [ "$1" = "$own_tree" ] && { echo "the repo's own tree"; return; }
    [ "$1" = "$main_tree" ] && { echo "main's checkout"; return; }
    [ "$1" = "$batch_tree" ] && { echo "the land batch tree"; return; }
    [ -n "$tickets_now" ] && printf '%s\n' "$tickets_now" | grep -qxF "$2" && { echo "named by a land ticket"; return; }
    merged "$2" || { echo "unmerged"; return; }
    [ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ] && { echo "dirty"; return; }
    busy "$1" && { echo "busy"; return; }
}

git rev-parse --git-dir > /dev/null 2>&1 || { echo "reclaim: not inside a git repo" >&2; exit 2; }

if [ "$now" -eq 0 ]; then
    free="$(free_gb)"
    if [ "$free" -ge "$threshold" ]; then
        echo "reclaim: ${free} GB free, threshold ${threshold} GB — nothing to do"
        exit 0
    fi
    echo "reclaim: ${free} GB free, under ${threshold} GB"
fi

list="$(worktrees)"
own_tree="$(real "$(printf '%s\n' "$list" | head -n 1 | cut -f 1)")"
main_tree="$(real "$(printf '%s\n' "$list" | awk -F '\t' '$2 == "main" { print $1; exit }')")"
batch_tree="$(real "${AVRA_LAND_BATCH_WT:-$(dirname "${main_tree:-$own_tree}")/avra-land-batch-wt}")"
[ -n "$batch_tree" ] || batch_tree="${AVRA_LAND_BATCH_WT:-}"
tickets_now="$(ticketed)"
cwds_now="$(cwds)" || exit 1

looked=0
retired=0
tab="$(printf '\t')"
while IFS="$tab" read -r path br; do
    [ -n "$path" ] || continue
    looked=$((looked + 1))
    wt="$(real "$path")"
    [ -n "$wt" ] || continue
    [ -z "$(kept_because "$wt" "$br")" ] || continue
    if [ "$dry_run" -eq 1 ]; then
        echo "would retire $wt ($br)"
        retired=$((retired + 1))
    elif git worktree remove "$wt"; then
        echo "retired $wt ($br)"
        retired=$((retired + 1))
    fi
done <<EOF
$list
EOF

[ "$dry_run" -eq 1 ] && verb="would retire" || verb="retired"
echo "reclaim: looked at $looked worktree(s), $verb $retired"

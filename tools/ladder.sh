#!/bin/sh
# tool-witness: --self-test
# BUILDS A LADDER: each rung's tree, in a worktree of its own, with the compiler of the rung before it, and
# answers the last product's path. The one definition CI's prepare and a lane's Sprite both call.
#
#   sh tools/ladder.sh <compiler> <rung-commit>...      prints the last rung's compiler on stdout
#   sh tools/ladder.sh --self-test
#
# A rung's compiler is a REAL generation (`make avra` run by the previous rung's product), so each
# step is the one the generation law already asks of a tree, and a compiler is never asked to read
# what only a newer one can. A rung that does not build names itself and its log; nothing falls back
# to the seed, which cannot read a rung either. The whole ladder is capped at AVRA_LADDER_S (900 s),
# each rung at what is left.
#
# A RUNG IS REPLAYED ON THE TREE UNDER BUILD, NEVER ON ITS OWN. With AVRA_LADDER_BASE set (the base the
# tree is judged against: origin/main for a pull request, the commit before for main's own push), the
# rung's tree is that base with the rung merged in — what a batch or a squash makes of it — so a rung
# whose branch began before the base moved is read with the base's sources, not its stale ones. A rung
# the base already holds is no rung: the starting compiler, built from the base, already reads it.
set -eu
if [ "${1:-}" = --self-test ]; then
    me=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
    d=$(mktemp -d "${TMPDIR:-/tmp}/avra-ladder.XXXXXX")
    git init -q -b main "$d/repo"
    g() { git -C "$d/repo" -c user.name=t -c user.email=t@t "$@"; }
    # a tree whose `make avra` copies the compiler it is handed, stamped with the rung it built
    cat > "$d/repo/Makefile" <<'MK'
avra:
	@mkdir -p build
	@{ cat build/avra; echo "built-by-previous"; } > build/avra.next && chmod +x build/avra.next && mv build/avra.next build/avra
MK
    echo one > "$d/repo/rung"; g add -A; g commit -q -m "rung one

Rung: one"
    r1=$(g rev-parse HEAD)
    echo two > "$d/repo/rung"; g commit -q -am "rung two

Rung: two"
    r2=$(g rev-parse HEAD)
    printf '#!/bin/sh\nstart\n' > "$d/start"; chmod +x "$d/start"
    out=$(cd "$d/repo" && AVRA_LADDER_DIR="$d/work" sh "$me" "$d/start" "$r1" "$r2" 2>"$d/err") || { cat "$d/err"; echo "ladder: a two-rung ladder failed"; exit 1; }
    [ -x "$out" ] && [ "$(grep -c built-by-previous "$out")" = 2 ] \
        || { echo "ladder: the product was not built twice in a chain: $out"; exit 1; }
    # a rung whose build fails names itself and the ladder stops
    printf 'avra:\n\t@exit 1\n' > "$d/repo/Makefile"; g commit -q -am "broken

Rung: broken"
    r3=$(g rev-parse HEAD)
    if (cd "$d/repo" && AVRA_LADDER_DIR="$d/work2" sh "$me" "$d/start" "$r3" > "$d/out3" 2> "$d/err3"); then echo "ladder: a rung that failed to build was passed"; exit 1; fi
    grep -q "rung 1 did not build" "$d/err3" || { echo "ladder: the failing rung was not named: $(cat "$d/err3")"; exit 1; }
    # a rung whose branch began before the base moved is replayed ON the base: a tree that needs the
    # base's file builds, where the rung's own stale tree would not
    printf 'avra:\n\t@test -f moved && mkdir -p build && { cat build/avra; echo built-on-base; } > build/avra.next && chmod +x build/avra.next && mv build/avra.next build/avra\n' > "$d/repo/Makefile"
    g commit -q -am "a build that needs the base's file"
    fix=$(g rev-parse HEAD)
    g checkout -q -b stale "$fix"
    echo stale > "$d/repo/rung"; g commit -q -am "a rung begun before the base moved

Rung: stale"
    r4=$(g rev-parse HEAD)
    g checkout -q main
    echo here > "$d/repo/moved"; g add moved; g commit -q -m "the base moves"
    base=$(g rev-parse HEAD)
    if (cd "$d/repo" && AVRA_LADDER_DIR="$d/work3" sh "$me" "$d/start" "$r4" > /dev/null 2>&1); then
        echo "ladder: the fixture is no witness — the stale rung built on its own tree"; exit 1
    fi
    out=$(cd "$d/repo" && AVRA_LADDER_DIR="$d/work4" AVRA_LADDER_BASE="$base" sh "$me" "$d/start" "$r4" 2>"$d/err4") \
        || { cat "$d/err4"; echo "ladder: a stale rung replayed on the base did not build"; exit 1; }
    grep -q built-on-base "$out" || { echo "ladder: the replayed rung's product is not the base's build"; exit 1; }
    out=$(cd "$d/repo" && AVRA_LADDER_DIR="$d/work5" AVRA_LADDER_BASE="$base" sh "$me" "$d/start" "$r1" 2>"$d/err5") \
        || { cat "$d/err5"; echo "ladder: a rung the base holds failed"; exit 1; }
    grep -q "already in the base" "$d/err5" || { echo "ladder: a rung the base holds was replayed"; exit 1; }
    echo "ladder: self-test passed — two rungs chain their products, a failing rung names itself and stops, a stale rung is replayed on the base, a rung the base holds is skipped"
    exit 0
fi
cur=$(cd "$(dirname "${1:?usage: ladder.sh <compiler> <rung>...}")" && pwd)/$(basename "$1")
shift
# AVRA_LADDER_REPO: the repository that holds the rungs and the base, where the tree under build has no .git (a Sprite's).
[ -z "${AVRA_LADDER_REPO:-}" ] || cd "$AVRA_LADDER_REPO"
dir=${AVRA_LADDER_DIR:-${RUNNER_TEMP:-/tmp}/ladder}
mkdir -p "$dir"
cap=${AVRA_LADDER_S:-900}
began=$(date +%s)
i=0
for r in "$@"; do
    i=$((i + 1))
    left=$((cap - ($(date +%s) - began)))
    [ "$left" -gt 0 ] || { echo "ladder: the $cap s cap passed before rung $i" >&2; exit 1; }
    wt=$dir/rung-$i
    if [ -n "${AVRA_LADDER_BASE:-}" ]; then
        git merge-base "$AVRA_LADDER_BASE" "$r" >/dev/null 2>&1 || git fetch -q --deepen=300 origin 2>/dev/null || :
        if git merge-base --is-ancestor "$r" "$AVRA_LADDER_BASE" 2>/dev/null; then
            echo "ladder: rung $i at $(git log -1 --format=%h "$r") is already in the base — no replay" >&2
            continue
        fi
        git worktree add -q --detach "$wt" "$AVRA_LADDER_BASE"
        git -C "$wt" -c user.name=ladder -c user.email=ladder@avra.invalid merge -q --no-edit "$r" > "$wt.merge.log" 2>&1 || {
            cat "$wt.merge.log" >&2
            echo "ladder: rung $i does not merge onto the base $(git log -1 --format=%h "$AVRA_LADDER_BASE")" >&2
            exit 1
        }
    else
        git worktree add -q --detach "$wt" "$r"
    fi
    mkdir -p "$wt/build"
    cp "$cur" "$wt/build/avra"
    chmod +x "$wt/build/avra"
    why=$(git log -1 --format=%B "$r" | sed -n 's/^Rung: //p' | head -n 1)
    echo "ladder: rung $i at $(git log -1 --format=%h "$r") — $why" >&2
    s=$(date +%s)
    if ! (cd "$wt" && timeout -k 10 "$left" make -s avra) > "$wt/ladder.log" 2>&1; then
        cat "$wt/ladder.log" >&2
        echo "ladder: rung $i did not build with the compiler of the rung before it (see its log above)" >&2
        exit 1
    fi
    echo "ladder: rung $i built in $(($(date +%s) - s)) s" >&2
    cur=$wt/build/avra
done
echo "$cur"

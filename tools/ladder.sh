#!/bin/sh
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
    echo "ladder: self-test passed — two rungs chain their products, a failing rung names itself and stops"
    exit 0
fi
cur=$(cd "$(dirname "${1:?usage: ladder.sh <compiler> <rung>...}")" && pwd)/$(basename "$1")
shift
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
    git worktree add -q --detach "$wt" "$r"
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

#!/bin/sh
# EACH STORE BUG THE FUZZER EXISTS FOR IS FOUND BY IT WITH ITS FIX TAKEN BACK. Every patch under
# tools/store-fuzz/ takes one fix back out of this tree; for each, a copy of the tree with the patch
# laid on, a compiler built from it, and the fuzzer run over that regression's seeds — which must
# FAIL. A patch that no longer lays on is refused by name: renew it against the tree, never drop it.
#   1 an unrecorded read whose key doesn't cover its miss: faced_signature, the machine store poisoned
#   2 orphans kept by a write: a new answer nothing reaches, written standing
#   3 a directory listing that names the store beside its sources: a neighbour's save works again
#   4 the stale-reader meet: what a reader that stands no more read, asked and written back — taken
#     back WITH 5, which makes any place that comes back a root and so leaves the meet's ask
#     harmless; the fuzzer's seat, seat, seat (a method's defaulted seat added, renamed twice) holds
#     with 4 alone taken back and fails with both
#   5 a place that comes back not made a root: a record checked read by read works a lost answer out
#     again, written standing where no root reaches it
#   6 a rebased chain's roots: a root a delta made, rewritten as no root, lost over the base alone
# Each compiler build is the long part (minutes); the regressions run one after another.
#
#   sh tools/store_fuzz_regressions.sh [<n>…]      (default: every patch)
. "$(dirname "$0")/lib/scratch.sh"
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
# the seeds, the steps and the fixture each regression is held to: a draw that reaches its shape (the
# unrecorded read's is the board's, a dev loop's half-typed declaration, as its own witness has it)
seeds_of() {
    case $1 in
        1) echo "1-5 2 board" ;;
        2) echo "2-7 12 packages" ;;
        3) echo "4-6 13 packages" ;;
        4) echo "1-2 3 packages" ;;
        5) echo "1-2 3 packages" ;;
        6) echo "14-15 8 packages" ;;
    esac
}
only=${*:-1 2 3 4 5 6}
missed=""
for n in $only; do
    patch=$(ls tools/store-fuzz/regress-"$n"-*.patch 2>/dev/null | head -1)
    [ -n "$patch" ] || { echo "store_fuzz_regressions: no patch numbered $n" >&2; exit 2; }
    scratch_dir work
    git worktree add -q --detach "$work" HEAD || exit 2
    git diff HEAD | (cd "$work" && git apply --allow-empty) || { echo "store_fuzz_regressions: this tree's own edits don't lay on a copy" >&2; exit 2; }
    if ! (cd "$work" && git apply "$root/$patch"); then
        echo "store_fuzz_regressions: $patch no longer lays on this tree — renew it against the tree" >&2
        git worktree remove --force "$work"
        exit 2
    fi
    echo "store_fuzz_regressions: $patch laid on — building its compiler"
    if ! (cd "$work" && mkdir -p build && cp -p "$root"/build/avra "$root"/build/.avra-built-from "$root"/build/*.o "$root"/build/*.a build/ 2>/dev/null; AVRA_PROGRAM_NET=0 make avra build/sqlite3.o build/sqlite_sentinel.o >"$work/make.log" 2>&1); then
        echo "store_fuzz_regressions: $patch's compiler didn't build:" >&2; tail -20 "$work/make.log" >&2
        git worktree remove --force "$work"; exit 2
    fi
    set -- $(seeds_of "$n")
    ./wisp --compiler "$root/build/avra" store_fuzz --compiler "$work/build/avra" --fixture "$3" --seeds "$1" --steps "$2" --no-shrink >"$work/fuzz.log" 2>&1
    said=$?
    if [ "$said" = 2 ]; then
        echo "store_fuzz_regressions: $patch — the harness failed, which finds nothing:" >&2
        grep "harness failed" "$work/fuzz.log" | head -2 >&2
        git worktree remove --force "$work"; exit 2
    elif [ "$said" = 0 ]; then
        echo "store_fuzz_regressions: $patch — NOT FOUND over seeds $1, $2 steps each, on the $3 fixture"
        missed="$missed $n"
    else
        echo "store_fuzz_regressions: $patch — found:"
        grep "FAILS\|replay with" "$work/fuzz.log" | sed 's/^/    /'
    fi
    git worktree remove --force "$work"
done
[ -z "$missed" ] || { echo "store_fuzz_regressions: the fuzzer missed:$missed" >&2; exit 1; }
echo "store_fuzz_regressions: every regression found"

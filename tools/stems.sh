#!/bin/sh
# THE STEM LAW'S KEEPER. The Makefile holds ONE definition of "a stem
# names its object, so a stem is unique tree-wide" (TREE_STEM_LAW);
# this drives that definition with synthetic inputs, so the law and its
# test can never be two rules disagreeing. TREE_C is overridden on
# make's command line — no file is created, nothing in packages/ moves.
#
# BOTH SURFACES, because a keeper that has only ever been watched
# refusing is half-tested: the ACCEPT rows prove it does not refuse a
# tree that is fine, and a dead alternative there would widen the law
# in silence.
#
# EVERY ROW CARRIES THE TREE'S OWN C. `test` wants RUNTIME_OBJS
# whatever TREE_C says, so a row omitting runtime/avra_runtime.c asks
# make for an object no source can build and fails for a reason that
# is not the law. The first draft did, and PASSED — the objects were
# on disk from an earlier build, and the rows only spoke when the
# tree was cold.
set -e
cd "$(dirname "$0")/.."
: "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
export LLVM_PREFIX

fails=0
rows=0

# A row: the words `make -n test` must answer for these sources, and
# the verdict. `refuse` demands the law names every clashing file.
OWN="runtime/avra_runtime.c backend/llvm_wrapper.c"

row() {
    what="$1"; want_status="$2"; sources="$3"; want_words="$4"
    rows=$((rows + 1))
    out=$(make -n test TREE_C="$OWN $sources" 2>&1) && status=0 || status=$?
    if [ "$status" != "$want_status" ]; then
        echo "stems: $what — status $status, wanted $want_status"
        fails=$((fails + 1))
        return
    fi
    case "$out" in
        *"$want_words"*) ;;
        *) echo "stems: $what — the words are not there: $want_words"
           fails=$((fails + 1)) ;;
    esac
}

LAW="a stem is unique tree-wide"

row "two packages sharing a stem" 2 \
    "packages/std-io/src/c/util.c packages/std-path/src/c/util.c" \
    "rename one of: packages/std-io/src/c/util.c packages/std-path/src/c/util.c"
row "a vendored unit against a package's own" 2 \
    "packages/std-a/vendor/z.c packages/std-b/src/c/z.c" "$LAW"
row "three sharing one stem" 2 \
    "a/src/c/u.c b/src/c/u.c c/src/c/u.c" "rename one of: a/src/c/u.c b/src/c/u.c c/src/c/u.c"
row "two clashes at once" 2 "a/p.c b/p.c a/q.c b/q.c" "a/p.c b/p.c a/q.c b/q.c"
row "distinct stems stand" 0 \
    "packages/std-net/src/c/std_net.c packages/width-witness/src/c/width_witness.c" ""
row "one package source stands" 0 "packages/std-net/src/c/std_net.c" ""
row "the tree's own C alone stands" 0 "" ""

# The tree itself, through the same law.
rows=$((rows + 1))
make -n test >/dev/null 2>&1 || { echo "stems: the tree's own stems clash"; fails=$((fails + 1)); }

if [ "$fails" != 0 ]; then
    echo "stems: $fails of $rows rows failed"
    exit 1
fi
echo "stems: $rows rows — the stem law refuses every clash and accepts every distinct set"

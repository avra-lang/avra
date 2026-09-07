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
    out=$(make -n idioms TREE_C="$OWN $sources" 2>&1) && status=0 || status=$?
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

# A TARGET DEPENDS ON WHAT IT LINKS. Two lists, two rules, and the
# rules read DIFFERENT sources from the Makefile so they cannot agree
# with it by construction: the manifests say what a package promises
# the link, and `build/avra` itself says what the compiler took.
#
# It went wrong twice in one campaign, in both directions. A
# hand-kept list let `make avra` link an object it had never built —
# the evaluator's trampoline, then @std/io's own C. Depending on every
# object instead cost a 9.5 MB vendored amalgamation compiled for a
# binary that never links it.
# A target's PREREQUISITES, which is the question — `make -n` prints
# only what it would DO, and an object already on disk produces no
# line at all, so a recipe scan answers "absent" about everything a
# warm tree already has.
prereqs_of() { make -p -n "$1" 2>/dev/null | grep -m1 "^$1:" | sed "s/^$1://"; }

# EVERY OBJECT A MANIFEST NAMES IS A PACKAGE OBJECT.
rows=$((rows + 1))
package_objs=" $(prereqs_of test) "
for obj in $(sed -n 's/.*objects *= *\[\(.*\)\].*/\1/p' packages/*/avra.toml \
             | tr ',' '\n' | tr -d ' "' | sed 's|.*/||' | sort -u); do
    case "$package_objs" in
        *" build/$obj "*) ;;
        *) echo "stems: a manifest names build/$obj and no target that runs programs depends on it"
           fails=$((fails + 1)) ;;
    esac
done

# EVERY OBJECT THE COMPILER TOOK IS A COMPILER OBJECT — asked of the
# BINARY, not of a closure walked here. A second dependency resolver
# would be a copy of the one that decides the answer; `nm` reads what
# actually happened.
rows=$((rows + 1))
looked=0
if [ -x build/avra ]; then
    compiler_objs=" $(prereqs_of avra) "
    for o in build/*.o; do
        [ -e "$o" ] || continue
        sym=$(nm -gU "$o" 2>/dev/null | sed -n 's/.* T _//p' | head -1)
        [ -n "$sym" ] || continue
        nm -gU build/avra 2>/dev/null | grep -q " T _$sym\$" || continue
        looked=$((looked + 1))
        case "$compiler_objs" in
            *" $o "*) ;;
            *) echo "stems: build/avra carries $sym from $o, and \`make avra\` does not depend on it"
               fails=$((fails + 1)) ;;
        esac
    done
fi
# A CHECK THAT EXAMINED NOTHING IS NOT A CHECK THAT PASSED. It reads
# objects on disk, and on a cold tree there are none — so it says how
# many it looked at rather than reporting green over an empty set.
if [ "$looked" = 0 ]; then
    echo "stems: the compiler's objects were not on disk — that rule examined NOTHING"
fi

# A MAKEFILE VARIABLE IS ASSIGNED ONCE. Make takes the LAST assignment
# and the earlier one is dead — but it does not LOOK dead, and a
# reader who edits it is editing nothing. `COMPILER_OBJS` was defined
# twice inside the very change that fixed the link-dependency class,
# and the cost was a FALSE NEGATIVE IN A REVIEW: lane A edited the
# dead copy to test this keeper's teeth, watched the keeper pass, and
# was drafting "the compiler-list check does not work" before the
# prerequisite order made them look again. A dead definition that
# reads as authoritative turns a working keeper into a broken one in
# the reviewer's notes.
#
# READ TEXTUALLY, and here that is right rather than a shortcut: the
# rule is about the FILE's own shape, and make's database shows only
# the surviving value — it cannot say a name was assigned twice.
rows=$((rows + 1))
twice=$(grep -E '^[A-Za-z_][A-Za-z0-9_]* *:?\??=' Makefile \
        | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*).*/\1/' | sort | uniq -d)
for name in $twice; do
    where=$(grep -nE "^$name *:?\??=" Makefile | cut -d: -f1 | tr '\n' ' ')
    echo "stems: the Makefile assigns $name more than once (lines $where) — make takes the last and the rest are dead"
    fails=$((fails + 1))
done

if [ "$fails" != 0 ]; then
    echo "stems: $fails of $rows rows failed"
    exit 1
fi
echo "stems: $rows rows — the stem law holds, every manifest object has a target, and $looked of the compiler's own were read from the binary"

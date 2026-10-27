#!/bin/sh
# DB 06 step 5: A PRODUCER'S STAMP COVERS THE C ITS CODE RUNS.
#
# A compiler fills the store; a second compiler, whose runtime C differs by one line and
# whose answers are otherwise identical, reads that store. The witness is what the second
# one finds there: every module record it would have produced itself (a MISS, so it
# recomputes), never the first one's rows.
set -u
. "$(dirname "$0")/lib/attack.sh"
R=build/db06-step5
mkdir -p $R
pkg=${PKG:-packages/std-relation}
c=runtime/avra_runtime.c

wipe() { if [ -d .avra-cache ]; then find .avra-cache -delete; fi; true; }
sig_hits() { awk -F'\t' 'BEGIN { n = 0 } $1 == "Q" && $2 == "store" && $3 == "kind" && $4 == "get" && $5 == "hit" && $6 == "sig" { n++ } END { print n }' "$1"; }
sig_rows() { awk -F'\t' 'BEGIN { n = 0 } $1 == "Q" && $2 == "store" && $3 == "kind" && $4 == "get" && $6 == "sig" { n++ } END { print n }' "$1"; }
run() { # run <label>
    AVRA_QTRACE=1 ./avra check $pkg >$R/$1.out 2>$R/$1.trace
    echo "$1: exit $? — module-record lookups $(sig_rows $R/$1.trace), hit $(sig_hits $R/$1.trace)"
}
build() {
    make -s avra >$R/build.log 2>&1 || { echo "BUILD FAILED"; tail -20 $R/build.log; exit 1; }
}

cp $c $R/avra_runtime.c.kept
trap 'cp $R/avra_runtime.c.kept $c' EXIT INT TERM

echo "=== compiler A: this tree's, against this tree's runtime C"
wipe
build
run a1
run a2

echo "=== the C moves: one symbol more, no behaviour changes"
printf '\n/* the witness`s own symbol: the runtime C of a second build */\nint avra_db06_step5_probe(void) { return 0; }\n' >> $c
build
echo "archive $(shasum -a 256 build/libavra_runtime.a | cut -d' ' -f1 | cut -c1-16), binary $(shasum -a 256 build/avra | cut -d' ' -f1 | cut -c1-16)"

echo "=== compiler B, over A's store"
run b1
run b2

echo "=== the edit changes no answer"
cmp -s $R/a1.out $R/b1.out && echo "same answer" || echo "DIFFERENT ANSWER"

hits=$(sig_hits $R/b1.trace)
echo "WITNESS: the second compiler read $hits of the first one's module records"
[ "$hits" = 0 ] || { echo "FAIL: a compiler whose C differs read $hits module records"; exit 1; }
# the tree's compiler is rebuilt from the C it stands on, so whatever runs next runs it
cp $R/avra_runtime.c.kept $c
build
echo "PASS"

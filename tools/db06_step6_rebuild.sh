#!/bin/sh
# DB 06 step 6: §6.8's "a check after a rebuild that changed one query recomputes that
# query's answers only" — MEASURED.
#
# A compiler fills the tree's store. ONE LEAF of ONE query moves, the compiler is rebuilt, and
# the second compiler checks the same package over the first one's store. What the second run
# had to WRITE is the answer (`--counts`' `store_rows_written`, and the store's own trace line
# `Q store kind get hit|miss <family>`):
#
#   a warm check of an unchanged tree                     writes 0 rows
#   the same check after a rebuild that moved one leaf     writes the store
#
# and the families say why, because `store.av`'s `stamp_of` gives each family ONE stamp:
#   sig   `producers.sig` — a digest over the CODE HASHES of the record producer's closure
#         (`record.av`), so a rebuild that moves no fn of that closure keeps every record and
#         one that moves a fn inside it keeps none: per FAMILY, never per query
#   unit  `own ${print}` — the running compiler's own bytes, so ANY rebuild re-keys every row
#         of that family at once
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
R=build/db06-step6
mkdir -p $R
pkg=${PKG:-packages/std-avrac}
leaf=packages/std-avrac/src/compiler/producers.av
from='p.length >= 7'
to='7 <= p.length'

rows() { awk -F'\t' -v f="$2" 'BEGIN { h = 0; m = 0 } $1 == "Q" && $2 == "store" && $3 == "kind" && $4 == "get" && $6 == f { if ($5 == "hit") h++; else m++ } END { printf "%d hit, %d miss", h, m }' "$1"; }
written() { sed -n 's/.*store_rows_written=\([0-9]*\).*/\1/p' $R/$1.out | tail -1; }
computed() { sed -n 's/.*queries_computed=\([0-9]*\).*/\1/p' $R/$1.out | tail -1; }
checked() {
    AVRA_QTRACE=1 ./avra check --counts $pkg >$R/$1.out 2>$R/$1.err
    echo "status $?" >>$R/$1.out
    grep '^Q	' $R/$1.err >$R/$1.trace
    grep -v -e '^Q	' -e '^watch:' -e 'job control turned off' $R/$1.err >>$R/$1.out
}
build() {
    AVRA_QTRACE=1 make -s avra >$R/build-$1.log 2>&1 || { echo "BUILD FAILED"; tail -20 $R/build-$1.log; cp $R/producers.av.kept $leaf; exit 1; }
    cp build/avra $R/avra.$1
}
cp $leaf $R/producers.av.kept
trap 'cp $R/producers.av.kept $leaf' EXIT INT TERM

echo "=== compiler A: this tree's, over a store of this tree's"
if [ -d .avra-cache ]; then find .avra-cache -delete; fi
build a
checked a1
checked a2
echo "cold check: sig $(rows $R/a1.trace sig) · unit $(rows $R/a1.trace unit) · rows written $(written a1)"
echo "warm check: sig $(rows $R/a2.trace sig) · unit $(rows $R/a2.trace unit) · rows written $(written a2), queries $(computed a2)"

echo
echo "=== ONE leaf of ONE query moves: \`${from}\` becomes \`${to}\`"
sed -i.bak "s/${from}/${to}/" $leaf
landed=$(grep -c "$to" $leaf)
[ "$landed" = 1 ] || { echo "FAIL: the edit landed ${landed} time(s)"; exit 1; }
build b
echo "compiler A $(shasum -a 256 $R/avra.a | cut -c1-16) -> compiler B $(shasum -a 256 build/avra | cut -c1-16)"
checked b1
echo "warm check: sig $(rows $R/b1.trace sig) · unit $(rows $R/b1.trace unit) · rows written $(written b1), queries $(computed b1)"

# THE ANSWER IS WHAT A CHECK SAID: its diagnostics. `counts:` and `why:` are the run's own
# work counters, and a run that recomputes must differ there — comparing them would be asking
# whether a recompute was a recompute.
answers() { sed -e '/^counts: /d' -e '/^why: /d' -e '/^status /d' $R/$1.out; }
answers a1 >$R/a1.answers
answers b1 >$R/b1.answers
echo "=== the edit changes no answer"
cmp -s $R/a1.answers $R/b1.answers && echo "same answer: $(wc -l < $R/b1.answers) lines of diagnostics, cold A against rebuilt B" || { echo "DIFFERENT ANSWER"; diff $R/a1.answers $R/b1.answers | head -10; }

# The tree's compiler is rebuilt from the source it stands on, so whatever runs next runs it.
cp $R/producers.av.kept $leaf
build restored
checked r1
echo "restored:   sig $(rows $R/r1.trace sig) · unit $(rows $R/r1.trace unit) · rows written $(written r1)"

a=$(written a2)
b=$(written b1)
r=$(written r1)
echo
echo "WITNESS: a warm check over an unchanged tree wrote ${a} store row(s); after ONE leaf of ONE"
echo "         query moved and the compiler rebuilt, the same check wrote ${b}; restored, ${r}"
[ "$a" = 0 ] || { echo "FAIL: the unchanged tree's warm check wrote ${a} row(s)"; exit 1; }
[ "$b" -gt 0 ] || { echo "FAIL: the rebuilt tree's warm check wrote nothing, so it reused a foreign store"; exit 1; }
[ "$r" = 0 ] || { echo "FAIL: the restored tree's warm check wrote ${r} row(s)"; exit 1; }
echo "§6.8: a rebuild that changed ONE query recomputed and rewrote the whole store — no row of"
echo "      any family is keyed by the code of the query that answers it"
echo "PASS"

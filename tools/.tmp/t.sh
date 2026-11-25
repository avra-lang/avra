for p in nullable expr_spine impls; do
P=packages/std-avrac/src/features/$p
./avra test $P >/dev/null 2>&1   # warm everything and make the proofs
echo "== $p warm, proofs kept:"; ./avra test $P 2>&1 | grep -E "^proofs:" | cut -c1-120
for d in $(find . -type d -name proofs 2>/dev/null | head -3); do find $d -type f -delete; done
echo "== $p warm, proofs deleted:"; ./avra test $P 2>&1 | grep -E "^proofs:" | cut -c1-120
done
echo W-DONE

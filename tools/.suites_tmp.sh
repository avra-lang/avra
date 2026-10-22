make avra 2>&1 | tail -3
echo "== grammar"; build/avra test packages/std-grammar 2>&1 | grep -E "✗|tests passed"
for f in packages/std-avrac/src/features/tests/node_grammar_test.av packages/std-avrac/src/features/tests/node_grammar_fold_test.av packages/std-avrac/src/core/tests/facet_mark_test.av packages/std-avrac/src/core/tests/facet_adversarial_test.av; do echo "== $f"; build/avra test $f 2>&1 | grep -E "✗|tests passed|actual|expected"; done
cd packages; for f in std-grammar/src/builders.av std-avrac/src/features/builder.av std-avrac/src/features/node_grammar.av std-avrac/src/features/tests/node_grammar_test.av; do cp $f /tmp/b_$(basename $f); ../build/avra fmt --write $f >/dev/null 2>&1; echo "== DIFF $f"; diff -u /tmp/b_$(basename $f) $f; done
echo "== all done"

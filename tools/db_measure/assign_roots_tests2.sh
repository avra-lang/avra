#!/bin/sh
# avra-8sb5.57.195/198: the targeted suites not reached in the first run.
cd "$(dirname "$0")/../.." || exit 1
for f in \
    packages/std-avrac/src/features/mutation/tests/mutation_mechanical_test.av \
    packages/std-avrac/src/features/expr_stmt/tests/expr_stmt_test.av \
    packages/std-avrac/src/features/expr_stmt/tests/expr_stmt_mechanical_test.av \
    packages/std-avrac/src/compiler/tests/references_test.av \
    packages/std-avrac/src/core/tests/flow_test.av ; do
    echo "== $f =="
    ./avra test "$f" 2>&1 | tail -2
    echo "exit $?"
done

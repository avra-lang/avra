#!/bin/sh
export LLVM_PREFIX=/usr/lib/llvm-22
cd "$(dirname "$0")/.."
find . -name .avra-cache -type d -prune -exec rm -rf {} +
echo "=== make avra x2"
make avra > build/m1.log 2>&1; tail -2 build/m1.log
make avra > build/m2.log 2>&1; tail -2 build/m2.log
T=packages/std-avrac/src/features/annotations/tests
F="packages/std-avrac/src/compiler/expand.av packages/std-avrac/src/compiler/voices.av packages/std-avrac/src/compiler/workspace_analysis.av packages/std-avrac/src/features/annotations/check.av $T/annotations_adversarial_test.av $T/const_argument/src/main.av $T/const_argument/src/tags.av $T/const_argument/src/far/names.av"
echo "=== fmt --write"
build/avra fmt --write $F 2>&1 | tail -5
tar cf build/fmt.tar $F
echo "=== fncall probe"
(cd probes/fncall && ../../build/avra run src/main.av 2>&1 | head -12)
echo "=== program test"
build/avra test $T/const_argument 2>&1 | tail -15
echo "=== adversarial"
build/avra test $T/annotations_adversarial_test.av 2>&1 | tail -25
echo "=== idioms"
make idioms 2>&1 | tail -15
echo "=== std-avrac suite"
build/avra test packages/std-avrac 2>&1 | tail -40

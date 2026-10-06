#!/bin/sh
# THE DIFF'S LAW, AT LENGTH: packages/std-ui/src/realize/dom/tests/repaint_law
# built native and run over UI_FUZZ_CASES (default 2000) cases under each of
# UI_FUZZ_SEEDS (default 20) seeds from UI_FUZZ_SEED (default 1). The suite
# runs the same program over a few cases in both engines; this is the long
# run. A case that breaks the law is printed shrunk, with the seed and turn
# that replay it, and the run fails.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$here/build/avra}
law="$here/packages/std-ui/src/realize/dom/tests/repaint_law/repaint_law"
[ -x "$avra" ] || { echo "ui-fuzz: no compiler at $avra — nothing ran"; exit 1; }
mkdir -p "$here/build"
"$avra" build "$law.av" > "$here/build/ui-fuzz-build.out" 2>&1 || { tail -20 "$here/build/ui-fuzz-build.out"; echo "ui-fuzz: the program did not build"; exit 1; }
out=$(UI_FUZZ_SEED=${UI_FUZZ_SEED:-1} UI_FUZZ_SEEDS=${UI_FUZZ_SEEDS:-20} UI_FUZZ_CASES=${UI_FUZZ_CASES:-2000} "$law") || { echo "$out"; echo "ui-fuzz: the program failed"; exit 1; }
held=$(echo "$out" | grep -c ' cases hold the law' || true)
if [ "$held" -ne "${UI_FUZZ_SEEDS:-20}" ]; then
    echo "$out"
    echo "ui-fuzz: the law is broken — $held of ${UI_FUZZ_SEEDS:-20} seeds held"
    exit 1
fi
echo "$out" | tail -3
echo "ui-fuzz: $held seeds of ${UI_FUZZ_CASES:-2000} cases each hold the law"

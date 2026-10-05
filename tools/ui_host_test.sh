#!/bin/sh
# THE JS HOST'S OWN PROOF, in two halves. runtime/dom/bootstrap_test.js
# applies every patch op to a stub document and checks the echo.
# runtime/dom/corpus_test.js then holds the host to the MODEL host the
# diff's property test judges by: cases the program grows from a seed
# (packages/std-ui/src/realize/dom/tests/host_corpus) are applied by
# bootstrap.js and the page it ends holding is compared with the model's —
# first the few cases the suite pins, then UI_CORPUS_CASES (default 300)
# under each of UI_CORPUS_SEEDS (default "1 2") from a native build.
# It needs `node`; where node is absent this SKIPS, spoken, so a machine
# without it is not falsely green — and so does the wide run where no
# compiler stands.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
if ! command -v node >/dev/null 2>&1; then
    echo "ui-host-test: SKIPPED — no \`node\` on this machine; runtime/dom/bootstrap_test.js did not run"
    exit 0
fi
out=$(node "$here/runtime/dom/bootstrap_test.js") || { echo "$out" | grep -v '^✓' ; echo "ui-host-test: the host's tests failed"; exit 1; }
echo "ui-host-test: $(echo "$out" | tail -1)"

corpus="$here/packages/std-ui/src/realize/dom/tests/host_corpus/host_corpus"
out=$(node "$here/runtime/dom/corpus_test.js" "$corpus.expected") || { echo "$out"; echo "ui-host-test: the host and the model disagree on the pinned cases"; exit 1; }
echo "ui-host-test: pinned corpus — $out"

avra=${AVRA:-$here/build/avra}
if [ ! -x "$avra" ]; then
    echo "ui-host-test: SKIPPED the wide corpus — no compiler at $avra"
    exit 0
fi
mkdir -p "$here/build"
"$avra" build "$corpus.av" > "$here/build/ui-corpus-build.out" 2>&1 || { tail -20 "$here/build/ui-corpus-build.out"; echo "ui-host-test: the corpus program did not build"; exit 1; }
for seed in ${UI_CORPUS_SEEDS:-1 2}; do
    UI_CORPUS_SEED=$seed UI_CORPUS_CASES=${UI_CORPUS_CASES:-300} "$corpus" > "$here/build/ui-corpus.txt" || { echo "ui-host-test: the corpus program failed under seed $seed"; exit 1; }
    out=$(node "$here/runtime/dom/corpus_test.js" "$here/build/ui-corpus.txt") || { echo "$out"; echo "ui-host-test: the host and the model disagree under seed $seed — replay: UI_CORPUS_SEED=$seed UI_CORPUS_CASES=${UI_CORPUS_CASES:-300} $corpus | node runtime/dom/corpus_test.js"; exit 1; }
    echo "ui-host-test: seed $seed — $out"
done

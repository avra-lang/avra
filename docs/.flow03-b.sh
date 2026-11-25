#!/bin/sh
# Temporary: the @unbroken PR's checks — the diagnostics doc made, the
# test file green, three breaks, then the keepers.
set -u
build/avra diagnostics > docs/DIAGNOSTICS.md 2> build/diag.err; echo "diagnostics $?"; head -3 build/diag.err
echo "DIAGB64:$(gzip -c docs/DIAGNOSTICS.md | base64 -w0)"
t=packages/std-avrac/src/compiler/tests/unbroken_test.av
run() { AVRA_MEM_CEILING_MB=5000 build/avra test "$t" > build/u.out 2>&1; grep -E 'tests passed|✗|avra:' build/u.out | sed 's/@.*//' | head -8; }
echo "== green"; run
broke() {
    f=$1; from=$2; to=$3; label=$4
    cp "$f" build/u.keep
    python3 - "$f" "$from" "$to" <<'PY'
import sys
p, a, b = sys.argv[1:4]
t = open(p).read()
assert t.count(a) == 1, a
open(p, 'w').write(t.replace(a, b))
PY
    echo "== break: $label"; run
    grep -q '✗' build/u.out || echo "SURVIVED: $label"
    cp build/u.keep "$f"
}
broke packages/std-avrac/src/compiler/typing/typing.av "        self.unbroken_law(x)
" "" "the law is never asked"
broke packages/std-avrac/src/compiler/typing/unbroken.av ".Fn or .Method or .Default or .Main or .Case -> !x.external && !self.view.decls.marks_unbroken(g)," ".Fn or .Method or .Default or .Main or .Case -> false," "every fn is taken as unbroken"
broke packages/std-avrac/src/compiler/cancel_reach.av "own: !self.decls.marks_unbroken(d) && s.spins() ||" "own: s.spins() ||" "the fact ignores the mark"
broke packages/std-avrac/src/features/decls.av "fn marks_unbroken(d: DeclId) -> bool { !self.meta_annotations(d, \"unbroken\").is_empty() }" "fn marks_unbroken(d: DeclId) -> bool { self.annotations_of(d).any(it.name == \"unbroken\") }" "the mark is read as a word"
make keepers > build/keepers.out 2>&1; echo "keepers $?"; grep -E 'keepers: [a-z-]+ refused|witnesses:' build/keepers.out | head

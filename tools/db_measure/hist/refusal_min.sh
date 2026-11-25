#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
T=packages/std-avrac/src
build/avra fmt --check $T/compiler/references.av $T/compiler/consumes.av $T/features/decls.av $T/compiler/tests/references_refused_test.av | tail -n 1
for t in $T/compiler/tests/references_refused_test.av $T/features/tests/refs_stand_test.av $T/compiler/tests/references_test.av $(ls $T/compiler/tests/*consum* 2>/dev/null); do
    build/avra test "$t" > "$HOME/rf.log" 2>&1; echo "PROOF	$(basename "$t")	status=$?	$(grep -a 'tests passed' "$HOME/rf.log")"
    grep -a "✗\|^error\|^avra:" -A8 "$HOME/rf.log" | head -n 40 | cut -c1-260
done
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/rf.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"; grep -a "NEW violation" -A6 "$HOME/rf.idioms.log" | head -n 12 | cut -c1-220
m=$T/features/decls.av
cp "$m" "$HOME/decls.clean"
python3 - "$m" <<'PY'
import sys
p = sys.argv[1]
t = open(p).read()
a = "fn refs_stand() -> bool { (self.ensure_refs.get())() }"
assert t.count(a) == 1
open(p, "w").write(t.replace(a, "fn refs_stand() -> bool {\n        let _ = (self.ensure_refs.get())()\n        true\n    }"))
PY
build/avra test $T/compiler/tests/references_refused_test.av > "$HOME/rf.mut.log" 2>&1; echo "MUTANT	readers-read-anyway	status=$?	$(grep -a 'tests passed' "$HOME/rf.mut.log")"
grep -a "✗\|^avra:" "$HOME/rf.mut.log" | head -n 6 | cut -c1-260
cp "$HOME/decls.clean" "$m"

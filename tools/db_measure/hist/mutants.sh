#!/bin/sh
# read-cost on the clean tree, then each named mutant of Rows.replaced against the specs that must catch it.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
f=packages/std-relation/src/rows.av
make read-cost > "$HOME/rc.log" 2>&1; echo "PROOF	read-cost	status=$?"; grep -a "^write\.\|read_cost" "$HOME/rc.log"
cp "$f" "$HOME/rows.clean"
mutant() {
    python3 - "$f" "$2" "$3" <<'PY'
import sys
p, a, b = sys.argv[1:4]
t = open(p).read()
assert t.count(a) == 1, a
open(p, "w").write(t.replace(a, b))
PY
    build/avra test packages/std-relation/src/tests/given_kernel_test.av > "$HOME/mut.$1.log" 2>&1
    echo "MUTANT	$1	status=$?	$(grep -a 'tests passed' "$HOME/mut.$1.log")"
    grep -a "✗" "$HOME/mut.$1.log" | cut -c1-260
    cp "$HOME/rows.clean" "$f"
}
mutant every-bucket 'if b >= 0 && self.met.first(self.met.buckets, b) { out.push(b) }' 'if b >= 0 { out.push(b) }'
mutant heard-by-db 'let heard = db.read_in(self.family.get())' 'let heard = db.read_ever()'
build/avra test packages/std-relation/src/tests/given_kernel_test.av > "$HOME/mut.none.log" 2>&1
echo "MUTANT	none	status=$?	$(grep -a 'tests passed' "$HOME/mut.none.log")"

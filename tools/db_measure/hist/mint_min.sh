#!/bin/sh
export AVRA_MEM_CEILING_MB=${AVRA_MEM_CEILING_MB:-5000}
build/avra fmt --check packages/std-avrac/src/features/decls_mint.av packages/std-avrac/src/compiler/interface.av packages/std-avrac/src/features/tests/decl_facts_test.av | tail -n 1
build/avra test packages/std-avrac/src/features/tests/decl_facts_test.av > "$HOME/mm.test.log" 2>&1; echo "PROOF	decl_facts_test	status=$?	$(grep -a 'tests passed' "$HOME/mm.test.log")"; grep -a "✗\|^error" -A6 "$HOME/mm.test.log" | head -n 30 | cut -c1-220
build/avra check packages/std-avrac --baseline tools/idioms.baseline > "$HOME/mm.idioms.log" 2>&1; echo "PROOF	idioms std-avrac	status=$?"
f=packages/cli/src/commands/shared.av
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
cp "$f" "$HOME/shared.orig"
build/avra check packages/cli > /dev/null 2>&1; echo "PROOF	cold check cli	status=$?"
python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(t.replace("· memo", "· memo held-mint", 1))
PY
build/avra check --time packages/cli > "$HOME/mm.edit.log" 2>&1; echo "PROOF	one-edit check cli	status=$?	$(grep -a '^time:' "$HOME/mm.edit.log" | tail -n 1 | cut -c1-230)"
cp "$HOME/shared.orig" "$f"

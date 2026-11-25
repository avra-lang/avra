#!/bin/sh
make -s try || { echo "try failed"; exit 1; }
cp build/avra build/avra.builder; cp build/avra-try build/avra
CACHE_ATTACKS=tw sh tools/cache_attacks.sh 2>&1 | tail -8; echo "tw exit $?"
find .avra-cache -delete 2>/dev/null
build/avra check packages/cli > build/cold.out 2>&1; echo "cold cli exit $?"
F=packages/cli/src/commands/shared.av
cp $F build/shared.orig
python3 - <<'PY'
p="packages/cli/src/commands/shared.av"
t=open(p).read()
open(p,"w").write("// probe\n"+t)
PY
build/avra check packages/cli > build/edit.out 2>&1; echo "comment edit exit $?"; tail -c 300 build/edit.out
cp build/shared.orig $F
cp build/avra.builder build/avra

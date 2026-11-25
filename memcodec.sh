#!/bin/sh
F=packages/std-avrac/src/features/facts.av
cp $F build/facts.orig
echo "== A branch as is"; python3 ru.py build/a.out build/a.err build/avra check packages/std-avrac; tail -c 200 build/a.out
python3 - <<'PY'
p="packages/std-avrac/src/features/facts.av"
t=open(p).read()
t=t.replace("@codec\nexport type TypeFacts","export type TypeFacts",1)
open(p,"w").write(t)
PY
echo "== B without @codec on TypeFacts"; python3 ru.py build/b.out build/b.err build/avra check packages/std-avrac; grep -ac "^error" build/b.out
cp build/facts.orig $F

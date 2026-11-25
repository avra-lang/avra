#!/bin/sh
F=packages/std-avrac/src/features/facts.av
cp $F build/facts.orig
python3 - <<'PY'
p="packages/std-avrac/src/features/facts.av"
t=open(p).read()
t=t.replace("export type TypeFacts = {","@codec\nexport type TypeFacts = {",1)
t=t.replace("    voices: Voices,\n}","    @local voices: Voices = no_voices(),\n}",1)
t=t.replace("use @std.meta.{derive}","use @std.meta.{derive}\nuse @std.relation.{codec}",1)
open(p,"w").write(t)
PY
python3 ru.py build/x.out build/x.err build/avra expand --time packages/std-avrac/src/features/facts.av
wc -c build/x.out
grep -c "static fn write_" build/x.out; grep -c "static fn read_" build/x.out; grep -c "static fn hash_" build/x.out
grep -o "static fn write_[a-z0-9_]*" build/x.out | head -80
cp build/facts.orig $F

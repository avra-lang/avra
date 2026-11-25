#!/bin/sh
make -s try || { echo "try failed"; exit 1; }
find .avra-cache -delete 2>/dev/null
build/avra-try check --time packages/std-relation > build/c1.out 2>&1; echo "cold exit $?"
F=packages/std-relation/src/relation.av
cp $F build/rel.orig
python3 - <<'PY'
p="packages/std-relation/src/relation.av"
t=open(p).read()
open(p,"w").write("// probe\n"+t)
PY
AVRA_QTRACE=1 build/avra-try check --time packages/std-relation > build/c2.out 2> build/c2.q; echo "comment edit exit $?"
grep -a "^time" build/c2.out | cut -c1-500
grep -a "ask Consumed\|Q.ask.Consumed" build/c2.q | cut -f4,5 | sort | uniq -c | head
tail -c 300 build/c2.out
cp build/rel.orig $F

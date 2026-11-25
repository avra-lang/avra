#!/bin/sh
# One cold check of the cli with the kernel graph on, then the graph's M1 table.
F=packages/std-avrac/src/compiler/families/families.av
rm -rf .avra-cache
AVRA_QTRACE=1 AVRA_DB_GRAPH=1 build/avra check packages/cli > graph.out 2> graph.txt; echo "check rc=$?"
echo "graph lines: $(wc -l < graph.txt)"
python3 tools/db_measure/graph.py --m1 graph.txt $F > m1.table 2>&1; echo "m1 rc=$?"
tail -30 m1.table

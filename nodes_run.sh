find /tmp/nodes-corpus2 -delete 2>/dev/null
find build/w-base build/w-head -delete 2>/dev/null
sh nodes_witness.sh build/avra.base build/w-base
sh nodes_witness.sh build/avra build/w-head
echo "IRDIFF $(diff -rq build/w-base/ir build/w-head/ir | wc -l) of $(ls build/w-head/ir | wc -l)"
diff -rq build/w-base/ir build/w-head/ir | head -20
echo "nonzero-exit base: $(grep -l '^exit [1-9]' build/w-base/ir/* | wc -l) head: $(grep -l '^exit [1-9]' build/w-head/ir/* | wc -l)"
cmp build/w-base/diagnostics.txt build/w-head/diagnostics.txt && echo DIAG-SAME
diff build/w-base/diagnostics.txt build/w-head/diagnostics.txt | head -60
tail -2 build/w-base/diagnostics.err build/w-head/diagnostics.err

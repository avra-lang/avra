cd /home/sprite/avra-build/avra-whole-names/tree
say() { grep -a "^warning\[compiler" | grep -a "climbing_import\|relation_reach\|by_id_writer\|fp_tag_repeated\|restamp_tag_repeated\|restamp_method_tag_repeated\|fp_run_spliced" | cut -c1-210; }
echo "== clean std-avrac";  build/avra check packages/std-avrac 2>&1 | say | head -5
echo "== clean std-relation"; build/avra check packages/std-relation 2>&1 | say | head -3
echo "== clean std-http"; build/avra check packages/std-http 2>&1 | say | head -3
echo "== MUT core imports compiler"
f=packages/std-avrac/src/core/arena.av; cp $f /tmp/m1.bak; printf '\nuse compiler.{avra}\n' >> $f
build/avra check packages/std-avrac 2>&1 | say | head -3; cp /tmp/m1.bak $f
echo "== MUT relation names avrac"
f=packages/std-relation/src/db.av; cp $f /tmp/m2.bak; printf '\nuse @std.avrac.core.{DeclId}\n' >> $f
build/avra check packages/std-relation 2>&1 | say | head -3; cp /tmp/m2.bak $f
echo "== MUT engine names io"
f=packages/std-relation/src/engine/table.av; cp $f /tmp/m3.bak; printf '\nuse @std.io.{env}\n' >> $f
build/avra check packages/std-relation 2>&1 | say | head -3; cp /tmp/m3.bak $f
echo "== MUT by-id verb"
f=packages/std-http/src/route.av; cp $f /tmp/m4.bak; printf '\nfn stray_by_id(db: int) -> int { db.put_owned(1) }\n' >> $f
build/avra check packages/std-http 2>&1 | say | head -3; cp /tmp/m4.bak $f
echo "== MUT repeated tag + splice"
f=packages/std-avrac/src/core/side_table.av; cp $f /tmp/m5.bak; printf '\nfn dup_probe() -> int { fp(1, [3]) }\nfn splice_probe(a: List<int>, b: List<int>) -> int { fp(7777, a.concat(b)) }\n' >> $f
build/avra check packages/std-avrac 2>&1 | say | head -5; cp /tmp/m5.bak $f

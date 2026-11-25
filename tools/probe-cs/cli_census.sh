# check packages/cli census, main vs branch, both over main's source. $1 = main compiler hash.
set -u
T=$PWD
rm -rf /tmp/mt && mkdir -p /tmp/mt/build
cp -r Makefile avra avra.toml runtime backend bootstrap packages tools corpus /tmp/mt/ 2>/dev/null
( cd /tmp/mt && patch -s -R -p1 < $T/tools/probe-cs/fix.patch && grep -c held_below packages/std-avrac/src/compiler/memory/memory.av )
cp /home/sprite/avra-compilers/$1/avra /tmp/mt/build/avra
for d in /tmp/mt $T; do sed 's/_note_retain/note_retain/' $T/tools/census.sh > $d/tools/census_linux.sh; done
( cd /tmp/mt && make -o avra libs >/dev/null 2>&1; ls build/*.o | wc -l )
echo "== BEFORE (main compiler, main source)"
( cd /tmp/mt && sh tools/census_linux.sh check /tmp/mt/packages/cli > /tmp/before.out 2>&1; grep -E "^(rc|alloc|once|census)" /tmp/before.out; tail -5 /tmp/before.out; tail -15 build/census-build.out )
[ "${2:-}" = before ] && exit 0
echo "== AFTER (branch compiler, main source as input)"
sh tools/census_linux.sh check /tmp/mt/packages/cli > /tmp/after.out 2>&1; grep -E "^(rc|alloc|once|census)" /tmp/after.out; tail -5 /tmp/after.out
rm -f tools/census_linux.sh

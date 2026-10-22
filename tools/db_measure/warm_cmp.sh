# a cold build of a package against the same build after the one-edit check has filled the store:
# cmp, and how far the two binaries differ. The package's binary is its src/main (the make avra recipe's cp).
cd "$(dirname "$0")/../.."
P=${1:-packages/cli}
B=$P/src/main
clear_store() {
  i=0
  find . -name .avra-cache -type d -prune | while read -r d; do
    i=$((i + 1)); mv "$d" "build/aside.$1.$$.$i"
  done
}
clear_store cold
./avra build $P > build/warm.cold.out 2>&1; echo "cold build exit $?"
cp $B build/w.cold
sh tools/db_measure/warm_edit.sh 1 > build/warm.edit.out 2>&1; echo "warm_edit exit $?"
./avra build $P > build/warm.build.out 2>&1; echo "warm build exit $?"
cp $B build/w.warm
echo "sizes: cold $(wc -c < build/w.cold) warm $(wc -c < build/w.warm)"
if cmp -s build/w.cold build/w.warm; then echo "cold vs warm: SAME"; else echo "cold vs warm: DIFFER"; echo "differing bytes: $(cmp -l build/w.cold build/w.warm | wc -l)"; fi
git status --short | head -n 5

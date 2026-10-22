# The warm edit loop on main: make try (a leaf and a core edit), then one-edit check and build of packages/cli, 3 runs each.
cd "$(dirname "$0")/../.."
LEAF=packages/cli/src/commands/shared.av
CORE=packages/std-avrac/src/core/side_table.av
mkdir -p build/loop
cp $LEAF build/loop/leaf.orig
cp $CORE build/loop/core.orig
edit() { # edit <file> <orig-copy> <anchor> <stamp>: the original with the stamp inserted after the anchor
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
dest, orig, anchor, stamp = sys.argv[1:5]
text = open(orig, encoding="utf-8").read()
assert text.count(anchor) == 1, anchor
open(dest, "w", encoding="utf-8").write(text.replace(anchor, anchor + " " + stamp, 1))
PY
}
# a cold build and check first, so the one-edit runs are warm
./avra build packages/cli > build/loop/cold.out 2>&1; echo "cold build exit $?"
./avra check packages/cli > build/loop/coldcheck.out 2>&1; echo "cold check exit $?"
for i in 1 2 3; do
  s=$(date +%s%N)
  edit $LEAF build/loop/leaf.orig "· memo" "t$i$(date +%s%N)"
  ./avra check --time packages/cli > build/loop/c$i.out 2> build/loop/c$i.err; st=$?
  e=$(date +%s%N)
  echo "check run $i exit $st ms $(( (e - s) / 1000000 )) $(grep -h -o 'held [0-9]*/[0-9]*' build/loop/c$i.err build/loop/c$i.out | head -n 1)"
  s=$(date +%s%N)
  ./avra build --time packages/cli > build/loop/b$i.out 2> build/loop/b$i.err; st=$?
  e=$(date +%s%N)
  echo "build run $i exit $st ms $(( (e - s) / 1000000 )) $(grep -h -o 'held [0-9]*/[0-9]*' build/loop/b$i.err build/loop/b$i.out | head -n 1)"
done
cp build/loop/leaf.orig $LEAF
for i in 1 2 3; do
  edit $LEAF build/loop/leaf.orig "· memo" "m$i$(date +%s%N)"
  s=$(date +%s%N); make try > build/loop/try_leaf$i.out 2>&1; st=$?; e=$(date +%s%N)
  echo "make try leaf run $i exit $st ms $(( (e - s) / 1000000 ))"
  cp build/loop/leaf.orig $LEAF
  edit $CORE build/loop/core.orig "holds [" "k$i$(date +%s%N)"
  s=$(date +%s%N); make try > build/loop/try_core$i.out 2>&1; st=$?; e=$(date +%s%N)
  echo "make try core run $i exit $st ms $(( (e - s) / 1000000 ))"
  cp build/loop/core.orig $CORE
done
cmp -s build/loop/leaf.orig $LEAF && cmp -s build/loop/core.orig $CORE && echo "restored both"

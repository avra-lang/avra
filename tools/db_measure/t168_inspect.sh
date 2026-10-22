# inspect the t168 memory log left on the sprite
cd "$(dirname "$0")/../.." || exit 1
echo "== all mem: lines, numbered =="
grep -n '^mem:' build/t168mem.log
echo "== first 6 lines =="
head -6 build/t168mem.log

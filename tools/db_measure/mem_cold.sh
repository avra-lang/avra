# Cold `check` of packages/cli with the runtime's live-memory accounting: peak and live categories.
cd "$(dirname "$0")/../.."
S=build/mem167
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.mem167.$$.$i"
done
AVRA_MEM_STATS=1 ./avra check packages/cli > $S/out.txt 2> $S/err.txt; echo "cold check exit $?"
grep -h "^mem:" $S/err.txt | head -n 40

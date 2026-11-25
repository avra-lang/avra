# Calls to side_grow for the DeclAt columns on a cold cli check: count, cells, histogram, caller.
cd "$(dirname "$0")/../.."
S=build/grow
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.grow.$$.$i"
done
AVRA_QTRACE=1 ./avra check packages/cli 2> $S/trace.txt > /dev/null; echo "cold check exit $?"
G=$S/trace.txt
echo "calls by caller:"; awk -F'\t' '$1=="Q" && $2=="grow" {print $3}' $G | sort | uniq -c
echo "calls: $(grep -c -P '^Q\tgrow\t' $G)  cells (sum of sizes): $(awk -F'\t' '$1=="Q" && $2=="grow" {s+=$5} END{print s+0}' $G)"
echo "distinct files: $(awk -F'\t' '$1=="Q" && $2=="grow" {print $4}' $G | sort -u | wc -l)"
echo "size histogram (bucket: calls):"; awk -F'\t' '$1=="Q" && $2=="grow" {n=$5; b=1; while (b*2<=n) b*=2; print b}' $G | sort -n | uniq -c
echo "largest sizes:"; awk -F'\t' '$1=="Q" && $2=="grow" {print $5, $3, $4}' $G | sort -rn | head -n 5

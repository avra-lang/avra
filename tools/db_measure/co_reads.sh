# cold check, then a build under AVRA_QTRACE: per-file read reasons of the build; binary diff size.
cd "$(dirname "$0")/../.."
S=build/cor
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.cor.$$.$i"
done
./avra check packages/cli > $S/check.out 2>&1; echo "check exit $?"
AVRA_QTRACE=1 ./avra build --time packages/cli > $S/build.out 2> $S/build.err; echo "build exit $?"
echo "reads by reason:"; awk -F'\t' '$1=="Q" && $2=="reads" {print $3}' $S/build.err | sort | uniq -c | sort -rn
echo "attempts:"; grep -P '^Q\tattempt' $S/build.err | head -n 6
echo "binary diff bytes: $(cmp -l build/co/ref.bin packages/cli/src/main 2>/dev/null | wc -l)"
readelf -n packages/cli/src/main 2>/dev/null | grep -i "build id"; readelf -n build/co/ref.bin 2>/dev/null | grep -i "build id"

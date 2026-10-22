# Cold check then build under AVRA_QTRACE: the per-file key and seen digest the check and the build each compute.
cd "$(dirname "$0")/../.."
S=build/seen
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.seen.$$.$i"
done
AVRA_QTRACE=1 ./avra check packages/cli > /dev/null 2> $S/check.err; echo "check exit $?"
AVRA_QTRACE=1 ./avra build packages/cli > /dev/null 2> $S/build.err; echo "build exit $?"
awk -F'\t' '$1=="Q" && $2=="okey"' $S/check.err | sort -u -t"$(printf '\t')" -k3,3 > $S/check.keys
awk -F'\t' '$1=="Q" && $2=="okey"' $S/build.err | sort -u -t"$(printf '\t')" -k3,3 > $S/build.keys
echo "check keyed files: $(wc -l < $S/check.keys)  build keyed files: $(wc -l < $S/build.keys)"
echo "same key: $(join -t"$(printf '\t')" -j1 <(awk -F'\t' '{print $3"\t"$5}' $S/check.keys | sort) <(awk -F'\t' '{print $3"\t"$5}' $S/build.keys | sort) | awk -F'\t' '$2==$3' | wc -l)"
echo "seen differs: $(join -t"$(printf '\t')" -j1 <(awk -F'\t' '{print $3"\t"$4}' $S/check.keys | sort) <(awk -F'\t' '{print $3"\t"$4}' $S/build.keys | sort) | awk -F'\t' '$2!=$3' | wc -l)"
echo "key differs: $(join -t"$(printf '\t')" -j1 <(awk -F'\t' '{print $3"\t"$5}' $S/check.keys | sort) <(awk -F'\t' '{print $3"\t"$5}' $S/build.keys | sort) | awk -F'\t' '$2!=$3' | wc -l)"

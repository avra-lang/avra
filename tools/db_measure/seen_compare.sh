# Compares the check's and the build's per-file keys, path by path. Fields: Q, okey, path, seen, key.
cd "$(dirname "$0")/../.."
S=build/seen
awk -F'\t' 'FNR==NR {seen[$3]=$4; key[$3]=$5; next} ($3 in seen) { n++; if (seen[$3]==$4) s++; if (key[$3]==$5) k++ } END { print "build files:", FNR, "matched by path:", n, "same seen:", s, "same key:", k }' $S/check.keys $S/build.keys

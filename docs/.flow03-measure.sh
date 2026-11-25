#!/bin/sh
# Temporary: the cancel-reach fact's cost by census, on identical input —
# SIDE=after is this tree; SIDE=before is this tree with the branch's
# packages diff reversed (main's source at the merge base).
set -u
here=$(pwd)
dir=$here
if [ "${SIDE:-after}" = before ]; then
    dir=/tmp/flow03-before
    rm -rf "$dir"; mkdir -p "$dir"
    tar cf - --exclude=./.avra-cache --exclude=./build/flow-bench . | tar xf - -C "$dir"
    (cd "$dir" && patch -s -p1 -R < docs/.flow03-change.patch) || { echo "the reverse patch does not apply"; exit 1; }
fi
echo "== side ${SIDE:-after}: cancel_reach.av present: $(ls "$dir/packages/std-avrac/src/compiler/cancel_reach.av" 2>/dev/null | wc -l)"
for w in ${WORK:-packages/std-http packages/cli}; do
    t0=$(date +%s)
    (cd "$dir" && sh tools/census.sh check "$w" > "$here/build/census-${SIDE:-after}-$(basename "$w").out" 2>&1)
    echo "== census ${SIDE:-after}: check $w ($(( $(date +%s) - t0 )) s with the census build)"
    grep -E '^(rc|once|alloc):' "$here/build/census-${SIDE:-after}-$(basename "$w").out" | head -8
    grep -iE 'cancel' "$here/build/census-${SIDE:-after}-$(basename "$w").out" | head -12
done

set -u
export COST_SNAPSHOT=1d9bdb8b025ff40bb210812db2c8877a5e57f386
root=$(pwd)
rows() { (cd "$1" && sh ./wisp cost rows build/cost 2> /dev/null) | grep -vE '^(#|snapshot)' | sort; }
measured() { # <name> <tree>
    : > "$root/build/$1.rows"
    for part in warm cold-b; do
        (cd "$2" && COST_PART=$part sh tools/cost.sh judge) > "$root/build/$1-$part.log" 2>&1
        echo "MEASURED $1 $part status $?"
        tail -4 "$root/build/$1-$part.log" | sed "s/^/  $1 $part| /"
        rows "$2" >> "$root/build/$1.rows"
        echo "ROWS $1 after $part: $(wc -l < "$root/build/$1.rows")"
    done
    sort -o "$root/build/$1.rows" "$root/build/$1.rows"
}
# THE LAW TAKEN OUT, in a tree of its own: its entry answers nothing, so the walk never runs; that
# tree's compiler built twice from its own source, so its census builder is its own.
nolaw=$(mktemp -d "${TMPDIR:-/tmp}/avra-nolaw.XXXXXX")
git worktree add -q --detach "$nolaw" HEAD
sed -i 's/^fn queries_reading_world(view: ItemView) -> List<Found> {$/&\n    if true { return [] }/' "$nolaw/packages/std-avrac/src/compiler/item_query_door.av"
echo "PATCHED $(grep -c 'if true { return \[\] }' "$nolaw/packages/std-avrac/src/compiler/item_query_door.av")"
mkdir -p "$nolaw/build" && cp -p build/avra build/.avra-built-from build/*.o build/*.a "$nolaw/build/" 2> /dev/null
cp -rp build/wisp "$nolaw/build/" 2> /dev/null
for gen in 1 2; do
    (cd "$nolaw" && make avra > "$root/build/nolaw-make-$gen.log" 2>&1) || { echo "NOLAW make avra $gen failed"; tail -20 "$root/build/nolaw-make-$gen.log"; exit 1; }
done
echo "NOLAW built: $(cat "$nolaw/build/.avra-built-from")"
measured nolaw "$nolaw"
measured law "$root"
[ -s build/law.rows ] && [ -s build/nolaw.rows ] || { echo "a side measured no rows: law $(wc -l < build/law.rows), no law $(wc -l < build/nolaw.rows) — nothing accepted"; exit 1; }
echo "=== LAW vs NOLAW (the same snapshot; law minus no law)"
join -j1 <(awk '{print $1"/"$2, $3}' build/law.rows) <(awk '{print $1"/"$2, $3}' build/nolaw.rows) | awk '$2 != $3 { d = $2 - $3; printf "%s %+d (%.2f%%)\n", $1, d, ($3 ? 100 * d / $3 : 0) }' | tee build/law.delta
echo "ROWS joined: $(join -j1 <(awk '{print $1"/"$2}' build/law.rows) <(awk '{print $1"/"$2}' build/nolaw.rows) | wc -l)"
said=$(awk '$1 ~ /^(check-cli|check-program|cold-with-store-fill)\/(list_reads|retains|boxes|string_compares)$/ {printf "%s%s %s %s", s, $1, $2, $3; s="; "}' build/law.delta)
echo "=== CAUSE law part: ${said:-none}"
make cost-accept CAUSE="the snapshot moves to 1d9bdb8b (tagged), whose link reads the world only through its door, under the pinned hash seed; the query-door law is a correctness law, and its own price on that snapshot, law minus no law, is: ${said:-no counted row moved}; every other move is the snapshot's"
st=$?
echo "ACCEPT status $st"
git status --short -- cost/
echo "=== COST DIFF BEGIN"
git diff -- cost/
echo "=== COST DIFF END"
exit $st

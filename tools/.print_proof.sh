export AVRA_HASH_SEED=1
set -u
run() { # <name> [compiler]
    if [ -n "${2:-}" ]; then COST_COMPILER=$2 COST_PART=cold-b sh tools/cost.sh > build/$1.log 2>&1; else COST_PART=cold-b sh tools/cost.sh > build/$1.log 2>&1; fi
    echo "RUN $1 status $?"
    find build/cost-$1 -delete 2> /dev/null; cp -r build/cost build/cost-$1
    sh ./wisp cost rows build/cost-$1 2> /dev/null | grep -vE '^(#|snapshot)' | sort > build/$1.rows
}
run a
cp build/avra.census build/avra.census-a && cp build/.avra.census-built-from build/.avra.census-a-built-from
run a2 build/avra.census-a
cp build/avra.census build/avra.census-b && printf 'x' >> build/avra.census-b && cp build/.avra.census-built-from build/.avra.census-b-built-from
echo "B differs from A: $(cmp build/avra.census-a build/avra.census-b 2>&1 | head -1)"
run b build/avra.census-b
echo "== A vs A again"; diff build/a.rows build/a2.rows | grep '^[<>]' | head -20
echo "== A vs B"; diff build/a.rows build/b.rows | grep '^[<>]' | head -40
for s in build/cost-a/*.sites; do n=$(basename $s); [ -f build/cost-b/$n ] || continue
    sort $s > build/sa; sort build/cost-b/$n > build/sb; sort build/cost-a2/$n > build/sa2
    echo "== sites $n A vs B"; diff build/sa build/sb | grep '^[<>]' | head -40
    echo "== sites $n A vs A again"; diff build/sa build/sa2 | grep '^[<>]' | head -20
done
ls build/cost-a | head -30
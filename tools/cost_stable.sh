#!/bin/sh
# THE WARM ROWS HOLD ACROSS A COMPILER THAT DIFFERS IN NOTHING THEY READ: two census compilers of this
# tree, the second with one help string of the compiler changed — another binary, another code hash,
# every question it asks hashed anew — each run over the warm part of tools/cost.sh, and
# `wisp cost same` holds every edit's answers worked out again equal in both, and the work
# its census counted within a tenth of the gate's tolerance. A row that moves past that is ordered by
# hash, not by work: no row the gate may hold to yet.
#   sh tools/cost_stable.sh        (CENSUS_BUILDER as tools/census_compiler.sh takes it)
set -eu
cd "$(dirname "$0")/.."
help=packages/std-avrac/src/features/consts/check.av
said='help: "use a scalar, text, octets'
grep -q "$said" "$help" || { echo "cost_stable: $help no longer says $said — name another help string"; exit 1; }
out=build/cost-stable
[ ! -e "$out" ] || find "$out" -delete
mkdir -p "$out"
sh tools/census_compiler.sh "$out/avra.a"
cp "$help" "$out/help.orig"
restore() { cp "$out/help.orig" "$help"; }
trap restore EXIT INT TERM
sed "s|$said|$said (every one)|" "$out/help.orig" > "$help"
sh tools/census_compiler.sh "$out/avra.b"
restore
trap - EXIT INT TERM
! cmp -s "$out/avra.a" "$out/avra.b" || { echo "cost_stable: the two compilers are one binary — the help string moved nothing"; exit 1; }
for c in a b; do
    COST_PART=warm COST_COMPILER="$out/avra.$c" sh tools/cost.sh > "$out/$c.log" 2>&1 || { tail -5 "$out/$c.log"; echo "cost_stable: the warm run of compiler $c failed"; exit 1; }
    mkdir -p "$out/$c"
    find build/cost -maxdepth 1 \( -name 'edit-*.out' -o -name 'edit-*.census' \) -exec cp {} "$out/$c/" \;
done
./wisp cost same "$out/a" "$out/b"

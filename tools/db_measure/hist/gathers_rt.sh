#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
A=$(pwd)/build/avra
# the exit-1 of a warm one-edit check: what it says
f=packages/cli/src/commands/explain.av; cp $f $HOME/rt.orig
$A check packages/cli > /dev/null 2>&1; echo "x0 status=$?"
printf '// edit 1\n' >> $f; $A check packages/cli > $HOME/x1.log 2>&1; echo "x1 status=$?"
printf '// edit 2\n' >> $f; $A check packages/cli > $HOME/x2.log 2>&1; echo "x2 status=$?"; grep -av '^watch:' $HOME/x2.log | tail -n 12 | cut -c1-220
cp $HOME/rt.orig $f
# red-team: a dependency's package collect, a member removed under the held collect
r=$HOME/grt.$$; d=$r/app; g=$r/gk; mkdir -p $d/src/m $g/src/m
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $g/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $g/src/lib.av
printf 'use lib.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\n' > $g/src/m/m.av
printf '[package]\nname = "rt-gra"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $d/avra.toml
printf 'use @rt.gk.lib.{a_at}\nuse rk.{r_at}\nprintln("a=${a_at()} r=${r_at()}")\n' > $d/src/main.av
# the root package's own collect, its member in a file nothing imports
printf 'use @std.meta.{Named}\nexport fn rank(_t: Named, _r: int) {}\nexport collect enum Rk = @rank in package by it.mark.args[0]\nexport fn r_at() -> int { Rk.P.ordinal }\n' > $d/src/rk.av
printf 'use rk.{rank}\n@rank(5)\nexport type P = {}\n' > $d/src/m/m.av
b() { (cd $d && "$A" build --time . > $r/o.log 2>&1; st=$?; echo "$1 status=$st prints=$(./src/main 2>&1 | head -n 1) $(grep -o 'held [0-9]*/[0-9]*' $r/o.log | tail -n 1) $(grep -a '^error\|^avra:' $r/o.log | head -n 2 | tr '\n' ' ')"); }
v() { (cd $d && "$A" check . > /dev/null 2>&1; "$A" check --verify-held . > $r/v.log 2>&1; echo "$1 verify-held status=$? $(grep -aE 'held=|verify-held:|^avra:' $r/v.log | head -3 | tr '\n' ' ' | cut -c1-250)"); }
b "1 cold (want a=1 r=0)"
printf 'use lib.{kind}\n@kind(5)\nexport type A = {}\n' > $g/src/m/m.av
b "2 dependency member B removed, lib.av held (want a=0 r=0)"
printf 'use rk.{rank}\n@rank(5)\nexport type P = {}\n@rank(1)\nexport type Q = {}\n' > $d/src/m/m.av
b "3 root member Q added, rk.av held (want a=0 r=1)"
printf 'use rk.{rank}\n@rank(5)\nexport type P = {}\n' > $d/src/m/m.av
b "4 root member Q removed (want a=0 r=0)"
printf '// moved\n' >> $d/src/main.av
v "5 main edited"

#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
A=$(pwd)/build/avra; r=$HOME/kg.$$; d=$r/app; g=$r/gk; mkdir -p $d/src $g/src/m
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $g/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $g/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $g/src/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $g/src/m/m.av
printf '[package]\nname = "rt-kga"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $d/avra.toml
printf 'use @rt.gk.lib.{a_at}\nprintln("a=${a_at()}")\n' > $d/src/main.av
b() { (cd $d && "$A" build --time . > $r/o.log 2>&1; st=$?; echo "$1 status=$st prints=$(./src/main 2>&1 | head -n 1) $(grep -o 'held [0-9]*/[0-9]*' $r/o.log | tail -n 1) $(grep -a '^error\|^avra:' $r/o.log | head -n 2 | tr '\n' ' ')"); }
v() { (cd $d && "$A" check --verify-held . > $r/v.log 2>&1; echo "$1 verify-held status=$? $(grep -aE 'held=|verify-held:|^avra:' $r/v.log | head -4 | tr '\n' ' ' | cut -c1-300)"); }
b "1 cold (want a=0)"
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\n' > $g/src/m/m.av
b "2 member added in the dependency, lib.av held (want a=1)"
echo "2 what was read and why:"; sed -n '/^read:/,$p' $r/o.log | head -n 12 | cut -c1-200
(cd $d && "$A" check --time . > $r/c.log 2>&1; echo "2b check after the build: $(grep -o 'held [0-9]*/[0-9]*' $r/c.log | tail -n 1)")
printf '// moved\n' >> $d/src/main.av
(cd $d && "$A" check . > /dev/null 2>&1)
v "3 main edited"

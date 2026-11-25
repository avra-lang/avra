#!/bin/sh
# Why the collector is read at the member-file-added step: what moved in its key.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
A=$(pwd)/build/avra; r=$HOME/gw.$$; d=$r/app; g=$r/gk; mkdir -p $d/src $g/src/m $g/src/c
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $g/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $g/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $g/src/c/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $g/src/m/m.av
printf '[package]\nname = "rt-gw"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $d/avra.toml
printf 'use @rt.gk.c.{a_at}\nprintln("a=${a_at()}")\n' > $d/src/main.av
b() { (cd $d && "$A" build --time . > $r/o.log 2>&1; echo "$1: $(./src/main) $(grep -ao 'held [0-9]*/[0-9]*' $r/o.log | tail -n 1)"; sed -n '/^read:/,$p' $r/o.log | head -n 8 | cut -c1-200); }
st() { b "$1"; (cd $d && "$A" run . > /dev/null 2>&1; "$A" check --verify-held . > $r/v.log 2>&1; echo "   verify-held $?"); }
st "cold"
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\n' > $g/src/m/m.av; st "B added"
printf 'use k.{kind}\n// B removed\n@kind(5)\nexport type A = {}\n' > $g/src/m/m.av; st "B removed"
mkdir -p $g/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $g/src/n/n.av
st "member file added"

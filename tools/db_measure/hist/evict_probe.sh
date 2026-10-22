#!/bin/sh
# Which step leaves the next build with nothing kept: a run, a check, or a --verify-held.
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
A=$(pwd)/build/avra; r=$HOME/ev.$$; d=$r/app; g=$r/gk; mkdir -p $d/src $g/src/m
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $g/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $g/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $g/src/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $g/src/m/m.av
printf '[package]\nname = "rt-ev"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $d/avra.toml
printf 'use @rt.gk.lib.{a_at}\nprintln("a=${a_at()}")\n' > $d/src/main.av
b() { printf "// %s\n" "$1" >> $d/src/main.av; (cd $d && "$A" build --time . > $r/o.log 2>&1; echo "$1: build $(grep -ao 'held [0-9]*/[0-9]*' $r/o.log | tail -n 1) $(sed -n '/^read:/,$p' $r/o.log | grep -c '^  ') read-listed")
}
b "cold"
b "build again (baseline)"
(cd $d && "$A" run . > /dev/null 2>&1); b "after a run"
b "build again"
(cd $d && "$A" check . > /dev/null 2>&1); b "after a check"
b "build again"
(cd $d && "$A" check --verify-held . > /dev/null 2>&1); b "after --verify-held"
b "build again"

#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
r=$HOME/rk.$$; mkdir -p $r/gk/src/c $r/gk/src/p $r/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $r/gk/avra.toml
printf 'use @std.meta.{Code}\nexport component pick {\n    run: fn(Code) -> int?\n}\n' > $r/gk/src/k.av
printf 'use k.{pick}\ntype Entry = { name: string, root: List<int> }\ncollect xs: List<Entry> = pick in package as Entry { name: it.name, root: it.root_kind } by it.name\nexport fn shown() -> string { "${xs.length} ${xs[0].root[0]}" }\n' > $r/gk/src/c/lib.av
printf 'use k.{pick}\nexport pick one {\n    quote { a + b } -> 1,\n}\n' > $r/gk/src/p/p.av
printf '[package]\nname = "rt-rk"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $r/app/avra.toml
printf 'use @rt.gk.c.{shown}\nprintln(shown())\n' > $r/app/src/main.av
A=$(pwd)/build/avra
(cd $r/app && "$A" build . > $r/o.log 2>&1; echo "cold status=$? prints=$(./src/main 2>&1)"; grep -aE "^error|^avra:" -A4 $r/o.log | head -12 | cut -c1-200)
printf 'use k.{pick}\nexport pick one {\n    quote { f(a) } -> 1,\n}\n' > $r/gk/src/p/p.av
(cd $r/app && "$A" build . > $r/o.log 2>&1; echo "warm status=$? prints=$(./src/main 2>&1)")
rm -rf $r/app/.avra-cache; (cd $r/app && "$A" build . > /dev/null 2>&1; echo "fresh prints=$(./src/main 2>&1)")

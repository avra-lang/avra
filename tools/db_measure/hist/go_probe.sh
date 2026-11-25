#!/bin/sh
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
go=$HOME/go.$$; mkdir -p $go/gk/src/c $go/gk/src/p $go/gk/src/q $go/app/src
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $go/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn seq(_t: Named, _rank: int) {}\n' > $go/gk/src/k.av
printf 'use k.{seq}\ntype Entry = { name: string }\ncollect xs: List<Entry> = @seq in package as Entry { name: it.name } by it.mark.args[0]\nexport fn x_at() -> int { [e.name for e in xs].index_of("X") }\n' > $go/gk/src/c/lib.av
printf 'use k.{seq}\n@seq(0)\nexport type X = {}\n' > $go/gk/src/p/p.av
printf 'use k.{seq}\n@seq(0)\nexport type Y = {}\n' > $go/gk/src/q/q.av
printf '[package]\nname = "rt-go"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n' > $go/app/avra.toml
printf 'use @rt.gk.c.{x_at}\nprintln("x=${x_at()}")\n' > $go/app/src/main.av
./avra build $go/app 2>&1 | grep -av "^watch:" | head -n 12 | cut -c1-200
echo "cold: $($go/app/src/main)"
mkdir -p $go/gk/src/z; mv $go/gk/src/p/p.av $go/gk/src/z/z.av; rmdir $go/gk/src/p
AVRA_QTRACE=1 ./avra build --time $go/app > $go/w.log 2>&1; grep -a "^Q	gathered" $go/w.log | sort -u; echo "warm: $($go/app/src/main)"; grep -a "held\|read:\|^  " $go/w.log | head -8
rm -rf $go/app/.avra-cache; ./avra build $go/app > /dev/null 2>&1; echo "fresh: $($go/app/src/main)"

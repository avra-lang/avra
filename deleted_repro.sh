# usage: sh deleted_repro.sh <compiler>
A=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
R=/tmp/delrepro
mkdir -p $R && find $R -mindepth 1 -delete
mkdir -p $R/lib/src/m $R/app/src
printf '[package]\nname        = "@d/lib"\nversion     = "0.0.1"\ndescription = "x"\n\n[lib]\nname = "d-lib"\npath = "src/lib.av"\n' > $R/lib/avra.toml
printf 'export fn top() -> int { 0 }\n' > $R/lib/src/lib.av
printf 'export fn a() -> int { 1 }\n' > $R/lib/src/m/one.av
printf 'export fn b() -> int { 2 }\n' > $R/lib/src/m/two.av
printf '[package]\nname        = "delapp"\nversion     = "0.0.1"\ndescription = "x"\n\n[bin]\nname = "delapp"\npath = "src/main.av"\n\n[dependencies]\n"@d/lib" = { path = "../lib" }\n' > $R/app/avra.toml
printf 'use @d.lib.m.{a}\nprintln("${a()}")\n' > $R/app/src/main.av
for verb in check build build; do
  $A $verb $R/app > /tmp/del1.out 2>&1; echo "$verb before: $?"; tail -2 /tmp/del1.out
done
mv $R/lib/src/m/two.av /tmp/two.av.aside
for verb in check build; do
  $A $verb $R/app > /tmp/del2.out 2>&1; echo "$verb after delete: $?"; tail -4 /tmp/del2.out
done

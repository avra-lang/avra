# usage: sh moved_repro.sh <compiler>  — a store made at one checkout path, read at another
A=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
R=/tmp/moved
mkdir -p $R && find $R -mindepth 1 -delete
mkdir -p $R/one/lib/src/m $R/one/app/src $R/one/.git
printf '[package]\nname = "@m/lib"\nversion = "0.1.0"\n\n[lib]\nname = "m-lib"\npath = "src/lib.av"\n' > $R/one/lib/avra.toml
printf 'export fn top(x: int) -> int { x ?? 0 }\n' > $R/one/lib/src/lib.av
printf 'export fn k() -> int { 2 }\n' > $R/one/lib/src/m/k.av
printf '[package]\nname = "app"\nversion = "0.1.0"\n\n[dependencies]\n"@m/lib" = { path = "../lib" }\n' > $R/one/app/avra.toml
printf 'use @m.lib.{top}\nuse @m.lib.m.{k}\nprintln("${top(k())}")\n' > $R/one/app/src/main.av
$A check --time $R/one/app > /tmp/m1.out 2>&1; echo "one: $?"; grep -a "^time: \|warning" /tmp/m1.out | head -3
AVRA_QTRACE=1 $A check --time $R/one/app > /tmp/m1b.out 2>/tmp/m1b.trace; echo "one again: $?"; grep -a "^time: " /tmp/m1b.out | head -2
cp -R $R/one $R/two
AVRA_QTRACE=1 $A check --time $R/two/app > /tmp/m2.out 2> /tmp/m2.trace; echo "two: $?"; grep -a "^time: " /tmp/m2.out /tmp/m2.trace | head -3
grep -a "Q.store.*miss" /tmp/m2.trace | cut -f3- | sort | uniq -c | sort -rn | head -20
# an edit after the move: the files it leaves alone are held as they would be in place
cp -R $R/one $R/three
printf 'use @m.lib.{top}\nuse @m.lib.m.{k}\nprintln("${top(k()) + 1}")\n' > $R/one/app/src/main.av
$A check --time $R/one/app > /tmp/m3.out 2>&1; echo "edit in place: $(grep -ao "held [0-9]*/[0-9]*" /tmp/m3.out | tail -1)"
printf 'use @m.lib.{top}\nuse @m.lib.m.{k}\nprintln("${top(k()) + 1}")\n' > $R/three/app/src/main.av
AVRA_QTRACE=1 $A check --time $R/three/app > /tmp/m4.out 2> /tmp/m4.trace; echo "edit moved: $(grep -ao "held [0-9]*/[0-9]*" /tmp/m4.out /tmp/m4.trace | tail -1)"
grep -a "kind" /tmp/m4.trace | grep -a miss | cut -f4- | sort | uniq -c | sort -rn | head -14

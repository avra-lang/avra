#!/bin/sh
# probe: warm-hold parse counts, deleted import target, deleted held file, missing record.
A=build/avra
R=$PWD/build/m3probe
rm -rf "$R" .avra-cache; mkdir -p $R
say() { echo "=== $*"; }
tline() { grep '^time:' | head -1 | grep -oE 'held [0-9]+/[0-9]+|attempt [0-9]+|discarded [0-9]+|refused [0-9]+' | tr '\n' ' '; }

# P1 zero parse
mkdir -p $R/zp/src/m1 $R/zp/src/m2 $R/zp/src/m3
printf '[package]\nname = "rt-zp"\nversion = "0.1.0"\n' > $R/zp/avra.toml
printf 'export fn f1() -> int { 1 }\n' > $R/zp/src/m1/mod.av
printf 'use m1.{f1}\nexport fn f2() -> int { f1() + 1 }\n' > $R/zp/src/m2/mod.av
printf 'use m2.{f2}\nexport fn f3() -> int { f2() + 1 }\n' > $R/zp/src/m3/mod.av
printf 'use m3.{f3}\nprintln("${f3()}")\n' > $R/zp/src/main.av
say P1 cold; $A check --time $R/zp 2>&1 | tline; echo
say P1 warm; AVRA_QTRACE=1 $A check --time $R/zp > $R/p1.out 2> $R/p1.err; echo "exit $?"; cat $R/p1.out | tline; grep '^time:' $R/p1.err | tline; echo
echo "parsed computes (family 1): $(grep -cP '^Q\task\t1\t[0-9]+\tcompute' $R/p1.err)"; echo "plain computes: $(grep -P '^Q\task\t' $R/p1.err | awk -F'\t' '$5=="compute"{print $3}' | sort | uniq -c | sort -rn | head -30)"
grep -A20 '^read:' $R/p1.out $R/p1.err | head -20
ed() { python3 - "$@" <<'PY'
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
ed $R/zp/src/m1/mod.av "{ 1 }" "{ 10 }"
say P1 body edit m1; AVRA_QTRACE=1 $A check --time $R/zp > $R/p1b.out 2> $R/p1b.err; echo "exit $?"; cat $R/p1b.out $R/p1b.err | tline; echo; grep -A8 '^read:' $R/p1b.out $R/p1b.err | head
echo "parsed computes: $(grep -cP '^Q\task\t1\t[0-9]+\tcompute' $R/p1b.err)"

# P2 deleted import target
mkdir -p $R/dt/src/mid $R/dt/src/leaf
printf '[package]\nname = "rt-dt"\nversion = "0.1.0"\n' > $R/dt/avra.toml
printf 'export fn f() -> int { 1 }\n' > $R/dt/src/leaf/mod.av
printf 'use leaf.{f}\nexport fn g() -> int { f() + 1 }\n' > $R/dt/src/mid/mod.av
printf 'use mid.{g}\nprintln("${g()}")\n' > $R/dt/src/main.av
say P2 cold; $A check --time $R/dt 2>&1 | tline; echo
say P2 warm; $A check --time $R/dt 2>&1 | tline; echo
rm -rf $R/dt/src/leaf
say P2 leaf deleted; $A check --time $R/dt > $R/p2.out 2>&1; echo "exit $?"; cat $R/p2.out | grep -v '^watch' | head -20
mv .avra-cache $R/cache.p2; say P2 cold reference; $A check $R/dt 2>&1 | head -8; echo "exit $?"; rm -rf .avra-cache; mv $R/cache.p2 .avra-cache

# P3 deleted held sibling
mkdir -p $R/ds/src/mid
printf '[package]\nname = "rt-ds"\nversion = "0.1.0"\n' > $R/ds/avra.toml
printf 'export fn h() -> int { 2 }\n' > $R/ds/src/mid/b.av
printf 'export fn g() -> int { h() + 1 }\n' > $R/ds/src/mid/a.av
printf 'use mid.{g}\nprintln("${g()}")\n' > $R/ds/src/main.av
say P3 cold; $A check --time $R/ds 2>&1 | tline; echo
say P3 warm; $A check --time $R/ds 2>&1 | tline; echo
rm $R/ds/src/mid/b.av
say P3 b deleted; $A check --time $R/ds > $R/p3.out 2>&1; echo "exit $?"; grep -v '^watch' $R/p3.out | head -20

# P4 missing record
mkdir -p $R/nrl/src $R/nr/src
printf '[package]\nname = "@rt/nrl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-nrl"\npath = "src/lib.av"\n' > $R/nrl/avra.toml
printf 'export fn lf() -> int { 3 }\n' > $R/nrl/src/lib.av
printf '[package]\nname = "rt-nr"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/nrl" = { path = "../nrl" }\n' > $R/nr/avra.toml
printf 'use @rt.nrl.{lf}\nexport fn u() -> int { lf() + 1 }\n' > $R/nr/src/user.av
printf 'use user.{u}\nprintln("${u()}")\n' > $R/nr/src/main.av
say P4 cold; $A check --time $R/nr 2>&1 | tline; echo
say P4 warm; $A check --time $R/nr 2>&1 | tline; echo
echo "Sig rows naming nrl: $(grep -rl "nrl/src/lib.av" .avra-cache/*/Sig 2>/dev/null | wc -l)"
for f in $(grep -rl "nrl/src/lib.av" .avra-cache/*/Sig 2>/dev/null); do echo "-- $f"; head -c 300 $f; echo; done
for f in $(grep -rl "nrl/src/lib.av" .avra-cache/*/Sig 2>/dev/null); do rm -f "$f" "$f.deps"; done
say P4 record deleted; $A check --time $R/nr > $R/p4.out 2>&1; echo "exit $?"; grep -v '^watch' $R/p4.out | head -20

#!/bin/sh
A=build/avra
R=$PWD/build/m3probe2
rm -rf "$R" .avra-cache; mkdir -p $R
say() { echo "=== $*"; }
tl() { grep -E '^time:|^read:|^  ' | grep -v '│' | head -12; }
ed() { python3 - "$@" <<'PY'
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
# P4 missing record
mkdir -p $R/nrl/src $R/nr/src
printf '[package]\nname = "@rt/nrl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-nrl"\npath = "src/lib.av"\n' > $R/nrl/avra.toml
printf 'export fn lf() -> int { 3 }\n' > $R/nrl/src/lib.av
printf '[package]\nname = "rt-nr"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/nrl" = { path = "../nrl" }\n' > $R/nr/avra.toml
printf 'use @rt.nrl.{lf}\nexport fn u() -> int { lf() + 1 }\n' > $R/nr/src/user.av
printf 'use user.{u}\nprintln("${u()}")\n' > $R/nr/src/main.av
say P4 cold; $A check --time $R/nr 2>&1 | tl
printf '// m\n' >> $R/nr/src/main.av
say P4 entry edit; $A check --time $R/nr 2>&1 | tl
find .avra-cache -maxdepth 2 | head
echo "sig rows naming nrl: $(grep -rl "nrl/src/lib.av" .avra-cache/*/sig 2>/dev/null | wc -l)"
for f in $(grep -rl "nrl/src/lib.av" .avra-cache/*/sig 2>/dev/null); do echo "-- $f"; head -c 400 $f; echo; done
for f in $(grep -rl "nrl/src/lib.av" .avra-cache/*/sig 2>/dev/null); do rm -f "$f" "$f.deps"; done
printf '// m2\n' >> $R/nr/src/main.av
say P4 record body deleted; $A check --time $R/nr 2>&1 | tl
say P4 again; printf '// m3\n' >> $R/nr/src/main.av; $A check --time $R/nr 2>&1 | tl

# P2b one reached file of a two-file module deleted
mkdir -p $R/rf/src/x $R/rf/src/mid
printf '[package]\nname = "rt-rf"\nversion = "0.1.0"\n' > $R/rf/avra.toml
printf 'export fn f() -> int { 1 }\n' > $R/rf/src/x/a.av
printf 'export fn g() -> int { 2 }\n' > $R/rf/src/x/b.av
printf 'use x.{f}\nexport fn m() -> int { f() + 1 }\n' > $R/rf/src/mid/mod.av
printf 'use mid.{m}\nuse x.{g}\nprintln("${m()} ${g()}")\n' > $R/rf/src/main.av
say P2b cold; $A check --time $R/rf 2>&1 | tl
printf '// e\n' >> $R/rf/src/main.av
say P2b entry edit; $A check --time $R/rf 2>&1 | tl
rm $R/rf/src/x/a.av
say P2b a.av deleted; $A check --time $R/rf > $R/p2b.out 2>&1; echo "exit $?"; grep -v '│\|╭\|╰\|──' $R/p2b.out | head -12

# P5 callee E edit, explicit
mkdir -p $R/ee/src/errs $R/ee/src/user
printf '[package]\nname = "rt-ee"\nversion = "0.1.0"\n' > $R/ee/avra.toml
cat > $R/ee/src/errs/mod.av <<'AV'
export type Bad = { code: int }
export type Worse = { code: int, why: string }
export type Other = { why: string }
export fn risky(n: int) -> Result<int, Bad> {
    if n < 0 { fail Bad { code: n } }
    n
}
export fn inferred(n: int) -> Result<int, _> {
    if n < 0 { fail Bad { code: n } }
    n
}
AV
cat > $R/ee/src/user/mod.av <<'AV'
use errs.{risky, inferred}
export fn shown(n: int) -> string {
    match risky(n) {
        .Ok(v) -> "ok ${v}",
        .Err(e) -> "err ${e.code}",
    }
}
export fn shown2(n: int) -> string {
    match inferred(n) {
        .Ok(v) -> "ok ${v}",
        .Err(e) -> "err ${e.code}",
    }
}
AV
printf 'use user.{shown, shown2}\nprintln("${shown(1)} ${shown(-2)} ${shown2(-3)}")\n' > $R/ee/src/main.av
say P5 cold build; $A build --time $R/ee 2>&1 | tl; $R/ee/src/main
printf '// e\n' >> $R/ee/src/main.av
say P5 warm build; $A build --time $R/ee 2>&1 | tl; $R/ee/src/main
ed $R/ee/src/errs/mod.av 'export fn risky(n: int) -> Result<int, Bad> {
    if n < 0 { fail Bad { code: n } }' 'export fn risky(n: int) -> Result<int, Worse> {
    if n < 0 { fail Worse { code: n * 10, why: "w" } }'
say P5 explicit E Bad-to-Worse build; $A build --time $R/ee 2>&1 | tl; $R/ee/src/main; $A run $R/ee 2>&1 | tail -1
ed $R/ee/src/errs/mod.av '    if n < 0 { fail Bad { code: n } }
    n
}' '    if n < 0 { fail Worse { code: n * 100, why: "i" } }
    n
}'
say P5 inferred E Bad-to-Worse build; $A build --time $R/ee 2>&1 | tl; $R/ee/src/main; $A run $R/ee 2>&1 | tail -1
ed $R/ee/src/errs/mod.av 'Result<int, Worse> {
    if n < 0 { fail Worse { code: n * 10, why: "w" } }' 'Result<int, Other> {
    if n < 0 { fail Other { why: "o" } }'
say P5 explicit E to Other, check must refuse e.code; $A check --time $R/ee > $R/p5.out 2>&1; echo "exit $?"; grep -v '│\|╭\|╰\|──' $R/p5.out | head -10
mv .avra-cache $R/c5; say P5 cold ref; $A check $R/ee 2>&1 | grep -v '│\|╭\|╰\|──' | head -6; rm -rf .avra-cache; mv $R/c5 .avra-cache

#!/bin/sh
# THE BUILD CACHE, ATTACKED. Two programs and a library share ONE store; every step
# edits a source, builds THROUGH the store, runs the binary, and holds it to the
# evaluator, which reads no cache. A hold that links the wrong body, or none, is a
# disagreement here. The fixtures are written fresh each run: the steps edit them.
set -u
cd "$(dirname "$0")/../.."
# The shim's own lines are no program's output: its `watch:` reports, and the
# warning a shell with no terminal prints when the watchdog asks for job control.
unwatched() { grep -v -e '^watch:' -e 'job control turned off'; }

R=build/cache-attacks; fails=0; steps=0; holds=0
rm -rf "$R" .avra-cache && mkdir -p $R
S() { # S <label> <app>
    steps=$((steps+1))
    out=$(./avra build --time $R/$2 2>$R/$2.err); st=$?; bin=$(printf '%s\n' "$out" | tail -1)
    held=$(grep -oE "held [0-9]+/[0-9]+" $R/$2.err | tail -1)
    case "$held" in "held 0/"*|"") ;; *) holds=$((holds+1)) ;; esac
    if [ ! -x "$bin" ]; then fails=$((fails+1)); echo "FAIL  $1 [$2] did not build (status $st): $(printf '%s\n' "$out" | cat - $R/$2.err | grep -vE '^watch:|^time:' | head -4 | tr '\n' ' ')"; return; fi
    # A REFUSED HOLD IS A FINDING HERE: the build is right and the hold was wrong.
    if grep -q "the hold was refused" $R/$2.err; then fails=$((fails+1)); echo "FAIL  $1 [$2] the hold was refused: $(grep 'the hold was refused' $R/$2.err | head -1 | cut -c1-200)"; return; fi
    nat=$("$bin" 2>&1); ev=$(./avra run $R/$2 2>/dev/null | unwatched)
    if [ "$nat" = "$ev" ]; then [ -n "${VERBOSE:-}" ] && echo "ok    $1 [$2] ($held) -> $nat"; else fails=$((fails+1)); echo "FAIL  $1 [$2] ($held) native='$nat' eval='$ev'"; fi
}
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}
# A COLLECT GATHERS WHAT ITS SCOPE HOLDS NOW, HELD OR NOT. `kg` depends on `@rt/gk`, whose
# c/lib.av collects every `@kind` in its package, in a module of its own; its members stand in files nothing imports, so
# only the collect reaches them, and the mark they wear is declared in a file of its own, so a
# member's compile-time run never reads the collecting file. A member is added, removed, a member file added and deleted —
# each edit touching no file the collect stands in, so lib.av is held — and A's ordinal follows
# every time. The root package's own `in package` collect follows the same edits, and `@rt/kc`'s
# `in closure` list stands with no package collect beside it. After every step a held reading
# answers what a fresh one does (`--verify-held`), and the evaluator agrees with the binary.
mkdir -p $R/gk/src/m $R/gk/src/c $R/kc/src/z $R/kg/src/m
printf '[package]\nname = "@rt/gk"\nversion = "0.1.0"\n' > $R/gk/avra.toml
printf 'use @std.meta.{Named}\nexport fn kind(_t: Named, _rank: int) {}\n' > $R/gk/src/k.av
printf 'use k.{kind}\nexport collect enum Kind = @kind in package by it.mark.args[0]\nexport fn a_at() -> int { Kind.A.ordinal }\n' > $R/gk/src/c/lib.av
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n' > $R/gk/src/m/m.av
printf '[package]\nname = "@rt/kc"\nversion = "0.1.0"\n' > $R/kc/avra.toml
printf 'use @std.meta.{Named}\nexport fn mark(_t: Named) {}\n' > $R/kc/src/mk.av
printf 'use mk.{mark}\ntype Entry = { name: string }\ncollect near: List<Entry> = @mark in closure as Entry { name: it.name } by it.name\nexport fn c_at() -> int { near.length }\n' > $R/kc/src/kc.av
printf 'use mk.{mark}\n@mark\nexport type Z = {}\n' > $R/kc/src/z/z.av
printf '[package]\nname = "rt-kg"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/gk" = { path = "../gk" }\n"@rt/kc" = { path = "../kc" }\n' > $R/kg/avra.toml
printf 'use @std.meta.{Named}\nexport fn rank(_t: Named, _r: int) {}\n' > $R/kg/src/rm.av
printf 'use rm.{rank}\nexport collect enum Rk = @rank in package by it.mark.args[0]\nexport fn r_at() -> int { Rk.P.ordinal }\n' > $R/kg/src/rk.av
printf 'use rm.{rank}\n@rank(5)\nexport type P = {}\n' > $R/kg/src/m/m.av
printf 'use @rt.gk.c.{a_at}\nuse @rt.kc.kc.{c_at}\nuse rk.{r_at}\nprintln("a=${a_at()} r=${r_at()} c=${c_at()}")\n' > $R/kg/src/main.av
kg_step() { # kg_step <label> <wanted a=… r=…>: built, the binary agrees with the evaluator and prints it, a held reading agrees with a fresh one
    S "kg: $1" kg
    steps=$((steps+1)); kg_out=$($R/kg/src/main 2>&1)
    case "$kg_out" in "$2 c="*) ;; *) fails=$((fails+1)); echo "FAIL  kg: $1: the binary printed '$kg_out', wanted '$2 c=…'" ;; esac
    steps=$((steps+1)); kg_v=$(./avra check --verify-held $R/kg 2>&1); kg_st=$?
    [ $kg_st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  kg: $1: --verify-held exit $kg_st: $(printf '%s' "$kg_v" | grep -aE 'held=|verify-held:|^avra:' | head -3 | tr '\n' ' ' | cut -c1-260)"; }
}
kg_step "cold" "a=0 r=0"
printf 'use k.{kind}\n@kind(5)\nexport type A = {}\n@kind(1)\nexport type B = {}\n' > $R/gk/src/m/m.av
kg_step "a member added in the dependency, lib.av held" "a=1 r=0"
printf 'use k.{kind}\n// B removed\n@kind(5)\nexport type A = {}\n' > $R/gk/src/m/m.av
kg_step "the member removed" "a=0 r=0"
# a member file in a module of its own: no key of lib.av reaches it, so what it gathers is
# the first reason lib.av is read
mkdir -p $R/gk/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $R/gk/src/n/n.av
# PROBE: the step the shared store reads lib.av as unkept
echo "== cache held BEFORE the step"; ./avra cache held $R/kg 2>&1 | grep -v "^watch:" | head -20
mkdir -p $R/gk/src/n; printf 'use k.{kind}\n@kind(0)\nexport type C = {}\n' > $R/gk/src/n/n.av
steps=$((steps+1)); out=$(./avra build --time $R/kg 2>$R/kg.err); echo "probe build status $?"
grep -E "held [0-9]+/[0-9]+" $R/kg.err | tail -1
sed -n '/^read:/,$p' $R/kg.err | grep -i "lib.av" | head -3
grep -iE "nothing kept stands in|gathers|moved" $R/kg.err | head -5
echo "steps=$steps fails=$fails"
echo "== cache held AFTER the step"; ./avra cache held $R/kg 2>&1 | grep -v "^watch:" | head -20

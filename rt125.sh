#!/bin/sh
# red-team for avra-8sb5.57.125: impls reached through their type
set -u
cd "$(dirname "$0")"
R=build/rt125; fails=0
rm -rf "$R" .avra-cache && mkdir -p $R/tl/src $R/pl/src $R/app/src
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  edit found nothing: $1 <- $2"; }
import sys
p, a, b = sys.argv[1:4]
t = open(p).read()
if a not in t: sys.exit(1)
open(p, 'w').write(t.replace(a, b, 1))
PY
}
B() { # B <label> [<file> <want>]...
    label=$1; shift
    out=$(./avra build --time $R/app 2>&1)
    run=$($R/app/src/main 2>&1)
    while [ $# -ge 2 ]; do
        case "$out" in *"read:"*"$1"*) got=read ;; *) got=held ;; esac
        if [ "$got" = "$2" ]; then echo "ok    $label: $1 -> $got [$run]"; else fails=$((fails+1)); echo "FAIL  $label: $1 wanted $2, got $got [$run] $(printf '%s' "$out" | grep -A8 '^read:' | tr '\n' ' ')"; fi
        shift 2
    done
}
printf '[package]\nname = "@rt/pl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-pl"\npath = "src/lib.av"\n' > $R/pl/avra.toml
printf 'export fn one() -> int { 1 }\n' > $R/pl/src/lib.av
printf 'export type Pt = { v: int }\n' > $R/pl/src/ty.av
printf 'use ty.{Pt}\nfn k() -> int { 10 }\nimpl Pt { fn twice() -> int { self.v * 2 + k() } }\n' > $R/pl/src/inh.av
printf 'export type Bx<T> = { held: T }\n' > $R/pl/src/bx.av
printf 'use bx.{Bx}\nfn g() -> int { 0 }\nimpl Bx<T> { fn get() -> T { self.held } }\n' > $R/pl/src/bx_impl.av
printf '[package]\nname = "@rt/tl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-tl"\npath = "src/lib.av"\n\n[dependencies]\n"@rt/pl" = { path = "../pl" }\n' > $R/tl/avra.toml
printf 'export fn two() -> int { 2 }\n' > $R/tl/src/lib.av
printf 'export trait Say { fn say() -> int }\n' > $R/tl/src/say.av
printf 'use say.{Say}\nuse @rt.pl.{Pt}\nfn base() -> int { 1 }\nimpl Say for Pt { fn say() -> int { self.v + base() } }\n' > $R/tl/src/imp.av
printf '[package]\nname = "rt-app"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/pl" = { path = "../pl" }\n"@rt/tl" = { path = "../tl" }\n' > $R/app/avra.toml
printf 'use @rt.tl.{Say}\nuse @rt.pl.{Pt}\nexport fn said() -> int {\n    let s: dyn Say = Pt { v: 4 }\n    s.say()\n}\n' > $R/app/src/dyn.av
printf 'use @rt.pl.{Pt}\nexport fn tw() -> int { Pt { v: 3 }.twice() }\n' > $R/app/src/inh.av
printf 'use @rt.pl.{Bx}\nexport fn gb() -> int { Bx { held: 7 }.get() }\n' > $R/app/src/gen.av
printf 'println("app ${said()} ${tw()} ${gb()}")\n' > $R/app/src/main.av
B "cold" dyn.av read
B "warm" dyn.av held inh.av held gen.av held
ed $R/tl/src/imp.av "fn base() -> int" "fn base(n: int = 0) -> int"
B "impl in the TRAIT's package, type in a third: sig edit" dyn.av read inh.av held gen.av held
ed $R/tl/src/imp.av "self.v + base() }" "self.v + base() + 1 }"
B "that impl's body only" dyn.av held
ed $R/pl/src/inh.av "fn k() -> int" "fn k(n: int = 0) -> int"
B "inherent method's file: sig edit" inh.av read gen.av held
ed $R/pl/src/inh.av "+ k() }" "+ k() + 1 }"
B "inherent body only" inh.av held
ed $R/pl/src/bx_impl.av "fn g() -> int" "fn g(n: int = 0) -> int"
B "generic impl's file: sig edit" gen.av read
ed $R/pl/src/bx_impl.av "self.held }" "self.held }\n    fn other() -> int { 1 }"
B "generic impl gains a method" gen.av read
printf 'use @rt.pl.{Pt}\nexport trait Two { fn two() -> int }\nimpl Two for Pt { fn two() -> int { 2 } }\n' > $R/tl/src/imp2.av
B "an impl ADDED in an unnamed file of the trait's package" dyn.av read
rm -f $R/tl/src/imp2.av
B "and DELETED — back to a state already kept" dyn.av held
echo "rt125: $fails failure(s)"
[ $fails -eq 0 ]

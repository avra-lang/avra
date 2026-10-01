#!/bin/sh
# Focused repro + qtrace for avra-8sb5.57.127: does reaching Pt's type file
# actually ask tl's typed_index for a brand-new unnamed-impl file (imp2.av),
# or is the file never consulted at all.
set -u
cd "$(dirname "$0")"
R=build/rt127
rm -rf "$R" .avra-cache && mkdir -p $R/tl/src $R/pl/src $R/app/src
printf '[package]\nname = "@rt/pl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-pl"\npath = "src/lib.av"\n' > $R/pl/avra.toml
printf 'export fn one() -> int { 1 }\n' > $R/pl/src/lib.av
printf 'export type Pt = { v: int }\n' > $R/pl/src/ty.av
printf '[package]\nname = "@rt/tl"\nversion = "0.1.0"\n\n[lib]\nname = "rt-tl"\npath = "src/lib.av"\n\n[dependencies]\n"@rt/pl" = { path = "../pl" }\n' > $R/tl/avra.toml
printf 'export fn two() -> int { 2 }\n' > $R/tl/src/lib.av
printf 'export trait Say { fn say() -> int }\n' > $R/tl/src/say.av
printf 'use say.{Say}\nuse @rt.pl.{Pt}\nfn base() -> int { 1 }\nimpl Say for Pt { fn say() -> int { self.v + base() } }\n' > $R/tl/src/imp.av
printf '[package]\nname = "rt-app"\nversion = "0.1.0"\n\n[dependencies]\n"@rt/pl" = { path = "../pl" }\n"@rt/tl" = { path = "../tl" }\n' > $R/app/avra.toml
printf 'use @rt.tl.{Say}\nuse @rt.pl.{Pt}\nexport fn said() -> int {\n    let s: dyn Say = Pt { v: 4 }\n    s.say()\n}\n' > $R/app/src/dyn.av
printf 'println("app ${said()}")\n' > $R/app/src/main.av

echo "=== cold build ==="
./avra build --time $R/app 2>&1 | tail -5
echo "=== warm no-op (settle into held state) ==="
./avra build --time $R/app 2>&1 | tail -5

echo "=== adding imp2.av (impl Two for Pt, unused trait) ==="
printf 'use @rt.pl.{Pt}\nexport trait Two { fn two() -> int }\nimpl Two for Pt { fn two() -> int { 2 } }\n' > $R/tl/src/imp2.av

echo "=== rebuild under AVRA_QTRACE=1 ==="
AVRA_QTRACE=1 ./avra build --time $R/app > build/rt127_stdout.log 2> build/rt127_trace.log
echo "exit=$?"
tail -10 build/rt127_stdout.log
echo "trace line count: $(wc -l < build/rt127_trace.log)"

#!/bin/sh
# TWO PACKAGES CHECKED ONE AFTER THE OTHER THROUGH ONE STORE EACH SEE THEIR OWN MODULES. A
# library's root module is `""` when it is the root and a named module when a program depends on
# it, so an answer kept by the first check (its module's files) must not stand in the second.
# The app reads the library's types after the library was checked alone; a refusal here is the
# library's own names unseen.
set -u
. "$(dirname "$0")/lib/attack.sh"

R=build/package-swap
who=package-swap-attack
T=build/aside/ps.$$; mkdir -p $T
[ -e "$R" ] && mv "$R" $T/package-swap
mkdir -p $R/lib/src $R/app/src
mv .avra-cache $T/cache 2>/dev/null
cat > $R/lib/avra.toml <<'TOML'
[package]
name = "@rt/swap"
version = "0.1.0"

[lib]
name = "rt-swap"
path = "src/lib.av"
TOML
cat > $R/app/avra.toml <<'TOML'
[package]
name = "package-swap-attack"
version = "0.1.0"

[dependencies]
"@rt/swap" = { path = "../lib" }
TOML
printf 'export type Info = { kind: string }\nexport fn info() -> Info { Info { kind: "k" } }\n' > $R/lib/src/lib.av
printf 'use @rt.swap.{Info, info}\n\nlet i: Info = info()\nprintln(i.kind)\n' > $R/app/src/main.av

checked() {
    out=$(./avra check $1 2>&1) || { fail "$2: refused: $(echo "$out" | grep -m1 'error')"; return; }
    steps=$((steps + 1))
}

checked $R/lib "the library alone"
checked $R/app "the app over the library the first check kept"
checked $R/lib "the library again"

verdict $who "the library, the app over it, the library again"

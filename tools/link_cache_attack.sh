#!/bin/sh
# WHAT A KEPT BINARY LINKED, ATTACKED. A program's key covers the sources it
# was compiled from; the runtime archive and a package's objects are what it
# was LINKED with, and either can change while every source stays put. Each
# step rebuilds through ONE store and holds the build to what it linked: a
# changed object must print its new answer, a changed archive must relink,
# and an unchanged pair must still be a cache hit.
set -u
cd "$(dirname "$0")/.."
R=build/link-cache-attack; T=$R/toolchain; fails=0; steps=0
rm -rf "$R" .avra-cache && mkdir -p $R/app/src $T/build
# a toolchain of its own, so its archive can move: the compiler, the tree
# it reads beside it, and a COPY of the runtime archive
cp build/avra $T/build/avra
for d in packages Makefile backend runtime; do ln -s "$(pwd)/$d" $T/$d; done
cp build/libavra_runtime.a $T/build/libavra_runtime.a
cat > $R/app/avra.toml <<'TOML'
[package]
name = "link-cache-attack"
version = "0.1.0"

[link]
objects = ["value.o"]
TOML
cat > $R/app/src/main.av <<'AV'
extern fn lca_value() -> int
println("v ${lca_value()}")
AV
value() { # value <n>: the package object answers n
    printf '#include <stdint.h>\nint64_t lca_value(void) { return %s; }\n' "$1" > $R/app/value.c
    cc -c -O1 -o $R/app/value.o $R/app/value.c
}
S() { # S <label> <want: built|cache hit> <want output>
    steps=$((steps+1))
    $T/build/avra build --time $R/app/src/main.av > $R/out 2> $R/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $1: did not build (status $st): $(head -3 $R/err | tr '\n' ' ')"; return; fi
    how=$(grep -oE "cache hit|built" $R/err | tail -1)
    got=$($R/app/src/main 2>&1)
    if [ "$how" != "$2" ] || [ "$got" != "$3" ]; then fails=$((fails+1)); echo "FAIL  $1: $how, printed '$got' — wanted $2, '$3'"; fi
}
value 1;                                   S "cold" "built" "v 1"
                                           S "no-op" "cache hit" "v 1"
value 2;                                   S "the package object changed, no source did" "built" "v 2"
                                           S "no-op after the object" "cache hit" "v 2"
printf 'int lca_unused(void) { return 0; }\n' > $R/extra.c
cc -c -o $R/extra.o $R/extra.c && ar q $T/build/libavra_runtime.a $R/extra.o 2>/dev/null
                                           S "the runtime archive changed, no source did" "built" "v 2"
                                           S "no-op after the archive" "cache hit" "v 2"
rm $R/app/value.o;                         steps=$((steps+1))
if $T/build/avra build $R/app/src/main.av > $R/out 2> $R/err; then fails=$((fails+1)); echo "FAIL  a linked object deleted: the kept binary was handed back"; fi
echo "link-cache-attack: $steps builds through one store, $fails failed"
[ "$fails" -eq 0 ]

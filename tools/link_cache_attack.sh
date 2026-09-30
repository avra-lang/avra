#!/bin/sh
# WHAT A KEPT BINARY LINKED, ATTACKED. A program's key covers the sources it
# was compiled from; the runtime archive and a package's objects are what it
# was LINKED with, and the codegen mode is how it was EMITTED — any of them
# can move while every source stays put. Each step rebuilds through ONE store
# and holds the build to its inputs: a changed object must print its new
# answer (a suite must pass on it), a changed archive or mode must relink,
# and an unchanged set must still be a cache hit.
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
extern fn lca_value() -> i64
println("v ${lca_value()}")
AV
mkdir -p $R/app/src/tests
cat > $R/app/src/tests/value_test.av <<'AV'
extern fn lca_value() -> i64
spec "link cache attack" {
    given "the package object" {
        then "answers 2" { lca_value() == 2 }
    }
}
AV
value() { # value <n>: the package object answers n
    printf '#include <stdint.h>\nint64_t lca_value(void) { return %s; }\n' "$1" > $R/app/value.c
    cc -c -O1 -o $R/app/value.o $R/app/value.c
}
S() { # S <label> <want: built|cache hit> <want output> [<env assignment>]
    steps=$((steps+1))
    env ${4:-} $T/build/avra build --time $R/app/src/main.av > $R/out 2> $R/err; st=$?
    if [ $st -ne 0 ]; then fails=$((fails+1)); echo "FAIL  $1: did not build (status $st): $(head -3 $R/err | tr '\n' ' ')"; return; fi
    how=$(grep -oE "cache hit|built" $R/err | tail -1)
    got=$($R/app/src/main 2>&1)
    if [ "$how" != "$2" ] || [ "$got" != "$3" ]; then fails=$((fails+1)); echo "FAIL  $1: $how, printed '$got' — wanted $2, '$3'"; fi
}
U() { # U <label> <want: built|cache hit> <want status>: the suite over the object
    steps=$((steps+1))
    $T/build/avra test --time $R/app/src/tests/value_test.av > $R/out 2> $R/err; st=$?
    how=$(grep -oE "cache hit|built|link" $R/err | tail -1); [ "$how" = "link" ] && how=built
    if [ "$how" != "$2" ] || [ "$st" != "$3" ]; then fails=$((fails+1)); echo "FAIL  $1: $how, status $st — wanted $2, status $3"; fi
}
value 1;                                   S "cold" "built" "v 1"
                                           S "no-op" "cache hit" "v 1"
value 2;                                   S "the package object changed, no source did" "built" "v 2"
                                           S "no-op after the object" "cache hit" "v 2"
printf 'int lca_unused(void) { return 0; }\n' > $R/extra.c
cc -c -o $R/extra.o $R/extra.c && ar q $T/build/libavra_runtime.a $R/extra.o 2>/dev/null
                                           S "the runtime archive changed, no source did" "built" "v 2"
                                           S "no-op after the archive" "cache hit" "v 2"
                                           S "codegen mode moved to calls" "built" "v 2" AVRA_INLINE_RUNTIME=0
                                           S "no-op under calls" "cache hit" "v 2" AVRA_INLINE_RUNTIME=0
                                           S "codegen mode back to inlined" "cache hit" "v 2"
value 1;                                   U "a suite, cold" "built" 1
                                           U "a suite, no-op" "cache hit" 1
value 2;                                   U "a suite, the package object changed" "built" 0
rm $R/app/value.o;                         steps=$((steps+1))
if $T/build/avra build $R/app/src/main.av > $R/out 2> $R/err; then fails=$((fails+1)); echo "FAIL  a linked object deleted: the kept binary was handed back"; fi
echo "link-cache-attack: $steps builds through one store, $fails failed"
[ "$fails" -eq 0 ]

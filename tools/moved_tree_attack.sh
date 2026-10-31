#!/bin/sh
# A BINARY IS A FUNCTION OF ITS PACKAGE, NOT OF WHERE THE TREE STANDS. One
# package, a generic instantiated twice, built at two depths: no symbol may
# carry the building machine's path, so the two binaries are the same bytes.
set -u
. "$(dirname "$0")/lib/attack.sh"
R=build/moved-tree-attack
rm -rf "$R" && mkdir -p $R/one $R/two/deeper
for d in $R/one/app $R/two/deeper/app; do
    mkdir -p $d/src/a
    printf '[package]\nname = "moved-tree-attack"\nversion = "0.1.0"\n' > $d/avra.toml
    printf 'export fn id<T>(x: T) -> T { x }\n' > $d/src/a/k.av
    printf 'use a.{id}\n\nprintln("${id(3)} ${id("s")}")\n' > $d/src/main.av
    ./avra build $d > $R/out 2> $R/err || { fail "$d did not build: $(head -2 $R/err | tr '\n' ' ')"; continue; }
    got=$($d/src/main 2>&1)
    [ "$got" = "3 s" ] || fail "$d printed '$got', wanted '3 s'"
    cp $d/src/main $d.bin
    # a signature is made where the binary was signed; the code it signs is what is compared
    command -v codesign > /dev/null && codesign --remove-signature $d.bin
done
if [ $fails -eq 0 ]; then
    n=$(cmp -l $R/one/app.bin $R/two/deeper/app.bin 2>&1 | wc -l | tr -d ' ')
    [ "$n" = 0 ] || fail "the binaries built at two depths differ in $n byte(s)"
fi
verdict "moved-tree-attack" "one package built at two depths"

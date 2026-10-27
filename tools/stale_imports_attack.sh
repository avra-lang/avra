#!/bin/sh
# A PROGRAM'S ANSWER IS A FUNCTION OF ITS TEXT, NEVER OF WHAT ANOTHER LEFT IN THE STORE. One
# directory runs a program that imports a package, then a program that imports nothing: the
# second's check must print what the same program prints in a directory that never held the
# first. The old record's imports are not the new text's, so they are never carried in.
set -u
. "$(dirname "$0")/lib/attack.sh"

R=build/stale-imports; fails=0
find "$R" -mindepth 1 -delete 2>/dev/null
for d in warm cold; do
    mkdir -p $R/$d/src
    cat > $R/$d/avra.toml <<'TOML'
[package]
name = "si"
version = "0.1.0"

[bin]
path = "src/main.av"
TOML
done
cat > $R/first.av <<'AV'
use @std.toml.{parse_toml}
let doc = parse_toml("a = 1")
AV
cat > $R/second.av <<'AV'
type S = { a: int }
impl S {
}
AV

cp $R/first.av $R/warm/src/main.av
./avra check $R/warm > $R/first.out 2>&1
cp $R/second.av $R/warm/src/main.av
./avra check $R/warm > $R/warm.out 2>&1
cp $R/second.av $R/cold/src/main.av
./avra check $R/cold > $R/cold.out 2>&1

if ! cmp -s $R/warm.out $R/cold.out; then
    echo "stale-imports: FAILED — the same program printed differently after another left its imports in the store:"
    diff $R/cold.out $R/warm.out | head -20
    fails=1
fi
[ "$fails" = 0 ] && echo "stale-imports: a program prints the same in a directory another program used" || exit 1

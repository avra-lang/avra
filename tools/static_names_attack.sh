#!/bin/sh
# A KEPT OBJECT IS A FUNCTION OF ITS KEY. Static data is named by its file's
# module and stem and the node that wrote it, never by an id a derivation hands
# out — so an object a warm build keeps holds the very bytes a cold build of the
# same source writes, and two files of one stem in two modules never share a
# name inside the one object that reads them both. It CLEARS the store, as the
# attacks beside it do.
set -u
cd "$(dirname "$0")/.."
R=build/static-names-attack; fails=0
rm -rf "$R" .avra-cache && mkdir -p $R/app/src/a $R/app/src/b
cat > $R/app/avra.toml <<'TOML'
[package]
name = "static-names-attack"
version = "0.1.0"
TOML
kept() { # kept <a's list> <b's list>: both modules' k.av, one stem, one shape
    printf 'fn mk() -> List<int> { [%s] }\n\nexport const K: List<int> = mk()\n' "$1" > $R/app/src/a/k.av
    printf 'fn mk() -> List<int> { [%s] }\n\nexport const K: List<int> = mk()\n' "$2" > $R/app/src/b/k.av
}
printf 'use a.{K as KA}\nuse b.{K as KB}\n\nprintln("${KA[0]} ${KB[0]}")\n' > $R/app/src/main.av
B() { # B <label> <wanted output>: build through the store and run it
    ./avra build --time $R/app > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  $1: status $st: $(grep -vE '^watch:|^time:' $R/err | head -2 | tr '\n' ' ')"; return 1; }
    got=$($R/app/src/main 2>&1)
    [ "$got" = "$2" ] || { fails=$((fails+1)); echo "FAIL  $1: printed '$got', wanted '$2'"; }
}
# ONE STORE FOR EVERY COMPILER (S2): the objects stand at `.avra-cache/obj`,
# where the per-compiler layout kept them under a print directory.
objects() { ls -d .avra-cache/obj .avra-cache/*/obj 2>/dev/null | head -1; }
kept "1, 2" "7, 8"
B "cold" "1 7" || { echo "static-names-attack: the cold build failed"; exit 1; }
kept "1, 2" "9, 8"
B "b moved, a held" "1 9"
rm -rf $R/warm && cp -R "$(objects)" $R/warm
rm -rf .avra-cache
B "the same source cold" "1 9"
cold=$(objects); same=0
for f in $(cd $R/warm && find . -type f); do
    [ -f "$cold/$f" ] || continue
    if cmp -s "$R/warm/$f" "$cold/$f"; then same=$((same+1)); else fails=$((fails+1)); echo "FAIL  object $f differs between the warm build and the cold one"; fi
done
# A COMPARISON OF NOTHING IS NO COMPARISON: every file's object is kept under one key.
[ $same -ge 3 ] || { fails=$((fails+1)); echo "FAIL  $same object(s) compared — the attack examined nothing"; }
echo "static-names-attack: $same kept object(s) byte-identical warm and cold, $fails failed"
[ "$fails" -eq 0 ]

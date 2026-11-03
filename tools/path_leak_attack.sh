#!/bin/sh
# A SAVED ROW IS A FUNCTION OF ITS PACKAGE, NOT OF WHERE THE TREE STANDS. One package is
# built from two checkouts at different depths; no byte of either checkout's cache may carry
# that checkout's absolute path — the property a machine-wide shared cache needs. Each file
# that does is named with the count of its leaks.
set -u
. "$(dirname "$0")/lib/attack.sh"
AVRA=${AVRA:-./avra}
# outside the tree: a package under it is cached at the tree's root, not its own
R=$(cd "$(mktemp -d)" && pwd -P)
mkdir -p "$R/one/app/src" "$R/two/deeper/app/src"
for d in "$R/one/app" "$R/two/deeper/app"; do
    printf '[package]\nname = "path-leak-attack"\nversion = "0.1.0"\n' > "$d/avra.toml"
    # a warning, so a place in its own file is kept too
    printf 'fn twice(n: int) -> int { n ?? 3 }\nfn main() { println("${twice(4)}") }\n' > "$d/src/main.av"
    # the checkout's own cache is the machine's, so every row it keeps is examined here
    AVRA_CACHE_DIR="$d/.avra-cache" $AVRA build "$d" > "$R/out" 2> "$R/err" || { fail "$d did not build: $(head -2 "$R/err" | tr '\n' ' ')"; continue; }
    seen=0
    for f in $(find "$d/.avra-cache" -type f); do
        [ -f "$f" ] || continue
        seen=$((seen + 1))
        n=$(grep -a -o -F "$d" "$f" | wc -l | tr -d ' ')
        [ "$n" = 0 ] || fail "${f#$d/}: $n path(s) of its checkout, e.g. $(grep -a -o "$d[A-Za-z0-9_/.-]*" "$f" | head -1 | sed "s|$d|<root>|")"
    done
    [ "$seen" -gt 0 ] || fail "$d: the build left no cache to examine"
    echo "path-leak-attack: ${d#$R/}: $seen cache file(s) examined"
done
find "$R" -delete
verdict "path-leak-attack" "one package built from two checkouts"

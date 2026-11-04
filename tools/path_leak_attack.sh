#!/bin/sh
# A SAVED ROW IS A FUNCTION OF ITS PACKAGE, NOT OF WHERE THE TREE STANDS. One package is
# built from two checkouts at different depths, each with a path dependency laid beside it; no
# byte of either checkout's cache — a row, a key or a kept read's name — may carry an absolute
# path of the checkout or of what stands beside it, the property a machine-wide shared cache
# needs. Each file that does is named with the count of its leaks.
set -u
. "$(dirname "$0")/lib/attack.sh"
AVRA=${AVRA:-./avra}
# outside the tree: a package under it is cached at the tree's root, not its own
R=$(cd "$(mktemp -d)" && pwd -P)
mkdir -p "$R/one/app/src" "$R/two/deeper/app/src" "$R/one/lib/src" "$R/two/deeper/lib/src"
for d in "$R/one/app" "$R/two/deeper/app"; do
    printf '[package]\nname = "@leak/lib"\nversion = "0.1.0"\n' > "$d/../lib/avra.toml"
    printf 'export fn four() -> int { 4 }\n' > "$d/../lib/src/lib.av"
    printf '[package]\nname = "path-leak-attack"\nversion = "0.1.0"\n\n[dependencies]\n"@leak/lib" = { path = "../lib" }\n' > "$d/avra.toml"
    # a warning, so a place in its own file is kept too
    printf 'use @leak.lib.{four}\nuse @std.meta.{embed}\nconst NOTE: string = embed("note.txt")\nfn twice(n: int) -> int { n ?? 3 }\nfn main() { println("${twice(four())} ${NOTE.length}") }\n' > "$d/src/main.av"
    # a compile-time run reads a file, so a record names what it read
    printf 'hi\n' > "$d/src/note.txt"
    # the checkout's own cache is the machine's, so every row it keeps is examined here
    AVRA_CACHE_DIR="$d/.avra-cache" $AVRA build "$d" > "$R/out" 2> "$R/err" || { fail "$d did not build: $(head -2 "$R/err" | tr '\n' ' ')"; continue; }
    seen=0
    # cas/stores is the shared store's registry of where readers stand: a location by design
    for f in $(find "$d/.avra-cache" -type f ! -path '*/cas/stores/*'); do
        [ -f "$f" ] || continue
        seen=$((seen + 1))
        around=$(dirname "$d")
        # a path a record hexes is the same leak in other letters
        hexed=$(printf '%s/' "$around" | od -An -tx1 | tr -d ' \n')
        n=$(( $(grep -a -o -F "$around/" "$f" | wc -l) + $(grep -a -o -i -F "$hexed" "$f" | wc -l) ))
        [ "$n" = 0 ] || fail "${f#$d/}: $n path(s) of its checkout or beside it, e.g. $(grep -a -o "$around/[A-Za-z0-9_/.-]*" "$f" | head -1 | sed "s|$around|<around>|")"
    done
    [ "$seen" -gt 0 ] || fail "$d: the build left no cache to examine"
    echo "path-leak-attack: ${d#$R/}: $seen cache file(s) examined"
done
find "$R" -delete
verdict "path-leak-attack" "one package built from two checkouts"

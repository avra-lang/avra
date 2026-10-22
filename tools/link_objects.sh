#!/bin/sh
# THE OBJECTS A MANIFEST'S [link] ROW NAMES, as the build/ paths make builds.
# The one reader of `objects = [...]` and `wasm_objects = [...]`: the
# Makefile's object lists and the keepers ask here, never a sed of their own.
#
#   sh tools/link_objects.sh                 every package's objects
#   sh tools/link_objects.sh --wasm          every package's wasm objects (build/wasm32/)
#   sh tools/link_objects.sh --closure <pkg> the objects of <pkg> and every
#                                            @std package its sources `use`, tests aside
#   sh tools/link_objects.sh --rows <key> <manifest>  one manifest's row as written
#   sh tools/link_objects.sh --self-test
# A root other than the tree is `LINK_ROOT=<dir>`.

root="${LINK_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# rows <key> <manifest>...: each entry of a `key = [...]` row, as written
rows() {
    key=$1; shift
    [ $# -gt 0 ] || return 0
    sed -n "s/^ *$key *= *\[\(.*\)\].*/\1/p" "$@" | tr ',' '\n' | tr -d ' "' | sed '/^$/d'
}

# objects <key> <prefix> <manifest>...: the build/ path each entry names
objects() {
    key=$1 prefix=$2; shift 2
    rows "$key" "$@" | sed 's|.*/||' | sed "s|^|$prefix|" | LC_ALL=C sort -u
}

# closure <pkg>: the package and every @std package its non-test sources use, transitively.
# One grep over every package's sources; the walk is awk's.
closure() {
    grep -roE --include='*.av' --exclude-dir=tests \
        '^[[:space:]]*(export[[:space:]]+)?use[[:space:]]+@std\.[a-z_]+' "$root"/packages/*/src 2>/dev/null |
    awk -v start="$1" '{
            n = split($0, path, "/packages/"); split(path[n], part, "/")
            d = $0; sub(/.*@std\./, "", d); gsub(/_/, "-", d)
            uses[part[1]] = uses[part[1]] " std-" d
        }
        END {
            seen[start] = 1; todo[1] = start; n = 1
            for (i = 1; i <= n; i++) {
                k = split(uses[todo[i]], ds, " ")
                for (j = 1; j <= k; j++) if (!(ds[j] in seen)) { seen[ds[j]] = 1; todo[++n] = ds[j] }
            }
            for (i = 1; i <= n; i++) print todo[i]
        }'
}

manifests() { for p in "$@"; do [ ! -f "$root/packages/$p/avra.toml" ] || echo "$root/packages/$p/avra.toml"; done; }

self_test() {
    t=$(mktemp -d) || exit 1
    trap 'find "$t" -delete' EXIT
    fails=0
    bad() { fails=$((fails + 1)); echo "link_objects: FAIL — $1"; }
    mk() { mkdir -p "$t/packages/$1/src/tests"; printf '[package]\nname = "%s"\n%b' "$1" "$2" > "$t/packages/$1/avra.toml"; }
    mk app ''
    mk std-io '[link]\nobjects = ["../../build/io.o", "../../build/io_watch.o"]\nwasm_objects = ["c/io_wasm.c"]\n'
    mk std-deep '[link]\nobjects = ["../../build/deep.a"]\n'
    mk std-tested '[link]\nobjects = ["../../build/tested.o"]\n'
    mk std-alone '[link]\nobjects = ["../../build/alone.o"]\n'
    printf 'use @std.io.{read}\n' > "$t/packages/app/src/main.av"
    printf 'export use @std.deep\n' > "$t/packages/std-io/src/io.av"
    printf 'use @std.tested\n' > "$t/packages/app/src/tests/t.av"
    all=$(LINK_ROOT=$t sh "$0" | tr '\n' ' ')
    [ "$all" = "build/alone.o build/deep.a build/io.o build/io_watch.o build/tested.o " ] || bad "every manifest: got '$all'"
    wasm=$(LINK_ROOT=$t sh "$0" --wasm | tr '\n' ' ')
    [ "$wasm" = "build/wasm32/io_wasm.c " ] || bad "wasm objects: got '$wasm'"
    cl=$(LINK_ROOT=$t sh "$0" --closure app | tr '\n' ' ')
    [ "$cl" = "build/deep.a build/io.o build/io_watch.o " ] || bad "closure (transitive, tests aside, unreached aside): got '$cl'"
    rw=$(LINK_ROOT=$t sh "$0" --rows objects "$t/packages/std-io/avra.toml" | tr '\n' ' ')
    [ "$rw" = "../../build/io.o ../../build/io_watch.o " ] || bad "one manifest's rows as written: got '$rw'"
    [ "$fails" = 0 ] || exit 1
    echo "link_objects: self-test passed — 4 fixtures (every manifest, wasm, a transitive closure with tests and unreached packages aside, rows as written)"
}

case "$1" in
    --self-test) self_test ;;
    --wasm) objects wasm_objects build/wasm32/ "$root"/packages/*/avra.toml ;;
    --closure) objects objects build/ $(manifests $(closure "$2")) ;;
    --rows) rows "$2" "$3" ;;
    "") objects objects build/ "$root"/packages/*/avra.toml ;;
    *) echo "usage: sh tools/link_objects.sh [--wasm | --closure <pkg> | --rows <key> <manifest> | --self-test]" >&2; exit 2 ;;
esac

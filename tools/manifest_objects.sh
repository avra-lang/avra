#!/bin/sh
# tool-witness: run by make stems
# THE OBJECTS A MANIFEST'S [link] ROW NAMES, as the build/ paths make builds.
# The one reader of `objects = [...]` and `[link.objects_for]`: the
# Makefile's object lists and the keepers ask here, never a sed of their own.
# An entry names its file once; a platform builds it under its own object
# directory (`build/<dir>/`), and `[link.objects_for]` gives a platform's set
# only where it differs (`wasm32 = []`: no build there).
#
#   sh tools/manifest_objects.sh [--platform <dir>]                  every package's objects
#   sh tools/manifest_objects.sh [--platform <dir>] <pkg>            one package's (a name under
#                                                                    packages/, or a directory
#                                                                    holding an avra.toml)
#   sh tools/manifest_objects.sh [--platform <dir>] --closure <pkg>  <pkg>'s and every @std package
#                                                                    its sources `use`, tests aside
#   sh tools/manifest_objects.sh --rows <key> <manifest>             one manifest's `[link]` row as written
# `--platform <dir>` answers that platform's objects (build/<dir>/) in place of the host's.
#   sh tools/manifest_objects.sh --self-test
# A root other than the tree is `MANIFEST_ROOT=<dir>`.

root="${MANIFEST_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# rows <key> <manifest>...: each entry of a `[link]` row `key = [...]`, as written
rows() { section_rows link "$@"; }

# section_rows <section> <key> <manifest>...: each entry of a `key = [...]` row under `[section]`
section_rows() {
    section=$1 key=$2; shift 2
    [ $# -gt 0 ] || return 0
    awk -v key="$key" -v section="$section" '
        FNR == 1 { inlink = 0; reading = 0 }
        /^\[/ { h = $0; sub(/^\[/, "", h); sub(/\][ \t]*$/, "", h); inlink = (h == section); next }
        !inlink { next }
        reading == 0 && $0 ~ "^[ \t]*" key "[ \t]*=" { reading = 1 }
        reading == 1 {
            line = $0
            sub(/^[ \t]*#.*/, "", line)
            while (match(line, /"[^"]*"/)) {
                print substr(line, RSTART + 1, RLENGTH - 2)
                line = substr(line, RSTART + RLENGTH)
            }
            if ($0 ~ /\]/) reading = 2
        }
    ' "$@"
}

# writes <section> <key> <manifest>: whether the manifest writes `key` under `[section]`
writes() {
    awk -v section="$1" -v key="$2" '
        /^\[/ { h = $0; sub(/^\[/, "", h); sub(/\][ \t]*$/, "", h); next }
        h == section && $0 ~ "^[ \t]*" key "[ \t]*=" { found = 1 }
        END { exit !found }
    ' "$3"
}

# objects <dir> <manifest>...: the build/ path of each object a manifest carries on the platform
# whose object directory is <dir> (empty: the host) — its `[link.objects_for]` row for <dir> where
# it writes one, else `objects`
objects() {
    pdir=$1; shift
    for m in "$@"; do
        if [ -n "$pdir" ] && writes link.objects_for "$pdir" "$m"; then
            section_rows link.objects_for "$pdir" "$m"
        else
            rows objects "$m"
        fi
    done | sed 's|.*/||' | sed "s|^|build/${pdir:+$pdir/}|" | LC_ALL=C sort -u
}

# dir <pkg>: a package's directory under the root — `packages/<pkg>`, or <pkg> itself
# when it is a directory holding an avra.toml (`tools`, `packages/cli`).
dir() {
    if [ -f "$root/packages/$1/avra.toml" ]; then echo "packages/$1"
    elif [ -f "$root/${1%/}/avra.toml" ]; then echo "${1%/}"
    else echo "manifest_objects: no package \`$1\` (neither packages/$1 nor $1 holds an avra.toml)" >&2; return 1
    fi
}

# closure <dir>: the package and every @std package its non-test sources use, transitively,
# as directories. `use @std.x_y` is packages/std-x_y — the name is the directory's.
# One grep over every package's sources; the walk is awk's.
closure() {
    grep -roE --include='*.av' --exclude-dir=tests \
        '^[[:space:]]*(export[[:space:]]+)?use[[:space:]]+@std\.[a-z_]+' "$root/$1/src" "$root"/packages/*/src 2>/dev/null |
    awk -v start="$1" -v root="$root/" '{
            p = substr($0, length(root) + 1); sub(/\/src\/.*/, "", p)
            d = $0; sub(/.*@std\./, "", d)
            uses[p] = uses[p] " packages/std-" d
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

manifests() { for d in "$@"; do [ ! -f "$root/$d/avra.toml" ] || echo "$root/$d/avra.toml"; done; }

self_test() {
    t=$(mktemp -d) || exit 1
    trap 'find "$t" -delete' EXIT
    fails=0
    bad() { fails=$((fails + 1)); echo "manifest_objects: FAIL — $1"; }
    mk() { mkdir -p "$t/packages/$1/src/tests"; printf '[package]\nname = "%s"\n%b' "$1" "$2" > "$t/packages/$1/avra.toml"; }
    mk app ''
    mk std-io '[link]\nobjects = ["../../build/io.o", "../../build/io_watch.o"]\n\n[link.objects_for]\nwasm32 = ["../../build/io.o"]\n'
    mk std-deep '[link]\nobjects = ["../../build/deep.a"]\n\n[link.objects_for]\nwasm32 = []\n'
    mk std-tested '[link]\nobjects = ["../../build/tested.o"]\n'
    mk std-alone '[link]\nobjects = ["../../build/alone.o"]\n'
    printf 'use @std.io.{read}\n' > "$t/packages/app/src/main.av"
    printf 'export use @std.deep\n' > "$t/packages/std-io/src/io.av"
    printf 'use @std.tested\n' > "$t/packages/app/src/tests/t.av"
    all=$(MANIFEST_ROOT=$t sh "$0" | tr '\n' ' ')
    [ "$all" = "build/alone.o build/deep.a build/io.o build/io_watch.o build/tested.o " ] || bad "every manifest: got '$all'"
    wasm=$(MANIFEST_ROOT=$t sh "$0" --platform wasm32 | tr '\n' ' ')
    [ "$wasm" = "build/wasm32/alone.o build/wasm32/io.o build/wasm32/tested.o " ] || bad "a platform's objects (one set, an exception, none): got '$wasm'"
    sim=$(MANIFEST_ROOT=$t sh "$0" --platform iphonesimulator std-io | tr '\n' ' ')
    [ "$sim" = "build/iphonesimulator/io.o build/iphonesimulator/io_watch.o " ] || bad "a platform with no exception carries objects: got '$sim'"
    cl=$(MANIFEST_ROOT=$t sh "$0" --closure app | tr '\n' ' ')
    [ "$cl" = "build/deep.a build/io.o build/io_watch.o " ] || bad "closure (transitive, tests aside, unreached aside): got '$cl'"
    one=$(MANIFEST_ROOT=$t sh "$0" std-io | tr '\n' ' ')
    [ "$one" = "build/io.o build/io_watch.o " ] || bad "one package: got '$one'"
    wcl=$(MANIFEST_ROOT=$t sh "$0" --platform wasm32 --closure app | tr '\n' ' ')
    [ "$wcl" = "build/wasm32/io.o " ] || bad "a closure's platform objects: got '$wcl'"
    mk std-x_y '[link]\nobjects = ["../../build/xy.o"]\n'
    mkdir -p "$t/kit/src"; printf '[package]\nname = "kit"\n' > "$t/kit/avra.toml"
    printf 'use @std.x_y\nuse @std.io\n' > "$t/kit/src/main.av"
    kit=$(MANIFEST_ROOT=$t sh "$0" --closure kit | tr '\n' ' ')
    [ "$kit" = "build/deep.a build/io.o build/io_watch.o build/xy.o " ] || bad "a package directory outside packages/, an underscored name: got '$kit'"
    MANIFEST_ROOT=$t sh "$0" --closure nowhere > /dev/null 2>&1 && bad "a package that does not exist answered"
    rw=$(MANIFEST_ROOT=$t sh "$0" --rows objects "$t/packages/std-io/avra.toml" | tr '\n' ' ')
    [ "$rw" = "../../build/io.o ../../build/io_watch.o " ] || bad "one manifest's rows as written: got '$rw'"
    [ "$fails" = 0 ] || exit 1
    echo "manifest_objects: self-test passed — 9 fixtures (every manifest, a platform with exceptions, a platform without, one package, a transitive closure with tests and unreached packages aside, a closure's platform objects, a package directory outside packages/ with an underscored @std name, an unknown package refused, rows as written)"
}

platform=
if [ "${1:-}" = --platform ]; then platform=$2; shift 2; fi
case "${1:-}" in
    --self-test) self_test ;;
    --closure) d=$(dir "$2") || exit 1; objects "$platform" $(manifests $(closure "$d")) ;;
    --rows) rows "$2" "$3" ;;
    "") objects "$platform" "$root"/packages/*/avra.toml ;;
    -*) echo "usage: sh tools/manifest_objects.sh [--platform <dir>] [<pkg> | --closure <pkg>] | --rows <key> <manifest> | --self-test" >&2; exit 2 ;;
    *) d=$(dir "$1") || exit 1; objects "$platform" $(manifests "$d") ;;
esac

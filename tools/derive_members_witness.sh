#!/bin/sh
# A DERIVE'S NEW MEMBERS ARE SEEN ON THE NEXT CHECK. A package's own trait derives `first` beside a
# type, through `beside(t, quote { impl ${t} { … } })`; a test of that package passes; a second member
# is added inside the quoted impl, and the test calling it is run again over the same machine cache:
# the program layer sees `second`.
#   sh tools/derive_members_witness.sh [compiler]     (default build/avra)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=$(cd "$(dirname "${1:-$root/build/avra}")" && pwd)/$(basename "${1:-$root/build/avra}")
w=$(mktemp -d "${TMPDIR:-/tmp}/avra-derive-members.XXXXXX")
trap 'find "$w" -delete 2>/dev/null || :' EXIT
fail() { echo "derive_members_witness: $*"; exit 1; }
held() { echo "derive_members_witness: $*"; }

laid() {
    p="$w/$1"
    mkdir -p "$p/src/tests"
    cat > "$p/avra.toml" <<'EOF'
[package]
name        = "@probe/drv"
version     = "0.0.1"
description = "a derive whose generated members change"

[lib]
name = "probe-drv"
path = "src/drv.av"
EOF
    cat > "$p/src/made.av" <<'EOF'
use @std.meta.{Type, Directive, beside, literal}

export trait Made {
    static fn derive(t: Type) -> List<Directive> {
        [beside(t, quote {
            impl ${t} {
                static fn first() -> string { ${literal("one")} }
            }
        })]
    }
}
EOF
    cat > "$p/src/drv.av" <<'EOF'
use @std.meta.{derive}
use made.{Made}

@derive(Made)
export type Point = { x: int }
EOF
    cat > "$p/src/tests/drv_test.av" <<'EOF'
use @probe.drv.{Point}

spec "drv" {
    given "a derived member" {
        then "first" { Point.first() == "one" }
    }
}
EOF
}

grown() {
    p="$w/$1"
    sed -i.was 's|                static fn first() -> string { ${literal("one")} }|&\
                static fn second() -> int { 2 }|' "$p/src/made.av"
    sed -i.was 's|        then "first" { Point.first() == "one" }|&\
        then "second" { Point.second() == 2 }|' "$p/src/tests/drv_test.av"
    find "$p" -name '*.was' -delete
}

# one case: a fresh package and machine cache under `$2...` as env, run, grown, run again
seen() {
    name=$1
    shift
    laid "$name"
    mkdir -p "$w/$name-cache"
    env AVRA_CACHE_DIR="$w/$name-cache" "$@" "$avra" test "$w/$name" > "$w/$name.first" 2>&1 ||
        fail "($name) the first member's test failed: $(head -3 "$w/$name.first")"
    grown "$name"
    env AVRA_CACHE_DIR="$w/$name-cache" "$@" "$avra" test "$w/$name" > "$w/$name.grown" 2>&1
}

seen layer X=1 || fail "the program layer missed the new member: $(grep -m1 'error\[' "$w/layer.grown")"
held "the program layer sees a derive's new member"

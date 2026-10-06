#!/bin/sh
# The cancel slice's spelling probes, checked and run OUTSIDE the tree:
# each file asks one question of today's compiler, as a package of its
# own. A probe that checks clean is run in both engines. A probe is a
# `.probe` here and an `.av` only where it is checked: several are
# refused by design, and the tree holds no Avra the formatter cannot
# read.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
dir=${TMPDIR:-/tmp}/flow-probe-cancel
echo "== $(uname -srm)"
for f in "$here"/p*.probe; do
    name=$(basename "$f" .probe)
    pkg=$dir/$name
    mkdir -p "$pkg/src"
    printf '[package]\nname        = "%s"\nversion     = "0.0.1"\ndescription = "a probe"\n' "$(echo "$name" | tr _ -)" > "$pkg/avra.toml"
    cp "$f" "$pkg/src/main.av"
    echo "== $name — $(sed -n '1s,^//! asks: ,,p' "$f")"
    "$root/build/avra" check "$pkg" > "$pkg/check" 2>&1
    if ! grep -q '^error' "$pkg/check"; then
        echo "checks clean"
        echo "-- evaluated"
        timeout 20 "$root/build/avra" run "$pkg" 2>&1 | head -12
        echo "-- native"
        if "$root/build/avra" build "$pkg" > "$pkg/build" 2>&1; then timeout 20 "$pkg/src/main" 2>&1 | head -12; else head -6 "$pkg/build"; fi
    else
        echo "errors: $(grep -c '^error' "$pkg/check")"
        grep -vE '^\s*$' "$pkg/check" | sed "s,$pkg/src/,," | head -${PROBE_LINES:-36}
    fi
done

#!/bin/sh
# The cancel slice's spelling probes, checked and run OUTSIDE the tree:
# each file asks one question of today's compiler. A probe that checks
# clean is run in both engines. A probe is a `.probe` here and an `.av`
# only where it is checked: several are refused by design, and the tree
# holds no Avra the formatter cannot read.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
dir=${TMPDIR:-/tmp}/flow-probe-cancel
mkdir -p "$dir"
echo "== $(uname -srm), tree $(cat "$root/build/.avra-compiler-hash" 2>/dev/null || git -C "$root" rev-parse --short HEAD 2>/dev/null || echo synced)"
for f in "$here"/p*.probe; do
    name=$(basename "$f" .probe)
    cp "$f" "$dir/$name.av"
    echo "== $name — $(sed -n '1s,^//! asks: ,,p' "$f")"
    if "$root/build/avra" check "$dir/$name.av" > "$dir/$name.check" 2>&1 && ! grep -q '^error' "$dir/$name.check"; then
        echo "checks clean"
        echo "-- evaluated"; timeout 20 "$root/build/avra" run "$dir/$name.av" 2>&1 | head -12
        echo "-- native"; "$root/build/avra" build "$dir/$name.av" > "$dir/$name.build" 2>&1 && timeout 20 "$dir/$name" 2>&1 | head -12 || head -6 "$dir/$name.build"
    else
        grep -cE '^error' "$dir/$name.check" | sed 's/^/errors: /'
        grep -vE '^\s*$' "$dir/$name.check" | head -${PROBE_LINES:-40}
    fi
done

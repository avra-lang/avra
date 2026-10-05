#!/bin/sh
# THE HOST'S TABLE IS GENERATED: runtime/dom/wire.gen.js is what
# `host_table` (packages/std-ui/src/realize/dom/wire.av) writes, and a
# number changed in Avra alone would leave a host reading another wire.
# Regenerate: build/avra run packages/std-ui/src/realize/dom/tests/host/host.av > runtime/dom/wire.gen.js
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
gen="$here/build/wire.gen.js"
mkdir -p "$here/build"
"$here/build/avra" run "$here/packages/std-ui/src/realize/dom/tests/host/host.av" > "$gen"
[ -s "$gen" ] || { echo "ui-host: the program wrote no table — nothing was compared"; exit 1; }
if ! cmp -s "$gen" "$here/runtime/dom/wire.gen.js"; then
  echo "ui-host: runtime/dom/wire.gen.js is not what realize/dom/wire.av says — it is generated, never edited:"
  echo "ui-host:   build/avra run packages/std-ui/src/realize/dom/tests/host/host.av > runtime/dom/wire.gen.js"
  diff "$here/runtime/dom/wire.gen.js" "$gen" | head -20
  exit 1
fi
echo "ui-host: the host's table is the wire's ($(grep -c '^export const' "$gen") exports compared)"

#!/bin/sh
# THE PAGE: a runnable page beside a wasm module. `dom_page.sh <wasm> <outdir> [title]`.
# The program owns its stylesheet (it sends it in its first frame), so the
# page carries an EMPTY style element the glue fills — never a copy of the
# CSS kept in a second place.
set -e
wasm=$1
out=$2
title=${3:-Avra}
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$wasm" ] || { echo "dom_page: no such module: $wasm" >&2; exit 1; }
mkdir -p "$out"
cp "$here/runtime/dom/bootstrap.js" "$here/runtime/dom/wasi.js" "$out/"
cp "$wasm" "$out/app.wasm"
sed -e "s|<!--TITLE-->|$title|" "$here/runtime/dom/page.html" > "$out/index.html"
printf 'dom_page: %s (app.wasm, bootstrap.js, wasi.js, index.html)\n' "$out"

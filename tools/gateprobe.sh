#!/bin/sh
# The gate's wasm-check state: the compiler, an older node first on PATH, a Node 24 beside it as node-jspi.
set -u
d=$(mktemp -d /tmp/nodes.XXXXXX)
curl -sL https://nodejs.org/dist/v22.13.0/node-v22.13.0-linux-x64.tar.xz | tar -xJ -C "$d" || { echo "no node 22"; exit 1; }
mkdir -p "$d/bin"
ln -s "$d"/node-v22.13.0-linux-x64/bin/node "$d/bin/node"
n24=$(readlink -f "$(command -v node)")
echo "n24=$n24"; echo "default node: $($d/bin/node --version); jspi node: $($n24 --version)"
make -s wasm-runtime wasm-packages >/dev/null 2>&1
echo "## OLD script (NODE=node 22)"
PATH="$d/bin:$PATH" sh tools/.old-check.sh 2>&1 | grep -E "^wasm-check:|^---|^[+-]" | head -24
echo "## FIXED script (node 22 first on PATH, node-jspi = Node 24)"
sh .github/ci/install_node.sh >/dev/null 2>&1; echo "node-jspi: $(command -v node-jspi) $(node-jspi --version)"
PATH="$d/bin:$PATH" sh tools/wasm-check.sh 2>&1 | grep -E "^wasm-check:" | head -16

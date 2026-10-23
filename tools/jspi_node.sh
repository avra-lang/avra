# THE NODE A TASK MODULE RUNS UNDER, for the scripts that source this (`. tools/jspi_node.sh`, after
# `say` is defined): $NODE when it names one, else the image's `node-jspi` (a Node 24, which has the
# standard JSPI API), else `node`. A node whose engine lacks `WebAssembly.Suspending` is REFUSED BY
# NAME, never run: a module that parks prints nothing under it. No node at all is the caller's skip.
node=${NODE:-$(command -v node-jspi || echo node)}
if command -v "$node" >/dev/null 2>&1 \
    && ! "$node" --experimental-wasm-jspi -e 'process.exit(typeof WebAssembly.Suspending === "function" ? 0 : 1)' >/dev/null 2>&1; then
    say "REFUSED: $($node --version) has no WebAssembly.Suspending — a module with tasks cannot run here; install a Node 24 as node-jspi (.github/ci/install_node.sh) or set NODE"
    exit 1
fi

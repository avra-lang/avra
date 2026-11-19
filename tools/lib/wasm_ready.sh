# `wasm_ready`: the wasm runtime archive and the package wasm objects every wasm build links, made
# current for the tree `tree` names. make is the judge of what is current, so no file test stands in
# for it; a failure carries make's own words to stderr and answers 1.
wasm_ready() {
    wasm_out=$(cd "$tree" && make -s wasm-runtime wasm-packages 2>&1) || { printf '%s\n' "$wasm_out" >&2; return 1; }
}

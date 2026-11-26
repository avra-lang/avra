# THE TOOLCHAIN AS A LEDGER KEY: what decides a binary's bytes, `[a-z0-9._-]`. Sourced.
#   toolchain_key <compiler> [<linker>]   the platform, then each driver's name and version
#                                         (`linux-x86_64-clang-22.1.2`); a linker that is the
#                                         compiler's own version is said once
# A driver whose version reads as neither clang nor gcc is `unknown`, so its rows are its own.
driver_version() {
    "$1" --version 2>/dev/null | head -1 |
        sed -n 's/.*clang version \([0-9][0-9.]*\).*/clang-\1/p; t; s/^gcc.* \([0-9][0-9.]*\)$/gcc-\1/p' |
        head -1 | grep . || echo unknown
}
toolchain_key() {
    plat=$(printf '%s-%s' "$(uname -s)" "$(uname -m)" | tr 'A-Z' 'a-z')
    cc=$(driver_version "$1")
    ld=$(driver_version "${2:-$1}")
    if [ "$cc" = "$ld" ]; then echo "$plat-$cc"; else echo "$plat-$cc-$ld"; fi
}
#   wasm_toolchain_key                    the wasm target's: the clang that builds it and the
#                                         binaryen that optimises it (`wasm32-clang-22.1.2-wasm-opt-123`)
wasm_toolchain_key() {
    opt=$(wasm-opt --version 2>/dev/null | sed -n 's/.*version \([0-9][0-9]*\).*/\1/p' | head -1)
    echo "wasm32-$(driver_version clang)-wasm-opt-${opt:-unknown}"
}

#!/bin/sh
# tool-witness: --self-test
# THE COMPILER'S LLVM LINK WORDS, in plain POSIX shell: `packages/std-avrac/avra.toml`'s `[link]`
# `search` and `libs` rows as `-L`/`-l` words, the environment's holes filled. The Makefile reads
# them while it parses itself, before any compiler or interpreter beyond the platform's exists, so
# a cold machine links the seed with no Python. The checks that hold the row to llvm-config and to
# the compiler's own platform defaults stay in tools/llvm_link.py (they run with a toolchain).
#
#   sh tools/llvm_link.sh --words
#   sh tools/llvm_link.sh --self-test
set -eu
cd "$(dirname "$0")/.."

# hole <name>: what a `${NAME}` means when the environment names nothing — the compiler's own
# `platform_hole` (compiler/whole.av).
hole() {
    case "$1" in
        AVRA_CXX_RUNTIME) if [ "$(uname -s)" = Darwin ]; then echo c++; else echo stdc++; fi ;;
        AVRA_SYS_SEARCH)
            if [ "$(uname -s)" = Darwin ]; then dirs="/opt/homebrew/lib /usr/local/lib"
            else dirs="/usr/lib/x86_64-linux-gnu /usr/lib/aarch64-linux-gnu /usr/lib64 /usr/lib"; fi
            for d in $dirs; do
                for ext in a so dylib; do
                    if [ -e "$d/libzstd.$ext" ]; then echo "$d"; return 0; fi
                done
            done ;;
    esac
    return 0
}

# expanded <flag>: `${NAME}` filled from the environment, else the platform's answer.
expanded() {
    rest=$1
    out=
    while :; do
        case "$rest" in
            *'${'*) ;;
            *) out="$out$rest"; break ;;
        esac
        out="$out${rest%%\$\{*}"
        rest=${rest#*\$\{}
        case "$rest" in
            *'}'*) ;;
            *) out="$out\${$rest"; break ;;
        esac
        name=${rest%%\}*}
        rest=${rest#*\}}
        eval "val=\${$name-__unset__}"
        if [ "$val" = __unset__ ]; then val=$(hole "$name"); fi
        out="$out$val"
    done
    printf '%s' "$out"
}

# row <key> <letter>: the manifest's `[link]` array under the key, one `<letter>word` per entry
# (the one `[link]` reader is tools/manifest_objects.sh).
row() {
    sh "$(dirname "$0")/manifest_objects.sh" --rows "$1" packages/std-avrac/avra.toml | while IFS= read -r entry; do
        word=$(expanded "$entry")
        [ -z "$word" ] || printf '%s%s\n' "$2" "$word"
    done
}

words() {
    : "${LLVM_PREFIX:=/opt/homebrew/opt/llvm}"
    export LLVM_PREFIX
    if [ -z "${AVRA_CXX_RUNTIME+x}" ]; then AVRA_CXX_RUNTIME=$(hole AVRA_CXX_RUNTIME); export AVRA_CXX_RUNTIME; fi
    if [ "$(uname -s)" = Darwin ] && [ -z "${AVRA_SYS_SEARCH+x}" ]; then AVRA_SYS_SEARCH=/opt/homebrew/lib; export AVRA_SYS_SEARCH; fi
    { row search -L; row libs -l; } | tr '\n' ' ' | sed 's/ $//'
    echo
}

if [ "${1:-}" = --words ]; then words; exit 0; fi
if [ "${1:-}" = --self-test ]; then
    got=$(LLVM_PREFIX=/p AVRA_SYS_SEARCH=/s AVRA_CXX_RUNTIME=cx words)
    case "$got" in "-L/p/lib -L/s -lLLVM"*" -lcx "*) ;; *) echo "llvm_link: holes were not filled: $got"; exit 1 ;; esac
    [ "$(expanded 'a${NOPE_NOT_SET}b')" = ab ] || { echo "llvm_link: an unknown hole did not read empty"; exit 1; }
    [ "$(expanded 'x${unclosed')" = 'x${unclosed' ] || { echo "llvm_link: an unclosed hole was not kept"; exit 1; }
    echo "llvm_link: self-test passed — holes from the environment, unknown holes empty, an unclosed one kept"
    exit 0
fi
echo "usage: llvm_link.sh --words | --self-test" >&2
exit 2

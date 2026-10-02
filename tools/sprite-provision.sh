#!/bin/sh
# Make this machine able to build the tree — the provisioning half of a
# fresh Sprite session. Idempotent, so it is safe to run on every start.
#
# A Sprite is a stock Ubuntu image: clang, python3, make and git are
# already there, LLVM's development package is not, and the tree links
# `-lLLVM` and compiles against the llvm-c headers. This installs that
# package and points the tree's LLVM root at it, so `make` and `./avra`
# run with no environment setup.
#
# Linux-only; on macOS the Homebrew toolchain already satisfies the
# tree, so this is a no-op.
#
#   sh tools/sprite-provision.sh
set -eu

[ "$(uname -s)" = Linux ] || exit 0

root="$(cd "$(dirname "$0")/.." && pwd)"
major="${AVRA_LLVM_MAJOR:-22}"
prefix="/usr/lib/llvm-$major"

if ! dpkg -s "llvm-$major-dev" >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
        "llvm-$major-dev" "clang-$major" \
        "lld-$major" wasi-libc "libclang-rt-$major-dev-wasm32" wabt binaryen
fi

# THE TREE SPELLS ITS LLVM ROOT AS ${LLVM_PREFIX} and defaults it to the
# Homebrew path. Point that default at the distro LLVM so the Makefile,
# the `avra` shim and every tool resolve it without an environment — a
# Sprite session's non-login shells have none — and make `clang` and
# `llvm-config` name the same major the linked library is.
sudo install -d /opt/homebrew/opt /usr/local/bin
sudo ln -sfn "$prefix" /opt/homebrew/opt/llvm
sudo ln -sf "$prefix/bin/clang" /usr/local/bin/clang
sudo ln -sf "$prefix/bin/llvm-config" /usr/local/bin/llvm-config

# Login shells carry the same values the compiler reads.
printf '%s\n' \
    "export LLVM_PREFIX=$prefix" \
    "export CC=$prefix/bin/clang" \
    | sudo tee /etc/profile.d/avra-llvm.sh >/dev/null

test -f "$prefix/include/llvm-c/Core.h" \
    || { echo "sprite-provision: no llvm-c headers under $prefix" >&2; exit 1; }
test -e "$prefix/lib/libLLVM.so" \
    || { echo "sprite-provision: no libLLVM.so under $prefix" >&2; exit 1; }
echo "sprite-provision: LLVM $major ready at $prefix"

# A compiler on disk is what makes an agent's first turn useful. The
# seed links into one in seconds, and it IS this tree's compiler exactly
# when the tree is the source the seed came from — which
# `bootstrap/seed.sources` records. A mismatch costs a build, and the
# build's product is verified before it is trusted.
if [ ! -x "$root/build/avra" ]; then
    make -C "$root" -s recover
    if [ ! -f "$root/bootstrap/seed.sources" ] \
       || [ "$(cd "$root" && sh tools/sources_hash.sh)" != "$(cat "$root/bootstrap/seed.sources")" ]; then
        make -C "$root" -s avra
        # A compiler carries the link semantics it was BUILT with, so a
        # product linked by a seed older than this tree still links the
        # old way; the fixpoint is reached when the compiler exports its
        # own globals for the evaluator's `dlsym`.
        if ! nm -D "$root/build/avra" 2>/dev/null | grep -q avra_host_is_dir; then
            make -C "$root" -s avra
        fi
    fi
fi
echo "sprite-provision: build/avra ready"

#!/bin/sh
# The build toolchain on a stock Ubuntu 26.04 container: LLVM 22, as on a Sprite.
set -eu
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    ca-certificates git make python3 clang-22 llvm-22-dev >/dev/null
ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/clang
ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/cc
ln -sf /usr/lib/llvm-22/bin/llvm-config /usr/local/bin/llvm-config
mkdir -p /opt/homebrew/opt
ln -sfn /usr/lib/llvm-22 /opt/homebrew/opt/llvm

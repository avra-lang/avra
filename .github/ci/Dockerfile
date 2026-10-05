# The checks' machine: Ubuntu 26.04 and LLVM 22, as on a Sprite. `nodejs` runs
# the UI host's own tests and the board on a page (ui-host-test, ui-board).
FROM ubuntu:26.04
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      ca-certificates git make python3 clang-22 llvm-22-dev \
      lld-22 wasi-libc libclang-rt-22-dev-wasm32 wabt binaryen nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/clang \
 && ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/cc \
 && ln -sf /usr/lib/llvm-22/bin/llvm-config /usr/local/bin/llvm-config \
 && mkdir -p /opt/homebrew/opt && ln -sfn /usr/lib/llvm-22 /opt/homebrew/opt/llvm \
 && git config --system --add safe.directory '*'
ENV LLVM_PREFIX=/usr/lib/llvm-22 CC=/usr/lib/llvm-22/bin/clang

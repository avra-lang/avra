# The checks' machine: Ubuntu 26.04 and LLVM 22, as on a Sprite — its packages
# are packages.txt, which a Sprite's provisioning reads too. `nodejs` runs the
# UI host's own tests and the board on a page (ui-host-test, ui-board); the pinned Firefox runs the board in a real browser (ui-browser); a pinned Node 24 (`node-jspi`) runs the JSPI half of the hosted scheduler (wasm-host-check).
FROM ubuntu:26.04
COPY packages.txt /tmp/packages.txt
COPY install_firefox.sh /tmp/install_firefox.sh
COPY install_node.sh /tmp/install_node.sh
RUN apt-get update -qq \
 && grep -v '^#' /tmp/packages.txt | DEBIAN_FRONTEND=noninteractive xargs apt-get install -y -qq --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/clang \
 && ln -sf /usr/lib/llvm-22/bin/clang /usr/local/bin/cc \
 && ln -sf /usr/lib/llvm-22/bin/llvm-config /usr/local/bin/llvm-config \
 && mkdir -p /opt/homebrew/opt && ln -sfn /usr/lib/llvm-22 /opt/homebrew/opt/llvm \
 && sh /tmp/install_firefox.sh \
 && sh /tmp/install_node.sh \
 && git config --system --add safe.directory '*'
ENV LLVM_PREFIX=/usr/lib/llvm-22 CC=/usr/lib/llvm-22/bin/clang AVRA_CXX_RUNTIME=stdc++

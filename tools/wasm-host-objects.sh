#!/bin/sh
# The host package objects and archives a wasm fixture's native build links (`[link] objects`
# rows such as ../../build/std_time.o). A gate job holds only the compiler, so a script that
# builds a fixture natively asks for them here, once, in one place.
#   sh tools/wasm-host-objects.sh <tree>
set -eu
tree=${1:?usage: wasm-host-objects.sh <tree>}
( cd "$tree" && make -s -o avra libs ) || { echo "wasm: the host package objects did not build" >&2; exit 1; }

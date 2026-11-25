#!/bin/bash
# Ladder for .102.3: gate-builder builds the rung tree (rung_program.av), the rung's product builds HEAD.
set -u
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
sh tools/gate.sh unpack build/gate-builder.tar.gz || tar xzf build/gate-builder.tar.gz build/avra
fail=""
step() { echo "== $1"; shift; "$@" || fail="$fail [$*]"; }
P=packages/std-avrac/src/compiler/program.av
printf 'let x = 1\nx + 1\n' > /tmp/probe.av
cp "$P" build/program.final.av
cp rung_program.av "$P"
step rung-build sh -c 'make avra > build/rung.out 2>&1 || { tail -20 build/rung.out; exit 1; }'
cp build/program.final.av "$P"
step head-build sh -c 'make avra > build/head.out 2>&1 || { tail -20 build/head.out; exit 1; }'
step fresh-compiles build/avra run /tmp/probe.av
step wisp-build ./wisp --compiler build/avra --path
step wisp-parser-fresh ./wisp parser --avra build/avra
step parser-keeper make -s -o avra parser
step generator-tests ./avra test packages/std-grammar/src/tests/generate_test.av
step type-ref-tests ./avra test packages/std-avrac/src/compiler/tests/slot_names_test.av
step wisp-suite ./avra test packages/wisp
echo "== verdict:${fail:- all held}"
[ -z "$fail" ]

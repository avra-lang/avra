#!/bin/bash
export LLVM_PREFIX=/usr/lib/llvm-22
build/avra fmt --check packages/std-avrac/src/compiler/derive.av packages/std-avrac/src/compiler/findings.av; echo "fmt exit $?"
build/avra check packages/std-avrac/src/compiler/derive.av 2>&1 | grep -E "^(error|warning)" | head; echo done

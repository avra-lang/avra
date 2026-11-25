#!/bin/bash
# The witnesses as written, then under a validation that trusts every row,
# then under no reuse at all. Each build runs twice before its suite.
export LLVM_PREFIX=/usr/lib/llvm-22
f=packages/std-avrac/src/compiler/kept_settle.av
t=packages/cli/src/commands/tests/kept_settle_test.av
two() { make -s avra > /tmp/m1.log 2>&1 && make -s avra > /tmp/m2.log 2>&1 || { grep -E '^error|─\[' /tmp/m1.log /tmp/m2.log | head; return 1; }; }
run() { echo "== $1"; build/avra test $t 2>&1 | grep -E "✗|passed" | sed 's/.*bodies \/ //' | cut -c1-120; }
cp $f /tmp/ks.orig
two && run "as written"
sed -i '/kept_row_stands(r)) { return null }/d' $f
two && run "every row trusted"
cp /tmp/ks.orig $f
sed -i 's/^        if keyed != null {$/        if false {/' $f
two && run "no reuse"
cp /tmp/ks.orig $f

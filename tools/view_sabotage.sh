#!/bin/bash
# The cache suites with every module's view taken as standing.
export LLVM_PREFIX=/usr/lib/llvm-22
f=packages/std-avrac/src/compiler/record.av
cp $f /tmp/rec.orig
sed -i 's/let key = node_key(Stored.Unit, \["view", m.text(), self.view_print(store, m)\])/let key = node_key(Stored.Unit, ["view", m.text()])/' $f
grep -c '"view", m.text()\])' $f
make -s avra > /tmp/s1.log 2>&1 && make -s avra > /tmp/s2.log 2>&1 || { grep -E "^error|─\[" /tmp/s1.log /tmp/s2.log | head; cp /tmp/rec.orig $f; exit 2; }
build/avra test packages/cli 2>&1 | grep -E "✗|passed" | cut -c1-200
build/avra test packages/std-avrac/src/compiler/tests 2>&1 | grep -E "✗|passed" | cut -c1-200
cp /tmp/rec.orig $f

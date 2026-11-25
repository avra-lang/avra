#!/bin/bash
# Runs INSIDE a Sprite tree: a cold check of packages/cli, the fmt.av
# one-line edit, then the warm check under callgrind; prints the --time
# line and the top functions by inclusive and by self cost.
set -u
export LLVM_PREFIX=/usr/lib/llvm-22
command -v valgrind > /dev/null || { sudo apt-get install -y -q valgrind > /dev/null 2>&1 || sudo apk add -q valgrind > /dev/null 2>&1; }
command -v valgrind > /dev/null || { echo "no valgrind"; exit 2; }
find . -name .avra-cache -type d -prune -exec rm -rf {} +
build/avra check packages/cli > /dev/null 2>&1
f=packages/cli/src/commands/fmt.av
cp "$f" /tmp/cg.orig
sed -i 's/"avra: ${path}: ${e.describe/"avra - ${path}: ${e.describe/' "$f"
cmp -s /tmp/cg.orig "$f" && echo "EDIT DID NOT APPLY"
rm -f /tmp/cg.out.*
valgrind --tool=callgrind --callgrind-out-file=/tmp/cg.out.%p build/avra check --time packages/cli > /tmp/cg.check 2>&1
cp /tmp/cg.orig "$f"
grep '^time:' /tmp/cg.check | head -1
tail -5 /tmp/cg.check
out=$(ls -S /tmp/cg.out.* | head -1)
echo "== inclusive"
callgrind_annotate --inclusive=yes "$out" 2>/dev/null | grep -E "^ *[0-9,]+ " | head -90
echo "== self"
callgrind_annotate "$out" 2>/dev/null | grep -E "^ *[0-9,]+ " | head -40

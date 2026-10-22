#!/bin/sh
[ -d tools ] || exit 70
echo "@@BEGIN"
build/avra run packages/std-ui/src/realize/dom/tests/host_corpus/host_corpus.av 2>/tmp/gen.err
echo "@@END"
head -c 400 /tmp/gen.err

#!/bin/sh
[ -d tools ] || exit 70
build/avra run packages/std-db/src/tests/relations_probe/relations_probe.av 2>&1 | grep -a -v "^warning\|^ \|^[0-9]* │\|^─\|^$\|^help" | head -20

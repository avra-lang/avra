#!/bin/sh
[ -d tools ] || { echo "not at the tree root"; exit 70; }
echo "tree: $(git rev-parse --short HEAD 2>/dev/null)"
for t in inputs vocab externs rt-ns rt-header; do make $t > /tmp/mk.$t.log 2>&1 && v=PASS || v=FAIL; echo "$v make $t"; [ $v = FAIL ] && tail -6 /tmp/mk.$t.log | cut -c1-250; done
sh tools/exp/ct.sh 2>&1 | grep -a "^==\|status\|eval ==\|DIFFERS"
make bootstrap > /tmp/mk.bootstrap.log 2>&1 && echo "PASS make bootstrap" || { echo "FAIL make bootstrap"; tail -8 /tmp/mk.bootstrap.log | cut -c1-250; }

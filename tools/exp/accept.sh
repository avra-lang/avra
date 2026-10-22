#!/bin/sh
[ -d tools ] || exit 70
make idioms-accept > /tmp/acc.log 2>&1; echo "accept status $?"
echo "@@BASELINE"; cat tools/idioms.baseline; echo "@@END"

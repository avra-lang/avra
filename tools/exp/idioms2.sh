#!/bin/sh
[ -d tools ] || exit 70
make idioms > /tmp/i2.log 2>&1; echo "make idioms status $?"; tail -3 /tmp/i2.log | cut -c1-200

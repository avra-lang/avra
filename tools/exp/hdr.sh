#!/bin/sh
[ -d tools ] || exit 70
build/avra runtime-header > /tmp/hdr.gen 2>/tmp/hdr.err; echo "hdr status $?"
echo "@@BEGIN"; cat /tmp/hdr.gen; echo "@@END"

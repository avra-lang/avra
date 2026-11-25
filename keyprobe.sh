#!/bin/sh
# Largest spelled query key over one cold cli check.
rm -rf .avra-cache
AVRA_QTRACE=1 build/avra check packages/cli > kp.out 2> kp.err; echo "rc=$?"
awk -F"\t" '$1=="KL" {n++; if ($2+0 > m) m=$2+0; s+=$2} END {print "keys=" n " max=" m " total=" s}' kp.err

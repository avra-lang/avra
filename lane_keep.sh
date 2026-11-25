#!/bin/bash
A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
find .avra-cache -mindepth 1 -delete
AVRA_QTRACE=1 $A check packages/cli >/dev/null 2>/tmp/tC.txt; echo "cold $?"
echo "cold keepdb:"; grep -a $'^Q\tkeepdb' /tmp/tC.txt | cut -f4 | sort | uniq -c
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration7 — write',1))"
AVRA_QTRACE=1 timeout 100 $A check packages/cli >/dev/null 2>/tmp/tA.txt; echo "edit $?"
cp /tmp/shared.orig $F
echo "edit keepdb by attempt:"; awk -F'\t' '/^Q\tattempt/{a=$3} /^Q\tkeepdb/{print a, $4}' /tmp/tA.txt | sort | uniq -c
echo "edit Db moved by attempt:"; awk -F'\t' '/^Q\tattempt/{a=$3} /^Q row moved i\tNamed\tDb/{print a, $0}' /tmp/tA.txt | cut -c1-80 | sort | uniq -c
echo "cold probe:"; grep -a $'^Q\tbucketprobe\tDb' /tmp/tC.txt | sort | uniq -c | cut -c1-80

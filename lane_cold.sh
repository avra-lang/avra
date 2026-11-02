#!/bin/bash
A=./build/avra-try
find .avra-cache -mindepth 1 -delete
s0=$(date +%s.%N); AVRA_QTRACE=1 $A check --time packages/cli >/tmp/oC.txt 2>/tmp/tC.txt; echo "cold $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
grep -a "^time" /tmp/oC.txt /tmp/tC.txt | cut -c1-700 | head -8
grep -a $'^Q\tattempt' /tmp/tC.txt
echo "kept typed: $(grep -ac $'^Q\tstore\tkeep' /tmp/tC.txt)"
grep -a $'^Q\tbucketprobe' /tmp/tC.txt | sed "s|/home/sprite/avra-build/avra-hd-saved/tree/packages/||g" | sort | uniq -c | sort -rn | cut -c1-800 | head -6

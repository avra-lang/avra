#!/bin/bash
A=./build/avra-try
find .avra-cache -mindepth 1 -delete
$A check packages/cli >/dev/null 2>&1; echo "cold $?"
s0=$(date +%s.%N); AVRA_QTRACE=1 $A check --time packages/cli >/tmp/oW.txt 2>/tmp/tW.txt; echo "warm $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
grep -a "^time" /tmp/oW.txt /tmp/tW.txt | cut -c1-500 | head -3
grep -a $'^Q\tattempt' /tmp/tW.txt
echo "restored $(grep -ac $'^Q\tsaved\trestored' /tmp/tW.txt) missed $(grep -ac $'^Q\tsaved\tmissed' /tmp/tW.txt) parses $(grep -ac $'^Q\tparse' /tmp/tW.txt)"
grep -a $'^Q\tbucketprobe' /tmp/tW.txt | sed "s|/home/sprite/avra-build/avra-hd-saved/tree/packages/||g" | sort | uniq -c | sort -rn | cut -c1-800 | head -6

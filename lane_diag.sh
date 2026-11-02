#!/bin/bash
A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
[ -n "$COLD" ] && { find .avra-cache -mindepth 1 -delete 2>/dev/null; s0=$(date +%s.%N); $A check packages/cli >/dev/null 2>&1; echo "cold $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"; }
s0=$(date +%s.%N); $A check packages/cli >/dev/null 2>&1; echo "warm $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration7 — write',1))"
s0=$(date +%s.%N); AVRA_QTRACE=1 timeout ${T:-90} $A check --time packages/cli > /tmp/o.txt 2>/tmp/t.txt; echo "traced exit $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
cp /tmp/shared.orig $F
grep -a "^time" /tmp/o.txt /tmp/t.txt | cut -c1-600
echo "parses $(grep -ac $'^Q\tparse' /tmp/t.txt) restored $(grep -ac $'^Q\tsaved\trestored' /tmp/t.txt) missed $(grep -ac $'^Q\tsaved\tmissed' /tmp/t.txt)"
grep -a $'^Q\tsaved\tmissed' /tmp/t.txt | cut -f5 | sort | uniq -c | sort -rn | head -12
echo "--- moved leaves"; grep -a "^Q row moved" /tmp/t.txt | awk '{print $4, $5}' | sort | uniq -c | sort -rn | head -12
echo "--- holds/attempt"; grep -a $'^Q\t\(attempt\|holds\|held\)' /tmp/t.txt | cut -c1-300 | head
echo "--- first parses"; grep -a $'^Q\tparse' /tmp/t.txt | head -8
echo "--- turn reads"; grep -a $'^Q\tturnread' /tmp/t.txt | cut -f3 | sort | uniq -c | sort -rn | head; grep -a $'^Q\tturnread' /tmp/t.txt | head -5
bash lane_diag2.sh

#!/bin/bash
A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
edit() { python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration$1 — write',1))"; }
find .avra-cache -mindepth 1 -delete
s0=$(date +%s.%N); $A check --time packages/cli >/tmp/oC.txt 2>&1; echo "cold $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
grep -a "^time" /tmp/oC.txt | tail -1 | grep -oE "bodies [0-9]+ms|analyze [0-9]+ms|lower [0-9]+ms|keep [0-9]+ms" | tr '\n' ' '; echo; du -sh .avra-cache
for i in 1 2 3; do
edit $i
s0=$(date +%s.%N); AVRA_QTRACE=1 timeout 150 $A check --time packages/cli >/tmp/o$i.txt 2>/tmp/e$i.txt; echo "edit$i $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s attempts $(grep -ac $'^Q\tattempt' /tmp/e$i.txt) restored $(grep -ac $'^Q\tsaved\trestored' /tmp/e$i.txt) missed $(grep -ac $'^Q\tsaved\tmissed' /tmp/e$i.txt) $(grep -aoE 'held [0-9]+/[0-9]+' /tmp/o$i.txt /tmp/e$i.txt | tail -1)"
grep -a $'^Q\tsaved\tmissed' /tmp/e$i.txt | cut -f5 | sort | uniq -c | sort -rn | head -4
done
for i in 4 5; do edit $i
s0=$(date +%s.%N); timeout 150 $A check --time packages/cli >/tmp/o$i.txt 2>&1; echo "untraced edit$i $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s $(grep -aoE 'held [0-9]+/[0-9]+' /tmp/o$i.txt | tail -1)"; done
cp /tmp/shared.orig $F
$A check packages/cli >/tmp/oW.txt 2>&1; echo "warm-orig $?"
find .avra-cache -mindepth 1 -delete
$A check packages/cli >/tmp/oC2.txt 2>&1; echo "cold-orig $?"
if diff <(grep -av "^time" /tmp/oW.txt) <(grep -av "^time" /tmp/oC2.txt) >/tmp/cw.diff; then echo "cold == warm output ($(wc -l < /tmp/oC2.txt) lines)"; else echo "cold != warm"; head -20 /tmp/cw.diff; fi
echo "== holdless: cold, 2 warm-ups, measured"
find .avra-cache -mindepth 1 -delete
$A check packages/cli >/dev/null 2>&1; echo "cold $?"
for i in 7 8; do edit $i; s0=$(date +%s.%N); AVRA_DB_VERIFY=none timeout 450 $A check packages/cli >/dev/null 2>&1; echo "holdless warm-up $i $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"; done
edit 9; s0=$(date +%s.%N); AVRA_DB_VERIFY=none timeout 450 $A check --time packages/cli >/tmp/o9.txt 2>&1; echo "holdless measured $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
grep -a "^time" /tmp/o9.txt | tail -1 | grep -oE "(resolve|bodies|analyze|lower|keep) [0-9]+ms" | tr '\n' ' '; echo
edit 10; AVRA_DB_VERIFY=none AVRA_QTRACE=1 timeout 450 $A check packages/cli >/dev/null 2>/tmp/e10.txt; echo "holdless traced $? restored $(grep -ac $'^Q\tsaved\trestored' /tmp/e10.txt) missed $(grep -ac $'^Q\tsaved\tmissed' /tmp/e10.txt)"
grep -a $'^Q\tsaved\tmissed' /tmp/e10.txt | cut -f5 | sort | uniq -c | sort -rn | head -6
cp /tmp/shared.orig $F

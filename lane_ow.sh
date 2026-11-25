#!/bin/bash
A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
find .avra-cache -mindepth 1 -delete
$A check packages/cli >/tmp/oC.txt 2>&1; echo "cold $?"
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration1 — write',1))"
s0=$(date +%s.%N); $A check --time packages/cli >/tmp/o1.txt 2>&1; echo "edit $? $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s $(grep -aoE 'held [0-9]+/[0-9]+' /tmp/o1.txt | tail -1)"
cp /tmp/shared.orig $F
$A check packages/cli >/tmp/oW.txt 2>&1; echo "warm $?"
if diff <(grep -av "^time" /tmp/oW.txt) <(grep -av "^time" /tmp/oC.txt) >/dev/null; then echo "cold == warm output ($(wc -l < /tmp/oC.txt) lines)"; else echo "cold != warm"; diff <(grep -av "^time" /tmp/oW.txt) <(grep -av "^time" /tmp/oC.txt) | head; fi
timeout 900 $A test packages/std-avrac/src/compiler > /tmp/ct.txt 2>&1; echo "compiler tests exit $?"; tail -5 /tmp/ct.txt

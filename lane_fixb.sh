A=./build/avra-try
F=packages/cli/src/commands/shared.av
cp $F /tmp/shared.orig
[ -n "$KEEP" ] || find .avra-cache -mindepth 1 -delete 2>/dev/null
[ -n "$KEEP" ] || $A check packages/cli >/dev/null 2>&1; echo "cold"
$A check packages/cli >/dev/null 2>&1; echo "warm $?"
for i in 1 2 3; do
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration$i — write',1))"
s0=$(date +%s.%N); timeout 200 $A check --time packages/cli > /tmp/o.txt 2>&1; e=$?; echo "body-edit-$i exit $e $(python3 -c "print(round($(date +%s.%N)-$s0,2))")s"
grep -a "^time" /tmp/o.txt | cut -c1-400
done
python3 -c "
import pathlib
p=pathlib.Path('$F'); s=open('/tmp/shared.orig').read()
p.write_text(s.replace(\"names no declaration — write\",'names no declaration9 — write',1))"
AVRA_QTRACE=1 timeout 200 $A check packages/cli > /dev/null 2>/tmp/t.txt; echo "traced exit $?"
echo "restored $(grep -ac $'^Q\tsaved\trestored' /tmp/t.txt) missed $(grep -ac $'^Q\tsaved\tmissed' /tmp/t.txt) attempts $(grep -ac $'^Q\tattempt' /tmp/t.txt)"
grep -a $'^Q\tsaved\tmissed' /tmp/t.txt | awk -F'\t' '{print $5}' | sort | uniq -c | sort -rn | head -8
grep -a $'^Q\tconst_verdict' /tmp/t.txt | awk -F'\t' '{print $4}' | sort | uniq -c
cp /tmp/shared.orig $F

#!/bin/bash
echo "--- Sig moved samples"; grep -a "^Q row moved i	Sig" /tmp/t.txt | sort | uniq -c | sort -rn | head -15
echo "--- Named moved samples"; grep -a "^Q row moved i	Named" /tmp/t.txt | sort | uniq -c | sort -rn | head -8
echo "--- before attempt 1"; n=$(grep -an $'^Q\tattempt\t1' /tmp/t.txt | head -1 | cut -d: -f1); sed -n "$((n-40)),$((n))p" /tmp/t.txt | grep -av $'^Q\t\(store\|ask\|settle\|db\)' | cut -c1-250
grep -a "^turn\|gave way\|turned" /tmp/o.txt /tmp/t.txt | head
echo "--- const verdicts"; grep -a $'^Q\tconst_verdict' /tmp/t.txt | cut -f4 | sort | uniq -c
echo "--- unkept readers (decoded)"; grep -a $'^Q\tturnread' /tmp/t.txt | cut -f3,4 | sort | uniq -c | sort -rn | python3 -c "
import sys,binascii
for l in list(sys.stdin)[:10]:
    p=l.rstrip().split('\t'); w=p[-1].split('~')
    try: print(p[0][:60], '|', binascii.unhexlify(w[0]).decode()[-60:], '|', binascii.unhexlify(w[1]).decode()[-60:] if len(w)>1 else '')
    except Exception as e: print(l[:150].rstrip())
"

#!/bin/bash
for e in e1 e2; do
n=$(grep -an $'^Q\tturnread' /tmp/$e.txt | head -1 | cut -d: -f1); [ -z "$n" ] && n=$(wc -l < /tmp/$e.txt)
echo "=== $e upto $n"
head -n $n /tmp/$e.txt | grep -a $'^Q\t\(const_verdict\|saved\t[a-z]*\t\)' | grep -av "restored" | awk -F'\t' '$2=="const_verdict"||$5!~/new/' | cut -c1-160 | sort | uniq -c | sort -rn | head -12
head -n $n /tmp/$e.txt | grep -a $'^Q\tconst_verdict' | cut -f3,4 | head -20 | tr '\n' ' '; echo
done
n=$(grep -an $'^Q\tturnread' /tmp/e2.txt | head -1 | cut -d: -f1)
head -n $n /tmp/e2.txt | grep -av $'^Q\t\(store\|db\|leaf\|turnread\)\|row moved\|\treuse' | tail -40 | cut -c1-200

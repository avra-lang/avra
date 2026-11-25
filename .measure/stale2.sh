#!/bin/sh
echo "// probe" >> packages/std-avrac/src/compiler/answers.av
make try > build/try.log 2>&1
echo "try status $? errors $(grep -c 'expected BREAK' build/try.log)"
ls .avra-cache/store
./avra cache log | tail -5
rev=$(./avra cache log | tail -1 | awk '{print $2}')
./avra cache show $rev > build/show.txt
echo "families at rev $rev:"; cut -f1 build/show.txt | sort | uniq -c | sort -rn | head -20
sha256sum build/avra build/avra-try 2>/dev/null
AVRA_QTRACE=1 ./avra check packages/cli > /dev/null 2> build/q.txt
echo "errors $(grep -a -c 'parse.expected' build/q.txt)"
grep -a '^Q	store	\(stamp\|open\)' build/q.txt | head -5
grep -a '^Q	store	kind	get	hit	answer' build/q.txt | cut -f4-8 | sed 's/#.*//' | sort | uniq -c | sort -rn | head -5

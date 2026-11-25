#!/bin/sh
echo "// probe" >> packages/std-avrac/src/compiler/answers.av
AVRA_QTRACE=1 make try > build/try.log 2>&1
echo "try status $? errors $(grep -a -c 'expected BREAK' build/try.log)"
echo "event kinds:"; grep -a '^Q	' build/try.log | cut -f2 | sort | uniq -c | sort -rn | head -12
echo "leaf lines:"; grep -a '^Q	leaf' build/try.log | cut -f2-4 | sort | uniq -c | sort -rn | head
echo "answer hits by query:"; grep -a '^Q	store	kind	get	hit	answer' build/try.log | cut -f6 | sed 's/#.*//' | sort | uniq -c | sort -rn | head -6
echo "answer misses by query:"; grep -a '^Q	store	kind	get	miss	answer' build/try.log | cut -f6 | sed 's/#.*//' | sort | uniq -c | sort -rn | head -6
echo "stamps:"; grep -a '^Q	store	\(stamp\|open\)' build/try.log | cut -c1-120 | head -8

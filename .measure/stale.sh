#!/bin/sh
echo "// probe" >> packages/std-avrac/src/compiler/answers.av
AVRA_QTRACE=1 make try > build/try.log 2>&1
echo "try status $?"
grep -c "expected BREAK" build/try.log
grep '^Q	store	\(stamp\|open\)' build/try.log | sort | uniq -c | head
grep '^Q	store	kind	[a-z]*	hit	answer' build/try.log | cut -f3-7 | sort | uniq -c | sort -rn | head -8
grep -o 'own [0-9a-f]*\.[0-9a-f]*' build/try.log | sort | uniq -c | head
ls .avra-cache/store | head -20

#!/bin/sh
set -u
[ -d build/cold_q ] && find build/cold_q -delete
AVRA_CACHE_DIR=build/cold_q AVRA_QTRACE=1 build/avra.tip check packages/cli > /dev/null 2> build/cold_q.q
grep -an "^Q	attempt" build/cold_q.q | head
echo "-- process parse/declare/mint lines (first 12)"
grep -anE "std-process" build/cold_q.q | grep -aE "Q	(parse|declare|mint)" | head -12
echo "-- stage.av parse"
grep -anE "Q	parse.*cli/src/stage.av" build/cold_q.q | head
echo "-- first declare of status_of"
grep -anE "Q	declare	status_of" build/cold_q.q | head -3
echo "-- named_type_fail in attempt 0, top"
awk -F'\t' 'NR<'"$(grep -an '^Q	attempt	1' build/cold_q.q | head -1 | cut -d: -f1)"' && $2=="named_type_fail"{print $3, $4}' build/cold_q.q | sort | uniq -c | sort -rn | head -8

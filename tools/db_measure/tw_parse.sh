#!/bin/sh
# THE tw EDIT, TRACED: the four-file fixture of cache_attacks.sh's `tw`, one unused fn's body
# moved to fresh text, and every file QTRACE says was parsed.
#
#   AVRA_BIN=build/avra-try sh tools/db_measure/tw_parse.sh
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
A=${AVRA_BIN:-build/avra}
R=build/tw-parse
find "$R" -mindepth 1 -delete 2>/dev/null
mkdir -p $R/src/f $R/src/x $R/src/y
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/src/main.av
"$A" check $R > /dev/null 2>&1
"$A" check $R > /dev/null 2>&1
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + %s }\n' "$(date +%s)" > $R/src/y/calc.av
AVRA_QTRACE=1 "$A" check --time $R > $R/out.txt 2> $R/q.txt
echo "exit $?"
echo "files parsed: $(awk -F'\t' '$1=="Q" && $2=="parse"' $R/q.txt | grep -c .)"
awk -F'\t' '$1=="Q" && $2=="parse" {print "  " $3}' $R/q.txt | sed 's#.*/build/tw-parse/#  #'
awk -F'\t' '$1=="Q" && $2=="said" {n[$3]++} END{for(k in n) print "said", k, n[k]}' $R/q.txt
grep -E '^time:|defect' $R/out.txt $R/q.txt | cut -c1-300 | tail -3

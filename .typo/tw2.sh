R=/tmp/twr2; find $R -delete 2>/dev/null; mkdir -p $R/tw/src/f $R/tw/src/x $R/tw/src/y
AV=$PWD/build/avra-try
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/tw/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/tw/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/tw/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/tw/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/tw/src/main.av
AVRA_QTRACE=1 $AV check $R/tw >/dev/null 2>$R/trace0; $AV build $R/tw >/dev/null 2>&1
python3 - <<'PY'
p='/tmp/twr2/tw/src/y/calc.av'; s=open(p).read(); open(p,'w').write(s.replace("n + 1","n + 7",1))
PY
AVRA_DB_GRAPH=1 AVRA_QTRACE=1 $AV check --counts $R/tw 2>$R/trace >$R/out; head -12 $R/out | cut -c1-200
echo "-- parses"; grep "^Q.parse" $R/trace | sort | uniq -c | cut -c1-120
echo "-- asks that computed, by family"; grep "^Q.ask.*compute" $R/trace | awk -F'\t' '{print $3}' | sort | uniq -c | sort -rn | head -12
echo "-- askers of Parsed"; python3 .typo/askers.py $R/trace
echo "-- said standing (second check, after the edit)"; grep -a "^Q.said" $R/trace | awk -F"\t" '{print $3, $4}' | sed "s#/tmp/twr2/tw/##;s#/home/sprite/avra-build/avra-typo/tree/##"
echo "-- cold: FileSaid reads"; grep -a "^Q.reads.FileSaid" $R/trace0 | cut -c1-200 | head -6
echo "-- cold: reads by family"; grep -a "^Q.reads" $R/trace0 | cut -f3,4,5 | head -30
echo "-- restore misses"; grep -a "^Q.restore\|^Q.saved" $R/trace | cut -c1-220 | sort | uniq -c | sort -rn | head -14
echo "-- cold FileSaid read lists"; grep -a "^Q.detail" $R/trace0 | sed "s/^Q.detail.//" | tr "\t" "~" | cut -c1-700

echo "-- cold env probes"; grep -a "^Q.env" $R/trace0 | sed "s/^Q.env.//" | tr "\t" "~" | tr "|" "\n" | sed "s/~/ /g" | cut -c1-200 | head -80

R=/tmp/vr-tw-$$
mkdir -p $R/src/f $R/src/x $R/src/y
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/src/main.av
echo "== cold"; ./avra-try check $R 2>&1 | tail -3; echo "exit $?"
echo "== warm same (verify)"; ./avra-try check $R 2>&1 | tail -4; echo "exit ${PIPESTATUS:-?}"
sed -i 's/n + 1/n + 7/' $R/src/y/calc.av
echo "== edit unreached (verify)"
AVRA_VERIFY_REVIVE=1 AVRA_QTRACE=1 ./avra-try check $R > /tmp/vr1.txt 2>&1; echo "exit $?"
grep -c "" /tmp/vr1.txt; grep "^Q.verify" /tmp/vr1.txt | sort | uniq -c | head -20; grep -v "^Q" /tmp/vr1.txt | head -12 | cut -c1-240
sed -i 's/n \* 2/n * 3/' $R/src/y/calc.av
echo "== edit read decl (verify)"
AVRA_VERIFY_REVIVE=1 AVRA_QTRACE=1 ./avra-try check $R > /tmp/vr2.txt 2>&1; echo "exit $?"
grep "^Q.verify" /tmp/vr2.txt | sort | uniq -c | head -20; grep -v "^Q" /tmp/vr2.txt | head -12 | cut -c1-240

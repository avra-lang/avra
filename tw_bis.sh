R=/tmp/vr-bis-$$
mkdir -p $R/src/f $R/src/x $R/src/y
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/src/main.av
./avra-try check $R > /tmp/bis0.txt 2>&1; echo "cold exit $?"
sed -i 's/n + 1/n + 7/' $R/src/y/calc.av
./avra-try check $R > /tmp/bis1.txt 2>&1; echo "edit1 exit $?"
grep -c "" /tmp/bis1.txt; grep -m3 "defect\|use_before_def\|unresolved\|^error" /tmp/bis1.txt | cut -c1-200
sed -i 's/n \* 2/n * 3/' $R/src/y/calc.av
./avra-try check $R > /tmp/bis2.txt 2>&1; echo "edit2 exit $?"; grep -m3 "defect\|use_before_def\|unresolved\|^error" /tmp/bis2.txt | cut -c1-200

R=/tmp/trr; find $R -delete 2>/dev/null; mkdir -p $R/tw/src/f $R/tw/src/x $R/tw/src/y
AV=$PWD/build/avra-try
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/tw/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/tw/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/tw/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/tw/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/tw/src/main.av
$AV check $R/tw >/dev/null 2>&1; echo cold=$?; $AV build $R/tw >/dev/null 2>&1; echo build=$?
python3 - <<'PY'
p='/tmp/trr/tw/src/y/calc.av'; s=open(p).read(); open(p,'w').write(s.replace("n + 1","n + 7",1))
PY
$AV check $R/tw > $R/out1 2>&1; echo edit1=$?; tail -5 $R/out1 | cut -c1-300
printf '// c\n' >> $R/tw/src/y/calc.av; $AV check $R/tw > $R/out2 2>&1; echo comment=$?; tail -5 $R/out2 | cut -c1-300

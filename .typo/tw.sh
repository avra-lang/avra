R=/tmp/twr; find $R -delete 2>/dev/null; mkdir -p $R
ed() { python3 - "$1" "$2" "$3" <<'PY'
import sys; p,a,b=sys.argv[1:]; s=open(p).read(); open(p,'w').write(s.replace(a,b,1))
PY
}
mkdir -p $R/tw/src/f $R/tw/src/x $R/tw/src/y
printf '[package]\nname = "rt-tw"\nversion = "0.1.0"\n' > $R/tw/avra.toml
printf 'export fn twice(n: int) -> int { n * 2 }\nexport fn unused(n: int) -> int { n + 1 }\n' > $R/tw/src/y/calc.av
printf 'use y.{twice}\nexport const J: int = twice(3)\n' > $R/tw/src/x/mid.av
printf 'use x.{J}\nexport const K: int = J * 2\nexport fn shown() -> int { K }\n' > $R/tw/src/f/held.av
printf 'use f.{shown}\nprintln("${shown()}")\n' > $R/tw/src/main.av
./avra check $R/tw >/dev/null 2>&1; ./avra build $R/tw >/dev/null 2>&1
ed $R/tw/src/y/calc.av "n + 1" "n + 7"
AVRA_QTRACE=1 ./avra check --time $R/tw 2>$R/trace; grep -E "^time|^read|^  " $R/trace | head
grep -E "PROBE|^Q.attempt|suspects" $R/trace | head -40

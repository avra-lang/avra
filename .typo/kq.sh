R=/tmp/kqr; find $R -delete 2>/dev/null; mkdir -p $R
ed() { python3 - "$1" "$2" "$3" <<'PY'
import sys; p,a,b=sys.argv[1:]; s=open(p).read(); open(p,'w').write(s.replace(a,b,1))
PY
}
mkdir -p $R/kq/src/f $R/kq/src/x
printf '[package]\nname = "rt-kq"\nversion = "0.1.0"\n' > $R/kq/avra.toml
printf 'export const A: int = 1\nexport const B: int = 2\nexport const C: int = 3\n' > $R/kq/src/x/vals.av
printf 'use x.{B, C}\nexport const V: int = B * 10\nexport fn shows() -> int { C }\n' > $R/kq/src/f/readers.av
printf 'use f.{V, shows}\nprintln("${V} ${shows()}")\n' > $R/kq/src/main.av
./avra check $R/kq >/dev/null 2>&1; ./avra build $R/kq >/dev/null 2>&1
printf '// moved\n' >> $R/kq/src/main.av; ./avra check $R/kq >/dev/null 2>&1
ed $R/kq/src/x/vals.av "A: int = 1" "A: int = 9"; ./avra check $R/kq >/dev/null 2>&1; ./avra build $R/kq >/dev/null 2>&1
ed $R/kq/src/x/vals.av "C: int = 3" "C: int = 4"
AVRA_QTRACE=1 ./avra check --time $R/kq 2>$R/trace | grep -E "^time|^read|^  "
grep -E "const_verdict.*ran|^Q.attempt" $R/trace

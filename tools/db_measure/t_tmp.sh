export AVRA_BIN=build/avra
R=build/consts-fix; mv $R $R.aside.$$ 2>/dev/null; mkdir -p $R/src
printf '[package]\nname = "consts-fix"\nversion = "0.1.0"\n' > $R/avra.toml
python3 - <<'PY'
n=1000
lines=["fn twice(x: int) -> int { x * 2 }",""]
for i in range(n):
    lines.append(f"const C{i}: int = twice({i})")
lines += ["", "println(\"${C0 + C999}\")"]
open("build/consts-fix/src/main.av","w").write("\n".join(lines)+"\n")
PY
mv .avra-cache .avra-cache.aside.$$ 2>/dev/null
tm() { s=$(date +%s%N); AVRA_QTRACE=1 ./avra check $R > build/cf.out 2> build/cf.err; st=$?; e=$(date +%s%N); echo "$1: exit $st $(( (e-s)/1000000 )) ms | $(grep -c 'const_verdict.*stood' build/cf.err) stood $(grep -c 'const_verdict.*ran' build/cf.err) ran"; }
tm cold
tm unchanged
printf '// a comment\n' | cat - $R/src/main.av > build/cf.new && cp build/cf.new $R/src/main.av
tm "comment above"
cp build/cf.new $R/src/main.av; printf '\n// tail\n' >> $R/src/main.av
tm "comment below"
python3 - <<'PY'
p="build/consts-fix/src/main.av"; t=open(p).read().replace("x * 2","x * 3"); open(p,"w").write(t)
PY
tm "body of twice edited"

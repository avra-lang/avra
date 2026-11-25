D=/tmp/edr; find $D -delete 2>/dev/null; mkdir -p $D/src
printf '[package]\nname = "ed"\nversion = "0.1.0"\n\n[bin]\nname = "ed"\npath = "src/main.av"\n' > $D/avra.toml
for i in 1 2 3 4 5 6 7 8; do printf 'export fn f%s(n: int) -> int { n + %s }\n' $i $i > $D/src/m$i.av; done
printf 'use m1.{f1}\nuse m2.{f2}\nuse m3.{f3}\nuse m4.{f4}\nuse m5.{f5}\nuse m6.{f6}\nuse m7.{f7}\nuse m8.{f8}\nfn main() { let x = f1(1) + f2(1) + f3(1) + f4(1) + f5(1) + f6(1) + f7(1) + f8(1) }\n' > $D/src/main.av
AV=$PWD/build/avra-try
run() { s=$(date +%s%N); AVRA_QTRACE=1 $AV check --time $D 2>$D/t.$1 >$D/o.$1; st=$?; e=$(date +%s%N); printf '%s status=%s %sms typed_computes=%s parses=%s lowered=%s attempts=%s\n' $1 $st $(( (e-s)/1000000 )) $(grep -c '^Q.ask.Typed.*compute' $D/t.$1) $(grep -c '^Q.parse' $D/t.$1) $(grep -c 'unit.lowered' $D/t.$1) $(grep -c '^Q.attempt' $D/t.$1); }
run cold; run unchanged
printf 'export fn f3(n: int) -> int { n + 33 }\n' > $D/src/m3.av; run body_edit
printf 'export fn f3(n: int) -> int { n + 34 }\n' > $D/src/m3.av; run body_edit2
printf 'export fn f3(n: string) -> string { n }\n' > $D/src/m3.av; run sig_edit

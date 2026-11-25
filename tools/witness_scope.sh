# One fixture package, every path shape `avra test` takes, each exit status and output.
T=$(pwd); R=$(mktemp -d)/scoped
mkdir -p $R/src/tests/good $R/src/tests/wrong $R/src/tests/trap
printf '[package]\nname = "scoped"\nversion = "0.1.0"\n' > $R/avra.toml
printf 'export fn plain() -> int { 1 }\n' > $R/src/plain.av
printf 'spec "sum" { given "two" { then "adds" { 1 + 2 == 3 } } }\n' > $R/src/tests/sum_test.av
printf 'println("good")\n' > $R/src/tests/good/good.av; printf 'good\n' > $R/src/tests/good/good.expected
printf 'println("right")\n' > $R/src/tests/wrong/wrong.av; printf 'wrong\n' > $R/src/tests/wrong/wrong.expected
printf 'let missing: int? = null\nmissing!\n' > $R/src/tests/trap/trap.av; printf 'unwrapped an absent value\n' > $R/src/tests/trap/trap.refuses
cd $R
for p in src/tests/wrong/wrong.av src/tests/good/good.av src/tests/trap/trap.av src/tests/sum_test.av src/tests/good src/plain.av src/absent.av; do
  echo "=== avra test $p"
  AVRA_CWD=$R $T/build/avra test $p > out 2> err; st=$?
  sed 's/^/  out: /' out; sed 's/^/  err: /' err; echo "  exit: $st"
done

B=$PWD; T=$(mktemp -d); cp tools/cse-probe/*.av $T/; cd $T
for f in ${FILES:-a b b3 c d e}; do
  echo "== $f"
  AVRA_ALIAS_LOG=1 $B/build/avra run $f.av > out.$f 2> err.$f; echo "run exit $? $(cat out.$f) clones $(grep -c ALIAS_CLONE err.$f)"
  $B/build/avra build $f.av > bout.$f 2>&1 || { echo build failed; head -5 bout.$f; continue; }
  AVRA_ALIAS_LOG=1 ./$f > nout.$f 2> nerr.$f; echo "native exit $? $(cat nout.$f) clones $(grep -c ALIAS_CLONE nerr.$f)"
done

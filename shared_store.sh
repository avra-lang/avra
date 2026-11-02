# usage: sh shared_store.sh <label> — the builder fills the store building the cli, then build/avra-try checks over it
find .avra-cache -mindepth 1 -delete
make try > /tmp/try.out 2>&1 || { echo "$1 try failed"; grep -a "^error" -A4 /tmp/try.out | head; exit 1; }
for p in packages/std-avrac packages/cli; do
  for i in 1 2; do ./build/avra-try check $p > /tmp/ss.out 2>&1; echo "$1 $p run $i: exit $? errors $(grep -ac '^error' /tmp/ss.out)"; done
done

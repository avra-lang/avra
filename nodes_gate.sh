F=$(git -C . diff --name-only 2>/dev/null | grep '\.av$')
[ -n "$F" ] || F="$NODES_FILES"
echo "== fmt"; build/avra fmt --check $F; echo "fmt $?"
echo "== suites"; for d in $NODES_SUITES; do ./avra test $d 2>&1 | tail -n 2; done
echo "== idioms"; build/avra check packages/std-avrac --baseline tools/idioms.baseline 2>&1 | tail -n 4
echo "== cache-attacks"; make -s cache-attacks 2>&1 | tail -n 4

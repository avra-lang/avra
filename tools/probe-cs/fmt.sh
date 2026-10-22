for f in "$@"; do cp $f /tmp/x.av; build/avra fmt --write /tmp/x.av >/dev/null 2>&1; diff $f /tmp/x.av && echo "ok $f"; done

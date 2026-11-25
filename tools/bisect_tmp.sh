#!/bin/sh
d=packages/std-avrac/src/features/collects/tests/delegated_package_two_derived
make -s try 2>&1 | tail -1
for b in build/avra ./avra-try; do
  n=$(basename $b)
  find .avra-cache -delete 2>/dev/null
  AVRA_QTRACE=1 $b check $d > /dev/null 2> /tmp/tr.$n
  echo "== $n"
  grep -a -c 'Q.attempt' /tmp/tr.$n
  grep -a 'Q.attempt\|kept-settle\|Q.store.sealed\|Q.store.hit.unit\|Q.store.miss.unit' /tmp/tr.$n | cut -c1-160 | head -40
done

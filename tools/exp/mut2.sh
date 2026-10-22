#!/bin/sh
[ -d tools ] || exit 70
f=packages/std-db/src/migrate.av
cp $f /tmp/mig.good
try() {
  sed "$1" /tmp/mig.good > $f
  find .avra-cache.aside.* -delete 2>/dev/null
  [ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
  build/avra test packages/std-db/src/tests/migrate_test.av > /tmp/m2.log 2>&1
  echo "== $2"; grep -a "✗\|passed" /tmp/m2.log | cut -c1-150 | head -4
}
try 's/hint = renames.find(it.to == d.name \&\& has(had, it.from))/hint = renames.find(it.to == d.name)/' "ghost hint renames"
cp /tmp/mig.good $f
build/avra test packages/std-db/src/tests/migrate_test.av 2>&1 | grep -a "passed\|✗"

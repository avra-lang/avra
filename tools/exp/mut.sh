#!/bin/sh
[ -d tools ] || exit 70
f=packages/std-http/src/route.av
cp $f /tmp/route.good
try() {
  cp /tmp/route.good $f
  sed "$1" /tmp/route.good > $f
  find .avra-cache.aside.* -delete 2>/dev/null
  [ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
  build/avra test packages/std-http/src/tests/route_test.av > /tmp/m.log 2>&1
  echo "== $2"; grep -a "✗\|passed\|error" /tmp/m.log | cut -c1-170 | head -6; tail -2 /tmp/m.log | cut -c1-170
}
try 's/if takes_rest(r.reach) \&\& !marks_rest(r.pattern) {/if false {/' "Unmarked off"
try 's/if r.reach == Reach.Width \&\& marks_rest(r.pattern) {/if false {/' "Unclaimed off"
try 's/if above != null { .Overlap/if false { .Overlap/' "Overlap off"
cp /tmp/route.good $f

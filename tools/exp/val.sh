#!/bin/sh
[ -d tools ] || exit 70
find .avra-cache.aside.* -delete 2>/dev/null
[ -d .avra-cache ] && mv .avra-cache .avra-cache.aside.$$
for p in std-db; do build/avra check packages/$p > /tmp/v.$p.log 2>&1; echo "check $p status $?"; grep -a "^error" -A7 /tmp/v.$p.log | head -40 | cut -c1-220; done
for p in std-db; do build/avra test packages/$p > /tmp/vt.$p.log 2>&1; echo "test $p status $?"; grep -a -v "^warning\|^ \|^[0-9]* │\|^─\|^$\|^help\|^proofs\|^avra:" /tmp/vt.$p.log | tail -12 | cut -c1-220; done

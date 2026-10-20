set -u
mkdir -p /tmp/aside && mv .avra-cache /tmp/aside/u$$ 2>/dev/null
AVRA_QTRACE=1 build/avra check --counts packages/cli 2>/tmp/p273.q >/dev/null
grep -a "^counts" /tmp/p273.q | tr ' ' '\n' | grep -a "typed_comp\|queries_computed="
grep -a "^Q.typed" /tmp/p273.q | cut -f2,3,4 | sort | uniq -c | sort -rn | head -8
wc -l /tmp/p273.q

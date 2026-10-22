mkdir -p /tmp/cs && cp tools/probe-cs/thaw.av /tmp/cs/
for c in /home/sprite/avra-compilers/$1/avra build/avra; do
  [ -x $c ] || { echo "no $c"; continue; }
  cp $c build/avra.probe; rm -rf /tmp/cs/.avra-cache
  echo "== $c"; build/avra.probe ir /tmp/cs/thaw.av | grep -n "slot_get\|thawed\|slot_set" | head -6
  AVRA_RC_GUARD=1 build/avra.probe run /tmp/cs/thaw.av 2>&1 | tail -2
  build/avra.probe build /tmp/cs/thaw.av >/dev/null 2>&1; AVRA_RC_GUARD=1 /tmp/cs/thaw 2>&1 | tail -2
done

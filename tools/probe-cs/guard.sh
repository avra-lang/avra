set -u
mkdir -p /tmp/cs && cp tools/probe-cs/*.av /tmp/cs/
rm -rf .avra-cache /tmp/cs/.avra-cache
echo "== eval, guarded"; AVRA_RC_GUARD=1 AVRA_MEM_STATS=1 build/avra run /tmp/cs/set_at.av 2>&1 | grep -vE "^mem:   "
echo "exit $?"
build/avra build /tmp/cs/set_at.av >/tmp/cs/b.out 2>&1 || tail /tmp/cs/b.out
echo "== native, guarded"; AVRA_RC_GUARD=1 AVRA_MEM_STATS=1 /tmp/cs/set_at 2>&1 | grep -vE "^mem:   "
echo "== ir"; build/avra ir /tmp/cs/set_at.av | grep -n "slot_get\|slot_set" | head -30

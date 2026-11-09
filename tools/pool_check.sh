#!/bin/sh
# THE MEMORY POOL, held to what it promises, with real processes: a run needing more than the whole
# pool refuses in its own words; a run inside it finishes; a run that finds the pool held waits for
# it and then finishes. Each case gets a pool of its own, so no real run's slots are touched.
set -u
cd "$(dirname "$0")/.."
probe_dir=tools/pool
pools=$(mktemp -d "${TMPDIR:-/tmp}/avra-pool-check.XXXXXX")
trap 'find "$pools" -delete 2>/dev/null' EXIT
./avra build "$PWD/$probe_dir" >/dev/null 2>"$pools/build.log" || { cat "$pools/build.log"; echo "pool: the probe does not build"; exit 1; }
probe=$probe_dir/src/main
failed=0
said() { echo "pool: $1"; }

mkdir "$pools/over"
out=$(AVRA_MEM_POOL_DIR="$pools/over" AVRA_MEM_POOL_MB=512 POOL_MB=1500 "$probe" 2>&1)
case "$out" in *"needs more than the machine's whole memory pool"*) said "a run over the whole pool refuses";; *) said "FAIL: a run over the whole pool did not refuse: $out"; failed=1;; esac

mkdir "$pools/inside"
out=$(AVRA_MEM_POOL_DIR="$pools/inside" AVRA_MEM_POOL_MB=2048 POOL_MB=300 "$probe" 2>&1)
case "$out" in *"done 37499999"*) said "a run inside the pool finishes";; *) said "FAIL: a run inside the pool: $out"; failed=1;; esac

mkdir "$pools/shared"
AVRA_MEM_POOL_DIR="$pools/shared" AVRA_MEM_POOL_MB=512 POOL_MB=500 HOLD_MS=3000 "$probe" >"$pools/first.out" 2>&1 &
first=$!
sleep 1
second=$(AVRA_MEM_POOL_DIR="$pools/shared" AVRA_MEM_POOL_MB=512 POOL_MB=300 "$probe" 2>&1)
wait "$first"
case "$second" in *"waiting for memory"*"done 37499999"*) said "a run finding the pool held waits, then finishes";; *) said "FAIL: a run finding the pool held: $second"; failed=1;; esac
grep -q "done 62499999" "$pools/first.out" || { said "FAIL: the run holding the pool: $(cat "$pools/first.out")"; failed=1; }

[ "$failed" = 0 ] && said "3 cases held" && exit 0
exit 1

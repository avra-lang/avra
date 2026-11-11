#!/bin/sh
# THE MEMORY POOL, held to what it promises, with real processes: a run needing more than the whole
# pool refuses in its own words; a run inside it finishes; a run that finds the pool held waits for
# it and then finishes; a run past its peak holds only what it still uses, for the child it waits on
# and for any other run. Each case gets a pool of its own, so no real run's slots are touched.
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
AVRA_MEM_POOL_DIR="$pools/shared" AVRA_MEM_POOL_MB=1024 POOL_MB=400 HOLD_MS=3000 "$probe" >"$pools/first.out" 2>&1 &
first=$!
sleep 1
second=$(AVRA_MEM_POOL_DIR="$pools/shared" AVRA_MEM_POOL_MB=1024 POOL_MB=300 "$probe" 2>&1)
wait "$first"
case "$second" in *"waiting for memory"*"done 37499999"*) said "a run finding the pool held waits, then finishes";; *) said "FAIL: a run finding the pool held: $second"; failed=1;; esac
grep -q "done 49999999" "$pools/first.out" || { said "FAIL: the run holding the pool: $(cat "$pools/first.out")"; failed=1; }

# A run past its peak holds what it uses: a 400 MB list made and dropped, in a pool of four slots.
# At its peak it holds three, so a child needing three finds one free and is refused at its wait,
# unless the dropped list's slots went back.
mkdir "$pools/peak"
out=$(AVRA_MEM_POOL_DIR="$pools/peak" AVRA_MEM_POOL_MB=1024 AVRA_MEM_POOL_WAIT_MS=2000 PEAK_MB=400 CHILD_MB=300 POOL_MB=1 POOL_SELF="$PWD/$probe" "$probe" 2>&1)
case "$out" in *"child 0: allocated 37500000"*"done 37499999"*) said "a run past its peak lets the child it waits on take its slots";; *) said "FAIL: a run past its peak kept its slots from its child: $out"; failed=1;; esac

# The same peak, then idle: another run needing three slots finishes while it still lives.
mkdir "$pools/idle"
AVRA_MEM_POOL_DIR="$pools/idle" AVRA_MEM_POOL_MB=1024 PEAK_MB=400 POOL_MB=1 HOLD_MS=6000 "$probe" >"$pools/idle.out" 2>&1 &
idle=$!
n=0
until grep -q "allocated" "$pools/idle.out" || [ "$n" -ge 50 ]; do sleep 0.1; n=$((n + 1)); done
other=$(AVRA_MEM_POOL_DIR="$pools/idle" AVRA_MEM_POOL_MB=1024 AVRA_MEM_POOL_WAIT_MS=2000 POOL_MB=300 "$probe" 2>&1)
alive=0; kill -0 "$idle" 2>/dev/null && alive=1
wait "$idle"
case "$alive:$other" in 1:*"done 37499999"*) said "an idle run past its peak lets another run take its slots";; *) said "FAIL: an idle run past its peak kept its slots (idle alive: $alive): $other"; failed=1;; esac
grep -q "done 124999" "$pools/idle.out" || { said "FAIL: the idle run: $(cat "$pools/idle.out")"; failed=1; }

[ "$failed" = 0 ] && said "5 cases held" && exit 0
exit 1

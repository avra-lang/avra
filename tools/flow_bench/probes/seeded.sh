#!/bin/sh
# THE SEEDED PICK, MEASURED: that a production switch is the one it was
# (the hot leaves' instructions against a base scheduler, and the C
# bench's rows beside it), and what a seeded switch costs.
#
#   sh tools/flow_bench/probes/seeded.sh <base avra_fiber.c>
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../.." && pwd)
base=${1:?the scheduler to compare against, as a file}
out=$root/build/flow-bench/seeded
rounds=${ROUNDS:-5}
mkdir -p "$out"
probes=""
[ "$(uname -s)" = Darwin ] || probes=-fstack-clash-protection
rest=""
for c in "$root"/runtime/*.c; do
    [ "$(basename "$c")" = avra_fiber.c ] && continue
    cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/$(basename "$c" .c).o" "$c"
    rest="$rest $out/$(basename "$c" .c).o"
done
cp "$base" "$out/base_fiber.c"
cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/fiber_base.o" "$out/base_fiber.c"
cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/fiber_today.o" "$root/runtime/avra_fiber.c"

echo "== $(uname -srm), $(cc --version | head -1)"
echo "== hot leaves: instructions in the base / today / lines that differ"
for fn in avra_fiber_yield avra_wait_park avra_gate_claim avra_fiber_sleep avra_task_join avra_task_spawn avra_fiber_park_fd avra_vtask_next; do
    for which in base today; do
        objdump -d --no-show-raw-insn "$out/fiber_$which.o" | awk -v fn="$fn" '
            /^[0-9a-f]+ <.*>:$/ { on = ($2 == "<" fn ">:" || $2 == "<_" fn ">:") ; next }
            on && /^ +[0-9a-f]+:/ { sub(/^ *[0-9a-f]+:[ \t]*/, ""); gsub(/0x[0-9a-f]+/, "ADDR"); gsub(/<[^>]*>/, ""); gsub(/[ \t]+[0-9a-f]+[ \t]*$/, " ADDR"); print }' > "$out/$which.$fn.s"
    done
    echo "$fn $(wc -l < "$out/base.$fn.s") $(wc -l < "$out/today.$fn.s") $(diff "$out/base.$fn.s" "$out/today.$fn.s" | grep -c '^[<>]' || true)"
done

for which in base today; do
    cc -O2 -I"$root/runtime" -o "$out/spawn_bench_$which" "$here/spawn_bench.c" "$out/fiber_$which.o" $rest
    cc -O2 -I"$root/runtime" -o "$out/latency_bench_$which" "$here/latency_bench.c" "$out/fiber_$which.o" $rest
done
cc -O2 -I"$root/runtime" -o "$out/seeded_bench" "$here/seeded_bench.c" "$out/fiber_today.o" $rest

# `<key> <total> <count>` lines of several rounds, as the least per key.
least() {
    awk '{ v = $2 / $3; if (!($1 in best) || v < best[$1]) best[$1] = v; if (!($1 in at)) { at[$1] = ++n; name[n] = $1 } }
         END { for (i = 1; i <= n; i++) printf (best[name[i]] < 1 ? "  %-44s %.4f\n" : "  %-44s %.1f\n"), name[i], best[name[i]] }'
}
echo "== the C bench's rows, ns a unit, least of $rounds: base then today"
for which in base today; do
    echo "-- $which"
    for r in $(seq "$rounds"); do
        "$out/spawn_bench_$which" c
        "$out/spawn_bench_$which" c within
        "$out/spawn_bench_$which" c gate
        "$out/latency_bench_$which" c
    done | least
done
echo "== a seeded switch beside the queue's own, ns a switch (polls: asked per switch), least of $rounds"
for r in $(seq "$rounds"); do "$out/seeded_bench"; done | grep -v warmup | least

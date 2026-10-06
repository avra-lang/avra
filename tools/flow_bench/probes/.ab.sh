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

git_base_rt=${2:?the base avra_runtime.c}
cc -c -O2 -fPIC $probes -I"$root/runtime" -o "$out/rt_base.o" -x c "$git_base_rt"
for which in base today; do
    o=$out/rt_base.o; [ $which = today ] && o=$out/avra_runtime.o
    objdump -d --no-show-raw-insn "$o" | awk '/^[0-9a-f]+ <_?avra_now_ns>:$/ { on = 1; next } /^[0-9a-f]+ </ { on = 0 } on && /^ +[0-9a-f]+:/ { n++ } END { print "avra_now_ns instructions:", n }'
done
for which in base today; do
    cc -O2 -I"$root/runtime" -o "$out/spawn_bench_$which" "$here/spawn_bench.c" "$out/fiber_$which.o" $rest
    cc -O2 -I"$root/runtime" -o "$out/latency_bench_$which" "$here/latency_bench.c" "$out/fiber_$which.o" $rest
done

# `<key> <total> <count>` lines of several rounds: least and median per key.
stats() {
    awk '{ v = $2 / $3; k = $1; n[k]++; vals[k, n[k]] = v; if (!(k in at)) { at[k] = ++m; name[m] = k } }
         END { for (i = 1; i <= m; i++) { k = name[i]; c = n[k];
                 for (a = 1; a <= c; a++) for (b = a + 1; b <= c; b++) if (vals[k, b] < vals[k, a]) { x = vals[k, a]; vals[k, a] = vals[k, b]; vals[k, b] = x }
                 printf "  %-34s least %10.1f  median %10.1f\n", k, vals[k, 1], vals[k, int((c + 1) / 2)] } }'
}
echo "== the C bench's rows, ns a unit, $rounds rounds, base and today ALTERNATED"
: > "$out/base.rows"; : > "$out/today.rows"
for r in $(seq "$rounds"); do
    for which in base today; do
        { "$out/spawn_bench_$which" c; "$out/spawn_bench_$which" c within; "$out/spawn_bench_$which" c gate; "$out/latency_bench_$which" c; } >> "$out/$which.rows"
    done
done
for which in base today; do echo "-- $which"; grep -v "bursts\|latency_busy\|meanwhile" "$out/$which.rows" | stats; done

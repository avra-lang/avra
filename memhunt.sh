#!/bin/bash
# Cold then warm `make try`-shaped build of packages/cli, with max RSS, a per-process RSS sampler,
# and AVRA_MEM_STATS with symbolized sites.
set -u
cd "$(git rev-parse --show-toplevel)"
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
memtime() {
    python3 -c '
import resource, subprocess, sys, time
t = time.time()
st = subprocess.call(sys.argv[1:])
r = resource.getrusage(resource.RUSAGE_CHILDREN)
sys.stderr.write("Maximum resident set size (kbytes): %d\nElapsed (wall clock) time: %.1fs\n" % (r.ru_maxrss, time.time() - t))
sys.exit(st)
' "$@"
}
# THE BUILDER: the gate's Linux compiler (program b5a71497), then this tree's compiler at gen 2.
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
tar xzf build/gate-builder.tar.gz build/avra
build/avra --version
make -s objects libs >/dev/null 2>&1 || true
for gen in ${MEMHUNT_GENS:-1}; do
    find .avra-cache -mindepth 1 -delete 2>/dev/null
    memtime make avra > build/memhunt-gen$gen.log 2>&1
    st=$?
    echo "== gen $gen make avra: status $st"
    grep -E "Maximum resident|Elapsed" build/memhunt-gen$gen.log
    [ $st = 0 ] || { tail -30 build/memhunt-gen$gen.log; exit 70; }
done
echo "== head $(git log -1 --format=%h) compiler $(ls -la build/avra | awk '{print $5}')"
free -m | head -2

sampler() {
    out=$1
    while :; do
        ps -eo rss=,comm= --sort=-rss | head -3 | tr '\n' ';' >> "$out"
        ps -eo rss=,comm= | awk '$2 == "avra" { s += $1; n++ } END { printf "%d avra_sum%d;", s, n }' >> "$out"
        echo >> "$out"
        sleep 1
    done
}

one() {
    label=$1
    log=build/memhunt-$label.err
    samp=build/memhunt-$label.samp
    : > "$samp"
    sampler "$samp" &
    sp=$!
    t0=$(date +%s)
    memtime env AVRA_MEM_STATS=1 AVRA_MEM_SITES=30 AVRA_PROGRAM_MODE=release ./avra ${MEMHUNT_VERB:-build} packages/cli ${MEMHUNT_FLAG---time} > build/memhunt-$label.out 2> "$log"
    st=$?
    kill $sp 2>/dev/null
    echo "== $label: status $st, $(( $(date +%s) - t0 ))s"
    grep -E "Maximum resident|Elapsed" "$log"
    echo "-- top sampled processes (max rss MB by comm)"
    tr ';' '\n' < "$samp" | awk 'NF==2 { if ($1 > m[$2]) m[$2] = $1 } END { for (c in m) printf "%8d %s\n", m[c]/1024, c }' | sort -rn | head -6
    echo "-- rss timeline (top process, every 10s)"
    awk 'NR % 10 == 1 { split($0, a, ";"); print NR "s " a[1] }' "$samp" | head -40
    echo "-- mem stats"
    grep -E "^mem:" "$log" | grep -v " site " | head -40
    echo "-- sites"
    grep -E "^mem:   site" "$log" | while read -r _ _ addr rest; do
        sym=$(addr2line -f -C -e build/avra "$addr" 2>/dev/null | head -1)
        echo "$addr $sym :: $rest"
    done
    echo "-- time lines"
    grep -E "^time:" build/memhunt-$label.out "$log" | head -30
    echo "-- stderr tail"
    grep -vE "^mem:|^\s" "$log" | tail -8
}

find .avra-cache -mindepth 1 -delete 2>/dev/null
find "$HOME/.avra/cache" -mindepth 1 -delete 2>/dev/null
one cold
[ -n "${MEMHUNT_COLD_ONLY:-}" ] || one warm

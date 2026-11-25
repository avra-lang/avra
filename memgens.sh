#!/bin/bash
# gen-1 and gen-2 compilers of this tree, each measured over the same cold cli build with AVRA_MEM_STATS.
set -u
cd "$(git rev-parse --show-toplevel)"
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_WORK_AHEAD_OFF=1 AVRA_WAVE_ALONE=1
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
wipe() {
    find . -path ./build -prune -o -type d -name .avra-cache -prune -print | while read -r d; do find "$d" -mindepth 1 -delete; done
    find packages/cli/src -maxdepth 1 \( -name main -o -name '.main*' -o -name 'main.av.ll' \) -delete
    find "$HOME/.avra" -mindepth 1 -delete 2>/dev/null
    find "$AVRA_CACHE_DIR" -mindepth 1 -delete 2>/dev/null
}
stores() { du -sm .avra-cache packages/*/.avra-cache "$AVRA_CACHE_DIR" 2>/dev/null | awk '$1 > 0' | tr '\n' ' '; echo; }
export AVRA_CACHE_DIR=$PWD/build/machine-cache
mkdir -p "$AVRA_CACHE_DIR"
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
tar xzf build/gate-builder.tar.gz build/avra
cp build/avra build/avra-gen0
for gen in 1 2; do
    wipe
    memtime make avra > build/gen$gen.log 2>&1 || { tail -30 build/gen$gen.log; exit 70; }
    echo "== built gen $gen (by gen $((gen-1))):"; grep -E "Maximum resident|Elapsed" build/gen$gen.log
    cp build/avra build/avra-gen$gen
    echo "stores: $(stores)"
done
for gen in ${MEMHUNT_MEASURE:-0 1 2}; do
    cp build/avra-gen$gen build/avra
    wipe
    memtime env AVRA_MEM_STATS=1 AVRA_MEM_SITES=30 AVRA_PROGRAM_MODE=release ./avra ${MEMHUNT_VERB:-build} packages/cli > build/stats$gen.out 2> build/stats$gen.err
    echo "== gen $gen cold cli ${MEMHUNT_VERB:-build}: status $?"; grep -E "^time:" build/stats$gen.out build/stats$gen.err | head -4; echo "stores: $(stores)"
    grep -E "Maximum resident|Elapsed" build/stats$gen.err
    grep -E "^mem:" build/stats$gen.err | grep -vE " site |cap " | head -12
    grep -E "^mem:   site" build/stats$gen.err | head -20 | while read -r _ _ addr rest; do
        echo "$addr $(addr2line -f -C -e build/avra-gen$gen "$addr" 2>/dev/null | head -1) :: $rest"
    done
    grep -E "^mem:     cap" build/stats$gen.err | sort -k5 -rn | head -5
    grep -E "^mem:   wide" build/stats$gen.err | head -6
done

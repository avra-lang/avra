#!/bin/bash
# The held budget's knee: one compiler per budget (a scratch edit of HELD_BUDGET, never committed), each
# over cold and warm `build packages/cli --time` and warm `check`, one process.
set -u
cd "$(git rev-parse --show-toplevel)"
export LLVM_PREFIX=${LLVM_PREFIX:-/usr/lib/llvm-22}
export AVRA_WORK_AHEAD_OFF=1 AVRA_WAVE_ALONE=1 AVRA_CACHE_DIR=$PWD/build/machine-cache
memtime() {
    python3 -c '
import resource, subprocess, sys, time
t = time.time()
st = subprocess.call(sys.argv[1:])
r = resource.getrusage(resource.RUSAGE_CHILDREN)
sys.stderr.write("rss %d MB, %.1fs, status %d\n" % (r.ru_maxrss // 1024, time.time() - t, st))
sys.exit(st)
' "$@"
}
wipe() {
    find . -path ./build -prune -o -type d -name .avra-cache -prune -print | while read -r d; do find "$d" -mindepth 1 -delete; done
    find packages/cli/src -maxdepth 1 \( -name main -o -name '.main*' -o -name 'main.av.ll' \) -delete
    find "$HOME/.avra" "$AVRA_CACHE_DIR" -mindepth 1 -delete 2>/dev/null; mkdir -p "$AVRA_CACHE_DIR"
}
curl -fsSL --retry 3 -o build/gate-builder.tar.gz https://github.com/avra-lang/avra/releases/download/gate-builder/compiler.tar.gz
tar xzf build/gate-builder.tar.gz build/avra
cp build/avra build/avra-parent
make -s objects libs >/dev/null 2>&1 || true
cp packages/std-program/src/held_clock.av build/held_clock.av.orig
for mb in ${BUDGETS:-64 256 1024}; do
    sed "s/^const HELD_BUDGET: int = .*/const HELD_BUDGET: int = $((mb * 1048576))/" build/held_clock.av.orig > packages/std-program/src/held_clock.av
    cp build/avra-parent build/avra
    wipe
    memtime make avra > build/gen-$mb.log 2>&1 || { tail -30 build/gen-$mb.log; exit 70; }
    cp build/avra build/avra-$mb
done
cp build/held_clock.av.orig packages/std-program/src/held_clock.av
one() {
    memtime timeout 1500 env AVRA_MEM_STATS=1 AVRA_PROGRAM_MODE=release ./avra $2 packages/cli $3 > build/$1.out 2> build/$1.err
    printf '%-18s %s | %s | %s\n' "$1" "$(grep -E '^rss ' build/$1.err)" "$(grep -E '^mem: peak' build/$1.err)" "$(grep -hE '^decoded:' build/$1.out build/$1.err | head -1)"
}
for who in parent ${BUDGETS:-64 256 1024}; do
    cp build/avra-$who build/avra
    wipe
    one "build-$who-cold" build --time
    one "build-$who-warm" build --time
    one "check-$who-warm" check --counts
done
for who in parent 64; do
    echo "-- check-$who-warm sites"
    grep -E "^mem:   (list boxes|list buffers|bytes|strings)" build/check-$who-warm.err
    grep -E "^mem:   site" build/check-$who-warm.err | head -8 | while read -r _ _ addr rest; do
        echo "$addr $(addr2line -f -e build/avra-$who "$addr" 2>/dev/null | head -1 | sed 's/av_\$40std\$2F//; s/\$2F/\//g; s/\$2E/./g') :: $rest"
    done
done

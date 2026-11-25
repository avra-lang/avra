#!/bin/bash
# AVRA_HELD_ANSWERS_OFF A/B over cold and warm `check`/`build packages/cli`, one process, gate-builder (head's gen 2).
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
sh tools/gate.sh unpack build/gate-builder.tar.gz || exit 70
make -s objects libs >/dev/null 2>&1 || true
one() { # <label> <verb> <env…>
    label=$1 verb=$2; shift 2
    memtime timeout 1500 env "$@" AVRA_MEM_STATS=1 AVRA_PROGRAM_MODE=release ./avra $verb packages/cli > build/$label.out 2> build/$label.err
    printf '%-22s %s | %s | %s\n' "$label" "$(grep -E '^rss ' build/$label.err)" "$(grep -E '^mem: peak' build/$label.err)" "$(grep -hE '^time: (check|lower)' build/$label.out build/$label.err | head -1)"
    grep -E "^mem:   (list boxes|list buffers|bytes)" build/$label.err | tr -s ' ' | tr '\n' ';'; echo
}
for verb in check build; do
    for held in on off; do
        e=X=1; [ $held = off ] && e=AVRA_HELD_ANSWERS_OFF=1
        wipe
        one "$verb-$held-cold" $verb $e
        one "$verb-$held-warm" $verb $e
    done
done

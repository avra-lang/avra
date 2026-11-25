#!/bin/bash
# S3 measured against its parent: gate-builder (the parent's gen 2) and this tree's compiler, each over
# the same cold and warm `check`/`build packages/cli`, one process.
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
wipe
memtime make avra > build/gen1.log 2>&1 || { tail -40 build/gen1.log; exit 70; }
echo "built gen 1 by the parent: $(grep '^rss' build/gen1.log)"
cp build/avra build/avra-s3
one() { # <label> <verb>
    memtime timeout 1500 env AVRA_MEM_STATS=1 AVRA_PROGRAM_MODE=release ./avra $2 packages/cli ${3:-} > build/$1.out 2> build/$1.err
    printf '%-20s %s | %s | %s\n' "$1" "$(grep -E '^rss ' build/$1.err)" "$(grep -E '^mem: peak' build/$1.err)" "$(grep -hE '^decoded:' build/$1.err | head -1)"
}
for verb in check build; do
    flag=; [ $verb = check ] && flag=--counts
    for who in parent s3; do
        cp build/avra-$who build/avra
        wipe
        one "$verb-$who-cold" $verb $flag
        one "$verb-$who-warm" $verb $flag
    done
done
grep -E "^mem:   (list boxes|list buffers|bytes)" build/check-s3-cold.err
for who in parent s3; do
    cp build/avra-$who build/avra
    wipe
    memtime timeout 1500 env AVRA_MEM_STATS=1 ./avra test packages/std-program --time > build/suite-$who.out 2> build/suite-$who.err
    printf '%-20s %s | %s | %s\n' "suite-$who" "$(grep -E '^rss ' build/suite-$who.err)" "$(grep -E '^mem: peak' build/suite-$who.err | head -1)" "$(grep -hE '^decoded:' build/suite-$who.err | tail -1)"
    tail -3 build/suite-$who.out
done
cp build/avra-s3 build/avra
wipe
memtime make avra > build/gen2.log 2>&1 || { tail -40 build/gen2.log; exit 70; }
echo "built gen 2 by gen 1: $(grep '^rss' build/gen2.log)"

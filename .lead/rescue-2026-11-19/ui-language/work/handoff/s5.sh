#!/bin/sh
cd /work/b53 && . /etc/profile.d/avra.sh
[ -x build/avra-a2 ] || cp -p build/avra-try build/avra-a2
make build/libavra_runtime.a > /tmp/claude-0/s5-make.log 2>&1; cp -pn /work/ctx-wt/build/*.o build/ 2>/dev/null
AVRA_PROGRAM_MODE=release build/avra-a2 build packages/cli > /tmp/claude-0/s5-build.log 2>&1
if [ ! -x packages/cli/src/main ]; then grep -B2 -A14 '^error' /tmp/claude-0/s5-build.log | head -60; echo "S5 BUILD FAILED"; exit 1; fi
cp packages/cli/src/main build/avra-try && cp build/avra-try build/avra && find packages/cli/src -maxdepth 1 \( -name main -o -name main.av.ll \) -delete
build/avra-try runtime-header | cmp - runtime/avra_rt.h && echo "rt header same"
build/avra-try runtime-namespace | cmp - packages/std-avrac/src/features/rt.av && echo "rt.av same"
echo "S5 OK"

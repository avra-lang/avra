set -e
T=/home/sprite/avra-build/avra-parse/tree
find /home/sprite/base2 -mindepth 1 -delete 2>/dev/null || true
mkdir -p /home/sprite/base2
cd $T && tar cf - --exclude=.avra-cache --exclude=build/avra.pre --exclude='build/avra.pre.*' --exclude=build/avra.census --exclude=.git . | (cd /home/sprite/base2 && tar xf -)
cd /home/sprite/base2
patch -R -p1 < /home/sprite/seq.patch
export AVRA_CWD=$PWD
build/avra build packages/cli > build/base-build.out 2>&1 || { tail -5 build/base-build.out; exit 1; }
mv packages/cli/src/main build/avra-base2
ls -la build/avra-base2

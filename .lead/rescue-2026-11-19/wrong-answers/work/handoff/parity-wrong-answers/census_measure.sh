#!/bin/sh
# Measure the cost and determinism of census workloads.
#   census_measure.sh build            build the census compiler once, timed
#   census_measure.sh run <tag> <ahead:on|off> <cmd...>   one cold run, timed, counts saved
set -u
T=/work/avra
SRC=/work/census-src
OUT=/tmp/claude-0/-home-user/eabfde80-5d84-5793-ab10-2655cf2de6a7/scratchpad/census
mkdir -p "$OUT"
. /etc/profile.d/avra.sh
case "$1" in
build)
    cd "$T"
    counted="-DAVRA_CENSUS -fno-omit-frame-pointer"
    if [ -n "${SITES:-}" ]; then export AVRA_CENSUS_SITES=1; fi
    s=$(date +%s)
    make --no-print-directory CFLAGS_avra_runtime="$counted" CFLAGS_avra_hot="$counted" build/libavra_runtime.a > "$OUT/rt.out" 2>&1 || { tail -5 "$OUT/rt.out"; exit 1; }
    m=$(date +%s)
    AVRA_PROGRAM_NET=0 AVRA_FRAME_POINTERS=1 AVRA_INLINE_RUNTIME=0 AVRA_CENSUS_TYPES=1 AVRA_PROGRAM_MODE=release \
        /usr/bin/time -f "build: %e s wall, %U s user, %M KB peak" build/avra-try build packages/cli > "$OUT/build.out" 2>&1
    rc=$?
    e=$(date +%s)
    [ $rc -eq 0 ] && cp packages/cli/src/main build/avra.census-gate
    find packages/cli/src/main packages/cli/src/main.av.ll -maxdepth 0 -delete 2>/dev/null
    make --no-print-directory build/libavra_runtime.a > /dev/null 2>&1 || echo "shipping runtime did not rebuild"
    f=$(date +%s)
    echo "runtime $((m-s)) s; compiler build $((e-m)) s (rc $rc); runtime restore $((f-e)) s"
    tail -1 "$OUT/build.out"
    nm build/avra.census-gate | grep -Eq '[ _]note_retain$' && echo "census binary ok"
    ;;
run)
    tag=$2; ahead=$3; shift 3
    cache=/tmp/census-cache-fixed; [ -d "$cache" ] && find "$cache" -delete; mkdir -p "$cache"
    cd "$SRC"
    find "$SRC/packages" \( -path "*/src/main" -o -name "*.av.ll" \) -type f -delete 2>/dev/null
    find "$SRC" -path "*/.avra-cache*" -delete 2>/dev/null
    if [ "$ahead" = off ]; then export AVRA_WORK_AHEAD_OFF=1; else unset AVRA_WORK_AHEAD_OFF; fi
    if [ -n "${SITES:-}" ]; then export AVRA_CENSUS_SITES=1; fi
    s=$(date +%s)
    AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$cache" AVRA_STORE_KEPT_HERE=1 AVRA_MEM_STATS=1 \
        /usr/bin/time -f "time: %e s wall, %U s user, %M KB peak" "$T/build/avra.census-gate" "$@" > "$OUT/$tag.stdout" 2> "$OUT/$tag.out"
    rc=$?
    e=$(date +%s)
    grep -E '^(rc:|alloc: [0-9]|once:|time:)' "$OUT/$tag.out" > "$OUT/$tag.counts"
    echo "$tag rc=$rc $((e-s)) s"; cat "$OUT/$tag.counts"
    find "$cache" -delete
    find "$SRC" -path "*/.avra-cache*" -delete 2>/dev/null
    ;;
esac

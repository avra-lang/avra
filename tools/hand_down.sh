#!/bin/sh
# tool-witness: --self-test
# THE HAND-DOWN: what one CI job built, carried to the jobs that run it.
# `pack` tars `build/` and the store's rows beside it — never the compiler
# (its own artifact) nor the store's machine code (each job's own to make)
# — and holds the tar to its byte budget, since every downstream job
# downloads it. `unpack` lays it back and stands every file newer than the
# checkout's sources, so no job rebuilds what was built from the same
# commit, then says what room the runner has: a 137 is measured against
# the cgroup's ceiling, never the VM's published spec.
#
#   sh tools/hand_down.sh pack [tar]      default avra-build.tar.gz
#   sh tools/hand_down.sh unpack [tar]
#   sh tools/hand_down.sh --self-test

WARN_BYTES=314572800
MAX_BYTES=1073741824

pack() {
    out="$1" warn="$2" max="$3"
    # the store reclaims by its own rule before it rides to every job
    if [ -d .avra-cache ] && [ -x build/avra ]; then
        build/avra cache clean || echo "::warning::avra cache clean failed"
        du -sh .avra-cache/* 2>/dev/null
    fi
    dirs=build; [ ! -d .avra-cache ] || dirs="build .avra-cache"
    # gzip -1: the store is text-heavy and the budget is the bytes a job downloads
    # a pipe answers gzip's status, so tar's own rides a mark beside the tar
    refused="$out.refused"
    find "$refused" -delete 2>/dev/null
    # shellcheck disable=SC2086
    { tar -cf - --exclude=build/avra --exclude=.avra-cache/obj --exclude=.avra-cache/bin $dirs || : > "$refused"; } | gzip -1 > "$out" || return 1
    [ ! -f "$refused" ] || { find "$refused" -delete; echo "::error::tar refused the hand-down"; return 1; }
    size=$(wc -c < "$out" | tr -d ' ')
    echo "hand-down: $out is $(( size / 1048576 )) MB compressed"
    [ "$size" -le "$warn" ] || echo "::warning::$out is $(( size / 1048576 )) MB; every downstream job downloads it (2.4 GB cost 3-5 min a job)"
    [ "$size" -le "$max" ] || { echo "::error::$out is $(( size / 1048576 )) MB, over the $(( max / 1048576 )) MB budget every downstream job downloads"; return 1; }
}

unpack() {
    tar -xzf "$1" || return 1
    [ ! -f build/avra ] || chmod +x build/avra
    find build -type f -exec touch {} + 2>/dev/null
    room
}

room() {
    [ -r /proc/meminfo ] || return 0
    echo "room: cpu=$(nproc)"
    awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "room: memory total %d MB, available %d MB\n", t/1024, a/1024}' /proc/meminfo
    printf 'room: cgroup memory.max %s B\n' "$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo n/a)"
}

self_test() {
    t=$(mktemp -d) || exit 1
    trap 'find "$t" -delete' EXIT
    fails=0
    bad() { fails=$((fails + 1)); echo "hand-down: FAIL — $1"; }
    mkdir -p "$t/from/build" "$t/from/.avra-cache/store" "$t/from/.avra-cache/obj" "$t/to"
    echo o > "$t/from/build/x.o"
    echo c > "$t/from/build/avra"
    echo r > "$t/from/.avra-cache/store/row"
    echo m > "$t/from/.avra-cache/obj/m.o"
    (cd "$t/from" && pack "$t/h.tar.gz" "$WARN_BYTES" "$MAX_BYTES" > /dev/null) || bad "pack refused a small tree"
    sleep 1
    touch "$t/ref"
    sleep 1
    cp "$t/h.tar.gz" "$t/to/" && (cd "$t/to" && unpack h.tar.gz > /dev/null) || bad "unpack refused its own pack"
    [ -f "$t/to/build/x.o" ] || bad "an object did not ride"
    [ -f "$t/to/.avra-cache/store/row" ] || bad "a store row did not ride"
    [ ! -f "$t/to/build/avra" ] || bad "the compiler rode the tar (it is its own artifact)"
    [ ! -f "$t/to/.avra-cache/obj/m.o" ] || bad "the store's machine code rode the tar"
    [ -n "$(find "$t/to/build/x.o" -newer "$t/ref")" ] || bad "an unpacked object is not newer than the sources"
    (cd "$t/from" && pack "$t/big.tar.gz" 1 2 > /dev/null) && bad "a tar over its budget was accepted"
    mkdir "$t/empty"
    (cd "$t/empty" && pack "$t/none.tar.gz" "$WARN_BYTES" "$MAX_BYTES" > /dev/null 2>&1) && bad "a tree with no build/ packed clean"
    [ "$fails" = 0 ] || exit 1
    echo "hand-down: self-test passed — 8 fixtures (rows ride, compiler and machine code stay, newer than sources, budget and tar refusals)"
}

case "$1" in
    pack) pack "${2:-avra-build.tar.gz}" "$WARN_BYTES" "$MAX_BYTES" ;;
    unpack) unpack "${2:-avra-build.tar.gz}" ;;
    --self-test) self_test ;;
    *) echo "usage: sh tools/hand_down.sh pack|unpack [tar] | --self-test" >&2; exit 2 ;;
esac

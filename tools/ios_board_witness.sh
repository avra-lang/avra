#!/bin/sh
# THE iOS SPIKE'S BOARD: `sh tools/ios_board_witness.sh [shot-name]` builds
# tools/ios-spike, launches it on one simulator mounting tools/ui-board's own
# `view`, logs every frame record to build/ios-spike/board.out and takes a
# screenshot. Spike code: thrown away after the ruling.
set -u
tree=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$tree/build/avra}
sdk=iphonesimulator
work=$tree/build/ios-spike
shot=${1:-board}
id=dev.avra.spike
fail() { echo "ios-board: FAIL — $*" >&2; exit 1; }
xcrun --sdk $sdk clang -target arm64-apple-ios17.0-simulator -fobjc-arc -O2 -Wall -Werror -c \
    -o "$tree/build/$sdk/ios_spike_host.o" "$tree/tools/ios-spike/host/ios_spike_host.m" || fail "the UIKit host did not build"
built=$(cd "$tree" && "$avra" build --target arm64-apple-ios-simulator tools/ios-spike) || fail "the spike did not build"
[ -d "$work/Spike.app" ] || fail "run tools/ios_spike_witness.sh once first: it writes Spike.app"
mv "$built" "$work/Spike.app/spike"
codesign -f -s - "$work/Spike.app" > /dev/null 2>&1 || fail "the app could not be signed"
udid=$(xcrun simctl list devices available | awk '/^-- iOS (26|18)/ { on = 1; next } /^--/ { on = 0 } on && $0 ~ dev' dev="${AVRA_BOARD_DEVICE:-iPhone}" |
    sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -n 1)
xcrun simctl boot "$udid" 2> /dev/null
xcrun simctl bootstatus "$udid" > /dev/null 2>&1 || :
trap 'xcrun simctl shutdown "$udid" > /dev/null 2>&1' EXIT
xcrun simctl install "$udid" "$work/Spike.app" || fail "install failed"
out=$work/board.out
: > "$out"
env SIMCTL_CHILD_AVRA_SPIKE_BOARD=1 SIMCTL_CHILD_AVRA_SPIKE_FRAMES=1 ${AVRA_BOARD_SCRIPT:+SIMCTL_CHILD_AVRA_SPIKE_BOARD_SCRIPT=$AVRA_BOARD_SCRIPT} ${AVRA_SPIKE_SERVER:+SIMCTL_CHILD_AVRA_SPIKE_SERVER=$AVRA_SPIKE_SERVER} \
    timeout ${AVRA_BOARD_FOR:-30} xcrun simctl launch --console-pty --terminate-running-process "$udid" "$id" > "$out" 2>&1 &
# shots at the given seconds after launch (AVRA_BOARD_SHOTS, default "8"), named <shot>[-<n>].png
n=0; t0=0
for at in ${AVRA_BOARD_SHOTS:-8}; do
    sleep $((at - t0)); t0=$at; n=$((n + 1))
    name=$shot; [ "$n" -gt 1 ] && name=$shot-$n
    xcrun simctl io "$udid" screenshot "$work/$name.png" > /dev/null 2>&1 && echo "ios-board: screenshot: $work/$name.png"
    # AVRA_BOARD_DARK_AFTER=<n>: the device turns dark after the n-th shot
    if [ "$n" = "${AVRA_BOARD_DARK_AFTER:-0}" ]; then xcrun simctl ui "$udid" appearance dark && echo "ios-board: appearance dark"; fi
done
xcrun simctl ui "$udid" appearance light
xcrun simctl terminate "$udid" "$id" > /dev/null 2>&1
wait
echo "ios-board: $(grep -c 'frame:' "$out") frames logged in $out"

#!/bin/sh
# THE iOS SPIKE'S SLICE 1 WITNESS: `sh tools/ios_spike_witness.sh` builds
# tools/ios-spike for the simulator, wraps it as an app with the scene
# lifecycle, and runs it four times on one simulator, reading what the app's
# own accessibility tree and its host report:
#   round trip — the label Avra supplies, then three presses through the
#                button's accessibility action, the label following
#   modes      — a ticking task keeps ticking in a scroll's tracking mode and
#                while an alert stands; a screenshot of the label
#   budget     — the longest gap between display frames with a task spinning
#   sync       — a handler run inside the host's call answers; one that waits
#                is refused in the runtime's words
# Prints the binary's size and the cold start to first frame. Exits 1 on the
# first failure, naming it. Spike code: thrown away after the ruling.
set -u

tree=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$tree/build/avra}
sdk=iphonesimulator
triple=arm64-apple-ios17.0-simulator
work=$tree/build/ios-spike
id=dev.avra.spike
mkdir -p "$work"

fail() { echo "ios-spike: FAIL — $*" >&2; exit 1; }
said() { echo "ios-spike: $*"; }

make -s -C "$tree" apple-runtime apple-packages || fail "the $sdk runtime or package objects did not build"
xcrun --sdk $sdk clang -target $triple -fobjc-arc -O2 -Wall -Werror -c \
    -o "$tree/build/$sdk/ios_spike_host.o" "$tree/tools/ios-spike/host/ios_spike_host.m" ||
    fail "the UIKit host did not build"
built=$(cd "$tree" && "$avra" build --target arm64-apple-ios-simulator tools/ios-spike) || fail "the spike did not build"

app=$work/Spike.app
mkdir -p "$app"
cp "$built" "$app/spike"
cat > "$app/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>spike</string>
<key>CFBundleIdentifier</key><string>$id</string>
<key>CFBundleName</key><string>Spike</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>17.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UIApplicationSceneManifest</key><dict>
  <key>UIApplicationSupportsMultipleScenes</key><false/>
  <key>UISceneConfigurations</key><dict>
    <key>UIWindowSceneSessionRoleApplication</key><array><dict>
      <key>UISceneConfigurationName</key><string>Default</string>
      <key>UISceneDelegateClassName</key><string>SpikeScene</string>
    </dict></array>
  </dict>
</dict>
</dict></plist>
EOF
codesign -f -s - "$app" > /dev/null 2>&1 || fail "the app could not be signed"
said "binary: $(wc -c < "$app/spike" | tr -d ' ') bytes"

booted_here=
udid=$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)) (Booted).*/\1/p' | head -n 1)
if [ -z "$udid" ]; then
    udid=$(xcrun simctl list devices available | awk '/^-- iOS (26|18)/ { on = 1; next } /^--/ { on = 0 } on && /iPhone/' |
        sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -n 1)
    [ -n "$udid" ] || fail "no iPhone simulator on iOS 26 or 18 is available"
    xcrun simctl boot "$udid" || fail "simulator $udid did not boot"
    booted_here=$udid
    xcrun simctl bootstatus "$udid" > /dev/null 2>&1 || :
fi
trap '[ -z "$booted_here" ] || xcrun simctl shutdown "$booted_here" > /dev/null 2>&1' EXIT
xcrun simctl install "$udid" "$app" || fail "install failed"
said "simulator $udid"

# launched <name> <VAR=value>...: the app's console for one run, to its end, in build/ios-spike/<name>.out
launched() {
    name=$1; shift
    out=$work/$name.out
    env "$@" timeout 40 xcrun simctl launch --console-pty --terminate-running-process "$udid" "$id" 2>&1 | tr -d '\r' > "$out"
    sed "s/^/  $name| /" "$out"
}

holds() { grep -qF "$2" "$work/$1.out" || fail "$1: expected \"$2\""; said "ok — $1: \"$2\""; }

# THE ROUND TRIP, with a screenshot of the label once the presses landed
: > "$work/roundtrip.out"
( launched roundtrip SIMCTL_CHILD_AVRA_SPIKE_WITNESS=1 SIMCTL_CHILD_AVRA_SPIKE_PRESS=3 SIMCTL_CHILD_AVRA_SPIKE_PAUSE=2 ) &
# shot <line> <file>: a screenshot once the run's console says <line>
shot() {
    for _ in $(seq 1 150); do
        grep -q "$1" "$work/roundtrip.out" 2> /dev/null && break
        sleep 0.1
    done
    sleep 0.5
    xcrun simctl io "$udid" screenshot "$work/$2" > /dev/null 2>&1 && said "screenshot: $work/$2"
}
shot "a11y before" slice1-before.png
shot "a11y after" slice1-after.png
wait
holds roundtrip "a11y before: label: taps: 0 | button: taps+"
holds roundtrip "a11y after 3 presses: label: taps: 3 | button: taps+"
holds roundtrip "first frame"
grep -q "ticks in tracking mode: [1-9]" "$work/roundtrip.out" || fail "modes: no tick in tracking mode"
said "ok — modes: $(grep -o 'ticks in tracking mode.*' "$work/roundtrip.out")"
grep -q "ticks while an alert stood: [1-9]" "$work/roundtrip.out" || fail "modes: no tick under an alert"
said "ok — modes: $(grep -o 'ticks while an alert stood.*' "$work/roundtrip.out")"
said "frames, idle: $(grep -o 'display frames.*' "$work/roundtrip.out")"

launched budget SIMCTL_CHILD_AVRA_SPIKE_WITNESS=1 SIMCTL_CHILD_AVRA_SPIKE_SPIN=1
said "frames, a task spinning: $(grep -o 'display frames.*' "$work/budget.out" || echo "none reported — the loop never ran")"

launched sync SIMCTL_CHILD_AVRA_SPIKE_WITNESS=1 SIMCTL_CHILD_AVRA_SPIKE_SYNC=0
holds sync "a synchronous answer: 42"
launched waits SIMCTL_CHILD_AVRA_SPIKE_WITNESS=1 SIMCTL_CHILD_AVRA_SPIKE_SYNC=1
holds waits "a host callback waited"
said "all held"

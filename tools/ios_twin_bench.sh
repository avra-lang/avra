#!/bin/sh
# THE TWIN'S BENCH: `sh tools/ios_twin_bench.sh [out-name]` builds the
# hand-written UIKit twin (tools/ios-spike/twin), launches it on one simulator
# with the benchmark's instrument on, writes its console to
# build/ios-spike/<out-name>.out and takes screenshots at AVRA_BOARD_SHOTS
# seconds. Spike code: thrown away after the ruling.
set -u
tree=$(cd "$(dirname "$0")/.." && pwd)
work=$tree/build/ios-spike
name=${1:-twin}
id=dev.avra.twin
fail() { echo "ios-twin: FAIL — $*" >&2; exit 1; }
app=$work/Twin.app
mkdir -p "$app"
xcrun --sdk iphonesimulator clang -target arm64-apple-ios17.0-simulator -fobjc-arc -O2 -Wall -Werror \
    -framework UIKit -framework QuartzCore -Wl,-U,_avra_mem_live -o "$app/twin" \
    "$tree/tools/ios-spike/twin/twin.m" "$tree/tools/ios-spike/host/spike_bench.m" || fail "the twin did not build"
cat > "$app/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>twin</string>
<key>CFBundleIdentifier</key><string>$id</string>
<key>CFBundleName</key><string>Twin</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>17.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
<key>UIApplicationSceneManifest</key><dict>
  <key>UIApplicationSupportsMultipleScenes</key><false/>
  <key>UISceneConfigurations</key><dict>
    <key>UIWindowSceneSessionRoleApplication</key><array><dict>
      <key>UISceneConfigurationName</key><string>Default</string>
      <key>UISceneDelegateClassName</key><string>TwinScene</string>
    </dict></array>
  </dict>
</dict>
</dict></plist>
EOF
codesign -f -s - "$app" > /dev/null 2>&1 || fail "the twin could not be signed"
echo "ios-twin: binary $(wc -c < "$app/twin" | tr -d ' ') bytes"
udid=$(xcrun simctl list devices available | awk '/^-- iOS (26|18)/ { on = 1; next } /^--/ { on = 0 } on && $0 ~ dev' dev="${AVRA_BOARD_DEVICE:-iPhone}" |
    sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -n 1)
xcrun simctl boot "$udid" 2> /dev/null
xcrun simctl bootstatus "$udid" > /dev/null 2>&1 || :
trap 'xcrun simctl shutdown "$udid" > /dev/null 2>&1' EXIT
xcrun simctl install "$udid" "$app" || fail "install failed"
out=$work/$name.out
: > "$out"
env SIMCTL_CHILD_AVRA_SPIKE_BENCH=1 ${AVRA_SPIKE_SHOTS:+SIMCTL_CHILD_AVRA_SPIKE_SHOTS=1} ${AVRA_SPIKE_ROWS:+SIMCTL_CHILD_AVRA_SPIKE_ROWS=$AVRA_SPIKE_ROWS} \
    timeout ${AVRA_BOARD_FOR:-20} xcrun simctl launch --console-pty --terminate-running-process "$udid" "$id" > "$out" 2>&1 &
n=0; t0=0
for at in ${AVRA_BOARD_SHOTS:-}; do
    sleep $((at - t0)); t0=$at; n=$((n + 1))
    xcrun simctl io "$udid" screenshot "$work/$name-$n.png" > /dev/null 2>&1 && echo "ios-twin: screenshot: $work/$name-$n.png"
done
wait
tr -d '\r' < "$out" | grep "bench:"

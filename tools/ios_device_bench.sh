#!/bin/sh
# THE BENCH ON A DEVICE: `sh tools/ios_device_bench.sh avra|twin <label> <runs>`
# bundles the Avra spike or its UIKit twin for iphoneos, signs it with the
# owner's Apple Development identity under the team's wildcard development
# profile (both read from the keychain and the profile directories at run time,
# never written to the tree), installs it on AVRA_DEVICE and runs the
# benchmark's instrument <runs> times, keeping each console in
# build/ios-spike/device/<label>-<n>.out. The Avra app is built beforehand:
#   make APPLE_SDK=iphoneos apple-runtime apple-packages
#   xcrun --sdk iphoneos clang -target arm64-apple-ios17.0 -fobjc-arc -O2 -c \
#       -o build/iphoneos/ios_spike_host.o tools/ios-spike/host/ios_spike_host.m
#   ./avra build --target arm64-apple-ios tools/ios-spike
# The Avra app's mode and size come from AVRA_BOARD_MODE and AVRA_SPIKE_ROWS.
# Spike code.
set -u
tree=$(cd "$(dirname "$0")/.." && pwd)
which=$1; label=$2; runs=$3
device=${AVRA_DEVICE:?set AVRA_DEVICE to a device identifier from `xcrun devicectl list devices`}
work=$tree/build/ios-device
out=$tree/build/ios-spike/device
mkdir -p "$work" "$out"
fail() { echo "ios-device: FAIL — $*" >&2; exit 1; }

free=$(df -m /System/Volumes/Data | awk 'NR == 2 { print $4 }')
[ "$free" -ge 3072 ] || fail "${free} MB free, under 3 GB"

if [ "$which" = twin ]; then id=dev.avra.twin; exe=twin; app=$work/Twin.app; scene=TwinScene
else id=dev.avra.spike; exe=spike; app=$work/Spike.app; scene=SpikeScene; fi

# The signing: the wildcard development profile, a development identity whose
# certificate it carries, and the entitlements it grants for this app's id.
python3 -I - "$id" "$work/$exe.entitlements" "$work/$exe.identity" "$work/$exe.profile" <<'PY' || fail "no development identity and profile fit"
import glob, hashlib, os, plistlib, subprocess, sys
app_id, ent_out, ident_out, prof_out = sys.argv[1:5]
idents = subprocess.run(["security", "find-identity", "-v", "-p", "codesigning"], capture_output=True, text=True).stdout
dev = [l.split()[1] for l in idents.splitlines() if '"Apple Development:' in l]
dirs = ["~/Library/MobileDevice/Provisioning Profiles", "~/Library/Developer/Xcode/UserData/Provisioning Profiles"]
for d in dirs:
    for f in sorted(glob.glob(os.path.join(os.path.expanduser(d), "*.mobileprovision"))):
        p = plistlib.loads(subprocess.run(["security", "cms", "-D", "-i", f], capture_output=True).stdout)
        if p.get("Name") != "iOS Team Provisioning Profile: *":
            continue
        certs = {hashlib.sha1(c).hexdigest().upper() for c in p.get("DeveloperCertificates", [])}
        fit = [h for h in dev if h in certs]
        if not fit:
            continue
        granted = p["Entitlements"]
        prefix = granted["application-identifier"][:-1]
        ent = {
            "application-identifier": prefix + app_id,
            "com.apple.developer.team-identifier": granted["com.apple.developer.team-identifier"],
            "get-task-allow": granted.get("get-task-allow", False),
        }
        open(ent_out, "wb").write(plistlib.dumps(ent))
        open(ident_out, "w").write(fit[0])
        open(prof_out, "w").write(f)
        sys.exit(0)
sys.exit(1)
PY

mkdir -p "$app"
if [ "$which" = twin ]; then
    xcrun --sdk iphoneos clang -target arm64-apple-ios17.0 -fobjc-arc -O2 -Wall -Werror \
        -framework UIKit -framework QuartzCore -o "$app/twin" \
        "$tree/tools/ios-spike/twin/twin.m" "$tree/tools/ios-spike/host/spike_bench.m" || fail "the twin did not build"
else
    [ -f "$tree/tools/ios-spike/src/main.iphoneos" ] || fail "build the Avra app for iphoneos first (see the header)"
    mv "$tree/tools/ios-spike/src/main.iphoneos" "$app/spike"
fi
cat > "$app/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$exe</string>
<key>CFBundleIdentifier</key><string>$id</string>
<key>CFBundleName</key><string>$exe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleSupportedPlatforms</key><array><string>iPhoneOS</string></array>
<key>MinimumOSVersion</key><string>17.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
<key>UILaunchScreen</key><dict/>
<key>CADisableMinimumFrameDurationOnPhone</key><true/>
<key>UIApplicationSceneManifest</key><dict>
  <key>UIApplicationSupportsMultipleScenes</key><false/>
  <key>UISceneConfigurations</key><dict>
    <key>UIWindowSceneSessionRoleApplication</key><array><dict>
      <key>UISceneConfigurationName</key><string>Default</string>
      <key>UISceneDelegateClassName</key><string>$scene</string>
    </dict></array>
  </dict>
</dict>
</dict></plist>
EOF
cp "$(cat "$work/$exe.profile")" "$app/embedded.mobileprovision"
codesign -f -s "$(cat "$work/$exe.identity")" --entitlements "$work/$exe.entitlements" "$app" > "$work/$exe.sign.log" 2>&1 ||
    { cat "$work/$exe.sign.log" >&2; fail "signing refused"; }
echo "ios-device: $exe binary $(wc -c < "$app/$exe" | tr -d ' ') bytes, signed"
xcrun devicectl device install app --device "$device" "$app" > "$work/$exe.install.log" 2>&1 ||
    { tail -20 "$work/$exe.install.log" >&2; fail "install refused"; }
echo "ios-device: installed $id"

for i in $(seq 1 "$runs"); do
    env DEVICECTL_CHILD_AVRA_SPIKE_BENCH=1 ${AVRA_BOARD_MODE:+DEVICECTL_CHILD_AVRA_SPIKE_BOARD=$AVRA_BOARD_MODE} \
        ${AVRA_SPIKE_ROWS:+DEVICECTL_CHILD_AVRA_SPIKE_ROWS=$AVRA_SPIKE_ROWS} \
        timeout ${AVRA_BOARD_FOR:-60} xcrun devicectl device process launch --device "$device" --console \
        --terminate-existing "$id" > "$out/$label-$i.out" 2>&1
    echo "ios-device: $label run $i: $(tr -d '\r' < "$out/$label-$i.out" | grep -c 'bench:') bench lines"
done

#!/bin/sh
# THE iOS SIMULATOR WITNESS: `sh tools/ios_sim_witness.sh` builds four
# programs for arm64-apple-ios-simulator, wraps each in an .app, installs
# and launches it on one booted simulator, and holds what it printed:
#   hello      — a program runs and prints
#   tasks      — a task is spawned and awaited (the stack switch)
#   runaway    — a task's runaway recursion traps in Avra's own words
#   foundation — an extern reaches Foundation (NSLog) and CoreFoundation
# Exits 1 on the first failure, naming it. Boots a simulator only when
# none is booted, and shuts down only the one it booted.
set -u

tree=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$tree/build/avra}
target=arm64-apple-ios-simulator
work=$tree/build/ios-witness
mkdir -p "$work"

fail() { echo "ios-sim-witness: FAIL — $*" >&2; exit 1; }
said() { echo "ios-sim-witness: $*"; }

make -s -C "$tree" apple-runtime || fail "the iphonesimulator runtime archive did not build"

# The booted simulator, else the first iPhone on an iOS 26 or 18 runtime, booted here.
booted_here=
udid=$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)) (Booted).*/\1/p' | head -n 1)
if [ -z "$udid" ]; then
    udid=$(xcrun simctl list devices available | awk '/^-- iOS (26|18)/ { on = 1; next } /^--/ { on = 0 } on && /iPhone/' |
        sed -n 's/.*(\([0-9A-F-]\{36\}\)).*/\1/p' | head -n 1)
    [ -n "$udid" ] || fail "no iPhone simulator on iOS 26 or 18 is available"
    xcrun simctl boot "$udid" || fail "simulator $udid did not boot"
    booted_here=$udid
    xcrun simctl bootstatus "$udid" >/dev/null 2>&1 || :
fi
said "simulator $udid"
trap '[ -z "$booted_here" ] || xcrun simctl shutdown "$booted_here" >/dev/null 2>&1' EXIT

write_programs() {
    cat > "$work/hello.av" <<'EOF'
println("hello")
EOF
    cat > "$work/tasks.av" <<'EOF'
fn sum_to(n: int) -> int { if n == 0 { 0 } else { n + sum_to(n - 1) } }

let a = spawn { sum_to(1000) }
let b = spawn { sum_to(2000) }
println("tasks ${a.await} ${b.await}")
EOF
    cat > "$work/runaway.av" <<'EOF'
fn down(n: int) -> int {
    if n == -1 { return 0 }
    let r = down(n + 1)
    if r == n { println("met ${n}") }
    r
}

let t = spawn { down(0) }
println("runaway ${t.await}")
EOF
    cat > "$work/foundation.av" <<'EOF'
extern fn CFStringCreateWithCString(alloc: ptr?, text: string, encoding: u32) -> i64
extern fn NSLog(format: i64)
extern fn CFAbsoluteTimeGetCurrent() -> float

NSLog(CFStringCreateWithCString(null, "foundation reached", 134217984))
println("foundation clock ${CFAbsoluteTimeGetCurrent() > 0.0}")
EOF
}

# app <name>: the program built for the simulator and wrapped as <name>.app; its path.
app() {
    built=$(cd "$work" && "$avra" build --target "$target" "$1.av") || fail "$1: the build failed"
    bundle=$work/$1.app
    mkdir -p "$bundle"
    cp "$built" "$bundle/$1"
    cat > "$bundle/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$1</string>
<key>CFBundleIdentifier</key><string>dev.avra.witness.$1</string>
<key>CFBundleName</key><string>$1</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>MinimumOSVersion</key><string>17.0</string>
</dict></plist>
EOF
    codesign -f -s - "$bundle" >/dev/null 2>&1 || fail "$1: the bundle could not be signed"
    echo "$bundle"
}

# launched <name>: what the app printed on its console, run to its end.
launched() {
    bundle=$(app "$1") || exit 1
    file "$bundle/$1" | grep -q arm64 || fail "$1: the binary is not arm64"
    xcrun simctl install "$udid" "$bundle" || fail "$1: install failed"
    timeout 60 xcrun simctl launch --console-pty --terminate-running-process "$udid" "dev.avra.witness.$1" 2>&1 |
        tr -d '\r' > "$work/$1.out"
    cat "$work/$1.out"
}

# holds <name> <text>: the app's console said <text>.
holds() {
    out=$(launched "$1") || exit 1
    printf '%s\n' "$out" | sed "s/^/  $1| /"
    printf '%s\n' "$out" | grep -qF "$2" || fail "$1: expected \"$2\" on the console"
    said "ok — $1: \"$2\""
}

write_programs
holds hello "hello"
holds tasks "tasks 500500 2001000"
holds runaway "avra: a task's stack overflowed"
grep -q "runaway " "$work/runaway.out" && fail "runaway: the program went on past the trap"
timeout 60 xcrun simctl spawn "$udid" "$work/runaway.app/runaway" > "$work/runaway.spawn" 2>&1
code=$?
sed 's/^/  runaway (spawn)| /' "$work/runaway.spawn"
[ "$code" = 2 ] || fail "runaway: exited $code where a trap exits 2"
said "ok — runaway: exit 2"
holds foundation "foundation reached"
grep -qF "foundation clock true" "$work/foundation.out" || fail "foundation: CoreFoundation's clock did not answer"
said "ok — foundation: \"foundation clock true\""
said "all held"

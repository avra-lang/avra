#!/bin/sh
# WITNESS — `tools/gate_changed.sh`, the ONE enqueue gate the train and
# `tools/work land`'s preflight both call: keepers, the changed-file fmt, and
# the affected packages' idioms, all on the tree's own compiler. Hermetic —
# stubs for `avra`, `make` and `git` — so the proof is about the WIRING.
# Run: sh tools/witness_gate_changed.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
gate=$repo/tools/gate_changed.sh
tmp=$(mktemp -d "${TMPDIR:-/tmp}/avra-gate-changed.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/packages/pkg/bad/src" "$tmp/packages/pkg/good/src"
: > "$tmp/packages/pkg/bad/src/bad.av"
printf 'fn a() -> int {\n    1\n}\n' > "$tmp/a.av"
printf 'BROKEN\n' > "$tmp/broken.av"
avralog="$tmp/avra.log"
makelog="$tmp/make.log"
gitlog="$tmp/git.log"
: > "$avralog"
: > "$makelog"
: > "$gitlog"

cat > "$tmp/bin/avra" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$AVRA_LOG"
cmd=$1
shift
case "$cmd" in
    fmt)
        for f in "$@"; do
            [ -f "$f" ] || continue
            if grep -q BROKEN "$f"; then echo "fmt --check: 1 refused"; exit 1; fi
        done
        echo "fmt --check: ok"
        ;;
    check)
        for a in "$@"; do
            case "$a" in */bad) echo "idioms: refused $a"; exit 1 ;; esac
        done
        echo "check: ok"
        ;;
esac
exit 0
SH
cat > "$tmp/bin/make" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$MAKE_LOG"
exit 0
SH
cat > "$tmp/bin/git" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$GIT_LOG"
exit 99
SH
# A `clang` with no wasm target, so the gate's wasm proof skips here as it
# does on a machine without the toolchain — it reads the real tree.
cat > "$tmp/bin/clang" <<'SH'
#!/bin/sh
exit 0
SH
chmod +x "$tmp/bin/avra" "$tmp/bin/make" "$tmp/bin/git" "$tmp/bin/clang"

run() {
    ( cd "$tmp" && PATH="$tmp/bin:$PATH" AVRA="$tmp/bin/avra" \
        AVRA_LOG="$avralog" MAKE_LOG="$makelog" GIT_LOG="$gitlog" sh "$gate" "$@" )
}

fail=0
say() { echo "witness_gate_changed: $1"; fail=1; }

# (a) a changed .av the compiler refuses: the gate fails, and keepers ran.
: > "$makelog"
run --files broken.av >/dev/null 2>&1 && say "(a) a refused changed .av answered success"
[ -s "$makelog" ] || say "(a) the keepers never ran"

# (b) an affected package whose idioms refuse: the gate fails.
run --files a.av --packages pkg/bad >/dev/null 2>&1 && say "(b) a refused package answered success"

# (c) a clean change: the gate passes and the keepers ran.
: > "$makelog"
run --files a.av --packages pkg/good >/dev/null 2>&1 || say "(c) a clean change answered failure"
[ -s "$makelog" ] || say "(c) the keepers never ran"

# (d) --no-keepers: the caller already ran them, so `make` is not called.
: > "$makelog"
run --files a.av --packages pkg/good --no-keepers >/dev/null 2>&1 || say "(d) a clean change answered failure"
[ -s "$makelog" ] && say "(d) --no-keepers still ran the keepers"

# (e) no git: the --files/--packages door names its inputs, never a ref.
[ -s "$gitlog" ] && say "(e) the gate called git"

# (f) nothing changed: no compiler, no keepers, success.
: > "$avralog"
run --files --packages >/dev/null 2>&1 || say "(f) an empty change answered failure"
[ -s "$avralog" ] && say "(f) the compiler ran with nothing changed"

[ "$fail" -eq 0 ] && echo "witness_gate_changed: 6 proved — keepers, fmt and idioms, inputs named, no git"
exit "$fail"

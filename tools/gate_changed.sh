#!/bin/sh
# THE ENQUEUE GATE — the checks the train runs, in ONE definition, so the
# local preflight (`tools/work land`) and the train can never be two
# instruments. A PR's own `test` check only admits it (checks.yml's PR step
# is "admitted; the train is what gets tested"), so this is the gate that
# must run BEFORE a branch is pushed.
#
#   sh tools/gate_changed.sh --refs <base> <head> [--no-keepers]   # a git tree
#   sh tools/gate_changed.sh --files <f…> --packages <p…>          # no `.git`
#
# With the tree's OWN compiler (${AVRA:-build/avra}; `tools/sp` builds it
# from the branch), it runs:
#   - the static keepers
#   - `fmt --check` on the changed `.av`
#   - `check <pkg> --baseline tools/idioms.baseline` on each affected package
# `--no-keepers` is for a caller that already ran them (the train's own
# keepers step); the preflight runs them here.
set -eu
avra=${AVRA:-build/avra}
files=""
packages=""
base=""
head=""
keepers=1
while [ "$#" -gt 0 ]; do
    case "$1" in
        --refs)
            [ "$#" -ge 3 ] || { echo "gate_changed: --refs needs <base> <head>" >&2; exit 2; }
            base=$2
            head=$3
            shift 3
            ;;
        --files)
            shift
            while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do files="$files $1"; shift; done
            ;;
        --packages)
            shift
            while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do packages="$packages $1"; shift; done
            ;;
        --no-keepers) keepers=0; shift ;;
        *) echo "gate_changed: unknown argument $1" >&2; exit 2 ;;
    esac
done
[ -x "$avra" ] || { echo "gate_changed: no compiler at $avra" >&2; exit 2; }
if [ -n "$base" ]; then
    files=$(git diff --name-only --diff-filter=d "$base" "$head" -- '*.av')
    packages=$(sh tools/affected_packages.sh "$base" "$head" "$PWD" 2>/dev/null)
fi
if [ -z "$files" ] && [ -z "$packages" ]; then
    echo "gate_changed: nothing changed — no .av, no affected package"
    exit 0
fi
if [ "$keepers" = 1 ]; then
    for k in fingerprints vocab families cited externs dogfooding-rules ui-host ui-host-test; do
        make -s -o avra "$k" || { echo "gate_changed: keeper $k refused" >&2; exit 1; }
    done
fi
[ -z "$files" ] || "$avra" fmt --check $files
for p in $packages; do
    [ -d "packages/$p/src" ] || continue
    "$avra" check "packages/$p" --baseline tools/idioms.baseline \
        || { echo "gate_changed: idioms refused packages/$p" >&2; exit 1; }
done
# THE WASM TARGET'S OWN PROOF, where its toolchain stands: the import/export
# seam, the refusals, and eval == native == wasm. Each SKIPS, spoken, when the
# toolchain is absent, so a machine without it is not falsely green.
if command -v clang >/dev/null 2>&1 && clang --print-targets 2>/dev/null | grep -q wasm32; then
    make -s -o avra wasm-runtime wasm-packages >/dev/null 2>&1 || true
    sh tools/wasm-check.sh || { echo "gate_changed: wasm-check refused" >&2; exit 1; }
    sh tools/wasm-seam-check.sh || { echo "gate_changed: wasm-seam refused" >&2; exit 1; }
    sh tools/wasm-refuses.sh || { echo "gate_changed: wasm-refuses refused" >&2; exit 1; }
fi
echo "gate_changed: clean — changed .av and affected idioms hold"

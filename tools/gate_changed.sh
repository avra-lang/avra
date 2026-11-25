#!/bin/sh
# THE GATE'S CHECKS, in ONE definition, so a lane (`sh tools/work run sh
# tools/gate_changed.sh --files … --packages …`) and a PR's own gate can never
# be two instruments.
#
#   sh tools/gate_changed.sh --refs <base> <head> [--no-keepers]
#   sh tools/gate_changed.sh --files <f…> --packages <p…> [--no-keepers]
#
# With the tree's OWN compiler (${AVRA:-build/avra}; `tools/work run` builds
# it from the branch on the lane's Sprite), it runs:
#   - the keepers (`make keepers`, the Makefile's one list — the wasm target's
#     proof among them)
#   - `fmt --check` on the changed `.av`
#   - `check <pkg> --baseline tools/idioms.baseline` on each affected package
# `--no-keepers` is for a caller that already ran them (the gate's own
# keepers jobs).
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
    make -s -o avra keepers || { echo "gate_changed: a keeper refused" >&2; exit 1; }
fi
[ -z "$files" ] || "$avra" fmt --check $files
for p in $packages; do
    [ -d "packages/$p/src" ] || continue
    "$avra" check "packages/$p" --baseline tools/idioms.baseline \
        || { echo "gate_changed: idioms refused packages/$p" >&2; exit 1; }
done
echo "gate_changed: clean — changed .av and affected idioms hold"

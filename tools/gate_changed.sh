#!/bin/sh
# THE GATE'S CHECKS, in ONE definition, so a lane (`sh tools/work run sh
# tools/gate_changed.sh --files … --packages …`) and a PR's own gate can never
# be two instruments.
#
#   sh tools/gate_changed.sh [--no-keepers]                  what this tree changed since its trunk
#   sh tools/gate_changed.sh --refs <base> <head> [--no-keepers]
#   sh tools/gate_changed.sh --files <f…> --packages <p…> [--no-keepers]
#
# A TREE IS DIFFED AGAINST ITS OWN TRUNK: with no refs or files named, the base is the tree's merge-base
# with program where that merge-base holds a commit main lacks (a lane branched off program), else its
# merge-base with main, and the working tree is what is examined, uncommitted and untracked `.av`
# included. Every run says how many `.av` it examined against what. A run that examines no `.av` on a
# tree that changed some since its trunk FAILS: a base that answers nothing is not a clean tree.
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
# a run that names a base, its files or its packages — even none — asks of those alone
named=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --refs)
            named=1
            [ "$#" -ge 3 ] || { echo "gate_changed: --refs needs <base> <head>" >&2; exit 2; }
            base=$2
            head=$3
            shift 3
            ;;
        --files)
            named=1
            shift
            while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do files="$files $1"; shift; done
            ;;
        --packages)
            named=1
            shift
            while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do packages="$packages $1"; shift; done
            ;;
        --no-keepers) keepers=0; shift ;;
        *) echo "gate_changed: unknown argument $1" >&2; exit 2 ;;
    esac
done
[ -x "$avra" ] || { echo "gate_changed: no compiler at $avra" >&2; exit 2; }
# the tree's trunk and its merge-base with it, as `<trunk> <sha>`: program's where that merge-base holds a
# commit main lacks, else main's; nothing where neither trunk is known here
trunk() {
    if git rev-parse -q --verify origin/program > /dev/null; then
        on=$(git merge-base HEAD origin/program 2> /dev/null) || on=
        if [ -n "$on" ] && ! { git rev-parse -q --verify origin/main > /dev/null && git merge-base --is-ancestor "$on" origin/main; }; then
            echo "program $on"
            return 0
        fi
    fi
    git rev-parse -q --verify origin/main > /dev/null && on=$(git merge-base HEAD origin/main 2> /dev/null) && [ -n "$on" ] && echo "main $on"
}
# the `.av` the working tree changed since `$1`, uncommitted and untracked ones too, one a line
worked() {
    { git diff --name-only --diff-filter=d "$1" -- '*.av'; git ls-files --others --exclude-standard -- '*.av'; } | sort -u
}
if [ "$named" = 0 ]; then
    read -r line on <<EOF
$(trunk)
EOF
    [ -n "${on:-}" ] || { echo "gate_changed: this tree's trunk is not known here (no origin/program or origin/main) — name --refs <base> <head>" >&2; exit 2; }
    files=$(worked "$on")
    packages=$({ sh tools/affected_packages.sh "$on" HEAD "$PWD" 2>/dev/null; printf '%s\n' $files | sed -n 's|^packages/\([^/]*\)/.*|\1|p'; } | sort -u)
    against="$line $(printf '%.8s' "$on")"
elif [ -n "$base" ]; then
    files=$(git diff --name-only --diff-filter=d "$base" "$head" -- '*.av')
    packages=$(sh tools/affected_packages.sh "$base" "$head" "$PWD" 2>/dev/null)
    against="$(printf '%.8s' "$(git rev-parse -q --verify "$base" || echo "$base")")..$(printf '%.8s' "$(git rev-parse -q --verify "$head" || echo "$head")")"
else
    against="the files named"
fi
echo "gate_changed: $(printf '%s\n' $files | grep -c .) .av changed vs $against, $(printf '%s\n' $packages | grep -c .) package(s):" $packages
if [ -z "$files" ]; then
    read -r tline ton <<EOF
$(trunk)
EOF
    if [ -n "${ton:-}" ] && [ -n "$(worked "$ton")" ]; then
        echo "gate_changed: examined no .av, yet $(worked "$ton" | wc -l | tr -d ' ') .av changed since this tree's trunk ($tline $(printf '%.8s' "$ton")) — refused; run it with no refs, or name that base" >&2
        exit 1
    fi
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

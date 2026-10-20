#!/bin/sh
# NO NEW PYTHON UNDER tools/: the instruments are one Avra package (tools/src, `avra-tools`), so a
# new `tools/*.py` is a refusal, and the baseline (tools/py.baseline) only ever shrinks — a port
# deletes its file in the commit that lands it, and nothing here adds a name to the list.
#
#   sh tools/no_new_py.sh            the keeper
#   sh tools/no_new_py.sh --self-test
set -eu
cd "$(dirname "$0")/.."
check() { # check <dir> <baseline>  — prints each new .py, answers its count
    n=0
    for f in "$1"/*.py; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        grep -qx "tools/$name" "$2" || { echo "no-new-py: tools/$name is new — the tools are Avra (tools/src, avra-tools); port it as a command, never add a .py"; n=$((n + 1)); }
    done
    return $n
}
if [ "${1:-}" = --self-test ]; then
    d=$(mktemp -d)
    printf 'tools/old.py\n' > "$d/base"
    : > "$d/old.py"
    check "$d" "$d/base" >/dev/null && ok1=1 || ok1=0
    : > "$d/fresh.py"
    out=$(check "$d" "$d/base" || true)
    [ "$ok1" = 1 ] || { echo "no_new_py: a listed file was refused"; exit 1; }
    printf '%s' "$out" | grep -q "tools/fresh.py is new" || { echo "no_new_py: a new .py was not refused"; exit 1; }
    echo "no_new_py: self-test passed — a listed file stands, a new one is refused by name"
    exit 0
fi
check tools tools/py.baseline && echo "no-new-py: $(ls tools/*.py | wc -l | tr -d ' ') .py file(s), none outside the baseline of $(wc -l < tools/py.baseline | tr -d ' ')" || { echo "no-new-py: refused"; exit 1; }

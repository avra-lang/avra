#!/bin/sh
# Every package through the program layer: what its laws find (`tapes --findings`) and what its program
# tests answer (`tapes --ran --left`), one row each; exit 1 when any accepted source carries an
# error-severity finding.
#
#   tools/program_refusals_sweep.sh [package dir]...
#
# With no arguments: every package under packages/, then tools/ui-board. AVRA names the compiler
# (default: the tree's build/avra-try). Each package's `.avra-cache` is emptied after its row, since a
# store per package fills the disk.
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$root/build/avra-try}
[ $# -gt 0 ] || set -- "$root"/packages/* "$root/tools/ui-board"
work=$(mktemp -d)
status=0
printf '%-22s %5s %6s %5s  %s\n' package find errors type "ran exit: tests/made/eval/native/failing"
for p in "$@"; do
  [ -f "$p/avra.toml" ] || continue
  pkg=$(cd "$p" && pwd)
  name=$(basename "$pkg")
  "$avra" tapes "$pkg" --findings > "$work/$name.find" 2>&1
  fe=$?
  "$avra" tapes "$pkg" --ran --left > "$work/$name.ran" 2>&1
  re=$?
  errors=$(grep -c '^error' "$work/$name.find")
  printf '%-22s %5s %6s %5s  %s: %s\n' "$name" "$fe" "$errors" "$(grep -c '^error\[type\.' "$work/$name.find")" "$re" \
    "$(grep -E '^ran:' "$work/$name.ran" | grep -oE '[0-9]+ (program|made|printing|natively|runs)' | grep -oE '^[0-9]+' | paste -sd/ -)"
  if [ "$errors" -gt 0 ]; then
    status=1
    grep -A3 '^error' "$work/$name.find" | head -20 | sed 's/^/    /'
  fi
  [ "$re" -eq 0 ] || grep -E '^fails:' "$work/$name.ran" | cut -c1-160 | sed 's/^/    /'
  find "$pkg" -name .avra-cache -type d -prune -exec find {} -mindepth 1 -delete \;
done
find "$work" -delete
exit $status

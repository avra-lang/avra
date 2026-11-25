#!/bin/sh
# The program layer's findings held to the old path's `check`, package by package, over the kinds the
# program layer holds: exit 1 when any package differs.
#
#   tools/program_findings_gate.sh [--old-dir DIR] [--except FRAGMENT]... <package dir>...
#
# --old-dir DIR reads the old leg from DIR/<package name>.check (`check <pkg>`'s stdout) and runs
# `check` only for a package with no such file, writing it there. AVRA names the compiler
# (default: the tree's build/avra-try). A block located in a path holding FRAGMENT is dropped from
# both sides.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${AVRA:-$root/build/avra-try}
old_dir=""
excepts=""
while [ $# -gt 0 ]; do
  case $1 in
    --old-dir) old_dir=$2; shift 2 ;;
    --except) excepts="$excepts --except $2"; shift 2 ;;
    *) break ;;
  esac
done
[ $# -gt 0 ] || { echo "usage: $0 [--old-dir DIR] [--except FRAGMENT]... <package dir>..." >&2; exit 2; }
work=$(mktemp -d)
[ -n "$old_dir" ] || old_dir=$work
mkdir -p "$old_dir"
status=0
for p in "$@"; do
  pkg=$(cd "$p" && pwd)
  name=$(basename "$pkg")
  "$avra" tapes "$pkg" --kinds > "$work/$name.kinds" || { echo "$name: --kinds failed"; status=1; continue; }
  "$avra" tapes "$pkg" --findings > "$work/$name.new" 2> "$work/$name.new.err"
  found=$?
  [ -s "$old_dir/$name.check" ] || "$avra" check "$pkg" > "$old_dir/$name.check" 2> "$work/$name.old.err"
  # shellcheck disable=SC2086
  if python3 "$root/tools/program_findings.py" compare "$work/$name.new" "$old_dir/$name.check" "$work/$name.kinds" $excepts > "$work/$name.diff"; then
    echo "$name: same — $(tail -1 "$work/$name.diff") (findings exit $found)"
  else
    echo "$name: DIFFERS — $(tail -1 "$work/$name.diff")"
    cat "$work/$name.diff"
    status=1
  fi
done
find "$work" -delete
exit $status

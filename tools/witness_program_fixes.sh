#!/bin/sh
# `avra fix` SAYS AND WRITES ON THE PROGRAM LAYER WHAT IT DOES ON THE OLD PATH. Each case under
# tools/program-fixes/ is a package of its own (tools/lib/cases.sh), copied cold for each path. Held
# alike, word for word: `fix --dry --json` (each application, its tier — proved, accepted by its
# rule's law, repaired, or only shown — and its edits), the same under `--repair`, and the file
# `fix` writes. A case holding `differs.why` is known to differ for the reason written there: said,
# not failed, while it differs, and failed once it holds.
#   sh tools/witness_program_fixes.sh [compiler] [case…]   (default build/avra, every case)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/tools/lib/cases.sh"
cases_dir="$root/tools/program-fixes"
avra=${1:-build/avra}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_program_fixes: no compiler at $avra" >&2; exit 1; }
[ $# -gt 0 ] && shift
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
# what `fix` says and writes of the case `$1` on the path `$2` (0 the old, 1 the program layer), its
# copy's path said as `<case>`
said() {
    c="$tmp/$1.$2"
    cp -R "$cases_dir/$1" "$c"
    find "$c" -name .avra-cache -prune -exec find {} -delete \;
    mkdir -p "$c.store"
    for flags in "--dry --json" "--dry --json --repair"; do
        (cd "$c" && AVRA_PROGRAM=$2 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$c.store" "$avra" fix $flags . >"$c.said" 2>/dev/null)
        code=$?
        sed "s#$c#<case>#g" "$c.said"
        echo "exit $code"
    done
    (cd "$c" && AVRA_PROGRAM=$2 AVRA_PROGRAM_NET=0 AVRA_CACHE_DIR="$c.store" "$avra" fix . >/dev/null 2>&1)
    cat "$c"/src/*.av
}
if [ $# -gt 0 ]; then names="$*"; else names=$(cases_in "$cases_dir"); leftovers_in "$cases_dir" | sed 's/^/witness_program_fixes: leftover /'; fi
held=0; failed=0; known=0
for name in $names; do
    said "$name" 0 > "$tmp/$name.old"
    said "$name" 1 > "$tmp/$name.new"
    why="$cases_dir/$name/differs.why"
    if cmp -s "$tmp/$name.old" "$tmp/$name.new"; then
        if [ -e "$why" ]; then echo "$name: holds now, yet differs.why says the paths differ — take the file away"; failed=$((failed + 1)); else held=$((held + 1)); fi
    elif [ -e "$why" ]; then
        echo "$name: known to differ — $(head -1 "$why")"; known=$((known + 1))
    else
        echo "$name: the program layer's fix differs from the old path's"; diff "$tmp/$name.old" "$tmp/$name.new" | head -12; failed=$((failed + 1))
    fi
done
echo "witness_program_fixes: $held of $((held + failed + known)) cases hold, $known known to differ, $failed failing"
[ "$failed" = 0 ]

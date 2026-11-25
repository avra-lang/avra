#!/bin/sh
# ONE FIXTURE OF THE SOUNDNESS SWEEP: the old `check` (net on), then the layer's `build` (net off),
# each bounded at 300 s; one TSV line on stdout:
#   path  old_exit  old_first  old_first_error  layer_exit  layer_first  layer_first_error
# where `first` is the first diagnostic as `error:kind` or `warning:kind`. The fixture's build
# products (its own `.avra-cache`, never a nested fixture's) are deleted after, so a sweep never
# fills the disk. A library, which declares no entry point, is checked by the layer instead.
# usage: one.sh <tree at d00e7c64, built> <out dir for logs> <fixture path relative to the tree>
tree=$1; out=$2; rel=$3; cd "$tree" || exit 0
mkdir -p "$out"
key=$(printf '%s' "$rel" | tr '/' '_')
first() { grep -m1 -oE '^(error|warning)\[[^]]+\]' "$1" | sed -E 's/^(error|warning)\[(.*)\]$/\1:\2/'; }
firsterr() { grep -m1 -oE '^error\[[^]]+\]' "$1" | sed -E 's/^error\[(.*)\]$/\1/'; }
AVRA_PROGRAM=0 AVRA_PROGRAM_NET=1 timeout 300 build/avra check "$rel" > "$out/$key.old" 2>&1; oe=$?
AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 timeout 300 build/avra build "$rel" > "$out/$key.new" 2>&1; ne=$?
# a package that declares no entry point is a library: nothing builds, so the layer CHECKS it
if [ $ne -ne 0 ] && grep -q "declares no entry point" "$out/$key.new"; then
    AVRA_PROGRAM=1 AVRA_PROGRAM_NET=0 timeout 300 build/avra check "$rel" > "$out/$key.new" 2>&1; ne=$?
fi
# this fixture's own build products only: a fixture nested inside it builds into its own
d=$rel; [ -d "$d" ] || d=$(dirname "$rel")
[ -d "$d/.avra-cache" ] && find "$d/.avra-cache" -delete 2>/dev/null
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$rel" "$oe" "$(first $out/$key.old)" "$(firsterr $out/$key.old)" "$ne" "$(first $out/$key.new)" "$(firsterr $out/$key.new)"

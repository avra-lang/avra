#!/bin/sh
# tool-witness: --self-test
# Runs each named keeper through a make command, says when one refuses, and ENDS with one line naming
# every refusal: a keeper that refuses mid-stream scrolls away under the ones after it, and the
# last lines of a log are what a reader (and a `tail`) sees.
#
#   sh tools/keepers_loop.sh "<make command>" <keeper>...
#   sh tools/keepers_loop.sh --self-test
set -u
if [ "${1:-}" = --self-test ]; then
    d=$(mktemp -d "${TMPDIR:-/tmp}/avra-keepers-loop.XXXXXX")
    cat > "$d/make.sh" <<'STUB'
#!/bin/sh
for k in "$@"; do case "$k" in k2|k4) exit 1 ;; esac; done
exit 0
STUB
    out=$(sh "$0" "sh $d/make.sh" k1 k2 k3 k4 k5 2>&1); st=$?
    [ "$st" = 1 ] || { echo "keepers_loop: a refusal did not exit 1 (got $st)"; exit 1; }
    [ "$(printf '%s\n' "$out" | tail -n 1)" = "keepers: REFUSED: k2 k4" ] \
        || { echo "keepers_loop: the last line did not name the refusals: $(printf '%s\n' "$out" | tail -n 1)"; exit 1; }
    out=$(sh "$0" "sh $d/make.sh" k1 k3 2>&1); st=$?
    [ "$st" = 0 ] && ! printf '%s\n' "$out" | grep -q REFUSED \
        || { echo "keepers_loop: a clean run exited $st or said REFUSED"; exit 1; }
    echo "keepers_loop: self-test passed — a mid-loop refusal is named on the last line, a clean run is silent"
    exit 0
fi
cmd=$1
shift
refused=""
for k in "$@"; do
    t0=$(date +%s)
    echo "keepers: running $k" >&2
    $cmd "$k" || { refused="$refused $k"; echo "keepers: $k refused" >&2; }
    echo "keepers: $k $(( $(date +%s) - t0 ))s"
done
[ -z "$refused" ] || { echo "keepers: REFUSED:$refused" >&2; exit 1; }

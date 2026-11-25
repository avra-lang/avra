#!/bin/sh
# A LAW SKIPPED BY THE KINDS IT NEEDS FINDS NOTHING IT WOULD HAVE FOUND: `law_findings` asks a law of
# an item only where the item holds a kind the law, each analysis it reads through, and each kind it
# judges need (`needs`, `through`, `on`), so a kind declared wrong drops a finding without a word.
# Every law not skipped is asked alike either way, so here each law skipped is asked of each item of
# each package's program it was skipped for, in one process per package (`avra tapes --needs`): one
# that finds something there is named with its item, and fails the witness. How many items each
# package held is said. Every package under packages/ and every refusal witness under
# tools/program-refusals/ is a case; the gate deals them across its `needs` slices.
#   sh tools/witness_program_needs.sh [compiler] [--jobs J] [package…]
#   sh tools/witness_program_needs.sh --cases    (every case, one per line)
#   (default build/avra-try; J defaults to 3; with no package, every case)
set -u
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
cases() { ls -d packages/*/ tools/program-refusals/*/ | sed 's#/$##'; }
if [ "${1:-}" = --cases ]; then cases; exit 0; fi
avra=build/avra-try
jobs=3
case "${1:-}" in packages/*|tools/*|--*|"") ;; *) avra=$1; shift ;; esac
if [ "${1:-}" = --jobs ]; then jobs=$2; shift 2; fi
[ -x "$avra" ] || { echo "witness_program_needs: no compiler at $avra" >&2; exit 1; }
case "$avra" in /*) ;; *) avra="$root/$avra" ;; esac
[ $# -gt 0 ] || set -- $(cases)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
held() { # held <package>: one line saying the package's hold, then any items apart
    p=$1
    out=$tmp/$(printf '%s' "$p" | tr '/' '_')
    if [ ! -d "$p" ]; then echo "$p: no package there" > "$out.said"; echo FAIL > "$out.verdict"; return; fi
    # the package's own store stands aside, and what this hold writes there is let go after
    had=no
    if [ -d "$p/.avra-cache" ]; then mv "$p/.avra-cache" "$out.aside"; had=yes; fi
    mkdir -p "$out.cache"
    AVRA_CACHE_DIR="$out.cache" "$avra" tapes --needs "$p" > "$out.out" 2> "$out.err"
    code=$?
    rm -rf "$out.cache" "$p/.avra-cache"
    if [ "$had" = yes ]; then mv "$out.aside" "$p/.avra-cache"; fi
    said=$(grep '^needs:' "$out.out" | tail -1)
    if [ -z "$said" ]; then
        { echo "$p: no hold said (exit $code)"; tail -3 "$out.err"; } > "$out.said"; echo FAIL > "$out.verdict"; return
    fi
    { echo "$p: ${said#needs: }"; grep '^apart:' "$out.out"; } > "$out.said"
    if [ "$code" = 0 ]; then echo OK > "$out.verdict"; else echo FAIL > "$out.verdict"; fi
}
n=0
for p in "$@"; do
    held "$p" &
    n=$((n + 1))
    if [ "$n" -ge "$jobs" ]; then wait; n=0; fi
done
wait
for p in "$@"; do cat "$tmp/$(printf '%s' "$p" | tr '/' '_').said"; done
failed=$(cat "$tmp"/*.verdict | grep -c FAIL)
if [ "$failed" = 0 ]; then
    echo "witness_program_needs: $# held, no law skipped by the kinds it needs finds anything"
    exit 0
fi
echo "witness_program_needs: $failed of $# apart or unheld"
exit 1

#!/bin/sh
# A VALIDATOR HANDED A RECORD CONST IS JUDGED AGAIN WHEN THAT CONST'S VALUE MOVES, wherever the
# move is written. A package whose `@impact(routine)` reads `routine`, a record const in another file
# whose grade reads `LIMIT` there, `BASE` of another package, and a fn. Built warm after each edit of
# one of them — values the validator refuses and passes, by turns — the warm build says and exits
# what a cold build of the same source does.
#   sh tools/witness_validator_upstream_const.sh [compiler]   (default build/avra-try)
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
[ -x "$avra" ] || { echo "witness_validator_upstream_const: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'find "$tmp" -delete' EXIT
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
pkg="$tmp/warm"
mkdir -p "$pkg/src/lib" "$pkg/vendor/v/src" "$tmp/warm.machine"
printf '[package]\nname = "warm"\nversion = "0.0.1"\n\n[dependencies]\n"@x/v" = { path = "vendor/v" }\n' >"$pkg/avra.toml"
printf '[package]\nname = "@x/v"\nversion = "0.0.1"\n' >"$pkg/vendor/v/avra.toml"
cat >"$pkg/src/main.av" <<'EOF'
use @std.meta.{Fn, Diagnostic, refuse}
use lib.{routine, Impact}
fn impact(_f: Fn, i: Impact) -> List<Diagnostic> { if i.grade > 3 { [refuse("too high")] } else { [] } }
@impact(routine)
fn work() -> int { 1 }
println("${work()}")
EOF
# `routine` in another file of the package reads `LIMIT` there, `BASE` of another package, and a fn
written() {
    printf 'use @x.v.{BASE}\nexport type Impact = { grade: int = 0, note: string = "" }\nfn bumped(n: int) -> int { n + %s }\nexport const LIMIT: int = %s\nexport const routine: Impact = Impact { grade: bumped(LIMIT + BASE), note: "low" }\n' "$3" "$1" >"$pkg/src/lib/a.av"
    printf 'export const BASE: int = %s\n' "$2" >"$pkg/vendor/v/src/v.av"
}
# what a build of the package says and how it exits, its warnings and its product aside
built() {
    (cd "$1" && AVRA_CACHE_DIR="$2" "$avra" build . 2>&1; echo "exit $?") | sed "s#$1#<pkg>#g" | awk '/^warning\[/ { w = 1; next } w { if ($0 == "") w = 0; next } { print }' | grep -v '^<pkg>/src/main$'
}
failed=0
built "$pkg" "$tmp/warm.machine" >/dev/null
for step in "5 1 0" "1 1 0" "1 9 0" "1 1 0" "1 1 5" "5 1 0"; do
    written $step
    warm=$(built "$pkg" "$tmp/warm.machine")
    cold_pkg="$tmp/cold"
    find "$tmp" -maxdepth 1 -name "cold*" -exec find {} -delete \;
    mkdir -p "$cold_pkg.machine"
    cp -R "$pkg" "$cold_pkg"
    find "$cold_pkg" -name .avra-cache -prune -exec find {} -delete \;
    cold=$(built "$cold_pkg" "$cold_pkg.machine" | sed "s#<pkg>#<pkg>#g")
    if [ "$warm" != "$cold" ]; then
        echo "witness_validator_upstream_const: LIMIT, BASE, the bump = $step: the warm build said otherwise than a cold one" >&2
        echo "--- warm:" >&2; echo "$warm" >&2; echo "--- cold:" >&2; echo "$cold" >&2
        failed=1
    fi
done
[ -n "${SHOW:-}" ] && echo "$warm"
[ "$failed" = 0 ] && echo "witness_validator_upstream_const: an upstream const in another file, another package, and a fn it calls, each edited — every warm build says what a cold one does"
exit "$failed"

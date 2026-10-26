#!/bin/sh
# THE SERVED MODEL'S WEIGHT ON A PAGE: a wasm program that imports an `@crud` model and reads its route
# data (tools/wasm-routes/served) is within a few bytes of the same program over a plain record with the route
# data written by hand (tools/wasm-routes/plain). The descriptor is two scalars; a rise past the cap means a
# handler, the database or a closure rode the model onto the page. The cap is an absolute byte count, never a
# ratio: the claim is that the derive adds nothing, so a few bytes of data is its whole allowance.
set -eu
. "$(dirname "$0")/lib/tree.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-wr.XXXXXX")
target=${WASM_TARGET:-wasm}
trap 'find "$work" -delete 2>/dev/null || true' EXIT
wasm_who=wasm-routes-size; . "$here/lib/wasm.sh"

needs_compiler

# THE DESCRIPTOR CARRIES NO SERVER CODE, wasm or not: the program over the served model defines no handler, router,
# database or decoder — only what the page reads. The check names what it examined, so an empty emit cannot pass.
ir="$work/served.ll"
"$avra" emit "$here/wasm-routes/served" > "$ir" 2>/dev/null || { say "the served page did not emit"; exit 1; }
defined=$(grep -a '^define' "$ir" | sed 's/(.*//')
[ -n "$(printf '%s\n' "$defined" | grep -a 'Todo.*paths')" ] || { say "the served page defines no Todo.paths — nothing was examined"; exit 1; }
leaked=$(printf '%s\n' "$defined" | grep -aE 'crud_routes|Wire|Mounted|sqlite|from_json|Todo.2Eroutes|Db.2E' || true)
[ -z "$leaked" ] || { say "REGRESSED — the served page defines server code: $leaked"; exit 1; }
say "the served page defines $(printf '%s\n' "$defined" | wc -l | tr -d ' ') fns and none of them is the server's"

needs_wasm_clang
wasm_ready || skip "the wasm runtime archive did not build"

cap=${WASM_ROUTES_CAP:-64}

# The bytes of one fixture built for the target, or empty when it will not build. Each build has a directory of
# its own, so one fixture's output is never mistaken for the other's.
bytes_of() { # fixture
    pkg="$work/$1"
    cp -R "$here/wasm-routes/$1" "$pkg"
    w=$(sh "$here/capped.sh" --last "$avra" build --target "$target" "$pkg" 2>/dev/null) || w=""
    [ -f "$w" ] || { echo ""; return; }
    stat -c%s "$w" 2>/dev/null || stat -f%z "$w"
}

plain=$(bytes_of plain)
[ -n "$plain" ] || { say "the plain page did not build"; exit 1; }
served=$(bytes_of served)
[ -n "$served" ] || { say "the page over an @crud model did not build"; exit 1; }
say "plain=${plain}B served=${served}B cap=${cap}B"
if [ "$served" -gt "$(( plain + cap ))" ]; then
    say "REGRESSED — the served model weighs $(( served - plain )) B more on a page than a plain record (cap ${cap}): something of the server rode the descriptor onto the page"
    exit 1
fi
say "the served model's route data is within its cap"

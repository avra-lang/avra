#!/bin/sh
# THE SERVED MODEL'S WEIGHT ON A PAGE. A wasm page that imports an `@crud` model and uses it as a record
# (tools/wasm-routes/imported) is within a few bytes of the same page over a plain record (plain); one that also
# reads the model's route data (served) adds the descriptor and nothing else. The IR of that page defines no
# handler, router, database or decoder. The caps are absolute byte counts, never ratios: a rise past one means
# something of the server rode the model, or the descriptor, onto the page.
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

# Importing a served model is free (a few bytes); reading its route data costs the descriptor, which is bounded.
cap=${WASM_ROUTES_CAP:-64}
reach_cap=${WASM_ROUTES_REACH_CAP:-4096}

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
imported=$(bytes_of imported)
[ -n "$imported" ] || { say "the page over an @crud model did not build"; exit 1; }
served=$(bytes_of served)
[ -n "$served" ] || { say "the page reading an @crud model's routes did not build"; exit 1; }
say "plain=${plain}B imported=${imported}B served=${served}B cap=${cap}B reach_cap=${reach_cap}B"
if [ "$imported" -gt "$(( plain + cap ))" ]; then
    say "REGRESSED — importing a served model weighs $(( imported - plain )) B on a page (cap ${cap}): something of the server rode the model onto it"
    exit 1
fi
if [ "$served" -gt "$(( imported + reach_cap ))" ]; then
    say "REGRESSED — reading the route data weighs $(( served - imported )) B (cap ${reach_cap}): something of the server rode the descriptor onto the page"
    exit 1
fi
say "importing a served model and reading its route data are within their caps"

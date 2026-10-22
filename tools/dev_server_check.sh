#!/bin/sh
# `avra dev` RUNS THE SERVER A PAGE NAMES: a page package whose manifest says
# `[dev] server = "server"` is served with its server beside it on one origin —
# a route the page does not own is answered by the server's program, built for
# this machine — and a save to the server's source is answered by the server
# built again, with no restart of `avra dev`.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-dev-server.XXXXXX")
fails=0
say() { echo "dev-server: $*"; }
fail() { fails=$((fails + 1)); say "FAILED $*"; }

mkdir -p "$work/page/src" "$work/page/server/src"
printf '[package]\nname = "dev-page"\nversion = "0.1.0"\n\n[dev]\nserver = "server"\n' > "$work/page/avra.toml"
printf 'use @std.ui.components.{text}\nuse @std.ui.web.{mount}\n\nmount(() -> text "page")\n' > "$work/page/src/main.av"
printf '[package]\nname = "dev-server"\nversion = "0.1.0"\n' > "$work/page/server/avra.toml"
served() {
    printf 'use @std.io.{env}\nuse @std.text.{parse_int}\nuse @std.http.route.{get, post}\nuse @std.http.server.{server}\n\nserver api {\n    port: parse_int(env("PORT") ?? "") ?? 0\n    get "/hello" { _req -> "%s" }\n    post "/echo" { req -> "echo " + (req.body.text() ?? "?") }\n}\nlet _ = api.run()\n' "$1" > "$work/page/server/src/main.av"
}
served "one"

"$avra" dev --port 0 "$work/page" > "$work/dev.out" 2> "$work/dev.err" &
dev=$!
trap 'kill "$dev" 2>/dev/null || true' EXIT
until grep -q '^dev: .* at http' "$work/dev.out" 2>/dev/null; do
    kill -0 "$dev" 2>/dev/null || { cat "$work/dev.err" "$work/dev.out"; say "avra dev ended before it served"; exit 1; }
    sleep 0.2
done
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/dev.out" | head -1)
tries=0
until grep -q '^dev: server .* runs on' "$work/dev.out" 2>/dev/null; do
    kill -0 "$dev" 2>/dev/null || { cat "$work/dev.err" "$work/dev.out"; say "avra dev ended before its server ran"; exit 1; }
    tries=$((tries + 1))
    [ "$tries" -lt 450 ] || { cat "$work/dev.out" "$work/dev.err"; say "FAILED avra dev never ran the server the page names (90 s)"; exit 1; }
    sleep 0.2
done
grep '^dev: server' "$work/dev.out" | tail -1

[ -n "${DEV_SERVER_DEBUG:-}" ] && { curl -si "${url}hello" | head -12; port=$(sed -n 's/^dev: server .* runs on 127.0.0.1:\([0-9]*\).*$/\1/p' "$work/dev.out" | tail -1); echo "--- the child itself on $port:"; curl -si "http://127.0.0.1:$port/hello" | head -8; cat "$work/dev.err" | tail -5; }
got=$(curl -s "${url}hello")
[ "$got" = "one" ] && say "ok    a route the page does not own is the server's: GET /hello -> $got" || fail "GET /hello answered '$got', wanted 'one'"
got=$(curl -s -X POST --data "sent" "${url}echo")
[ "$got" = "echo sent" ] && say "ok    a POST and its body reach the server: $got" || fail "POST /echo answered '$got', wanted 'echo sent'"
page=$(curl -s "$url")
case "$page" in *app.wasm*|*bootstrap.js*) say "ok    the page is still the page's" ;; *) fail "GET / is not the page: $(echo "$page" | head -c 80)";; esac
glue=$(curl -s -o /dev/null -w '%{http_code}' "${url}bootstrap.js")
[ "$glue" = "200" ] && say "ok    the page's glue is still the page's" || fail "GET /bootstrap.js answered $glue"

runs=$(grep -c '^dev: server .* runs on' "$work/dev.out")
served "two"
tries=0
until [ "$(grep -c '^dev: server .* runs on' "$work/dev.out")" -gt "$runs" ]; do
    tries=$((tries + 1)); [ "$tries" -lt 600 ] || { fail "a save to the server's source was never built"; break; }
    sleep 0.2
done
got=$(curl -s "${url}hello")
[ "$got" = "two" ] && say "ok    a save to the server's source is served without restarting dev: GET /hello -> $got" || fail "after the save GET /hello answered '$got', wanted 'two'"
kill -0 "$dev" 2>/dev/null && say "ok    the same dev process served both" || fail "dev ended"

[ "$fails" -eq 0 ] && { say "every claim holds"; exit 0; }
say "$fails claim(s) FAILED"; exit 1

#!/bin/sh
# `avra dev` RUNS THE SERVER A PAGE NAMES: a page package whose manifest says
# `[dev] server = "server"` is served with its server beside it on one origin —
# a route the page does not own is answered by the server's program, built for
# this machine — and a save to the server's source is answered by the server
# built again, with no restart of `avra dev`. The server writes no port: a
# `server` with none listens on `PORT` (how dev hands it one), else 8080, and a
# written `port` wins over `PORT`.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tree=$(cd "$here/.." && pwd)
avra=${AVRA:-$tree/build/avra}
work=$(mktemp -d "${TMPDIR:-/tmp}/avra-dev-server.XXXXXX")
who=dev-server
. "$tree/tools/lib/steps.sh"

mkdir -p "$work/page/src" "$work/page/server/src"
printf '[package]\nname = "dev-page"\nversion = "0.1.0"\n\n[dev]\nserver = "server"\n' > "$work/page/avra.toml"
printf 'use @std.ui.components.{text}\nuse @std.ui.web.{mount}\n\nmount(() -> text "page")\n' > "$work/page/src/main.av"
printf '[package]\nname = "dev-server"\nversion = "0.1.0"\n' > "$work/page/server/avra.toml"
served() {
    printf 'use @std.http.route.{get, post}\nuse @std.http.server.{server}\n\nserver api {\n    %s\n    get "/hello" { _req -> "%s" }\n    post "/echo" { req -> "echo " + (req.body.text() ?? "?") }\n}\nlet ran = api.run()\nif ran is .Err(e) { eprintln(e.describe().message) }\n' "${2:-}" "$1" > "${3:-$work/page/server}/src/main.av"
}
served "one"

# waits <seconds> <what> <test…>: the test polled every 0.2 s while dev lives,
# for no longer than the bound; past it, or with dev gone, a counted failure
# naming what was waited for, dev's own words beside it.
waits() {
    w_left=$(($1 * 5)); w_what=$2; shift 2
    until "$@"; do
        kill -0 "$dev" 2>/dev/null || { cat "$work/dev.err" "$work/dev.out"; fail "avra dev ended before $w_what"; verdict; exit 1; }
        w_left=$((w_left - 1))
        [ "$w_left" -gt 0 ] || { cat "$work/dev.out" "$work/dev.err"; fail "avra dev never $w_what ($1 s)"; verdict; exit 1; }
        sleep 0.2
    done
}
logged() { grep -q "$1" "$work/dev.out" 2>/dev/null; }
rebuilt() { [ "$(grep -c '^dev: server .* runs on' "$work/dev.out")" -gt "$runs" ]; }

"$avra" dev --port 0 "$work/page" > "$work/dev.out" 2> "$work/dev.err" &
dev=$!
trap 'kill "$dev" 2>/dev/null || true' EXIT
waits 90 "served the page" logged '^dev: .* at http'
url=$(sed -n 's/^dev: .* at \(http[^ ]*\).*$/\1/p' "$work/dev.out" | head -1)
waits 90 "ran the server the page names" logged '^dev: server .* runs on'
grep '^dev: server' "$work/dev.out" | tail -1

[ -n "${DEV_SERVER_DEBUG:-}" ] && { curl -si --max-time 10 "${url}hello" | head -12; port=$(sed -n 's/^dev: server .* runs on 127.0.0.1:\([0-9]*\).*$/\1/p' "$work/dev.out" | tail -1); echo "--- the child itself on $port:"; curl -si --max-time 10 "http://127.0.0.1:$port/hello" | head -8; cat "$work/dev.err" | tail -5; }
got=$(curl -s --max-time 10 "${url}hello")
[ "$got" = "one" ] && say "a route the page does not own is the server's: GET /hello -> $got" || fail "GET /hello answered '$got', wanted 'one'"
got=$(curl -s --max-time 10 -X POST --data "sent" "${url}echo")
[ "$got" = "echo sent" ] && say "a POST and its body reach the server: $got" || fail "POST /echo answered '$got', wanted 'echo sent'"
page=$(curl -s --max-time 10 "$url")
case "$page" in *app.wasm*|*bootstrap.js*) say "the page is still the page's" ;; *) fail "GET / is not the page: $(echo "$page" | head -c 80)";; esac
glue=$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' "${url}bootstrap.js")
[ "$glue" = "200" ] && say "the page's glue is still the page's" || fail "GET /bootstrap.js answered $glue"

runs=$(grep -c '^dev: server .* runs on' "$work/dev.out")
served "two"
waits 120 "built the save to the server's source" rebuilt
got=$(curl -s --max-time 10 "${url}hello")
[ "$got" = "two" ] && say "a save to the server's source is served without restarting dev: GET /hello -> $got" || fail "after the save GET /hello answered '$got', wanted 'two'"
kill -0 "$dev" 2>/dev/null && say "the same dev process served both" || fail "dev ended"
kill "$dev" 2>/dev/null || true

# The same program outside dev: no PORT is 8080, a PORT that is no port is
# refused, and a written port wins over PORT.
answered() { tries=0; until got=$(curl -s --max-time 2 "http://127.0.0.1:$1/hello") && [ -n "$got" ]; do tries=$((tries + 1)); [ "$tries" -lt 100 ] || return 1; [ -z "${2:-}" ] || kill -0 "$2" 2>/dev/null || return 1; sleep 0.1; done; echo "$got"; }
bin=$(sh "$here/capped.sh" --last "$avra" build "$work/page/server" 2>"$work/build.err") || fail "the page server did not build: $(tail -3 "$work/build.err")"
if curl -s --max-time 10 -o /dev/null "http://127.0.0.1:8080/" 2>/dev/null; then
    fail "something already answers on 8080, so the default cannot be witnessed"
else
    env -u PORT "$bin" > /dev/null 2>&1 &
    plain=$!
    got=$(answered 8080 || echo "nothing")
    kill "$plain" 2>/dev/null || true
    [ "$got" = "two" ] && say "with no PORT a server that writes no port listens on 8080" || fail "with no PORT, 127.0.0.1:8080 answered '$got'"
fi
PORT=abc "$bin" > /dev/null 2> "$work/bad.err" &
bad=$!
sleep 1
if kill -0 "$bad" 2>/dev/null; then kill "$bad"; fail "a PORT that is no port was served anyway"
elif grep -q "PORT=abc" "$work/bad.err"; then say "a PORT that is no port is refused: $(head -1 "$work/bad.err")"
else fail "a bad PORT ended the server without saying so: $(cat "$work/bad.err")"; fi
mkdir -p "$work/written/src"
printf '[package]\nname = "written"\nversion = "0.1.0"\n' > "$work/written/avra.toml"
# A port the OS handed out and released can be taken before the server binds it, so a server that
# ends on "Address already in use" is built again on a fresh port, never counted.
free_port() { python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])'; }
got=nothing
for attempt in 1 2 3 4 5; do
    written=${DEV_SERVER_PORT:-$(free_port)}
    served "written" "port: $written" "$work/written"
    wbin=$(sh "$here/capped.sh" --last "$avra" build "$work/written" 2>"$work/build.err") || fail "the written-port server did not build: $(tail -3 "$work/build.err")"
    PORT=1 "$wbin" > /dev/null 2> "$work/written.err" &
    w=$!
    got=$(answered "$written" "$w" || echo "nothing")
    kill "$w" 2>/dev/null || true
    grep -q "Address already in use" "$work/written.err" || break
    say "port $written was taken before the server bound it; again on a fresh one"
    unset DEV_SERVER_PORT
done
[ "$got" = "written" ] && say "a written port wins over PORT: :$written answered, PORT=1 ignored" || fail "a server writing port $written answered '$got'"

verdict "every claim holds"

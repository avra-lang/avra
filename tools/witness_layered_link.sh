#!/bin/sh
# A LAYERED BUILD RUNS THE BODY THAT MOVED. Built with AVRA_PROGRAM_MODE=dev, a
# program links as a world and an overlay: a bucket that moves since the world
# was linked goes to the overlay, and the world must not keep its own copy, or a
# caller in the world would still run the old body. The program's entry and four
# callers in their own files each call `said()` in a fifth; `said()` is edited
# twice, a caller once, and the edits are taken back, a warm build after each —
# every product must print what its own source says. The world must keep at least
# one bucket through the edits of `said()`, so a caller it holds calls across into
# the overlay. Each step says its link commands (AVRA_LINK_TRACE) and what the
# product printed; the last line is PASS or FAIL.
#   sh tools/witness_layered_link.sh [compiler]   (default build/avra-try)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
avra=${1:-build/avra-try}
case $avra in /*) ;; *) avra="$root/$avra" ;; esac
tmp=$(mktemp -d)
verdict=FAIL
finish() { find "$tmp" -delete; echo "witness_layered_link: $verdict"; }
trap finish EXIT
[ -x "$avra" ] || { echo "witness_layered_link: no compiler at $avra" >&2; exit 1; }
export AVRA_PROGRAM=1 AVRA_PROGRAM_MODE=dev AVRA_LINK_TRACE=1 AVRA_CACHE_DIR="$tmp/machine"
mkdir -p "$tmp/machine" "$tmp/p/src"
p="$tmp/p"
layers="$p/.avra-cache/tapes-build/layers"
printf '[package]\nname = "layered"\nversion = "0.0.1"\n' >"$p/avra.toml"
for i in 1 2 3 4; do
    printf 'use said.{said}\n\n/// What caller %s says.\nexport fn by%s() -> string { "%s:${said()}" }\n' "$i" "$i" "$i" >"$p/src/by$i.av"
done
printf 'use by1.{by1}\nuse by2.{by2}\nuse by3.{by3}\nuse by4.{by4}\nuse said.{said}\n\nprintln("${said()} ${by1()} ${by2()} ${by3()} ${by4()}")\n' >"$p/src/main.av"
said() { printf '/// What the program says.\nexport fn said() -> string { "%s" }\n' "$1" >"$p/src/said.av"; }

# build, saying its links, run, and hold the output to what the source says
step=0
expect() {
    step=$((step + 1))
    echo "witness_layered_link: build $step: $avra build $p"
    if ! "$avra" build "$p" >"$tmp/log" 2>&1; then
        grep '^link: ' "$tmp/log" | sed 's/^/  /' || :
        echo "witness_layered_link: build $step failed:" >&2; grep -v '^link: ' "$tmp/log" | tail -8 >&2; exit 1
    fi
    grep '^link: ' "$tmp/log" | sed 's/^/  /' || :
    got=$("$p/src/main" 2>&1) || { echo "witness_layered_link: build $step's product failed to run: $got" >&2; exit 1; }
    echo "  ran: $got"
    [ "$got" = "$1" ] || { echo "witness_layered_link: build $step printed \`$got\`, its source says \`$1\`" >&2; exit 1; }
}
world_keys() { cat "$layers"/world-*/keys.txt; echo; }
overlay_keys() { cat "$layers"/overlay/keys.txt 2>/dev/null || :; }

said one
expect "one 1:one 2:one 3:one 4:one"
cold=$(world_keys)
said two
expect "two 1:two 2:two 3:two 4:two"
[ -n "$(overlay_keys)" ] || { echo "witness_layered_link: an edit linked no overlay" >&2; exit 1; }
kept=$(world_keys | grep -cxF "$cold" || :)
[ "$kept" -gt 0 ] || { echo "witness_layered_link: the world kept no bucket, so nothing calls across" >&2; exit 1; }
said three
expect "three 1:three 2:three 3:three 4:three"
sed -i.bak 's/"1:/"one:/' "$p/src/by1.av"
expect "three one:three 2:three 3:three 4:three"
mv "$p/src/by1.av.bak" "$p/src/by1.av"
said one
expect "one 1:one 2:one 3:one 4:one"
echo "witness_layered_link: every product ran what its source says"
verdict=PASS

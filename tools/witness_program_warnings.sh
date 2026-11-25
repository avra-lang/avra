#!/bin/sh
# tool-witness: run by the gate's warnings-* slice (tools/gate.sh), never twice
# A PROGRAM-LAYER BUILD WARNS, AND WARNS AS THE OLD PATH DID. The cli built cold says warnings, a
# no-op build again says the same ones, and a warm build of an edit that adds one says it too. Each
# package under tools/program-warnings/ warns on the program layer exactly as its `warns.expected`
# says: the old path's warnings of it, its last word, frozen at cbc437f4 before its deletion. Empties
# every `.avra-cache` under packages/ and its own machine stores.
#   sh tools/witness_program_warnings.sh [compiler]   (default build/avra-try)
#   WITNESS_ONLY names its parts, each alone or several: `cold` (the cli built cold and again with no
#   change), `edit` (the cli edited, built warm over its cold build), `builds` (both), `cases`
#   (tools/program-warnings/).
set -eu
# a store is copied, counted or emptied here between builds, so each build saves its own before it answers
export AVRA_STORE_KEPT_HERE=1
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${1:-build/avra-try}
[ -x "$avra" ] || { echo "witness_program_warnings: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
file=packages/cli/src/commands/fmt.av
line='type FmtCmd = {}'
becomes='type FmtCmd = {}\nenum Quarter { North, East, South, West }\nfn quartered(q: Quarter) -> int { match q { .North -> 1, .East -> 2, _ -> 0 } }'
cp "$file" "$tmp/orig.av"
restore() { cp "$tmp/orig.av" "$file"; find "$tmp" -delete; }
trap restore EXIT
[ "$(grep -cxF "$line" "$file")" = 1 ] || { echo "witness_program_warnings: \`$line\` is not one line of $file" >&2; exit 1; }

cold() {
    for d in $(find packages -name .avra-cache -type d -prune); do find "$d" -mindepth 1 -delete; done
    mkdir -p "$tmp/machine"; find "$tmp/machine" -mindepth 1 -delete
}
built() {
    if ! "$@" "$avra" build packages/cli >/dev/null 2>"$tmp/err"; then
        echo "witness_program_warnings: the build failed:" >&2; tail -5 "$tmp/err" >&2; exit 1
    fi
}
# Each warning of `$1`, one per paragraph, as one line: its words, its frame, its help.
warnings() { awk '/^warning\[/ { on = 1 } on && /^$/ { print ""; on = 0; next } on { printf "%s\x1f", $0 } END { if (on) print "" }' "$1" | grep -v '^$'; }
held() {
    built env AVRA_CACHE_DIR="$tmp/machine"
    warnings "$tmp/err" > "$tmp/$1.new"
}
# Each warning of `$1` as its own paragraph, a blank line after each, as a `warns.expected` holds them.
paragraphs() { awk '/^warning\[/ { on = 1 } on && /^$/ { print ""; on = 0; next } on { print }' "$1"; }

# a part named by WITNESS_ONLY, or every part when it names none
wanted() { [ -z "${WITNESS_ONLY:-}" ] || printf ' %s ' "$WITNESS_ONLY" | grep -q " $1 "; }

cold
if wanted builds || wanted cold || wanted edit; then
    held cold
    [ -s "$tmp/cold.new" ] || { echo "witness_program_warnings: the program layer said no warning" >&2; exit 1; }
    echo "witness_program_warnings: cold — $(wc -l < "$tmp/cold.new" | tr -d ' ') warning(s)"
fi
if wanted builds || wanted cold; then
    held noop
    cmp -s "$tmp/noop.new" "$tmp/cold.new" || { echo "witness_program_warnings: a no-op build warns otherwise than the cold one" >&2; exit 1; }
    echo "witness_program_warnings: no-op — the cold build's warnings"
fi
# the edit: the program layer's build of it, warm over its cold store
if wanted builds || wanted edit; then
    awk -v a="$line" -v b="$becomes" '$0 == a { print b; next } { print }' "$tmp/orig.av" > "$file"
    held edit
    [ "$(wc -l < "$tmp/edit.new")" -gt "$(wc -l < "$tmp/cold.new")" ] || { echo "witness_program_warnings: the edit's warning is not said" >&2; exit 1; }
    grep -vFxf "$tmp/cold.new" "$tmp/edit.new" | tr '\037' '\n' | grep -q '^warning\[' || { echo "witness_program_warnings: the edit's warning is not said" >&2; exit 1; }
    echo "witness_program_warnings: warm edit adding a warning — said"
fi

# Each case under tools/program-warnings/ is a package of its own, built cold in a copy of its own:
# its warnings must be its `warns.expected`, word for word.
cp "$tmp/orig.av" "$file"
if wanted cases; then
    . tools/lib/cases.sh
    leftovers_in tools/program-warnings | sed 's/^/witness_program_warnings: leftover /'
    for name in $(cases_in tools/program-warnings); do
        d="tools/program-warnings/$name/"
        c="$tmp/case-$name"
        cp -R "$d" "$c"
        [ -e "$d/warns.expected" ] || { echo "witness_program_warnings: case $name holds no warns.expected" >&2; exit 1; }
        mkdir -p "$c-store"
        AVRA_CACHE_DIR="$c-store" "$avra" build "$c" >/dev/null 2>"$c.err" || {
            echo "witness_program_warnings: case $name does not build:" >&2; tail -5 "$c.err" >&2; exit 1
        }
        paragraphs "$c.err" | sed "s|$c|<case>|g" > "$c.said"
        if ! cmp -s "$d/warns.expected" "$c.said"; then
            echo "witness_program_warnings: case $name — the program layer's warnings are not its warns.expected" >&2
            diff "$d/warns.expected" "$c.said" | head -30 >&2
            exit 1
        fi
        echo "witness_program_warnings: case $name — $(grep -c '^warning\[' "$c.said") warning(s) as warns.expected says them"
    done
fi

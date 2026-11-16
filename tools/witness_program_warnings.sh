#!/bin/sh
# A PROGRAM-LAYER BUILD WARNS AS THE OLD PATH DOES, for every kind it holds a law of. The cli is
# built cold on the program layer and on the old path, and every warning the old path says of such a
# kind the program layer must say too, in the same words and the same order; a warning the program
# layer says beyond them is named (the old path says none for a file only a `use` of a module
# within its directory reaches), an old-path warning tools/program-warnings.known excuses is named
# and not required, and the old path's warnings of a kind the program layer has no law for are
# counted by kind. A no-op build then says the same
# warnings, and so does a warm build of an edit that adds one, as the old path does. Then each
# package under tools/program-warnings/ warns on the program layer exactly as on the old path, and
# `check` of the cli says, on both paths, what the build says and its rules find, held alike. Empties every
# `.avra-cache` under packages/ and its own machine stores.
#   sh tools/witness_program_warnings.sh [compiler]   (default build/avra-try)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
avra=${1:-build/avra-try}
[ -x "$avra" ] || { echo "witness_program_warnings: no compiler at $avra" >&2; exit 1; }
tmp=$(mktemp -d)
file=packages/cli/src/commands/fmt.av
line='enum Outcome { Canonical, Differs, Refused }'
becomes='enum Outcome { Canonical, Differs, Refused }\nenum Quarter { North, East, South, West }\nfn quartered(q: Quarter) -> int { match q { .North -> 1, .East -> 2, _ -> 0 } }'
cp "$file" "$tmp/orig.av"
restore() { cp "$tmp/orig.av" "$file"; find "$tmp" -delete; }
trap restore EXIT
[ "$(grep -cxF "$line" "$file")" = 1 ] || { echo "witness_program_warnings: \`$line\` is not one line of $file" >&2; exit 1; }

cold() {
    for d in $(find packages -name .avra-cache -type d -prune); do find "$d" -mindepth 1 -delete; done
    for m in "$tmp/machine" "$tmp/machine-old"; do mkdir -p "$m"; find "$m" -mindepth 1 -delete; done
}
built() {
    if ! "$@" "$avra" build packages/cli >/dev/null 2>"$tmp/err"; then
        echo "witness_program_warnings: the build failed:" >&2; tail -5 "$tmp/err" >&2; exit 1
    fi
}
# Each warning of `$1`, one per paragraph, as one line: its words, its frame, its help.
warnings() { awk '/^warning\[/ { on = 1 } on && /^$/ { print ""; on = 0; next } on { printf "%s\x1f", $0 } END { if (on) print "" }' "$1" | grep -v '^$'; }
held() {
    built env AVRA_PROGRAM=1 AVRA_CACHE_DIR="$tmp/machine"
    warnings "$tmp/err" > "$tmp/$1.new"
}
old() {
    built env AVRA_PROGRAM=0 AVRA_CACHE_DIR="$tmp/machine-old"
    warnings "$tmp/err" > "$tmp/$1.old"
}
# The old path's warnings of the kinds `$1.new` says, against `$1.new` itself.
alike() {
    kinds=$(sed 's/\].*//' "$tmp/$1.new" | sort -u)
    kinds="$kinds" awk 'BEGIN { n = split(ENVIRON["kinds"], ks, "\n"); for (i = 1; i <= n; i++) want[ks[i]] = 1 } { k = $0; sub(/\].*/, "", k); if (k in want) print }' "$tmp/$1.old" > "$tmp/$1.kinds"
    excused "$tmp/$1.kinds" > "$tmp/$1.excused"
    grep -vFxf "$tmp/$1.excused" "$tmp/$1.kinds" > "$tmp/$1.held" || :
    grep -Fxf "$tmp/$1.held" "$tmp/$1.new" > "$tmp/$1.kept" || :
    grep -vFxf "$tmp/$1.held" "$tmp/$1.new" > "$tmp/$1.beyond" || :
    if ! cmp -s "$tmp/$1.held" "$tmp/$1.kept"; then
        echo "witness_program_warnings: $2 — the program layer's warnings are not the old path's" >&2
        diff "$tmp/$1.held" "$tmp/$1.kept" | tr '\037' '\n' | head -30 >&2
        exit 1
    fi
    echo "witness_program_warnings: $2 — $(wc -l < "$tmp/$1.kept" | tr -d ' ') warning(s) as the old path says them, $(wc -l < "$tmp/$1.beyond" | tr -d ' ') beyond them"
    tr '\037' '\n' < "$tmp/$1.beyond" | grep '╭─\[' | sed 's/.*╭─\[/  beyond: /; s/\]$//' || :
    tr '\037' '\n' < "$tmp/$1.excused" | grep '╭─\[' | sed 's/.*╭─\[/  excused: /; s/\]$//' || :
}
# The warnings of `$1` tools/program-warnings.known excuses: its file and its words both match a line.
excused() {
    grep -v '^#' tools/program-warnings.known | while IFS='	' read -r path words _why; do
        if [ "$path" = '*' ]; then grep -F "$words" "$1" || :; else grep -F "/$path:" "$1" | grep -F "$words" || :; fi
    done | sort -u
}

cold
held cold
old cold
[ -s "$tmp/cold.new" ] || { echo "witness_program_warnings: the program layer said no warning" >&2; exit 1; }
alike cold "cold"
echo "witness_program_warnings: no law on the program layer yet:"
sed 's/\].*//; s/^warning\[//' "$tmp/cold.old" | sort | uniq -c | while read -r n k; do
    grep -q "^warning\[$k\]" "$tmp/cold.new" || echo "  $k $n"
done
held noop
cmp -s "$tmp/noop.new" "$tmp/cold.new" || { echo "witness_program_warnings: a no-op build warns otherwise than the cold one" >&2; exit 1; }
echo "witness_program_warnings: no-op — the cold build's warnings"
awk -v a="$line" -v b="$becomes" '$0 == a { print b; next } { print }' "$tmp/orig.av" > "$file"
held edit
old edit
[ "$(wc -l < "$tmp/edit.new")" -gt "$(wc -l < "$tmp/cold.new")" ] || { echo "witness_program_warnings: the edit's warning is not said" >&2; exit 1; }
alike edit "warm edit adding a warning"
# `check` of the cli says what its build says and what its rules find, on both paths alike.
checked() {
    if ! env $1 AVRA_CACHE_DIR="$tmp/$2-store" "$avra" check packages/cli >"$tmp/out" 2>"$tmp/err"; then
        echo "witness_program_warnings: check failed on the $2 path:" >&2; tail -5 "$tmp/err" >&2; exit 1
    fi
    warnings "$tmp/out" > "$tmp/check.$2"
}
cp "$tmp/orig.av" "$file"
checked AVRA_PROGRAM=1 new
checked AVRA_PROGRAM=0 old
alike check "check"

# Each case under tools/program-warnings/ is a package of its own, built cold on both paths in a
# copy of its own: the program layer's warnings must be the old path's, word for word, and there
# must be some.
cp "$tmp/orig.av" "$file"
for d in tools/program-warnings/*/; do
    name=$(basename "$d")
    c="$tmp/case-$name"
    cp -R "$d" "$c"
    for side in old new; do
        mkdir -p "$c-$side-store"
        if [ "$side" = new ]; then run="env AVRA_PROGRAM=1"; else run="env AVRA_PROGRAM=0"; fi
        $run AVRA_CACHE_DIR="$c-$side-store" "$avra" build "$c" >/dev/null 2>"$c.$side.err" || {
            echo "witness_program_warnings: case $name does not build on the $side path:" >&2; tail -5 "$c.$side.err" >&2; exit 1
        }
        warnings "$c.$side.err" | sed "s|$c|<case>|g" > "$c.$side"
    done
    [ -s "$c.old" ] || { echo "witness_program_warnings: case $name warns of nothing on the old path" >&2; exit 1; }
    if ! cmp -s "$c.old" "$c.new"; then
        echo "witness_program_warnings: case $name — the program layer's warnings are not the old path's" >&2
        diff "$c.old" "$c.new" | tr '\037' '\n' | head -30 >&2
        exit 1
    fi
    echo "witness_program_warnings: case $name — $(wc -l < "$c.new" | tr -d ' ') warning(s) as the old path says them"
done

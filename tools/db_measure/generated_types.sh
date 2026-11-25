#!/bin/sh
# A COMMENT ABOVE N GENERATED TYPES, MEASURED. DB 09's receipt: a settlement
# that touches 1,000 named types, and a comment inserted above them, must cost
# <= 0.06 s warm (0.25 s today). The types are written by this script — one
# `type Tk = { n: int }` each, one const whose initializer constructs every one
# of them — so the source is generated, its text digest moves on the comment,
# and every `t` line kept_settle holds for the settlement is judged again.
#
# The fixture ASSERTS before it measures: the const answers its sum cold, the
# comment does not move it, and a literal it reads DOES move it. A fixture that
# only timed would pass while the cache answered anything.
#
#   sh tools/db_measure/generated_types.sh [count] [rounds]
# Answers one line per run: label, wall ms, status, and the compiler's own
# `time:` line where it printed one. `AVRA_BIN` names the binary (default
# ./avra, so the shim's lock and watchdog apply).
set -u
N=${1:-1000}
R=${2:-3}
A=${AVRA_BIN:-./avra}
here=$(cd "$(dirname "$0")/../.." && pwd)
root=${TMPDIR:-/tmp}/avra_gen_types.$$
out=$root.out
if [ -n "${AVRA_KEEP:-}" ]; then
    trap 'find "$out" "$out.orig" "$out.err" -delete 2>/dev/null' EXIT INT TERM
    echo "kept	$root"
else
    trap 'find "$root" -depth -delete 2>/dev/null; find "$out" "$out.orig" "$out.err" -delete 2>/dev/null' EXIT INT TERM
fi
now() { date +%s%N; }
ms() { echo $((($(now) - $1) / 1000000)); }

# THE PACKAGE: `count` types, and one const that constructs every one of them,
# so the settlement resolves all `count` named types and keeps a `t` line for
# each. `src/main.av` settles it and prints it.
generated() {
    count=$1
    mkdir -p "$root/src"
    printf '[package]\nname = "gentypes"\nversion = "0.1.0"\n' > "$root/avra.toml"
    {
        echo '//! generated: one type per line, and one const that builds them all.'
        i=0
        while [ "$i" -lt "$count" ]; do
            echo "type T$i = { n: int }"
            i=$((i + 1))
        done
        printf 'export const TOTAL: int = '
        [ "$count" -gt 0 ] || printf '0'
        i=0
        while [ "$i" -lt "$count" ]; do
            [ "$i" -gt 0 ] && printf ' +\n    '
            printf 'T%s { n: %s }.n' "$i" "$((i + 1))"
            i=$((i + 1))
        done
        echo
    } > "$root/src/types.av"
    printf 'use types.{TOTAL}\n\nprintln("${TOTAL}")\n' > "$root/src/main.av"
}

# THE SUM OF 1..count, which the const must answer.
expected() { echo $((($1 * ($1 + 1)) / 2)); }

# `avra run` over the program: what it printed, or `<status N>`.
answered() {
    "$A" run "$root/src/main.av" 2> "$out.err" | tr -d '\n'
    st=$?
    [ "$st" = 0 ] || echo "<status $st>"
}

# One `check` of the package: label, wall ms, status, and the `time:` line.
checked() {
    s=$(now)
    "$A" check --time "$root" > "$out" 2>&1
    st=$?
    echo "$1	wall_ms=$(ms "$s")	status=$st	$(grep '^time:' "$out" | tail -n 1)"
}

# A comment inserted at the head of the file, so its text digest moves and no
# declaration's syntax does. Each round writes text no earlier round wrote.
commented() {
    cp "$root/src/types.av" "$out.orig"
    python3 - "$out.orig" "$root/src/types.av" "$1" <<'PY'
import sys
orig, dest, word = sys.argv[1:4]
text = open(orig, encoding="utf-8").read()
open(dest, "w", encoding="utf-8").write("// " + word + "\n" + text)
PY
}

# THE RECEIPT THAT THE FIXTURE EXAMINES SOMETHING: the value cold, the value
# under a comment insert, and the value after a literal the const reads moves.
asserts() {
    count=$1
    sum=$(expected "$count")
    got=$(answered)
    [ "$got" = "$sum" ] || { echo "ASSERT FAIL: cold answered \`$got\`, wanted \`$sum\`"; return 1; }
    [ -e "$root/.avra-cache" ] || "$A" check "$root" > "$out" 2>&1
    commented "a comment above the generated types"
    got=$(answered)
    [ "$got" = "$sum" ] || { echo "ASSERT FAIL: after a comment answered \`$got\`, wanted \`$sum\`"; return 1; }
    # A literal the const READS, moved: the kept verdict must not stand.
    cp "$out.orig" "$root/src/types.av"
    python3 - "$root/src/types.av" <<'PY'
import sys
p = sys.argv[1]
text = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(text.replace("T0 { n: 1 }.n", "T0 { n: 1000000 }.n", 1))
PY
    got=$(answered)
    moved=$((sum + 999999))
    [ "$got" = "$moved" ] || { echo "ASSERT FAIL: after a literal edit answered \`$got\`, wanted \`$moved\`"; return 1; }
    cp "$out.orig" "$root/src/types.av"
    echo "asserts	ok	cold=$sum	commented_same=yes	literal_moved=$moved"
}

# A package's store, emptied: the fixture must measure a COLD settlement.
cooled() {
    find "$root" -name .avra-cache -type d -prune -exec sh -c 'find "$1" -depth -delete' _ {} \;
}

open_package() {
    generated "$1"
    cooled
    checked "cold_$1"
    checked "noop_$1"
}

echo "tree	$here	count=$N	rounds=$R	binary=$A"
open_package 0 || exit 1
commented "a comment above no generated types"
checked "comment_0"
open_package "$N" || exit 1
asserts "$N" || exit 1
i=1
while [ "$i" -le "$R" ]; do
    commented "a comment above the generated types $i"
    checked "comment_$N.$i"
    i=$((i + 1))
done

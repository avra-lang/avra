#!/bin/sh
# The formatter's receipt. A formatter owes LOSSLESSNESS — `fmt(x) == x`
# up to canonical spelling — not idempotence: a second pass has nothing
# left to lose, so `fmt(fmt(x)) == fmt(x)` passes while `fmt(x) != x`.
#
# It renders EVERY `.av` under `packages/` and reports what did not come
# back, one class per line. The classes are counted separately because a
# single number hides them:
#
#   own    — a `//` alone on its line: a remark, the trivia cursor's job.
#            This includes a `//` inside a raw `grammar { }` body, which the
#            grammar DSL drops (avra-8sb5.11.114) — the one named exception.
#   doc    — a `///` line (avra-8sb5.11.104 holds the non-declaration ones)
#   trail  — a `//` sharing its line with code (avra-8sb5.11.112)
#
# NO `flat` CLASS, AND THE REASON IS MEASURED. A one-line-brace class was
# tried and DELETED: it is a proxy that CORRELATES, so it reads as coverage
# while measuring the printer's string handling. Three patterns were measured
# over the tree and all three moved on their own — any one-line `{…}` nets
# NEGATIVE (the printer renders struct/map literals one-line itself);
# keyword/`=`/`->` anywhere nets worse (it counts `if … { … }` embedded in
# strings); line-start keywords INFLATE the output, because `fmt` re-spells a
# triple-quoted string as an escaped one-liner and this script's `\n`
# un-escape re-expands its embedded code. What decides preserve-vs-expand is
# the PRINTER, at the body; a receipt for it belongs at that decision site
# (a spec test over generated probes), never in a regex guessing at it.
#
# A class's count is a DIFF of the same awk over input and output, so a
# misread line (a `//` inside a string) appears on both sides and cancels.
set -u
avra=${AVRA:-build/avra}
root=${1:-.}
# a `shift` past `$#` ends the script under dash, whatever follows it
[ "$#" -gt 0 ] && shift
if [ "$#" -gt 0 ]; then
    list=$*
else
    list=$(find "$root/packages" -name '*.av' | sort)
fi
files=0
refused=0
lost_files=0
own=0
doc=0
trail=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

counts() {
    # `\n` inside a string literal is a line break the lexer sees as
    # text; re-expanding it keeps the count from calling a re-spelled
    # string a lost comment (a `fmt` writes a triple-quoted string as
    # one escaped line).
    awk 'BEGIN{own=0;doc=0;trail=0}
         { gsub(/\\n/, "\n")
           n = split($0, part, "\n")
           for (i = 1; i <= n; i++) {
             l = part[i]; sub(/^[ \t]+/, "", l)
             if (l == "") continue
             if (l ~ /^\/\/\//) {doc++; continue}
             if (l ~ /^\/\//) {own++; continue}
             if (index(part[i], "//") > 0) {trail++}
           } }
         END{printf "%d %d %d\n", own, doc, trail}' "$1"
}

for f in $list; do
    files=$((files + 1))
    out="$work/out.av"
    if ! "$avra" fmt "$f" > "$out" 2>/dev/null; then
        refused=$((refused + 1))
        continue
    fi
    set -- $(counts "$f")
    io=$1; id=$2; it=$3
    set -- $(counts "$out")
    oo=$1; od=$2; ot=$3
    if [ "$io" -ne "$oo" ] || [ "$id" -ne "$od" ] || [ "$it" -ne "$ot" ]; then
        lost_files=$((lost_files + 1))
        echo "$f  own $io->$oo  doc $id->$od  trail $it->$ot"
    fi
    own=$((own + io - oo))
    doc=$((doc + id - od))
    trail=$((trail + it - ot))
done

echo "fmt_roundtrip: $files file(s) rendered, $refused refused, $lost_files with a deficit"
echo "fmt_roundtrip: lost own-line remarks $own, doc lines $doc, trailing comments $trail"

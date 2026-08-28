#!/bin/sh
# Error tolerance is the product: deterministic mutations of every
# corpus program run through `avra check`, which must DIAGNOSE (exit
# 0-2) and never crash (signal-grade exit). Standalone, not in the
# gate (spawn-heavy) — run after grammar or lexer work.
set -u
cd "$(dirname "$0")/.."
fails=0
n=0
for f in corpus/*.av; do
    base=$(basename "$f" .av)
    for m in head1 head2 noparen dupbrace dropfirst reversed noquote; do
        out="build/fuzz_${base}_${m}.av"
        case "$m" in
            head1) head -c $(( $(wc -c < "$f") / 3 + 1 )) "$f" > "$out" ;;
            head2) head -c $(( $(wc -c < "$f") * 2 / 3 + 1 )) "$f" > "$out" ;;
            noparen) tr -d '(' < "$f" > "$out" ;;
            dupbrace) sed 's/{/{{/g' "$f" > "$out" ;;
            dropfirst) tail -n +2 "$f" > "$out" ;;
            reversed) tail -r "$f" > "$out" 2>/dev/null || tac "$f" > "$out" ;;
            noquote) tr -d '"' < "$f" > "$out" ;;
        esac
        ./avra check "$out" > /dev/null 2>&1
        code=$?
        n=$((n + 1))
        if [ "$code" -gt 2 ]; then
            echo "fuzz: CRASH (exit $code) on $out"
            fails=$((fails + 1))
        else
            rm -f "$out"
        fi
    done
done
if [ "$fails" -eq 0 ]; then
    echo "fuzz: $n mutants, all diagnosed, none crashed"
else
    echo "fuzz: $fails crash(es) — mutant files kept in build/"
fi
exit "$fails"

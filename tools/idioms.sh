#!/bin/sh
# The idiom ratchet: mechanical smells the compiler cannot judge yet,
# counted and pinned. A count ABOVE its baseline fails the build — new
# code writes the idiomatic form (DOGFOODING.md, by I-code), or bumps
# tools/idioms.baseline deliberately in the same commit, where review
# sees it. Counts falling is progress: run `make idioms-accept`.
#
# Rules are DELIBERATELY noisy — the baseline absorbs today's
# licensed sites; only a RISE fails. Species without rules, and why:
#   I5  dedupe folds — the remaining sites are duplicate-DETECTION
#       (they emit on the dup); the union cases use core distinct().
#   I6  head-plus-tail builds — subsumed by I1/I3.
#   I10 name->value if-ladders — too few and too varied to grep;
#       the review round hunts them.
# The whole script dies into the per-feature idiom engine (ROADMAP,
# Era IV) once idiom rules are Avra fns over Avra's own AST.
set -u
cd "$(dirname "$0")/.."
SRC="packages/std-avrac/src packages/cli/src"
BASE=tools/idioms.baseline

g() { # plain pattern search over product+test sources
    grep -rnE --include="*.av" "$1" $SRC 2>/dev/null | grep -v "spec_test" || true
}

count_rule() {
    case "$1" in
        I1)  g 'mut [a-z_]+: *List<[^>]*> *= *\[\]' | wc -l ;;
        I2)  g 'cx\.store\.expr\(cx\.(value_at|eval)\(' | wc -l ;;
        I3)  g 'for [a-z_0-9]+ in [^{]+\{ [a-z_]+\.push\(' | wc -l ;;
        I4)  g 'mut [a-z_]+: [A-Za-z_<>]+\? = null' | wc -l ;;
        I7)  g '\[[a-z_]+\.length - 1\]' | wc -l ;;
        I8)  g 'cx\.store\.stmt_value\(' | wc -l ;;
        I9)  g '\.index != |\.index == ' | grep -v tests | wc -l ;;
        I11) grep -rhoE --include="*.av" '"[a-z][^"]{15,}"' $SRC --exclude-dir=tests 2>/dev/null \
                 | grep -v spec_test | grep -vE '^"[a-z]+\.[a-z_]+"$' \
                 | sort | uniq -c | awk '$1 >= 2' | wc -l ;;
        I12) grep -rhoE --include="*.av" '[A-Z][a-zA-Z]+ \{ [^{}]* \}' $SRC 2>/dev/null \
                 | grep -v spec_test | sort | uniq -c | awk '$1 >= 2' | wc -l ;;
        I13) /usr/bin/grep -rn --include="*.av" \
                 'name_at(\([a-z!._]*\)).*name_at(\1)\|type_name(\([a-z!._]*\)).*type_name(\2)\|shape_at(\([a-z!._]*\)).*shape_at(\3)' \
                 $SRC 2>/dev/null | grep -v spec_test | wc -l ;;
        I14) grep -rn --include="*.av" -A4 '\.emit(pointed(' $SRC 2>/dev/null \
                 | grep -v spec_test | grep -c 'intern(Type.Error)' ;;
    esac
}

show_rule() { # the offending material, printed on a regression
    case "$1" in
        I11) grep -rhoE --include="*.av" '"[a-z][^"]{15,}"' $SRC --exclude-dir=tests 2>/dev/null \
                 | grep -v spec_test | grep -vE '^"[a-z]+\.[a-z_]+"$' \
                 | sort | uniq -c | awk '$1 >= 2' ;;
        I12) grep -rhoE --include="*.av" '[A-Z][a-zA-Z]+ \{ [^{}]* \}' $SRC 2>/dev/null \
                 | grep -v spec_test | sort | uniq -c | awk '$1 >= 2' ;;
        I13) /usr/bin/grep -rn --include="*.av" \
                 'name_at(\([a-z!._]*\)).*name_at(\1)\|type_name(\([a-z!._]*\)).*type_name(\2)\|shape_at(\([a-z!._]*\)).*shape_at(\3)' \
                 $SRC 2>/dev/null | grep -v spec_test ;;
        I14) grep -rn --include="*.av" -A4 '\.emit(pointed(' $SRC 2>/dev/null \
                 | grep -v spec_test | grep -B4 'intern(Type.Error)' ;;
        I1)  g 'mut [a-z_]+: *List<[^>]*> *= *\[\]' ;;
        I2)  g 'cx\.store\.expr\(cx\.(value_at|eval)\(' ;;
        I3)  g 'for [a-z_0-9]+ in [^{]+\{ [a-z_]+\.push\(' ;;
        I4)  g 'mut [a-z_]+: [A-Za-z_<>]+\? = null' ;;
        I7)  g '\[[a-z_]+\.length - 1\]' ;;
        I8)  g 'cx\.store\.stmt_value\(' ;;
        I9)  g '\.index != |\.index == ' | grep -v tests ;;
    esac
}

rule_words() {
    case "$1" in
        I1)  echo "an empty-list accumulator — is this loop a MAP? write the comprehension" ;;
        I2)  echo "the spelled-out evaluated-payload chain — use cx.int_at / truth_at / elems_at" ;;
        I3)  echo "a single-line for-push — a map (comprehension) or an extend (concat/flatten)" ;;
        I4)  echo "a nullable flag local — is this scan a find/index_of? (reverse scans are licensed)" ;;
        I7)  echo "last-element index arithmetic — use .last()! (exception: rebind-alias mutation)" ;;
        I8)  echo "the spelled statement-value ritual — use cx.walk_value / eval_value / lower_value" ;;
        I9)  echo "a hand-rolled type-id comparison — is this the agreement law? use types_disagree" ;;
        I11) echo "a long string duplicated in product code — shared messages are fns, defined once" ;;
        I12) echo "an identical struct literal written twice — name its constructor" ;;
        I13) echo "the same projection twice in one expression — bind it once" ;;
        I14) echo "emit-then-intern(Error) — the refusal tail is spoken(cx, d)" ;;
    esac
}

RULES="I1 I2 I3 I4 I7 I8 I9 I11 I12 I13 I14"

if [ "${1:-}" = "--accept" ]; then
    : > "$BASE"
    for r in $RULES; do
        echo "$r $(count_rule "$r" | tr -d ' ')" >> "$BASE"
    done
    echo "idioms: baseline accepted:"
    cat "$BASE"
    exit 0
fi

fail=0
summary=""
for r in $RULES; do
    base=$(grep "^$r " "$BASE" | awk '{print $2}')
    [ -z "$base" ] && base=0
    now=$(count_rule "$r" | tr -d ' ')
    summary="$summary $r=$now/$base"
    if [ "$now" -gt "$base" ]; then
        echo "idiom $r regressed: $(rule_words "$r")"
        echo "  baseline $base, now $now — the material:"
        show_rule "$r" | sed 's/^/    /'
        fail=1
    fi
done

if [ "$fail" -eq 0 ]; then
    echo "idioms: no regressions ($summary )"
else
    echo "idioms: write the idiomatic form (DOGFOODING.md), or bump tools/idioms.baseline in this commit."
fi
exit $fail

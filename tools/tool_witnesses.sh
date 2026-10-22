#!/bin/sh
# THE TOOLS' OWN WITNESSES, DERIVED. No list names them: a hand list let
# witnesses and self-tests be written and run by nobody.
#
# A witness is `tools/witness_*.sh` or `tools/*_test.sh`, run bare, or a tool
# that declares `# tool-witness: --self-test`, run with it. A witness another
# keeper runs declares `# tool-witness: run by <keeper>` and is that keeper's.
# A tool that answers --self-test is refused unless it declares one of the two
# or a Makefile recipe runs its self-test: an undeclared self-test is one
# nobody runs.
#
#   sh tools/tool_witnesses.sh list         each witness and who runs it
#   sh tools/tool_witnesses.sh run          run the ones that are this keeper's
#   sh tools/tool_witnesses.sh --self-test
# A root other than the tree is `WITNESS_ROOT=<dir>`.

root="${WITNESS_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# The shapes that ANSWER --self-test (a tool that only calls another's is no witness).
answers='("\$\{?1(:-)?\}?"|\$1) *= *"?--self-test|--self-test\)|["'"'"']--self-test["'"'"'] *(in|==)|== *\[?["'"'"']--self-test|add_argument\(["'"'"']--self-test'

# list: `<tool> <mode> <who>` a line; mode is `bare` or `--self-test`, who is
# `here`, `run by <keeper>`, or `UNDECLARED`
list() {
    for f in "$root"/tools/*.sh "$root"/tools/*.py; do
        [ -f "$f" ] || continue
        name=${f##*/}
        held=$(sed -n 's/^#[[:space:]]*tool-witness:[[:space:]]*\(run by .*\)/\1/p' "$f" | head -1)
        case "$name" in
            tool_witnesses.sh) continue ;;
            witness_*.sh|*_test.sh) echo "$name bare ${held:-here}"; continue ;;
        esac
        if grep -q '^#[[:space:]]*tool-witness:[[:space:]]*--self-test' "$f"; then
            echo "$name --self-test here"
        elif [ -n "$held" ]; then
            echo "$name --self-test $held"
        elif grep -qE -- "$answers" "$f"; then
            if grep -qE "^	.*tools/$name[^;|&]*--self-test" "$root/Makefile"; then
                echo "$name --self-test run by make"
            else
                echo "$name --self-test UNDECLARED"
            fi
        fi
    done
}

run() {
    undeclared=$(list | awk '$3 == "UNDECLARED" { print $1 }')
    if [ -n "$undeclared" ]; then
        for n in $undeclared; do
            echo "tool-witnesses: tools/$n answers --self-test and no keeper runs it — declare \`# tool-witness: --self-test\` (or \`run by <keeper>\`)"
        done
        return 1
    fi
    fail="" n=0
    for w in $(list | awk '$3 == "here" { print $1 ":" $2 }'); do
        name=${w%%:*} mode=${w#*:}
        n=$((n + 1))
        case "$name" in *.py) cmd=python3 ;; *) cmd=sh ;; esac
        if [ "$mode" = bare ]; then
            $cmd "$root/tools/$name" || fail="$fail [$name]"
        else
            $cmd "$root/tools/$name" --self-test || fail="$fail [$name]"
        fi
    done
    [ -z "$fail" ] || { echo "tool-witnesses: refused —$fail"; return 1; }
    echo "tool-witnesses: $n witness(es) run here, each proved on its fixtures"
}

self_test() {
    t=$(mktemp -d) || exit 1
    trap 'find "$t" -delete' EXIT
    mkdir -p "$t/tools"
    printf '# tool-witness: --self-test\n[ "$1" = --self-test ]\n' > "$t/tools/a.sh"
    printf 'exit 0\n' > "$t/tools/witness_b.sh"
    printf '# tool-witness: run by make keeper\nexit 0\n' > "$t/tools/c_test.sh"
    printf 'if "--self-test" in argv: pass\n' > "$t/tools/d.py"
    printf '[ "$1" = --self-test ]\n' > "$t/tools/e.sh"
    printf 'echo plain\nsh tools/a.sh --self-test\n' > "$t/tools/f.sh"
    printf 'keeper:\n\t@python3 tools/d.py --self-test\n' > "$t/Makefile"
    got=$(WITNESS_ROOT=$t sh "$0" list | tr '\n' ';')
    want="a.sh --self-test here;c_test.sh bare run by make keeper;e.sh --self-test UNDECLARED;witness_b.sh bare here;d.py --self-test run by make;"
    fails=0
    [ "$got" = "$want" ] || { fails=$((fails + 1)); echo "tool_witnesses: FAIL — list: got '$got'"; }
    WITNESS_ROOT=$t sh "$0" run > /dev/null 2>&1 && { fails=$((fails + 1)); echo "tool_witnesses: FAIL — an undeclared self-test ran clean"; }
    printf '# tool-witness: --self-test\n[ "$1" = --self-test ]\n' > "$t/tools/e.sh"
    out=$(WITNESS_ROOT=$t sh "$0" run 2>&1) || { fails=$((fails + 1)); echo "tool_witnesses: FAIL — a declared tree refused: $out"; }
    printf 'exit 1\n' > "$t/tools/witness_b.sh"
    WITNESS_ROOT=$t sh "$0" run > /dev/null 2>&1 && { fails=$((fails + 1)); echo "tool_witnesses: FAIL — a failing witness ran clean"; }
    [ "$fails" = 0 ] || exit 1
    echo "tool_witnesses: self-test passed — 4 fixtures (the list's three sources and two owners, an undeclared self-test refused, a declared tree run, a failing witness refused)"
}

case "$1" in
    list) list ;;
    run) run ;;
    --self-test) self_test ;;
    *) echo "usage: sh tools/tool_witnesses.sh list|run|--self-test" >&2; exit 2 ;;
esac

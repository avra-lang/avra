#!/bin/sh
# A BUILD'S STATUS NEVER DIES IN A PIPE. `avra build … | tail -n 1` answers tail's status, so a
# failed build, run or make reads as whatever its last line was. Its spelling is
# `sh tools/capped.sh --last <cmd>` (the line and the command's status) or a capped log; this
# refuses a build, run, make or node piped into `tail` anywhere else. A pipe that is not a
# status's (its producer's failure is judged on another line) says so at its site:
# `# tail-status: <reason>`.
#
#   sh tools/tail_status.sh [<file>…]    the tree's shell, Makefile and workflows when none named
#   sh tools/tail_status.sh --self-test
set -u

# The lines of the named files that pipe a build, run, make or node into tail.
sites() {
    grep -nHE '(\./avra|build/avra|"\$avra"|\$\{?AVRA[}[:space:]]|(^|[^[:alnum:]_.-])make[[:space:]]|(^|[^[:alnum:]_.-])node[[:space:]])[^|#;)]*\|[[:space:]]*tail([[:space:]]|$)' "$@" 2>/dev/null |
        grep -v '# tail-status: '
}

if [ "${1:-}" = --self-test ]; then
    d=$(mktemp -d)
    trap 'rm -rf "$d"' EXIT
    fails=0
    refuses() { printf '%s\n' "$2" > "$d/f.sh"; [ -n "$(sites "$d/f.sh")" ] || { fails=$((fails + 1)); echo "tail_status: did not refuse $1"; }; }
    accepts() { printf '%s\n' "$2" > "$d/f.sh"; [ -z "$(sites "$d/f.sh")" ] || { fails=$((fails + 1)); echo "tail_status: refused $1"; }; }
    refuses "a build's last line" 'bin=$(./avra build $R/p | tail -1)'
    refuses "a named compiler's build" 'w=$("$avra" build --target wasm "$work/min" 2>/dev/null | tail -n 1)'
    refuses "an AVRA run" 'run() { $AVRA run $R/p 2>&1 | tail -1; }'
    refuses "build/avra" 'built=$(build/avra build tools | tail -n 1)'
    refuses "a make" 'make -s libs 2>&1 | tail -5'
    refuses "a node script" 'said=$(node t.js | tail -1)'
    accepts "capped --last" 'bin=$(sh tools/capped.sh --last ./avra build $R/p)'
    accepts "a captured string" 'bin=$(printf '"'"'%s\n'"'"' "$out" | tail -1)'
    accepts "a status taken first" 'out=$(./avra build x 2>e); st=$?; bin=$(printf x | tail -1)'
    accepts "a file read" 'held=$(grep -oE "held [0-9]+" $R/err | tail -1)'
    accepts "a licensed site" 'make -s x | tail -3  # tail-status: the next line checks the log'
    accepts "a word ending in make" 'remake x | tail -1; cmake y | tail -1'
    [ "$fails" = 0 ] && { echo "tail_status: self-test passed — 6 refusals and 6 accepts"; exit 0; }
    exit 1
fi

if [ $# = 0 ]; then
    cd "$(dirname "$0")/.."
    set -- $(find tools .github -name '*.sh' -not -name capped.sh -not -name tail_status.sh) Makefile .github/workflows/*.yml
fi
found=$(sites "$@")
if [ -n "$found" ]; then
    printf '%s\n' "$found"
    echo "tail_status: a build, run, make or node piped into tail loses its status — \`sh tools/capped.sh --last <cmd>\`, or \`# tail-status: <reason>\` where the status is judged elsewhere"
    exit 1
fi
echo "tail_status: clean — $# file(s) read, no status piped into tail"

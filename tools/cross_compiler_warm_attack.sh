#!/bin/sh
# A STORE WARMED BY ANOTHER COMPILER GENERATION KEEPS WHAT THE NEXT ONE PARSES. The published
# compiler (A) warms a store over the tree; the tree's own compiler (B, build/avra) checks it twice,
# then every edit is held to the count below. Then A builds the tree (gen 1), gen 1 builds it again
# (gen 2), and gen 2 is what checks: its first check is a hit, and every one-literal edit after it
# must parse exactly the edited file and the two that read it (shared.av, main.av, std-cli's
# cli.av) — never the files the store held from the generations before. A hold that trusts a row
# the new compiler never re-kept re-parses a changed dependency (core/digest.av in #1176) or a
# hundred files on every edit. It CLEARS the store, as the attacks beside it do. A = the
# published compiler of origin/main (or of ATTACK_WARM_KEY), or ATTACK_WARM_COMPILER; with neither it REFUSES — an attack
# that examined nothing is not a pass. Needs a machine the published compiler runs on.
set -u
cd "$(dirname "$0")/.."
fails=0
edited=packages/cli/src/commands/shared.av
fail() { fails=$((fails + 1)); echo "FAIL  $1"; }
if [ -n "${ATTACK_WARM_COMPILER:-}" ]; then
    cp "$ATTACK_WARM_COMPILER" build/avra-warm || { echo "cross_compiler_warm: cannot read ATTACK_WARM_COMPILER"; exit 1; }
else
    mkdir -p build/warm-from
    FETCH_BUILD=build/warm-from sh tools/fetch_compiler.sh ${ATTACK_WARM_KEY:+--key $ATTACK_WARM_KEY} >/dev/null 2>&1 \
        && cp build/warm-from/avra build/avra-warm \
        || { echo "cross_compiler_warm: no published compiler to warm with (set ATTACK_WARM_COMPILER)"; exit 1; }
fi
chmod +x build/avra-warm
find .avra-cache -type f -delete 2>/dev/null
orig=$(mktemp)
cp "$edited" "$orig"
restore() { cp "$orig" "$edited"; find "$orig" -delete; }
trap restore EXIT INT TERM
parsed() { # parsed <compiler> -> count of distinct files parsed by one check
    AVRA_QTRACE=1 "$1" check packages/cli 2>build/cross-warm.err >/dev/null || { fail "check exited non-zero under $1"; return; }
    grep -a '^Q	parse	' build/cross-warm.err | cut -f3 | sort -u | grep -c .
}
build_with() { # build_with <compiler> <out>
    "$1" build packages/cli >build/cross-warm.build 2>&1 || { tail -n 8 build/cross-warm.build; fail "build under $1 refused"; return 1; }
    cp packages/cli/src/main "$2"
    find packages/cli/src/main packages/cli/src/main.av.ll -delete 2>/dev/null
    chmod +x "$2"
}
edits() { # edits <compiler> <label>: one check unchanged, then three fresh literal edits
    n=$(parsed $1)
    [ "$n" = 0 ] && echo "$2 unchanged: 0 file(s) parsed" || fail "$2: unchanged check parsed $n file(s), wanted 0"
    nonce=$(date +%s)
    i=0
    while [ "$i" -lt 3 ]; do
        i=$((i + 1))
        cp "$orig" "$edited"
        python3 - "$edited" "· memo" "x$nonce$i" <<'PY'
import sys
path, lit, word = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(text.replace(lit, lit + " " + word, 1))
PY
        n=$(parsed $1)
        echo "$2 edit $i: $n file(s) parsed"
        [ "$n" = 3 ] || fail "$2: edit $i parsed $n file(s), wanted 3 (shared.av, main.av, std-cli cli.av)"
    done
    cp "$orig" "$edited"
}
[ -x build/avra ] || { echo "cross_compiler_warm: no tree compiler at build/avra"; exit 1; }
parsed build/avra-warm >/dev/null
echo "B first check: $(parsed build/avra) file(s) parsed"
edits build/avra "B"
find .avra-cache -type f -delete 2>/dev/null
parsed build/avra-warm >/dev/null
build_with build/avra-warm build/avra-gen1 || exit 1
build_with build/avra-gen1 build/avra-gen2 || exit 1
echo "gen 2 first check: $(parsed build/avra-gen2) file(s) parsed"
edits build/avra-gen2 "gen 2"
if [ "$fails" -eq 0 ]; then echo "cross_compiler_warm: clean"; else echo "cross_compiler_warm: $fails failure(s)"; exit 1; fi

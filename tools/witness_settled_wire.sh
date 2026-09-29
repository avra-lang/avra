#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/witness_settled_wire.sh`
#
# A HELD CONST'S VALUE ROUND-TRIPS THE WIRE, for the three shapes a
# component instance takes: DATA that settles (a `flag`/`option`
# instance, `compiler/lower/state.av`'s `settles(ty)` answers true),
# BEHAVIOUR that never settles (a `rule` — `component rule`'s `run:
# fn(Code) -> Fix?` field is an identity, `settles` answers false),
# and a plain `const` unrelated to instances at all
# (`grammar_of_grammars`). `check --baseline` twice over the SAME
# `.avra-cache`: the first run is cold and writes what it can settle;
# the second reads packages/std-cli, packages/std-avrac and
# packages/std-grammar as HELD, and a held const whose row expects a
# value that was never written answers `language.defect: a held
# const's value did not decode` — the witness is that neither run
# says so.
#
# MEMCAP names the memory-cap wrapper each check runs under (cap 4000 MB).
set -u

memcap="${MEMCAP:?MEMCAP must name the memory-cap wrapper, memcap.sh}"
tree="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d "${TMPDIR:-/tmp}/avra-witness-wire.XXXXXX")"

export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
cd "$tree" || exit 1

# A cold store is what makes the first run's write the only source for
# the second run's read. Caches are regenerable build state, never
# restored — same as tools/witness_held_instance.sh's own cold start.
mkdir -p "$logs/caches-aside"
find . -name .avra-cache -type d -prune | while read -r c; do
    mv "$c" "$logs/caches-aside/$(echo "${c#./}" | tr / _)"
done

run() { # run <label>
    st=0
    for pkg in std-cli std-avrac std-grammar; do
        sh "$memcap" 4000 build/avra check "packages/$pkg" --baseline tools/idioms.baseline >> "$logs/$1.log" 2>&1 || st=1
    done
    echo "$st" > "$logs/$1.exit"
}

run cold
run warm

decoded() { grep -c 'did not decode' "$logs/$1.log"; }
printf 'cold: exit %s | held-const decode failures %s\n' "$(cat "$logs/cold.exit")" "$(decoded cold)"
printf 'warm: exit %s | held-const decode failures %s\n' "$(cat "$logs/warm.exit")" "$(decoded warm)"
echo "logs: $logs"

# Neither pass may report a held const that failed to decode — the
# defect this witness exists to catch, whichever run would show it.
[ "$(decoded cold)" = 0 ] && [ "$(decoded warm)" = 0 ]

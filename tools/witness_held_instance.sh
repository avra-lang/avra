#!/bin/sh
# `MEMCAP=<memcap.sh> sh tools/witness_held_instance.sh [<test file>]`
#
# A HELD FILE'S DECLARED INSTANCES, READ BY A MODULE THAT MOVED. `compiler.rules`
# collects every `rule` instance in the program, and the instances live in
# `features`. Build the package's suite cold, then move one fn in the `compiler`
# module and build again over the warm store: `features` stands as kept objects,
# `compiler` is read, and the collect calls each held instance's unit. That call
# must close and link, and the suite must run: the warm answer is the cold one.
#
# A held file's object provides everything the file declares, so a declared
# instance's unit is the file's own body and a held instance is named by a stub.
# Without that the warm build either refuses to close over the instance's symbol
# or links a program whose collect reads a hole.
#
# A standalone witness, never a gate step: two whole-package suite builds. It moves
# one fn body in `compiler/cache_walk.av` and puts the file back on the way out, checked
# byte for byte.
#
# MEMCAP names the memory-cap wrapper each build runs under (cap 4000 MB).
set -u

memcap="${MEMCAP:?MEMCAP must name the memory-cap wrapper, memcap.sh}"
suite="${1:-packages/std-avrac/src/compiler/tests/publish_test.av}"
tree="$(cd "$(dirname "$0")/.." && pwd)"
logs="$(mktemp -d "${TMPDIR:-/tmp}/avra-witness-held.XXXXXX")"
moved=packages/std-avrac/src/compiler/cache_walk.av

export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
AVRA_WATCH_HELD=1
export AVRA_WATCH_HELD

cd "$tree" || exit 1

# The file comes back whatever ends the run: an edit left behind is part of the compiler's source.
cp "$moved" "$logs/moved.av.orig"
back() {
    cp "$logs/moved.av.orig" "$moved"
    cmp -s "$logs/moved.av.orig" "$moved" || echo "witness_held_instance: $moved NOT restored — the original is $logs/moved.av.orig" >&2
}
trap back EXIT INT TERM

# A cold store is what makes the second build the only one that holds.
mkdir -p "$logs/caches-aside"
find . -name .avra-cache -type d -prune | while read -r c; do
    mv "$c" "$logs/caches-aside/$(echo "${c#./}" | tr / _)"
done

build() { # build <label>
    sh "$memcap" 4000 build/avra test "$suite" > "$logs/$1.log" 2>&1
    echo $? > "$logs/$1.exit"
}

build cold
# one fn's body moves; no signature does
moved_fn='fn module_shown(name: string) -> string { if name == "" { "the root module" } else { name } }'
python3 - "$moved" "$moved_fn" <<'PY' || { echo "witness_held_instance: the fn to move is gone from $moved" >&2; exit 2; }
import sys
path, old = sys.argv[1], sys.argv[2]
text = open(path).read()
assert old in text
open(path, "w").write(text.replace(old, old.replace('"the root module"', '"the root module, moved"'), 1))
PY
build warm

held_line() { grep -E 'tests passed' "$logs/$1.log" | tail -1; }
report() {
    printf '%s: exit %s | %s | not closed %s | undefined %s | stopped %s\n' "$1" "$(cat "$logs/$1.exit")" \
        "$(held_line "$1")" \
        "$(grep -c 'not closed' "$logs/$1.log")" \
        "$(grep -c 'Undefined symbols' "$logs/$1.log")" \
        "$(grep -c 'STOPPED' "$logs/$1.log")"
}
report cold
report warm
echo "logs: $logs"

# The warm build answers what the cold one did, and says so: a build that ran
# no cases has no answer to compare.
[ "$(cat "$logs/cold.exit")" = 0 ] && [ "$(cat "$logs/warm.exit")" = 0 ] &&
    [ -n "$(held_line cold)" ] && [ "$(held_line cold)" = "$(held_line warm)" ]

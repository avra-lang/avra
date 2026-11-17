#!/bin/sh
# A TYPING NAMES THE NODES OF THE STORE IT CHECKED. An item read back is held in a store that its
# bodies' elaborations grow with the sugar nodes they mint; let go, it is read back afresh without
# them. A typing kept from the grown store holds entries past the fresh one's end, so a law that
# walks a kept typing over the store it reads now runs past that store. One program, built cold
# twice: as the process holds items, and with every item let go as soon as another is read
# (`AVRA_HELD_BYTES=1`), which puts a fresh store under a typing kept from a grown one. Both
# builds must pass, with the same binary and the same words.
#
#   sh tools/held_store_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${HELD_ATTACK_AVRA:-$(pwd)/avra}
R=build/held-store-attack
rm -rf "$R" && mkdir -p "$R"
unset AVRA_PROGRAM AVRA_PROGRAM_NET AVRA_HELD_BYTES AVRA_HELD_ITEMS_OFF

# The program, in a store of its own, cold: the soak driver, whose std reaches bodies with sugar
# beside siblings in one item.
program() {
    p=$R/soak
    rm -rf "$p" && mkdir -p "$p/src"
    printf '[package]\nname = "held-soak"\nversion = "0.1.0"\n' > "$p/avra.toml"
    cp packages/std-http-soak/src/main.av "$p/src/main.av"
    own_store "$p"
}

# The program built cold and whole in one place, the items held bounded by `$2` bytes where given;
# its binary and its words kept as `$1`.
built() {
    program
    if [ -n "${2:-}" ]; then
        AVRA_HELD_BYTES="$2" "$A" build --release "$R/soak" > "$R/$1.words" 2>&1 || { echo "BUILD FAILED: $(grep -m1 -i 'avra:\|error' "$R/$1.words")"; return; }
    else
        "$A" build --release "$R/soak" > "$R/$1.words" 2>&1 || { echo "BUILD FAILED: $(grep -m1 -i 'avra:\|error' "$R/$1.words")"; return; }
    fi
    cp "$R/soak/src/main" "$R/$1.bin"
    echo built
}

steps=$((steps + 1)); held=$(built held)
[ "$held" = built ] || fail "held: $held"
steps=$((steps + 1)); let_go=$(built let-go 1)
[ "$let_go" = built ] || fail "every item let go: $let_go"
if [ "$held" = built ] && [ "$let_go" = built ]; then
    steps=$((steps + 1))
    cmp -s "$R/held.bin" "$R/let-go.bin" || fail "the binaries differ: items read again are not the same items"
    steps=$((steps + 1))
    cmp -s "$R/held.words" "$R/let-go.words" || fail "the builds say different words: $(diff "$R/held.words" "$R/let-go.words" | head -3)"
fi
verdict "held-store-attack: $steps step(s)" "held and let go"

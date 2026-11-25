#!/bin/sh
# A TYPING NAMES THE NODES OF THE STORE IT CHECKED. An item read back is held in a store that its
# bodies' elaborations grow with the sugar nodes they mint; let go, it is read back afresh without
# them. A typing kept from the grown store holds entries past the fresh one's end, so a law that
# walks a kept typing over the store it reads now runs past that store. One program, built cold
# twice: as the process holds items, and with every item let go as soon as another is read
# (`AVRA_HELD_BYTES=1`), which puts a fresh store under a typing kept from a grown one. Both
# builds must pass, with the same binary and the same words.
#
# A literal an elaboration mints is named by its turn among the literals alike before it in its
# store, so a store a sibling's elaboration grew would count the sibling's: the second program's
# impl has two methods whose instances each fill an equal list from `@says`, and the hash of the code
# reaching both, which names that literal, is printed. Built as the process holds items and with
# every item read afresh (`AVRA_HELD_ITEMS_OFF`), it must print the same.
#
#   sh tools/held_store_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${HELD_ATTACK_AVRA:-$(pwd)/avra}
R=build/held-store-attack
rm -rf "$R" && mkdir -p "$R"
unset AVRA_HELD_BYTES AVRA_HELD_ITEMS_OFF

# The program `$1` (soak or turn), in a store of its own, cold: the soak driver, whose std reaches
# bodies with sugar beside siblings in one item; or two sibling methods filling equal literals.
program() {
    p=$R/$1
    rm -rf "$p" && mkdir -p "$p/src"
    printf '[package]\nname = "held-%s"\nversion = "0.1.0"\n' "$1" > "$p/avra.toml"
    if [ "$1" = soak ]; then cp packages/std-http-soak/src/main.av "$p/src/main.av"; else turn > "$p/src/main.av"; fi
    own_store "$p"
}

turn() {
    cat <<'AV'
use @std.meta.{Diagnostic, code_hash}

component told {
    run: fn(int) -> int
    says: List<string> = []

    fn check() -> List<Diagnostic> { [] }
}

type Box = { n: int }

impl Box {
    fn a() -> int {
        @says("same")
        told t { n -> n + 1 }
        t.run(self.n) + t.says.length
    }

    fn b() -> int {
        @says("same")
        told t { n -> n + 2 }
        t.run(self.n) + t.says.length
    }
}

fn both() -> int { Box { n: 1 }.a() + Box { n: 1 }.b() }

println("${both()} ${code_hash(both) ?? "unhashed"}")
AV
}

# The program `$1` built cold and whole in one place under the setting `$3` (none where empty); its
# binary, its words and, for the turn program, what it prints, kept as `$2`.
built() {
    program "$1"
    env ${3:-} "$A" build --release "$R/$1" > "$R/$2.words" 2>&1 || { echo "BUILD FAILED: $(grep -m1 -i 'avra:\|error' "$R/$2.words")"; return; }
    cp "$R/$1/src/main" "$R/$2.bin"
    if [ "$1" = turn ]; then "$R/$2.bin" > "$R/$2.said" 2>&1; fi
    echo built
}

steps=$((steps + 1)); held=$(built soak held)
[ "$held" = built ] || fail "held: $held"
steps=$((steps + 1)); let_go=$(built soak let-go AVRA_HELD_BYTES=1)
[ "$let_go" = built ] || fail "every item let go: $let_go"
if [ "$held" = built ] && [ "$let_go" = built ]; then
    steps=$((steps + 1))
    cmp -s "$R/held.bin" "$R/let-go.bin" || fail "the binaries differ: items read again are not the same items"
    steps=$((steps + 1))
    cmp -s "$R/held.words" "$R/let-go.words" || fail "the builds say different words: $(diff "$R/held.words" "$R/let-go.words" | head -3)"
fi
steps=$((steps + 1)); turn_held=$(built turn turn-held)
[ "$turn_held" = built ] || fail "the turn program held: $turn_held"
steps=$((steps + 1)); turn_fresh=$(built turn turn-fresh AVRA_HELD_ITEMS_OFF=1)
[ "$turn_fresh" = built ] || fail "the turn program read afresh: $turn_fresh"
if [ "$turn_held" = built ] && [ "$turn_fresh" = built ]; then
    steps=$((steps + 1))
    cmp -s "$R/turn-held.said" "$R/turn-fresh.said" || fail "the code hash reaching two siblings' minted literals moves with the store: $(cat "$R/turn-held.said") against $(cat "$R/turn-fresh.said")"
fi
verdict "held-store-attack: $steps step(s)" "held, let go and read afresh"

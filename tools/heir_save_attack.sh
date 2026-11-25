#!/bin/sh
# A BUILD ANSWERS BEFORE ITS STORE IS SAVED, AND THE NEXT BUILD READS THE SAVE WHOLE. A build
# leaves its store to an heir, a process that outlives it. One package, its heir held back
# (`AVRA_HEIR_LINGERS_MS`) so each case meets the save unfinished:
#   a build started at once says it waits for the heir, then stands on what it saved, working out
#   nothing;
#   an heir killed before it saves costs the next build its work and never its answer, and that
#   build says the save did not finish, once;
#   a store emptied under the heir is built again whole;
#   an edit made while the heir saves is the edit the next build builds;
#   `AVRA_STORE_KEPT_HERE` saves before the build answers, and leaves no heir.
#
#   sh tools/heir_save_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${HEIR_ATTACK_AVRA:-$(pwd)/avra}
R=build/heir-save-attack
find "$R" -delete 2>/dev/null; mkdir -p "$R"
unset AVRA_STORE_KEPT_HERE AVRA_HEIR_LINGERS_MS
LINGER=4000

# The package `$1`: an entry printing `word()` and the sum of enough files that a cold build forks.
package() {
    p=$R/$1
    find "$p" -delete 2>/dev/null; mkdir -p "$p/src"
    printf '[package]\nname = "heir-%s"\nversion = "0.1.0"\n' "$1" > "$p/avra.toml"
    printf 'export fn word() -> string { "before" }\n' > "$p/src/leaf.av"
    uses=""; sum="0"
    for k in $(seq 0 39); do
        printf 'export fn f%s() -> int { %s }\n' "$k" "$k" > "$p/src/f$k.av"
        uses="${uses}use f$k.{f$k}\n"; sum="$sum + f$k()"
    done
    printf "use leaf.{word}\n${uses}\nprintln(\"\${word()} \${$sum}\")\n" > "$p/src/main.av"
    own_store "$p"
}

now_ms() { echo $(($(date +%s%N) / 1000000)); }
store() { echo "$R/$1/.avra-cache/tapes"; }
frontiers() { ls "$(store "$1")" 2>/dev/null | grep -c '^frontier-'; }
heirs() { pgrep -f "build $R/$1\$" | wc -l | tr -d ' '; }
settled() { while [ "$(heirs "$1")" != 0 ]; do sleep 0.2; done; }
said() { "$R/$1/src/main" | cut -d' ' -f1; }
# Whether a build of `$1` stood on what the store held, as its `--time` line says: 1 or 0. Its
# words are left at `$R/$1.after`.
worked() { "$A" build "$R/$1" --time 2>"$R/$1.after" >/dev/null; grep -c 'cache hit' "$R/$1.after"; }

# 1. The build answers with its store unsaved; the build after it waits and stands.
package waits
steps=$((steps + 1))
AVRA_HEIR_LINGERS_MS=$LINGER "$A" build "$R/waits" > "$R/waits.build" 2>&1 || fail "the build failed"
[ "$(frontiers waits)" = 0 ] || fail "the store was saved before the build answered: no heir held the save"
[ "$(heirs waits)" = 1 ] || fail "$(heirs waits) heirs outlive the build, not one"
steps=$((steps + 1))
from=$(now_ms)
hit=$(worked waits)
took=$(($(now_ms) - from))
[ "$(frontiers waits)" -ge 1 ] || fail "the build after did not wait for the heir: the store holds no frontier"
[ "$hit" = 1 ] || fail "the build after did not stand on what the heir saved"
[ "$(grep -c "waiting for the last build's save" "$R/waits.after")" = 1 ] || fail "the build after waited without saying so once"
[ "$took" -ge 1000 ] || fail "the build after answered in ${took}ms: it did not wait for an heir held back ${LINGER}ms"
[ "$(said waits)" = before ] || fail "the binary says '$(said waits)'"
settled waits

# 2. An heir killed before it saves: the next build works it out again and is right.
package killed
steps=$((steps + 1))
AVRA_HEIR_LINGERS_MS=$LINGER "$A" build "$R/killed" > "$R/killed.build" 2>&1 || fail "the build failed"
pkill -9 -f "build $R/killed\$"
"$A" build "$R/killed" > "$R/killed.again" 2>&1 || fail "the build after a killed heir failed"
[ "$(said killed)" = before ] || fail "after a killed heir the binary says '$(said killed)'"
[ "$(grep -c 'save of .* did not finish' "$R/killed.again")" = 1 ] || fail "the build after a killed heir did not say its save was unfinished"
settled killed
"$A" build "$R/killed" > "$R/killed.third" 2>&1 || fail "the second build after a killed heir failed"
[ "$(grep -c 'did not finish' "$R/killed.third")" = 0 ] || fail "an unfinished save was said twice"
settled killed
[ "$(frontiers killed)" -ge 1 ] || fail "the build after a killed heir saved no frontier"

# 3. The store emptied under the heir: the next build is whole.
package emptied
steps=$((steps + 1))
AVRA_HEIR_LINGERS_MS=$LINGER "$A" build "$R/emptied" > "$R/emptied.build" 2>&1 || fail "the build failed"
find "$R/emptied/.avra-cache" -mindepth 1 -delete 2>/dev/null
printf 'export fn word() -> string { "after" }\n' > "$R/emptied/src/leaf.av"
"$A" build "$R/emptied" > "$R/emptied.again" 2>&1 || fail "the build over an emptied store failed"
[ "$(said emptied)" = after ] || fail "over an emptied store the binary says '$(said emptied)', the file says 'after'"
settled emptied
"$A" build "$R/emptied" > "$R/emptied.third" 2>&1 || fail "the build after the heir of an emptied store failed"
[ "$(said emptied)" = after ] || fail "after the heir of an emptied store the binary says '$(said emptied)'"
settled emptied

# 4. An edit made while the heir saves is what the next build builds.
package edited
steps=$((steps + 1))
AVRA_HEIR_LINGERS_MS=$LINGER "$A" build "$R/edited" > "$R/edited.build" 2>&1 || fail "the build failed"
printf 'export fn word() -> string { "after" }\n' > "$R/edited/src/leaf.av"
"$A" build "$R/edited" > "$R/edited.again" 2>&1 || fail "the build of the edit failed"
[ "$(said edited)" = after ] || fail "an edit made while the heir saved was not built: the binary says '$(said edited)'"
settled edited

# 5. Kept here, the store is whole when the build answers.
package here
steps=$((steps + 1))
AVRA_STORE_KEPT_HERE=1 AVRA_HEIR_LINGERS_MS=$LINGER "$A" build "$R/here" > "$R/here.build" 2>&1 || fail "the build failed"
[ "$(heirs here)" = 0 ] || fail "kept here, an heir outlives the build"
[ "$(frontiers here)" -ge 1 ] || fail "kept here, the build answered with no frontier saved"
verdict "heir-save-attack: $steps step(s)" "waits, killed, emptied, edited, kept here"

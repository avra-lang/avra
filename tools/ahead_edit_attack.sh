#!/bin/sh
# AN EDIT BETWEEN A WAVE AND ITS MERGE IS CAUGHT. The asking process takes what its cores learned
# without walking it, only where every input a core read is the one it reads now. One package, built
# cold; after the last wave forks and before it merges, the file the program prints from is edited
# (`AVRA_AHEAD_EDIT`). The binary must print the edit. The same build with the cores' answers taken
# unproven (`AVRA_AHEAD_UNPROVEN`) must print what the cores read, so the attack exercises the
# proof, not a path that never forks.
#
#   sh tools/ahead_edit_attack.sh
set -u
. "$(dirname "$0")/lib/attack.sh"
A=${AHEAD_ATTACK_AVRA:-$(pwd)/avra}
R=build/ahead-edit-attack
rm -rf "$R" && mkdir -p "$R"
unset AVRA_AHEAD_EDIT AVRA_AHEAD_UNPROVEN

# The package: an entry printing `word()` and the sum of enough files that every wave forks.
package() {
    p=$R/$1
    rm -rf "$p" && mkdir -p "$p/src"
    printf '[package]\nname = "ahead-%s"\nversion = "0.1.0"\n' "$1" > "$p/avra.toml"
    printf 'export fn word() -> string { "before" }\n' > "$p/src/leaf.av"
    uses=""; sum="0"
    for k in $(seq 0 39); do
        printf 'export fn f%s() -> int { %s }\n' "$k" "$k" > "$p/src/f$k.av"
        uses="${uses}use f$k.{f$k}\n"; sum="$sum + f$k()"
    done
    printf "use leaf.{word}\n${uses}\nprintln(\"\${word()} \${$sum}\")\n" > "$p/src/main.av"
    own_store "$p"
}

# How many waves a cold build of the package forks: the `ahead:` lines it says.
waves() {
    package count
    AVRA_QUERY_TIMES=1 "$A" build "$R/count" 2>&1 >/dev/null | grep -c '^ahead: [0-9].* taken'
}

# The package built cold with the leaf edited after wave `$2`, its binary's words; `$3` takes the cores' answers unproven.
edited_run() {
    package "$1"
    edit="$2:$R/$1/src/leaf.av=export fn word() -> string { \"after\" }
"
    if [ -n "${3:-}" ]; then
        AVRA_AHEAD_UNPROVEN=1 AVRA_AHEAD_EDIT="$edit" "$A" build "$R/$1" > "$R/$1.build" 2>&1 || { echo "BUILD FAILED"; return; }
    else
        AVRA_AHEAD_EDIT="$edit" "$A" build "$R/$1" > "$R/$1.build" 2>&1 || { echo "BUILD FAILED"; return; }
    fi
    "$R/$1/src/main" | cut -d' ' -f1
}

n=$(waves)
steps=$((steps + 1))
if [ "${n:-0}" -lt 1 ]; then
    fail "the package forked no wave ($n): nothing here exercises the cores' answers"
else
    last=$((n - 1))
    steps=$((steps + 1)); proved=$(edited_run proved "$last")
    [ "$proved" = after ] || fail "an edit after wave $last was not caught: the binary says '$proved', the file says 'after'"
    steps=$((steps + 1)); unproved=$(edited_run unproved "$last" unproven)
    [ "$unproved" = before ] || fail "taken unproven, the binary says '$unproved': the edit lands where the proof is not what catches it"
fi
verdict "ahead-edit-attack: $n wave(s), $steps step(s)" "proved and unproven"

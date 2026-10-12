#!/bin/sh
# `avra docs <name>`, SAVED WITH ITS READS AND ATTACKED (DB 06). The answer is kept with
# the digest of every source file of the program and the package's listing; a later
# process serves it only while every digest stands. Each step edits the package, asks,
# and holds the answer to the ORACLE — the same question in a copy with no store — and
# says whether the program was parsed (a hit parses nothing). The steps that could be
# served stale: an edit to the declaration's file, a same-name declaration added to a
# file that already exists (the listing does not move), another in a new file, a file
# removed, an input restored.
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
BIN="$(pwd)/build/avra"
R="$(pwd)/build/docs-cache-attack"; fails=0; steps=0
rm -rf "$R" && mkdir -p "$R/p/src/util" && git init -q "$R"
cat > "$R/p/avra.toml" <<'TOML'
[package]
name = "docs-attack"
version = "0.1.0"
TOML
write_a() { printf '%s\n' "/// $1" "export fn target() -> int { 1 }" > "$R/p/src/a.av"; }
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
printf '%s\n' "use a.{target}" "println(\"\${target()}\")" > "$R/p/src/main.av"
write_a "doc one"

say() { steps=$((steps + 1)); echo "docs-cache-attack: $1"; }
fail() { fails=$((fails + 1)); echo "docs-cache-attack: FAILED — $1"; }
ask() { (cd "$1" && AVRA_QTRACE=1 AVRA_CWD="$1" "$BIN" docs target 2>"$R/trace" | tr '\n' ' '); }
parsed() { grep -c 'Q	parse' "$R/trace"; }
# the oracle: a copy in a repo of its own, so no store answers
oracle() { rm -rf "$R/o" && mkdir -p "$R/o" && git init -q "$R/o" && cp -R "$R/p" "$R/o/p"; ask "$R/o/p"; }
# expect NAME WANT-HIT: the answer equals the oracle's, and the program was parsed or not
expect() {
    got=$(ask "$R/p"); n=$(parsed); want=$(oracle)
    [ "$got" = "$want" ] || { fail "$1: answered '$got', the oracle '$want'"; return; }
    if [ "$2" = hit ] && [ "$n" != 0 ]; then fail "$1: parsed $n files where a hit parses none"; return; fi
    if [ "$2" = miss ] && [ "$n" = 0 ]; then fail "$1: a stale answer was served — nothing was parsed"; return; fi
    say "$1 ($2): $got"
}

expect "cold" miss
expect "warm, nothing moved" hit
write_a "doc two"
expect "the declaration's file edited" miss
expect "warm again" hit
printf '%s\n' "/// the other one" "export fn target() -> int { 3 }" >> "$R/p/src/util/b.av"
expect "a same-name declaration added to an EXISTING file (the listing does not move)" miss
expect "warm on the collision" hit
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
expect "the collision removed: one row per question, so the earlier answer is gone" miss
printf '%s\n' "export fn target() -> int { 4 }" > "$R/p/src/util/c.av"
expect "a same-name declaration in a NEW file of another module" miss
rm "$R/p/src/util/c.av"
expect "the new file removed" miss
write_a "doc one"
expect "the first text restored" miss
expect "and warm" hit
rm "$R/p/src/a.av"; printf '%s\n' "use util.{other}" "println(\"\${other()}\")" > "$R/p/src/main.av"
expect "the declaration's file removed" miss

[ $fails -eq 0 ] || { echo "docs-cache-attack: $fails of $steps FAILED"; exit 1; }
echo "docs-cache-attack: $steps steps passed"

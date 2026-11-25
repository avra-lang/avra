#!/bin/sh
# `avra docs <name>` ON THE PROGRAM LAYER, ATTACKED (DB 06). Each file's documentation is an answer
# the package's store keeps by the file's text; the package's files and its dependencies' are read.
# Each step edits the program, asks, and holds the answer to the ORACLE — the same question in a
# copy with a store of its own — and names the files the step must parse: exactly those whose text
# the store has not seen. A text the store has seen before (an input restored) is served without a
# parse; a text it has not is never served from another. The steps that could be served stale: an
# edit to the declaration's file, a same-name declaration added to a file that already exists (the
# listing does not move), another in a new file, a file removed, an input restored, the same in a
# dependency.
set -u
. "$(dirname "$0")/lib/attack.sh"
BIN="$(pwd)/build/avra"
R="$(pwd)/build/docs-cache-attack"
rm -rf "$R" && mkdir -p "$R/p/src/util" "$R/dep/src/sub" && git init -q "$R"
cat > "$R/p/avra.toml" <<'TOML'
[package]
name = "docs-attack"
version = "0.1.0"

[dependencies]
"@da/dep" = { path = "../dep" }
TOML
cat > "$R/dep/avra.toml" <<'TOML'
[package]
name = "@da/dep"
version = "0.1.0"

[lib]
name = "da-dep"
path = "src/lib.av"
TOML
printf '%s\n' "use sub.{x}" "/// dep doc" "export fn shared() -> int { x() + 5 }" > "$R/dep/src/lib.av"
printf '%s\n' "export fn x() -> int { 1 }" > "$R/dep/src/sub/a.av"
write_a() { printf '%s\n' "/// $1" "export fn target() -> int { 1 }" > "$R/p/src/a.av"; }
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
printf '%s\n' "use a.{target}" "use @da.dep.{shared}" "println(\"\${target() + shared()}\")" > "$R/p/src/main.av"
write_a "doc one"

who=docs-cache-attack
. tools/lib/steps.sh
ask() { (cd "$1" && AVRA_QTRACE=1 AVRA_CWD="$1" "$BIN" docs "${2:-target}" 2>"$R/trace" | tr '\n' ' '); }
parsed() { grep -P '^Q\tparse\t[^<]' "$R/trace" | cut -f3 | sort | tr '\n' ' '; }
# the oracle: a copy in a repo and a store of its own, so no store answers
oracle() { rm -rf "$R/o" && mkdir -p "$R/o" && git init -q "$R/o" && cp -R "$R/p" "$R/o/p" && cp -R "$R/dep" "$R/o/dep"; AVRA_CACHE_DIR="$R/o/.avra-cache" ask "$R/o/p" "${1:-target}"; }
# expect NAME PARSED [NAME-ASKED]: the answer equals the oracle's, and the files parsed are PARSED
expect() {
    got=$(ask "$R/p" "${3:-target}"); n=$(parsed); want=$(oracle "${3:-target}")
    [ "$got" = "$want" ] || { fail "$1: answered '$got', the oracle '$want'"; return; }
    [ "$n" = "$2" ] || { fail "$1: parsed '$n' where the unseen texts are '$2'"; return; }
    say "$1 (parsed: ${2:-none}): $got"
}
P=docs-attack/src
D=@da/dep/src
expect "cold" "@da/dep/src/lib.av @da/dep/src/sub/a.av $P/a.av $P/main.av $P/util/b.av "
expect "warm, nothing moved" ""
write_a "doc two"
expect "the declaration's file edited" "$P/a.av "
expect "warm again" ""
printf '%s\n' "/// the other one" "export fn target() -> int { 3 }" >> "$R/p/src/util/b.av"
expect "a same-name declaration added to an EXISTING file (the listing does not move)" "$P/util/b.av "
expect "warm on the collision" ""
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
expect "the collision removed: the earlier text, seen, is served" ""
printf '%s\n' "export fn target() -> int { 4 }" > "$R/p/src/util/c.av"
expect "a same-name declaration in a NEW file of another module" "$P/util/c.av "
rm "$R/p/src/util/c.av"
expect "the new file removed" ""
write_a "doc one"
expect "the first text restored" ""
expect "a DEPENDENCY's declaration" "" shared
printf '%s\n' "/// the other shared" "export fn shared() -> int { 6 }" > "$R/dep/src/sub/b.av"
expect "a same-name declaration in a NEW file of the dependency's module" "$D/sub/b.av " shared
rm "$R/dep/src/sub/b.av"
expect "the dependency's new file removed" "" shared
printf '%s\n' "use sub.{x}" "/// dep doc, edited" "export fn shared() -> int { x() + 5 }" > "$R/dep/src/lib.av"
expect "the dependency's declaration edited" "$D/lib.av " shared
rm "$R/p/src/a.av"; printf '%s\n' "use util.{other}" "println(\"\${other()}\")" > "$R/p/src/main.av"
expect "the declaration's file removed" "$P/main.av "

verdict

#!/bin/sh
# THE EDIT CORPUS (DB 06): no stale answer after any one scripted edit. A fixture package
# (a library dependency beside it) is checked and asked about through ONE warm store; after
# each edit the warm answers are compared with a COLD copy of the same tree, whose store is
# empty. `check` is compared as a set of diagnostic blocks (their order differs between warm
# and cold runs), `docs` as text, both with their exit status. A step that is not marked `noop` must CHANGE the cold answer, or the corpus
# edited nothing it can see.
#
#   sh tools/db_corpus.sh
set -u
cd "$(dirname "$0")/.."
export AVRA_WATCH_HELD=1
export AVRA_MAX_COMPILES=0
BIN="$(pwd)/build/avra"
R="$(pwd)/build/db-corpus"
rm -rf "$R" && mkdir -p "$R/p/src/util" "$R/dep/src/sub" && git init -q "$R"
cat > "$R/p/avra.toml" <<'TOML'
[package]
name = "corpus"
version = "0.1.0"

[dependencies]
"@dc/dep" = { path = "../dep" }
TOML
cat > "$R/dep/avra.toml" <<'TOML'
[package]
name = "@dc/dep"
version = "0.1.0"

[lib]
name = "dc-dep"
path = "src/lib.av"
TOML
printf '%s\n' "use sub.{x}" "/// dep doc" "export fn shared() -> int { x() + 5 }" > "$R/dep/src/lib.av"
printf '%s\n' "export fn x() -> int { 1 }" > "$R/dep/src/sub/a.av"
printf '%s\n' "/// target doc" "export fn target() -> int { 1 }" "export fn helper() -> int { target() + 1 }" > "$R/p/src/a.av"
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
printf '%s\n' "use a.{target, helper}" "use @dc.dep.{shared}" "println(\"\${target() + helper() + shared()}\")" > "$R/p/src/main.av"

who=db-corpus
. tools/lib/steps.sh
# a tree built: its binary's defined symbols (sorted), what the program prints and its status
built() {
    rm -f "$1/src/main"
    AVRA_CWD="$1" "$BIN" build . > /dev/null 2>&1; echo "build status $?"
    if [ -x "$1/src/main" ]; then
        nm -g --defined-only "$1/src/main" 2>/dev/null | awk '{print $NF}' | sort | tr '\n' ' '; echo
        "$1/src/main" 2>&1; echo "run status $?"
    fi
}
# one tree's answers, normalised: check's blocks sorted, then docs for two names
answers() {
    (cd "$1" && {
        AVRA_CWD="$1" "$BIN" check . 2>&1; echo "status $?"
        AVRA_CWD="$1" "$BIN" docs target 2>&1; echo "status $?"
        AVRA_CWD="$1" "$BIN" docs shared 2>&1; echo "status $?"
        built "$1"
    }) | python3 -I -c '
import sys
t = sys.stdin.read()
blocks = sorted(b.strip() for b in t.split("\n\n") if b.strip())
print("\n--\n".join(blocks))'
}
cold() {
    rm -rf "$R/o" && mkdir -p "$R/o" && git init -q "$R/o" && cp -R "$R/p" "$R/o/p" && cp -R "$R/dep" "$R/o/dep"
    answers "$R/o/p" | sed "s#$R/o/#$R/#g"
}
last=""
step() { # step NAME: the tree is edited already
    warm=$(answers "$R/p"); want=$(cold)
    if [ "$warm" = "$want" ]; then say "$1$(printf '%s' "$warm" | grep -q avra_corpus_hosted && echo ' [the binary defines the host fn]')"; else fail "$1: the warm answers differ from the cold ones"; printf '%s\n' "$warm" > "$R/warm.txt"; printf '%s\n' "$want" > "$R/cold.txt"; diff "$R/warm.txt" "$R/cold.txt" | head -40; fi
    if [ "$want" = "$last" ] && [ "${2:-}" != noop ]; then fail "$1: the edit changed nothing the corpus can see"; fi
    last="$want"
}

step "the fixture, cold then warm" noop
step "warm again" noop
printf '%s\n' "/// target doc" "export fn target() -> int { 2 }" "export fn helper() -> int { target() + 1 }" > "$R/p/src/a.av"
step "a body edited (no diagnostic or doc moves)" noop
printf '%s\n' "/// target doc, edited" "export fn target() -> int { 2 }" "export fn helper() -> int { target() + 1 }" > "$R/p/src/a.av"
step "a doc edited"
printf '%s\n' "/// target doc, edited" "export fn target() -> int { 2 }" "export fn helper() -> int { target() + 'x' }" > "$R/p/src/a.av"
step "a type error introduced"
printf '%s\n' "/// target doc, edited" "export fn target() -> int { 2 }" "export fn helper() -> int { target() + 1 }" > "$R/p/src/a.av"
step "and repaired"
printf '%s\n' "/// the other target" "export fn target() -> int { 9 }" > "$R/p/src/util/b.av"
step "a same-name declaration in a new module's file"
printf '%s\n' "export fn other() -> int { 2 }" > "$R/p/src/util/b.av"
step "and removed"
printf '%s\n' "/// dep doc, edited" "export fn shared() -> int { x() + 5 }" > "$R/dep/src/lib.av.new" && printf '%s\n' "use sub.{x}" "/// dep doc, edited" "export fn shared() -> int { x() + 5 }" > "$R/dep/src/lib.av"; rm -f "$R/dep/src/lib.av.new"
step "a dependency's doc edited"
printf '%s\n' "/// the other shared" "export fn shared() -> int { 6 }" > "$R/dep/src/sub/b.av"
step "a same-name declaration in a new file of the dependency's module"
rm "$R/dep/src/sub/b.av"
step "and removed"
printf '%s\n' "export fn x() -> int { 1 }" "export fn unused_x() -> int { 7 }" > "$R/dep/src/sub/a.av"
step "an unrelated declaration added to the dependency" noop
rm "$R/p/src/util/b.av"
step "an unused file deleted" noop
printf '%s\n' "extern fn avra_corpus_hosted(a: int) -> int { a + 1 }" > "$R/p/src/host.av"
step "a host fn added to a module"
printf '%s\n' "/// target doc, edited" "export fn target() -> int { 4 }" "export fn helper() -> int { target() + 1 }" > "$R/p/src/a.av"
step "a body edited beside a held module that carries a host fn"
rm "$R/p/src/host.av"
step "and the host fn removed"

verdict "the warm answers equal the cold ones"

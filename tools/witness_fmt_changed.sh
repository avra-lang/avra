#!/bin/sh
# WITNESS — `tools/fmt_changed.sh`, THE ONE changed-file fmt check the train
# and a lane's preflight both call. Hermetic: a scratch git repo,
# a stub compiler and a stub `git` that records every call, so the proof is
# about the WIRING — which files reach the compiler, which exit status comes
# back, and that nothing ever fetches or watches `main` — never about a real
# build. Run: sh tools/witness_fmt_changed.sh
set -eu
repo=$(cd "$(dirname "$0")/.." && pwd)
script=$repo/tools/fmt_changed.sh
tmp=$(mktemp -d "${TMPDIR:-/tmp}/avra-fmt-changed.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
log="$tmp/avra.log"
gitlog="$tmp/git.log"
: > "$log"
: > "$gitlog"
realgit=$(command -v git)

# A stub compiler: records the files it was handed, and refuses any holding
# the marker — the shape a stale binary's refusal takes from the caller's side.
cat > "$tmp/bin/avra" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$AVRA_LOG"
for f in "$@"; do
    [ -f "$f" ] || continue
    if grep -q BROKEN "$f"; then echo "fmt --check: 1 refused"; exit 1; fi
done
echo "fmt --check: $# examined, 0 differing, 0 refused"
SH
chmod +x "$tmp/bin/avra"

# A git that records the subcommand, then runs the real one — so a `fetch`,
# `log`, `ls-remote` or `remote` would be visible, and `diff` passes through.
cat > "$tmp/bin/git" <<SH
#!/bin/sh
echo "\$*" >> "$gitlog"
exec "$realgit" "\$@"
SH
chmod +x "$tmp/bin/git"

(
    cd "$tmp"
    # born on a branch of its own: `main` is then made beside it, whatever
    # this machine names a new repository's first branch
    "$tmp/bin/git" init -q -b seed
    "$tmp/bin/git" config user.email w@x
    "$tmp/bin/git" config user.name w
    printf 'fn a() -> int {\n    1\n}\n' > a.av
    "$tmp/bin/git" add a.av
    "$tmp/bin/git" commit -qm one
    "$tmp/bin/git" branch -f main
    "$tmp/bin/git" checkout -q -b feature
    printf 'BROKEN\n' > b.av
    "$tmp/bin/git" add b.av
    "$tmp/bin/git" commit -qm two
)

run() { ( cd "$tmp" && PATH="$tmp/bin:$PATH" AVRA="$tmp/bin/avra" AVRA_LOG="$log" sh "$script" "$@" ); }

fail=0
say() { echo "witness_fmt_changed: $1"; fail=1; }

# (a) a changed file the compiler refuses fails the check.
: > "$log"
run main feature >/dev/null 2>&1 && say "(a) a refused changed file answered success"
grep -q 'b\.av' "$log" || say "(a) the changed file never reached the compiler"
grep -q 'a\.av' "$log" && say "(a) an UNCHANGED file reached the compiler"

# (b) nothing changed between the same refs — no compiler call, success.
: > "$log"
run main main >/dev/null 2>&1 || say "(b) an unchanged range answered failure"
[ -s "$log" ] && say "(b) the compiler ran with no changed files"

# (c) a canonical changed file passes.
(
    cd "$tmp"
    printf 'fn b() -> int {\n    2\n}\n' > b.av
    "$tmp/bin/git" add b.av
    "$tmp/bin/git" commit -qm three
)
run main feature >/dev/null 2>&1 || say "(c) a canonical change answered failure"

# (d) the check NAMES its refs and never watches `main` — no fetch, no log,
#     no remote query.
grep -Eq '^(fetch|log|ls-remote|remote|pull)' "$gitlog" && say "(d) the check polled a remote, not a named ref"
grep -q '^diff ' "$gitlog" || say "(d) the check never diffed the named refs"

# (e) the `--files` front door — the one a tree with no `.git` (a Sprite)
#     uses — checks exactly the files it is handed, and calls no git at all.
printf 'BROKEN\n' > "$tmp/c.av"
: > "$log"
before=$(wc -l < "$gitlog")
run --files c.av >/dev/null 2>&1 && say "(e) --files refused file answered success"
grep -q 'c\.av' "$log" || say "(e) --files never reached the compiler"
[ "$(wc -l < "$gitlog")" -eq "$before" ] || say "(e) --files called git"

# (f) a fixture whose case expects a lex refusal is malformed on purpose:
#     skipped with one line naming it, never handed to the compiler, success.
mkdir -p "$tmp/cases/lexed/src"
printf 'BROKEN @@m\n' > "$tmp/cases/lexed/src/main.av"
printf 'error[lex.error]: expected a name after `@`\n' > "$tmp/cases/lexed/refuses.expected"
: > "$log"
out=$(run --files cases/lexed/src/main.av 2>&1) || say "(f) a fixture expecting lex.error answered failure"
[ "$(printf '%s\n' "$out" | grep -c 'skipped cases/lexed/src/main\.av')" -eq 1 ] || say "(f) the skipped fixture was not named in one line"
grep -q 'lexed' "$log" && say "(f) a fixture expecting lex.error reached the compiler"

# (g) a broken file WITHOUT that expectation still fails — one whose case
#     expects only a non-parse refusal, and beside a skipped fixture too.
mkdir -p "$tmp/cases/laws/src"
printf 'BROKEN\n' > "$tmp/cases/laws/src/main.av"
printf 'error[annotation.unread_mark]: every mark is read by something that claims it\n' > "$tmp/cases/laws/refuses.expected"
run --files cases/laws/src/main.av >/dev/null 2>&1 && say "(g) a broken file whose case expects no parse refusal answered success"
: > "$log"
run --files cases/lexed/src/main.av c.av >/dev/null 2>&1 && say "(g) a broken file beside a skipped fixture answered success"
grep -q 'c\.av' "$log" || say "(g) the broken file beside a skipped fixture never reached the compiler"

[ "$fail" -eq 0 ] && echo "witness_fmt_changed: 7 proved — one instrument, branch compiler, refs named, main never watched, parse fixtures skipped and nothing else"
exit "$fail"

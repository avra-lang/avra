#!/bin/sh
# FIXTURES FOR tools/batch.sh — no network and no GitHub: a scratch origin
# (a bare repository) with real branches to merge, and AVRA_GH standing in
# for `gh`. The fake answers `pr view`, `pr list`, `run view` from JSON files
# written here, and records every other call in gh.log.
#
# `sh tools/batch_test.sh` prints a summary; a non-zero exit is a failure.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/avra-batch-test.XXXXXX")
scratch=$(cd "$scratch" && pwd -P)
trap 'rm -rf "$scratch"' EXIT
trap 'exit 130' INT TERM

total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }
check() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (got '$1', wanted '$2')" "${4:-}"; fi; }

fx="$scratch/fx"
mkdir -p "$fx"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# ── The fake gh ──────────────────────────────────────────────────────────
cat > "$scratch/gh" <<'SH'
#!/bin/sh
echo "$*" >> "$FX/gh.log"
case "$1" in
    api) exit 0 ;;
esac
case "$1 $2" in
    "pr view")
        [ -f "$FX/pr-$3.json" ] || { echo "no PR $3" >&2; exit 1; }
        cat "$FX/pr-$3.json" ;;
    "pr list")
        branch=$(printf '%s\n' "$@" | sed -n 's/^batch-//p' | head -n 1)
        f="$FX/list-batch-$branch.json"
        if [ -f "$f" ]; then cat "$f"; else echo "[]"; fi ;;
    "pr create")
        echo "https://github.com/avra-lang/avra/pull/900" ;;
    "pr merge")
        [ -f "$FX/automerge-refused" ] && { echo "auto-merge refused" >&2; exit 1; }
        exit 0 ;;
    "pr close") exit 0 ;;
    "run view")
        cat "$FX/run-$3.log" 2>/dev/null ;;
    *) exit 0 ;;
esac
SH
chmod +x "$scratch/gh"

# ── Fixture PRs ───────────────────────────────────────────────────────────
# pr_json <number> <title> <head> <state> <test> <attacks|ABSENT> <before> <file>…
pr_json() {
    n=$1; title=$2; head=$3; state=$4; test=$5; attacks=$6; before=$7; shift 7
    python3 - "$fx/pr-$n.json" "$n" "$title" "$head" "$state" "$test" "$attacks" "$before" "$@" <<'PY'
import json, sys
path, n, title, head, state, test, attacks, before = sys.argv[1:9]
files = sys.argv[9:]
checks = [{"name": "test", "conclusion": test, "detailsUrl": "https://github.com/x/y/actions/runs/1/job/2"}]
if attacks != "ABSENT":
    checks.append({"name": "cache-attacks", "conclusion": attacks, "detailsUrl": "https://github.com/x/y/actions/runs/1/job/3"})
body = "Work.\n\n" + ("Before/after: " + before + "\n" if before != "-" else "")
json.dump({"number": int(n), "title": title, "headRefName": head, "isDraft": False,
           "state": state, "body": body, "statusCheckRollup": checks,
           "files": [{"path": f} for f in files]}, open(path, "w"))
PY
}

# ── The origin and the work clone ─────────────────────────────────────────
git init -q --bare "$scratch/origin.git"
git -C "$scratch/origin.git" symbolic-ref HEAD refs/heads/main
git init -q -b main "$scratch/seed"
printf 'a0\n' > "$scratch/seed/a.txt"
printf 'b0\n' > "$scratch/seed/b.txt"
printf 'c0\n' > "$scratch/seed/c.txt"
git -C "$scratch/seed" add . && git -C "$scratch/seed" commit -q -m seed
git -C "$scratch/seed" remote add origin "$scratch/origin.git"
git -C "$scratch/seed" push -q origin main
# Three members: h2 edits a.txt, h3 edits b.txt, h4 edits a.txt too (conflicts with h2).
for b in h2 h3 h4; do git -C "$scratch/seed" checkout -q -b $b main; done
git -C "$scratch/seed" checkout -q h2 && printf 'a2\n' > "$scratch/seed/a.txt" && git -C "$scratch/seed" commit -q -am h2
git -C "$scratch/seed" checkout -q h3 && printf 'b3\n' > "$scratch/seed/b.txt" && git -C "$scratch/seed" commit -q -am h3
git -C "$scratch/seed" checkout -q h4 && printf 'a4\n' > "$scratch/seed/a.txt" && git -C "$scratch/seed" commit -q -am h4
git -C "$scratch/seed" push -q origin h2 h3 h4
git clone -q "$scratch/origin.git" "$scratch/clone"
mkdir -p "$scratch/clone/tools"
cp "$here/batch.sh" "$scratch/clone/tools/batch.sh"

batch() {
    (cd "$scratch/clone" && FX="$fx" AVRA_GH="$scratch/gh" sh tools/batch.sh "$@") > "$scratch/out" 2> "$scratch/err"
}
reset_clone() {
    git -C "$scratch/clone" merge --abort >/dev/null 2>&1 || true
    git -C "$scratch/clone" checkout -q main 2>/dev/null || true
    git -C "$scratch/clone" fetch -q origin 2>/dev/null
    git -C "$scratch/clone" reset -q --hard origin/main 2>/dev/null
    git -C "$scratch/clone" branch -q -D $(git -C "$scratch/clone" branch --list 'batch-*' | tr -d ' *') 2>/dev/null || true
    rm -f "$fx/gh.log" "$fx"/list-batch-*.json "$fx"/automerge-refused
}
calls() { grep -c "$1" "$fx/gh.log" 2>/dev/null || echo 0; }

# ── Member fixtures ───────────────────────────────────────────────────────
pr_json 2 "h2: a's edit" h2 OPEN SUCCESS SUCCESS "2.1 s -> 1.6 s" src/a.txt
pr_json 3 "h3: b's edit" h3 OPEN SUCCESS SUCCESS - src/b.txt
pr_json 4 "h4: a's other edit" h4 OPEN SUCCESS SUCCESS - src/a.txt
pr_json 5 "h5: test red" h2 OPEN FAILURE SUCCESS - src/a.txt
pr_json 6 "h6: attacks red" h3 OPEN SUCCESS FAILURE - src/b.txt
pr_json 7 "h7: attacks skipped" h3 OPEN SUCCESS SKIPPED - src/b.txt
pr_json 8 "h8: attacks absent" h3 OPEN SUCCESS ABSENT - src/b.txt

# ── 1. A red test check refuses the member ────────────────────────────────
reset_clone
batch --n 1 5
check "$?" "1" "refusal: a member whose test check is FAILURE exits 1"
check "$(grep -c '#5 refused: its test check is FAILURE, not SUCCESS' "$scratch/err")" "1" "refusal: names the member and its test check"
check "$(git -C "$scratch/clone" ls-remote --heads origin 'batch-*' | wc -l | tr -d ' ')" "0" "refusal: nothing is pushed"

# ── 2. A failing cache-attacks job refuses the member ─────────────────────
reset_clone
batch --n 1 6
check "$?" "1" "refusal: a member whose cache-attacks is FAILURE exits 1"
check "$(grep -c '#6 refused: its cache-attacks job is FAILURE' "$scratch/err")" "1" "refusal: names the member and its cache-attacks job"

# ── 3. A skipped cache-attacks needs evidence, per member ─────────────────
reset_clone
batch --n 1 7
check "$?" "1" "skipped attacks: refused without --attacks-ran"
check "$(grep -c '#7: cache-attacks is SKIPPED, so it did not run.*--attacks-ran 7=' "$scratch/err")" "1" "skipped attacks: says so and names the flag for that member"
reset_clone
batch --n 1 8
check "$?" "1" "absent attacks: refused without evidence, the same as skipped"
check "$(grep -c '#8: cache-attacks is ABSENT' "$scratch/err")" "1" "absent attacks: named as absent, not as passing"

# ── 4. Evidence given per member lets the batch through ───────────────────
reset_clone
batch --n 4 --attacks-ran "7=sprite: 1412 pass, cache-attacks clean" 2 7
check "$?" "0" "evidence: a skipped member with --attacks-ran for it is accepted"
check "$(git -C "$scratch/clone" show origin/batch-4:b.txt 2>/dev/null)" "b3" "evidence: the skipped member's edit is on the batch"
check "$(grep -c 'Cache-attacks did not run for these members' "$fx/gh.log")" "1" "evidence: the body says cache-attacks did not run, for the members that lacked it"
check "$(grep -c 'sprite: 1412 pass' "$fx/gh.log")" "1" "evidence: the given evidence is printed on the batch PR body"

# ── 5. A conflict is named and never resolved ─────────────────────────────
reset_clone
batch --n 9 2 4
check "$?" "1" "conflict: a member that conflicts exits 1"
check "$(grep -c '#4 (h4) conflicts with batch-9; conflicting files: a.txt' "$scratch/err")" "1" "conflict: names the member, its head and the conflicting file"
check "$(git -C "$scratch/clone" ls-remote --heads origin 'batch-9' | wc -l | tr -d ' ')" "0" "conflict: the batch is not pushed"
check "$(test -f "$scratch/clone/.git/MERGE_HEAD" && echo merging || echo clean)" "clean" "conflict: the merge is aborted, nothing is left half-merged"

# ── 6. Success: one batch, merged in order, armed, members retitled ───────
reset_clone
batch --n 6 2 3
check "$?" "0" "success: two members batch and exit 0"
check "$(git -C "$scratch/clone" show origin/batch-6:a.txt)" "a2" "success: the first member's edit is on batch-6"
check "$(git -C "$scratch/clone" show origin/batch-6:b.txt)" "b3" "success: the second member's edit is on batch-6"
check "$(grep -c '^pr create --base main --head batch-6 --title batch #6: #2 #3' "$fx/gh.log")" "1" "success: ONE PR, non-draft, titled with its members"
check "$(grep -c 'batch-members: 2 3' "$fx/gh.log")" "1" "success: the body names its members in a machine-readable line"
check "$(grep -c '2.1 s -> 1.6 s' "$fx/gh.log")" "1" "success: the member's before/after line is in the body"
check "$(grep -c '^pr merge 900 --auto --squash' "$fx/gh.log")" "1" "success: auto-merge is armed on the batch PR"
check "$(grep -c 'DO NOT MERGE (lands via batch #6) — h2: a.s edit' "$fx/gh.log")" "1" "success: member 2 is retitled, its title kept after the dash"
check "$(grep -c 'DO NOT MERGE (lands via batch #6) — h3: b.s edit' "$fx/gh.log")" "1" "success: member 3 is retitled too"
check "$(grep -c 'repos/:owner/:repo/pulls/2' "$fx/gh.log")" "1" "success: the retitle goes through the REST PATCH"

# ── 7. A refusal does not stop a later batch from numbering up ────────────
reset_clone
git -C "$scratch/clone" push -q origin origin/h2:refs/heads/batch-3 2>/dev/null
batch 2
check "$?" "0" "numbering: a batch with no --n takes the next number after the remote's"
check "$(grep -c 'pr create --base main --head batch-7' "$fx/gh.log")" "1" "numbering: batch-7 when batch-6 is the highest on origin"

# ── 8. close after a merge closes the members with a pointer ─────────────
reset_clone
python3 - "$fx/list-batch-6.json" <<'PY'
import json, sys
json.dump([{"number": 900, "state": "MERGED", "body": "<!-- batch-members: 2 3 -->", "statusCheckRollup": []}], open(sys.argv[1], "w"))
PY
batch close 6
check "$?" "0" "close: a merged batch closes and exits 0"
check "$(grep -c '^pr close 2 --comment Landed via batch #6' "$fx/gh.log")" "1" "close: member 2 closed with a pointer to the batch"
check "$(grep -c '^pr close 3 --comment Landed via batch #6' "$fx/gh.log")" "1" "close: member 3 closed with a pointer to the batch"

# ── 9. close on a red batch closes nothing and names the file's job ───────
reset_clone
python3 - "$fx/list-batch-2.json" <<'PY'
import json, sys
json.dump([{"number": 901, "state": "OPEN", "body": "<!-- batch-members: 2 -->",
            "statusCheckRollup": [{"name": "cache-attacks", "conclusion": "FAILURE",
                                   "detailsUrl": "https://github.com/x/y/actions/runs/77/job/9"}]}],
          open(sys.argv[1], "w"))
PY
printf 'error at src/a.txt:3: boom\n' > "$fx/run-77.log"
batch close 2
check "$?" "1" "red close: a batch that did not merge exits 1"
check "$(grep -c '^pr close' "$fx/gh.log")" "0" "red close: no member is closed"
check "$(grep -c "#2's file src/a.txt is named by cache-attacks" "$scratch/err")" "1" "red close: names the member whose file the failing log names"

echo
echo "batch tests: $((total - failed))/$total passed"
[ "$failed" = 0 ]

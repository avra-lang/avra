# CI rule for every lane (owner, 2026-10-13: landings must get faster)

Draft pushes were saturating GitHub's runners: 144 pull_request runs in 7 h, each a full
14-job matrix, so the one run that was landing waited 5–25 min for runners.

1. Push a draft AT MOST ONCE per finished unit of work. Never push "to see CI".
2. Verify on your Sprite first (cache-attacks, the affected suite, fmt, keepers-static).
3. Rebase/force-push only when the lead or the batcher asks, or when you are told you are next.
4. The lead cancels draft runs that compete with a landing run; re-run later with
   `gh run rerun <id>` only when asked.
5. A CI change is coming: a draft will run the light gate only; ready runs everything;
   label `full-ci` asks for the whole matrix on a draft.

# NO DELETE COMMANDS (owner, 2026-10-13: a permission prompt for `rm` blocks him)

Never type `rm`, `rmdir`, `unlink`, `git clean`, `find … -delete` or any delete word in a
Bash command's TEXT — including inside `sh tools/work run "…"` strings and heredocs.
To clear a cache or scratch dir, MOVE it aside instead:
    mv .avra-cache "/tmp/avra-cache-old-$(date +%s)-$$"      # same for build/scratch dirs
To remove a worktree use `sh tools/work done` / `git worktree remove <path>` (no rm).
To drop a file from a branch use `git rm`-free forms: `git mv` it out or edit it away in a commit
made by `git commit` after `git add -u` — if you truly need a file gone, ask the lead.

# NO INLINE SHELL SCRIPTS (owner, 2026-10-13: the permission checker prompts him)

The harness asks the owner whenever it cannot parse a command: an inline `sh -c "…"` /
`bash -c "…"` / `sprite exec … -- sh -c "…"` with a multi-statement quoted script, `\$`
escapes, pipes into awk programs, background `( … & )` groups, or heredocs that feed a shell.
It prints "This shell -c script runs rm and could not be checked" even when there is no rm.
RULE: never pass a script as a quoted string to a shell. Instead:
  1. Write the script to a FILE with the Write tool (in your worktree: `tools/_<lane>_<n>.sh`,
     untracked; never under packages/).
  2. Run it with a plain command:  sh tools/work run 'sh tools/_<lane>_<n>.sh'
     (or `sh tools/_<lane>_<n>.sh` locally). No `sprite exec` by hand — use `tools/work run`.
  3. Read results with plain commands: `tail -n 20 file`, `grep -a pattern file`.
Keep every Bash command to simple words: no `sh -c`, no `$(…)` inside quoted remote strings,
no `&` backgrounding with a polling loop (use the tool's own background/attach).

## Receipts start with `avra explain` (owner, 2026-10-13)
Before any custom trace or hand profile, a "why was this redone / where does the time go" question is asked of the compiler:
- `./avra explain --stats --time <pkg>` — answers derived per family, phase times. Run it on the scenario BEFORE and AFTER; the per-family counts are the receipt.
- `./avra explain --why <pkg>` — which files are not held and why, the way down to each moved input.
- `./avra explain 'Family(subject)'` / a file / `@name` — what one answer read, who reads it.
If explain cannot answer the question (a new saved family, a discarded attempt), that is a gap in explain: fix it there, from the same rows — never a second printout. AVRA_QTRACE / AVRA_LEAVES are for what explain does not yet show, and each such use names the gap in the lane file.

## Before a compiler rebuild after a merge or branch switch: move the cache aside (2026-10-13)
A `.avra-cache` left by another tree makes the derivation turn 4–5 times: measured 771–991 s and 4.36 GB peak
(OOM on an 8 GB Sprite) against 149 s and 2.1 GB with the cache aside; one lane's prep was killed at its 1,200 s bound,
132 s with the recipe. Until the turn-loop fix lands, every run script that rebuilds the compiler after `git merge`,
`git rebase`, `git switch` or a main merge starts with:
    mv .avra-cache "/tmp/old-$(date +%s)-$$"
(in a script file, never inline; never `rm`). Keeper for the fix: draft #737 (cache attack `ot`).

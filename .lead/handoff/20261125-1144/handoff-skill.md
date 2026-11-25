---
name: handoff
description: Snapshot EVERY lane right now (cloud lanes over the claude-web bridge, local agents and worktrees, gates in flight), push each as a handoff/* branch with its own HANDOFF.md, then write one lead handoff doc a new session can resume from. WIP is expected; lose nothing. Use when the owner says /handoff, "switching accounts", or "hand everything off".
---

# /handoff: lose nothing

Run it NOW, in parallel, with no confirmation. WIP is fine: uncommitted work is captured, never cleaned up first. Speed beats polish. A lane that can't answer is recorded as such, never skipped silently.

Stamp: `TS=$(date -u +%Y%m%d-%H%M)`. Every branch is `handoff/$TS/<lane>`. Never push `main` or `program`.

## 1. Cloud lanes (claude-web bridge)

1. `list_sessions`. Every session that isn't `completed` and was updated in the last 3 days is a lane. Include `blocked` and `review_ready`.
2. Send ALL of them, in one burst (`send_message`), this exact order:

   > HANDOFF NOW (account switch). Stop what you're doing. In your repo: (1) `git checkout -b wip-handoff && git add -A && git commit -m "handoff: WIP <what it is>"`; if the hook refuses, fix only what it names or note it, never `--no-verify`, and never discard anything. (1b) PUSH IT YOURSELF: attach avra-lang/avra (`git remote add gh https://github.com/avra-lang/avra.git` if absent), `git fetch --depth=50 gh program`, rebase your own commits onto `gh/program` (`git rebase --onto gh/program <your base> wip-handoff`; the old local program history carries a 101 MB blob GitHub refuses), then `git push gh wip-handoff:refs/heads/handoff/$TS/<lane>`. Put HANDOFF.md in the pushed commit as `docs/handoff/<lane>.md`. (2) Write `/work/out/HANDOFF.md`: goal, ticket ids, branch names and tip shas, what's done, what's half-done (files and state), what's next (exact next command), open questions, runs in flight (ids), and the base it sits on. (3) `git bundle create /work/out/handoff.bundle --all`. (4) Reply "HANDOFF READY" with the two paths. Do it within 5 minutes.

   A lane's own hook is the rule: never `--no-verify`. If the hook refuses WIP, the side branch still takes the commit, because fmt failure on WIP is recorded, not fixed.
3. As each replies (or after 6 minutes, for everyone), `pull_files` both paths into `.lead/handoff/$TS/<lane>/`. A lane that never answered: `read_session` with limit 5, saved as its HANDOFF.md, marked "NO REPLY: transcript tail only".
4. Lanes push their own `handoff/$TS/<lane>` branch (the Claude GitHub App is installed on avra-lang; pushes work, but lane-side deletes 403, so the lead deletes stale branches). Only for a lane whose push failed, use its bundle as a fallback: `git fetch <bundle> '+refs/heads/*:refs/handoff/$TS/<lane>/*'`, then push its current branch and every wip branch to origin as `handoff/$TS/<lane>/<branch>`. Add the lane's HANDOFF.md as a commit on top of its main branch (`docs/handoff/<lane>.md`) before pushing.

## 2. Local agents and worktrees

1. `ListAgents` for local teammates and subagents. SendMessage each one: "HANDOFF NOW: commit WIP on a branch, write HANDOFF.md in your worktree root (same fields as above), reply with the branch and path." Wait at most 5 minutes.
2. Without waiting on them, for EVERY worktree (`git -C /Users/tristan/projects/tristanMatthias/avra worktree list`): if it's dirty, capture its WIP WITHOUT touching its branch or index:
   ```sh
   cd <wt>; IDX=$(mktemp); cp .git/index "$IDX" 2>/dev/null || cp "$(git rev-parse --git-dir)/index" "$IDX"
   GIT_INDEX_FILE=$IDX git add -A && T=$(GIT_INDEX_FILE=$IDX git write-tree) && C=$(git commit-tree $T -p HEAD -m "handoff WIP $(basename <wt>)")
   git push origin "$C:refs/heads/handoff/$TS/local/$(basename <wt>)"
   ```
   Clean worktrees with unpushed commits: push `HEAD` to the same name. Skip only worktrees that are clean AND fully on origin.
3. A teammate's HANDOFF.md, when it arrives, goes into `.lead/handoff/$TS/<agent>/`.

## 3. Gates and runs in flight

`gh run list -R avra-lang/avra --limit 30`: record every in-progress or queued gate/ and run/ (id, branch, what it holds), and every green gate not yet landed. Don't cancel anything.

## 4. Peer sessions on this Mac

SendMessage "Avra UI" and "Avra Services" (and any other live avra session): "HANDOFF: account switch. Write your own handoff doc and tell me its path." Record their replies.

## 5. The lead handoff doc

Write `.lead/handoff/$TS/LEAD_HANDOFF.md`, short and scannable:
- **Resume first:** the 5 things a new lead does in its first 10 minutes.
- **Program head** (sha), the last landing, and the landing queue in order (train contents, mirror shas, gate branches).
- **Every lane, one row each:** name, session id or URL (or local worktree), ticket, branch `handoff/$TS/...`, state (done, WIP, blocked on what), and next step.
- **Gates and runs in flight** (from step 3).
- **Owner decisions and standing orders** from this session that aren't in memory or docs yet.
- **Open questions for the owner.**
- **Infra:** bridge restart (`bun src/cli.ts stop`, then any claude-web call), the gate-builder release assets, the cron sweep to recreate (CronCreate, every 20 min), and disk state.
- Pointers: `.lead/PROGRAM_DESIGN.md`, `.lead/handoff/RECOVERY_2026_11_24_STATE.md`, the tasks db (`TASKS_DB=.tasks/avra.db`).

Then push it: commit `.lead/handoff/$TS/` (the lead doc plus every lane's HANDOFF.md) via a temporary index on `origin/program` (as in 2.2) to `handoff/$TS/lead`. Also save the memory pointer: update `MEMORY.md` with "RESUME HERE: handoff/$TS/lead → .lead/handoff/$TS/LEAD_HANDOFF.md".

## 6. Report

Tell the owner, in under 15 lines: the branch to resume from, counts (lanes captured / no-reply / local worktrees pushed), anything that failed to capture and why, and the one line to paste into the new session: `Resume from handoff/$TS/lead: read .lead/handoff/$TS/LEAD_HANDOFF.md`.

## Rules

- No `rm`, no `git stash`, no `reset --hard`, no `--no-verify`, never push `main` or `program`.
- Never wait more than 6 minutes on any one lane; capture what exists.
- Fewer than every lane is a failure: list each missing one by name.

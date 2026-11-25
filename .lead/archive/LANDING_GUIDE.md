# THE LANDING GUIDE — how work gets through, and how we are never stuck again

> **SUPERSEDED as the single source by
> `docs/2026_10_11_THE_PIPELINE.md`.** The model changed on 2026-10-11:
> the merge queue was DROPPED for "require branches to be up to date"
> plus auto-merge, and the PR's own check is now the gate. §0 below states
> the current model; the queue mechanics further down are kept as history,
> not as instructions. This file is local and uncommitted.

## THE MODEL RULE (owner directive, absolute)
**ALWAYS spawn lanes on `deepseek/deepseek-v4.1-flash`. NEVER `deepseek-v4-pro` or any
larger model.** Pro burned a large multiple of the tokens for no better result. Omit the
`model` field only when the session model is already flash; otherwise set it explicitly.

This is the STANDARD PROCESS. It exists because we lost hours to nine specific,
avoidable failures (listed at the end, each with the rule that prevents it). Follow
it mechanically. If a step here is wrong, fix THIS FILE in the same change.

---

## 0. THE ONE-PARAGRAPH MODEL
**GREEN MUST MEAN LANDABLE, BY CONSTRUCTION.** A PR lands only when `main`'s ruleset accepts it:
**its required `test` check is green and it is up to date with `main`**. `main` is protected and
moves ONLY through auto-merge, one PR at a time — there is NO merge queue (dropped 2026-10-11:
"up to date" gives back the combination test the queue existed for, without trains that test many
PRs at once, HEADGREEN batching, or a rebase treadmill).

**THE SYSTEM (four mechanisms; each either runs or it doesn't):**
1. **Dev = Sprite, warm = ~10 s.** Lanes build/test on their Sprite against a warm store; the
   fast loop IS the loop. A cold build happens only when the compiler's own source changed.
2. **A PR check is the GATE.** `fmt` on the changed `.av`, idioms and `check` on the affected
   closure, the compiler-free keepers first, plus the keepers, the seed check and the affected
   packages' suites over the combination (which the branch holds, because it must be up to date).
   One definition: `.github/workflows/checks.yml`.
3. **Auto-merge is the landing mechanism.** A green PR has auto-merge armed (`gh pr merge
   <n> --auto --squash`) and merges itself once it is up to date; `land` arms it and moves on.
4. **A DETERMINISTIC WATCHER (no LLM) runs every ~5 min and never sleeps:** a PR whose required
   check failed → comment the exact `job — line` and re-run the failed jobs once; a green,
   mergeable PR → arm auto-merge; a green, armed PR behind `main` → refresh its branch; a PR
   that conflicts → name the rebase; a closed PR's run → cancel it. This is what makes
   'nothing is landing' impossible.

**The two standing rules that remain:** keep `main` green, and only ever offer a PR that is
green, on `main`, and not stacked.

**DO NOT make a PR run extra jobs to "close the gap" — that costs an hour per PR.** The
gap is closed by mechanisms 1 and 4: everything is proven at dev time on a Sprite, and the
watcher catches whatever slips.

---

## 1. BEFORE YOU PUSH (every lane, every PR, no exceptions)
Run these, in order, and **quote the last line of each in your report**:

1. `git fetch origin`
2. `git rebase origin/main` — **ONLY INTO `main`.** If there are conflicts, resolve
   mechanically; if a conflict is SEMANTIC (the two sides changed the same logic), STOP
   and report — never guess.
3. **A STACK IS FORBIDDEN.** A PR whose base branch is not `main` is never tested against the
   combination. If your work depends on another
   unlanded branch, land that first, then rebase onto `main`. Never open a PR against
   another PR's branch.
4. **RUN WHAT THE CHECK RUNS**, not just the files you touched:
   `sh tools/gate_changed.sh --refs origin/main HEAD --no-keepers` AND
   `make keepers-static` AND `make keepers-pr`, AND the affected package's suites
   (`./avra test packages/<the package(s) you changed>`, on a Sprite).
   *A green PR is cheaper than a red one, always. A red PR wastes a round (and, until it is green, blocks nothing else).*
5. **`git push`.** Then confirm it landed on the remote (`git ls-remote origin <branch>`).
6. **`gh pr merge <n> --auto --squash`** — and confirm `autoMerge=true`
   (`gh pr view <n> --json autoMergeRequest`). **This is the ONLY landing mechanism.**
   If the branch is behind `main`, the watcher refreshes it; never write or rely on a
   polling script; a watcher that dies is silent.
7. If the PR's base is not `main`, `--auto` will fail — that is rule 3 telling you it is stacked.

**If step 6 fails for any reason, fix the reason — do not "leave it for the lead".** A
green PR with no auto-merge sitting on a branch IS the bug.

---

## 2. THE ONE THING THAT BLOCKS EVERYTHING (check this FIRST, always)
Before queuing **anything**, ask: **is `main` itself green?** A keeper red on `main`
fails every train, so **no PR can land no matter what you do to it**, and every PR's
`test` check shows FAILURE.

- **Test it:** `gh run list -R avra-lang/avra --branch main` and, for the actual keeper,
  check out `origin/main` and run `make keepers-a` / `make keepers`.
- **If `main` is red, STOP ALL FEATURE WORK AND FIX `main` FIRST.** One lane, one PR,
  the keeper fix — it is the only thing that matters. Do not open, rebase, or queue
  anything else until it is green. (We lost seven hours to exactly this.)
- Common cause: a repo-wide KEEPER refuses (`codecs`, `idioms`, `seed-check`, `footprint`,
  `families`). It is almost always a **real source defect a recent merge introduced**, not
  a stale artifact. **Reproduce the keeper refusal on a fresh build before blaming the
  seed or a cache.**

---

## 3. THE LEAD'S LOOP (this is the job; nothing moves without it)
**A lane runs ONE task and then is DISCARDED — it is not a worker. A stopped lane is
SILENT.** So the lead must:

1. **Every time a lane reports, reply with its NEXT task in the same turn.** "Holding"
   or "noted" is a STOPPED LANE. Never answer a report without a next task (or an
   explicit "you are done for now").
2. **Keep 5–8 lanes running.** Before ending a turn: `intercom list` — if fewer than ~5
   are working, spawn more from the epic's remaining work.
3. **Every cycle, run the BOARD CHECK** (one command each):
   - `gh pr list --state open` → any of OUR PRs without `autoMerge=true`? Set it.
   - any CONFLICTING? Rebase it.  any STACKED? Un-stack it.
   - `gh api … mergeQueue` → is anything queued? If not and PRs are green, something is
     wrong (a red main, or auto-merge missing).
   - any lane's branch with commits **not pushed**? (`git status -sb` in each worktree;
     `git log --oneline origin/<branch>..<branch>`.) **An unpushed commit is a seven-hour
     stall in the making.**
4. **A lane with a finished run and no next task is a bug in the lead**, not in the lane.

---

## 4. WHEN SOMETHING IS STUCK — THE DIAGNOSIS ORDER (never skip)
1. **Ask GitHub, not your guess.** `gh pr view <n> --json state,mergeable,autoMergeRequest`
   and **try to enqueue it** (`enqueuePullRequest`). The error message IS the diagnosis:
   - *"No merge queue found for branch X"* → **stacked** (rule 3).
   - *"Required status check `test` is failing"* → **a check is red**; read THAT job's log.
   - *"merge conflicts / not in mergeable state"* → **rebase** (rule 1.2).
   - *"already in the queue"* → good, wait.
2. **A failing check names its job. Read that job's log** —
   `gh run view --job <id> --log | sed 's/^[^Z]*Z //' | grep -nE '✗|::error|FAILED'`.
3. **NEVER announce a cause from one screen of output.** Read the log for the job that
   actually failed; the first "refused"/"FAILED" line is the cause. (I once blamed the seed
   from an adjacency in the log; the real failure was the next keeper.)
4. **Reproduce the failing check's own scope locally** before changing anything.
5. Fix the CAUSE. Never weaken a keeper, a test, or a law to make something pass.

---

## 5. THE PRE-QUEUE GATE (run this on a PR before it is considered done)
- [ ] rebased on `main`, **not stacked**
- [ ] `gate_changed` + `keepers-static` + `keepers-pr` clean
- [ ] the **affected package's suites** green (the same ones the check runs)
- [ ] **a hot-path change quotes before/after per-phase times, and `make speed-ratchet`
      is clean** — each phase of `packages/cli`'s own build and check is held against
      `tools/speed.budget` and REFUSES past it (naming the phase and the delta;
      `tools/speed_ratchet.py`). The soft 25% job note is not enough: a sum of small
      per-phase regressions slips under it. Measured per machine — on the Mac it runs on
      the lane's Sprite; a cold store skips until `make try` has warmed it.
- [ ] quality bar met (HAIKU_RULES: idiomatic Avra; impl over functional; ONE definition
      per shape; `// LICENSED` at the site; refusals as named voices)
- [ ] pushed, and present on the remote
- [ ] `gh pr merge <n> --auto --squash`, and `autoMerge=true` confirmed

**A PR is "done" only at the last checkbox. Anything earlier is work-in-progress, no
matter how green it looks locally.**

---

## 6. THE RESOURCE CEILINGS (they stall work silently — check them too)
- **Sprites** are the build machines: one per lane. `sh tools/work sprites` — if none is
  free, **provision one** (`sh tools/work new <name>` / `bind`); do not run heavy builds
  on the Mac (ONE build slot, shared). A lane with no Sprite is a lane that cannot finish.
- **Credits / in-flight budget:** a `402 in_flight_budget_exhausted` kills every lane at
  once. It is an ACCOUNT limit — tell the owner; do not retry in a loop.
- **A rate-limited/blocked lane looks identical to a slow one.** Check `intercom list`
  and the run's output tail (`…/tasks/<id>.output`, its mtime) before assuming progress.

---

## 7. THE NINE FAILURES THIS FILE PREVENTS (why each rule exists)
1. **Red pushes** → a train with one red PR drops the WHOLE train (5–10 innocent PRs
   bounce). *Rule 1.4: run the check's scope.*
2. **A committed-but-unpushed fix** → the campaign sat 7 hours on one unpushed commit.
   *Rule 1.5 + rule 3.3.*
3. **No auto-merge** → green PRs never entered the queue. *Rule 1.6: `--auto`, confirm it.*
4. **Stacked PRs** → `No merge queue found`; they can NEVER land. *Rule 1.3: stacks forbidden.*
5. **A red keeper on `main`** → every train fails; nothing can land. *Section 2: fix main FIRST.*
6. **Stale branches** → merge conflicts. *Rule 1.2: rebase onto `main` before pushing.*
7. **The lead stopped feeding lanes** → an empty fleet, silently. *Section 3: the loop is the job.*
8. **Dead watchers** → a poller that dies re-queues nothing, invisibly. *Rule 1.6: the platform does it.*
9. **A cause announced from one log line** → a wrong diagnosis cost hours. *Section 4.3: reproduce it.*

---

## 8. BABYSITTING A LANDING (when you must)
Native auto-merge is the mechanism; you should not need to poll. If a PR is **green,
mergeable, on `main`, auto-merge set, and still not queued after ~10 minutes**, take it
out and put it back once (`dequeuePullRequest` then `enqueuePullRequest`) — a queue entry
with no `merge_group` run is stuck and waiting does not start one. If a train fails,
read its failing job (Section 4) — and if the failure is a **train-mate's**, that PR is
the one to fix, not yours.

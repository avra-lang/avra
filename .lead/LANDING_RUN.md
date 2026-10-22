# LANDING RUN — owner asleep ~9h (2026-10-16 01:25Z → ~10:25Z)

Goal: **every in-flight branch fully landed on main** by the owner's return. One landing at a
time; batch waves when two are close; never push mid-run; never red; every lane red-teams +
does a review round before it pushes.

## Protocol (every landing)
1. `gh pr update-branch <n>` (or rebase by hand if conflicts / seed-owning branch), then
   `make bootstrap` if the tree's compiler changed.
2. `sh tools/work wait <branch>` bounded; then strip `DO NOT MERGE` via
   `gh api -X PATCH …/pulls/<n> -f title=…`; `gh pr ready <n>`; `gh pr merge <n> --auto --squash`.
3. If the run reds: **wait for the FULL matrix**, collect every failure, fix once, push once.
4. On merge: close members with a pointer; ping CHANNELS (`01a136e2`) so we interleave.
5. Recreate a dead lane against its **worktree + branch head** (the worktree is the durable unit;
   dead agents are garbage-collected and cannot be resumed — verify with `get_subagent_result`).

## Queue (land in this order; batch when they collide-free and close together)
| # | thing | branch / PR | blocker |
|---|---|---|---|
| 0 | CHANNELS wave 2 | **already in** (9cdec783) | — |
| 1 | **nodes step 2 (both halves)** | **LANDED #813** (08:55Z, main 8811834c; net −229) | done |
| 2 | **#808 + s4bc3 → ONE integration** | PR #808 closed-carried; `db-s4bc` | `s4bc3` push (3/4 green, std-avrac fighting the floor) |
| 3 | `db-07a` mint ownership | `db-07a` (base db-slice) | lands after #2 (same files) |
| 4 | `db-09` Settled/Lifted | `db-09` | independent |
| 5 | `db-01b` producer listing | `db-01b` | independent |
| 6 | `db-05c` store **clean** + time-travel | `db-05c` | independent; gc→clean rename ordered |
| 7 | `db-04e` input-door ledger | `db-04e` | independent |
| 8 | `nodes-step3` shape defaults | `nodes-step3` | independent |
| 9 | `nodes-field-default` ladder | `nodes-field-default` (1: field, 2: seed, 3: reader) | seed ladder |
| 10 | `nodes-facet` `@facet` | `nodes-facet` | independent |
| 11 | `nodes-carriers` N-variants | `nodes-carriers` | independent |
| 12 | un-stack #800/#804 after #807/#808 land | — | close as carried |
| 13 | **07e** hold deletion (after 2+3+4) | — | next real speed step |

## Coordination rules (race avoidance)
- Distinct branch + worktree per lane; never two pushes to one branch.
- **ONE lane (`land-run`) pushes to main, ever.** Worker lanes only open DRAFT PRs and ping the lead. One landing at a time: `update-branch` → wait register → ready → arm.
- **NEVER run a git WRITE from the main checkout**: its index carries 505 staged files / 338k insertions left by a lane (local main also 42 behind). Work in a worktree. Pure `gh` needs no checkout.
- Anything landing within minutes of another → merge into ONE integration PR (`mega-integrate` pattern).
- A full suite / `make bootstrap` on a **Sprite only**. Never invoke `watch.sh` from a lane script
  (nested watchdog self-deadlocks the machine lock).
- `avra cache gc` is spelled **`avra cache clean`** (owner directive).

## Standing lane protocol
- Red-team (`.claude/skills/red-team/SKILL.md`): 8 classes, every survivor a permanent test.
- Review-round (`.claude/skills/review-round/SKILL.md`): dogfooding/DRY/centralizing/prose/test honesty.
- Check in ≤3 lines with `LEARN:` / `DECIDE:` / `BLOCK:` tags.

## Housekeeping (owner directive — do it as you go)
- **TASK DB after every landing**: `.tasks/avra.db` — comment the epic task with the PR + receipts,
  close the task a landing completes (verify acceptance, never close blind), create a task for any
  new finding/blocker. Use the `tasks` CLI (`TASKS_DB=$PWD/.tasks/avra.db`); never MCP tools.
- **CLEAN UP WHEN DONE**: when a lane's PR has landed — `sh tools/work done` (frees its Sprite),
  close the branch's superseded drafts (`gh api -X PATCH …/pulls/N -f state=closed` with a pointer),
  close carried batch members, and move scratch aside (`mv`, never `rm`). Never delete a sibling
  lane's worktree without the owner's word; never clear another worktree's `.avra-cache`.
- Keep `.lead/LANDING_RUN.md` and `.lead/NIGHT_LOG.md` current so the wake-up report is exact.

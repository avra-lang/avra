# STD relaunch — handoff

A new STD task master reads this file and takes the work. Written
2026-09-15 by the outgoing master. State first, then how to run it,
then the sessions.

## STATE at main `43ae6f4`

26 merges landed 09-14/15. Tracker: `export
TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db
TASKS_ACTOR="STD MASTER"`. Epic `avra-ms0j` under `avra-8sb5`.

### In flight
| what | where |
|---|---|
| nothing | No open PRs. Every branch pushed on 09-14/15 is landed. |

### Lanes
- **STD-DATA** — LIVE. `.6.2` (the sqlite read half) is WRITTEN and
  proved (430/430 both engines) but MUST LAND AS TWO PRs: a new
  `rt_sigs` row the compiler's own source declares CANNOT GATE from a
  seed that predates it. PR A is **#26** (`data/adopt-row`) and carries
  the runtime C, the row, the reach law and the vocab entry — NO
  `RtHost` variant and NO placeholder arm: the row lands
  `host: RtHost.Unhosted`, which is true while the evaluator has no
  arm, and whose arm already exists. Gated from a COLD BOOTSTRAP on
  main's seed (`seed-check: the seed compiles HEAD`, peak 811 MB).
  Merge it and `make seed`. PR B is **#25** (`data/sqlite-read`),
  already written and proved 430/430 both engines; it adds the
  declaration, the `RtHost` variant with its real arm, and the faces,
  and gates once main's seed knows the row. `avra-vvds` holds the
  ladder. Doing `.3.2` meanwhile; then `.3.6`. Epic `avra-bjkk`.
- **TOOLCHAIN** — CLOSED, epic closed, five worktrees retired and
  branches archived. `avra-kpqs` left open and UNASSIGNED for a fresh
  session (it is not in a closed epic by accident).
- **LANE-D / STD-SUBSTRATE / STD-NET-HTTP** — closed, worktrees
  retired, branches archived as `archive/*` tags (pushed).
- **LANGUAGE-CORE** (`avra-2y5c`), **SUGAR** (`avra-70jh`) — never
  launched, both need re-scoping; see below.

### Owner's queue `avra-8sb5.8`
`avra-us1e` (probe a trigger the day it is recorded; evidence in
`avra-57b8`), `avra-nu2m` (decorate a law only with what a named
instrument re-derives; three instances), `avra-tsxq` (the 40 GB
runaway log), `avra-8sb5.5.3` (main's worktree holds another session's
uncommitted work — an integration never stashes), `avra-8sb5.8.1`,
`avra-8sb5.8.10`.

Snapshotted and pushed: `snapshot/main-wip-20260915` (9 docs files,
still live in main's worktree) and `snapshot/sq-ffi-float-20260915`.

## How to run it

**Integrate:** `sh tools/integrate.sh <lane> <message-file>`, launched
detached (`nohup … &`), watched with a Monitor on its log. It wants a
worktree at `../avra-lane-<lane>` ON BRANCH `lane/<lane>` and refuses
any other branch, deliberately. Never aim it at a session's own
worktree.

**After `main at <sha>`:** if the primary will not fast-forward (the
owner's 9 uncommitted docs files), `git stash push -u`, `git merge
--ff-only <sha>`, `git stash apply`, drop. Then push, close the PR,
and kill the integrator BEFORE removing its worktree — its tail
rebuilds a removed worktree and wastes a lock slot.

**Conflicts:** ROADMAP survey sections and CLAUDE.md law additions are
append-collisions; keep both sides, then `grep -n "^- [A-Z]" CLAUDE.md
| sed 's/^[0-9]*://' | sort | uniq -d` must answer nothing. Real
conflicts do occur (a Makefile seed-check union, a deduplicated
`vocab.sh` row) — read before resolving.

**Batch when you can.** Four toolchain branches merged as one
integration: one gate, one seed, instead of four of each.

**Docs-only diffs** may be landed by inspection, ANNOUNCED on the PR:
nothing in the Makefile or `tools/` reads CLAUDE.md or ROADMAP.md as
data. Read a doctrine diff yourself first.

**Stacked PRs:** retarget the child to main BEFORE deleting the parent
branch. The integrator rebases, so a parent's tip is never an ancestor
and GitHub closes the orphan (`avra-z3f7`; it closed #22, reopened as
#24). `gh pr edit --base` needs a scope the lanes' tokens lack.

**The lock has three slots** (`b118773`). A gate peaks ~830 MB on a
16 GB machine. The comptime campaign layered ticket fairness on top in
`../avra-lane-comptime` — a strict superset, worth taking into main.

## What bit us
- **Disk twice.** A build log with no ceiling reached 43 GB. Capped at
  `5aedc2a`; six other redirects at `avra-e21k`. On ENOSPC stop
  everything: a failing link deletes `build/avra`.
- **A fork bomb** from a self-test reachable from its own entry point
  — 2441 processes, every other session's builds dying on `fork:`.
- **Eight harness kills** in one night. The gate is one transaction; a
  kill in its last step discards all of it. `avra-b878`.
- **A lane's receipt is not certification.** Reports route and
  prioritise; the integrator's gate decides. One false green was sent
  and retracted (`avra-d0om`).

## Standing orders (every session)
Opus. Fresh worktree from main; `make bootstrap` in a cold tree.
Tracker is the channel — claim, close with receipts, create at the
ROOT then `--parent`. `/red-team`, `/review-round`, `/feedback` every
slice. One PR per slice against main, ≤3k lines, never push to main.
Short commits and comments, no narrative docs. Survey at the end,
wants under `avra-8sb5.11`.

**The thing that worked:** six tasks were falsified by the lanes that
received them, every time by measuring rather than reading, and every
time the task was what was wrong. Hand a lane a claim, not an
instruction, and say so.

## Sessions

### STD-DATA (live)
Worktrees `../avra-lane-sq-ffi`, `../avra-lane-sqlite`. Epic
`avra-bjkk`. Now `.6.2`, the text/blob READ half, Option A as ruled ON
the task by the owner: the copy exported, named unsafe, wrapped;
negative length refused; (null, 0) the empty box; faces ask the column
class first and answer Result; an empty text/blob is an EMPTY BOX and
only SQL NULL is null; a borrowed view is a recorded trigger. Write
the empty case first. Then `.3.2` (read_bytes/write_bytes against
Bytes), `.3.6` ([link] objects escaping a package root).

### LANGUAGE-CORE (not launched — RE-SCOPE FIRST)
Epic `avra-2y5c`, worktree `../avra-lane-c`. The epic is stale twice
over: `Cell<T>` ALREADY EXISTS
(`packages/std-avrac/src/features/cells/`), and `avra-8sb5.4.4`'s
"blocked on the owner" is discharged (`avra-8sb5.8.2` — spec 11.5
wins, Cell the only door, get/set not forwarding, the memo's write is
the compiler's state). REAL WORK: `avra-8sb5.4.5`, **H3, a live
soundness hole** — `mut ys = self.xs` then `ys.push(v)` mutates
through an immutable parameter with zero diagnostics, both engines
answering `1 2 2` where spec 11.5 demands `1 1 0`; the engines agree
and are both wrong. Then `.4.4` S2, the cell ABI with the borrow
deleted. Plus `avra-ewei`, `avra-ismf`, `avra-mtrh`, `avra-3cvq`.

### SUGAR (not launched — nothing filed)
Epic `avra-70jh` is empty. Sugars 3–5 are
`docs/2026_09_09_SUGAR_3..5`: typed runtime rows `rt.name`, emission
as an expression, named arguments. Each is grammar + typing, then a
sweep of the compiler's own passes, a ratchet rule in DOGFOODING with
its matcher, gate. A new DSL word needs the four-generation ladder and
a seed refresh. Then triage `avra-8sb5.10` and `avra-8sb5.11` into the
next five, with wanting sites.

### TASK MASTER
You do not write code. Audit the db, not reports. Rule everything the
owner need not; keep `avra-8sb5.8` to what only they can decide and
record each ruling on its task. Review by SHAPE, gate every PR
yourself, merge bottom-up, `make seed` after a compiler change. Report
ADHD style: next action first, ≤5 items, state every turn.

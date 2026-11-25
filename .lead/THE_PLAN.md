# The plan — the one document

Replaces every other plan and handover in `.lead/` for this work. History: `.lead/HANDOVER.md`.

**The one line of work:** `origin/hold-out`. Every other branch is history, never a base.
**Goal:** `.lead/GOAL_2026_10_30.md`, done criteria unchanged.

## The root defect

Compiler facts are written into shared tables as a side effect of passes. They should be query
answers. `names_settled`, `kept_owed`, the signature replay log, `unheard` and hand-marked
`@lasting` all exist because of it. A fix that adds another of these is the wrong fix.

## Decision: replace in place, no compiler rewrite

Keep the passes, the query engine and the test suites. Replace the fact model one piece at a time,
deleting the old piece in the same commit. Review the decision at Gate 1.

## Milestones

| # | Result | Proof | Owner | State |
|---|---|---|---|---|
| 1 | Warm reuse: judge by name, per-file roots, reverse index | one-edit ≤2 s, 0 errors; checking mode agrees; attack cases | L-reuse | in progress (47.3 s) |
| | **GATE 1** | see below | lead + owner | |
| 2 | Facts are answers: `items_of_file`, names over it; `names_settled`, `kept_owed` gone | warm report equals cold report | L-reuse | queued |
| 3 | ≤300 ms: unchanged ≤60 ms, build after edit ≤500 ms, std-avrac edit ≤600 ms | measured on an idle machine | L-reuse | queued |
| 4 | One store: `@family` → 0; `db.av`, `kept_settle.av` deleted; hold mentions → 0 | counts at 0 | L-reuse | queued |
| 5 | One format, one key, one hash: hand `_wire`, `*_key`, `fingerprint` gone; `@lasting` inferred | ratchet at 0 or each survivor licensed | L-reuse | queued |
| 6 | One ceiling: 4 disk settings → 1; a kept answer and what it names live in one store (objects no longer split from their list) | store_bound and object_gone attacks | L-reuse | queued |
| 7 | Sound: `cache_attacks` ported and green, `kg`, `dt` fixed | whole script, no known reds | L-reuse | queued |
| 8 | Nodes epic closed. Owner chose 2026-11-05: construct-only builders go; a builder with real logic stays as a function, with a written reason at the site (replaces "≤1") | ticket text done | L-nodes | in progress |
| 9 | Landed: `hold-out` → `hd-clean` → main | green gate | lead | last |
| 10 | Cleanup: PR #1371, branches, worktrees, old docs | see below | lead | last |

## Must clear before landing

- `tasks/tests/within_net` dies with signal 11 in the combined ~10k-test run: a forked schedule child at its stack's bottom (`program_under`, avra_fiber.c). Crash reports: `~/Library/Logs/DiagnosticReports/suite-2026-11-05-*.ips`. Not reproduced alone.
- `features/collects/tests/closure_entry_b` prints `[]`, not `[knob]`, in a batch; passes alone. Red on hold-out too, so not from the merge. A wrong answer. It stops the features group, so later features didn't run.
- 17 cli suite reds, also red on base.
- A law spoken only at another file's instantiation isn't re-checked in normal warm mode.

## Gate 1: is replacing in place working?

Measured after milestone 1 lands, on an idle machine:

- Body edit ≤2 s with correct answers, and signature, new-fn and new-file edits proportional to what reads them, never a whole-program run: continue.
- Over 2 s, or wrong answers the attacks can't pin down: stop. Lead brings the owner a costed
  option to rewrite the storage and validity layer behind the existing query API.

## Rules for every lane

- One stream: L-reuse alone owns milestones 1–7. L-nodes is the only other lane, at low build priority.
- World-class bar: derive and centralize everything possible. One definition per mechanism; "for now" code needs a deletion point in this plan.
- `grammar/` is a library for any language: no Avra concept enters it; a new form must make sense for a JSON or SQL grammar and cost nothing on rules that don't use it.
- Big sweeping batches over small slices. Reuse existing mechanisms first.
- A batch deletes what it replaces; lines go down.
- No new side-table write, hand format, hand key or hidden read.
- Before each push: whole compiler suite, `warm_agrees_test`, the attack cases.
- Wrong-answer risk gets a two-process test, watched failing first.
- This is the only plan; never write another elsewhere.

## Cleanup rule

- Old docs move to `.lead/archive/`.
- A branch or worktree is deleted only with nothing unmerged or uncommitted in it, or with the
  owner's explicit word.

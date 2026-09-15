# Perfect-compiler program — handoff

I am the COMPTIME TASK MASTER. I own phases A–K of
`docs/2026_09_14_PERFECT_COMPILER.md` (NOT §9/phase F — the owner
excluded it). Workers do the slices; **I commit and merge, they never
do.** This file is the whole workload; keep it current.

## Integration

| | |
|---|---|
| branch | `lane/comptime`, worktree `../avra-lane-comptime` |
| head | `28dcac8`, pushed to origin |
| main | `fa0c1ec` — BEHIND; merge at a milestone, not per slice |
| dashboard | https://claude.ai/code/artifact/782ea599-df60-4594-a9a1-dcd500ce0b14 — file `build/scratch/perfect-compiler.html`, `P = [name, size, done, total]`, republish with the Artifact tool, same path. No text updates. |
| tasks | `export TASKS_DB=/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db`; `tasks` CLI direct, NEVER the MCP task tools. Survey wants under epic `avra-8sb5.11`. |

## Phases

| | state | worktree / branch |
|---|---|---|
| A typed names, derived copier | **DONE** 2/2 | retired |
| B one meta vocabulary, one crossing | **DONE** 3/3 | retired |
| H side tables, derived identity | **DONE** 2/2 | retired |
| G runtime header + diagnostic witnesses | **DONE** 2/2 | `../avra-phase-g`, `phase/g` @ `efb1200`, merged, clean — retire it |
| C children + fingerprints derived | 1/3 | `../avra-phase-c`, `phase/c` @ `1c39ad8` |
| D grammar names the node, fmt | 2/4 | `../avra-phase-d`, `phase/d` @ `a582dac` |
| E type marks, IR roles, ownership | 0/3 | `../avra-phase-e`, `phase/e` @ `1c39ad8` |
| I ownership roles on Ins | **UNSTAFFED** | blocked: marks the same `Ins` payloads as E2 — start only after E2 lands |
| J one hole-bearing block | not started | after D |
| K attack/doc/binding/diagnostic `at` | not started | last |

## In flight

- **C1** — `@derive(Children)` + `@derive(Identity)` over the node model.
  Corrections it made to its brief, both upheld: `kids`/`post_order` STAY
  hand-written (a feature hides children it types under a narrowing); the
  identity derive generates **store vocabulary**, because folding an
  `ExprId`'s index would give identical subtrees different identities.
  Required: make `nodes_test.av`'s content-identity case FAIL first.
  Carries `make seed` (first commit that READS a grown field).
  Also owes: a witness for `F2086` (see G's keeper below).
- **D2 rung 1** — comments + blank lines as offset-keyed trivia.
  Receipt over all 548 files: 0 refused, **283 remark lines lost in 41
  files** (its gap), **527 doc-comment lines lost in 21 files**
  (PRE-EXISTING — `///` is kept only on a declaration), 497 files differ
  for reasons not yet explained. RULED: build the **positional cursor**,
  not ten per-site lookups. `--write` stays gated on both counts reaching
  zero over every file — never a corpus.
- **E2** — role marks on `Ins` payloads. Approved: the payload-mark
  **grammar change** (marks attach to a variant today, not a payload), so
  phase I inherits the honest spelling. §4 DROPPED as a derive — 40
  matches not 20, and the three machine-shape readers disagree on four
  variants, so they are three properties, not one. Keep `step`, the
  memory pass and `emit_ins` hand-written. Ruled on `make vocab`: keep
  the rows, change what each ASSERTS (hand-written → grep; derived →
  assert the annotation), and refuse a row whose subject is in neither.

## Standing orders (owner)

- Subagents run **opus**, never fable.
- FULL AUTHORITY to change bad architecture, names, interfaces. Never
  work around them.
- Beautiful, fast, DRY, centralized. Idiom bar BEFORE writing each fn.
- Every slice: `/red-team`, then `/review-round`, then `/feedback`.
- Workers never commit. Report tree + proposed message; **I commit.**
- End-of-life survey per worker, filed under `avra-8sb5.11`.

## Merge protocol

1. Worker reports green gate READ TO THE END + commit message.
2. `git -C ../avra-lane-comptime fetch <worktree> <branch>; git merge`.
3. If `git diff FETCH_HEAD -- . ':!tools/watch.sh'` is EMPTY, the
   worker's gate is the receipt — say so, skip re-gating.
4. Otherwise it is code nobody gated: build, prove the fixed point,
   `make gate`, refresh the seed if a keeper says so.
5. Push, update the dashboard, update this file.

**Two merges needed a LADDER**: when both parents moved the compiler,
neither parent's seed can read the merged tree. Build the intermediate
generation with the migrated grams in their OLD spelling, restore, build
twice. Expect gen1 != gen2 and gen2 == gen3 after a syntax change.

## Machine

- Lock is **three slots, entered in arrival order** (`tools/watch.sh`,
  `e21b5dd`). A ticket means WAITING, not RUNNING — drop it when a slot
  is taken or the queue defeats the slots.
- 16 GB, disk ~96% full. ENOSPC hit zero three times; **stop and report,
  never retry-loop.** Swap cannot grow when the disk is full, which is
  what panicked the machine, not the compiler.
- Kill by PID, never by pattern. Park scratch OUTSIDE `packages/`.
- `cp build/avra build/avra.pre` before every risky build — it has been
  the way back five times.

## Open, filed, unowned

| id | |
|---|---|
| `avra-9cbe` | `core.Payload` and `@std.meta.Field` are ONE concept; the poorer copy is WHY a type spelling gets parsed as text. Routed to C (owns `Kind`). |
| `avra-9tfi` | two more string-keyed spelling registries retirable onto `Kind` — same seam |
| `avra-iwls` | **P1**: an annotation on a file's FIRST statement runs TWICE, silently. `no_stmt` is `StmtId{index:0}`, a real index. Witnessed with a control. Tree is lucky, not safe. |
| `avra-jbpa` | `avra expand` traps on an empty file (pre-existing) |
| `avra-iusx` | std-process `proc_seam` race — not ours |
| `avra-egav` | phase H owes an after-census; before-baseline in the ticket |
| `avra-iemo` | a re-entrant expansion's hush may erase a spoken refusal (unwitnessed) |
| `avra-6ndp` | collapse `Variant.payload` into a projection of `fields` (shrink ladder) |
| `avra-5m62` | ANSWERED by G: summary and law are different artifacts, 60 of 72 differ |

## Laws this program paid for

- A merge of two lanes that both moved the compiler needs a **ladder**.
- A seed refresh is owed by the first commit that **READS** a grown
  field, not the one that grew it. Tell: an index one past a length, at
  an annotation.
- A formatter owes **losslessness**; idempotence passes *because* of the
  bug, since the second pass has nothing left to lose.
- A **performance defect and a sampling temptation are the same defect**
  — ask whether the subset was chosen by the question or by the runtime.
- A bad pattern propagates by being the **nearest example to copy**.
- A witness that no longer triggers its code is a green test proving
  nothing — assert the code FIRED.

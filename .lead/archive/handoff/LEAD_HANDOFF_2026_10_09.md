# Lead handoff — 2026-10-09 (DB + nodes campaign)

You lead epics **avra-8sb5.57 (Compiler DB)** and **avra-8sb5.89 (nodes)**. Repo
`/Users/tristan/projects/tristanMatthias/avra`. Lanes read `.lead/handoff/HAIKU_RULES.md`
(now carrying the Code QUALITY bar). A **peer session "CHANNELS" (01a11cf4)** shares this
checkout on the flow-03 runtime campaign — NEVER touch its worktrees (`avra-flow-02`,
`avra-flow-03`, `avra-flow-03r`, `avra-flow-l12`) or PRs (#499/#510/#511/#514). #345/#338/#339
are neither ours.

## THE FAILURE MODE THAT COST THE MOST (read this first)
**A pi agent runs ONE task and is then DISCARDED; it is not a worker.** The lead's whole job is
the loop: *lane reports → immediately hand it the next task.* I repeatedly replied "holding"
(acknowledgement) instead of re-tasking, and because a stopped agent is SILENT nothing surfaced
it. Keep 5–8 lanes running, check `intercom list` for the fleet, and NEVER let a report go
unanswered with the next task. A finished agent cannot always be resumed — respawn it fresh
with a self-contained brief.

## THE LANDING MODEL (do not re-litigate)
- `allow_auto_merge` is **true**. Do NOT use `.lead/scripts/qwatch.sh` (a dead poller); instead
  every PR calls **`gh pr merge <n> --auto --squash`**. A STACKED PR (base ≠ main) cannot
  auto-merge until its base lands; rebase it onto main then.
- **A LANE MUST RUN THE CHECK'S OWN SCOPE BEFORE PUSHING** — the affected package's tests, not
  just the files it touched. Red pushes were the dominant cost; one red PR drops a whole train.
- PR check = fmt + idioms + pr-keepers + touched suites. The TRAIN runs the full gate: `gate`,
  `pr-keepers`, `suites`, `keepers` (all keepers incl. `seed-check`), `test` (aggregator).
- Keep PRs small AND serialised per file-family (the store's/ codec's slices all edit the same
  files, so only one of each can be green at once).

## THE CURRENT BLOCKER (in flight)
Every train failed at `keepers` → `seed-check` refused: the committed `bootstrap/seed.ll` could
not compile HEAD (a shape was consumed without a seed refresh). **Lane `seed-refresh`
(8db46111-0196-4df)** is producing that PR; the moment it lands the trains stop failing and the
whole queue drains at once (HEADGREEN). After that, **add `seed-check` to the PR-level keeper
set** so the first reader reddens its OWN PR, not every train.
Also fixed on the way: the store obj cache now folds the build mode (host/wasm `.o` collision).

## LANES RUNNING (spawned 2026-10-09 ~later)
| lane | worktree / branch | task |
|---|---|---|
| seed-refresh | new | refresh `bootstrap/seed.ll` so `seed-check` passes; PR + auto-merge |
| store-compact | avra-db-a3 / `store-compact` | compaction+gc+time-window → `store_attacks` 10/0; PR |
| store-body | avra-db-store / `db-05c-body` (PR #524) | body/idx write green; then §6.1 checklist |
| db07 | avra-db07 / `db07-dispatch` | per-family dispatch (code-hash precision) |
| nodes-next | avra-nodes | fix `.89.8` derived walk, else land step 1b (Control) |
| fastloop-218 | avra-fast-loop / `verdict-decls` | `.218` cli-scale held 0/492 |
| landing | (was 96a26746) | already cleared the PR backlog: 3 merged, 8 to green+queue |
| quality | read-only | reviewed all PRs; findings routed |

## EPIC STATE (tree-verified)
- **DB01 ✅, DB03 ~done (36 codec pairs, 0 gaps), DB04 ✅ (input door done, 130→87 outside).**
- **DB05 ~half:** keys→BLAKE3 ✅ (#494), skeleton ✅ (#509), names/sets ✅ (#512), columnar
  meta ✅ (#515), **code-hash generation-stability ✅ (#522 — a no-op rebuild moves 0/37)**;
  **compaction written but no PR; body/idx = #524; S2 precision = DB07.**
- **DB06 blocked on DB05; DB07–DB12 open.** `.218` (DB07 first cut) blocked on the cli-scale check.
- **Nodes:** step 2 nearly done (expr 2e/2f landed; **Stmt half S-a = #521**); step 3 blocked by
  bug `.89.8` (a `kids` default calling `@derive(Children)`'s `expr_children` segfaults — with
  `kids -> []` the tree is green, so the DERIVED WALK is the defect); steps 1b/5/6 untouched.
- Tests-doctrine note: the quality bar is in HAIKU_RULES (idiomatic Avra; impl over functional;
  one definition per shape; `// LICENSED` at the site; refusals as NAMED VOICE fns).

## OPEN THREADS
- `db03c` Map-encoding (`Map<string, DeclId>`) — design call.
- The `kids`/`heirs` decision: **one `@own` field mark + `heirs` stays on `NodeSemantics`**.
- `.89.8` (derived-walk bug), `.89.7`/`.57.217` closed, tracker synced 2026-10-09.

# Lead handoff — continuation of session 01a11cef-77d2-753a-aed5-65fd00ebd638

Written 2026-10-08 ~late PM. Supersedes `LEAD_HANDOFF_2026_10_08_PM.md` where they disagree —
that one's branch list was largely stale (db-names→#385, static-names→#419, db-00a→#312, and
`.378` L1 were all already on main).

## Agent resumability
Agent state is per **session id**: `.../pi-subagents-502/<cwd>/<PI_SESSION_ID>/tasks/`.
- Resume by agent ID works only inside the SAME session id. Resume THIS session to keep the 8
  live lanes resumable; a fresh session cannot resolve these IDs — respawn from the table below.
- A restart kills running lanes; their uncommitted work survives in their worktrees.

## Live lanes (agent id · worktree · branch · task · state)
| lane | agent id | worktree / branch | task | state |
|---|---|---|---|---|
| db-inputs-h | `90a7d990-22cb-4a4` | avra-db-inputs / shape-memo | `type_shape` as a Shape query, memoise NESTED visits build-wide (the #443 ~40 s) | in flight |
| nodes-h | `6c167d4f-a124-4d1` | avra-nodes / nodes-2f | nodes step 2f (components, when, impls `method_call_*`, closures) | in flight |
| fast-loop-h | `f95b0dba-d3ad-479` | avra-fast-loop / verdict-decls | per-decl verdict + staleness attacks f/g/h in CACHE_ATTACKS `vd` | in flight |
| db-store-h | `aec71196-9554-4df` | avra-db-store / one-okey-2 | held-count (part 1); **05c-1 BLAKE3 already done** → next is 05c-2 keys | in flight |
| db-a3-h | `a4576980-d543-411` | avra-db-a3 / db-01e | DB01 **01e** (families by name, delete `tools/families.order`) | in flight, staged-delete present |
| db-explain-h | `dab77cd1-a17b-43c` | avra-db-explain / decls-insert-above | DB03b codec, **option A′** (helpers for recursive records + payload enums) | in flight |
| db-measure-h | `95c2923c-d839-454` | avra-db-said / link-lld | land `link-lld` (#411 now merged) | in flight |
| queue-rebase | `d9ee06c2-24ae-4ad` | avra-queue-rebase | rebase #471/#474/#479 | DONE |

## Facts established this session (verified on main, not tickets)
- **BLAKE3 is DONE**: vendored + built (`HASH_OBJS`) + archived into `COMPILER_OBJS`, seed.ll
  references it. DB05's 05c-1 is closed. Next DB05 work is 05c-2 (keys → BLAKE3) then the store format.
- **DB03a done** (#362/#419/#385); **#483 merged** (`24f7d8e`) — DB03 acceptance witness landed.
- **#471 merged**; **#474, #479 open & mergeable**; **#468 is the owner's DRAFT** (train failed on suites+test).
- **DB01** 01a–d merged, **01e in flight** (db-a3-h). **DB05 store format = the critical path.**
- Board candidates not yet landed: `nodes-2e` (nodes-h's next), `tool-door`, `explain-moved`
  (PR once #474 lands).
- Designs written this session: `handoff/218-part2-design.md` (.218 per-declaration reads),
  `handoff/nodes-step3-reducibility.md` (7/9 residue mark-reducible; Comp & Component irreducible).

## Stranded worktrees with real tracked work (survey)
- `avra-rel` `[trace/dbfork]` @ 8254155 — 5 files uncommitted (+59/−30): `features/decls_mint.av`
  (50 lines), `compiler/structural_types.av`, `features/contexts.av`, `features/decls.av`,
  `decl_row_parity_test.av` — **decl-rows territory**.
- `avra-mh-held` (detached @ `bc2d64a`) — **35 files STAGED, never committed**: deletes the witness
  system (`witness.av` + 11 witness tests, ~3 500 lines), deletes `store/pack.av` and
  `store/explain.av`, rewrites `codecs.av`, `db.av`, `workspace.av`, `namespace.av`. Old frozen refactor.
- Everything else dirty is untracked probe scripts (largest: `avra-db-said` 37, `avra-db-125` 47,
  `avra-flow-03` 16, `avra-ui-h` 23, `avra-ui-i` 18 — all untracked).

## Pending DB features (tree-verified) — see the two tables in chat
DB01 01e · DB03b/03c · DB04(e) inputs.baseline 135 · **DB05 store format** · DB06–DB12.
Nodes: 1b (delete flow_derive.av) · 2 (in flight) · 3 (BLOCKED on owner mark-vs-override) · 4 · 5 · 6.

## Owner rules still in force
Lanes never idle; one task → report; ~10 min bound. Never `rm -rf`/`stash`/`--no-verify`; land only
via PR + queue; rebase onto origin/main only. Heavy runs on Sprites (all bound) else the Mac
`watch.sh` lock. Terse traffic; speak only for merges/drops/big decisions/blockers.

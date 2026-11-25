# LIVE HANDOVER — 2026-10-20 (DB lead, session 2)

This supersedes `HANDOVER_2026-10-20.md` §1 only. Read that file for doctrine, lanes'
history and open bugs.

## State

- **main** = `0f4e9317` (batch N).
- **Batch O = #1108**, head **`9e607df9`**, `hold` removed, **armed**. Re-gating.
  - Local worktree `/Users/tristan/projects/tristanMatthias/avra-gatei`, branch `batchO4`,
    Sprite `avra-flow-05-s1`.
  - `2e336cf1` = merge of N. Its two conflicts were exactly the owed three items:
    `Makefile` TOOL_WITNESSES (union), `family_reflect_test.av` (43 families: main's
    `CancelSummary`/`WriteSummary` + O's `FileRefs`), `tools/read_lists.ceiling`
    (dropped `CancelReach`/`Receivers`; only `Settled` stands).
  - `9de8b704` + `5ef5cf23` = the UI fixes for both red suites (`kept_state`/`prop_cell`;
    a head param the parent fills by name is TOLD, so never a cell). `94d9cef6` is the
    **reverted** `said_kind` attempt — `5ef5cf23` reverts it; do not re-derive it.
  - `9e607df9` = empty re-gate commit. `census-gate` is the only red and it is the stale
    baseline (main's published census is from `b2f3541f`); the body carries a
    `SPEED_ACCEPT:` line with the numbers and the reason. If it is still red, read
    `tools/census_ratchet.py`'s `judge` — a waiver alone must sit under `census.budget`
    (99683 / 129610) or the budget must move in the diff.
- **Batch P (next):** #1122 first; then #1089, #1070, #1083, #1129(+#1116), #1096,
  #1124, #1115, #1125, #1130, #1094, #1107, #1097, #1123, #1114, #1103, #1117, #1121,
  #1101, #1100, then the tools stack (#1065→#1109→#1110→#1111→#1119→#1120, #1112,
  #1113 needs `make bootstrap`, #1118, #1126–#1128). `ci-design` owns the stack's order.

## PR pile (owner asked for this explicitly)

144 open → **87**. Closed 51 proved landed (48 by branch ancestry inside a merged batch's
head via `refs/pull/<n>/head`, 18 by the patch reverse-applying to main; 15 proved twice)
and 6 whose own titles say `DO NOT MERGE` (the pre-DB-deletion branches A16 names).
Each closure carries its receipt as a comment; branches were left in place.
The old numbers are in `.lead/triage/` (`open.json`, `landed.json`, `classify.json`,
`res.json`) — `classify.json` has the reverse-apply verdict per PR.

## Lanes (respawned after a harness crash killed the first wave)

| lane | worktree | job |
|---|---|---|
| sched-orders2 | avra-sched-orders @8ebf3555 | DB 07e steps 2–3 + .57.298 |
| nodes-means2 | avra-body-exprs @7c8c2e07 | DB 07f `Decl.body_exprs` + the rule + #1121 |
| db-warm2 | avra-db-warm @87758eb2 | `cache-attacks` + `warm_edit.sh`, then its PR (unblocks db-gather) |
| errors-voices2 | avra-errors-voices (9 dirty) | DB 08a `Verdict` |
| store-trap2 | avra-store-trap | DB 09 fixture then delete, one line kind per commit |
| seed-run2 | avra-flat296 | .57.296 + receiver seal |
| ci-design2 | avra-ci-stack @47764a75 | the tools stack, rebased in order |
| nodes-fold2 | avra-db02-explain @154048b8 | `avra explain` round-trip, then #1097 |
| db-rows | new `avra-db-rows` | the 7+-field `row_ctor` |

**A lane that dies leaves its commits in its worktree.** Always `git log --oneline -3`
there before briefing a successor; do not let it redo committed work.

## Owner's question answered, 2026-10-20

**The 6-field limit on models is real, unsolved and in main**: `packages/std-db/src/db.av`
`row_ctor` writes one arm per arity 1–6 and its `rest ->` arm emits a CALL TO A FUNCTION
THAT DOES NOT EXIST (`a_model_with_more_than_six_fields_needs_a_wider_row_constructor()`),
so a 7-field `@model` fails to compile with a sentence as a function name. The fix is the
law CLAUDE.md already states: a record literal takes its fields as a run,
`${t} { ..${inits} }`, at any width. `db-rows` owns it; it should ride batch P.

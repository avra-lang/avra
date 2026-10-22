# DB/nodes lead handover — 2026-10-22

Written by the DB/nodes lead session `01a15807` at the end of its context.
Read with `CLAUDE.md`; this file is state, not doctrine.

## Where main is

`db2b815e` — **batch S-clean landed** (15 members). Before it: O `543526b6`,
P `b1e59ff3`, Q `846e8a84`, R `3896b7c1`, and `#1164` (jq in `packages.txt`).

## THE ONE THING NEXT

**Batch T (`#1162`, branch `batch-t` @ `0b31109a`) is a draft and is DIRTY** —
it needs a rebase onto `db2b815e`. The rebase stops on **two conflicts**:
`Makefile` and `tools/ci_invariants.py`, both from `#1165`
(`graph-substrate-fixes`) against S-clean's newer edits. I aborted rather than
resolve blind. Resolve those two, push, then **ready + arm it**.

T carries: the ~21 original members plus `#1173` (the silent-miscompile fix),
`#1161` (std-db 6-field cap dead), `#1163` (nodes 5.2 when_expr), `#1170`,
`#1172`, `#886`, `#1036`, `#1039`, `#1165`/`#1166`/`#1167`, and `#1175`
(DB 07e). `fmt --check` was 115/115 clean before the rebase.

**`#1173` matters most**: a file-level module of the root package never recorded
its dependency on the root's own record (`enclosings()` excluded the root
package's root `""`), so editing a type in that top-level file left a reader in
another directory with a stale object — it reads the wrong field and crashes or
prints garbage. One line plus `tools/file_module_attack.sh`, which fails 2 of 3
builds on main.

## Epic positions, verified

**DB** (design order `00→01→02,03,04→05→06→07→08,09→10→11`):
- 00, 01, 02, 04 **done** · 03a/03c **partial**
- **05 done** (05a `#1158`; 05b/05c `#582`)
- **06 done** (steps 1/4/5 + §6.8; `#1145` `#1146`)
- **07a/b/c/d/e done** — `#1175` landed 07e: `settle_holds` gone, three Cells
  and seven write sites gone, and a `read_with` list copy **per read per
  attempt** gone. 502 builds / 159 under a hold / **0 failed**, all eight
  attacks by name green, `avra ir` 233 programs byte-identical.
- **07f (`Analysis` dissolves) = `#1100`, inside T.**
- **07's GATE IS NOT MET**: target ≤60 ms unchanged / ≤300 ms one-body edit;
  measured **~250 ms** and **~2.2 s** (`load 988 · analyze 671 · lower 502 ·
  keep 181`, held 549/551, parse 0, discarded 0).
- 08 **partial** (`Linked` only) · 09 **unblocked, decided** · 10 **not
  started** · 11 **done** · 12 **partial** (`families.ceiling` = 42).

**Nodes** (`avra-8sb5.89`): steps 1, 2, 3, 4, 7 **done**; step 5 **~2/3**;
step 6 **partial**. Both structural asks that blocked step 5 are **built**:
`#1166` (`TypeRef` Record row — six builders → one, `builders.av` 85 → 43
lines, `differing=0` over 15 programs, memory peak identical) and `#1167`
(`@anchor` on a payload field — 1942+1206+36+109 diagnostic lines and 6169
`avra diagnostics` **byte-identical**, cost −0.6% noise). Both are in T.

## Decisions taken (do not re-ask the owner)

- **DB 09 = Option C**, recorded on `avra-8sb5.57.178`: `Settled` stays a
  **named saved answer** (`Answers<Settlement>` + `ran_lasting`, which already
  compiles) rather than becoming a `@query`. No `Db` owner slot. A `MemoStart`
  cycle face only if C fails.
- **A batch ceiling of SIX members, at most one touching the compiler's own
  source.** Census slack is 1.5%/counter and one such member spends 2–4%; each
  census run is ~5 min, and bisecting an 18-member red batch cost **12 runs**.
- **The `features-b-cold` speed row is a broken baseline, not a regression.**
  CI reads `216s → 435/466s` (+101/116%) while a quiet Sprite measures **+1.9%**
  across 12 bisect runs that could attribute it to **no member**, and *every*
  cold row in the same run was inflated (`core-warm +67%`, `diagnostics +36%`,
  `io +30%`, `ui-http +31%`, `assets +38%`). `tools/speed_note.sh`'s guard is
  `grew >= 30s` — an **absolute** floor that a 216s row clears with noise
  alone. `SPEED_ACCEPT` with this evidence is in the S-clean and U bodies.
  **Follow-up owed: judge a row against the run's own median inflation.**

## In flight when this was written

Four perf lanes chasing DB 07's gate (each owes a COUNT, three alternating
medians, and a correctness attack):
`perf-methods` (.57.192 — 994 method tables rebuilt per edit → `analyze`),
`perf-load` (DB 05c input manifest + reverse index → `load`),
`perf-floor` (attribute `inputs` 103–115 ms and `judge` 125–130 ms, then the
stat fast path → the 250 ms no-op), and `speed-row` (settle the baseline).

## Lane results not yet acted on

`needs-work` decided all 13: **6 landable** (`#1114` `b0e5d5d4`,
`#1106` `e72e3fb1` — **seed regenerated and seed-check green**,
`#964` `c78b9292`, `#982` `8bad66c5`, `#479` `8b542996`, `#1094` `ff107ae4`),
**3 closed** with carriers named (`#978`, `#1004`, `#1047`), **2 held with live
findings**, **2 still labelled** (`#1112` needs T first; `#1117` needs a
semantic rebase). The 6 landables were rebased onto `693638fc`, one batch
behind — `update-branch` them before adding to a batch.

**Two real defects found, both "deferred work discovered at the next compile"**
— they need an ENGINE decision, not a patch:
- **`#1064`**: annotation expansion files generated decls into shared
  name-index buckets that `Visible:<file>`/`References` had already read;
  `input_unread` keeps the old hash, so the next `set_input` sees a move and
  3 `Lifted` rows go stale. The law owed: **a compile must end as a fixed point
  of its own writes.**
- **`#737`**: `CACHE_ATTACKS=ot` still answers `discarded 5` where cold has
  `discarded 0` on main's own compiler.

`nodes-anchor` also corrected a census: *"39 span reads / 10 builders"* does
**not** reproduce — 66 reads across 31 fns, only **one** rule-shaped.

## Judged-dead, do not revive

`#1028` (`@codec` — Q's `#1150` restored it without the reader-cost box; its
whole diff is `@codec`, so there is nothing else to take) · `#1068` (already on
main whole) · `#1065` (subsumed by `#1109`) · `#917` (its `#877` wasm-exnref
half is carried by **nothing** — now ticket `avra-rc0w`, which says the work
must be redone on top of `#1094`'s `Cleanup` shape).

## Working rules that cost real time today

- **Never build on the Mac for a CI question.** Read the CI job log; a local
  run answers about a different machine.
- **`gh pr view --json statusCheckRollup` mixes runs.** A FAILURE can belong to
  an older cancelled run on the same branch — check the run id before believing
  it.
- **No Sprite carries a `.git`**, so `ci-invariants`' `fetch_compiler`
  self-test and `ui-browser` fail there by environment. Check by name whether a
  keeper needs git or a browser before reading its red as a code failure.
- **`sh tools/watch.sh`'s first argument is a cap in MB, not seconds.**
- **The pre-commit hook needs `build/avra` at the branch's merge-base**, and
  Sprite builds are Linux ELF. Every main move invalidates every lane's
  compiler; a clean-tree `make avra` at the merge-base, copied in, is the way.
- **`gh pr edit` fails on this token** (`read:project`); use `gh api PATCH`.

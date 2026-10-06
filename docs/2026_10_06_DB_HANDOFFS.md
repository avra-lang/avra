# Compiler DB — hand-offs

2026-10-06 · branch `db-design` · design: [`2026_10_06_COMPILER_DB.md`](2026_10_06_COMPILER_DB.md)
· evidence: [`2026_10_06_DB_INVENTORY.md`](2026_10_06_DB_INVENTORY.md)

Each hand-off is written to be executed cold by a fresh agent. Rules that apply to all:
work in a **new sibling worktree** from `origin/main` (`sh tools/work new <name>`), never
in the lane named below (read it, copy from it); heavy runs on a Sprite; land only with
`sh tools/work land` on the lead's go. Nothing here was built or run by the author.

**Legend:** KEEP = land (as is or nearly) · REWORK = redo on main using it as a reference ·
ABANDON = leave; the worktree can be retired.

---

## 0. Summary

| # | lane / worktree | verdict | maps to design | ticket |
|---|---|---|---|---|
| H1 | `avra-warm-memory` (active) | KEEP | L8, PR 12 note | avra-8sb5.78, .57.163, avra-8sb5.76 |
| H2 | `avra-keepers-green` @ `01c219c` (active) | KEEP now, dissolve at PR 3 | §8 "Layout" row | .57.165 |
| H3 | `avra-m3-redteam` @ `a644ba4` | REWORK — keep the 17 cases | PR 3 acceptance | .57.6 (closed) |
| H4 | `avra-sources-design` (doc) | KEEP, re-point §1 | L1, L3, §9 | sources campaign |
| H5 | `avra-q148-prototype` (uncommitted) | REWORK | PR 11 | .57.148 |
| H6 | `avra-n3-apply` @ `af411a2` | REWORK (model only) | PR 11 | .57.12.4 / .57.12.5 |
| H7 | `avra-docfact-side` (uncommitted test) | KEEP the test | PR 5 | .57.9.7 |
| H8 | `avra-mh-held` / `perf/mh-held` @ `4fef2a3` | REWORK — salvage the test fix | PR 6 | .57.101 |
| H9 | `avra-warm101-11` (uncommitted) | ABANDON code, keep the finding | §4.3 | .57.101.11 |
| H10 | `avra-perf-hold-keys` @ `9aabcb1` | ABANDON | L3 (the counter-example) | .57.101 |
| H11 | `avra-arm-rows` (+ `-nobump`, `-noloop`) | ABANDON, keep the negative result | §4.1 | .57.4.7 |
| H12 | `avra-wants-modules`, `avra-pipe-op` (active, DB-adjacent) | NOTE for their owners | L5, L7 | — |
| H13 | the stale `avra/` checkout's untracked docs | KEEP as history | §12 | — |
| H14 | legacy sessions (COMPILER DB DESIGN, PERF, …) | STOP instruction | — | avra-8sb5.57 |
| — | every other DB-named worktree (≈100) | ABANDON — landed or scratch | — | inventory §1 |

---

## H1 — `avra-warm-memory` · KEEP (active; do not disturb)

- **Where:** `../avra-warm-memory`, 7 wip commits on current main (`235673b` … `abf52f0`).
- **Done:** treats the >5 GB warm rebuild as a *lifetime* problem — several whole
  derivations stand side by side (held attempt, "whole" re-derivation, from-sources
  fallback, rule examples, nested suites, the evaluator's quarrel path). Adds one
  `Workspace.discarded()` verb, "one derivation alive at a time", `tools/memsites.py`.
- **Not done:** no memory numbers in the tree; it does not touch `Kernel.newly_read` itself.
- **Maps to:** L8 ("partly held is never worse than cold"). It is the *second* half of L8
  (one derivation alive). The *first* half — validate before deriving — arrives with PR 6.
- **Instruction to its agent:** land as planned. Add to the PR: (1) before/after peak for
  `.57.163`'s scenario (partly-held vs cold, same commit); (2) cross-link `.57.163`,
  avra-8sb5.76, avra-8sb5.78 — they are one defect. Do **not** change how deps are stored;
  that is PR 12 (packed int deps: 71 B → ~9 B per dep, MEASURED 363 MB / 5.1 M boxes).
- **Tests:** the `.57.163` scenario; `cache-attacks`.

## H2 — `avra-keepers-green` @ `01c219c` · KEEP now

- **Done:** "a kept settlement stands only under the layout it was laid out in" — adds an
  `l` line to `compiler/kept_settle.av` via `kept_layout` / `Decls.crossing_layout`. Fixes
  the `cache-attacks` failure "a compile-time value did not cross as `Line`".
- **Maps to:** this is the 7th hand-written line kind. Land it — green keepers come first.
  At PR 3 it becomes a read of a kept `Layout(type key)` answer and the line dies with the file.
- **Remains for its agent:** get `cache-attacks`, `codecs`, `fmt-lossless` green, then add
  `cache-attacks` and `codecs` to the keeper loop at `.github/workflows/checks.yml:110`
  (today: `fingerprints vocab families cited externs dogfooding-rules ui-host ui-host-test
  ui-board`). That is half of PR 1.

## H3 — `avra-m3-redteam` @ `a644ba4` · REWORK (keep the cases)

- **Where:** branch `redteam/m3-witness-attacks`; `tests/witness_attack_test.av` (283
  lines), `witness_attack_trap_test.av`; result `.rt/attack5.log:2043` "11/17 tests passed"
  (2026-09-28).
- **State:** written against `lane/m3-witness` @ `499df24`; that code was deleted by #104
  (`85f1046`), so the file cannot land.
- **Do:** port the 17 cases to PR 3's kept door as its acceptance suite. The seven failing
  classes and the design's answer are in the design §8 ("the seven witness defect
  classes"). First check which are already in main's `tests/attack_test.av` /
  `hold_refusal_test.av` (not verified).
- **Tests:** the ported file; `make cache-attacks`.

## H4 — `avra-sources-design` · KEEP the doc, re-point §1

- **Where:** `../avra-sources-design/docs/2026_10_05_BUILD_TIME_SOURCES.md` (1,249 lines, 6
  commits, not on main); reviews at `…/scratchpad/sources-review/REVIEW.md`, `REVIEW2.md`.
- **Do:** replace its §1 ("two doors") with a pointer to the design's L1 and L3; delete
  `RunKind`, `Part`, `keep(run, value, witness)`; D1–D13 are answered in the design §9.
  Its §4 (steps/actions), §7 (native tools), §9 (homes) stand as the consumer. Its build
  order becomes: design PR 2 (input door) → PR 3–5 (kept door) → sources slices.
- **Stale in it:** C.23 (stale embed) is fixed on main by #282; `avra dev` is already a
  one-shot child build (`dev.av:9`).
- **A defect it surfaced, unfiled:** `avra dev`'s watch set is `Workspace.build_inputs`
  (`dev.av:292`), which excludes embedded files (`modules.av:275-289`) — an embed edit
  moves the key but is likely not watched (READ(agent), not run). After PR 7 the watch set
  is the root record's reads.

## H5 — `avra-q148-prototype` · REWORK

- **Where:** uncommitted, 11 modified + 1 untracked, +422/−85; no evidence it compiled.
- **What:** typed `by it.mark.args[N]` in `collect` + `dense`. The *order* half landed as
  #140 (`0d423e4`). The *projection* half did not: grammar `fp2`/`fidx`, `ProjField.index`,
  `mark_arg_reg` in `lower.av`.
- **Do:** redo the projection on main's `order_path` reader; add the field-type check the
  prototype skipped. Needed by PR 11 (a typed catalog of queries from their marks; deletes
  `family_word`, `compiler/workspace.av:523`).
- **Ladder:** grammar change to a form the compiler's own source uses → save
  `build/avra.pre`, bridge.

## H6 — `avra-n3-apply` @ `af411a2` · REWORK (the model, not the code)

- **What:** `DbKind` as a `collect enum` through dual `@family @db_kind` marks in
  `compiler/kinds/kinds.av`. It orders `by it.name`, which moves every ordinal → superseded
  by #192's `dense` rank.
- **Do:** nothing until PR 5. PR 5 deletes `DbRow`'s durable variants and `DbKind` outright
  (records are named by query path), so "derive `DbKind`" (`.57.12.5`) is **obsolete**, and
  the enum-variant splice it was blocked on is no longer needed for this.

## H7 — `avra-docfact-side` · KEEP the test

- **Where:** uncommitted on `3f073ba`: `features/tests/doc_fact_test.av` (+71) and
  `features/tests/doc_fact_kernel_witness/` (no `.expected`; never confirmed green).
- **Do:** copy both into a fresh worktree, write the `.expected` from the law ("an edit to
  decl A's doc reruns only the query that read A's slot"), run both engines. Land alone.
- **Related, open:** `.57.9.7`'s five walls (a `@side` relation unreachable from a Db-only
  `@query`; a dense `@local @key` making the derive generate nothing, silently; `put_in`
  at an out-of-order id breaking Rows' sequential-id invariant; `AnnotationFact`'s `Span?`
  not stable-carried; a stable `@key` generating nothing with no diagnostic). The silent
  derive is a defect to fix **before** PR 5; file it on its own.

## H8 — `avra-mh-held` · REWORK (salvage)

- **Where:** branch `perf/mh-held` @ `4fef2a3`; the worktree is stuck mid-rebase — do not
  touch it; `git show 4fef2a3` from any tree.
- **What:** `--time`'s "read:" list always names the entry file, so four hold assertions
  measured nothing. Corrected finding: an importer keys on a package's whole exported
  surface, one digest per package.
- **Do:** re-apply the test fix on main. Under PR 6 the assertion becomes "the record's
  reads list names `Record(M)`, not files", read from `avra explain --json`.

## H9 — `avra-warm101-11` · ABANDON the code

- **What:** a hand `ReachWitness { seen: [module, digest], deps: [dep, files] }` in
  `record.av`. Witness taken 70/70; won ~3 % (3.90 s → 3.78 s; load 2,231 → 1,667 ms)
  because validating whole-record digests cost what the walk saved. 0 of 70 `view_parts`
  calls had a settled kernel cell.
- **Why abandon:** a fourth hand witness. **Keep the finding:** a saved answer is validated
  from its record alone, before the kernel has anything — the design's §4.5.

## H10 — `avra-perf-hold-keys` · ABANDON (by recorded decision)

Three attempts at a hand `view_print` key: unsound (23 cache-attack failures vs base 2);
sound but slower (load 1,019 → 3,824 ms); per-build memo (15 failures: records mutate
mid-build). The best evidence for L3's "no hand-written checks".

## H11 — `avra-arm-rows` · ABANDON

`settled_analyses` (let a late write bump the revision, re-ask to a fixpoint): "gen 2 over
the cli traps in pass 2". Main refuses late writes instead (#72). **Keep the result:** an
input enters at admission, never inside a query — the design's §4.1 keeps that law (an
input's first read sets no revision; a *changed* input is a new process).

## H12 — active, DB-adjacent (a note for their owners, no action by the DB lane)

- `avra-wants-modules`: adds `facts.hosted` to `verify_held.av`. Check the hold record wire
  carries it; if a held file's answer depends on it and the wire does not, that is a stale
  answer.
- `avra-pipe-op`: `|>` adds a parse mark that restamps a fingerprint. Run `make
  fingerprints`; CLAUDE.md "a hash that forgets a payload".

## H13 — the stale `avra/` checkout

`avra/` is 153 commits behind with 156 dirty paths. It held the only copy of
`docs/2026_09_26_COMPILER_DB_TOWNHALL.md`; this branch commits it unchanged as history.
Also read there and **not** copied: `HANDOFF_COMPILER_DB_2026_10_01.md`, `MY_PLAN.md`,
`docs/2026_09_24_ORM.md`, `codex-session-*.md`. Recommend the owner decide whether
`2026_09_24_ORM.md` is committed (the ORM campaign cites it).

## H14 — legacy sessions

The peer sessions that worked this epic (COMPILER DB DESIGN, PERF, ORM, IDIOMS, ERRORS,
warm4, families2, …) hold lanes listed above. **Message to relay to each, verbatim:**

> The compiler DB design is final: `docs/2026_10_06_COMPILER_DB.md` on branch `db-design`.
> Stop work on any witness, hold-key, kept-line or family-mark change that is not in its
> §7.2 PR list. If you have uncommitted work, commit it on your own branch as `wip:` and
> report the branch and sha; do not land, rebase or clean. Your lane's disposition is in
> `docs/2026_10_06_DB_HANDOFFS.md`.

---

## Tickets — proposed dispositions (nothing was edited)

### Under avra-8sb5.57

| ticket | today | proposed | why |
|---|---|---|---|
| .57 (epic) | open | keep; re-point its design link from the townhall to the new doc | the townhall was in no tree |
| .57.101.12 "the M3 layer itself" | open | **re-scope → design PR 3** | reads written at settle, at the kept grain only (L4); as written it contradicts §6.5a |
| .57.101.11 kept view on witness deps | open, parked | **close as superseded by PR 6** | its premise (M3 exists) is false; `Record(module)` on L3 is the kept view |
| .57.101 speed P0 | in progress | keep; add the §6.3 budgets as its gate | — |
| .57.12 / .57.12.5 `DbKind` half of N3 | in progress / open | **close .12.5 as obsolete at PR 5** | `DbKind` is deleted, not derived |
| .57.148 families as `@query` | closed with the fork open | **reopen as PR 11**, pending owner decision 4 | — |
| .57.9 / .57.9.7 doc facts as relations | in progress / parked | keep; split out "a `@key` derive that generates nothing says nothing" as a P1 defect | blocks PR 5 |
| .57.163 partly-held memory | open | **merge with avra-8sb5.76 and .78**; owner = `avra-warm-memory` | one defect |
| .57.164 stale embed | open | **close** — fixed by #282 (`04a6a89`); note the bespoke path dies at PR 2 | — |
| .57.165 red keepers | open | keep; owner = `avra-keepers-green`; add "into CI" | PR 1 |
| .57.4.6 deadline (closed) | latent | **new ticket**: "pay before arming `@kept`" → PR 5 | recorded deadline, unpaid |
| .57.6 M3 (closed "done") | closed | add a note: product deleted by #104 | the close reason misleads |
| .57.141 kept settlement (marked deferred) | deferred | correct: built (#119); dies at PR 3 | — |
| .57.18 S3 per-decl durable reuse | closed unbuilt | leave closed | `Shape(decl)` + `Lifted` (PR 4) covers the valuable case |

### Outside the epic

| ticket | proposed | design step |
|---|---|---|
| avra-8sb5.68, .69 (wasm-opt, linker, env in no key) | fold into PR 7 | `Tool` / `Env` inputs |
| avra-8sb5.1.28.8, .1.35, .11.236 (suite key omits package C) | merge into one; PR 7 | `Proved(suite)` reads |
| avra-8sb5.46 (30-bit `fp_mix`), avra-8sb5.79 (linear fold) | raise priority; before PR 6 | L7: kept digests are 256-bit content digests; the *in-process* cutoff hash still needs fixing |
| avra-8sb5.9.2 (`parsed` cutoff vs spans) | close at PR 4 | §4.6 |
| avra-knya, avra-zsc2, avra-8sb5.31, avra-8sb5.25.20, avra-8sb5.70 (stale answers) | re-test under `AVRA_DB_CHECK` after PR 6; close what no longer reproduces | L3, L10 |
| avra-8sb5.36 (closed on detection) | add note: root fix is L5 | — |
| avra-8sb5.37, .40.17, .11.300 (cache root) | PR 9 decides the layout | §4.8 |
| avra-8sb5.11.120 (`let _ = store.keep(…)` ×391), .11.249/.250 (hand-cleared memo cells), .9.14 (passes as a uniform trait) | close as each PR deletes the sites | §7.1 |
| avra-8sb5.65.3.2.1 (planner narrows comprehension heads only) | keep; needed by PR 10 | `R.all(db).filter(…)` must reach the index |
| avra-8sb5.44 (ORM), .44.6.* | unblock after PR 10 | `Decl.by_marks(db, "model")` |
| avra-8sb5.72, avra-9vy7 (missing tests) | keep | — |

### New tickets the design needs (to be created by the lead)

| title | PR |
|---|---|
| `make inputs`: a ratchet on world reads outside `Host` (baseline ~177) | 1 |
| The input door: `query/input.av`, `Host`'s nine reads, a C digest row | 2 |
| The kept door + `Settled` on it; post records / reads / walk measurements | 3 |
| `AVRA_DB_CHECK`: recompute every kept answer that stood, trap on disagreement | 3 |
| `Lifted` kept, span-relative | 4 |
| Four host reads inside `Parsed`/`Plain` frames record no dep (`voices.av:680,701,713`, `workspace.av:1315`) | 2 |
| `avra dev` does not watch embedded files | 7 |
| `fmt --check`: the "hit without a parse" comment is false (`canon_key` parses) | 5 |
| Stale doc comments: `db.av:36-38`, `db.av:220-234`, `memo.av:28-30`, `workspace.av:814-819` | 5 |
| `avra explain` | 8 |
| Deps as packed ints | 12 |

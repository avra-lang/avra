# DB landing plan — the integration branches off PRE-#705 / PRE-flip bases

Written 2026-10-14 by lane `lower-cold`. A PLAN, no code. Source docs: `docs/2026_10_06_COMPILER_DB.md`
(§8 order: `00→01→02,03,04→05→06→07→08,09→10→11`), `.lead/DB_AUDIT.md`, `.lead/HANDOVER_2026-10-13.md` §4,
`.lead/lanes/{db-old-prs,db06,items-kept,edit-path,store-tw,lower-cold}.md`.

## 0. The landability fact that governs everything

`origin/main` at plan time = `98a3c688`. **All five branches are PRE-#705 and PRE-#710.** Four sit on
`de4b544d` (batch #9), 28–34 commits ahead of their merge-base; `db-slice` sits on `b0d98c49`, the exact
commit before the #710 `within → Result<T, TimedOut>` flip. #705 (the links bit) landed `6420a379`,
#710 landed `707ab829`. **No branch can PR to main directly** — a landable PR is a FRESH branch off
`origin/main` (`git switch -c land/<slice> origin/main`) with the commits CHERRY-PICKED in design order,
then re-verified. `db-registrations`' "fast-forward-only, never rebase" applies to the SHARED branch, not
to the landing branch.

## 1. Design-slice vocabulary (as this campaign uses it)

- **DB 03a — names**: every family key becomes a durable `decl_wire`/spelling, no process-local int.
- **DB 06 — the saved-answer rule**: a record is value + `(name, digest)` read list, valid iff every digest
  matches. Steps 1 (#618) and 4 (#642) are on main. **Step 5 = the producer/code-hash stamp** (a different
  compiler over the same store hits 0; `.lead/lanes/db06.md:27`, PR #653/#670) — **no branch below carries
  it**; it is the `db06` lane's, and DB 06 is not complete without it.
- **DB 07 — per-declaration answers; the hold deleted**: `a` rows/buckets named parts of their producer's
  answer · `b` `Resolved`/`Folded` per declaration · `c` the whole-program families split — Receivers(16),
  References(19), Failures(20), ReadReach(30), plus `CancelReach` and `MethodDiags` · `d` by-name loading
  replacing load/admit · `e` hold/record-lines/memo maps deleted · `f` `Analysis` dissolves. "Dispatch" = the
  four exhaustive `Family` matches a new family must pay (`reads_rows_whole`, `dispatch_verified`,
  `cache_walk.keyed_by`, `family_code_hash`).
- **DB 08 roots** (`Verdict`/`Linked`/`Proved`), **DB 09 `Settled`/`Lifted` saved**, **DB 10 plugin crossing**,
  **DB 11 shared store**: no branch carries these; DB 09's `Lifted` VALUE save owes the **`LiftResult` codec**
  (`.lead/lanes/db-old-prs.md:163`), which none builds.

## 2. Per-branch inventory → next slice → blocker

### db-registrations — `origin/db-registrations` @ `9de94c27` (base `de4b544d`, +28)
Topics: every family NAMED — `52da5184` Sig/Marks/Methods/Parsed/Items/Visible/Resolved/Named, `1734dd3f`
Sig/ConstTyped, `45ca24cc` Analysis/Names/Namespace/References/Settled, `629e0076` Settled, `8731e40b`
Settled stands on names · the **saved-answer meter**: `299f1b99` `AVRA_LEAVES` + `tools/digest_diff.py`,
`tools/leaves.sh` + `leaves.baseline` (ADDED here; `make leaves` does not exist on main) · position-free
digests: `1c9b9b77` arena id folds by the durable name, `07d280bf` Typed content digest, `7a3074cc` refused
sig named · `4491600a`…`1e47ca1f` `rel_loc` (a kept place relative to its declaration) · `5db788cd`+`16fc495c`
Receivers→`Writes` per-decl (DB 07c) · `3ba9448d` LoweredSaid verify · `22b9355b` `explain --why` discarded cost.
→ **NEXT SLICE: S1 = DB 03a + DB 06 registration (the naming foundation).** This is the layer DB 06 step 5
and DB 07 both sit on; every other branch stacks on it.
→ Blocker: base pre-#705/#710 (cherry-pick over the flip; `explain.av`'s `--why` change collides with #747,
now on main — drop or re-apply). `LiftResult` codec NOT needed here (these answers are digest-only under L4).
Pre-existing base reds to carry or fix: `decl_grain_test`/`family_reflect_test` (4, the `Writes` family),
`turn-memory-attack` ceiling, 2 idiom sites.

### db-slice — `origin/db-slice` @ `86df6e81` (base `b0d98c49` = PRE-flip, +77)
Topics: `e91c1cca`+`d7767c6d` **FileSaid** (a file's kept answer as a saved query with recorded reads) ·
`c28c97bb`+`1c8ca17b`+`dbfd3f09` **suspect set / store body-v4 reverse index / input manifest** ·
`ec276593` **on-demand hold** (a file whose rows still stand is never loaded) · `86df6e81` **MethodDiags**
(a file's clashes read its own methods' tables) · `67e062d0`…`fa3fc23b` the `fn nobody spells` view narrowing.
→ **NEXT SLICES: S4a DB 07c MethodDiags split (`86df6e81`, smallest), S4b DB 05c store reverse index +
FileSaid + suspect set, S4c DB 07d on-demand hold (`ec276593`).**
→ Blocker: (a) `b0d98c49` is the pre-flip commit — the on-demand hold edits `derive.av`/`record.av`/
`kept_settle.av` and must be rebased over #710; (b) `ec276593` cannot pay until the remaining whole-program
families are split (Receivers/References/Settled/CancelReach — items-kept report 34 §6), else `holding()`
still pulls every module; (c) FileSaid rides the store body-v4 reverse index (a DB 05c increment); (d) 21
pre-existing idiom sites, `fn-add-attack` 2 red, 4 std-avrac tests. **Do NOT PR db-slice whole.**

### refs-per-name — `origin/refs-per-name` @ `f6a2c3e3` (base `9de94c27`, +3 over S1)
Topics: `5f49d9a4` `ReadFound`/`Consumed` per-declaration families (the References split) · `5e8209fa` a
program entry reads its own file's parse · `f6a2c3e3` `Lowered` moved off `reads_rows_whole`, recording the
declaration's own `Named` bucket instead of `Items(file)`.
→ **NEXT SLICE: S3 = DB 07c References split.** Receipt: BODY re-lower 11,525→57, SIG 247→4, mismatched 0.
→ Blocker (EXACT, and it is not the base): **UNSOUND as it stands.** On the fine read, 3 units mismatch
(`commands.root_program`, `commands.wasm_runner`, `commands.verify_held`): `lifted_symbol` (`features/decls.av`)
and `spelled_static` (`features/values.av`) name generated symbols by the FILE-ABSOLUTE `e.index`
(`$l<N>`/`$lit<N>`), so a same-file signature edit above a lambda-bearing unit shifts the symbol with no
durable `Named` bucket to catch it — the coarse `Items(file)` edge caught it by accident. Needs the
**durable-symbol slice first**: make those two declaration-relative or content-addressed (as `site_of`
already is); it renames generated symbols and touches `.ll` goldens + `lower_test`'s `$l<N>` assertions.
Plus the S1 suite and 24 pre-existing WIP idiom sites.

### lower-cold-parsecut — `origin/lower-cold-parsecut` @ `d6246ceb` (base `9de94c27`, +6 over S1)
Topics: `15e10c0f` typing reads its own slice of the file's names (also in S1) · `78398e43`/`36ed70ea`/
`9de94c27` Namespace + name-slice durable digests · `fd1df2ba`+`ce417e73` a body stands on its own syntax,
`Family.Placed` (steps 1–4; `syntax(d)`+`placed(d)`), `e199f2e1` Names decl-grain leak closed · `bd5e990d`
**`Lifted` NAMED** (the intermediate gets an `AnswerRef` + durable `lift_hash`; clears the 47 unnamed reads) ·
`1ace44aa` Writes fixpoint split then `d6246ceb` **REVERT** (a wash; broke decl-grain).
→ **NEXT SLICE: S5 = DB 07b (`Resolved`/`Folded` per declaration; `Placed` + names-slice) + a DB 09
precursor (Lifted/Settled named).**
→ Blocker: (a) base pre-flip; (b) `Family.Placed` is a hand `@family` that raises `tools/families.ceiling`
37→39 (a ratchet loosening; doctrine says a ceiling may only fall — convert to `@query` or get a lead
ruling); (c) bd5e990d's Lifted-naming route contradicts the lead's earlier "only LiftLowered is a saved
answer" constraint BY DESIGN — a ruling is owed; (d) 3 residual noted-leaf `Lifted` movers; (e) the Writes
split is dropped, don't re-propose it. **The DB 09 `Lifted` VALUE save still owes the `LiftResult` codec.**

### cancel-bits — `origin/cancel-bits` @ `0ef03292` (base `9de94c27`, +1 over S1)
Topic: `0ef03292` **`CancelBits(DeclId)`** — the `CancelReach` fixpoint still computes whole, then settles
each fn's own bits; readers stand on their fn alone (DB 07c CancelReach split). Attack
`tools/cancel_bits_attack.sh` (10 steps, 0 failed); leaves: CancelReach blocked → 0.
→ **NEXT SLICE: S2 = DB 07c CancelReach split (the SMALLEST, forward-compatible).**
→ Blocker: base lacks #705, so `CancelReach` there is two-field (`parks`/`spins`; no `links`). The code never
names the fields (shared `cancel_word`/`cancels_so_far`), so it is forward-compatible — but the links half
and its attack can only be exercised AFTER rebasing onto post-#705 main. `families.ceiling` 37→39 (same
ratchet ruling as S5). Pre-existing base reds: `family_reflect_test`, `turn-memory-attack` ceiling, 2 idioms.

## 3. Ordered landing plan

Order follows §8 (03 naming before 06, 06 before 07) and the dependency graph above. One landing at a time.

**S1 — DB 03a + DB 06 registration (db-registrations foundation).** FIRST; everything stacks on it.
- PR: fresh branch off `origin/main`; cherry-pick `52da5184 … 9de94c27`. Files: `compiler/leaves.av`,
  `workspace.av`, `workspace_analysis.av`, `interface.av`, `rel_loc.av`, `families/families.av`,
  `receivers.av`, `dep_audit.av`, `derive.av`, `core/fp.av`, `core/fingerprint.av`, `core/{nodes,side_table,
  types,ir,debug}.av`, `features/decls.av`, `std-relation/src/{db.av,engine/kernel.av}`; tools `leaves.sh`,
  `leaves.baseline`, `digest_diff.py`, `writes_attack.sh`; Makefile `leaves:` + `writes_attack` in
  `cache-attacks`; the added tests. Drop `explain.av --why` if #747 conflicts.
- Receipts: `make leaves` (`no blocked share rose`; baseline only falls) · `tools/digest_diff.py` two-process
  index-shift (`namespace 83/84, LiftLowered 975/975, Names 16291/16291, Settled 489/489`) · `make
  cache-attacks` (13 scripts, incl. `writes_attack`, 0 failed) · `make codecs` · `make families-left` (≤37) ·
  `fmt --check`. Design acceptance: a declaration inserted above changes no other declaration's bytes.
- A16: this is the design's own path; it must NOT add a `key_parts`/`kept_settle` spelling or a second
  validity check beside the digest rule.

**S2 — DB 07c CancelReach split (`0ef03292`).** Smallest, forward-compatible. Cherry-pick onto post-#705
main, resolve `families.ceiling` (≤37, convert to `@query` if needed). Receipts: `make leaves` (CancelReach
0) · `tools/cancel_bits_attack.sh` · `make cache-attacks` · std-avrac suite green. Design acceptance: the #705
links bit rides along unmodified.

**S3 — the durable-symbol slice (new work, no branch yet), THEN DB 07c References split (`refs-per-name`).**
Make `lifted_symbol`/`spelled_static` declaration-relative or content-addressed; regenerate `.ll` goldens.
Then cherry-pick `5f49d9a4`, `5e8209fa`, `f6a2c3e3`. Receipts: `AVRA_DB_VERIFY=lowered` cli table (BODY 57,
SIG ≤4, **mismatched 0** — today SIG is mismatched 3) · `tools/readfound_attack.sh` · `make cache-attacks` ·
idiom baseline adopted or fixed. Design acceptance: one body edit re-lowers ~57 units, not 11,525.

**S4 — DB 07c MethodDiags (`86df6e81`), then DB 05c store reverse index + FileSaid + suspect set, then
DB 07d on-demand hold (`ec276593`).** Extract from db-slice topic-by-topic onto fresh branches off main;
never PR the integration branch whole. Receipts: `make leaves` · `make cache-attacks` · `files loaded N of
511` + `load ms` (the on-demand receipt) · `make db-corpus`. Design acceptance (DB 07): `warm_edit.sh`
unchanged ≤60 ms and one body edit ≤300 ms; `.57.163` repro peaks ≤ cold.

**S5 — DB 07b (Resolved/Folded per declaration; `Placed`, names slice) then the DB 09 `Lifted`/`Settled`
naming.** Cherry-pick `15e10c0f`…`d6246ceb` (skip the reverted `1ace44aa`). Receipts: `make leaves` (Typed
unnamed → 0, 47 Lifted cleared) · `tools/digest_diff.py` (`Placed 16387/16387`, `Lifted 326/326`) ·
`placed_family_test`/`lifted_naming_test` · `make cache-attacks`. Design acceptance (DB 07b): a body edit
moves no `Resolved`/`Namespace`/`Names`; leftover `Parsed` movers are the next cut.

**Not carried by any branch (owed before S5's DB 09 half):** DB 06 step 5 (producer stamp, `db06` lane),
DB 08 roots (`Verdict`/`Linked`/`Proved`), the **`LiftResult` codec** (DB 03c; the DB 09 value save),
DB 10 plugin crossing, DB 11 shared store.

## 4. A16 mechanisms these slices must NOT resurrect

- **Formats**: `KeyParts`/`stands_in` (1), module record lines/`written_from` (2), `kept_settle.av`'s
  `u c m f b e` line kinds (3), `program_key` (4), `DocFacts`/`FileWitness`/`still_valid` (6),
  `proved_key`/`clean_key`/`canon_key` (7–9), and the five unvalidated rows (`closure`, `embeds`, `homes`,
  `parts`, `seen`). A new kept answer records its `(name, digest)` reads — never a new `*_stands` spelling.
- **Grain**: do not re-add a coarse `Items(file)`/`reads_rows_whole` edge to make a fine read sound — that is
  the accident `f6a2c3e3` exists to remove (fix the symbol durability instead). Do not re-add `key_parts.runs`
  as a read.
- **Hold/attempts**: `derive.av`'s `Turn.Again`/`Attempt`/`settle_holds` and `record.av`'s hand `KeyParts`
  validity are DB 07e's to DELETE. `ec276593` (on-demand `holding()`) is DB 07d, the design's replacement for
  `load`/`admit` — it is design-aligned, but the landing must not add a SECOND validity check beside L3, and
  must not extend the record-line format to carry reads.
- **Families**: `Family.Placed`/`Writes`/`CancelBits` are hand `@family` markers; `tools/families.ceiling`
  must only FALL. Any slice that raises it (S5/S2 hold it at 39) must convert to `@query` or get a lead
  ruling. `make families-left` is the receipt.

## 5. What a reviewer must reject

(a) A PR targeting main from a PRE-#705 branch without a fresh rebase; (b) `db-slice` whole; (c)
refs-per-name with `mismatched ≠ 0`; (d) `Lifted` named while claiming its value is saved (needs the
`LiftResult` codec); (e) `families.ceiling` raised without a ruling; (f) a new hand validity format.
Every slice names its blocker; none is landable today without its receipt table.

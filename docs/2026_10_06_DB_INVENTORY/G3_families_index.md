# G3 — families / N3 / collect / index / reach worktrees: what is NOT on origin/main

Reference main: `avra-db-design` @ `05fe643` (2026-10-06 commit date, "ui: a component's body is its view… (#284)").
Method per worktree: `git cherry -v origin/main HEAD` (`-` = patch-id on main, `+` = not), then subject grep on
`origin/main`, then key-symbol grep in `avra-db-design`. All commands read-only. Nothing built or run.
Every count below is MEASURED from the named command/file unless marked ESTIMATED / NOT VERIFIED.

## 0. Headline

- 35 worktrees. **33 hold nothing unlanded that matters**: their commits are on main by patch-id or by squash
  (subject + symbol verified), or they are detached bases with a throwaway script.
- **Only three hold DB-relevant work not on main:**
  1. `avra-q148-prototype` (uncommitted, 12 paths) — a typed `it.mark.args[N]` **projection** into a collect's
     record field (`mark_arg_reg`). Main landed the ORDER half (#140) but not the projection half.
  2. `avra-n3-apply` `af411a2` — `DbKind` as a `collect enum` (dual `@family @db_kind` markers). Main did `Family`
     only; `DbKind` + `DbKind.tag()` are still hand-kept (`avra-db-design:packages/std-avrac/src/compiler/db.av:155-185`).
  3. `avra-m3-redteam` `a644ba4` — 17 red-team cases against durable witnesses, 6 failing by design. The machinery
     they attacked was deleted (#104), but the ATTACK LIST is a spec for any saved-answer rule.
- The townhall doc `docs/2026_09_26_COMPILER_DB_TOWNHALL.md` is **in none of these worktrees and not in
  avra-db-design**; it exists only in the stale `avra` checkout (2973 lines, staged-not-committed there).

## 0.1 What N3 is (townhall, `avra:docs/2026_09_26_COMPILER_DB_TOWNHALL.md`)

- `:2864` "**N3. `collect enum`** (COLLECTIONS step 4, unbuilt). Its variants are keyed by STABLE NAME, never by a
  dense ordinal, because a new member would shift every persisted ordinal after it … `collect enum Family =
  @relation or @query in closure` synthesizes the family enum, and matches over it stay exhaustive. This deletes
  `Family` (22 arms) and `DbKind` (21 arms), plus `rows_derive.av`'s standing note".
- `:1304` risk row: "persisted rows must key by the member's stable NAME, never its position, and a test must add a
  member in the middle."
- `:2955` "N3 lands with M1, deleting the family lists as they move."
- So the worktree names decode as: **n3-apply** = apply `collect enum` to Family/DbKind (ticket avra-8sb5.57.12.4);
  **n3-ordinal / n3-family** = make `Family.ordinal` the declaration's place (delete the hand `ordinal()` match);
  **families2/2b/2c/2d, flip175, seed175, seed-162, collect148, db159-collect, family-order-keeper** = ticket
  avra-8sb5.57.148 ("M5 proper: query families as @query declarations") waves.

## 0.2 What main actually holds today (the baseline these worktrees fed)

| Fact | Evidence |
|---|---|
| `Family` IS a collect enum, 32 markers, ordered by rank | `avra-db-design:packages/std-avrac/src/compiler/families/families.av:149` `export collect enum Family = @family in self by it.mark.args[0] dense` |
| The mark is a NO-OP carrying strings | `…/families/family_derive.av:20` `export fn family(_t: Named, _rank: int, _key: string, _answer: string) {}` |
| The mark is explicitly NOT the query door | `…/family_derive.av:9-14` "THE LAYER SPLIT: this mark is COMPILER-INTERNAL. It is NOT @std.relation's user-facing `@query fn q(db, …)` … the families answer dense structural values … carry no `Db` seat … so they cannot wear that form." |
| Registration walks the enum, one closure dispatching on `f` | `…/compiler/workspace.av:760-761` `for f in Family.all() { if ws.db.family((arg: int) -> ws.refetched(f, arg)) != f.ordinal { ws.defect(…) }` |
| `family_word` is still a hand match | `…/compiler/workspace.av:523` `fn family_word(f: Family) -> string { match f { .Source -> "Source", …` |
| `DbKind` still hand-written, 24 variants + `tag()` | `…/compiler/db.av:155-160` "`DbRow`'s own tags — hand-written, not derived" |
| Ordinal is the DURABLE key (the opposite of the townhall's N3 rule) | `avra-db-design:tools/families.py:4-6` "A `Family` ordinal is a DURABLE address: kernel rows, kept caches and witnesses are keyed by `ordinal`" |
| Real `@query` uses in the compiler | 2, both `…/compiler/doc_rows.av:13,20` (`grep -rn "@query\b"` minus tests/comments) |
| Declared indexes on Decl | `…/features/decl_rows.av:44-64` `@index name`, `@index word`, `@index marks: List<string>`, `@local @index key/home/external` |

Design consequence (my reading, flagged): the goal "a derived fact is a typed `@query` over `@relation` rows" is
NOT what `.148` delivered. `.148` delivered name/ordinal reflection of 32 memo spaces; the key and answer types are
unchecked strings (no reader: `grep "args\[1\]\|args\[2\]"` over `std-avrac/src` minus tests finds no family
consumer). The fork is recorded verbatim in ticket avra-8sb5.57.148 comment 2026-10-01 21:29: "THE FORK (needs the
lead) … the townhall's fn form and .148's declaration-reflection need are two different layers … If the lead wants
the townhall fn form instead, the dense answers must first become stably encodable — a much larger rewrite."

---

## 1. Families wave (ticket avra-8sb5.57.148, .157, .12.4, .159, .161, .162) — ALL LANDED

| Worktree | Branch | HEAD (date) subject | origin/main..HEAD | On main as | Dirty | Verdict |
|---|---|---|---|---|---|---|
| avra-collect148 | collect161-witness | `697673d` (10-01) test(collect): a family mark's rank arg orders a collect enum, not source order | 1 (`-`) | `c0e6265` #157 | none | ABANDON — landed |
| avra-db159-collect | db159-collect | `c79c7d6` (10-01) feat(compiler): collect's `by` compares typed literals, and `dense` orders by data | 1 (`-`) | `0d423e4` #140 | none | ABANDON — landed |
| avra-seed-162 | seed-162 | `a4bcf9a` (10-01) chore(seed): refresh … #140's collect order forms | 1 (`-`) | `1caf557` #159 | none | ABANDON — landed |
| avra-family-order-keeper | family-order-keeper | `e810cc2` (10-01) ci(tools): the Family ordinal order is append-only | 1 (`-`) | `2cb30a5` #127 | none | ABANDON — landed |
| avra-families2 | families2 | `9320642` (10-01) feat(db): the DeclId-keyed family markers (wave 2b) | 1 (`-`) | `1c9f9aa` #162 | 2 M (below) | ABANDON — dirty diff superseded |
| avra-families2b | families2b | `a539d85` (10-01) feat(db): the non-dense family markers complete the set (wave 2c) | 1 (`-`) | `2b051df` #166 | none | ABANDON — landed |
| avra-families2c | families2c | `583f93c` (10-01) feat(db): the family collect orders by rank, append-stable | 1 (`-`) | `0e67451` #171 | none | ABANDON — landed |
| avra-families2d | families2d | `1ea19b2` (10-01) feat(enums): E.all — every variant of a payload-free enum | 1 (`-`) | `ae63926` #175 | none | ABANDON — landed |
| avra-seed175 | seed175 | `2646d1e` (10-01) chore(seed): refresh over E.all | 1 (`-`) | `7993ef6` #185 | none | ABANDON — landed |
| avra-flip175 | flip175 | `da685a5` (10-01) feat(db): Family is the collected enum (avra-8sb5.57.12.4) | 1 (`-`) | `07e0d70` #192 | none | ABANDON — landed |

**avra-families2 uncommitted** (`families.av` +52/-… , `tests/family_reflect_test.av`): adds markers Sig(6), Methods(7),
Receivers(16), References(19), Failures(20), HeldSig(21), Raised(22), MethodDiags(23), LiftLowered(24), Names(26),
Marks(27) and re-pins `FamilyProbe` ordinals for 28 names under `by it.name`. Every one of those markers is on main
with the same rank/key/answer (`avra-db-design:…/families/families.av`, e.g. `@family(22, "DeclId", "List<TypeId>") type Raised = {}`),
and main went past it (ranks 28-31: Admitted, Named, ReadReach, DeclReads; `FamilyProbe` replaced by `Family`). Nothing to keep.

What the wave was attempting: turn the kernel's hand `Family` enum + `family_at/family_count/ordinal()` into
declarations a `collect enum` gathers. How far: complete for `Family` (enum + registration loop via `Family.all()`).
Not done by the wave: `family_word` (still a 32-arm hand match), `DbKind`, and any typing of key/answer.

Docs: `avra-flip175` and `avra-seed175` hold `docs/2026_10_02_PROVIDE_ENV.md`, absent from avra-db-design — tracked
at their base commit, later removed on main; not DB-relevant (env provision). No other doc differs on these branches.

## 2. N3 worktrees

### avra-n3-apply — `lane/n3-apply`, HEAD `af411a2` (2026-09-29) "feat(N3): synthesize Family and DbKind via collect enum"
- `origin/main..HEAD`: 1 commit, `+` by patch-id; subject not on main (`git log origin/main --grep="synthesize Family and DbKind"` → empty). Clean tree.
- Ticket: avra-8sb5.57.12.4 ("Apply to Family / DbKind (after M1)", CLOSED 2026-10-02), parent avra-8sb5.57.12 (N3, IN_PROGRESS).
- Attempt (from the diff, 16 files, +314/-217): new `compiler/kinds/kinds.av` (196 lines) with two no-op marks
  `fn family(_what: Named) {}` / `fn db_kind(_what: Named) {}` and one marker fn per concept; "Sixteen concepts wear
  both" marks (`@family @db_kind fn Source() {}` …); `collect enum … in self by it.name` mints both enums; deletes the
  hand `ordinal(f: Family)` match and the hand `DbKind` enum body; rewrites `rows_derive.av`'s "Kind stays hand-written" note.
- How far: complete and reported green by its own message ("std-avrac (313 cases) and std-relation (110 cases) both
  green … make cache-attacks 0 failed") — NOT VERIFIED here. Never landed: superseded by the rank-ordered design.
- Why it was superseded (and correctly): it orders `by it.name`, so every family ordinal MOVES ("Family.Raised's
  ordinal moved from 22 to 16", commit body) — the exact hazard the townhall's N3 risk row names. Main's version
  uses `by it.mark.args[0] dense` + `tools/families.order`.
- Not on main and still valuable:
  1. **`DbKind` from declarations.** Main still hand-keeps it. The dual-mark observation is the valuable part:
     Family ∩ DbKind = 17 names on main today (Source Parsed Lowered Manifest Plain Items Namespace Visible Resolved
     Typed ConstTyped Folded Analysis Lifted Expanded Settled Sig — read off `db.av:160-185` vs `families.av`);
     DbKind-only = Decl Warn Scan Canon Licenses Findings Answer. Two vocabularies name one set of saved answers.
     For "one saved-answer rule" these should be ONE declaration with a `persisted`/codec column, not two enums.
  2. A recorded reason the families could not wear `@query`: "`@query`'s wrapper binds to `@std/relation`'s own
     `Db`/`Memo<V>` types by name (query.av's `is_db`), which the compiler's own dense, Kernel-backed families do
     not use (that bridge is M5, unbuilt)". `is_db` is still there: `avra-db-design:packages/std-relation/src/query.av:91`.
  3. A probe result: "a `quote {}` template's free names resolve in the derive's OWN file, not the splice target's,
     confirmed by a real refusal" (commit body) — matters for any plugin-declared `@query`.
- Verdict: **REWORK** — the code is stale (name order, pre-#192 layout); the DbKind half and the dual-mark model are the design input.

### avra-n3-ordinal — `n3-ordinal`, HEAD `6332a17` (2026-09-30) "refactor(N3): Family's ordinal is its place in the declaration"
- 1 commit, `-` (on main as `53110b0` #103). Clean. **ABANDON — landed.**

### avra-n3-family — `lane/n3-family`, HEAD `4262aa6` (2026-09-30) same subject as n3-ordinal
- 6 ahead: `e1062a4`, `aa03890` (`+`, on main by subject as `6d2d631`, `c3275b7`), `db81313`, `64c0e09` (`-`, main
  `f8c60de`, `bf4e652`), `4262aa6` (`+`, same change as `6332a17` → #103), plus a merge. Clean.
- Same work as n3-ordinal stacked on the m5-decl commits. **ABANDON — landed.**

## 3. M3 (durable witness / hold) worktrees — ticket avra-8sb5.57.55

| Worktree | Branch | HEAD | Unlanded by patch-id | Status |
|---|---|---|---|---|
| avra-m3-red | detached | `2bfdc10` (10-01) compiler(hold): a gone file's record keys on bytes; the flattened witness and its switch are deleted | 1 `+` | On main as `85f1046` #104 (subject match; 28 files, +487/-2299) |
| avra-m3-close | m3-close | `35dbf0f` (10-01) test(fixtures): name ordinals by their place in Family | 4 `+` (`4f69fe4`, `d849579`, `2703e4e`, `35dbf0f`) | All folded into #104: the squash touches the same files (`decl_rows_test.av`, `method_rows_test.av`, `written_where_test.av`, `stable_names_test.av` +118, `workspace_fixtures.av`, `tools/cache_attacks.sh`) |
| avra-m3-redteam | redteam/m3-witness-attacks | `a644ba4` (09-28) test(compiler/witness): red-team cases for durable witnesses | 1 `+`, not on main | see below |

- **avra-m3-red dirty** (2 files, +4): `derive.av` adds `for path in held_paths(self) { let _ = self.parsed(self.file_id(path)) }`
  after `settle_holds`; `cache_attacks.sh` adds two `ee:` check lines. Experiment residue around held files' rule
  findings; the real fix is on main as `2f7f94c` #61. **ABANDON.**
- **avra-m3-close untracked** `tools/m3probe/` (6 shell scripts: `m3.sh`, `m3b.sh`, `compare.sh`, `receipt.sh`,
  `drop_witness_tests.sh`, `resolve_deleted.sh`; 2026-10-01). Scripts only, no result files. **ABANDON.**
- **avra-m3-redteam `a644ba4`** — `tests/witness_attack_test.av` (283 lines) + `witness_attack_trap_test.av` (10).
  Commit body: "NOT FOR LANDING AS-IS: 6 of 17 cases fail by design … Written against lane/m3-witness at 499df24".
  MEASURED result, `avra-m3-redteam/.rt/attack5.log:2043` "11/17 tests passed" (log dated 2026-09-28 01:34; command
  NOT RECORDED in the log head — the commit says "run with that lane's own compiler"). Failing cases (log lines 2022-2042):
  | Case | Asserted correct behaviour | Class of defect |
  |---|---|---|
  | ATK1 | trivia edit (leading comment) → report is fresh, positions moved | cutoff hash narrower than the value (spans) |
  | ATK2a | new sibling file defines a previously-undefined name → verdict fresh | NEGATIVE dependency (absence) not recorded |
  | ATK6 | two files witnessed in one process record the same number of Methods edges | edge recorded only for the first asker (memo hit records nothing) |
  | c-Parsed (1) | a file that never existed answers unresolved, not a hash | phantom key hashes |
  | c-Parsed (2) | a removed file's hash differs from an emptied file's | empty-vs-absent collision |
  | d | an entry stamped with another record-shape version is refused | schema version never compared |
  | trap file | Manifest ordinal past the packages answers unresolved, never traps | out-of-range key traps |
  Passing: ATK2b (second impl in an earlier file), ATK3 (callee `List<int>`→`List<string>`), ATK9 (callee decl deleted), c-Sig, c-Methods.
  The witness code under test is gone (`85f1046` deletes `witness.av` −667 and all `witness_*_test.av`), so the file
  cannot land. The seven defect CLASSES are independent of that implementation and are exactly what a single
  saved-answer rule must answer by construction. Main keeps `tests/attack_test.av`, `hold_refusal_test.av`,
  `witnesses_test.av` — whether they cover these seven is NOT VERIFIED.
  **Verdict: REWORK** — port the case list as the acceptance suite for the new saved-answer rule; discard the code.

## 4. M5 (Decl as a relation, declared indexes) worktrees

| Worktree | Branch | HEAD | Unlanded | Status |
|---|---|---|---|---|
| avra-m5s2-cand | detached | `64c0e09` (09-30) perf(m5-decl): a declaration read is one cell and one index | 2 `+` by patch-id (`e1062a4`, `aa03890`) | both on main by subject: `6d2d631`, `c3275b7`; other two `-` (`f8c60de`, `bf4e652`). **ABANDON — landed** |
| avra-m5-s2 | lane/m5-decl | `b49cf16` (09-30) Merge 'lane/db-impl-reach' | 16 ahead; `+`: `7754472`, `4fef2a3`, `e1062a4`, `aa03890`, `dc0507f`, `0f3706e` | `7754472` (delete flattened witness) superseded by #104; `4fef2a3` (cache_attacks MHC) in `tools/cache_attacks.sh` rewrite of #104 (NOT VERIFIED line-by-line); `dc0507f`+`0f3706e` = `8a85aec` #54. **ABANDON — landed** |
| avra-s3-index | lane/m5-index | `319584f` (09-30) Merge 'fix/warm-recheck' | 24 ahead; extra `+`: `1c7ba69`, `97a9dc2`; `-`: `ee21b13`, `cfec46b` | `ee21b13` = main `33dcdb5`; `cfec46b` = `02048b3`; `97a9dc2` = `2f7f94c` #61; `1c7ba69` → symbols on main (§5). **ABANDON — landed** |
| avra-m5b-facts | lane/m5b-facts | `6371f8c` (09-30) perf(db): name_slice_fp folds a declaration's columns in one pass | 1 `+` | on main as `0531e8b` #40. **ABANDON — landed** |
| avra-m5b-index | lane/m5b-index | `ba4a682` (09-30) | 0 ahead | untracked `tools/m5b-cost.sh` (perf-stat one cold check). **ABANDON** |
| avra-m5b-base | detached | `441d58e` (09-30) | 0 ahead | untracked `tools/m5b-cost.sh` (variant). **ABANDON** |
| avra-m5-s2-census-base | detached | `5c08d15` (09-29) | 0 ahead | untracked `tools/census_direct.sh` (identical to avra-m5-s2's). **ABANDON** |

- What M5 was: townhall `:2636` "M5 | `Decls` tables -> relations; indexes declared". What `ee21b13` did (commit
  body, verified on main): "Decl carries @index word …, @index marks (every @name it wears, a multi-valued index
  over a List field) and @local @index key. The hand CollectIndex and the keys map are deleted: gathered/
  gathered_by_mark read a bucket unrecorded and each member through decl". That is N2 + "collect lowers to an index
  lookup" — on main (`decl_rows.av:54-58`).
- `avra-m5-s2` untracked: `.avra-cache.aside-1790752775/`, `.avra-cache.aside-1790755217/` (parked caches), `tools/census_direct.sh`. No notes, no result files.
- No measurement artifacts in any of these trees (scripts print to `/tmp`, wiped).

## 5. Reach / verdict / warm-edit worktrees — tickets avra-8sb5.57.124, .119, .126, .101

| Worktree | Branch | HEAD | Unlanded by patch-id | Status |
|---|---|---|---|---|
| avra-importer-reach | importer-reach-pins | `f719dd8` (09-30) test(cache): an impl's reach is pinned across packages… | 0 (`-`) | main `eb4dfff` #93. **ABANDON — landed** |
| avra-reach-chain | perf/reach-chain | `9bd94de` (09-30) tools(land): the timed warm edit is anchored… | 3 `+`: `1c7ba69`, `5b9d1f8`, `9bd94de` | see below. **ABANDON — landed/retired** |
| avra-verdict124 | perf/verdict124 | `602c153` (09-30) perf: reuse only a kept structural refusal… | 6 `+` | landed evolved as `68d33f2` #119 → `compiler/kept_settle.av`. **ABANDON — landed** |
| avra-measure124 | detached | `146bdee` (09-30) wip: measure split | 3 `+` | `311bcaf` = reach-chain change; 2 wip script commits. **ABANDON** |
| avra-verify101 | detached | `5a885d8` (09-30) wip: measurement script | 1 `+` | `warm_split.sh` only (cold / no-edit / two named one-line edits, prints wall + `held N/M`). No results. **ABANDON** |

- `1c7ba69` symbols on main: `avra-db-design:…/compiler/workspace_analysis.av:648` `fn reach_probe(`, `…/compiler/lower/lower.av:607` `fn settlement_until(`,
  `…/compiler/derive.av:106` `"discarded ${self.turned}"`. `5b9d1f8` on main: `workspace_analysis.av:84` `fn entry_wanted(`.
  `9bd94de` edits `tools/land.sh`, which no longer exists on main (retired).
- Measurement quoted from `avra-reach-chain@1c7ba69` commit body (2026-09-30, "Measured on a Sprite, warm check-cli
  after the fmt.av:275 edit"): "held 393/401 (main 98), discarded 0, wall 32 s (69.8 s with the double derivation).
  The rest is 'lower' (~28 s, the entry's const re-settling every warm check)". Command not spelled in the commit; ESTIMATED to be `build/avra check --time packages/cli`
  (that is what `avra-verify101:warm_split.sh` runs).
- Design lesson worth carrying (from `avra-verdict124`): `c0ba862` "a Reach verdict is keyed on its witness chain
  alone" was REVERTED by `0430041`: "Chain-only reads leave the probe's asked bodies unread, so a const that
  re-settles turns the derivation (discarded 1, 69 s warm wall)." i.e. **a saved answer must record every read the
  computation made, not the minimal proof of its verdict** — else the derivation restarts. Main's doc of the
  resulting rule: `avra-db-design:…/compiler/kept_settle.av:5-13` ("A settlement's VALUE is a function of the bodies
  its run ENTERED and of the consts it READ; its STRUCTURAL verdict is a function of each reached unit's CALL SHAPE").
  `kept_settle.av` is a SECOND, bespoke saved-answer rule beside the hold path — a target for "one saved-answer rule".

## 6. q148 / typed-collect prototype

### avra-q148-prototype — `q148-prototype`, HEAD `51d36f4` (2026-10-01) "feat(compiler): Expr and Stmt as @relation @arena — checked, not rewired (#118)"
- `origin/main..HEAD`: 0 commits (HEAD is a main commit). **All work is uncommitted**: 11 modified + 1 untracked, `git diff --stat` = 11 files, +422/-85.
  - M `compiler/format/source_text.av` (34), `compiler/lower/lower.av` (103), `core/exact_derive.av`, `core/identity_derive.av`, `core/shape_derive.av` (1 each),
    `core/nodes.av` (53), `core/parts.av` (10), `features/collects/builders.av` (138), `check.av` (143), `mod.av` (15), `tests/collects_test.av` (8)
  - ?? `features/collects/order.av`
- Ticket: avra-8sb5.57.148 / .159 (the "q148" question: can a collect order by a typed annotation arg, append-stable).
- Attempt: an independent first build of `by it.mark.args[N]` typed compare + `dense`, i.e. the feature that landed as
  #140 from `avra-db159-collect`. Shapes it chose:
  - `core/nodes.av`: `export type OrderKey = { path: List<Plain>, index: int? }`, `export type OrderSpec = { keys: List<OrderKey>, dense: bool }`,
    `Collect.order: OrderSpec` (main kept `order: List<Plain>` and decodes one text via `order_path`, `avra-db-design:…/collects/order.av:15-22`).
  - `order.av`: `matched_mark(decls, d, word) -> Annotation?` reading RAW syntax args (`ExprId`s) + `enum SortVal { SInt(n: int), SStr(s: string) }`.
  - 5 diagnostics (`collect.order_whole_mark`, `order_mixed`, `dense_not_int`, `dense_duplicate`, `dense_gap`) vs main's 4 (`order_key`, `order_uncomparable`, `order_mixed`, `dense`).
  - Own fingerprint tags `fp(138, …)` / `fp(139, …)` for order key/spec, and `projfield_fp` gains `f.index ?? -1`.
- How far: grammar, builders, check, lower, formatter, derives and one test edit all written; NO evidence it built
  or passed (no log, no commit). NOT VERIFIED as compiling.
- **Not on main and still valuable — the PROJECTION half.** The prototype widens the projection grammar, not just `by`:
  - prototype `mod.av`: `fn:NAME ":" iw:NAME ( "." fp:NAME ( "." fp2:NAME )? ( "[" fidx:NUMBER "]" )? )?`
  - main `avra-db-design:…/collects/mod.av:38`: `fn:NAME ":" iw:NAME ( "." fp:NAME )?` — one segment, no index.
  - prototype `core/nodes.av`: `export type ProjField = { field: Plain, path: List<Plain>, index: int? }` (main `nodes.av:203`: no `index`).
  - prototype `lower.av`: `fn mark_arg_reg(mut lo: LowerCx, a: Analysis, kind: CollectKind, d: Decl, index: int) -> Reg { … match v { .SInt(n) -> lo.const_int(n), .SStr(s) -> lo.const_str(s) } }`
    — "One arg, typed by its own literal kind". Main can project only the WHOLE mark with args as text
    (`avra-db-design:…/compiler/lower/lower.av:1248` `if part == "args" { return string_list_box(lo, [a.text for a in m.args]) }`).
  - Why it matters for the design: with it, the family catalog is a typed TABLE, not just an enum —
    `collect families: List<FamilyRow> = @family in self as FamilyRow { name: it.name, rank: it.mark.args[0], key: it.mark.args[1], answer: it.mark.args[2] } by it.mark.args[0] dense`.
    That deletes main's hand `family_word` (workspace.av:523) and gives `explain db` / `cache why` / a plugin a
    queryable registry of every query (name, key type, answer type) — "everything queryable as relations", applied to
    the query vocabulary itself. It is the smallest missing language piece between today's `@family` and a real catalog.
  - Its own comment admits the gap a rework must close: "typed by its own literal kind — never the field's declared
    type, which this door has no part in checking" → the projected arg's type must be checked against the record field.
- Verdict: **REWORK** — order half is superseded by #140 (drop it, and drop `OrderSpec`); re-do the `it.mark.args[N]`
  projection on top of main's `order_path`/`sort_value` reader (one reader for both seats, as its own header argues:
  "a word added to the vocabulary reaches both through `matched_mark`").

## 7. Remaining worktrees (not DB/query-layer, or bare bases)

| Worktree | Branch | HEAD | Unlanded | DB-relevant? | Verdict |
|---|---|---|---|---|---|
| avra-consume74 | perf/consume74 | `06522bd` (09-30) fix(control): a bytes literal runs no children | 3 `+` | No (memory-pass consuming inference, ticket .57.74). All three squashed into `bfde4c0` #70 | ABANDON — landed |
| avra-consumed-ir-of | consumed-ir-of | `cc75716` (09-30) fix(compiler): ensure_consumed stays armed past disarm | 0 (`-`) | marginal (workspace disarm) — main `e2793f2` #78 | ABANDON — landed |
| avra-db160-cellget-rule | db160-cellget-rule | `72df24a` (10-01) idiom(compiler.cell_get_copy) (avra-8sb5.57.160) | 0 (`-`) | rule on main `993c2e9` #150; branch touched `DOGFOODING.md` (landed with it) | ABANDON — landed |
| avra-h2-laws-index | h2-laws-index | `f625b24` (10-01) docs(http): … framing laws' H2 section (avra-8sb5.1.31.8) | 0 (`-`) | No — HTTP docs "index", not a DB index; main `078e39c` #141; touched `docs/2026_09_29_HTTP_ROADMAP.md` | ABANDON — landed |
| avra-sign-order-base | detached | `9140cf2` (09-28) chore(seed) | 0 ahead | No. Dirty: `packages/cli/src/commands/ir.av` (+37, an `AVRA_IR_LLVM=1` debug path that emits `.dbg.ll`); untracked program test `features/maps/tests/nullable_value_get/` | ABANDON — debug residue |
| avra-mainbc | detached | `bc2d64a` (09-30) chore(seed) | 0 ahead | No. Untracked `tools/.ab.sh` (two `make avra` gens + cold/warm `avra test packages/cli`, greps "defect") | ABANDON |

## 8. Docs check (docs/*.md and root *.md vs avra-db-design)

| Finding | Evidence |
|---|---|
| No worktree in this slice has an untracked or branch-modified DB doc | loop over all 35: `git diff --name-only origin/main...HEAD -- 'docs/*.md' '*.md'` returns only `docs/2026_09_29_HTTP_ROADMAP.md` (h2-laws-index, landed) and `DOGFOODING.md` (db160, landed) |
| Present in worktree, absent from main | `docs/2026_10_02_PROVIDE_ENV.md` in avra-flip175, avra-seed175 only (tracked at their base; not DB) |
| Townhall doc | absent from every worktree here AND from avra-db-design; only `avra/docs/2026_09_26_COMPILER_DB_TOWNHALL.md` (2973 lines). The compiler's own source cites it (`tools/families.py`, tickets) — a dangling citation on main |
| DB docs main does have | `docs/2026_09_21_COMPILER.md`, `2026_09_22_COLLECTIONS.md`, `2026_09_24_DB_REDESIGN.md`, `2026_09_30_COLLECTIONS.md` |

Older bases naturally differ from main in many docs (staleness, not work); not enumerated.

## 9. Same-commit groups (treated once)

- `e1062a4 aa03890 db81313 64c0e09` (m5-decl) appear in avra-m5s2-cand, avra-m5-s2, avra-s3-index, avra-n3-family.
- `1c7ba69` (reach probe) appears in avra-reach-chain, avra-verdict124, avra-s3-index; `311bcaf` in avra-measure124 is the same change re-committed.
- `4262aa6` (n3-family) ≡ `6332a17` (n3-ordinal) ≡ main `53110b0`.
- `2bfdc10` (m3-red) ≡ `4f69fe4` (m3-close) ≡ main `85f1046`.
- `7754472 4fef2a3 dc0507f 0f3706e` appear in both avra-m5-s2 and avra-s3-index.
- `tools/census_direct.sh` identical in avra-m5-s2 and avra-m5-s2-census-base.

## 10. Ranked: most valuable unlanded pieces

1. **Typed `it.mark.args[N]` projection in `collect`** — `avra-q148-prototype` (uncommitted; `collects/mod.av` grammar `fp2`/`fidx`,
   `core/nodes.av` `ProjField.index`, `lower.av` `mark_arg_reg`). Turns the `@family` markers into a typed, queryable
   catalog of every query (name/rank/key/answer) and deletes `family_word`. REWORK onto main's `order_path` reader; add the field-type check it skipped.
2. **The witness red-team case list** — `avra-m3-redteam@a644ba4` + `.rt/attack5.log` ("11/17 tests passed"). Seven defect
   classes (trivia/span cutoff, negative dependency, edge-recorded-once, phantom key, empty-vs-absent, schema version,
   out-of-range key trap). Use as the acceptance suite for the one saved-answer rule. REWORK (code is dead; cases are not).
3. **`DbKind` from declarations, and the Family∩DbKind dual-mark model** — `avra-n3-apply@af411a2` `compiler/kinds/kinds.av`.
   Main still hand-keeps `DbKind` + `tag()`; 17 names are shared between the two enums. Design input for "one declaration
   says: this is a query, and this is how its answer is saved". REWORK (name-ordered ordinals must not be reused).
4. **The recorded fork** (not code): ticket avra-8sb5.57.148 comment 2026-10-01 21:29 + `family_derive.av:9-14` on main —
   `@family` is deliberately NOT `@query`; key/answer are unchecked strings. Closing this fork IS the "one query door" decision.
5. **Divergence to settle** (not code): townhall N3 says persisted rows key by stable NAME (`:2864`, `:1304`); main keys by
   ordinal and guards with an append-only keeper (`tools/families.py:4-6`). A plugin-declared `@query` cannot take a rank in
   a compiler-owned dense 0..N space, so the ordinal key blocks "declared by a feature or a plugin".
6. **Lesson from the reverted chain-key** — `avra-verdict124@0430041`: record every read, not the minimal proof, or the
   derivation turns (69 s vs 32 s warm, Sprite, 2026-09-30). Already embodied in `kept_settle.av`, which is itself a second saved-answer rule to fold in.

Everything else in this slice: ABANDON (landed or throwaway). Worktrees safe to retire once the owner agrees:
all except avra-q148-prototype, avra-n3-apply, avra-m3-redteam.

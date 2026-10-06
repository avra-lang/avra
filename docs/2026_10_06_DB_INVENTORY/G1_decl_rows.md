# G1 — decl-rows / arm / decl-* worktree slice: what is NOT on origin/main

Reference: `avra-db-design` @ origin/main `05fe643` (2026-10-05). All 29 worktrees exist. Nothing was built or run; every
"compiles?" answer is from commit messages/notes only (NOT VERIFIED by execution).

## 0. Headline

**No committed DB-layer code in this slice is missing from origin/main.** Every branch commit is either patch-identical to a
squash on main (whole-branch `git diff <merge-base> HEAD | git patch-id --stable` equals the squash's), or was superseded/reverted.
What is NOT on main is: one uncommitted test witness (`avra-docfact-side`), bisect/debug scratch, and design findings recorded in
commit bodies and ticket `avra-8sb5.57.9.7`.

MEASURED whole-branch patch-id equality (source: `git diff $(merge-base) HEAD | git patch-id --stable` vs `git diff SQ^ SQ | …`):

| worktree | branch patch-id | main squash | squash patch-id | equal |
|---|---|---|---|---|
| avra-arm47 (14 commits) | 5935181b8262 | 51bfc7d (#72) | 5935181b8262 | YES (27 files, +508/-80 both) |
| avra-decl-replace (5) | db28f8d42a31 | d4a9796 (#101) | db28f8d42a31 | YES (23 files, +802/-304) |
| avra-decl-unadmit (2) | fce4bdd4439b | a932b0a (#198) | fce4bdd4439b | YES (4 files, +78/-2) |
| avra-db-125 (4) | 61837a18d2df | 8a85aec (#54) | 61837a18d2df | YES (7 files, +300/-30) |
| avra-decls-fence (1+merge) | ae0f506be875 | 9cee431 (#38) | ae0f506be875 | YES |
| avra-db-119 (1) | 67f9c8a74606 | 8a85aec (#54) | 61837a18d2df | prefix of db-125 (first commit, same subject) |
| avra-arm-rows (24) | ea3480a7e1d1 | 51bfc7d (#72) | 5935181b8262 | NO — earlier attempt, superseded (see §2) |

Single-commit branches whose `git cherry origin/main HEAD` line is `-` (patch on main): decl-ids-side → acf083c (#99);
decl-owner-column → cd3df92 (#102); decl-rows-grain → a6f9072 (#173); typed-decl-grain → 46d8154 (#114);
ast-relations-s1 → fe658af (#89); derived-merge's 0435601 → 7c6127f.

---

## 1. The #72 lineage — "the compiler's relation Db records through the kernel" (avra-8sb5.57.4.7)

Seven worktrees are the same work at different points; treated once.

| worktree | branch | HEAD | date | ahead/behind | relation to arm47 |
|---|---|---|---|---|---|
| avra-arm47 | arm-decl-rows-gh | e9946b1 | 2026-10-01 14:11 | 14 / 122 | THE final branch = #72 exactly |
| avra-arm-decl-rows-gh | fix-embed-fns-test | 51fc38c | 2026-10-01 | 10 / 198 | first 10 of the 14 (older base 5a4c3cf, different shas, same subjects) |
| avra-arm47-dbg | detached | 9da77ea | 2026-10-01 | 5 / 198 | first 5 |
| avra-arm47-fold | arm47-fold | 8d1149b | 2026-10-01 | 3 / 198 | first 3 |
| avra-bisA, bisB, bisC, bisD | detached | bda20d4 (all four identical sha) | 2026-09-30 | 1 / 216 | first commit only, base d0f2432 |
| avra-bisE | detached | f4b6246 | 2026-09-30 | 1 / 198 | first commit only, base 5a4c3cf |

`git log --oneline origin/main..HEAD` of avra-arm47 (all `+` by per-commit patch-id, because main squashed them):
```
e9946b1 fix(hold): every held declaration is minted at hold-settle, before any query
aa70568 test(relation): every Hooks literal carries the new moved field
42f3259 fix(relation): late_check numbers each index list apart, not across their join
c3d4318 fix(relation): SideRows registers through the Db, not the hooks cell
d34fa1b fix(test): embed's refusal tests need @std/meta actually vendored
bb9fda1 fix(embed): whether a file is source is its shape, never whether it was embedded
f4f5168 fix(embed): source is source-shaped and never an embed's data
7e998af fix(hold): a whole-program walk reads source, never an embed's data
04a94bc fix(embed): a settled const's embed reads its file by identity, data marked at admit
9fce99f fix(admit): a read file reaches the components its directory declares
99dd6a4 fix(embed): a file is data only when an embed named it
dc25391 fix(admit): admit lists a module's files uncached, so the reading query records its edge
cbfad1d fix(compiler): embed()'s file is admitted at parse, its path refused unless written
97a4736 feat(db): the compiler's relation Db records through the kernel (avra-8sb5.57.4.7)
```
On main: YES, as one squash `51bfc7d 2026-10-01 feat(db): the compiler's relation Db records through the kernel (avra-8sb5.57.4.7) (#72)`.
`git diff 51bfc7d HEAD -- packages runtime tools Makefile` in avra-arm47 shows only `compiler/families/families.av` and
`family_reflect_test.av` (2 files) — main-side drift between the two bases, not branch work. Key symbols present in avra-db-design:
`decls.av:707 moved: (family: int, cell: int, is_late: bool) -> moved_in(kernel, stamps, family, cell, is_late)`,
`std-relation/src/rows.av:380 fn late_check(db: Db, relation: string, id: int, keys: List<List<IndexKey>>, now: int)`,
`compiler/modules.av:78 fn met_files(m: ModulePath)`, `compiler/interface.av:474 fn read_here(path: string)`,
`compiler/tests/late_mint_settles_test.av` exists.

WHAT IT ATTEMPTED (from the diff stat of 51bfc7d): arm `std-relation`'s `Db` hooks (`db.av` +108, `rows.av` +56) from the
`Decls`' own kernel so every relation read is a kernel edge and a write after a read ("late write") is heard; then a run of
fixes so nothing mints a File/Module row inside a query (admit before query; embed files admitted at parse; held declarations
minted at hold-settle).

Uncommitted (all scratch, bisect of "which late mint breaks gen-2"):

| tree | change | meaning |
|---|---|---|
| bisA | `whole.av`: `- self.admit_module(from, self.module_path_of(p.source.file))` | does removing own-module admit clear the trap |
| bisB | `whole.av`: `- if scope != null { self.decls.admit_scope(scope!, f) }` | same, for a `collect` scope |
| bisC | `derive.av`: `- let _ = self.file_id(path)` in the held loop | same, for a held file's row mint |
| bisD | `runtime/avra_runtime.c`: `if (getenv("AVRA_TRAP_BT")) { … backtrace_symbols_fd(bt, n, 2); }` + `tools/.bt.sh` | a trap backtrace env flag |
| bisE | `decls_mint.av`: `qtrace("Q\tmint\tfile\t${path}\treader=${self.record_kernel.reader()}\topen=${self.record_kernel.open_top()}\n")`; `kernel.av`: `fn open_top() -> string` ; `tools/.held.sh` (a 3-package held-chain repro) | names which open query a late File mint happens under |
| arm47-dbg | untracked `compiler/tests/zzdbg/` (extern-call probe), `tools/.d.sh` | debug |

HOW FAR: landed (#72). Ticket avra-8sb5.57.4.7.

NOT ON MAIN AND VALUABLE: only two debug instruments, neither on main (MEASURED: `grep -rn AVRA_TRAP_BT runtime` and
`grep -rn "fn open_top" packages/std-avrac/src/query` in avra-db-design both return nothing).
(a) bisE's "mint under which open query" trace line is exactly the audit a one-input-door design needs ("a row minted while a
query is open = an unrecorded input"). (b) `tools/.held.sh`'s held-chain fixture (app → @acme/dep → @acme/deeper, edit entry, rebuild).

VERDICT: **ABANDON** all seven trees (work is #72). Lift bisE's 2-hunk trace only if the design wants a permanent late-mint audit.

---

## 2. avra-arm-rows (lane/arm-decl-rows) + avra-arm-nobump + avra-arm-noloop — the first arming attempt

| tree | branch | HEAD | date | ahead/behind |
|---|---|---|---|---|
| avra-arm-rows | lane/arm-decl-rows | 71f402b | 2026-09-30 18:49 | 24 / 242 |
| avra-arm-nobump | scratch/arm-nobump | 6e1b3c6 | 2026-09-30 01:01 | 3 / 506 (= arm-rows' first 2 commits + a merge) |
| avra-arm-noloop | scratch/arm-noloop | 6e1b3c6 | same sha | same |

arm-rows `origin/main..HEAD` (non-merge): 6e751e3 wip arm Db through kernel; 6e1b3c6 wip settle loop and pins; aed9889 wip
red-green verify mark, late writes at the pass boundary; 535866b wip mint every used module at admit, a late write is refused;
9244bfe; e4b1bd6 style; 6fd4f4e arm from the Decls' own kernel; 540d1a6 collect scope + held import's record module minted
before any query; dfc116e a module walk reads only the files the program met; 84bd4d5 + d5ff2b6 (its revert); 71f402b every Db
owner spells how it takes a late write; plus 4 unrelated commits merged in from main-side batches (42cb36a `-` on main;
0dfea9f/539846d/87e27cb docs(collections) → on main as 5725537 (#36); c0203b7 land chore).

On main under another name: yes — #72 is this work redone on a fresh base (same file footprint: decls.av, kernel.av, db.av,
rows.av, whole.av, derive.av, interface.av, modules.av, workspace.av, parts.av, late_mint_settles_test.av).
What did NOT carry over, by design:
- `settled_analyses` (6e1b3c6): "Every open file's analysis, asked again until no late input moved: a late write … bumps the
  revision, so a pass that saw one re-asks". Not in avra-db-design (grep `fn settled_analyses` → none). Replaced by
  "mint before any query; a late write is refused".
- aed9889 body: "Not landable: gen 2 over the cli traps in pass 2 (side table `bindings` read past its range) after a late
  Module mint re-runs analysis."
- 535866b body: "Unverified: the load never fell under the machine's cap before the cut."
- 84bd4d5 `Hooks.moved` defaulting to refuse — reverted in d5ff2b6; main spells `moved:` at every owner (decls.av:707).

Uncommitted: arm-nobump `decls.av` `- if late { kernel.bump() }` / `+ let _ = late`; arm-noloop `whole.av` removes the
re-ask (`- if self.db.revision() == before { return out }  - self.settled_analyses()`); both + `tools/.bis.sh` (gen1/gen2 survive?).
arm-rows: untracked `tools/.all.sh` (two-gen build + suites driver).

HOW FAR: arm-rows reached 71f402b unlanded, then was restarted as arm-decl-rows-gh → #72.

VALUABLE, NOT ON MAIN (as knowledge, not code): the **negative result** — "tolerate a late write by bumping the revision and
re-asking until fixpoint" was built, trapped gen-2, and was dropped for "every input is admitted before any query reads the
relation". That is direct evidence for the "one input door" rule: inputs enter at admit, never inside a query.

VERDICT: **ABANDON** (superseded by #72); cite aed9889/535866b bodies in the design as the reason late writes are refused.

---

## 3. Branches that are exactly a main squash — ABANDON (tree can go)

| worktree | branch | HEAD (date) | commits not in main by sha | on main as | tickets | uncommitted |
|---|---|---|---|---|---|---|
| avra-decl-replace | decl-replace | 8c6b8bd (10-01) | 5979131 replace rows in one step; fbd4e73 bucket reads no row copied; 98b4d00 externs one bucket; 1e35f95 layout; 8c6b8bd witness | d4a9796 (#101), whole-branch patch-id equal | none named | none |
| avra-decl-replace-red | detached acf083c | = main #99, 0 ahead | — | — | — | untracked drafts of #101: `readmit_test.av` (older shape of main's file; main's differs by `admit_again` signature + `ws_rows`), `swept_heard/` (differs from main's), `tools/branch.patch` (56 KB, 12 files = the #101 diff as a patch), `tools/census_pair.sh`, `tools/census_sites.sh` |
| avra-decl-unadmit | decl-unadmit | 413b0af (10-02) | 5c008d4 un-admit; 413b0af gate wreck-cap | a932b0a (#198), equal; `decls_mint.av:302 fn unadmit(f: FileId) -> List<DeclId>` on main | none | none |
| avra-decl-ids-side | decl-ids-side | 31a4ab8 (10-01) | cherry `-` | acf083c (#99) | none | none |
| avra-decl-owner-column | decl-owner-column | 4107a8f (10-01) | cherry `-` | cd3df92 (#102); `decls.av:412 decl_ids: Cell<List<Cell<SideTable<DeclAt>>>>` | none | none |
| avra-decl-rows-grain | decl-rows-grain | 8f53fab (10-01) | cherry `-` | a6f9072 (#173) | avra-8sb5.57.155 | none |
| avra-decl-rows-red | detached f3b604a | = main #84, 0 ahead | — | — | — | `decl_grain_test.av` +49 lines (add/rename grain cases) — ALL on main already (`decl_grain_test.av:173 "a declaration added keeps every query of main's"`, `:185 "\`one\` renamed moves the frontier, and main is refused"`, `:197`); `runtime/avra_runtime.c` census top-N 16/20 → 400; untracked `corpus/` 35 MB frozen census input + `edges.awk` (per-dep-family edge counter) |
| avra-typed-decl-grain | typed-decl-grain | f9b251f (10-01) | cherry `-` | 46d8154 (#114) | none | untracked `tools/grain-census/` (run.sh + main's copy of one test file) |
| avra-decls-fence | lane/decls-fence | 83603ca (09-30) | 777274a cherry `-` + a merge | 9cee431 (#38) | none | none |
| avra-ast-relations-s1 | ast-relations-s1 | fbd6541 (09-30) | cherry `-` | fe658af (#89) | none | none |
| avra-db-125 | lane/db-impl-reach | fc3b23d (09-30) | aa482a1, 0477a0c, 3a276b9, fc3b23d | 8a85aec (#54), equal | avra-8sb5.57.119, .125 | 47 untracked `…/tests/*/build/` dirs (test output only) |
| avra-db-119 | lane/db-importer-names | dc0507f (09-30) | dc0507f | first commit of #54 | avra-8sb5.57.119 | none |
| avra-declares-arg | lane/declares-arg | 2242b17 (09-30) | 0 ahead | — | — | untracked `probes/` (9 tiny packages probing a declaring annotation's argument) — not DB |

What these attempted (from diffs/stat, all landed): re-admission replaces a file's Decl rows by owner run (#101); un-admission
sweeps them (#198); `decl_ids` and the node→owning-decl column as partition-owned `@side` relations (#99, #102); declaration
reads recorded at name-bucket grain rather than whole-table (#173, #114); `@arena/@side` relation modes (#89); the importer's
cache key narrowed to reached files and impls reached through their type (#54).

Only non-main artifact with any reuse: avra-decl-rows-red `corpus/edges.awk` (counts kernel edges per dep family and
"named readers" over thresholds 4…256) and the frozen `corpus/census-input` — a measuring rig, not design content.

VERDICT each: **ABANDON** (identical to main). decl-rows-red's `corpus/` is an optional measuring rig; nothing to merge.

---

## 4. avra-docfact-side — the one tree with unlanded DB test work

- branch `docfact-side`; HEAD 3f073ba 2026-10-01 `fix(compiler): a relation's cache-soundness bug — a hash read as a revision (#111)`; 0 ahead / 168 behind (HEAD is a main commit).
- Uncommitted:
  - ` M packages/std-avrac/src/features/tests/doc_fact_test.av` (+71): adds `facts_with(doc)`, `query_doc(decls, outer, d, runs)`
    and a new spec `"DocFact — rendering inside the query, through the REAL kernel (avra-8sb5.57.9.7)"` with one case
    `"an edit to decl A's doc reruns only the query that read A's slot"` asserting `a1 == 1 && b1 == 1 && a2 == 2 && b2 == 1`.
    It reads through the production door: `DocFact.get_db(decls.decl_rows.get(), decls.doc_facts, decls.doc_facts_side, d.index)`
    between `kernel.begin(outer)` / `kernel.settle(outer, …)`.
  - `?? packages/std-avrac/src/features/tests/doc_fact_kernel_witness/doc_fact_kernel_witness.av`: same scenario as a program
    printing `rev0…rev3`, `a1 b1 a2 b2`, and `kernel.deps_of(query_a)`. **No `.expected` file** — never pinned.
- On main? NO: avra-db-design `doc_fact_test.av` has one spec only (`:17 spec "DocFact — a declaration's doc and annotations, as a @side column"`); no `query_doc`, no `doc_fact_kernel_witness`.
- Ticket: avra-8sb5.57.9.7 "docs: render inside the query -- doc facts as relations" — **OPEN, P2**, parked.
- WHAT IT ATTEMPTED: prove per-SLOT invalidation of a `@side` column through the real kernel (edit A's doc → only A's reader recomputes).
- HOW FAR: test written; no evidence it ran green (no `.expected`, NOT VERIFIED). The code half (Shape A: make doc facts
  Db-owned relations so a Db-only `@query` renders inside itself) was attempted twice and reverted; ticket comments record five walls:
  1. "AnnotationFact (holds Span?) is NOT stable-carried -> a Db-owned relation refuses it."
  2. "Writing the doc row at the DECL SLOT (id: DeclId + put_in at d.index) breaks Rows' sequential-id invariant: put_in with id > next_id() pushes the row at next_id then grows only stamps … gen-2 traps 'index 10 is out of bounds (length 1)'."
  3. "Keying DocFact on the dense decl (@local @key decl: DeclId) makes the relation derive generate NOTHING."
  4. "A field named `key` COLLIDES with the derive's generated `key()` member."
  5. "With `@key doc_key: string` … the derive STILL generates no `DocFactKey`/`by_key`/`insert`/`stable_hash` … and NO relation derive diagnostic surfaces." → "Blocked on (5)'s mechanism, not on design."
  And the premise correction: "A @query takes ONLY a Db … A @side relation's one read door is `DocFact.get_db(db, store, side, id)` … which needs the `Cell<SideTable<DocFact>>` PLUS its `SideRows<DocFact>`, both fields of Decls, NOT of the Db. So the door a Db-only query would need does not exist."
- VALUABLE FOR THE DESIGN: this is the sharpest evidence in the slice against "everything queryable as relations" being true
  today — **`@side` relations are not reachable from a typed `@query`**, and a Db-owned relation cannot be keyed by a dense id.
  The uncommitted test is a ready witness for slot-grain reuse once a query door for side columns exists.
- VERDICT: **KEEP** the test diff (small, self-contained; rebase is trivial since HEAD is a main commit) and carry the five
  walls into the design as open requirements on `@relation`/`@query`.

---

## 5. Older, superseded trees

### avra-rel (trace/dbfork)
- HEAD 8254155 2026-09-28 `fix(decl_rows): export DeclRow, needed by the parity keeper outside features/`; 0 ahead / 928 behind (HEAD is on main).
- Uncommitted (5 files, +59/-30, plus `decls_mint.av.orig`):
  - `decls.av`: `- decl_rows: Cell<Db>,` / `+ decl_rows: Db,` and `new_db()` uncelled; `decls_mint.av`: the `DeclRow.insert(…)` in `mint` replaced by `let _ = DeclRow.rows_in(self.decl_rows).count()` — a deliberate fork-reproduction experiment (branch name `trace/dbfork`; the field's own doc says a copy's state "reached another's, 'index 21 is out of bounds (length 0)'"). NOT VERIFIED what it concluded; no notes file.
  - `decls_mint.av`: `mint_generated_code` threads a `cursor` through statements + new `fn stmts_end` — ON MAIN (`decls_mint.av:758 mut cursor = lo`, `:772 fn stmts_end`).
  - `contexts.av` `fn type_name_type` + `structural_types.av` `.Decl(d) -> self.decls.type_name_type(d)`, `fn called_type` — ON MAIN (`contexts.av:183`, `structural_types.av:89`).
- Main today: `decls.av:476 decl_rows: Cell<Db>` (the Cell stayed).
- VERDICT: **ABANDON** — the fixes landed; the rest is a throwaway experiment that confirms "a Db is an identity, hold it in a Cell".

### avra-recordview (fix/record-view)
- HEAD bbe4daa 2026-09-27 `fix(features/decls): mut_param_names never reads a held decl's parse`; 1 ahead / 1219 behind; ticket avra-8sb5.57.24.
- Diff: one guard in `decls.av`: `+ if self.held.get().get(self.file(x.file).path) != null { return [] }`.
- On main: superseded — `d1ef6d6 fix(decls): the seal index reads facts, never a held file's store`; `mut_param_names` no longer exists in avra-db-design (grep empty).
- Still-useful sentence from its body: "A held (minted) declaration has no parse — `x.stmt` is the ordinal a STRANGER'S record wrote". (Rule: a saved answer never carries a process-local index.)
- VERDICT: **ABANDON**.

### avra-derived-merge (lane/orm-derived-merge)
- HEAD 5796907 2026-09-25 `chore(seed): the compiler re-emitted for Declared`; 2 ahead / 1561 behind.
- 0435601 `feat(meta): add Declared, an alternate Declares answer with problems` — cherry `-`, on main as 7c6127f. 5796907 is a seed regeneration (+21276/-20990), stale.
- Not DB-layer. VERDICT: **ABANDON**.

---

## 6. Docs

MEASURED (`ls docs/*.md *.md` per tree vs avra-db-design; `git diff --name-only <merge-base> HEAD -- '*.md'`):

| tree | doc | status |
|---|---|---|
| avra-decl-unadmit | docs/2026_10_02_PROVIDE_ENV.md (106 lines) | absent on main because main DELETED it (`0718345 docs(ui): five docs whose work is done or superseded are removed (#274)`). UI `provide`/`env` design; not DB. |
| avra-arm-rows | docs/2026_09_30_COLLECTIONS.md | branch-touched via a merged docs batch; on main as #36. Not DB. |
| avra-decl-replace, avra-decls-fence | DOGFOODING.md | branch-touched; both branches are patch-identical to their squashes, so the edits are on main. |
| all others | — | no doc absent from main, none touched by the branch, no dirty `*.md` (decl-rows-red's dirty `.md` are inside the copied `corpus/census-input`). |

Other root/docs `.md` differ from avra-db-design only because the trees are 83–1561 commits behind; no tree in this slice carries
a DB-relevant doc that main lacks. NOT VERIFIED file-by-file for content drift beyond the two checks above.

---

## 7. Ranked: most valuable unlanded pieces

| # | what | sha / tree | files | why |
|---|---|---|---|---|
| 1 | Slot-grain reuse witness through the real kernel | uncommitted, avra-docfact-side (on 3f073ba) | `packages/std-avrac/src/features/tests/doc_fact_test.av` (+71), `features/tests/doc_fact_kernel_witness/doc_fact_kernel_witness.av` (no `.expected`) | Only unlanded test in the slice; pins "edit A → only A's reader reruns" for a `@side` column. Unproven green. |
| 2 | Five walls + premise correction on "doc facts as Db-owned relations" | ticket avra-8sb5.57.9.7 comments (2026-10-01/02), no code survives | — | Names concrete gaps in the query door: `@side` unreachable from `@query`; dense-id keys generate nothing; Rows needs in-order ids; `Span?` not stable-carried; a silent derive that emits nothing. |
| 3 | Negative result: settle-loop tolerance of late writes | 6e1b3c6, aed9889, 535866b in avra-arm-rows | `compiler/whole.av` (`settled_analyses`), `features/decls.av`, `query/kernel.av` | Evidence for the input-door rule: re-ask-until-fixpoint trapped gen-2 ("side table `bindings` read past its range"); main refuses late writes instead. Knowledge only. |
| 4 | "Which open query did this mint happen under" trace | uncommitted, avra-bisE (on f4b6246) | `features/decls_mint.av` (qtrace line), `query/kernel.av` (`fn open_top`) | 6-line audit instrument for unrecorded inputs; trivially re-creatable. |
| 5 | Held-chain repro + edge census rig | uncommitted, avra-bisE `tools/.held.sh`; avra-decl-rows-red `corpus/edges.awk`, `corpus/census-input` (35 MB) | as named | Fixtures for measuring held reuse and per-family edge counts; convenience only. |

Everything else in the 29 trees: on main or dead.

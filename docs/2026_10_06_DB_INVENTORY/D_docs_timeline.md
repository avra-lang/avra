# D — docs digest and timeline: the compiler's query / cache / DB layer

Agent D, 2026-10-05. Read-only. Nothing built or run.

**Tree shorthand**
- `DBD` = `/Users/tristan/projects/tristanMatthias/avra-db-design` (origin/main `05fe643`) — "main".
- `STALE` = `/Users/tristan/projects/tristanMatthias/avra` (stale checkout, untracked notes).
- `SRC` = `/Users/tristan/projects/tristanMatthias/avra-sources-design` (worktree-only doc).
- `OLD` = `/Users/tristan/projects/tristanMatthias/forge-crafting-intepreters` (old tree).
- `PN` = `/Users/tristan/projects/tristanMatthias/perf-notes`.
- `REV` = `…/scratchpad/sources-review/`.
- Code paths below are under `DBD/packages/` unless a tree is named.

**Method notes**
- `docs_only.tsv` did not exist. I computed the ONLY list myself (`dbd/D_only_raw.tsv`, 94 rows over 277 worktrees) and md5-compared the six DB docs across all worktrees.
- Read in full: townhall §0–§2, §3.1 M5 S1–S3a, §3.4 lessons + §7 round 4 + receipts, §3.5 accessor proposal, §4, §6, §7, §8; DB_REDESIGN; COMPILER.md; COLLECTIONS 09-22; ADDING_A_PROJECTION; HANDOFF; MY_PLAN; REVIEW; REVIEW2; BUILD_TIME_SOURCES §1; old L6 query-engine design; FULL_SPEC decision 26.
- Read by grep only: townhall §3.1–§3.3 and §3.5 rounds (≈1,400 lines of per-session red-team), codex session, FEEDBACK.md, ROADMAP.md, DOGFOODING.md, ORM, AUTONOMOUS, AUTHORITY, the old AST epic. Anything I cite from those is a quoted grep hit.
- "NOT VERIFIED" marks an inference.

---

## 1. Every doc found

| # | Path (tree) | Date | Lines | Status | Thesis |
|---|---|---|---|---|---|
| 1 | `STALE:docs/2026_09_26_COMPILER_DB_TOWNHALL.md` | 2026-09-26 → 10-01 | 2973 | **Only in STALE. Untracked, never committed in any tree** (`git log --all` empty; absent from all 277 worktrees' `docs/`). | `@relation` + `@query` are the whole API; every tool is a thin query; durable by default; slices M0–M6. |
| 2 | `DBD:docs/2026_09_24_DB_REDESIGN.md` | 2026-09-24 (status 09-25) | 305 | On main; identical in 272 worktrees. Header STALE by townhall §1's own word. | Two types: `Kernel` (changed?) + `Db` (give me this). One `Row` enum, `insert`/`get`/`demand`. |
| 3 | `DBD:docs/2026_09_21_COMPILER.md` | 2026-09-21 (edits to 09-24) | 523 | On main; 2 worktrees hold older 486/491-line versions. | The one compiler doc: pipeline as queries, the hold, eight laws, the store is one compiler's. |
| 4 | `DBD:docs/2026_09_22_COLLECTIONS.md` | 2026-09-22 | 159 | On main, identical everywhere. | `collect` = a whole-program query answered as a typed value; long game is one relational base. |
| 5 | `DBD:docs/2026_09_30_COLLECTIONS.md` | 2026-09-30 | 743 | On main; 3 older variants in worktrees. | **Not DB.** List/Map verb vocabulary and loop lowering. 3 incidental keyword hits. |
| 6 | `DBD:docs/2026_09_26_ADDING_A_PROJECTION.md` | 2026-09-26 (last 10-01) | 276 | On main; 3 older variants. | Plugin author's guide to `@relation`/`@query` as landed; lists what is not built. |
| 7 | `DBD:docs/2026_09_21_COST_MODEL.md` | 2026-09-21 | 294 | On main. | Not read (cost model; grep-matched only). NOT VERIFIED as DB-relevant. |
| 8 | `STALE:HANDOFF_COMPILER_DB_2026_10_01.md` | 2026-10-01 18:20 UTC | 134 | Only in STALE, untracked. | DB epic state: "147 closed, 12 left"; pipeline handover. |
| 9 | `STALE:MY_PLAN.md` | — | 14 | Only in STALE. | Owner's topic list ("Databases" is one line). No DB design content. |
| 10 | `STALE:codex-session-01a0b3e3-….md` | ~2026-09-19..21 (NOT VERIFIED) | 28496 | Only in STALE. | Cache-campaign handoff: content-addressed `store.av` + `interface.av`; "persist the RESULT, not the input". |
| 11 | `STALE:docs/2026_09_24_ORM.md` | 2026-09-24 | 904 | Only in STALE. | `@std/db` ORM (`@model`). Not the compiler DB; shares vocabulary only (townhall §4.8). |
| 12 | `STALE:docs/2026_09_24_AUTONOMOUS_SYSTEMS_AND_STATE.md` | 2026-09-24 | 610 | Only in STALE. | Durable state for agents. No compiler-DB content (0 relevant grep hits). |
| 13 | `STALE:docs/2026_09_29_AUTHORITY_AND_RECEIPTS.md` | 2026-09-29 | 275 | Only in STALE. | Principals, receipts, "live witnesses" — a different "witness". No compiler-DB content. |
| 14 | `SRC:docs/2026_10_05_BUILD_TIME_SOURCES.md` (v2.1, `06594b4`) | 2026-10-05 | 1249 | Worktree-only (avra-sources-design). | §1: two doors — ONE input door (`InputKind`/`Part`), ONE kept-fact door ("a kept run"); 13 questions pending the DB lead. |
| 15 | `REV/REVIEW.md` | 2026-10-05 | 313 | Scratch. | Review of #14 v1: "NOT READY"; infrastructure answer is "Five, not one". |
| 16 | `REV/REVIEW2.md` | 2026-10-05 | 242 | Scratch. | Review of #14 v2: "NOT READY as a whole. Close."; new flaws N1–N7. |
| 17 | `OLD:docs/2026_04_18_FULL_SPEC.md` decision 26.1–26.4 | 2026-04-18 | 6532 (≈130 relevant) | Old tree. | Component registration + query execution; per-declaration incremental; full result caching in `.avra/cache/`. |
| 18 | `OLD:docs/2026_06_14_AST_SOURCE_OF_TRUTH_EPIC.md` (Layer 6, §10.B) | 2026-06-14 | 887 | Old tree. | "The compiler becomes a query database"; Salsa red-green; M1 ≤ 200 ms warm. |
| 19 | `OLD:docs/2026_07_16_L6_QUERY_ENGINE_DESIGN.md` | 2026-07-16 | 546 | Old tree. | Full Salsa design: `MemoEntry`, red-green, `sig_fp`/`body_fp`, per-item keys, mmap disk cache, daemon. |
| 20 | `OLD:docs/2026_07_18_L6_CODEGEN_CACHE_DESIGN.md` | 2026-07-18 | 295 | Old tree. | Per-fn codegen cache; read side deferred. First 12 lines read only. |
| 21 | `DBD:ROADMAP.md:241–268` | 2026-09-06 | ~30 | On main. | "AN EARLY-CUTOFF HASH THAT COVERS A PROJECTION OF ITS VALUE IS A LIE, and the memo kernel has one." |
| 22 | `DBD:DOGFOODING.md:121,126` | — | 2 rules | On main. | `compiler.bypass_outside_bracket`, `compiler.file_id_across_relation` — the two DB keepers as rules. |
| 23 | `PN/AGENT_RULES.md`, `PN/BRIEF_0930.md` | 2026-09-28..30 | 25 + 36 | Outside repo. | Measurement protocol (fixed point vs fixed point, same input, clear caches every run). |
| 24 | `STALE:FEEDBACK.md` | — | 14519 | Tracked on main too. | 34 grep hits for kernel/cache/relation. Not read. |

Other worktree-only docs (not DB): `PROVIDE_ENV` (36 worktrees), `UI_TARGETS_AND_WIRE` (12), `DECLARATIVE_BOARD` (8), `INSTANCE_STATE` (6), `INLINE_HANDLER_DISPATCH_REACHABILITY` (5), `CHANNELS`/`CHANNELS_CANVAS`, `UI_ASSETS`, `UI_EMIT_PROBE`, six 09-05/06 DOC_* docs, `STD_RELAUNCH`, `DESIGN_LANGUAGE_BRIEF`, `WEB_UI_REVIEW`. Full list: `dbd/D_only_raw.tsv`.

**Task premise corrected:** the task said to diff STALE's townhall "against avra-db-design's version". There is no such version. `DBD/docs/` has no townhall file. The epic ticket and two on-main files point at it anyway (see §4, C1).

---

## 2. The timeline

| # | Date | Source | Proposed | Stated status |
|---|---|---|---|---|
| T1 | 2026-04-18 | `OLD:FULL_SPEC.md:5068–5200` (decision 26) | "Component-based registration, query-based execution". "Fine-grained per-declaration incremental via query cache", key `(module_path, decl_name, input_hash)`. "Full result caching", `.avra/cache/`, LRU 5 GB, compiler-version bump wipes. | Spec target: "Current compiler may start with coarser granularity". |
| T2 | 2026-06-14 | `OLD:AST epic:71,286–406,549–561,719` | "The compiler becomes a query database." Salsa named. Passes pure first, then "a bounded runtime core (red-green invalidation + content-addressed memo store)", "incremental result MUST equal from-scratch result". M1 "≤ 200 ms" needs a warm daemon. | "decided · epic `ps3t.8`". |
| T3 | 2026-07-16 | `OLD:L6_QUERY_ENGINE_DESIGN.md` | `MemoEntry { value_hash, value, deps, changed_at, verified_at, diagnostics }`. Keys are content ids: "**Never per-node** — bookkeeping would exceed savings". Two fingerprints per item (`sig_fp`, `body_fp`). Cycles error by default; fixpoint is opt-in. Disk: mmap flat arrays, namespaced by `(compiler-version, hash-version)`. Then a daemon that "**is** the LSP server". | Design; phases P0–P6. §8.1–8.2 record per-fn CGU as built in the old tree. |
| T4 | 2026-07-18 | `OLD:L6_CODEGEN_CACHE_DESIGN.md:1–12` | Per-fn codegen cache; write side built, read side "deliberately deferred". | "This document does not gate any work." |
| T5 | 2026-09-02 | `DBD@505664e` adds `query/kernel.av` (then `query/db.av`) | The new tree's memo kernel: `ask`/`begin`/`settle`, `changed_at`/`verified_at`/`value_hash`. In-process only. | Built. No design doc found for it. |
| T6 | 2026-09-06 | `DBD:ROADMAP.md:241–268` | First recorded flaw: `parsed` settles on structural fingerprints while its value carries text and spans. "THE FIX IS NOT ONE HASH… The cutoff must be PER CONSUMER". | Open checkbox. "IT CANNOT FAIL TODAY… compiles are one-shot". |
| T7 | ~2026-09-19..21 | `STALE:codex-session:5–60` | Cache campaign. A content-addressed `Store` (`Stored` enum; "a row counts as present only when its data and its .deps file exist") plus module interface records. "persist the RESULT, not the input"; "Do not mint AST nodes for a held file". | Built on `avra-cache-cas`; merged to main 2026-09-21 (`86d7009`, per memory note — NOT VERIFIED against the log). |
| T8 | 2026-09-21 | `DBD:COMPILER.md §2, §5, §7, §8` | One derivation verb `Workspace.derived(entry, want)`; eight hold laws; "A store is ONE compiler's: `.avra-cache/<print>/`"; "The sources are the hold's oracle. A hold bug costs time, never a wrong answer." Refuses "A resident compiler — no daemon; the owner's word" and per-function codegen units. | "What is true now". §7b lists open cache items. |
| T9 | 2026-09-22 | `DBD:COLLECTIONS.md §5` | `collect` "is a query in the memo kernel… one more `Family`". "The long game… program facts as one relational base, with collections, callers… and lint rules all as queries over it." | "Design… Not built." (Since built: `collect enum Family` exists.) |
| T10 | 2026-09-24 | `DBD:DB_REDESIGN.md §1–§7` | Rename `Db`→`Kernel`. New `Db { kernel, rows: Table<Row>, names, root }`, a process `once fn db()`. One `Row` enum for all 19 families. "`Memo<T>`, `Store`, and `Family` don't survive even as internals". Validity = walk recorded deps' content hashes. | "Phase 1 SHIPPED (2026-09-25) — one kind (`DbRow.Decl`)". Phases 2–3 "not designed in detail". §9 lists six divergences. |
| T11 | 2026-09-24 | Memory index only ("Store as a database") | Owner: "relations, inserts, indexes, typed queries; no bespoke whole-program walks". | NOT VERIFIED beyond the index line. |
| T12 | 2026-09-26 | `STALE:TOWNHALL §0, §6` | Owner goal: "The compiler's DB is a real database, and every tool is a THIN QUERY over its rows." Five musts: generic, easy, very performant, "Extremely centralized — one store per command; no side caches", resumable. Design: `@relation type R`, `@query fn q(db,k)`, marks `id`/`@key`/`@unique`/`@index`/`@local`. "A QUERY OWNS THE ROWS IT INSERTS." `Workspace` "shrinks to `{ db, host, lang }`". | "converged after four red-team rounds… There are no open blockers." Nine slices M0–M6. |
| T13 | 2026-09-26 | `DBD:ADDING_A_PROJECTION.md` | "no step 3: no codec, no hash, no index code". | "`@relation`, its accessors and `@query` are on main… The durable pack… and the compiler's own relations… are not built". |
| T14 | 2026-09-26..28 | `STALE:TOWNHALL §3.4 receipts` | One Db per command; name-index for `spec_id`; `Relation<T>` + `Db.families`; last-reader stamp. | Landed (`514c5f9`, `05e79df`, M1 at `57d8a39`). |
| T15 | 2026-09-28 → 10-01 | `STALE:TOWNHALL §6.5a`; `DBD@85f1046` (#104), `DBD@83d4877` (#109) | **Reversal.** "kernel grain cannot persist." "The durable witness is the hold path's `KeyParts`… Kernel-grain deps stay in-process… The flattened recording and its switch are deleted." | Built: the flattened witness deleted 10-01 (#104); "the pack is deleted" 10-01 (#109). |
| T16 | 2026-10-01 | `STALE:HANDOFF §3` | Remaining: `.4.7` arm decl rows through the kernel; `.148` "the query families as `@query` declarations, so N3 can derive Family/DbKind"; `.101` "warm recheck to seconds (owner's bar ~300 ms)". | "147 closed, 12 left". Last warm one-line edit: 4.27 s. |
| T17 | 2026-10-01 22:22 → 10-02 | ticket `avra-8sb5.57.101` comment; ticket `.57.101.12` | "ABANDON the view_print fingerprint — it is a second, incomplete spelling of the dependency set the kernel already writes as (stable name, hash) witnesses at settle (M3, .57.6)." New ticket: "NEEDED: the M3 layer itself — at settle (or at keep), write a cell's deps as (stable name, hash) into a durable row". | `.57.101.12` OPEN, P2, no assignee. Three failed attempts recorded. |
| T18 | 2026-10-05 | `SRC:BUILD_TIME_SOURCES.md §1` | "**No. There are two half-doors and five persistence paths.**" Door 1: `InputKind { Text, Bytes, Range, Listing, Exists, Env, Pin, Tool, Target }` + `Part { kind, name, hash }`. Door 2: "A kept run. It is P4, made general." | v2.1; "§1 pending the DB lead" (D1–D13). "Fewer than today; not yet two." |
| T19 | 2026-10-05 | `REV/REVIEW.md §D`, `REV/REVIEW2.md §C` | Ruling: "**Not one mechanism.**" Fix order: one typed input part; one persisted derived-fact door; only then new consumers. Second pass: the `Part` atom cannot hold P4's lines; ownership belongs to the DB campaign. | "NOT READY". "Items 1–5 are a session with the DB lead." |

**Shape of the history:** seven attempts to name one mechanism (T1, T3, T8, T10, T12, T17, T18). Each kept the previous one's stores and added at least one.

---

## 3. Decision register

Status key: **BUILT** / **PARTLY** / **NOT BUILT** / **REVERSED**. Code quotes are from `DBD/packages/`.

### 3a. Townhall §4 (lead decisions 1–10)

| # | Decision (quoted) | Status | Evidence |
|---|---|---|---|
| 4.1 | "**One `Db` per command.** A command derives one Workspace; a later reader takes its `Db`, never builds another." | **BUILT**, one stated exception | `cli/src/commands/check.av:91` `let prog = c.program ?? root_program(path)`. Exception: `cli/src/commands/docs.av:78` `mut d = fresh_db()` (a second Db by design, `std-avrac/src/compiler/db.av:560–564`). |
| 4.2 | "**Dense addressing only.**… No scans… no string keys built per ask." | **PARTLY** | Dense: `db.av:553` `families: Cell<List<Relation<DbRow>>>`; `workspace.av` `asks_index: Cell<Map<string, int>>`. Not dense: `db.av` `fn index_key(kind, name) -> string { "${kind.tag()}\t${name}" }` is built on every `Db.get`. |
| 4.3 | "**A durable row's witness covers everything it read,** plus the producing compiler's digest." | **PARTLY** | Compiler digest: by store directory, and `db.av` `db_qualified(root, compiler, name)`. Reads: `db.av` `still_valid` answers `true` for `.Sig … .Answer` ("validity in the caller's key"); only `.Decl` re-checks. |
| 4.4 | "**`Db` is an identity: its tables live behind a `Cell`.**" | **BUILT** | `db.av:552–553` `@identity export type Db = { kernel: Kernel, rows: Cell<Map<string, DbRow>>, families: Cell<…> }`. |
| 4.5 | "**A witness is a list of (stable name, value hash).** Never a dense id". | **REVERSED** for kernel deps (§6.5a); **NOT BUILT** as one shape | `compiler/record.av:1097` `KeyParts = { module, path, text, runs: List<string>, seen: List<SeenPart> }`. `Decl` still uses `listing_digest` + `FileWitness`. Kept settlements use `u/c/m/f/b` lines (`kept_settle.av:171–275`). Three witness shapes. |
| 4.6 | "**A durable row reads only through `ask`.**… Held-file reads record a dep on that module's `Sig` row." | **BUILT** (audit is off by default) | `compiler/workspace.av:1672–1673` `if self.is_held(x.file) { self.held_sig_dep(x.file)`. Rule `compiler.bypass_outside_bracket` (`DOGFOODING.md:121`). `features/bypass.av:41` `export const audit_build: bool = false`. |
| 4.7 | "**A row and its witness settle in one step.**" | **NOT BUILT** for kept settlements | `compiler/kept_settle.av:152–153`: two `store.keep(Stored.Unit, …, [])` calls (value, then `#lines`). `Db.insert` passes `[]` as edges (`db.av`, `store.keep(Stored.Rows, …, encoded(row), [])`). |
| 4.8 | "**The compiler's DB is not an `@std/db` instance.**… The two share ONE vocabulary". | **BUILT**, with a twist | `std-relation/` is the shared package (`6d894d5`, 2026-09-26). Twist: the compiler now holds TWO Db types — `workspace.av:48` `use @std.relation.db.{Db as RelDb, …}` and `workspace.av:400` `failures_db: Cell<RelDb>`. |
| 4.9 | "**Accessors are static fns on the relation, and the relation holds its rows.**" Condition: "PERF cuts the store reach from ~226 instructions to at most 40". | **BUILT**; condition **NOT VERIFIED** | `ADDING_A_PROJECTION.md` accessor table. Last number in the townhall: "~166 → ~119 per reach" (§3.5 status, 2026-09-28) — above the 40 bar. |
| 4.10 | "**A field's type decides how it enters the stable hash and the codec.**… `@local`… `<T>Stored`… An enum hashes by its variant's NAME". | **PARTLY** | Built: `std-relation/src/relation.av:20–22`, `stable.av:279` "A variant read back by its NAME". Not built: a typed id as a keyed REFERENCE. The compiler's own relations mark typed ids `@local`: `compiler/failures.av:119` `Raised = { @local @index owner: DeclId, @local errors: List<TypeId> }`; `features/decls.av:384` `Ref`. So those rows cannot persist. |

### 3b. Townhall §6 (the design) and §6.5a, §6.6

| Item | Quoted | Status | Evidence |
|---|---|---|---|
| §6.2 | "`Workspace` shrinks to `{ db, host, lang }`" | **NOT BUILT** | `compiler/workspace.av:328–403`: 36 fields (counted), incl. `decls`, `store`, `records`, `keys`, `hold`, `asks`, `failures_db`, two fixpoints. |
| §6.2 | "A QUERY OWNS THE ROWS IT INSERTS… UPSERTS by `@key`" | **BUILT** in `@std/relation` | `ADDING_A_PROJECTION.md`: "a rerun replaces them… two queries writing one key are refused". |
| §6.3 | "Durable by default, with nothing to tune." | **NOT BUILT** | `ADDING_A_PROJECTION.md` "Not yet": "answers and rows are memory for the life of the Db". `Db.answers` (`compiler/answers.av:12`) has no non-test caller (grep). |
| §6.3 | "Every read is recorded… There is no raw table to bypass." | **PARTLY** | `Decl`/`File`/`Module` are relations armed through the kernel (`workspace.av` `relation_hooks`, `moved: … !late`). `features/decls.av` is still 2,879 lines of tables. |
| §6.4 | "A relation's own stable name is its fully qualified import path" | **BUILT** | `ADDING_A_PROJECTION.md`: "`@example.a.Todo`, `@example.b.Todo`; the stores and hashes are separate". |
| §6.5 | "an index BUCKET is itself a Kernel cell" | **BUILT** | `std-relation/src/db.av` Hooks doc: "cell 0 the whole relation and cell `b + 1` bucket `b`". |
| §6.5 | "Validation never materializes" (hash + edges persist per node) | **REVERSED** by §6.5a | See next row. |
| **§6.5a** | "**Decision (lead).** The durable witness is the hold path's `KeyParts`: a file's text plus each module it imports' interface digest, per file… Kernel-grain deps stay in-process. Fine-grained recording happens lazily, only when `avra cache why` asks. The flattened recording and its switch are deleted." | **BUILT** | `DBD@85f1046` "the flattened witness and its switch are deleted (#104)". No `witness*.av` in `compiler/`. `record.av:1097`. `cli/src/commands/cache.av:1` "`avra cache` / `cache why <file|query>`". |
| §6.6 | "rows go to ONE packed file per package… append-only, checksummed log" | **REVERSED** | Built 09-28/29 (`store/pack` commits), then `DBD@83d4877` "the pack is deleted (#109)". No `open_pack` in the tree. `Stored.Rows` is still a file per row (`store/store.av`). |
| §6.6 | "Each record header carries its relation's SHAPE fingerprint" | **NOT BUILT** | `REVIEW2 C.9 D3`: "The record wire has no version tag". |
| §6.6 | "Every phase lands with a `make census` before/after" | NOT VERIFIED | — |
| §6.8 M0 | "`Db` tables behind `Cell`" | **BUILT** | 4.4 above. |
| §6.8 M1 | "`Relation<T>` in query/; 22 memo fields -> `Db.families`; a last-reader stamp" | **BUILT** | `query/memo.av:31,35` `export type Relation<T> = …`, `export alias Memo<T> = Relation<T>`. `query/kernel.av:34–35,49–51` stamps and `Restore`. |
| §6.8 M2a | "Directive WRAP" | **BUILT** | `std-meta/src/meta.av:494` `Directive = { twin, name, at, source: Decls? = null, wraps: bool = false }`. |
| §6.8 M2 | "`@relation`/`@query` derives" | **BUILT** | `std-relation/src/relation.av` (1,291 lines), `query.av`. |
| §6.8 M3a/M3 | mmap pack row; "settle writes deps as witness" | **REVERSED** | Built as a library, never wired (ticket `.57.6` comment 2026-09-28: "witnessed_check/open_pack are not wired into avra check yet"), then deleted. Ticket closed 2026-10-01 anyway. |
| §6.8 M4 | "Held reads record `Sig` deps; bypass lint" | **BUILT** | 4.6 above. |
| §6.8 M5 | "`Decls` tables -> relations" | **PARTLY** | `features/decl_rows.av:40` `Decl`, `features/file_rows.av:14,22` `File`, `Module`. `Decls` still exists. |
| §6.8 M6 | "`ErrorSite` + topology queries; docs via `Decl` index" | **PARTLY** | `compiler/failures.av:103,119` `ErrorSite`, `Raised`. `compiler/doc_rows.av:14,21` two `@query` fns. All over `RelDb`, in memory. |
| §6.11 M5b | "`Expr`/`Stmt` as arena relations, `SideTable` facts as column relations… renames `NodeStore` to `SyntaxArena`" | **PARTLY** | Rename built: `core/store.av:41` `export type SyntaxArena`. `@relation(arena)` exists (`std-relation/src/relation.av:530`). No `@relation(column)` (grep). |
| §6.11 | "record reads at the OWNER's grain, never per node" | **BUILT** as `@index(grain)` | `ADDING_A_PROJECTION.md`: "`@index(grain)` names the bucket `get` records a row's read through". |
| §3.1 M5 S1 | "a read of another file's declaration row… records ONE edge per (open query, foreign file)" | BUILT then refined (NOT VERIFIED) | HANDOFF `.155`: "Decl rows are recorded per file, so adding or renaming a decl re-types every importer"; ticket `.101.12` says `.155` "landed as #173; per-row Decl reads". |

### 3c. Townhall §7 (N1–N8)

| # | Quoted | Status | Evidence |
|---|---|---|---|
| N1 | "A comprehension over a relation IS a query, and the compiler picks the index." | **NOT BUILT** | No planner found (grep `unindexed`, `index plan`). Consumers call `Todo.by_owner(db, owner)` by name. NOT VERIFIED beyond grep. |
| N2 | "A multi-valued `@index` over a `List` field." | **BUILT** in the derive | `ADDING_A_PROJECTION.md`: "a list field files its row under every element". `features/decls.av:1333` `indexed_by_mark` still stands in `Decls`. |
| N3 | "`collect enum Family = @relation or @query in closure`… deletes `Family` (22 arms) and `DbKind` (21 arms)" | **PARTLY** | `compiler/families/families.av:149` `export collect enum Family = @family in self by it.mark.args[0] dense` (33 `@family` hits; ranks to 31). `DbKind` is still by hand: `db.av:155–160` "hand-written, not derived", 24 arms. |
| N4 | "WRAP directives" | **BUILT** | M2a above. |
| N5 | "`@query(fixpoint)`… a semi-naive WORKLIST" | **PARTLY** | Engine built: `query/fixpoint.av:1–3` "A GROWING-SET FIXPOINT… semi-naive". The annotation argument is not: `ADDING_A_PROJECTION.md` "`@query` takes no `fixpoint` argument". |
| N6 | "`avra explain why <query>(<args>)`" | **BUILT under another name** | `cli/src/commands/cache.av:1,24` `cache why`. No `explain.av` in `cli/src/commands/`. In-process walk, not a persisted witness tree. |
| N7 | "`@input` on a Db accessor. `db.file_text(path)` and `db.env(k)`" | **PARTLY** | `compiler/inputs.av:21,30` `@input export fn file_text(_db: RelDb, path)`, `env_value`. Its own header: folding with `FileWitness` "needs `@relation`/`@query` wired to THAT `Db`… not yet built". `REVIEW2 C.6`: "`InputSlot.read` never records a read". |
| N8 | "`Reference`… `Finding`… as a relation" | **BUILT** (in memory) | `features/decls.av:384` `Ref`; `compiler/findings.av:13` `Finding = { @index rule: string, @index file: string, text: string }`. |

### 3d. DB_REDESIGN (09-24)

| Decision | Status | Evidence |
|---|---|---|
| "Renamed: `query/db.av`'s `Db` → `Kernel`" | **BUILT** | `query/kernel.av`. |
| "`Memo<T>`, `Store`, and `Family` don't survive even as internals" | **REVERSED** | `query/memo.av:35` alias kept; `compiler/store/store.av` kept; `Family` is now a `collect enum`. |
| "`export once fn db() -> Db`" (process singleton) | **REVERSED** | `db.av:8–17`: the singleton claim "checked against the real code and found FALSE"; "`Db` itself now lives per-`Workspace`". |
| "`Analysis`… never becomes a `Row` — it holds a closure" | **REVERSED** | `db.av:288` `Analysis(Analysis)` is a `DbRow` variant. |
| "`fn demand(kind, name, compute)`" | **NOT BUILT** | No `demand` on `Db` (`db.av:571–640`). |
| §3 "`recalled`… `record.deps.all(current_content_hash…)`" | **NOT BUILT** | `still_valid` (4.3 above). |
| §8 "Compaction… no GC story yet" | BUILT differently | `COMPILER.md §2`: "the newest four kept on `.avra-cache/compilers`". |

### 3e. COMPILER.md (09-21)

| Decision | Status | Evidence |
|---|---|---|
| §2 law 6 "A hold bug costs time, never a wrong answer." | **CONTRADICTED by a probe** | `REVIEW2 C.10`: edit an `embed`ded file, rebuild, "binary prints **`3`**. `avra run` prints `8`." Whether main has since fixed it: NOT VERIFIED. |
| §2 "A store is ONE compiler's: `.avra-cache/<print>/`" | **BUILT** | `REVIEW` table: "confirmed. READ `build.av:227`". |
| §8 "A resident compiler — no daemon; the owner's word." | Stands in the doc; see C7 | `cli/src/commands/dev.av:1–7` exists. |
| §5 "An incomplete query result must not be memoized" | BUILT (per CLAUDE.md; NOT VERIFIED in code) | — |
| §7a.4 "Cache state out of the 70-field `Workspace`" | **PARTLY** | 36 fields now; `Keys`, `Hold`, `Records` groups exist. |

### 3f. HANDOFF (10-01) items

| Item | Then | Now |
|---|---|---|
| `.4.7` "compiler relation Db records through the kernel" | PR #72 draft | `REVIEW B1`: "CLOSED; `Decl`/`File`/`Module` relations are armed through the kernel (`workspace.av:567`)". Code: `relation_hooks`. **BUILT.** |
| `.148` "the query families as `@query` declarations" | design approved | **BUILT as `@family` markers**, not `@query` (`families.av`). Differs from the approved wording. |
| `.12` N3 "collect synthesizes Family/DbKind" | blocked | Family **BUILT**; DbKind **NOT BUILT**. |
| `.101` "warm recheck to seconds (owner's bar ~300 ms)" | 4.27 s | Ticket still IN_PROGRESS. Latest comment (10-02): "Warm one-line fmt.av edit PARSES 48->6". No newer wall time read. |
| `.146` "Decls has no un-admit for a deleted file" | open | NOT VERIFIED. |

### 3g. The independent review's rulings

| Ruling | Quoted | Status in code |
|---|---|---|
| REVIEW §D | "**Not one mechanism.**… Count after the design lands: hold `KeyParts`; `Db.insert` named rows with hand `still_valid`; `Db.answers` (unarmed); the proposed 'durable door'…; the proposed machine blob store… Five, not one." | True of main today for the first three (all verified above). |
| REVIEW §D fix 1 | "one typed input part (`Text`/`Bytes`/`Listing`/`Target`/`Pin`) that `Host` serves, that `KeyParts` carries, and that `@input` is declared over" | **NOT BUILT** (`KeyParts.runs: List<string>`). |
| REVIEW §D fix 2 | "One persisted derived-fact door: arm `Db.answers`… for `Lifted` and seated `Settled`, keyed by content." | **NOT BUILT**. `kept_settle.av:40` still `ask.seats.is_empty()`. |
| REVIEW2 **N1** | "the witness type (C.2)": `Part = { kind, name, hash }` cannot hold P4's `u`/`c`/`f` lines, which "stand by a tiered OR". | Open design question. `kept_settle.av:171,186,245,275` confirm four distinct stands rules. |
| REVIEW2 **N4** | "spans in a kept lift (C.4)": the lift's name is "three dense ids"; `@std/meta` values carry `at: Loc?`. | Open. NOT VERIFIED in code by me (review cites `workspace_analysis.av:695`). |
| REVIEW2 **N7** | "no input kind for existence or env (C.1)… closer to fifteen read shapes" | Adopted by SOURCES v2.1 (`Exists`, `Env` kinds). **NOT BUILT.** |
| REVIEW2 C.3 | "`Store.keep`'s `read` slot is not ready to be the witness… No verb reads edges back." | Confirmed: `store/store.av` has `has`/`get`/`keep`/`keep_once`/`keep_file`, no edge reader. |
| REVIEW2 C.5 | "`Db.answers` is armed past a recorded deadline" (ticket `.57.4.6`) | Deadline exists in the ticket's close reason ("Open deadline recorded in the ticket notes: imported-quer…"). Unpaid. |
| REVIEW2 Q12 | "who owns the two doors… the DB campaign." | Owner decision; SOURCES D13 defaults the same way. |

---

## 4. Contradictions

### Doc vs doc

| # | Side A | Side B |
|---|---|---|
| C1 | Epic `avra-8sb5.57`: "Design: docs/2026_09_26_COMPILER_DB_TOWNHALL.md". `DBD:ADDING_A_PROJECTION.md:3,…`: "the design doc is the source of truth". `compiler/inputs.av:1` cites "COMPILER DB townhall §7.2". | The file is not on main and has no git history anywhere. The epic's source of truth is one untracked file in a stale checkout. |
| C2 | TOWNHALL §4.5: "A witness is a list of (stable name, value hash)"; §6.5: "At `settle`, a query's Kernel deps are written… as `(stable name, value hash)` pairs". | TOWNHALL §6.5a (same file): "kernel grain cannot persist… Kernel-grain deps stay in-process." §4.5 and §6.5 were never amended. |
| C3 | TOWNHALL §6.5a (lead, ≤10-01): kernel deps do not persist; "A 1% gate is unreachable while a witness is flat." | Ticket `.57.101` comment 2026-10-01 22:22 ("BOSS decision"): the sound form is to key on "(stable name, hash) witnesses at settle (M3, .57.6)". Ticket `.57.101.12` (10-02): "NEEDED: the M3 layer itself". Reconcilable only as "coarse cells, direct deps, re-asked" — nobody wrote that down. |
| C4 | TOWNHALL top: "**Status (2026-09-26):** converged… There are no open blockers." | Same file: §6.3/§6.7 "Not yet carried (2026-09-28)", §6.5a reversal, §6.9 "Open, for the owner". The status line was never updated. |
| C5 | DB_REDESIGN §1: one process `once fn db()`; "`Memo<T>`, `Store`, and `Family` don't survive". | TOWNHALL §1: "`Db` lives per-`Workspace`… no process singleton"; "`Kernel`… stays; `Db` WRAPS it"; it calls the older header "STALE". DB_REDESIGN on main still shows the old status. |
| C6 | TOWNHALL §6.6: "A file per row cannot carry durable-by-default. So rows go to ONE packed file per package". | SOURCES §1.4: door 2 rides `Store.keep`'s per-row `.deps` file. REVIEW2 C.8 flags it: "**tension**… The pack was never wired; say so and ask." |
| C7 | COMPILER.md §8: "A resident compiler — no daemon; the owner's word." | OLD L6 §9.3: the warm daemon "**is** the LSP server"; M1 ≤ 200 ms "effectively requires the in-memory daemon". HANDOFF: "owner's bar ~300 ms" warm. A ~300 ms bar with no daemon and a 4.27 s measurement is an unreconciled target. |
| C8 | TOWNHALL §0.4: "one store per command; no side caches". | SOURCES §1.1: "five persistence paths" plus "five rows… that fit none"; "18 direct `Store.keep*` call sites". |
| C9 | COLLECTIONS §4.7: "Collected means reachable". | TOWNHALL §6.9: plugin registration through `collect … in closure` means an un-imported plugin module "would SILENTLY not register". Marked "Open, for the owner"; no answer found. |
| C10 | SOURCES v1 cited `.57.6` as "the durable door… before this". | `.57.6` is CLOSED with its product deleted. REVIEW B1 caught it; v2 removed it. |
| C11 | L6 (OLD) §2.1: keys "Never per-node". FULL_SPEC 26.4: cache "Parsed ASTs… Type-checked declarations… Diagnostics". | New-tree law (codex handoff): "Do not mint AST nodes for a held file"; TOWNHALL §6.11: parse is "usually recomputed". The new tree persists interfaces and objects, never the AST. A deliberate departure from the spec, recorded nowhere as one. |

### Doc vs code

| # | Doc | Code |
|---|---|---|
| X1 | TOWNHALL §2.1: "`db.av`'s header claims `record.av`/`voices.av` declare their own `DbRow`; they do not… the comment is wrong." | Still there: `compiler/db.av` header "`compiler/record.av` and `compiler/voices.av` declare their OWN, unrelated `DbRow` types too". `grep DbRow record.av voices.av` → nothing. |
| X2 | TOWNHALL §6.2: `Workspace` = `{ db, host, lang }`. | 36 fields (`workspace.av:328–403`). |
| X3 | ADDING_A_PROJECTION "Not yet": persistence "is avra-8sb5.57.6 (M3)". | `.57.6` is closed; its pack is deleted (`83d4877`). The guide points readers at a dead ticket. |
| X4 | ADDING_A_PROJECTION: "the compiler's own `Decl` relation is not (avra-8sb5.57.8)"; "two different `Db` types today (avra-8sb5.57.4.7)". | `features/decl_rows.av:40` `Decl` exists; `.57.8` and `.57.4.7` closed. But two Db types remain (`workspace.av:48,400`). Half stale, half still true. |
| X5 | `compiler/inputs.av` header: unification "§7.5 schedules at M3… not yet built". | M3 was built and deleted. The recorded trigger can no longer fire as written. |
| X6 | TOWNHALL §4.7 "one step". | `kept_settle.av:152–153` two keeps. |
| X7 | TOWNHALL §4.2 "no string keys built per ask". | `db.av` `index_key` string per `Db.get`; `std-relation/src/db.av` `cells: Cell<Map<string, int>>`, `owner_frames: Cell<Map<string, Frame>>`. |
| X8 | COMPILER.md §2 law 6. | REVIEW2 C.10 stale-embed probe (reviewer's binary `0b5bd64`). |
| X9 | COMPILER.md §1: "Every stage is a QUERY in the memo kernel (`query/db.av`)… `Family` (`compiler/workspace.av`)". | File is `query/kernel.av`; `Family` is in `compiler/families/families.av`. |
| X10 | COMPILER.md §8 "no daemon". | `cli/src/commands/dev.av:1–7`: "`avra dev <path>`… built again when a file the build reads moves". Whether it holds a compiler in process or re-runs one: NOT VERIFIED. |
| X11 | DB_REDESIGN §2: `Analysis` "never becomes a `Row`". | `db.av:288` `Analysis(Analysis)`. |
| X12 | CLAUDE.md names `avra explain` in several laws. | No `explain` command (`cli/src/commands/` listing; REVIEW C.18 "unknown command: explain"). |

---

## 5. Ideas to absorb, ideas to kill

### Absorb (10)

| # | Idea | Source | Why |
|---|---|---|---|
| A1 | Two annotations, five marks, and "no step 3: no codec, no hash, no index code". | TOWNHALL §6.3; ADDING_A_PROJECTION | Built, tested, and the only API a consumer has liked. |
| A2 | "A QUERY OWNS THE ROWS IT INSERTS" + upsert by `@key` + "A row with no owning query is an INPUT". | TOWNHALL §6.2 | Makes relations derived data. Built in `@std/relation`. |
| A3 | Coarse durable grain; fine grain stays in process and is computed lazily for `cache why`. | TOWNHALL §6.5a (measured: 2.54 M keys, ≥51.6 M deps; pack 279 MB; +62% to +216%) | The one decision in the whole history backed by a failed build of the alternative. |
| A4 | One typed input part (`kind`, stable name, hash of exactly what was read), incl. `Exists` and `Env`; "a missing part is a mismatch". | SOURCES §1.3; REVIEW §D fix 1; REVIEW2 N7 | Replaces ~15 read shapes and 4 hand listing digests. Closes the stale-embed class. |
| A5 | A witness atom that is EITHER an input part OR a derived-fact line with its own stands rule. | REVIEW2 C.2 / N1 | Keeps "a body edit elsewhere in the file still stands", which a flat hash loses. |
| A6 | Owner-grain read recording: one edge per (query, owner slice); a stamp, never a per-begin allocation. | TOWNHALL §6.11; §3.4 kbench (hit ~300–330, new dep ~1,830–2,050, unrecorded ~117–137 instr/read; the `Map` attempt cost +14.9%) | Measured both ways. |
| A7 | The cutoff is per consumer: what a dependent READ decides which fingerprint may cut it off. | ROADMAP:241–268; OLD L6 §7 (`sig_fp` vs `body_fp`) | The old and new trees reached the same rule independently. |
| A8 | Value + diagnostics memoize and invalidate together; incremental == from-scratch as the oracle. | OLD L6 §1, §10; COMPILER.md `cache-attacks` | The oracle exists (`cache_attacks`, the evaluator reads no cache). Name it as the DB's acceptance test. |
| A9 | The store directory is the compiler's print, so the compiler digest is in every witness "by position". | COMPILER.md §2; TOWNHALL §6.6 first receipt | Removes a whole class of key bugs for free. Keep it; put only content-named bytes outside. |
| A10 | Families and row kinds are DECLARED and collected (`collect enum … dense`), growth is append-only. | TOWNHALL N3; `families.av` | Built for `Family`. Finish it for `DbKind` and the kept-row kinds. |

Runner-up: the semi-naive fixpoint with a declared join and "a turn cap SPEAKS" (TOWNHALL N5; built in `query/fixpoint.av`).

### Kill (5)

| # | Idea | Source | Why |
|---|---|---|---|
| K1 | Persist every kernel cell's hash and edges ("durable by default… Every query's hash and edges persist"). | TOWNHALL §6.3, §6.5 | Measured dead in §6.5a. The text still stands in §6.3 and misleads (SOURCES v1 followed it). |
| K2 | The per-package append-only mmap pack as the durable tier. | TOWNHALL §6.6 | Built, never wired, deleted (#109). Reopen only with a consumer and a number. |
| K3 | A process-singleton `once fn db()` and one closed `Row` enum for every fact. | DB_REDESIGN §1–§2 | Disproved in `db.av`'s own header; a closed enum cannot take plugin rows (TOWNHALL §6.3). The 24-arm `DbRow` is the leftover. |
| K4 | A warm daemon / resident compiler as the route to "instant". | OLD AST epic M1; OLD L6 §9.3 | Refused by the owner (COMPILER.md §8). The final design must state the warm target that is honest without one. |
| K5 | A second fingerprint beside the dependency set (`view_print`, a stamp-keyed digest shortcut, a per-build memo of keys). | ticket `.57.101` comments (3 failed attempts; "23 failed vs base 2" cache attacks); SOURCES §1.2 ("tried twice and removed") | Each was "a second, incomplete spelling of the dependency set". |

Also worth an explicit "no": N1 index-planning comprehensions before joins exist (TOWNHALL's own risk order puts N1 last, "the planner must be exactly right"), and per-function codegen units (COMPILER.md §8).

---

## 6. The best base to supersede

**`STALE:docs/2026_09_26_COMPILER_DB_TOWNHALL.md` — about 60% right. ESTIMATED.**

| Part | Share of the doc's design weight | Verdict |
|---|---|---|
| §0 goal, §6.2 model, §6.3 API, §6.4 identity, §4.4/4.8/4.9/4.10 | ~35% | Right and mostly built. |
| §6.5a, §6.11 grain rules, §3.4 measurements | ~15% | Right; the only measured parts. |
| §7 N2/N3/N4/N5/N7/N8 | ~10% | Right in direction, half built. |
| §6.5 per-node durable witness, §6.6 pack, "durable by default" | ~25% | Wrong as written; reversed by its own §6.5a. |
| §6.2 "Workspace shrinks", §6.8 M5 "Decls → relations" complete, N1 | ~15% | Unbuilt; no evidence either way. |

Why it is still the base:
- It is the only doc with owner-stated goals (§0), numbered decisions with owners, and receipts.
- Its API is what `@std/relation` implements.

What disqualifies it as-is:
- It is 2,973 lines, ~1,900 of them per-session red-team transcript.
- It contradicts itself on the central question (C2).
- It is untracked, in one stale checkout (C1).
- It says nothing on the non-relation half: the hold, `KeyParts`, kept settlements, `Stored.{Unit,Warn,Obj,Bin}`, 14 non-test `Store.keep*` call sites (my grep; SOURCES counts 18).

The missing half is best stated by two shorter docs:
- `DBD:docs/2026_09_21_COMPILER.md §2 + §5` — the hold's eight laws. ~80% right for what it covers (ESTIMATED); it covers the durable side only.
- `SRC:…BUILD_TIME_SOURCES.md §1` + `REV/REVIEW2.md §C` — the honest inventory (inputs, persistence paths) and the 13 open questions.

**Recommended base:** townhall §0 + §4 + §6.2–§6.4 + §6.5a + §6.11, joined to COMPILER.md §2's laws and SOURCES §1's two doors, with §6.5/§6.6 rewritten around §6.5a. The first job is committing it.

---

## 7. Measurements found (every number, with source)

All MEASURED by the cited source, not by me.

| What | Number | Command / condition | Commit | Date | Source |
|---|---|---|---|---|---|
| Second Workspace per command | 352.9B → 500.7B instr (+42%); peak 807 MB → 1.33 GB | `/usr/bin/time -l build/avra check packages/cli`, cold | at `9cc4fd5` | ≤09-26 | TOWNHALL §3.4.1 |
| Range regression | 252.6B → 607.7B (2.4×); peak 780 MB → 1.99 GB | same | `4e98526` → `b0f18a2` | ≤09-26 | §3.4.1 |
| `spec_id` name scan | 42% of samples | macOS `sample`, check cli | `b0f18a2` | ≤09-26 | §3.4.2 |
| One Db per command | 591.2/590.7/589.6B → 338.9/338.6/338.7B (−42.6%); peak ~1.95 GB → ~816 MB | cold check cli, 3 runs | `abdd52c` → `47d9541` | 09-26/27 | §3.4 receipt |
| Warm check, licence row cached | 251.8B → 125.7B → **0.362B**; peak 1.18 GB → 767 MB → 7 MB | warm check cli, 2nd run | → `1c0cad6` | 09-27 | §3.4 receipt |
| Name index | 338.7B → 288.5B (−15.3%) | cold check cli | `12dd15a` | 09-27 | same |
| qtrace guard | 288.5B → 286.7B (−0.7%) | cold check cli | `85bbd32` | 09-27 | same |
| Total | cold 590.7B → 286.7B (−51.5%); warm ~700× | — | main `05e79df` | 09-27 | same |
| M1 `Relation<T>` | cold 327.9B → 325.8B; warm 0.391B → 0.366B; peak ~808 → ~715 MB cold | cold check cli, avg of 3 | `9c081e7` vs `57d8a39` | 09-27/28 | same |
| Kernel read costs | stamped repeat 301–331; new dep 1,833–2,054; unrecorded 117–137 instr/read | `/tmp/kbench`, N = 1e5..1e7 | `90685f9` | 09-28 | same |
| Per-begin `Map` (rejected) | 328.6B → 377.6B (+14.9%) | cold check cli | main `8fd617c` | 09-28 | same |
| Save/restore stamp | 328.4B vs 329.6B (+0.36%) | cold check cli | `c1956d2` | 09-28 | same |
| Flattened witness | median 74,600 edges/file; 33.3 M edges; pack 279 MB; witness ON vs OFF: cli cold +62%, cli edited +38%, std-avrac cold +116%, edited +216% | cold `check packages/std-avrac` | `ef0d957` | ~09-29 | §6.5a |
| Kernel grain size | ≥2.54 M keys, ≥51.6 M direct deps | `check packages/cli` | — | ~09-30 | §6.5a |
| `KeyParts` hold | 397/399 held on a warm cli edit | — | — | 09-29 | §6.5a; ticket `.101` note |
| Store shape | 2,699 files, median 1 byte, 5.9 MB in 11 MB on disk | — | `23a704f` | 09-26 | §6.6 |
| Relation store reach | ~226 instr (list), ~691 (string map); later ~166 → ~119 | 200k reaches, native | `095dc5e`; main `66f35cd` | 09-28 | §3.5 |
| Recorded foreign row read | ~1,453 instr first time | — | — | 09-28 | §3.1 M5 S1 |
| Audit flag as runtime Cell | +0.69% | census | — | 09-28 | §3.1 M5 S2 |
| Docs fast path | 8.05 s → 0.037 s second call | `avra docs LanguageFeature`, std-avrac | — | 09-25 | DB_REDESIGN header |
| Check, same doc | 11.27 s / 0.042 s → 10.94 s / 0.038 s cold/warm | check | — | 09-25 | DB_REDESIGN header |
| Gates table | build cli cold ~10–13 s; no-op 0.08 s; one edit 0.31–0.40 s; check cli no-op ~0.04 s; one edit ~0.18 s; check std-avrac cold 13 s / warm ~1.5 s | load 10–16, machine lock | — | 09-21 | COMPILER.md §3 |
| One-edit check breakdown | startup 15 · load 36 · mint/fill 26 · parse+typing ~20 · lower 16 · keep 16 ms | — | — | 09-21 | COMPILER.md §3 |
| Warm one-line edit | 6.30 → 4.27 s | check cli, with PR #124 | — | 10-01 | HANDOFF §2–3 |
| Warm edit phases | wall 4.43 s: ast 996, sublang 1021, load 1422, admit 1132, analyze 621, lower 679, keep 160 ms | `./avra check --time packages/cli`, quiet Sprite | — | 10-01 | ticket `.101` |
| Load fix | wall 4.72 → 4.07 s; load 1324 → 796 ms | same-session A/B | `38f9b94` | 10-01 | ticket `.101` |
| `view_parts/reach` | 451 ms of a warm check cli; 0 of 70 view cells settled | warm4 | — | 10-02 | ticket `.101.12` |
| Warm parses | 48 → 6 | warm one-line `fmt.av` edit | `dacb95f` (PR #182) | 10-02 | ticket `.101` |
| Repeated edit text | ~225 ms (a cache hit) | — | — | 10-01 | HANDOFF §5 |
| Small package skip | cold 1.7 s, edit 539–683 ms ("78× cut from 42 s") | 3-file package | `avra-cache-cas` `b7755bf` | ~09-19 | codex session |
| Suite peaks | 678 MB (cold, buggy), 971 MB (cold, fixed), 802 / 2219 / 806 MB (warm, exit 1) | `build/avra test packages/std-avrac` under memcap | — | 09-28 | `PN/repro_*.log`, `warm_cache_mut_marks…log` last lines |
| Fixed-point drift | ~2.2% between gen-1 and fixed point; +0.50% from ~500 added lines | check | — | 09-28..30 | `PN/AGENT_RULES.md` rule 8 |
| Generated-declaration cost | N=200 0.21 s / 78 MB; N=1000 0.78 s / 282 MB (~140 KB each); comment edit 0.05 → 1.02 s | reviewer probe | binary `0b5bd64` | 10-05 | REVIEW B4 |
| Evaluator speed | 1 M iterations 2.63 s; native JSON parse ~28 MB/s vs evaluator ~45 KB/s | reviewer probe | `0b5bd64` | 10-05 | REVIEW B6 |

The warm-edit gate in COMPILER.md (0.18 s check, 09-21) and the 10-01 measurements (4.27–4.72 s) differ ~25×. Different machine load and a much larger tree are likely causes; nobody recorded which. NOT VERIFIED.

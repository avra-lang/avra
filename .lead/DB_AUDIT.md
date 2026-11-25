# DB audit: origin/main vs docs/2026_10_06_COMPILER_DB.md

Base: `origin/main` @ 69522c3d (2026-10-12), fetched at audit time; 207 PRs since 2026-10-06. Read-only, nothing built or run.
Paths below are under `packages/std-avrac/src/compiler/` unless they start with `packages/` or `tools/`. "NV" = not verified.
"No trace" = a `git grep -E` over origin/main returned 0 hits. Line counts are `git show origin/main:<f> | wc -l`.

## Top answers

- (a) **DB 07** (per-declaration answers; the hold deleted). One step retires formats 1 and 2, `KeyParts`, the hold with its record lines and
  memo maps, `load_interface`/`admit_all`, `homes`/`parts`/`seen`, `Analysis`, and the `Turn.Again` loop. It is also the design's own critical path
  to 300 ms (§7.3). Next by count is DB 08 (formats 4, 7-9, `closure`/`embeds`/`homes`), which needs DB 07 first for `parts`/`seen`.
- (b) §7.3 (L718-725): the first point the 300 ms gate is reachable is "DB 07 b, c and `Lowered` saved: 150-250 ms". The design's estimates for the
  steps before it: DB 00a + `.57.193` ~3.8 s; DB 01b + 03a + lazy minting ~2.5 s; DB 05 + 06 ~2 s; DB 07d ~1.3 s.
  Missing on main: 07a (rows and buckets as named parts of their producer's answer), 07b (`Resolved`/`Folded` per declaration), 07c (four whole-program
  families split), 07d (merged only as DRAFT #576, load still runs), `Lowered` saved (only per-declaration `unit_rows.av`, #605, on the old path),
  DB 03a (`file` still `@local`, `features/decl_rows.av:43`), DB 06 beyond steps 1 and 4, mmap in place (see table 1).
  Measured on main: `tools/speed.budget` rows `ci-warm warm edit 23216` ms and `warm unchanged 314` ms. #577 (docs) records a Sprite run with
  `load 14243ms`, `discarded 1`, `lower 8083ms` for one body edit. Gate target is 300 / 60 ms.
- (c) The design says "Nothing is open" (L54) and A15 lists its own reversals; I found no later doc that contradicts it. The only post-design edit to the
  design file is #577 (DB 00d, measured: "no minimal fix; the unruled turn needs DB 07"). Where main departs from a design statement without a doc:
  (1) D10 "no switch": the hold and its oracle still run (`derive.av:59-98`, `Attempt.unheld`); (2) §6.2 step 6 "no load or admit phase" vs
  `derive.av:608 self.admit_all()` and `record.av:632 load_interface`; (3) A16 "`Stored.Sig/Fp`" removal at DB 05 vs `Stored` still has 7 variants
  (`store/store.av:21-48`); (4) D2 "families convert from DB 01" vs ceiling 37 (design started at 32). Doc-only items: DB_01A2_OWNED_ROWS.md, DB_04_INPUT_DOOR.md exist (NV whether they reverse anything).

## Table 1: §6.2 "What a warm command does" (L499-513)

| # | step | status | what does the job today (evidence) | what is missing |
|---|---|---|---|---|
| 1 | map each sealed body and idx; read live segments into a hash | **partial** | `store/pack.av` (613 lines) merges every segment at open (`pack.av:6-7`); `store/body.av` (433) seals `body-<rev>.pack/.idx/.val` (#524 reverted by #574, re-landed #582). Body is read with `read_bytes` (`body.av:341`, `:408`), idx fan-out is real (`body.av:9-10`). | **No mmap.** Runtime rows `avra_mmap_open/len/slice/word_at/close` exist (`core/runtime_api.av:1397-1449`, `features/rt.av:509-522`) but nothing in the compiler calls them: `git grep avra_mmap` outside the row table, the generated `rt.av` verbs and `runtime_reach_test.av` → 0 hits. So the idx and meta are decoded into heap values, not read in place. |
| 2 | digest every input the records name, by durability tier; unmoved tier = one compare | **partial / absent** | The input door: `host/input.av` (250), `host/host.av`; `make inputs` (Makefile:759, `tools/inputs.py`, baseline `tools/inputs.baseline` 66 sites). Files are hashed once over bytes (#624), BLAKE3 digest (#595, `packages/std-hash`). | No input manifest (the set of inputs a record names, as a list) and no durability tiers: `git grep -nE 'durab|Durab'` hits only `answers.av` (the `Durable` type), no tier concept. Every record's read set is still verified per record (`store.get_valid`, #618). |
| 3 | changed input → reverse index → transitive readers are *suspect* (ids only) | **absent** | `kernel.av:619 deps_of(key)` is reader→reads only; `engine/fixpoint.av:159-172` has a private `reverse` map for the fixpoint solver, not for inputs. `cache_walk.av` (496) answers "dependents" by walking the graph (NV whether by scan). "suspect": `git grep suspect packages` → 0 hits outside sqlite. | A durable input→readers index; a suspect set. The hold (`record.av`, `derive.av`) decides staleness by re-reading files, not by a reverse walk. |
| 4 | roots asked; a non-suspect answer stands untouched | **absent** | `Workspace.derive` → `tried` (`derive.av:604-614`) runs `holding` → `unruled` → `admit_all` → `analysed` → `bodies_lowered` → `kept` → `stood` on every command. | Roots as saved answers (DB 08, `Verdict`/`Linked`/`Proved`: no trace of `Linked`/`Proved` types in `compiler/`). |
| 5 | suspect answer verified root-down by its read set's hash; early cutoff | **partial** | Kernel early cutoff and "moved readers re-judged" (#597, `kernel.av:326 judged`, `:778 newly_read`); `@query` saved answers carry what they stood on (#642, "DB 06 step 4"); reads are `(name, digest)` pairs (#618, "DB 06 step 1"). Query code hash (§6.4) landed: #429, #443, #446, #458, #470, #546. | Applies to saved `@query` answers only; the compiler's own families (37 `@family`, `families/families.av`) are not saved queries. Per-set-hash compare exists in the store (`store/names.av`, #512, "one hash per set per revision"). |
| 6 | whatever a recomputation needs loaded by name, on demand; no load/admit | **absent** (draft only) | `holding()` (`derive.av:622-645`) calls `load_interface` per held module (`record.av:632`) then `settle_holds`; `derive.av:608 self.admit_all()` (`whole.av:163`); decl rows minted by `decls_mint`. #576 "DB 07d by-name loading" merged as DRAFT, measuring only; #351 mints a held file's rows with their facts, #347 re-files only changed buckets. `workspace.av:1728,1786,2132` use `finish_lazy` (lazy settle), a different thing. | by-name loading replacing load/admit (DB 07d). |
| 7 | append records + one commit marker to this process's segment | **implemented** | `store/pack.av`: per-writer `seg-<writer>.log`, frames end with a truncated-BLAKE3 commit marker (`pack.av:6-11`); #582 "a warm check writes nothing". | `Stored.Rows` payloads are still opaque rows written through `compiler/db.av`'s `DbRow` (27 variants; the design says "8 durable"), i.e. §6.0 "today's rows move in as opaque values" is where it stands. |

Where the loop lives: attempts and the hold are in `derive.av` — `enum Turn { Again(Attempt) Refused(string) }` (L59-62), `Attempt.unheld/adrift/gave_way` (L66-98),
`stood_first` (L412), `tried_anew` (L571), `tried` (L604), `holding` (L622), `home_moved`/`known_homes` (L633, L825). The hold's per-file record is `record.av` (1936 lines).

## Table 2: §8 PR list

| PR | status | evidence | `make` / command column |
|---|---|---|---|
| **DB 00** harness + keepers | landed | harness #296 (`tools/db_measure/`), keepers in CI #298/#116/#360, `keepers` (Makefile:958) | `make keepers` exists; `keepers-green` target → no trace. `tools/warm_edit_bench.sh` exists (Makefile:812-825 `warm-edit`). |
| 00a unchanged files parsed | landed (NV exactness) | #312 "a module's record holds every file it places — a one-line edit no longer re-parses files nothing reaches"; #309 measured load split + admit defect | table of why each file was read: NV |
| 00b load profile / early fix | partial | #309 (docs, measured); #593-era hold PRs #400, #412, #416 (55 s → 13 s) | admit defect "`.57.193`" fix: NV; admit still 16 ms, load 14.2 s (#577) |
| 00c `--time` prints discarded cost | landed | `--time` line in #577 prints `discarded: 11908ms` | — |
| **DB 01a** kernel into @std/relation | landed | #315 (`packages/std-relation/src/engine/kernel.av`); layering keeper `make layers` (Makefile:752) | — |
| 01b `@query`/`@input` kernel cells; second memo, hooks deleted | landed | #316 "one engine — … the second memo and the hooks are gone"; `git grep -E 'Memo<\|type Hooks' packages/std-relation/src` → 0 hits | — |
| 01c packed deps | landed | #299 "an edge is a packed int" | — |
| 01d read-cost census | landed | #317 `make read-cost` (Makefile:773), #323 budget row | — |
| 01e families by name; `make families-left` | partial | #484 (in #592), #456 ceiling keeper, `make families-left` (Makefile:748) | prints 37 (`tools/families.ceiling` = 37; design said "starts at 32"); 37 `@family` lines in `families/families.av` |
| **DB 02** `avra explain` | landed | #349, #370, #464 (`--stats`), #474 (`--why` lists answers a change reaches) | `explain --stats` per #464. Reads the in-memory graph; `--why` still re-derives (`cache_walk.av:5-8`) |
| **DB 03a** names + Decl key | partial | #362 (decl row keyed by file/kind/owner/maker/name/sibling), #385, #501 "an id crosses as a durable name" | `file` still `@local` (`features/decl_rows.av:43-44`): the design's stated precondition is unmet |
| 03b codec: payload enums, recursive records | landed | #487 "codec growth" (in #592) | — |
| 03c one codec per family answer (~20) | partial | #493 (SourceFile, Unsettled, Settlement, LiftResult), #496 (scalars), #504 (DeclSig), #518 (Loc, DiagFacts) | `make codecs` exists (Makefile:1055). Count converted vs ~20: NV |
| **DB 04a** digest row | landed | #325 | `make inputs` exists (Makefile:759) |
| 04b `Source`, `Manifest` | landed | #336, #352, #366 | — |
| 04c `embed`, listings | landed | #371, #384, #502; `admit_embeds`: no trace (0 hits) | — |
| 04d env, tool, target, compiler | landed | #395, #411, #516 | — |
| 04e the rest | partial | #486, #489, #491, #508; baseline still lists 66 outside-door sites (`tools/inputs.baseline`; design counted 172, 35 "not inputs") | `make inputs` fails only on a NEW site, not on the 66 |
| **DB 05a** `@std/hash` | landed | #397, #595; `packages/std-hash` | `make hash-door` exists (Makefile:206) |
| **DB 05b** query code hash | landed | #429, #443, #446, #458, #469, #470, #546, #544; `tools/code_hash_attacks.sh` | — |
| **DB 05c** store format | partial | #512, #515, #524 (reverted #574), #582; `tools/store_attacks.sh`, `make cache-attacks` (Makefile:597), #505, #543 | two tiers + per-writer segments + sealed body/idx in; mmap not used (table 1 step 1); `ls .avra-cache` shows `store/obj/bin`: NV; gc/time-travel (§6.7): NV; `.deps` files: no trace in `store/` |
| **DB 06** saved-answer rule | partial | #618 (step 1), #642 (step 4); steps 2-3: no trace by that name | `make db-corpus` → no trace (0 hits in Makefile, tools). `docs LanguageFeature` second run ≤0.05 s: NV. A5 17 attack cases ported: NV |
| **DB 07a** rows/buckets as named parts | partial | #347, #351, #362 are adjacent; the "minted by one query, filed by another" end-state: NV | — |
| 07b `Resolved`/`Folded` per declaration | partial | #114 "a use reads the declaration it names", #537 "a run's read names the declaration it read", #570, #597 | `Analysis` family still `@family("FileId","Analysis")` (`families.av`) |
| 07c four whole-program families split | not started (NV) | no PR title names it | — |
| 07d by-name loading | **DRAFT only** | #576 (DRAFT, "measuring"), #578 (DRAFT, "no delta"), #577 measured "no minimal fix" | `admit_all`/`load_interface` live (table 1) |
| 07e hold deleted | not started | `Turn`, `Attempt.hold`, `settle_holds` live (`derive.av`); #552/#575 wire the warm-edit gate as a keeper | — |
| 07f `Analysis` dissolves | not started | `analysis.av:30 export type Analysis` | `warm_edit.sh` gate: wired in CI (#552, #575); budget `ci-warm warm edit 23216` ms vs 300 target |
| **DB 08** roots | not started | no `Verdict`/`Linked`/`Proved` types; formats 4, 7-9 live (table 3) | — |
| **DB 09** `Settled`/`Lifted` | not started, grew | `kept_settle.av` 595 lines (design 324); #671 added a digest line scheme | — |
| **DB 10** plugin crossing | not started | no `…Row` plugin relations; `meta.av` (648 lines) has no ask-verb block at the design's 338-366 and 2 externs left (`avra_embed`, `avra_type_named`, L40-42); "collect enum" #585 is DB 10's collect membership only in part | the two-package probe: NV |
| **DB 11** shared content store | not started | `~/.avra/cache/cas`, `cache clean`: no trace in `packages/cli/src` or `compiler/` | — |
| **DB 12** families → `@query` | partial | #456 ceiling keeper; kernel dispatch #531 | 37 left; ceiling never lowered below 37 on main |

## Table 3: A16 "Every second mechanism on main"

| mechanism | verdict | evidence |
|---|---|---|
| std-relation `Memo<V>` second memo | **GONE** | #316 |
| `Hooks`: nine erased closures | **GONE** (relation side) | #316; `type Hooks` → 0 hits in std-relation. Compiler-side `workspace.av` hooks (`disarmed`, `discarded`): NV count |
| `@input` vs `Memo.input` | **GONE** | #316; `std-relation/src/input.av` is the one door |
| world reads outside any door (172) | **STILL** (reduced) | `tools/inputs.baseline` 66 sites; door `host/input.av` (250); #325 … #516 |
| `admit_embeds` string `"embed"` | **GONE** | #384 (no trace of `admit_embeds`) |
| `@family(rank,"Key","Answer")` | **STILL** | 37 sites `families/families.av`; ceiling 37 |
| compiler `Db`/`DbRow`/`DbKind`/`durable_key` | **STILL** | `db.av` 876 lines (design 732): `enum DbKind` L170, `enum DbRow` L291 (27 variants), `durable_key` L796 |
| `Db.answers`, `answer_name`, hex codec | **STILL** | `answers.av` 41 lines (design 46); `answer_name` L30 |
| format 1 `KeyParts`, `stands_in` | **STILL** | `answers.av:13`, `derive.av:480 stands_in`; `record.av` 1936 lines |
| format 2 module record lines `written_from` | **STILL** | `record.av:1001` |
| format 3 kept-settle lines `u c m f b e` (+`l`) | **STILL**, `l` landed | `kept_settle.av` 595 lines (design 324); `l` at L100 (`crossing_layout`) |
| format 4 `program_key` | **STILL** | `build.av:531` (build.av 927 lines) |
| format 5 links witness | NV | not located by grep in this pass |
| format 6 `DocFacts` + `FileWitness`, `still_valid` | **STILL** | `db.av:94`, `:128`, `:804` |
| formats 7-9 `proved_key`, `clean_key`, `canon_key` | **STILL** | `suite.av:275`, `derive.av:297`, `packages/cli/src/commands/fmt.av:81` |
| remembered rows `closure`, `embeds`, `homes`, `parts`, `seen` | **STILL** (4 of 5) | `build.av:478 closure_key`, `derive.av:294 homes_key`, `record.av:1522 parts_key`, `:1536 seen_key`; `embeds` row: not found (likely gone with #384, NV) |
| string-keyed memo maps (35/45) | NV | not counted this pass |
| `Store.keep`'s `read` slot; `.deps` files; `Stored.Sig/Fp` | **STILL / partly GONE** | `store.av:208 keep(... read: List<string>)`, `keep_reading` (L243, #618) beside it; `.deps`: no trace in `store/`; `Stored.Sig`, `Fp` still in the enum |
| `@side` column unreachable by a query (`DocFact`, `.57.9.7`) | NV | #106 gave `@side` columns per-slot deps; `DocFact` itself not re-checked |
| `Decls.gathered`'s raw bucket read | **STILL** | `features/decls.av:1664 fn gathered` (+ `gathered_into` L1673, `gathered_by_mark` L1694) |
| `@std/meta` ask verbs (extern + arm + closure each) | **mostly GONE** | `std-meta/src/meta.av` now has 2 externs (L40, L42) |
| `avra cache why/dependents/changed/held` | **STILL, grew** | `cache_walk.av` 496 lines (design 218); `explain.av` is the CLI face (#349, #474) |
| three types named `Db` | **STILL** | sqlite, relation, compiler (`compiler/db.av`) |
| `Expr`/`Stmt` as `@relation @arena` | stays (by design) | — |

### Added to main since 2026-10-06, on the old path (not in the design)

| addition | where | toward a design item, or a new format? |
|---|---|---|
| `unit_rows.av` — "a lowered unit kept by declaration" (`UnitRow{key,wants,facts,consts}` wire strings, `unit_served`, `consts_stand`) | `unit_rows.av` 217 lines, #605 | Step toward `Lowered` saved per declaration (DB 07 b/c, DB 08 `Lowered` root), but the validity test is a **new hand-written format** (a row judged by `consts_stand` + file surface, `unit_rows.av:20-30`) |
| `homes` rows (`homes_key`, `known_homes`, `home_moved`, `Turn.Again(homes)`) | `derive.av:294,633,825` | In the design's list of five unvalidated rows (A2); not new, but it **now drives a Turn** (`Attempt.homes`) |
| `asked_print` (clean_key's print of instantiation roots) | `derive.av:1023` | Design format 8; not new |
| kept-settle `l` line (layout) and digest-named line sets | `kept_settle.av:100`, #671 | design A2 format 3 already anticipates `l`; the digest naming is **new format surface** |
| `Unruled`/`unruled` turn, `lead_reads` const-verdict pre-reads | `derive.av` (#468 per #577), #416 "recorded runs read up front" | grows the hold (what DB 07e deletes); not a design item |
| held-collector / draft hold rules (#400, #412, #434, #608) | `record.av`, `derive.av`, `decls.av` | all inside the hold; same: deleted by DB 07e |
| `DbRow` 27 variants incl. `Visible/Resolved/Typed/…` lazy-finish rows | `db.av:291-345`, `workspace.av:1728-2183` | old path; DB 12 removes. Count vs design's "8 durable": NV on how many are durable |
| per-declaration `RowPlace`/`row_place` | `unit_rows.av` (`self.row_place(s,w)`) | tied to `unit_rows`; same verdict |
| A2 count today | | Design: **9 formats + 5 unvalidated rows**. Main: formats 1, 2, 3, 4, 6, 7, 8, 9 still present (8), format 5 NV, plus `unit_rows` wire = **>= 9 formats**, and 4 of the 5 rows. Net: none removed, one added |

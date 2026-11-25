# Harvest — store / codec / typed rows / durable names / DB 06·07·08·09·10·12

2026-10-30 · read-only survey · base `hd-clean` 3bdb4dbb (contains origin/main 5f65f027).

**Method.** For each ref: `git rev-list` ahead/behind vs origin/main; `git cherry`; PR state from
`gh pr list --state all`; and a **landed check**: every added line longer than 30 chars in
`merge-base..ref` is searched for verbatim in the same file on `hd-clean` (or `origin/main` for the
four "named in a batch" PRs). Shown as `landed x/y`. A squash or a later rewrite lowers the ratio,
so ≥ ~85 % means landed; < 10 % means not landed.

## Verdicts: the four "named in a merged batch, PR still open" PRs

| PR | branch | verdict | evidence |
|---|---|---|---|
| **#1201** store: seal into runs; names no place | `store-open-index` 50e6feee | **NOT LANDED** | landed 31/643 vs origin/main. `tools/store_keys.py` and `tools/store_names_attack.sh` absent; `packages.av` 0/72, `store/body.av` and `pack.av` 0/49. Batch AD (449c3fd7) names it only as "Waiting… latest runs red" and "not a member". Batch AN (#1288) shipped an interim seal-by-size instead. PR is a draft and conflicts. |
| **#1135** db-09: LiftResult's codec is paid | `db-09-lifted` 52355fab | **LANDED** | doc-only, landed 25/26 on origin/main (the A4.1 section of `docs/2026_10_06_COMPILER_DB.md`). It is a member of batch S-clean db2b815e (#1171). |
| **#1062** relation: `@over`'s listing exported | `db-170-over` 60ebc099 | **LANDED** | landed 22/23 on origin/main. `tests/over_export` 12/12 and `tests/producer_cross` 5/5 are present, and so is `query.av`. A member of S-clean db2b815e. |
| **#964** catch: CatchArm records; build_catch dies | `origin/land-catch4` c78b9292 | **NOT LANDED** | landed 1/73. `build_catch` is still on origin/main (`features/expr_spine/builders.av:105`, `mod.av:53 "catch_any" \| build_catch`), and `results/tests/catch_forms` is absent. Batch #1031 (f1a66e33) names it "#964: conflicts, owners to rebase". It is a nodes PR, not a store PR (Nodes step 5). |

Close #1135 and #1062 as landed via db2b815e. Rebase or port #964 in the Nodes lane. #1201 is
real, unlanded store work (see its row).

## Harvest table

Goal steps: **S1** = comment-edit fast path · **S2** = saved per-declaration analysis · **S3** = delete the hold · **S4** = DB 08/09 · **S5** = DB 12/10.

### A. The typed-rows / codec cluster (S2)

| ref / PR | what it did | proved / measured | why it failed or stalled | PORT (shas, files) | close? | step |
|---|---|---|---|---|---|---|
| `db-stored` 203b4635 (local), `origin/db-stored` 979cc157; recover `avra-codec-base-wip` 498cfb56 | WIP `@codec` generator in std-relation ("any record or enum, dense ids through a scope"). TypeFacts opts in (`compiler/facts_codec.av` 36 L, `facts_codec_test.av`). `SideTable.space` / `@window` (d89a1c54). | Round-trip witness for TypeFacts. | The relation half landed via #1150 (`db-03c-codec`): relation.av 150/207, stored_codec_test 74/80. The compiler half (TypeFacts `@codec`) is the build-OOM path (see 0272f17d). | Nothing from the generator. Maybe `core/side_table.av` `space`/`@window` (13 L, 0 landed) if windows must cross generically. | yes (learned: `@codec` on TypeFacts OOMs the build) | S2 |
| `db-07b-typed` 99504c18 = `origin/db-gather-typed` 7c8d3218 (the same 6 commits, rebased); worktree `avra-07a-gather` (dirty) | `compiler/typed_rows.av`: `typed_row(d)`, `typed_restored(x)` (`store.get_valid` + `rows_db.leaf_digest`), `keep_typed(store)` (`rows_db.leaves_of(kernel.deps_of(Typed))` → `keep_reading`), plus a `typed-miss` qtrace naming `first_moved`. | `.57.176` comment 2026-10-21: a one-literal cli edit gives **82 typed, restored 0** on both main and db-warm. The "82→37" claim **does not hold**. `AVRA_DB_VERIFY=typed`: 19108 settled, 19104 valid, 0 mismatched, so the rule is sound. **Ceiling: bodies 473–794 ms** of a 4.5–6.8 s warm check. | Inert. A kept row's first failed read has a **null digest**, because `hash_forced` answers null for an answer never asked (held `HeldSig`, `Names`, `Writes`, `Sig`, `Placed`). It also rides db-stored's old `@codec`, which drops main's `collect_names`. | **typed_rows.av glue**: its APIs all exist on hd-clean (`get_valid`, `keep_reading`, `leaves_of`, `leaf_digest`, `first_moved`). Only `hold.typed_made` is missing. Dirty wt: the `decl_from_ref` fix in `settlement_wire.av` (mint the file a wire names before resolving, 3 L), which a restore needs whenever a fact names a declaration in a held file. | yes after port | S2 |
| `hold-delete-keep` 13199b00 (local only) | Same series, plus **13199b00 "@codec hoists the owner and meets each kind once"**: `collect_kinds` with a `Reach{kinds, met: Map}` instead of `acc.any(spelled==)` (quadratic → linear). Also 0e2f6f70, a temporary `[lifted]` budget (6 M steps, 50 MB). | Removing the budget compiled. | 0/167 landed. Superseded by 0272f17d's decision. | **13199b00** (relation.av, ~55 L): an O(n²)→O(n) fix in the generator. Worth landing on its own, independent of TypeFacts. | yes after 13199b00 | S2/S5 |
| `hold-delete-typed` b12bd0cc / `origin/hold-delete-typed` **f10f8b04** | Typed saved per declaration through `saves`/`revive` in `saved.av` (`typed_text`, `typed_revived` → `Revival.Revived(DbRow.Typed)`), restored over its file's parse. Typed's arg named as a Decl. | Not measured standalone. | The base is the hold cut (`saved.av` is not on main or hd-clean). Typed as a **family answer** stands alone in every reader's read set: that is ONE_STORE's 7.9 GB OOM shape. | Learn only. The two refusals (an expanding file's window, a file not parsed here) are copied in e6929af0's `facts_restored`. | yes | S2 |
| `hold-delete-lowered` **0272f17d** (+5e20e089 merge into the cut) | **The rejection.** It deleted `facts_codec.av` and its test, and dropped Typed from saved families. "No `@codec` until the generator is bounded (its derive is the compiler build's OOM)". `stands_alone` became the registry. | — | Rejected because the `@codec` **derive** on a 20-column generic record is a compile-time settlement too big for the build, even after 13199b00. | The lesson: **no generated per-type codec for TypeFacts**. Use one executor per direction (e6929af0). | yes (learned) | S2 |
| **`origin/hd-sigfix` e6929af0 + 6e3685d5** (in `hd-sigfix`, 136 ahead, the hold cut) | **`compiler/facts_codec.av` (472 L) + `tests/facts_codec_test.av` (218 L)**: a hand executor, ONE per direction, over `@std.relation.stable` (`Writer`/`Reader`/`Scope`/`dense_read`/`written_dense`/`encoded_with`/`decoded_with`). `FactsScope` spells Decl/Type/File by durable ref and Expr/Stmt as offsets from the declaration's window. Every TypeFacts column is written. A table that **spoke** has no wire (`null`). `facts_row_key` is a plain `Stored.Unit` under `["facts", key_of(d), text_digest(path)]`, **never a family answer** (it avoids the stands-alone OOM). `facts_restored` / `facts_kept` / `facts_stands` validate one level of reads. | The test round-trips every column, its windows and absence. Built inside hd-sigfix (whose cold check times out at 600 s), so it is **never measured on a working tree**. | It lives only on the broken hold-delete branch. It depends on `WIRE_FACTS` (2913a0a2) and on `saved_name` / `saved_read_key` from the cut's `saved.av` (absent on hd-clean). | **Port `facts_codec.av` lines 1–440** (the executor, `FactsScope`, `facts_encoded_in`/`facts_decoded_in`) and the test **verbatim**: its imports exist on hd-clean except `WIRE_FACTS`. **Rewrite the save/validate block (440–515)** over hd-clean's `rows_db.leaves_of` + `store.keep_reading/get_valid(leaf_digest)`, as `typed_rows.av` does. Register the pair in `codecs.av` (`derived("facts_codec.facts_encoded_in/facts_decoded_in", …)`). | close hd-sigfix after the port and the hold harvest | **S2** |
| `origin/hd-sigfix` **2913a0a2** | `WIRE_FACTS`/`WIRE_PRODUCERS`/`WIRE_ROW` consts + `store_wire()` = the fold of every wire version. `own_stamp()` becomes `"wire ${store_wire()}"`: **a row stands under its wire's shape, never under the compiler that wrote it.** | — | Rides hd-sigfix. | **Port** (store.av +32, facts_codec +42, derive/producers/record small). It is ONE_STORE Move 4's "one stamp", and it lets a rebuilt compiler keep its rows. | with hd-sigfix | S2/S1 |
| `origin/hd-sigfix` 30d80f71, 2eb3161e/24a01003/31c3d459, f31e21f5, a491f45f | 30d80f71: a text digest is a family answer keyed by the octets read, and flush skips an unmoved row. 2eb3161e: an unchanged answer is not filed again. **f31e21f5: "a file whose row stands owes nothing — codes and voices are read back, not re-derived"** (derive.av, program.av). a491f45f: a saved unit stands for its lowering in a check. | hd-sigfix-era timings only (ONE_STORE: keep 109.6 s on the cut). | Inside the hold cut. | **f31e21f5** for S1 (keep 220 ms on 2 files). 2eb3161e as a cheap keep win. 30d80f71 for S4's input door. All need re-basing onto hd-clean's `saved.av`-free store. | with hd-sigfix | S1/S4 |
| `codec-pr` / PR **#1028** (CLOSED), `db-03c-codec` / PR **#1150** (CLOSED), `db-09-decoding` / PR **#1148** (CLOSED) | `@codec`: maps, nested records, `@local` fields, variants by place under an 8-octet fingerprint. The scope travels with the call. A record reads back where its answer is kept. | `tests/durable` `paired` runs once across 2 processes, and `@query -> LiftResult` saves (A4.1 correction). | — | **LANDED** (423/457, 553/560, 53/59 on hd-clean, via batch Q 846e8a84). Nothing to port. | yes | S4/S5 |

### B. Durable names and the store (S1/S2/S3)

| ref / PR | what it did | proved / measured | why failed / stalled | PORT | close? | step |
|---|---|---|---|---|---|---|
| **`by-name-store` 172175ec** (5 commits) | **276792ca (relation): "a key this process never settled stands on its saved answer's reads"**. The kernel looks a never-settled key up among saved answers (`Saved`/`SavedRead`), demands each read in order and compares value hashes. A Relation revives the value via its hook. **172175ec**: `compiler/saved.av` (160 L), a key's durable name and the rows the kernel finds saved answers by. Also contains the #1201 seal commits. | `engine/tests/saved_test.av` (127 L), `compiler/tests/saved_test.av`. | 35/846 landed. Never PR'd. Overtaken by the hold-delete branches, which grew `saved.av` to 657 L. | **276792ca is THE fix for the db-gather null-digest blocker** ("hash_forced answers null for an answer never asked"): a held declaration's Sig/Names answer becomes checkable by name. Port it (answers.av +50, kernel.av +64, test) and pair it with leaves.av's `AnswerRef` names, NOT with saved.av's `ArgName` (a second naming registry). | close after port | **S2**/S3 |
| **`store-open-index` / PR #1201** (DRAFT, conflicts) 50e6feee | Seal into **runs** (`BODY_VERSION` 7: a body names the run below; a seal folds only the newest runs while they are ≥ ¼ of the next). "Names no place": `package:path` keys and anchored values (`packages.av` +121). A closure collect's set rides the program's row. | Tiny program into a 28-package store: **0.65–0.80 s → 0.09–0.10 s**, store 150 → 42 MB; "32,874 row decodes to keep ~16 rows" eliminated. | Red against batch members (#1201 × #1229 interaction, batch AC closed), then conflicts. Batch AN's seal-by-size is the interim. | **Port** 284ac586 (minus what AN changed) + 56c8f1a1 + 50e6feee. It directly fixes the handoff's "a warm edit's cost grows with the store's AGE" (§7, §11 seal-threshold question). Re-measure the aged-store edit after it. | port, then close | S1 (aged store), S3 |
| `store-handup` / PR **#1101** (DRAFT) | `avra cache export` (one segment of rows over a base); CI shards hand store segments up and down. | `export_test.av` 37/37 on a Sprite. | Only provable on a main run. Batch T carried it and did not land (5/158 on hd-clean). | Nothing for S1–S4. A CI-cache optimisation for later. | close (learned; re-file under DB 11 if wanted) | — |
| `own-db-law` / PR **#479** (DRAFT, 6 conflicts); local 9ec114ee, `db06-own-db-law` d4e9046a | The own-Db law: a read of a Db made before the outermost open query refuses ("a query reads its own Db; a Db made before it opened is another query's input"). | `check packages/cli` makes 0 cross-Db reads. read-cost `row.unheard` 28→31. | 1/42 landed. A rebase plus read-cost re-measure owed. | Port at S5 (DB 10/12, the kernel purity laws, L10). Not needed for S1–S4. | keep open for S5 or re-file | S5 |
| `db06` #618, `db06-step4` #642 (MERGED); `db06-633b`/`db06-step3` #633, `db06-670`/`db06-stamp` #670, `db06-corpus` #686, `db06-fp-str` #728, `db06-frame-pointers` #726, `db06-misses` #679, `db06-qtrace` #653, `db06-scan-store` #731, `db06-store-stats` #725, `db06-unitkind` #688, `db06-4b` #678, `db06-seal` #749 (all CLOSED), `exp-db06-stack` | DB 06: `Store.keep_reading`/`get_valid`, saved docs answers, stamps, the corpus, the reverse index in body v4, `explain --stats` store traffic, etc. | `.57.175` CLOSED: 06 landed (#618, #642, #768, #788); `stamp_attack` 5/5. | — | All **landed** (86–100 % each; db06-seal 134/195 and db06-scan-store 7/11 are later rewrites). Nothing to port. | close all | — |
| `db-06-step5` #1145, `db-06-rest` #1146 (CLOSED) | Producer stamp covers runtime C; package C is a read set; §6.8's one-query rebuild counted. | 2nd compiler 215/380 foreign hits → 0/311. Warm unchanged = 0 rows; one leaf moved → 30,320 rows. | — | **Landed** (55/67, 124/129). Open gap: `CodeGraph.hash` answers `digest_of_name` for a CallRt row. | close | — |
| `db-04a1-one-kernel` #316, `db-04a2-fixed` #322, `db-04a2-followup` #323, `db-04a3-replaced` #328, `db-04a3` #331 (MERGED); `db-04a2-owned-runs`, `db-04a2-rebased`, `db-04a3-one-db`, `db-04a3-pre-rebase` (no PR) | DB 04a: one kernel, owned writes, replacement marks. | Merged. | The unmerged variants are rebases/alternates of the merged ones (506/862 and 131/428 landed). | Nothing. `db-04a3-one-db` 1f258f98 ("a Db's kernel is its own or its owner's") is the only unique idea; it is moot at DB 12. | close all | — |
| `origin/recover/wt/avra-db06-wip` 284cf03e, `…db06-step3-wip`, `…db06-stats-wip` | Uncommitted snapshots of db06 worktrees. | — | — | Superseded by the landed db06 series. | close | — |
| `perf-floor` 720a9eb8 | An input digest kept beside `avra_io_stamp` (size/mtime/ctime/inode), so an unchanged check STATS instead of reading. A 2 s racy window. | Unchanged floor **90/95/88 → 65/56/56 ms**. Inputs 38.8 → 4.1 ms. | Not on hd-clean. Owner rule 10-13 (memory "follow the DB design doc"): **no stat-first**. | Do not port. It contradicts the owner rule. Cite the measurement only. | close (learned) | (S1 floor) |

### C. DB 07 (per-declaration answers; the hold) — partly S3, cited for S2

| ref / PR | what it did | proved / measured | why failed / stalled | PORT | close? | step |
|---|---|---|---|---|---|---|
| `db-slice` ec276593, `db-07a` 14997fe0, `db-07e-producers` 36842105, `db-07f-files` f0de2b66, `db07e-keyfix` (#580 CLOSED, doc-only) | 07a/07d on-demand hold, producer rows, names-only walk. | `.57.176` 10-21 verdict: "all 31 commits on db-07e-producers are LANDED or SUPERSEDED" (#832, #857, #869, #1031). | — | Landed (75–86 %). Nothing to port. | close all | — |
| `analysis-dissolves` / PR #1100 (CLOSED) | 07f(b,c): an Analysis holds its workspace; a fn lowers from its own range's facts. | — | — | **Landed** 37/37. | close | — |
| `lowered-said` 3ba9448d | LoweredSaid (units kept as saved answers, judged under `AVRA_DB_VERIFY`), a Writes answer, AVRA_LEAVES + `tools/digest_diff.py`. | — | — | Landed 623/698. | close | — |
| `db-07e-closure` / PR #1175 (CLOSED) 6c7a682d | "The read set settles the hold". | `.57.176`: the delete as designed **broke 8 cache-attacks** (kr kv tw pk gi vd hc drm). 07e is 07d's remaining half: the **transitive compile-time-run closure + pending-read forcing must move into the by-name walk first**. | Refused by its own lane. | The lesson feeds S3 and S4: `settle_holds` carries two laws; delete it only after the closure moves. | close (learned) | S3/S4 |

### D. DB 08 / 09 (S4)

| ref / PR | what it did | proved / measured | why failed / stalled | PORT | close? | step |
|---|---|---|---|---|---|---|
| **worktree `avra-errors-voices` on `db08a-verdict`** (branch at 0f4e9317, 0 commits; ALL WORK UNCOMMITTED). Older snapshot: `origin/recover/wt/avra-db08-verdict-wip` 30dab63c | **DB 08a Verdict.** Staged: deletes `manifest_key` / `keep_manifest` / **`confirmed_key`** / `manifest_stands` / `ManifestEntry` (build.av −138). Factors `sources_of(closure)` and `objects_of(closure)`. derive.av reads `store.get_valid(Stored.Unit, verdict_key, verdict_now)`. Unstaged: **untracked `compiler/verdict.av` (79 L)**: `verdict_key(under)` names the program and no input; `verdict_reads` lists every read through the **input door** (`InputName{kind: Compiler/Text/Listing/Embedded/Octets}`) at its digest; `verdict_answer` is a `Family.Verdict` cell; `verdict_now(name)`. Also a `Verdict` `@family`, `named_verdict()` AnswerRef in leaves.av, and `verdict_verified` in workspace.av. | Not measured. | Lane abandoned mid-way (2026-10-19). Its base is main@0f4e9317, 75 behind. `.57.177`: "Roots exist on NO branch" (true: it was never committed). | **Port as S4's first rung**: verdict.av + the build.av deletion + the derive.av swap. It **replaces `program_key`/`confirmed_key`**. Don't add a new `@family`: make Verdict a saved answer per A16 / DB 12 (the `@family` count may only fall). **Conflict to resolve with S1**: S1's plan extends `confirmed_key`, which this deletes. P6 answer: make S1's per-file **token digest a door read kind** (`InputKind.Tokens`) in `verdict_reads`, so a comment edit leaves the Verdict standing. One mechanism serves both steps. | commit to a branch off hd-clean first (the worktree is the ONLY copy) | **S4** (+S1) |
| `db08a-canon` / PR #1095 (CLOSED) bb36150f | The formatter's canonical verdict is a named answer with recorded reads (`canon_key` gone). | — | — | **Landed** 56/56 (`canon_key` has 0 hits on hd-clean). | close | S4 |
| **`db08c-proved` / PR #1097 (CLOSED)** 010d560e, 4ff2a5bf | DB 08c: the suite's evaluator agreement is a **row kept with its reads** (`Stored.Unit` under (proved, compiler, program), `keep_reading` over the program, its `.expected` and every file it reaches). `proved_key` and the proofs dir go. `suite_proofs_test.av` (61 L). | — | 1/52 landed. Closed unmerged (no reason in the PR). "The pipeline that hands proofs between jobs is a separate change." | **Port** (suite.av, store.av, test). It is DB 08's `Proved` root. `proved_key` still has 2 hits on hd-clean. | close after port | S4 |
| `db-08` / PR #793 (MERGED) | The Lifted answer named; a durable name reads the NAME's bucket. | `.57.176`: 07b S5 Resolved 514/514 … Lifted 434/434, 0 mismatched. | — | Landed. | close | — |
| `db-09` / PR #812 (MERGED) a0d1f373 | Every pass reads the declaration it names; the whole-row read is retired. | — | — | Landed. | close | — |
| **worktree `avra-db-09`** (detached at 9cdec783, STAGED). Older snapshot: `origin/recover/wt/avra-db-09-wip` d54260bd | Deletes `reads_rows_whole` / `reading_whole` (LiftLowered/Lifted/Settled were the last whole-row readers). Adds `tests/lifted_naming_adversarial_test.av` (80 L, 4 cases: Lifted is a named answer, spelling round-trips, names the annotation and no position, is durable across two workspaces). | — | — | **Landed**: `reads_rows_whole` has 0 hits on hd-clean, and the adversarial test is present on hd-clean. The worktree is stale. | remove the worktree (ask: it is dirty) | — |
| **`settle-closure`** cce4f3d3, 21a75a8c (no PR) | **DB 09: a settlement's name reads stand as ONE digest cell.** The frame gathers the thousands of Named reads a derive's run makes and records one read of a live digest over the buckets. cce4f3d3 makes grouped name reads one verb over an owner's family and id. (Its first 3 commits, 07c References, landed.) | **Settled's longest read list 15,807 → 3,420 (p99 12,948 → 2,206)**, cold cli. Keeper limit 3,000 (`tools/read_lists.ceiling`). | Never PR'd. The DB 09 commits are 0/22 in workspace_analysis.av, `settle_closure_test.av` is absent, decls.av is 1/30. | **Port 21a75a8c + cce4f3d3** (leaves.av, workspace.av, workspace_analysis.av, decls.av ~+65, test, ceiling). It is the A4.2 blocker: Settled is the one family over the read-list limit. | close after port | **S4** |
| `db-09-settled` / PR #1156 (CLOSED) | Docs: Settled's save is no `@query`, and the cycle face is `memo.ask`. | Leaves Settled 549/549 on names; settle-write 549 runs, 0 filed rows; typedsaid valid 29419 / recomputed 2178 / mismatched 0 in a fresh process. | — | **Landed** (A4.2b is in the doc). **Option C decided 10-22** (`.57.178`): Settled stays a NAMED SAVED ANSWER via `Answers<Settlement>` + `ran_lasting` + `memo.ask`, wire `settlement_enum_wire` (already registered). | close | S4 |
| `db09` (local) 0588cae0 | A red witness: a comment above an annotated record re-runs 3 Lifted rows. | Red by design. | Never landed (0/27). | **Port** `compiler/tests/lifted_reuse/reuse_test.av` as S4's (and S1's) receipt for Lifted. | close after port | S4/S1 |
| `db-09-lifted` / PR #1135 | (see the verdicts above) | | | LANDED | close | S4 |
| `db-170-over` / PR #1062 | (see the verdicts above) | | | LANDED | close | S5 |

### E. DB 10 / other worktrees

| ref / wt | what | verdict | step |
|---|---|---|---|
| `avra-db10` (branch `db10-hygiene` = bd6b4df4, 0 commits) | Dirty: `core/rebuild.av` +1 (holed marks for a filled type). Untracked `enums/tests/type_origin_template/` and `std-relation/tests/relation_named_like_import/`. | Small fixes, unrelated to the store. Hand to the nodes / DB 10 lane or drop. Ask before removing. | S5 |
| `avra-db02-explain` (branch `db02-explain` 154048b8) | Dirty: `explain_test.av` +18 (labels a `--why` page prints), `cache_walk.av`. | DB 02 explain tests. `cache_walk.av` is deleted by A16 (DB 02). Port the test only if `explain --why` survives. | — |
| `avra-db-time`, `avra-db-rows` | Dirty edits to `packages/std-db` (the user-facing DB package, not the compiler's). | Out of scope for the compiler DB; route to the std-db owner. | — |
| `avra-nohold` (`hd-nohold2` 8b0fab71) | Dirty: `sig()` reads `decl_with_body(d)` after the parse attaches. Untracked `tw_*.sh` probe scripts. | Equivalent fix landed on hd-sigfix as bf13082b. hd-clean already has `63d74a94` (held sig from record). Belongs to the hold-cluster harvest. | S3 |
| `avra-07a-gather` | See `db-07b-typed`: its one dirty hunk is the `decl_from_ref` mint fix. | Port with S2. | S2 |

### F. Ticket status (tasks db)

| ticket | state | the line that matters |
|---|---|---|
| .174 DB 05 store | IN_PROGRESS | **DB 05 COMPLETE 2026-10-21** (05a #1158). Unchanged floor 56 ms on perf-floor (unlanded, stat-first). Floor's floor ≈ 31 ms (grammar assembly 16 ms + process start 15 ms). |
| .175 DB 06 | CLOSED | Landed #618 #642 #768 #788. The `.210` requirement (save Lowered IR so a build reuses a check) is still open. |
| .176 DB 07 | open | 07a–d landed. **07b Typed save NEGATIVE: restored 0, null-digest blocker, ceiling 473–794 ms.** **07e as designed breaks 8 attacks; the closure must move first.** |
| .177 DB 08 | OPEN | "Roots exist on NO branch". Correction: Verdict exists **uncommitted** in `avra-errors-voices`, and Proved on `db08c-proved`. |
| .178 DB 09 | OPEN | **Option C decided** (Settled = named saved answer, no `@query`, no Db owner slot). `kept_settle` deletion owed. |
| .181 DB 12 | OPEN | Ceiling 37 at 10-08. Today `@family(` has **46 hits** in hd-clean's source (grep count includes tests/docs; re-count with `make families`). |
| .203 retire the durable stopgap | IN_PROGRESS | **Done in fact**: `rows_alone` / `unsettles_restored` have 0 hits on hd-clean (#642). Close it. |

---

## BEST EXISTING PIECES

### STEP 1: comment-edit fast path (token row, warnings from facts, a wire pair)

**Already on hd-clean:** `compiler/token_place.av` (`TokenPlace`, `Anchored`, `anchored_at`,
`placed_in`, `token_digest`), `filesaid.av`'s `keep_warning_facts` / `warning_facts_of` (over
`diag_facts_wire`, declaration-anchored), the record's `syntax` column (eaf783a4), and
`build.av`'s `confirmed_key` / `program_key`.

**No prior work exists for steps A, B or C.** Searched all refs with `git log --all -S'trivia_only'`,
`-S'token_digest'` and `-S'input_trivia_only'`: only hd-clean's own 7c3bcd8d and the handoff
doc. Experiment 12 (a token row plus `trivia_only`, a net loss) was never committed.

Start from:
1. **The wire pair template:** `rel_loc.anchoring_wire/anchoring_of_wire` in `codecs.av`
   (`derived(name, exemplars, labels, wire, of_wire, same)`). Copy it for
   `token_place.token_place_wire/token_place_of_wire` with `TokenPlace`/`Anchored` exemplars
   (`@derive(Exemplar)`). Missing: the wire itself, and a `DiagFacts` wire whose `Loc`s cross as
   `Anchored` (today `diag_facts_wire` → `loc_wire` needs `decl_from_ref`).
2. **One stamp:** `origin/hd-sigfix` **2913a0a2** (`WIRE_*` + `store_wire()`). Port it so the new
   facts-row wire is a line in the one table, not a second version int.
3. **The keep cost (220 ms on cli):** `origin/hd-sigfix` **f31e21f5** ("a file whose row stands
   owes nothing") and **2eb3161e** ("an unchanged answer is not filed again"). Both need
   re-basing; they are the pieces of the cut that touch only `keep`.
4. **Aged store:** **#1201** (`store-open-index` 284ac586 + 56c8f1a1 + 50e6feee). Without it the
   measured edit grows with store age, so a 300 ms target can pass fresh and fail aged.
5. **Do not extend `confirmed_key` blindly.** The DB 08 Verdict WIP (`avra-errors-voices`) deletes
   it. Design S1's token check as a **door read** (`InputKind.Tokens`, digest = `token_digest`)
   in the verdict's read list, and S1 lands as rung 1 of S4. If S1 must land first, keep the
   check in one predicate (`input_trivia_only`) that `verdict_reads` can later call.
6. **Receipt for Lifted under a comment:** port `db09` 0588cae0's
   `lifted_reuse/reuse_test.av` (red today: 3 Lifted rows re-run).

### STEP 2: saved per-declaration analysis (typed rows, derived codec, early cutoff)

**Already on hd-clean:** `@codec` in std-relation (#1150 lineage). `@std.relation.stable`'s
`Scope`/`Writer`/`Reader`/`dense_read`/`written_dense`/`encoded_with`/`decoded_with`.
`Store.keep_reading`/`get_valid`/`reads_of`. `rows_db.leaves_of`/`leaf_digest`.
`leaves.av`'s `named_typed`/`typed_says` (the VALIDATE-only channel from #793; it never restores).
`first_moved`. `settlement_wire.av`'s `decl_ref`/`decl_from_ref`.

Start from, in this order:
1. **The executor:** `origin/hd-sigfix` **e6929af0 + 6e3685d5**, `compiler/facts_codec.av` lines
   1–440 + `tests/facts_codec_test.av`. Port verbatim. One executor per direction, no generated
   per-type code, so it avoids the build OOM recorded in 0272f17d. Missing on hd-clean: only
   `WIRE_FACTS` (port 2913a0a2 with it). Register `facts_encoded_in/facts_decoded_in` in
   `codec_pairs()` in the same commit (`make codecs` refuses it otherwise).
2. **The save/restore glue:** `db-07b-typed` 99504c18's **`compiler/typed_rows.av`** (`typed_row`,
   `typed_restored` via `get_valid(…, leaf_digest)`, `keep_typed` via `leaves_of(deps_of(Typed))`).
   Its APIs exist on hd-clean, except `hold.typed_made`, which must become "typed in this process"
   from the kernel. Use it **instead of** hd-sigfix's `facts_kept`/`facts_stands` (those need
   `saved.av`'s `saved_name`/`saved_read_key`, which are not on hd-clean and would be a second
   naming registry beside leaves.av's `AnswerRef`).
3. **The blocker that made typed rows inert (restored 0):** `by-name-store` **276792ca** (kernel:
   a never-settled key stands on its saved answer's reads). Port it. Without it, every row whose
   read is a held/unasked answer has a null digest and never restores (`.57.176`, 10-21).
4. **A decode fix:** `avra-07a-gather`'s uncommitted `decl_from_ref` hunk (mint the file a wire
   names). A restored fact that names a declaration in a held file needs it.
5. **The generator speedup** (for later derived codecs): `hold-delete-keep` **13199b00**
   (`collect_kinds` linear). It lands on its own.
6. **Granularity law** (ONE_STORE + 0272f17d): the row is a plain `Stored.Unit` per declaration,
   filed beside its file, **never a family answer that stands alone**. That is the 7.9 GB shape.
7. **Expectation, measured:** bodies were 473–794 ms of a 4.5–6.8 s warm check when db-gather
   measured it; on hd-clean `bodies` is 234 ms (cli) and 330–350 ms (std-avrac). S2's own win is
   ≤ that. Its real value is enabling S3 (a deleted hold needs typed answers to stand without a
   re-type).

Not to start from: `db-stored`'s TypeFacts `@codec` (OOM), `hold-delete-typed` f10f8b04 (a
family-answer save, the OOM shape), `0e2f6f70` (a budget waiver).

### STEP 4: DB 08/09 (program_key and kept_settle.av replaced by Settled/Lifted/Verdict/Linked)

**Already on hd-clean:** the `settlement_enum_wire` / `lift_result_wire` pairs registered.
`@query -> LiftResult` saves (#1150). `named_lifts`/`spelled_lift`/`lift_arg`. The canon verdict
as a named answer (#1095). Lifted named, and every pass reading the declaration it names
(#793, #812).

Start from:
1. **Verdict (replaces `program_key`/`confirmed_key`):** worktree
   `/Users/tristan/projects/tristanMatthias/avra-errors-voices` (`db08a-verdict`, **uncommitted, the
   only copy**). It holds `compiler/verdict.av` (untracked, 79 L), the staged build.av deletion
   (−138), the derive.av `get_valid(verdict_key, verdict_now)` swap and `sources_of`/`objects_of`.
   **First action: commit it to a branch** (a recover ref suffices). Missing: it was never built.
   Its `Family.Verdict` `@family` must not raise the DB 12 count (fold it into the saved-answer
   path). `program_key` must be deleted with it, and the manifest's per-input confirmation
   (`entry_stands`) must become `get_valid` over the door reads.
2. **Proved:** `db08c-proved` **4ff2a5bf + 010d560e** (suite.av, store.av, `suite_proofs_test.av`).
   `proved_key` goes.
3. **Linked:** **no prior work on any ref** (`.57.177` says so; confirmed: no branch subject or
   file names Linked as a root). `.57.175`'s `.210` note names what it needs: Lowered IR saved,
   so a build after a check reuses parse/analyze/lower.
4. **Settled (kept_settle.av, A4):** `settle-closure` **21a75a8c + cce4f3d3** first (the read list
   15,807 → 3,420, under the 3,000 keeper only after more grouping). Then **Option C** (`.57.178`,
   10-22): `Answers<Settlement>` + `ran_lasting` + `memo.ask` for the cycle, named by
   `family_code_hash(Family.Settled)`, wire `settlement_enum_wire`. Then delete the line kinds
   `u f c m b e l` one per PR, then `kept_settle.av`. **Ungate `answers_named()`**
   (`AVRA_LEAVES`/`AVRA_DB_VERIFY`) or nothing is kept (A4.2b item 2).
5. **Lifted:** the value save is unblocked (#1150). Port the `db09` red witness (0588cae0) as the
   receipt. A4's `t` line (one per named type touched) is the first thing the conversion retires
   (A4.3: a comment above 1,000 types costs 603–612 ms, `keep` 0.20 s of it).
6. **Hard constraint from 07e** (`.57.176`, 10-21): `settle_holds` carries pending-read forcing
   and the transitive compile-time-run closure. A Settled / kept_settle deletion that removes the
   `r` line before the closure moves into the by-name walk reproduces the 8 failed attacks
   (kr kv tw pk gi vd hc drm). A4.2b: "the `r` line is the hold's, so it goes with DB 07's hold".
   S4's kept_settle deletion therefore follows S3, or moves that closure itself.

## Refs safe to close now (landed or learned)

#1135, #1062 (landed via db2b815e) · `codec-pr`, `db-03c-codec`, `db-09-decoding`,
`db-09-settled`, `analysis-dissolves`, `lowered-said`, `db-slice`, `db-07a`, `db-07e-producers`,
`db-07f-files`, `db07e-keyfix`, `db08a-canon`, all `db06*` / `db-06-*` / `db-04a*`, `db-08`,
`db-09`, recover `avra-db06*-wip` · learned: `perf-floor` (stat-first, owner
rule), `db-07e-closure` #1175, `hold-delete-lowered` (the lesson recorded above) · ticket `.203`.

**Not to close until ported:** hd-sigfix (2913a0a2, e6929af0, 6e3685d5, f31e21f5, 2eb3161e),
`db-07b-typed` / `db-gather-typed` (typed_rows.av), `hold-delete-keep` (13199b00),
`by-name-store` (276792ca), #1201, `db08c-proved`, `settle-closure` (21a75a8c, cce4f3d3),
`db09` (0588cae0), worktree `avra-errors-voices` (Verdict, uncommitted), worktree
`avra-07a-gather` (the decl_from_ref hunk), #964 (nodes), #479 (S5).

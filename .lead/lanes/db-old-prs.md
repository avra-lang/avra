## HANDOFF UPDATE (2026-10-13, parked again; no Sprite runs)
1. #645 registry_hole fixed (ac37f54d on families-component-scan). decl_grain_test still red: converted scans read sibling files whole through `use` (DB 12 order: read by declaration).
2. #643, #645, #655, #663 are drafts; state in bodies. #663 inherits #645's red and is held.
3. 4b experiment: branch exp-4b-scans (local, 869dd29c). Staging works; converted input-only family: +2.5–3 s cold, no edit-path hits.
4. Keep path: made_lasting reached for 506 settles (wrote=false, leaves=true). Loss is in keep_answer or in the edit-side restore. Cause line in .lead/db06.md.
5. Waits on: db06 splits the keep/restore loss (two traces); #642/#678 land; #645 grain redesign.
6. Local worktrees: ../avra-4b (exp-4b-scans), ../avra-645fix (fix-645-red pushed). Sprite released.

# db-old-prs lane

## HANDOFF (2026-10-13, parked)
1. Built: #643 ComponentNames, #645 ComponentScan (both @query, families-left 37 -> 35 on their stack). Drafts.
2. Built: #663 int-keyed scans on top of #645. Spelled keys per cold check 43,593 -> 0. Draft.
3. Built: #655 query key bound (4096 bytes, law voice at Db.arg, attack test). Draft, independent of #642.
4. RED: #645 CI. suites (std-avrac): decl_grain_test workspace cases; type.registry_hole at failures.av:543. keepers-a and gate also red. #663 inherits it.
5. Unchecked: world_test.av:409 (revision count) on the #663 stack.
6. Cold cost: #643 +1.0 s (path-keyed), #645 +12.4 s (text-keyed run), #663 +1.4 s parse / +1.5 s analyze over main. Over the 0.3 s bar for all.
7. Waits on: db06 step 4b (#642 durable Db) for any conversion to pay. Lead rule: no conversion lands before that.
8. Waits on: #645 green (decl_grain_test, registry_hole) before #663 can move.
9. Syntax stays unconverted until DeclId has a durable key (DB 07a).
10. Parked: no Sprite run held; the detached callgrind was stopped (own run, rc 143). Stand by for the lead's wake on 4b.

Per-call cost for db06 (callgrind not feasible on a whole cold check within bound): int key ~1,195 Ir/call, string key ~18,140 Ir/call (microbench, bench_int_key / bench_str_key). Push removal (one round): parse 19.2, analyze 28.1 vs int-key 19.8 / 28.8 vs main 18.4 / 27.3.


## 2026-10-12T18:41:39Z — hold-is-a-hold (PR #608, draft)
- Watcher: rule (e) no longer readies a draft; rule (j) a held title is never armed and an armed one is disarmed once per head; rule (k) a green draft held >2h is named once and again each UTC day.
- auto-merge.yml: a title matching DO NOT MERGE skips arming.
- tools/work land: marks ready, strips a leading DO NOT MERGE via REST PATCH, refuses a title that is only the phrase.
- pipeline-status: WAITING ON A HUMAN/LEAD (green drafts with age, red >2h with failing jobs, BEHIND >1h, no push >24h), cap line, exit 1 for a green draft >6h. Live read ran clean.
- watch.sh default cap 4000 -> 6000 (tools, CLAUDE.md, ROADMAP, review-round skill, pipeline doc). Dated docs left as written.
- Self-tests: pr_watcher and pipeline_status fixtures, reclaim/watch/work witnesses via make tool-witnesses; make keepers-static green locally.
- Not yet: CI on #608 (draft), and the watcher's live disarm path is unexercised.

## 2026-10-12T19:06:28Z — DB 12 step 1: the families table (origin/main, make families-left = 37, ceiling 37)
All 37 markers are in packages/std-avrac/src/compiler/families/families.av (lines 16–171). Body = the fn that calls `relation(Family.X)`; "none" = no such call found, so the body is not located and the family is C until read. Codec = answer type has a registered wire (codecs.av labels, checked by word match — approximate).

| family | key | answer | body (file:line) | reads / shape | codec | class |
|---|---|---|---|---|---|---|
| Source | FileId | SourceFile | workspace.av:1298 source() | the door: listed bytes | yes | C (input) |
| Parsed | FileId | Parsed | workspace.av:1319 parsed() | source + lex/parse | no | B |
| Items | FileId | List<DeclId> | workspace.av:1595 items() | decl rows | yes | C |
| Namespace | ModuleId | ModuleNames | workspace.av:1663 namespace() | recursive (start_recursive) | no | C |
| Visible | FileId | Namespace | workspace.av:1695 visible() | recursive | no | C |
| Resolved | FileId | NameFacts | workspace.av:1740 resolved() | recursive, mints expansions | no | C |
| Sig | DeclId | DeclSig | workspace.av:1843 sig() | held-record machinery | yes (PR 504) | C |
| Methods | DeclId | List<DeclId> | workspace.av:1926 methods() | recursive, mints generated impls | yes | C |
| Typed | DeclId | TypeFacts | none located (verifier workspace.av:627) | body facts | no | C |
| ConstTyped | settle-int | TypeId | workspace_analysis.av:766 const_type_at() | settlement | yes | B |
| Folded | FileId | TypeFacts | workspace.av:2133 folded() | recursive, db | no | C |
| Analysis | FileId | Analysis | workspace_analysis.av:189 analysis() | recursive | no | C |
| Settled | settle-int | Settlement | workspace_analysis.av:604 settle_verdict() | settlement machinery | yes | B |
| Lowered | ask-int | Unit | none located (workspace.av:647) | lowering | marker | C |
| Lifted | lift-int | LiftResult | workspace_analysis.av:946 lifted_at() | compile-time runs | yes | B |
| Manifest | int | Manifest | packages.av:65 manifest() | avra.toml input (input_loaded) | no | B |
| Receivers | unit | bool? | none located (receivers.av:52) | whole-program survey | yes | C |
| Expanded | FileId | List<DeclId> | expand.av:105 expanded() | recursive, MINTS decls | yes | C |
| Plain | FileId | Parsed | workspace.av:1340 plain_parsed() | parse under no words | no | B |
| References | unit | List<Ref> | references.av:73 references() | whole-program | yes | C |
| Failures | unit | Raised | failures.av:462 | whole-program fixpoint | yes | C |
| HeldSig | ModuleId | string | none located (workspace.av:1884) | held record | yes | C |
| Raised | DeclId | List<TypeId> | none located (workspace.av:917) | failures | yes | C |
| MethodDiags | FileId | List<Diag> | workspace_analysis.av:87 method_diagnostics() | method table | yes | B |
| LiftLowered | lift-int | Unit | none located (workspace_analysis.av:416) | compile-time | marker | C |
| Syntax | DeclId | int | workspace.av:1981 syntax() | pure: parsed(file) + decl range | yes (int) | **A** |
| Names | DeclId | int | workspace.av:1996 name_slice() | resolved(file) — recursive | yes | B |
| Marks | DeclId | List<Diag> | workspace.av:1116 marks() | WRITES decls.record_marks | yes | C |
| Admitted | FileId | Unit | workspace.av:1621 admission() | WRITES rows | marker | C |
| Named | int | Unit | none located (workspace.av:967) | decl name index | marker | C |
| ReadReach | unit | int | workspace_analysis.av:240 read_reach() | whole-program solve | yes | C |
| DeclReads | DeclId | bool | none located (workspace.av:918) | ReadReach's writes | yes | C |
| Input | int | Read | world.av:146 input() | the door | Read | C |
| BlockScan | int | bool | voices.av:697 file_lexes_block() | WRITES the scan store (insert_scan) | yes | C |
| ComponentScan | int | bool | voices.av:728 file_declares_component() | pure: listed text + lex | yes (bool) | **A** |
| ComponentNames | int | List<string> | voices.av:747 component_names() | pure: listed text + lex | yes (packed) | **A** |
| CancelReach | unit | int | cancel_reach.av:38 | whole-program solve | yes | C |

Class count: A 3 (Syntax, ComponentScan, ComponentNames); B 8 (Parsed, ConstTyped, Settled, Lifted, Manifest, Plain, MethodDiags, Names); C 26 (incl. Source and Input, which are the door, not queries).

Why these three: each body is a pure derivation of its key from data already read through a query or the listed text, with no recursion guard, no row write and an answer with a wire today. Caveat: Syntax keys on a DeclId (dense), and the DB 12 rule for dense-id keys has not been checked against @query's argument rules yet.

Step 2 not started: waiting for your go on A-class before converting. Stayed out of derive.av, record.av, kept_settle.av, workspace_analysis.av (read only), unit_rows.av, store/*.

## 2026-10-12T19:45:38Z — DB 12 step 2 heartbeat
- #612 ComponentScan (convert-component-scan, draft): keyed by the file's text, marker/verifier/arms gone, ceiling 36. First CI found a fmt difference (a one-line query body), fixed in 12bc0b81; the checks on that head are running.
- #617 ComponentNames (convert-component-names, draft, from main): same shape, ceiling 36, its two revision tests now check names and revision. CI not started yet when written.
- Measurements (cold and one-edit check, compute counts) pending: no free Sprite. Syntax probe not run for the same reason.

## 2026-10-12T20:16:09Z — DB 12 step 2 status
- #612 ComponentScan (head ba5785b6): the first CI's fmt difference was not the query body. The cli suite then failed the explain test on the direct-reader count (2 vs 3). I restored it to 3. CI for ba5785b6 is running; not yet green.
- #617 ComponentNames (head from main): std-avrac suite FAILS. Failures cluster on family ordinals: cache_walk_test hard-codes ordinals (family_word(26) == "Raised"), family_reflect_test pins the name list, and decl_rows tests (items hash) go null. Removing a family shifts every later ordinal, so the fixtures that pin ordinals need updating, and the decl_rows cause is not yet read.
- Measurements still pending: no free Sprite (asked the lead twice). The Syntax probe waits on the same Sprite.

## 2026-10-12T20:56:56Z — DB 12 #612 measured: no compute win, not releasable as is
- Clean before (main a233910a) vs after (ba5785b6), one-edit = comment appended to check.av, same cold cache: ComponentScan computes 505 -> 504 (query family 39); all computes 601 -> 600; store value ops 3488 -> 3541 (no cross-process hit).
- Cold wall 148 s -> 177 s (analyze 28 -> 54 s), one-edit 8 s -> 10 s. One sample each; not yet repeated.
- Finding: a @query over the relation Db is memoised per process; no kept answer is loaded across processes. The durable pattern in this compiler is BlockScan's digest-keyed scan store (ws.db.scan(store, digest_of(...))). The Component scans need that, not a @query.
- #612 CI: gate, keepers-a, test and std-avrac and cli suites fail on ba5785b6. cache-attacks not shown in the list. Not releasable; I recommend holding #612 and converting ComponentScan through the scan store.

## 2026-10-12T21:27:47Z — pipeline ticket: #612/#617 closed; prepare measured; Sprite tooling PR
- Closed #612 and #617 with the reason (per-process memo, no durable hit; DB 06 gates DB 12).
- (1) #626 is NOT landed: it was CLOSED, superseded by #606 (OPEN, bound raise 1500 s). So the bounds on main are still 900 s / 1500 s. Measured the latest checks runs' prepare logs instead: one generation ran 117 s, 183 s, 235 s, 293 s, 317 s and 329 s (six runs, none over 900 s; the "exceeded its 900 s bound" text in the logs is the script's own echo, not a runtime event). The trigger to lower the bounds is met on data; the change belongs with #606's review.
- (2) .github/workflows now travels in the Sprite sync (tools/work). Verified on avra-fastloop: make ci-invariants clean (4 invariants).
- (3) AVRA_PROBE_BUILD=one: one generation from the standing compiler, never cached, prints "one generation, not a fixed point". Every run prints "source <hash>, binary <sha>". Verified on the Sprite (probe 1 s on an unchanged tree because make reuses its objects).
- PR #628 (sprite-sync-probe, draft, hold title): all three, witnesses work_test (64 checks) and witness_work_run pass.

## 2026-10-12T21:31:53Z — batch-6 generation, and the queue guard
- Correction: the six fast generations (117–329 s) were GitHub RUNNER logs (4 vCPU), not Sprite numbers. The Sprite has 8 vCPU and 16 GB.
- batch-6 attempt 1 (run 38295630287): started from latest avrac-6ba1b39f (release fetched); exact objs cache hit objs-2d3ad288, the same objs key as a run that built in 293 s. The first generation was killed at 900 s; recovery from the seed (gen-1, gen-2) took the job to 1224 s. Variance on a 4-vCPU runner under load, not a fixed cost. Do NOT lower the bounds on six samples; revisit at ~20 runs.
- PR #629 (queue-guard, draft, hold title): land refuses while another non-draft PR's test check is running, unless --batch; pipeline-status prints LANDING NOW WOULD. Witnesses: work_test 67 checks, pipeline_status self-test passes, make tool-witnesses passes.

## 2026-10-12T21:32:06Z — generation tally (compiler-touching runs; run, generation seconds, path)
| run | branch | generation | path |
|---|---|---|---|
| 38310674175 / 38309606302 | ran-by | 317 s | latest release, one generation (runner) |
| 38309481208 | batch-7 | 183 s | latest release, one generation, cancelled |
| 38309224922 | main | 183 s | latest release, one generation |
| 38307454795 | nodes-seed | 117 s | latest release, one generation |
| 38307237300 | digest-ab | 235 s | latest release, one generation (failed for another reason) |
| 38305547472 | nodes-records-1a | 329 s | latest release, one generation |
| 38305154799 | perf-cons2 | 293 s | latest release, one generation (failed for another reason) |
| 38295630287 attempt 1 | batch-6 | killed at 900 s; 1224 s total | latest release (6ba1b39f), objs-2d3ad288 exact hit, then recover from seed: gen-1, gen-2 |
Next occurrence of a timeout: record the last 50 log lines before the kill and whether the step was compile or link.

## 2026-10-12T22:32:25Z — tally (post-#606) and the generation finding
| run | branch | generation | path |
|---|---|---|---|
| 38309606302 | ran-by (#606's own head cd363cc2, cancelled) | 317 s | latest avrac-edf3110e, one generation |
| 38313864514 | main push (eaff334c, #606 merged) | killed at 404 s by the memory cap (status 137); 798 s total | latest avrac-b1d6444b, make avra FAILED, seed recovery gen-1 and gen-2 |
| 38315193548 | digest-ab (#624 efb48129) | 668 s total | latest avrac-b1d6444b, same failure and seed recovery |
| 38316346930 | batch-8 (#638, 428d7b8b) | 139 s | latest avrac-c84c70ab, one generation, no failure |
- FINDING: the failures were the CAP, not the bound. `./avra` wraps every package-scale run in `tools/watch.sh` at `AVRA_CAP_MB:-4000`; the self-build peaked at 4022 MB and was killed at 137. The generation message "exceeded its 1500 s bound" is printed for ANY `make avra` failure (the echo is generic), so it misled. Fix: PR #640 (shim default 6000). The bound text in checks.yml should also say what failed; not changed here.
- DB 12 prep: main's families-left reads 37 (ceiling 37), not 32; the lead's 32 does not match this main. Recording it; working from 37 → 36.

## 2026-10-12T22:48:29Z — DB 12 smallest conversion (#643) and M1
- #643 families-component-names (draft, hold title): ComponentNames → @query; families.ceiling 37 → 36. `make families-left` on main reads 37, not 32.
- M1 (AVRA_QTRACE=1 AVRA_DB_GRAPH=1, cold `check packages/cli`, same Sprite, one build each): before (main eaff334c) 82,953 cells, 6,899,662 direct deps, 89,879,721 reads; after (#643) 82,995 cells (+42), 6,900,410 deps (+748), 89,940,610 reads (+60,889). The query makes the graph slightly bigger; no saved answer is loaded across processes.
- CI on #643 will still fail the ordinal-pinned fixtures (cache_walk, family_reflect, decl_rows); not fixed in this draft.
- PR #640 (shim-cap-6000, draft): the `./avra` shim's default cap 4000 → 6000. The main push's generation was killed at 137 (peak 4022 MB), not timed out; the message "exceeded its 1500 s bound" is printed for any make-avra failure.

## 2026-10-12T23:03:02Z — generation words, peak, and the #643 fixtures
- (1) #644 gen-failure-words (draft): the generation and bootstrap echoes name the status: 124 bound, 137 killed (memory cap or kill), other = failed with its exit. Fake-status cases pass.
- (2) PEAK: CI's killed gen-1 peaks (4022 MB run 38313864514; 4097 MB #624) were from the cached release avrac-b1d6444b (the lead's pre-#606 hypothesis; not verified which tree built that release). A post-#606 binary (sha fd74c791, main eaff334c) building packages/cli cold under `watch.sh 6000`: peak 2334 MB, status 0. So gen-2 from a post-#606 compiler is NOT >3 GB. Note a warm check reads 104 MB only because it examined nothing; a cold store is required.
- (3) #643 fixtures: family_ordinal(name) replaces the pinned ordinals in cache_walk, decl_rows, method_rows, written_where; family_reflect expects 36. The five test files pass on the Sprite (rc 0 each). #643 stays a draft until DB 06's rule (#642).
- families-left on main: 37 (ceiling 37). The doc's 32 is stale.

## 2026-10-12T23:04:05Z — stacked conversions, the 32 lines, and the class-B work order
- (1) #645 families-component-scan (draft, stacked on #643): ComponentScan → @query; ceiling 36 → 35 (families-left on this stack reads 35). M1 for the stack: measuring on the Sprite now.
- Class-A third member, Syntax (DeclId key): NOT converted. A query keyed by a local DeclId is refused by L4 (a local id lives in the saved answer that owns it); I have not run the probe the lead asked for, and I need the ruling first.
- (2) Doc lines saying 32 (for the next docs PR to correct; I did not edit them):
  - docs/2026_10_06_COMPILER_DB.md:39 (D2: "The 32 families move to the same spelling…")
  - docs/2026_10_06_COMPILER_DB.md:85 ("so all 32 families are saved")
  - docs/2026_10_06_COMPILER_DB.md:319 (§4.1 heading "The 32 families")
  - docs/2026_10_06_COMPILER_DB.md:635 ("as 32 families become queries")
  - docs/2026_10_06_COMPILER_DB.md:752 (DB 12 row: "`make families-left` prints N of 32")
  - docs/2026_10_06_COMPILER_DB_HANDOFF.md:81 (01e row, "make families-left p…", check the wording)
  Main's count is 37 (the ceiling is 37 at main; the tools/families.ceiling file is the source).
- (3) Class-B, one line each (blocker → the DB step that removes it; DB numbers from docs §8):
  - Parsed (FileId → Parsed): the parse tree has no wire codec; needs the record/span codec (DB 03 spans) before its answer can be kept.
  - Plain (FileId → Parsed): same answer shape as Parsed; blocked on the same codec (DB 03 spans).
  - ConstTyped (settle-int → TypeId): the key is a settlement ask, not a durable name; needs the settlement keyed by its name (DB 01e names) and the saved-answer rule (DB 06).
  - Settled (settle-int → Settlement): same settlement key as ConstTyped plus a non-scalar answer; needs DB 01e names and DB 06.
  - Lifted (lift-int → LiftResult): the compile-time run's units are not a wire today; needs the LiftResult codec (DB 03) and DB 06.
  - Manifest (int → Manifest): an input read through the host (avra.toml); needs the input's saved-answer rule (DB 06) and the manifest's codec.
  - MethodDiags (FileId → List<Diag>): the diagnostics carry Locs; needs the span codec (DB 03 spans) so a diagnostic can be kept.
  - Names (DeclId → int): keyed by a local DeclId and reads the resolved file; needs the L4 ruling (a local id) plus DB 06.
- M1 for the stack #645 (on the Sprite, same method): 83,039 cells (+86 vs main), 6,920,749 deps (+21,087), 90,019,866 reads (+140,145). Each query conversion grows the graph.

## 2026-10-12T23:29:24Z — cold cost of the conversions (same Sprite, per-phase ms summed from check --time)
- main: 115.0, 116.2, 116.8, 122.3 s (mean 117.6)
- #643 ComponentNames: 121.2, 120.5, 118.8 s (mean 120.1) → +2.5 s (+2%); above 0.3 s, waits for #642.
- #645 stack (+ComponentScan): 202.9, 201.5, 200.9, 194.4 s (mean 200) → +82 s (+70%). The ComponentScan key is the whole file text (137 KB spelling per lookup); it must change before it can be measured as acceptable.
- Ruling: Syntax stays unconverted until DeclId has a durable key (DB 07a). No third class-A conversion; the next class-A is Syntax, so I stopped converting.
- Span codec: written into .lead/decl-lower.md (what Parsed, Plain and MethodDiags need: one loc_wire extension, decl key by DB 01e name, total place(RelLoc), arena kept or re-derived). Asks listed there; nothing built.

## 2026-10-12T23:39:22Z — LAW for the DB 12 work order (from the lead's ruling on #645)
A @query is NEVER keyed by a text. It is keyed by the thing's NAME (a file's path, a declaration's durable name), and it reads the text through an @input (`scanned_text`, pushed by the workspace; the std.relation @input door, ced9bb24). The dependency is then recorded and the key stays small. Keying by the text spelled a 137 KB key per lookup: +82 s cold on #645.

Measured after the fix (same Sprite, three cold rounds each, check packages/cli --time, sum of per-phase ms):
- main: 117.6 s mean (115.0, 116.2, 116.8, 122.3)
- #645 ComponentScan keyed by path, text via @input: 129.8, 131.3, 128.7 → mean 130.0 s, +12.4 s. Still over 0.3 s; it waits for #642.
- #643 ComponentNames: its key was the TEXT (+2.5 s), now keyed by path with @input: measured next (cold_cnp.out).
- #643 ComponentNames keyed by path, text via @input: 116.5, 117.3, 121.9 s → mean 118.6 s, +1.0 s over main's 117.6 (the rounds overlap main's range: 115–122). Over the 0.3 s line on the mean, so it waits for #642 by the rule, though the gap is inside the noise.
- #645 stack (ComponentScan path-keyed): +12.4 s. The text push per call (set_scanned_text on every file_declares_component) is the likely cost; not profiled.

## KEEPER PROPOSAL for the law (not built)
1. The @query's key parameters, after the Db seat, must each be an int, a bool, or a declared NAME type (`type FileName = string`, opaque per the name law) — a plain `string` key is refused at the declaration with the law's voice.
2. A name type is a distinct type, so a text can cross into a key only by an explicit `FileName(text)` conversion, which the grep-able conversion site makes visible; the keeper lists every such conversion whose argument is not a path or a name literal.
3. A runtime size bound at the key site (e.g. 4 KB): a key past it traps with the law's words, so the static escape is also measured.
4. The keeper is a `make` target that reads @query declarations from `avra rules --json` (the registry), not a grep, so it counts what the compiler counts.
5. Open: whether a `Text` type should be introduced for the source-text inputs, so a @query over source text has no spelling for a key at all.

## 2026-10-13T00:23:20Z — profile of #645, and the key-size bound
- (1) PROFILE of #645's +12.4 s (per-phase ms from check --time, same Sprite, two runs each):
  - main: ast 16.1/16.1, sublang 2.8/2.8, parse 18.4/18.4, resolve 3.7/3.3, bodies 5.0/5.1, analyze 27.5/27.2, lower 39.1/37.9, keep 9.7/9.4 (sum ~121.8/121.5)
  - #645 path-keyed: ast 17.3/16.2, sublang 3.9/3.7, parse 20.6/19.3, resolve 3.5/3.3, bodies 4.9/4.7, analyze 29.4/27.7, lower 38.5/37.3, keep 10.1/10.1 (sum ~128.6/122.7)
  - Difference: parse +1.0 to +2.2 s and ast noise; the rest is within noise. The earlier +12.4 s mean was three rounds on a noisy session. Not confirmed as per-call pushing: call counts are NOT measured yet. The fix if the push is per call: set once per file per revision (memoize the push by path + text digest in the workspace).
- (3) KEY BOUND (draft PR #655, query-key-bound):
  - Data: on the path-keyed stack, one cold check spells 43,593 query keys, largest 362 bytes, total 12.7 MB. On main, zero query keys are spelled in a cold cli check (no @query on that path).
  - Bound: 4096 bytes (PATH_MAX). A key past it traps at Db.arg with the law's words.
  - Attack (tests/key_bound): a 5000-char text as a @query key spells to 20006 bytes, trapped, exit 2. The .refuses carries the measured length.

## 2026-10-13T00:48:03Z — DB 12 experiment: does a converted family pay across processes? (A = db06-step4 unconverted, B = db06-step4 + #643 + #645)
Same Sprite, 3 rounds interleaved (A,B,A,B,A,B by label: A2 B2 A3 B3 plus one A1/B1 edit each), per-phase ms from `check packages/cli --time`. The unchanged check is a check-result cache hit (examines nothing), so only the cold and one-edit runs carry numbers.

| phase (ms) | A cold r2 | A cold r3 | B cold r2 | B cold r3 | A edit r2 | A edit r3 | B edit r2 | B edit r3 |
|---|---|---|---|---|---|---|---|---|
| parse | 18001 | 17761 | 19922 | 19530 | 0 | 0 | 0 | 0 |
| analyze | 26613 | 26287 | 28474 | 28353 | 456 | 431 | 448 | 423 |
| load | 1 | 1 | 1 | 1 | 1901 | 1826 | 1896 | 2040 |
| lower | 39207 | 37777 | 38167 | 37984 | 2209 | 2209 | 2243 | 2258 |
| keep | 9925 | 9122 | 9736 | 9728 | 94 | 92 | 95 | 104 |

Read:
- EDIT PATH: no difference beyond noise (load 1.83–2.04 s on both, analyze 0.42–0.46 s on both). A converted family does NOT make the one-edit check faster; the edit path is dominated by load and lower, not by the scans.
- COLD: B is slower: parse +1.5 to +2.0 s, analyze +1.9 to +2.1 s, both rounds. This is the cost of writing and keeping the converted answers on the cold path.
- RESTORE: the load phase on the edit path is ~1.9 s on both trees; no separate restore phase is visible, so the restore cost cannot be read from phases. The store hit line (`Q store hit|miss <family>`) is still not on db06-step4 (asked in .lead/lanes/db06.md); without it the hit counts are unmeasured.
- VERDICT for the class-B order: a converted family does not pay yet on the edit path, and the cold path pays about 2 s. The class-B conversions wait for DB 06's store-hit line and a measured hit count.

## 2026-10-13T00:49:11Z — are ComponentNames/ComponentScan SAVED? No. The experiment tested nothing.
- A @query is durable only when (a) its answer is decodable (bool, Str, List<Str> are: relation.av:361), (b) code_hash is non-null, and (c) its Db's Durable hooks are NOT transient (query.av:111 → ran_lasting, db.av:674).
- Our rows_db is `new_db()` (decls.av), which is `made(transient())` (db.av:210 and the transient hooks at db.av:190): the Db keeps nothing past the process. So zero cross-process hits is the expected result, not a measurement.
- Production never builds a durable Db: `durable_db(...)` appears only in answers_test (db06-step4). The compiler's `answers(store, parts)` (compiler/answers.av) is the per-FILE hook (KeyParts = module, path, text, runs, gathered, seen), so a durable scan needs one Durable per file, built per call.
- The cold +1.5–2 s (parse and analyze): the stack spells 43,593 query keys in one cold check (keyprobe, earlier); main spells zero query keys, so every key is a converted-scan call. ~2 s / 43,593 calls ≈ 46 µs per call of query machinery (spelled key, arg lookup, the input push). A per-call cost that size IS a defect in the wrapper, not the work.
- #653 is db06-qtrace (5bc4b3f0, store-level `Q store hit|miss`, pack.av). Not cherry-picked: without a durable Db for the scans, the line would count nothing for them.
- The durable design choice: BlockScan ALREADY saves its scan across processes through `ws.db.scan(store, digest_of(...))` (voices.av:700-715). The one durable path that works today is that digest-keyed store. The lead ruled that out as a second durable path; a per-file Durable (answers(store, parts)) is the other. One of the two must be chosen before ComponentScan/Names can be measured as saved.

## 2026-10-13 — int-keyed scans: draft #663 opened
- Branch `query-int-keys` (711d8f39) pushed; draft PR #663 stacked on #645, title "DO NOT MERGE: families: scans keyed by an int fingerprint — no path spelled per call".
- Spelled keys per cold check: 43,593 -> 0.
- Cold phases, 3 rounds mean: int-key parse 19.8 / analyze 28.8; main 18.4 / 27.3. Still +1.4 / +1.5 s.
- One round with the scan input push removed (uncommitted, timing only): parse 19.2 / analyze 28.1. One round, inside noise; push is at most part of the gap.
- Not verified: #645 is red in CI (suites std-avrac: decl_grain_test workspace cases, registry_hole warning at failures.av:543); #663 inherits it. world_test.av:409 unchecked on this stack.
- Target ≤5 µs per hit call NOT reached at cold level; microbench int key = ~1,195 Ir/call vs str ~18,140 Ir/call.

## 2026-10-13 — 4b experiment (db-old-prs, local only, branch exp-4b-scans, commit 869dd29c)
- Stack: origin/db06-4b (d7610105) + db06's qtrace (be3886df) + the converted scans (query-int-keys tree), with the scans reading `file_text` via `ws.stage_text(path)` and keyed by path (string).
- Staging inside the kernel frame: WORKS. 12 runs, zero "source text was read before the workspace staged it" traps.
- Phase ms, 3 interleaved rounds, same Sprite session (A = 4b with scans reverted, B = 4b + scans):
  - cold parse: A 19.0 / 18.4 / 17.9 (mean 18.4); B 22.2 / 20.2 / 20.3 (mean 20.9) → +2.5 s
  - cold analyze: A 29.3 / 29.0 / 28.1 (mean 28.8); B 33.5 / 30.4 / 31.1 (mean 31.7) → +2.9 s
  - cold wall: A 70–73 s, B 74–78 s
  - one-edit analyze: A 453–469 ms, B 457–469 ms (equal); load 1.56–1.61 s A, 1.47–1.52 s B (equal)
  - unchanged: whole-check cache hit in both (0–1 s), so this round does not exercise the queries
- Store hits on the edit path for the converted families: NONE observed. B edit path: `ask 39` 1283 times, 1000 settles, all `compute`. The `db hit/miss` tallies match A exactly. Db kinds are Sig/Scan/Warn/Licenses/Findings; no component kind appears.
- Answer to the lead's question: a converted input-only family does NOT pay on this stack. It costs ~+3 s cold and saves nothing on the edit path. Why the answers are not kept (made_lasting, or the query reads rows) is not yet traced.
- Not run: a db06 trace-level `Q store hit|miss <family>` line (the qtrace in be3886df prints `db hit|miss <kind>` and `store value <ordinal> <digest>` only).

## 2026-10-13 — #645 red: partial fix
- Registry hole fixed in failures.av `seated_target` (spelled all 17 DeclKind arms), commit ac37f54d on local branch fix-645-red (../avra-645fix, from origin/families-component-scan). Not pushed yet.
- decl_grain_test red NOT fixed: the scans read sibling files whole when a `use` resolves (workspace.av:1365 and :1474 call file_declares_component/component_names on the declaring siblings). That breaks the grain law "a use reads the declaration, never its file". Needs a design change (scan only on the declaring file's own answer), not a one-line fix.

## 2026-10-13 — keep-site trace (4b, probe reverted, Sprite released)
- made_lasting is reached for all 506 settles of declares_component_of / component_names_of: wrote=false, leaves=true. No refusal there.
- So the loss is after the keep closure (keep_answer: slot.get() null or store.keep result), or on the edit side (restored: kept_answer, decode `proved`, leaves_hold). Not split; one more trace in keep_answer and one after `restored` would split it.

## DB 12 work order — decl_grain (recorded per lead)
- A converted scan must read by DECLARATION, not by file. The conversion made `file_declares_component` and `component_names` run on every declaring sibling during a `use` (workspace.av:1365, :1474), which reads each sibling file whole. decl_grain_test ("a use reads the declaration, never its file") is red on #645 for that reason. It is a defect of the conversion, not a test to relax.

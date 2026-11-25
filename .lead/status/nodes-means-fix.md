# nodes-means-fix status (DONE, nothing owed)

origin/batch-nodes-3 = 2a60e06b = ee8732a8 (fix) + merge of origin/main. Already pushed.

Both bugs, ONE cause: NodeFacts.use_shape() defaulted to UseShape.Nothing and expr_refs mapped it to [].
The old expr_refs catch-all gave every other node (Ident, Prop, Binary...) a plain Read use; those refs vanished
(false unused_import; cache fell back to whole-file reads => tw/lm/gi "reader read all the same").
Fix: default/variant is `Read`, mapped to UseKind.Read (core/facts.av, core/facts_derive.av, compiler/references.av).

Witnesses on Sprite avra-db-07a:
- references_test.av 29/29 (incl. 246/259)
- full `make avra && make cache-attacks-a` on ee8732a8: 477 builds, 0 failed
- same on 2a60e06b (post-merge head): 477 builds, 154 under a hold, 0 failed (248s)
- pipe_test.av 89/89 after merge conflict (pipe_test.av:114 kept our label + main's help line)
- check packages/cli: 0 unused_import; fmt --check clean

Open, NOT mine: `check --baseline tools/idioms.baseline packages/cli` exits 1 on pre-existing new sites:
compiler.duplicated_literal (core/expr/facts.av `fn form()` x2; core/store.av .Variant/.Typed PayloadIs arms),
compiler.one_body_arms (features/quote/lower.av `match class {`). Need fix or baseline decision; I can take them if told.

Old nodes-operators lane HEAD saved at origin/nodes-means3-wip. Sprite avra-db-07a bound to ../avra-means-fix.

## Update: idiom sites fixed and pushed
Fixed idiomatically (no baseline growth): form_body const (facts.av x2), binding_payload helper (store.av),
`.PatId or .Id` (quote/lower.av), `for id, ask in` (compiler/leaves.av), `parts.last()!` (sugars.av),
`xs.map("${it}")` (collect_branches test). On Sprite: `check --baseline tools/idioms.baseline` exits 0 for
packages/std-avrac AND packages/cli; fmt clean; collect_branches test passes. Pushed to batch-nodes-3.

## Ticket: @sealed Url draws no type.sealed in a memory package (started)
Worktree ../avra-sealed (sealed-memory, off origin/main 83395deb). sealed_test.av's `provided(...)` cases
(analyze_source path) already pass on main for `Url = string`, Point, Scheme, Box. packages/std-ui url.av (the
reported Url) is NOT on main (only in errors-voices' tree). BLOCKED on errors-voices' exact repro (asked via SendMessage).
Suspect: features/decls.av is_sealed -> annotation_home / annotations_of order (ask the declaration first).

## Sealed ticket CLOSED: not reproduced on main (no repro from errors-voices; sealed_test.av provided() cases pass). std-ui Url is not on main.

## Ticket: delegate derive settle budget (started)
NodeFacts is only on batch-nodes-3 (not main), so the worktree is ../avra-delegate off origin/batch-nodes-3.

## delegate settle budget: DONE, draft PR #924 (branch delegate-linear-main, off origin/main)
Measured (AVRA_DEBUG=1 `settle:` on `build packages/cli`, Expr's delegate): 13 methods 4.75 MB (15 methods 5.26 MB = over 5 MiB).
Cause: delegated_arm rebuilt, per variant, the method-wide call / recursion Codes / Self list (same for every arm).
Fix (std-meta delegate): per-method `Ways` shared by all arms. Expr: 4.75 -> 1.94 MB, steps 268k -> 105k;
slope per added method ~0.08 MB (was ~0.26): 15 methods 2.1 MB, 25 3.1 MB, 43 4.7 MB. Budget unchanged.
Witness: features/collects/tests/delegated_wide (30 methods x 40 members): PRE fix = delegation refused (methods missing),
POST = proved eval == native. collects suite proved, check --baseline std-meta/std-avrac exit 0.
Caveat: measured on the batch-nodes-3 tree (NodeFacts probes); PR is cherry-picked onto main (derive code is independent).

## #924 std-meta tests: `./avra test packages/std-meta` on delegate-linear-main, Sprite: rc=0, programs proved eval==native (captured to a file). Commented on the PR.

## Ticket: unwitnessed voices (lower.*, annotation.*) — STARTED, coordinating
Asked errors-voices which rows/files they hold; no reply yet; no edits made. Scope (baseline tools/voices.baseline no_witness):
lower.{entry_only,code_hash_const,host_fn_twice,host_fn_shadows,host_fn_answers,host_fn_unasked,component_checked},
annotation.{said,kind,warning,unsettled,meta,unplaceable,wrap_kind}.
Findings: witnesses live in compiler/dev/witnesses.av (Source / Package(files at /w) / Beyond(why)). Annotation voices need
@std/meta vendored (existing precedent: Beyond("...golden is <test path>")); lower.host_fn_* come from compiler/whole.av (build-time),
probably not reachable by the report()-level runner -> Beyond with the proving test unless a Package reaches it.

## Voices (lower.*, annotation.*): DONE, draft PR (branch voices-lower-annotation)
Witness.Built variant (package through lowering + warnings). Real witnesses: lower.entry_only, host_fn_{twice,shadows,answers,unasked},
component_checked, annotation.{said,kind,warning,unsettled,meta,unplaceable}. Beyond (reason in witnesses.av): lower.code_hash_const
(rides const.trap), annotation.wrap_kind (no annotation stands on a default/spec case).
Exposed no_help on component_checked/annotation.said/annotation.warning -> default help added. baseline -14, no line added.
Sprite: diagnostics==docs, voices report==docs, voices exit 0, witnesses_test 13/13, voices_coverage_test 8/8, idioms no NEW.
Note: docs/DIAGNOSTICS.md + VOICES.md regenerated here; errors-voices' #891/#895 regeneration will conflict -> regenerate at rebase.

## Sealed ticket RESOLVED (not a bug): a @sealed MODULE is a directory; src/urls.av beside src/main.av is one module, so nothing is refused
(CLI and memory package agree). Sealing module at src/urls/urls.av refuses in both. Witnessed in PR #932 (type.sealed row); baseline -1.

## Voices, the rest: DONE, draft PR stacked on #932 (branch voices-rest)
Real: block.parse, resolve.{block_word,reexport_*,kept_apart,private_apart}, manifest.{duplicate_package,no_target}, type.{component_format,
not_offered,within,isolated,pattern,host_absence,host_fn,syntax_action}. Beyond+test: parse.trailing, build.failed, language.defect.
DELETED dead registrations type.list_empty, flow.source_loop (never spoken). block.parse help added. Baseline -22.
Witness.Built(files, entry) now (entry null = no target). Sprite: docs==compiler, voices exit 0, witnesses 13/13, coverage 8/8, idioms clean.

## bindings trap: FIXED, draft PR (branch bindings-trap off main)
Trace chain: Resolved(56)->Visible(56)->Expanded(264)->Lifted(151)->Resolved(264). A resolve under an OPEN expansion sized tables short and was kept.
Fix in compiler/workspace.av resolved(): partial=Expanded open -> answer then evict_call. Repro now gives `core does not export map_cell` (true refusal).
Witness compiler/tests/partial_resolve_test.av: PRE 1/2, POST 2/2 (drives open Expanded directly; no small source-level repro found).
cache-attacks-a 477/0 failed, idioms clean.
Generalization answered in PR #948 body: kernel CAN see it (Verdict.Cycle + abandon) but tainting every frame above a cycle breaks start_recursive families that re-enter by design
(Resolved settles 4x in one run intentionally) and needs a whole-suite measurement; the safe form is a per-family opt-in registry. Kept the special case. Partial-answer soundness stated in the PR.

## compiler/tests dir OOM: FIXED, draft PR (branch test-dir-memory off main)
Hoard (addr2line on build/suite): compiler.store.body_read Held rows + map_cell<Held> in store/pack.av: packs() held one Pack per (root,print) forever; test workspaces mint
unique `unnamed-` prints -> 128 packs each re-reading the body index. Fix: workspace holds/releases its pack (store.av pack_holding/pack_released; Keys.held_pack; ended releases).
Receipt: workspace_test child 1689->40 MB peak (live 1758->29); whole dir 7043 MB killed(137) -> 2969 MB, 1469/1469 pass. cache-attacks 477/0, idioms clean.
Residual: whole-dir child still ends 2.2 GB live: 220/2202 packs held by workspaces never let go (non-test_workspace paths).
Note: /tmp/m*.out names collide across lanes (another lane overwrote one of mine) — use unique names.

## Rebase after #936: #932 rebased + READY (509da923); #941 rebased (base retargeted to main; carries #932 and #954 commits)
Docs/VOICES/baseline regenerated from merged tree on both. #936's new remedy keeper: Built arm in remedies.av; type.sealed help no longer backticks `==`;
component_format help reworded; syntax_action witness = undefined-rule voice. witnesses_test needs #954 (pack release) with ~150 package witnesses (6000 MB ceiling otherwise) -> land #954 first or with #941.

## collect by it.module trap (avra-8sb5.57.281): FIXED, draft PR (branch collect-module off main)
Cause: features/decls.av short_module_of = module_of(d).split(".").last()! — root module name is "" -> [] -> trap. Not generated-specific (in-package marks crash too).
Fix `?? ""`. Witnesses collects/tests/collect_module_root + collect_module_derived (old compiler: unwrapped absent; new: pass); support/src/seats.av added.
collects dir: 34 programs proved, idioms clean.

## PR-route failure (expr_children missing, #976 972fe062 / #916): IN PROGRESS
CI route (from the prepare log): published compiler of main (key avrac-831a2ac, restore-key cache hit) -> make avra x2 -> warm store -> prune (obj/bin 300MB, `cache clean` 2 revisions) -> tarball avra-build.tar.gz (build/ + .avra-cache, 1.6 GB) -> each suites job extracts and runs groups in a loop.
Failing group: std-avrac/src/compiler (7x type.method, NO unsettled voice), 90s in after "212 rule examples proved".
NOT reproduced so far: (a) lane Sprite incremental builds A=main~971 -> B=972fe062; (b) gen2 (identical bytes to gen1); (c) `cache clean` revisions=2; (d) cold derive settle bytes (max 2.8MB < 5MiB); (e) the REAL CI artifacts (avra-compiler + avra-build tarball from run 39148755475) on a Sprite, compiler group alone: no error (hit the 6000 MB OOM that #954 fixes).
Now running the CI group order on the real artifact (sprite:/home/sprite/ci-run.sh, logs ci2*.log).

## PR-route `expr_children` failure: CAUSE FOUND, FIX = draft PR #1014 (branch budget-ambient, off main)
Cause: the compile-time MEMORY BUDGET counts the process heap against the run's start, and `type_named` (workspace callback inside the run) leaves 3.4 MB of workspace state that the run is billed for.
core.Children.derive over Expr: 2.15 MB normally, 5,589,624 bytes with ambient (limit 5,242,880) -> cut at 65k/99k steps -> a cut inside a re-entrant expansion is HUSHED -> Expr's expr_children never exists -> `SyntaxArena has no method expr_children` x7, no budget voice. PR route (big restored store + whole-dir suite) trips it, main's push doesn't.
Repro: run 39148755475 artifacts (avra-compiler + avra-build tarball) unpacked on a Sprite, failing job's groups in order -> 21 errors; with the fix Children = 1,273,528 bytes, compile passes. (Compiler group alone on the fresh store passes; order matters.)
Fix: Machine.named_unbilled (interp.av). Witness: compiler/tests/settle_bill_test.av (pre 1/2 'budget: held more than 1048576 bytes', post 2/2). Lesson in docs/2026_10_11_THE_PIPELINE.md §6.
Follow-ups (not done): (1) a derive cut by budget in a hushed re-entrant expansion should speak annotation.unsettled; (2) the budget is still a process-heap measure for other allocation. 
Also still open from earlier: #954 (pack release) residual 2.2 GB; its first attempt to release the rest was abandoned (ended-hook released nothing new; own-pack-per-workspace variant OOM'd the Sprite twice) — needs a fresh look.
Note: Sprite avra-db-07a holds ci-tree/ + 1.6 GB tar in /home/sprite (ci-build.tar.gz, ci-avra); delete when done.

## #1014 follow-ups DONE, PR marked ready (rebased on main d638bf2b, post-rebase not re-run)
(1) silent cut: refused lift answers Spoken on reuse + hush_expansion wipes -> second expansion silent. Fix Workspace.lift_refusal (+ expand reads it). Witness silent_cut_test 1/2 -> 2/2.
(2) bill: callbacks into the compiler are exactly `named` (unbilled now) and `embed` (run's own data) -> heap delta is the run's own; exact owner accounting needs box-header ABI change (seed rung), not done, not needed.
Sprite avra-db-07a still holds /home/sprite/ci-tree, ci-build.tar.gz, ci-avra, avra_A etc.

## Sprite cleanup DONE (find -delete); doors PR = #1027 (draft): named_door/embed_door + Billing + doors_test keeper (3/3).
## #954 residual 2.2 GB: investigated, NOT fixed (no shippable change). Facts:
- holder tally (AVRA_DEBUG hold/release by pack print + QTRACE parse): 1099 holds, 1027 releases; 72 unreleased = 71 workspaces made by `anew()` restarts (tried_anew keeps the fresh one when it stands) that are open+never ended + the one standing one. WSALONE log: all 71 NOT registered through alone().
- Tried: (a) release in disarmed (no change), (b) restarts of a one-shot join the standing list (stands_with), (c) close the pack's rows at last release, (d) no registry pack for ended workspaces. Measured on the same tree, whole dir (1494 cases): #954 alone child peak 4142 MB / live-at-exit 4.11 GB / watch 5192; with (a)+(b) 3833/3.59/4811; with (b)+(c) 4127/3.83/5177; (b)+(c)+(d) 4274/3.94/5356 => noise-level, not shipped.
- Per-file runs (compiler_print_adversarial 3 MB, world_test 85 MB peak, live ~0 at exit) show NO leak: the 4 GB is cross-case accumulation inside the single whole-dir process, and packs are not it (rows persist after closing).
- Lead: dir still runs (1494/1494, watch peak ~5.2 GB < 6 GB ceiling; the dir passes on #954 alone). Next lead if wanted: AVRA_RC_GUARD site replay on body_read rows with a 2-file subset that leaks across files, not whole-dir.

## #954 hoard: HOLDERS FOUND by AVRA_MEM_STATS bisect (local branch `restarts` in ../avra-pr976, 3 commits on main f75fc836, NOT pushed per instruction)
Method: prefix/groups of the 111 compiler test files, `live at exit` of the test child; then singles; then site -> addr2line (idx_payload/body_read = a pack's rows).
Holders: (1) rule_fix_test alone left 2.5 GB live: rule_proof.after_program() made a workspace per proof (ir_proved/edits_proved/law_proved/repair_clears) and ended none -> now discarded when the verdict is in (66 MB live after). (2) codecs_test left 250 MB: codec_workspace() made a workspace per caller, ended none -> one-shot (62 MB after). (3) anew() restarts never ended (71) -> join the standing list; witness restart_ends_test 0/2 -> 2/2.
Receipt (whole dir, 1500 cases, on #954 + the three): test-child peak 4444 -> 985 MB; live at exit 3.93 GB -> 277 MB; watch peak 5567 -> 4996 MB (the remaining peak is the COMPILE phase, 4475 MB, not the tests). Before this session's fixes, #954 alone: 4142 MB / 4.11 GB.
Left: ~277 MB at exit (~4 packs across file boundaries); not chased.

## Compile-phase peak (4475 MB compiling the compiler's own tests): HOLDERS (report before fixing)
Reproduced only on a compile whose source changed (warm-store compile of an unchanged tree peaks 825 MB): probe = one const appended to core/ir.av, AVRA_MEM_STATS=1 AVRA_MEM_DUMP_AT=3800 -> report at the crossing (peak 3975 MB, list buffers 1791 MB + list boxes 1347 MB + strings 555 + bytes 250).
Sites (addr2line on build/avra), live at the crossing: relation.writer 288 MB (ONE Writer of 94k made) ; store.reads_known 185 (652k live) ; Kernel.closed_frame 142 (267k query dep lists) ; memory-pass Stack.is_empty 126 ; store.body_read 79+68 (the pack's rows) ; SyntaxArena.alloc_expr 60 ; features.empty_lists 61 ; distinct_keys 58 ; span_of 42 ...
Seal (store/body.av seal -> body_payload, framed, idx_payload): relation.Writer = Cell<List<int>> = ONE INT (8 bytes) PER OCTET with doubling growth; a 128 MB body.pack is a ~1 GB list (+ transient copy), and framed(payload) re-writes the whole payload into a second Writer (another ~1 GB). From the previous full run: writer site peak 1444 MB, list buffers peak 2535 MB. seal also builds `reads = [reads_of(pack, h) for h in held]` for all 645k rows at once.
So: ~3 GB of the peak is the compile's own analysis data (legit, the whole compiler's 700 files at once), and the seal adds up to ~2.5 GB at the END of the compile on top (Writer at 8 B/octet, twice).
"One derivation alive": not seen in the site table (no second derivation's rows), unverified for turned attempts.
Proposed fixes (not done): (1) Writer buffers octets in Bytes chunks (or Bytes.append) instead of List<int>: 8x smaller, no doubling copies; (2) framed() builds header+payload+check as a Bytes concat, never re-encoding payload through a Writer; (3) seal streams reads per family instead of materializing all.

## Writer/seal GO: NOT NEEDED on current main (333d29e9) — re-measured first
Same probe (const appended to core/ir.av) + AVRA_MEM_STATS on main 333d29e9: compile-phase peak 2657 MB (was 4475 on f75fc836). #1015 (store index and bound) already rebuilt the seal: body = [framed(head)] + sections concat (List<Bytes>.bytes()), rows framed individually, index as a string join; the big Writer is gone: relation.writer site peak 72 MB (893k small writers), not 1444 MB.
Remaining top peak sites: Kernel.closed_frame 145, memory-pass Stack.is_empty 127, writer 72, empty_lists 62, alloc_expr 61, distinct_keys 59, Table.keep(decls) 46, span_of 43+37 — all the analysis working set; list boxes 1219 + list buffers 1007 MB at peak.

## sublang 4-35 s cold variance: NOT reproduced in 11 cold-store runs on idle avra-db-07a; the compiler side is deterministic
Runs (cold .avra-cache each, `check --time packages/cli`): sublang 2.58, 2.94, 2.78, 2.72 s (rusage run) and 2.80, 3.59, 2.90, 2.83, 4.16 s (QTRACE run); ast 10.8-11.8 s; wall 58-61 s, user 51-52 s, sys 4.2-4.7 s.
Determinism: QTRACE event streams of runs 2-5 are byte-identical (md5), run 1 differs by one line (store open): same 693 parses, 778,027 asks. So no scheduling/order/cache-by-timing nondeterminism inside the compiler for this phase.
What `sublang` is: Workspace.parsed_under_blocks times block_words(f, first) = packages() graph load, directory listings (`listed`), `file_declares_component` file reads, `line_words` module lookups — i.e. FIRST-TOUCH I/O and package admission, nested in `parse`; wall clock (self.clock()). So it is the phase that moves with host I/O: /proc/pressure/io on the Sprite read some avg10 18-37%, full 16-34% (tasks stalled on I/O a quarter of the time), io_full_stall 11-15 s per 60 s run, loadavg 3.4 with only my run.
Likely cause of 34.8 s: a cold OS page cache / I/O contention at the moment the run touched the tree (or a concurrent heavy run on the same host). Needs db-gather's raw table with the run order + psi to confirm.
Proposals: (1) `--time` should print CPU time (rusage / process cpu clock) beside wall per phase; (2) the hard speed gate must judge CPU time (user+sys), not wall — wall here moves ±10 s from I/O alone; (3) record /proc/pressure/io delta in the gate's own log so an outlier is explained.

## CPU per phase in `--time`: LANDING 1 of 2 committed locally (branch cpu-time in ../avra-pr976, on main 333d29e9; not pushed)
No CPU clock exists in the runtime, so a row is needed -> the two-landing seed ladder: (1) THIS commit: `avra_cpu_ns` (CLOCK_PROCESS_CPUTIME_ID) in runtime/avra_runtime.c + its RtSig row (Unhosted) + regenerated avra_rt.h and features/rt.av; Sprite keepers rt-header, rt-ns, externs, vocab green. (2) AFTER the seed refresh: declare `extern fn avra_cpu_ns()` in @std/time, Phase gains cpu_ns, workspace.timed reads both clocks, `--time` prints "<phase> 11.2s (cpu 10.9s)"; the declaration cannot be gated before the seed knows the row.
Writer ticket filed: avra-8sb5.57.293 (Writer over Bytes, after #1028).
Waiting on ci-design: where the gate's own log lives for the io-pressure delta, and whether the backstop switches wall -> CPU (lead leans yes, I agree; whole-process CPU needs no row: rusage from the harness).

## Compile-peak holders, measured 2026-10-19 (std-avrac check, probe = const appended to core/ir.av, AVRA_MEM_DUMP_AT=2000; base main 333d29e9). No fix made: both are working set, not hoards.
- Kernel.closed_frame 127-145 MB: 243k query dep lists live of 244k made, ~55 edges each (570 B/list = 72 B of boxes + 8 B x edges). Inherent graph: closed_frame's slice only trims capacity. Shrinking it means a denser dep encoding (shared prefix / interned frames), not a leak fix.
- "Stack.is_empty$Scope" 127 MB is a MISNAMED SYMBOL: 0x100ef50 is `filled<T>` (core/lists.av, `[v for i in 0..n]`) folded (identical code) with 3 siblings and attributed to the preceding named fn. Callers: SideTable.new (`side_table`, core/side_table.av:33): 222k live of 463k made, ~62 cells each, held to exit (std-http: 35k live at exit, 14 MB). So it is the per-declaration fact columns, dense by the SideTable totality law, mostly seed (null) cells.
- NOT a memory-pass leak: native + eval probes of the pass's own shapes (pop() ?? empty_scope(), rewrite_top, reg-sized tables, body_ins comprehension) end at 0 live.
- Lever: a column whose cells are all seed needs no buffer. SideTable could hold its window as (lo, count) and materialize cells at the first non-seed write (holds/hi/length read count; folded/ids/lay read cells). Win = (columns never written) x ~600 B; unmeasured which fraction that is — one counter at settle would say. Max ~5% of the 2.6 GB peak either way.
- Side find: `wide grow by 0x10577eb: 2457 MB over 530 buffers` = grammar `filled$i` (std.grammar) churn, 36 MB peak, 0 live: transient, not retained.
- Method note: addr2line names the preceding SYMBOL for an unsymboled/ICF'd fn; objdump the address and read the calls before trusting a site's name.

## SideTable never-written measure (2026-10-19, main 333d29e9 + temp probe, std-avrac check, probe reverted)
Registry flag per `side_table` made, "touched" = any set/lay; read over the first half of tables made (stable ones).
- By COUNT: 92% untouched (185k of 200k at 400k made). By CELLS: only 32% (6.3M of 19.5M) — the untouched tables are the small ones; the written ones are the big bodies.
- Savings from a lazy window = ~6.3M cells x 8 B + ~185k x ~70 B boxes = ~60 MB of a 2.6 GB peak = ~2%, of tables that are also mostly freed before the peak. NOT a real share; lazy-window SideTable NOT built, totality law untouched.
- Later ticket (lead's call): closed_frame dep lists via interned/shared frames (127-145 MB, ~5%).

## Residue at exit (the ~277 MB): HOLDERS (2026-10-19; branch residue = hoard + 1 commit, ../avra-pr976, local)
Census probe (PACKS lines at every pack hold/release, whole compiler tests dir, 1500 cases): at the END `packs()` held 41 NON-EMPTY entries / 328,873 rows while only 2 workspaces held packs. The 39 extra were minted by `pack_for` for stores with NO holder (tests' `store_at`, cache cmd) and entered in the registry forever (release is by holder count; nobody held them).
Fix (commit on `residue`): mint_pack enters the registry only when a workspace holds the key; a holder-less store owns its pack. Whole dir 1500/1500 pass; suite child live at exit 304 -> 239 MB; live map_cell (pack indexes) 84 -> 6. NOT zero.
What is left (328k body_read rows = 40+34 MB, ~239 MB total) is the 2 held packs: `standing_one_shot` keeps the LAST one-shot workspace standing by design (its answers may still be read; the next one lets it go). Zero at exit would need the suite to end it (`one_shot_let_go()` at the end of the entry) - an accounting nicety, not a hoard.

## ONE DERIVATION ALIVE UNDER TURNED ATTEMPTS: VERIFIED (2026-10-19, Sprite avra-db-07a, `build packages/cli`, warm store then one edit each, AVRA_QTRACE + AVRA_MEM_STATS)
- Turning edit (appended `fn zz_probe_1() -> int { 1 }` to cli/commands/fmt.av): 6 attempt lines, attempts 0,1,2 reading 0/374/376 (turned twice). Edits 2 and 3: 3 lines, one turn (reading 379).
- Comment-only edit: 3 attempt lines (no extra turn on the first derivation).
- PEAK: turning 1341 / 1340 / 1340 MB, comment-only 1339 MB; live at exit 920 MB in all four. Site tables line up row for row (same live counts at the top sites: 203k/145k/170k/254k); only the "made" counts differ (more work, same residency).
=> A superseded attempt's rows are NOT live: the peak is one attempt, not a sum (the 5 GB-vs-2.2 GB case is gone). Nothing to fix. (920 MB live at exit is the final standing derivation, by design.)

## fn-value reach (branch fn-reach, commit 742664be, local; base origin/main 5c60d480)  2026-10-19
Targets: the 49 asked targets of `build packages/cli` (warm store + one edit; QTRACE census, temp code removed).
- Baseline reach 26,058 of 30,306 nodes (26,206/30,551 on the later base); without ANY hub edge 13,825.
- FnAddr box classes (1,785 sites): local 34%, passed straight to a direct call 36%, escaping 30%.
- Escape precision, simulated: sound subset (local dropped from hubs) 25,982; optimistic bound (local + passed-down dropped) 25,744 => ~1%. keeps-fact plan DROPPED.
- Real inflator: the `dyn` hub (`type_shape_key` gave every `Dyn` the one word "dyn"): 99 members, cutting it alone drops 6,652; next hub 648, rest <100.
- Fix: `.Dyn(_, trait_name) -> word_shape("dyn ${trait_name}")` (1 line, lower/code_hash.av). Reach 26,206 -> 19,887 of 30,551 (-24%); only 4 dyn hubs / 69 members remain, cutting them all adds just -324 (per-method dyn split not worth it). Fn-type hubs: 368 hubs / 1,880 members; all cut = 14,427 => ceiling ~5.5k more, needs field-sensitive flow.
- Tests: code_hash_test +2 cases (35/35); "an impl method of another trait it never dispatches moves nothing" fails without the change (34/35).
- Gates on Sprite: cache-attacks-a (477 builds, 0 failed), -b1, -b2 rc=0; `make witnesses` rc=0; fmt --check clean.

## features-a 7.8 GB peak (errors-cascade): NOT REPRODUCED (2026-10-19, Sprite avra-db-07a, 8 GB, base origin/main 5c60d480)
One `build/avra test` over the 13 `tools/shards.py --paths std-avrac/@features-a` paths, AVRA_MEM_STATS=1, four variants, all rc=0, 3,403/3,403 tests, 124/124 programs:
- warm store: largest process peak 2,659 MB; cold store: 2,640 MB; after a core/ir.av edit (all derives turn): 2,967 MB; with AVRA_SOUND_CHECK=1 (CI's env): 2,889 MB. Sprite free memory never under ~5.0 GB (so ~3 GB used by the whole tree).
- The 7.8 GB run is not this tree/shape. Asked errors-cascade for sha, store state, shim vs bare, concurrent load. Likely suspects: another process on the Sprite counted by the watcher, or their compiler.
Also: lead's note: field-sensitive fn-type hub flow SKIPPED (ceiling ~28%, ~5.5k nodes, ratio poor).

## seat_entry (P0 .295) FIX: branch seat-entry in ../avra-pr976, on batchE 3af5ec4f (2026-10-19)
- Cause: a `collect ... in closure` had no gathered-set digest (package_gathering returned null unless scope == package), so a held collector's baked object served the set another program wrote. `admit_scope`/`scoped` innocent (returns at once for closure).
- 18c555ba: Gathering.scope; package_gathering via gathers_across_files (Package|Closure); gathered_set uses g.scope; `gathers` line carries a trailing scope word (absent = package); load_gathered loads package files for package scope only.
- 76fc91f1: tools/closure_gather_attack.sh in cache-attacks-b1; pre-fix: program b prints [] not [knob] (x2). 108b4cbb: closure_entry_a/b programs in one `avra test` process: pre-fix `native != expected` (seat_entry's signature), fixed 102/102 + 19 programs.
- Gates: std-ui full suite one process 872/872 + 49 programs; cache-attacks-b1 rc 0; collects+lists+collect_scope 517/517; fmt clean.
- FOLLOW-UP (cost): programs sharing a library re-read its collector module when their closures differ (the record's gathers line is last-writer-wins). Keep one kept object per closure digest side by side (bounded) so both are served without a re-read.
- CI-artifact repro (run 39230394257) left to ui-loop: a compiler built from the fix would not read the artifact's compiler-keyed rows.

## seat_entry stack REPLACED (2026-10-19): #1031 tip fix = 841daf92 (branch seat-1031 in ../avra-pr976, on 76fc91f1)
- 18c555ba (closure gathers digest) regressed fn_add_attack (b2) and the codecs keeper (scope_word/scope_of_word pair).
- 841daf92: digest folds each member's MODULE + NAME only (shape/text typed what no build had asked, turned the attempt); scope pair registered in codec_pairs() (derived_total, exemplars Package+Closure; Self/UnknownScope never written); fn_add_attack step 10 reordered, ORIGINAL strictness kept (47 checks, 0 failed).
- Reorder reason: the old order judged the unrelated fn AFTER a member revert; a revert to an older member set is a cache hit that leaves the newer set's record standing (last-writer-wins), so the digest rightly reads it as moved. Now: unrelated fn first (after one priming build), then the member add, then a settle build that reads the collector once to write the current set. The revert-then-unrelated case therefore READS the collector once; the side-by-side per-digest kept objects follow-up restores it.
- Gates: codecs-static, cache-attacks a/b1/b2, warm-edit, closure_gather_attack, closure_entry tests (747eb825), std-ui suite (872/872, 49 programs) all green.
- Batch G: 747eb825 (closure_entry witness) + 532415b3 (Named("main"): decls.row_read/wire_siblings record the file's own rows for a Main; main_bucket_test fails before/passes after), branch main-scope4. Gates green.

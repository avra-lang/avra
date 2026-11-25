
[2026-10-12T16:32:35Z] items-kept: lane bound (avra-rb524), based on origin/batch-5 9a985559; make bootstrap (gen-1) running on the Sprite, then gen-2 + warm_edit trace.

[2026-10-12T16:40:48Z] items-kept REPORT 1: on batch-5 9a985559 gen-2 (Sprite avra-rb524), cli one-edit x3: wall 8.97/8.48/8.28 s; ast 0.29, sublang 0.16, parse 0, resolve 0.05, sigs 0.03, bodies 0.35, held 499/501, discarded 0, load 2.2-2.6, admit 0.01, analyze 1.1, lower 3.8-4.0, keep 0.75-0.8. files parsed: 7. Nothing left for an items kept-record law in this scenario (not building it). Next: split load/lower/keep.

[2026-10-12T17:15:35Z] items-kept REPORT 2 (probe on gen-2+qtrace PROBE lines, cli one-edit; load 2.2-2.6 s): holding: load_interface 1.2-1.3 s over 796 modules (held_modules 0, 4 roots recursive), settle_holds 0.85-0.9 s, unruled 0. Inside load_interface: record_cached 48 ms, record_fields 30 ms, record_fault 25 ms in total; meet_file 1.14 s = the cost (read_why per held file: text_digest/reads_pending/stands_in/const_rows_ready; splitting now). Not the decode.

[2026-10-12T17:32:53Z] items-kept REPORT 3: load_interface 1.2 s is read_why per held file: reads_pending 725-760 ms (485 files); stands_in 30 ms, consts 11 ms, digest 1 ms. reads_pending is key_parts_cached; inside key_parts: view_parts 697 ms, runs 24, gathered 23, text 0.7. So ~0.7 s of the 2.5 s load is the per-module `reach` closure walk (record.av reach/view_parts) behind the object key; the key (not the hold) is needed by every held file anyway. Splitting reach now (sees/refs/indexes/walk). settle_holds 0.85 s = mint_module over all held files, eager (derive.av 998-1005).

[2026-10-12T17:40:13Z] items-kept REPORT 4 (final for this scope): reach split, cli one-edit, 84 reaches, 4742 files walked (56/module), 909 module-visits: sees_records 187 ms, ref rows 98, typed indexes 140, walk 62, view_parts assembly 233 (files_of is O(F) per dep + bytes_key store reads) = ~720 ms, spread, no single hot spot. PROPOSED CUTS: (a) micro: group reach files by owner once instead of files_of() per dep; skip reads_pending computing full key parts (needs only `runs`) — but obj_key_cached for stands_in needs the view anyway, so saves little. (b) structural (the one that reaches <1 s): a held file`s key needs the view only to ask whether anything it sees moved; store per module a closure digest (its record-time reach with each seen module`s bytes_key) and compare to the CURRENT bytes_keys of just those modules (O(reach mods)) instead of re-walking reach per module — i.e. reach becomes a stored record row, recomputed only for modules whose own record/seen iface moved. (c) settle_holds 0.85 s: mint_module eagerly mints every held declaration (derive.av 998-1005); lazy per-module mint on first by-name read is the cut, but the comment there says queries read relations before minting, so it needs the namespace/Decls relation to demand-mint. Probe patch (record.av/derive.av qtrace PROBE lines) saved at .lead/lanes/items-kept-probes.patch; worktree clean; lane NOT freed. Nothing pushed.

[2026-10-12T18:11:54Z] items-kept REPORT 5: cut 1 built (branch items-kept, NOT pushed yet): reach kept as Stored.Unit row `reach` (record.av view_parts/reached_kept/reached_walked); row = the records the walk read (module + content digest) and the files reached per module; judged by those digests; pairs recomputed live (bytes_key, files_iface, own file count) so a new file / moved interface is never read from the row. Attack `rk` in tools/cache_attacks.sh passes on the fixed build (standing records walk nothing; Box moved to another file -> rename seen). Witnessing it failing with the digest check removed: building now.

[2026-10-12T19:00:28Z] items-kept REPORT 6: cut 1 built and attacked, but the measured gain is small. Attack rk passes with the law and FAILS with the digest check removed (top held on a stale reach after Box moved: exit 0, wanted 1). Trace on the cli one-edit: reach kept 81 / walked 3 (was 84 walks). But cli one-edit 3 rounds: wall 9.38/8.32/8.61 s (before 8.97/8.48/8.28), load 2448/2116/2313 ms (before 2560/2297/2201): within noise. Probe of the kept path: reach check 220 ms (121 distinct records, 34.5 MB, store read 55 ms, digest 6 ms; rest was node_key hashing in record_key per lookup, now memoized), assemble 280 ms for 993 deps (reached_part: files_iface/bytes_key per dep). So the walk was NOT the bulk of the 0.7 s: it is the per-module re-assembly + record reads, still O(modules x reached deps). Cut 2 scoping: docs/2026_10_06_COMPILER_DB.md row 617 already states it: eager mint exists because a row minted inside a query arrives after its reader and the relation refuses a late write; the lazy form IS DB 07a (rows pulled by first read) and needs DB 03a names + DB 01b read-asks-the-producer; no standalone lazy form exists. One more probe cycle running to find what the remaining load is.

[2026-10-12T19:52:24Z] items-kept REPORT 7 — SCENARIO TABLE, main 216f3c10 gen-2, Sprite avra-rb524, packages/cli, 3 rounds, one traced edit each (wall; held; attempts/discarded; biggest phases)
| scenario | wall (s) | held | attempt/discarded | phases (ms) |
| check, body literal in commands/shared.av | 8.3-9.4 | 499/501 | 0/0 | load 2.2, analyze 1.0, lower 3.9, keep 0.8 |
| check, ADD a fn to shared.av | 71 / 71 / 107 | 415-418/504 | 1/3 | lower 16.7-29.6, keep 5.5-18, admit 3.2, load 2.4 |
| check, SIGNATURE change of rooted() (used by 6 files; param added / renamed) | 82 / 43 | 415-427/504 | 1/3 and 1/1 | lower 12.7-14.2, keep 4.9-5.3, admit 2.5-3.6 |
| check, body literal in std-avrac core/types.av | 211 / 211 / 212 | 0/504 | 0/1 | ast 18.3, parse 20.9, analyze 30.6, lower 124, keep 38 (a FULL COLD rebuild) |
| build, body literal in shared.av | 102 / 102 / 103 | 409/466 | 0/0 | load 2.7, admit 3.2-3.8, analyze 2.5, lower 30-31, keep 17, emit 7-8 (bar 500 ms) |
Reference cold check 156 s, cold build 158 s; noop check 0.24-1.0 s, noop build 0.53 s.
READINGS: (1) the edit-loop number in the brief (8-9 s) is the BEST case: the moment an edit adds or re-signs a declaration, or touches a dependency package, 70-210 s. (2) A body literal in std-avrac core makes a full cold rebuild (held 0/504, discarded 1): something keyed on core/types.av text reads it everywhere (compile-time runs / derives record the files they READ by TEXT, so every file whose derive reads core is moved); worth its own lane: key a run's read of a file by the declaration it read (the RunRead.ref/print mechanism) rather than the text. (3) Add-fn and signature edits turn once (attempt 1, discarded 3): ~420 held files then ~85 re-lowered and ~70 s of lower; the 'again' attempt re-reads. (4) build after a body edit lowers 30 s and keeps 17 s with held 409/466 vs check's 499/501: the build path holds 90 fewer files and lowers far more than the check, the owner's 500 ms bar is ~200x away. Note: after a check-populated store, the FIRST edit run of a different scenario is a full cold read when the previous scenario's restore was a whole-program cache hit but left per-file records of the edited text (restored text hit; records stale by text) — worth a look.
CUT 1 PR: https://github.com/avra-lang/avra/pull/613 (draft, DO NOT MERGE title): reach kept as a row, attack rk fails without the digest check; gain on cli one-edit within noise (reach walks 84->3, load 2.1-2.4 s before and after). keepers-static: fails at a Traceback in ci_invariants self-test (tools/pr_watcher.py edited on disk by someone else this session) — not from this change; fmt applied.

[2026-10-12T19:54:05Z] items-kept REPORT 8 — DB 07a scoped against main 708e712b (no building). Lines are file:line on main.
0. REMAINING LOAD (probe, cli one-edit, load 2.1 s): settle_holds 0.86 s (the eager mint) + load_interface 1.0 s (read_why per held file: reads_pending/key parts 0.51 s = view_parts 0.49 s [reach check 0.22 s + re-assembling 993 SeenParts 0.27 s], stands_in 0.03, consts 0.01, digest 0.001) + opened_store/attach ~0.2 s. Record decode is ~0.1 s total.
1. PREREQUISITES. DB 03a LANDED in effect: Decl's key is a durable NAME (decl_rows.av: @key path, name, kind, owner, maker, enclosing, sibling; the "file leaves @local" blocker is moot because the key is the file's path string, file: FileId stays an @local projection). #592 families by name, #582 sealed store: merged. DB 01b NOT landed: no producer listing (@query(over:)) exists in std-relation; own-db-law is parked (origin/own-db-law, -fixture-wip). So the clean 07a (a row = part of Items(file)'s answer, pulled by its first read, producers listable) is blocked on 01b; a smaller form is not.
2. WHERE THE LATE WRITE IS REFUSED. std-relation/db.av:80-96,319-335 landing(): a write to a cell last read THIS revision is Torn if a running reader holds it, Late if only settled readers read it AND the relation is .Given (the Decl rows are: decls.av arm_recording ... given_to(record_kernel)). A mint writes (a) the row, (b) its NAME bucket (decls.av:1006 name_bucket) and (c) the global index buckets word/marks/external/home (decls.av:97-101). So a lazy mint is legal exactly when no query has read those buckets yet. By-id reads (self.decl(d), 259 sites) are SAFE: an id exists only after its mint. The unsafe reads are the bucket readers that can run before a producing module is minted: named_rows (decls.av:2593; impls_named, decls_named: 3 callers), indexed (1372: 10 callers), indexed_by_mark (1378: 2), externs (2446: 4). Lazy ensure already exists for the per-file path (decls_of_file/held_items_of_file call ensure_file -> workspace.av:1035 file_ensured -> mint_module) and for impl/trait names (named_minted, workspace.av:1060, via hold.named_in). The eager loop (derive.av:998-1005) is what remains.
3. SMALLEST FIRST SLICE (no 01b needed). A record-derived producer index beside named_in: for each held module, which declaration NAMES, WORDS, MARKS and extern-ness its record lines carry (the fields are in the lines load_named already decodes: name p[5], word p[14], external p[0], annotations in facts). Each of the 4 bucket readers first mints the modules the index lists for the value (the named_minted pattern), THEN reads the bucket: nothing late, because the mint precedes the first read of that bucket by construction. Then delete the third loop in settle_holds (derive.av:998-1005) so mint_module runs from file_ensured/named_minted/the index only. Slice 0 (do first, one build): just delete the loop and run the cache-attacks + std-avrac/cli suites: the refusals it produces ARE the list of unsafe readers (this predicts the 4 above; if it names a 5th the plan changes). ATTACK: a held module declaring only (a) a name, (b) an @mark, (c) a word-component, (d) an extern, each used ONLY through its bucket by a file that never imports the module; edit an unrelated file; assert the declaration is found (output) and the module minted (qtrace count) — and a negative: an unrelated held module is NOT minted (qtrace mint count == modules the edit's cone reads). Each fails today on the loop-deleted tree without the index.
4. ESTIMATES (cli one-edit): slice 1 removes settle_holds' 0.86 s minus the cone actually read (signatures of what the edited bodies call, est. 10-20% of modules: ~0.1-0.2 s stays) => load 2.1 -> ~1.4 s, wall 8.5 -> ~7.8 s. Further slices: DB 05's input manifest/reverse index replaces read_why's per-file key judgment (0.51 s + stands 0.03) => load ~0.6 s; 01b+07a proper retires the index (it becomes listing the package's files) — no extra seconds, less machinery.
5. WHAT BECOMES DEAD after slice 1: settle_holds' third loop and hold_only/file_ready pre-keeping there; the comment block deriv.av:992-997; file_ready's eager keep. After 07d (not 07a): load_interface's meet_file/read_why/key_parts_cached, view_parts/reach/KeptReach (my PR #613), the hold's record lines, record_prints. NOT dead: load_named's decode (feeds the producer index).
6. RISKS: DeclId numbering order changes with lazy mint (ids appear in read order) — anything printing or sorting by id (diagnostic order, golden output, bucket member order 'in id order' decls.av:1370-2445) must sort by name key instead; this is the real review surface. Late writes surface as a refusal, not silence (good). Generated declarations (derive/collect) live in held modules' records too: the index must carry maker-generated rows, or those modules stay eager.

[2026-10-12T21:35:07Z] items-kept REPORT 9 — SLICE 0 RESULT (eager mint loop deleted, derive.av ~992-1005; patch: .lead/lanes/items-kept-slice0.patch; base 64bbcd82)
The tree COMPILES ITSELF without the loop (gen-1 by the old compiler, gen-2 by gen-1), a cold cli check exits 0 and the no-op is a cache hit. But the ONE-EDIT check traps: exit 2, "a Decl write moved the whole relation while a query (reader 817), which read it this revision, is still running — a query settles on one state of what it read" (Landing.Torn, db.av:80-96/319-335). Same trap for explain --stats/--why. The trace's last events are Parsed/Resolved/Visible(461) reuse: i.e. the lazy mint is triggered INSIDE a running Visible/Resolved query (file_ensured via namespace/items(g), workspace.av:1035) that has already read the Decl relation. So the unsafe path is not only the four bucket readers: it is any ensure issued from inside a query that has read decl rows. Consequences: (1) lazy mint must happen BEFORE the outermost query that can read a module: mint the import closure of the read files at the start of the derivation (outside any query), not on first read; (2) that is still a big saving only if the closure is small — to be measured (est. closure of cli's read files ~100 of ~800 modules => ~0.6 of the 0.86 s); (3) the clean fix (rows as part of Items(f)'s answer, pulled in the reader's own query) is exactly DB 01b — it cannot be done from outside the kernel. Next: measure the closure; pre-mint-the-closure slice; then types.av.

[2026-10-12T22:25:44Z] items-kept REPORT 10 — WHY A types.av LITERAL IS A FULL COLD REBUILD (main 64bbcd82 gen-2, cli check)
QTRACE of the edit: 'attempt 0 hold true homes false moved 0 reading 0' then 'attempt 1 hold FALSE homes false reading 412'; time line 'held 0/505, attempt 0, discarded 1'. So attempt 0 (under the hold) did not fail by diagnostic: it TURNED to hold:false, i.e. Attempt.unheld(why) (derive.av:75) was called — the hold's oracle gives up and derives from the sources whole. unheld has two callers: derive.av:685 'a sealed layout moved' (layouts_moved, derive.av:830) and derive.av:723 'what a held file said could not be read'. A first instrumented run (hold-refused trace in under_hold) printed nothing, which rules out the under_hold refusal path. explain --why (same state, types.av edited, nothing run): 4 inputs moved = types.av's text, and the compile-time-run read lists of std-http/src/h2_serve.av, std-http/src/hpack.av, std-avrac/src/compiler/store/meta.av (three files with consts; the read list is a digest list, not decodable from explain). Leading suspect, from reading: types.av line 10 declares 'export type TypeId = { index: int }' (a FLAT record, @derive(Fingerprint) on line 9) and layouts_moved compares what held lines keep flat against what the registry decides now: a flat record declared in the file that is re-parsed. Other core files with no flat record (digest.av) do not trip it. Confirming with a trace of which unheld branch fires and which type (build + run in flight).

[2026-10-12T22:31:15Z] items-kept REPORT 11 — ROOT CAUSE of the types.av full cold rebuild (traced, main 64bbcd82 gen-2, cli check after a types.av literal edit)
Trace (instrumented layouts_moved/unheld, since reverted): 'Q layout-flat-moved 0' ; 'Q layout-boxed-moved .../std-avrac/src/core/expr/expr.av IntLit,FloatLit,BoolLit' ; 'Q unheld a sealed layout moved'. => derive.av:685 analysed() -> layouts_moved (derive.av:830) -> Attempt.unheld (derive.av:75): attempt 0 (under the hold) turns to hold:false and attempt 1 derives the whole program from sources (held 0/505, discarded 1, 211 s). Not a diagnostic refusal (under_hold trace printed nothing).
MECHANISM. IntLit/FloatLit/BoolLit are one-scalar-field records (flat by declaration) that the LAST build kept BOXED: some  seat elsewhere sealed them (types.av:735-792 unflatten -> boxed_flat; record row 'Boxed' with path = the declaring file). expr.av is analysed (read) in attempt 0, the file that seals them is HELD ('a held file's seal is not re-met', derive.av:825-829), so the registry decides them flat again, kept_boxed (derive.av:847) says the record was boxed, and the check bails to the sources whole. The edit to types.av is only the trigger that gets expr.av read (reason expr.av is read: not yet traced; explain --why lists 4 moved inputs: types.av text and the compile-time-run read lists of std-http/h2_serve.av, std-http/hpack.av, std-avrac/compiler/store/meta.av; expr.av is not among them, so check what reads it). Other core files declare no kept-boxed record, which is why core/digest.av edits are 7-16 s.
THE FIX SHAPES. (1) Precise: a Boxed row records WHICH FILES SEALED it (record format growth: sealers appended to the row); when every sealing file is held, replay the seal onto the parsed file's record (unflatten) instead of bailing; bail only when a sealing file was read. (2) Cheap and sound today: replay without attribution is UNSOUND if the sealing site was the edited code (objects of held files were compiled boxed), so do not do it. (3) Independent: make the one file that is read (expr.av) not be read for a types.av edit (key a derive run's read by declaration, DB 07), after which no kept-boxed record is parsed. Recommend (1); it is exactly 'a seal from a held file is not re-met' made true. Estimated gain: core/types.av-class edits 211 s -> the 7-16 s class.

[2026-10-12T23:13:39Z] items-kept REPORT 12 — SEAL FIX (draft PR #647, branch seal-held, base eaff334c) + 07a SLICE 0 RE-SCOPE
SEAL FIX. Attribution is by the sealing DECLARATION without any format growth: a held Fn/Extern record row that seats the record's type under 'mut' (or writes it, per the row's written bits — the receiver case) IS the durable evidence (derive.av sealed_by_held/row_seals); growth law n/a, no seed refresh owed. Mechanism: layouts_judged -> if every kept-boxed-but-now-flat record has a held sealer, fail Turn.Again(at with sealed: [path TAB name]) and the next attempt unflattens those records after admit_all, before typing reads their layout (presealed); a record with no held sealer, or one the pre-seal did not cure, bails exactly as before. Attack sl (cache_attacks.sh): held mut-seat + writing method seal Cnt; read rec/r.av -> attempts 'true true' held 3/5 (with the evidence disabled: 'true false' held 0/5 = main's behaviour, witnessed); sealer edited away + declaring file read -> bails (false) and prints the right value, eval==native; a NEW sealing site in a read file -> program prints 29 both engines; that site removed -> bails again, prints 13. Not covered: sealing file DELETED outright (the removed-site case is the same branch), a seal made through a fn TYPE (keep_seats_boxed) — no held evidence, so it bails as today.
MEASURED (Sprite avra-rb524, cli check, core/types.av literal, 3 rounds): before (REPORT 7/11) held 0/504-505, attempt 0 discarded 1, 211/211/212 s. After: held 437/505, ONE attempt, no discard: 125 / 153 / 151 s; the time moved to lower (108 / 136 / 134 s) and load 4.5 s, analyze 5.2 s. cli one-edit row after (shared.av literal): 5.2 s, held 503/505 (was 8.3-9.4 s on 64bbcd82; base now has #605). Remaining 125-150 s is lowering all instantiations that read types.av: decl-lower's.
WHY expr.av IS READ (Q parse on a types.av edit, files parsed, first 20 of the list): core/types.av, std-meta/src/meta.av, std-meta/src/rule.av, std-relation/src/engine/{answers,fixpoint,kernel,key_marks,table}.av, then EVERY file of std-avrac/src/core/ (arena, chars, children_derive, control, debug, digest, exact_derive, exemplar_derive, fingerprint, flow_derive, ...). So expr.av is read because its whole MODULE is: admit_all parses every unheld file of an admitted module (doc row 620, whole.av admit_all) and the derive runs over core read module files by whole text. explain --why on the edit: 4 moved inputs = types.av text + the run-read lists of std-http h2_serve.av/hpack.av and compiler/store/meta.av. Leave to DB 07 (per-declaration run reads); not touched here.

07a SLICE 0, RE-SCOPED (Decl's producer = a query over the package's files; a mint is the producer's own owned write).
1. WHAT EXISTS. rows.av:372 replaced(db, owner, rows, how): owner-named all-or-nothing replace, a keyed rerun upserts, rows the owner no longer names are removed; it asks the cells it moves first and refuses with replaced_whole when held() finds a RUNNING reader on them (Torn), and a settled reader of the same revision is Late only when the relation is .Given (db.av landing(), 80-96/319-335). Decl already has per-file owners: decl_rows.av 'A FILE'S ADMISSION OWNS ITS ROWS' (stamp = the file's run; what a re-admission does not mint is removed from every bucket). So the owner-write exists; it does not by itself avoid Torn, because a write is a write: if any RUNNING query already recorded a read of a cell the mint moves, it is refused.
2. WHAT TORN IS HERE. Slice 0's trace: the mint is triggered inside Visible(461) (a running query that already read Decl) and moves 'the whole relation' (the message says whole, not a bucket): so some reader holds the WHOLE-relation cell (a walk with no bucket: decl_count / all_files / decls_so_far / raw index walks, decls.av 'a walk by index over decl_count reads'). Step 1 of the slice is therefore a map, not a fix: name the readers of the whole-relation cell and of each bucket family, and make Db.refuse name both the writer and the reader edge (db.writer(first) exists; the message prints a reader NUMBER only) — useful for every lane.
3. THE SHAPE THAT HAS NO LATE WRITE: a reader never records a bucket before its producers have written it. (a) a name/word/mark/extern -> producing-files index from the kept RECORDS (decoded already by load_named: names, facts.word, annotations, external bit; plus 'maker' lines for generated rows); (b) every bucket reader (named_rows 3 callers, indexed 10, indexed_by_mark 2, externs 4) first ensures the listed producers (mint_module), THEN reads the bucket — the bucket's readers are its producers' askers, so the listing the doc calls @query(over:) is exactly (a) for Decl; (c) whole-relation walks either become a bucket read (home bucket per file: already the case for decls_of_file) or ensure ALL producers first (tools, not the hot path); (d) by-id reads stay unchanged (an id exists only after its mint).
4. SLICES, each green on its own. 0a: refusal names writer+reader (no behaviour). 0b: the record-derived producer index + ensure-before-read in the 4 bucket readers, EAGER LOOP STILL IN (no behaviour change; the index is proved by an assertion that every bucket read is covered: qtrace count of 'ensured by index' vs 'already minted'). 0c: delete the eager loop (derive.av ~992-1005) and the whole-relation readers found by 0a; attack = a declaration reachable only through each bucket in a held module + an unrelated held module NOT minted (qtrace mint count == modules the edit's cone reads) + the slice-0 repro (the one-edit check exits 0). 0d: DeclId order: ids now follow read order; sorts by durable key (path, ordinal) in decls_of_file/named_rows/indexed/externs where output order is observable (diagnostics, golden output, 'in id order' docs decls.av 1370-2445).
5. EST. 0c: load 2.1 -> ~1.4 s (settle_holds 0.86 s minus the cone read), wall 5.2 -> ~4.5 s on the new base. Collisions: record.av (store-tw: key parts) only for the index read of record lines — put the index in its own file; derive.av/workspace.av settle_holds (decl-lower), std-relation/db.av refusal text (db06).

[2026-10-13T00:03:05Z] items-kept REPORT 13 — THE READER MAP (07a slice 0, with 0a's refusal text; PR #649)
With the eager mint loop deleted (patch .lead/lanes/items-kept-slice0.patch) on top of 0a, the cli one-edit check now speaks: 'a Decl write by query Methods:5642 moved the whole relation while a query (reader 817, Receivers:0), which read it this revision, is still running'. So: WHOLE-RELATION HOLDER = the Receivers whole-program query (family Receivers, arg 0 — the receivers pass, 41,435 reads in the doc's census, 'split per impl' = DB 07 c). WRITER = Methods(5642), a method-table query minting a held module (named_minted / file_ensured) while Receivers is running. Receivers walks the table by index over decl_count (the raw walk that records the whole-relation cell). Consequence: lazy mint on the one-edit path cannot land (0c) until Receivers stops holding the whole relation: either (a) Receivers is split per impl / per type bucket (DB 07 c — the bigger win, it also takes analyze's 'rebuilds all 994 method tables'), or (b) Receivers ensures every producer first (= eager mint again). It is the only holder on this path (the trap is the first and the run stopped there, so a second holder behind it is possible — each fix reveals the next, which is what 0a's text is for). So 0b/0c are blocked on the Receivers narrowing; proposing it as slice 0b' (before the producer index): make Receivers read per-bucket and measure what analyze loses/gains.
Also: PR #647 status. Rebased on 3229407d+ (02874a27); sl now includes the sealing-FILE-deleted case; full cache-attacks on the Sprite: 'cache-attacks: 390 builds through one store, 135 under a hold, 0 failed'; keepers-static: green on the Mac (every keeper but ci-invariants runs on the Sprite and passes there; ci-invariants needs .github/, which the Sprite sync omits, so it was run locally); fmt --check clean. 'test' still to run by name: next.

[2026-10-13T00:12:48Z] items-kept REPORT 14: #647 green by name on Sprite avra-rb524 at c1455e11: `CACHE_ATTACKS` full: 390 builds through one store, 135 under a hold, 0 failed (sl incl. sealing-file-deleted); `avra test packages/std-avrac`: 8724/8724 tests passed, 332 programs proved eval == native == expected; `make keepers-static`: green on the Mac (ci-invariants needs .github, absent on the Sprite); fmt --check clean. Ready to land alone.

[2026-10-13T01:19:01Z] items-kept REPORT 15 — 07a: narrowing landed as DRAFT PR #660; 0c in test; a PRE-EXISTING DEFECT FOUND
1. #660 (branch narrow-receivers, base main 02874a27): Decls.unheld_decls() — each unheld file's own rows via decls_of_file — replaces Decl.all in Receivers, Failures, ReadReach, CancelReach, clear_written, clear_inferred. The holder on the one-edit path was clear_written() inside Receivers (and clear_inferred in Failures), not the passes' survey lists. Checks: cache-attacks 373 builds / 129 held / 0 failed; avra test packages/std-avrac 8735/8735, 332 programs proved. Witness (needs the eager loop deleted): main + loop deleted traps 'Decl write by query Methods:5677 ... (reader 812, Receivers:0)'; #660 + loop deleted: cli one-edit exits 0, held 498/500, load 1718 ms (2.1-2.5 s before), analyze 949 ms, lower 2747 ms.
2. #649 (0a): fixed the two std-avrac tests that pinned the old words (kernel_relation_hooks_test.av:39, readmit_test.av:234). Without it #649's check would be red.
3. 0b (producer index): I looked for a failing witness before building it. A package whose collector is read while its @seq member's module stays held (attack lz) is gathered correctly on the loop-deleted tree: the existing gathers rows mint what a collect needs. So no failing case exists for the collect/mark bucket; the extern bucket cannot be witnessed at all because of finding 4. I did NOT build the record-format index. Instead the three global bucket readers (indexed, indexed_by_mark, externs) call held_ensured() first (mint every held file's module before the bucket read — the old eager behaviour, but only for a reader that actually runs), no format growth. If that readers is on the hot path of some command the win is lost for that command; measuring below. The producer INDEX stays the proper form when a measurement shows a hot reader.
4. PRE-EXISTING DEFECT (on main, reproduced on the eager tree; not mine): a HOST FN in a held module is missing from the linked program after a warm build. Repro: package with src/x/host.av = 'extern fn avra_lh_event(who: int) -> int { who + 1 }', src/main.av = println("lh"). Cold 'avra build' links it (nm: av_avra_lh_event, avra_lh_event = 2 symbols); append a comment to main.av and 'avra build' again (host.av held 2/3): nm shows 0 and the build does not list 'host fn:'. The host that calls it by name finds nothing. whole.av host_fn_owes / lowering's held-file path (a held file's object is the store's, but the link's -u / export list is built from externs() of READ files?) — owner unknown; worth its own ticket and an attack (lh, drafted: nm on the warm binary).

[2026-10-13T01:38:57Z] items-kept REPORT 16 — 0c MEASURED: LAZY MINT IS NO WALL WIN ON THE CLI ONE-EDIT. Branch lazy-mint2 (pushed, NO PR opened; = #660 + eager loop deleted + held_ensured() in indexed/indexed_by_mark/externs + attack lz). Same Sprite, same base (02874a27), shared.av literal, 3 rounds, :
  eager (narrow-receivers, #660): wall 5.83 / 5.19 / 5.05 s; load 2165-2235, analyze 472-486, resolve 51-58, sigs 27, bodies 345-352, lower 1816-2658
  lazy  (lazy-mint2):            wall 6.07 / 5.22 / 5.18 s; load 1722-1776, analyze 982-991, resolve 247-250, sigs 122-135, bodies 499-508, lower 1844-2767
Load fell 0.45 s and analyze + resolve + sigs + bodies rose ~0.9 s: the minting is not avoided, it moves to the first read. The read cone of the edited file (resolve/sigs/typing through held signatures) touches almost every module, so nearly every held module is minted anyway, now a module at a time inside the queries. Checks on lazy-mint2: cache-attacks 377 builds / 131 held / 0 failed; avra test packages/std-avrac 8735/8735; the trap on Receivers is gone. Verdict: do NOT land 0c as a speedup; #649 (0a) and #660 (narrowing) stay (they are the correct reads and make a later lazy mint possible), but the 0.86 s eager mint is not the cost to attack — it is paid for the cone. The way to make it vanish is to make the CONE small: per-declaration reads (DB 07 b/c: Resolved/Folded per declaration, Receivers per impl) so an edit reaches only the signatures it names; only then does an unread module stay unminted. 0d (id order) is moot until that.

[2026-10-13T01:41:10Z] items-kept REPORT 17 — RECEIVERS SPLIT (DB 07c), DESIGN + A CAUTION BEFORE BUILDING
Today (receivers.av:45-69): one query Receivers:0 over every UNHELD seated fn (#660): touch(sig(d)) each, summary(d) each (body read), Kleene fixpoint over Flow edges, bits written into side tables (record_seat_written), one print (writers_print). Consumers read bits through the hook; dep_audit maps Written(_) -> Receivers:0.
GRAIN. Not a receiver-type bucket, not a per-impl bucket: a seat's bit depends on its CALLEES' seats (Flow{from, callee, to}), which cross types, impls and modules, so neither bucket is closed under the dependency. The closed grain is the MEMBER = one fn (its seats' bit-list), and the engine for it already exists: engine/fixpoint.av Fixpoint<T> (semi-naive, one dense family, join = OR, 'a member that read something whose answer grew runs again', reverse edges scoped to the group) — ReadReach already uses it (workspace_analysis.av:255, read_fixpoint). So: Written(d) = Fixpoint<List<bool>> member d; contribution(d) = summary(d).own OR flows from callee members' values; a consumer asks Written(d) (a nested ask, recorded as an edge), no whole-program pass, no side-table writes by a pass.
WHAT A MEMBER READS OF Decl: its own row by id (bucket cell of its name, already recorded by decl(d)), seat_count/sig(d) (Sig(d) cell), syntax(d) (the body, a Syntax(d) cell), the callee's Written(g) (member cell), and for a call through a name, impls_named(name) filtered by aims_at/visible(file).types (CLAUDE.md's name-keyed-table law — the filter stays in the member, so it never reads another module's table unfiltered). Never decl_count, never Decl.all, never a walk by index.
METHOD TABLES (analyze's 994): Methods(d) per type already exists as a family keyed by the type decl (workspace.av:1930). The 'rebuilds all 994 tables on every edit' (doc row 621) is the receivers/References/MethodDiags whole-program passes invalidating them, not Methods itself; after the split an edit re-runs the members whose inputs moved.
ATTACKS (each must be witnessed failing first): (1) no torn write: with the eager loop deleted, a mint of a held module while a Written member runs is not refused (the repro is the loop-deleted one-edit check; main traps on Receivers:0, #660 clears it already — this attack pins it for the member form); (2) an impl added for type A re-runs only A's members: AVRA_QTRACE counts 'Q ask Written' computes: one body edit = members of the edited fns + their callers' members that read a grown value, never the program's ~1000; (3) the name-keyed law: a same-named type in another module is not touched by an impl for A (cache-attack with two modules declaring T).
THE CAUTION. In a fresh process (the CLI is one-shot; the kernel starts empty) every member is computed once either way: splitting Receivers does not remove work from a warm edit unless the per-member answers are SAVED (DB 06) — analyze is 0.47 s of the 5.2 s one-edit and Receivers is part of it. So the split is the right shape and the prerequisite for saved answers, but on its own it will not show on the one-edit wall; its win is the persistent kernel (dev/watch, language server) and add-impl's 'rebuild all method tables'. I have NOT built it. Before I do: (a) measure add-impl and one-edit on main-current (running next), (b) split analyze's 0.47 s by family with QTRACE counts to see what fraction is Receivers — if under ~0.15 s the split is deferred behind DB 06 and I go to the load cone instead. Tell me if you want it built regardless.

[2026-10-13T02:16:38Z] items-kept REPORT 18 — #649 BY NAME; ADD-DECLARATION COSTS 4 ATTEMPTS (the bigger fish than Receivers)
#649 (refuse-names, rebased on origin/main 132bc456, head 2fc41e52): GitHub checks all pass at 2b5af3ae (codecs, gate, keepers-a/b/static, seed-check, suites incl. std-avrac, std-relation); on the Sprite at 2fc41e52: cache-attacks 373 builds / 129 under a hold / 0 failed; avra test packages/std-avrac 8735/8735 passed, 332 programs proved. (The RED the lead saw was the pre-fix head: the two std-avrac goldens, fixed in 2b5af3ae.) #647: green on GitHub, in batch 9; not re-run.
MEASURED on main-current (Sprite, cli check, 3 rounds): one body literal (shared.av): 5.17 / 5.22 s (held 498/500, 0 attempts turned). ADD A TYPE+IMPL to shared.av: 68.3 / 60.0 / 57.6 s (held 410/500, attempt 1, discarded 3); the same file edited back (decl removed): 53.2 s. The standing attempt's phases sum to ~22 s; the other ~40 s is the 3 discarded attempts.
TRACE (qtrace Q attempt + a probe in having_read, since reverted): attempt 0 (hold) -> 'more 7: a compile-time run called one of its bodies' (std-http/src/files.av first) -> attempt 1 -> 'moved 1' (the records moved under the attempt: a restart) -> attempt 2 -> 'more 7: ... called one of its bodies' (std-text/src/text.av first) -> attempt 3 stands. explain --why on the same edit: 'moved module commands's interface' for stage.av, main.av and all 31 files of the package that import commands: a private type added to a module moves the module's interface digest (iface covers every declaration, exported or not: same-package use reaches both), so 90 files are read at once — correct and by design.
THE WASTE is the three turns, not the 90 reads: 2 x 'bodies_asked' (7 held files whose bodies compile-time runs of the re-read files call: their bodies are not known at attempt start although the re-read files' recorded run lists name them — forced_runs only closes over files that are read for a hold reason, not the bodies a re-run const asks) and 1 records-moved restart. Each attempt is ~13 s (load 1.9 + admit 3.5 + analysis...). If attempt 0 started with the 14 files in its read set, the add-declaration edit is ONE attempt ~20 s instead of ~60 s: the same lever for add-fn (71 s), signature change (43-82 s) and build (102 s, held 409/466). Proposed slice: remember per file, in the store, 'bodies this file's runs asked' (the bodies_asked closure) and seed attempt 0's read set with it (the homes_key mechanism, derive.av:294, already does this for instantiation homes); plus find why records move mid-attempt (the 'moved 1').
RECEIVERS SPLIT: design in REPORT 17. Not built: in a fresh process every member is computed once either way; analyze is 0.47 s of 5.2 s. Waiting for the lead's pick between (A) the remembered-bodies seed above (est. 60 s -> ~20 s on the add-declaration family), (B) the Receivers split anyway.

[2026-10-13T02:28:33Z] items-kept REPORT 19 — THE CONE of the cli one-edit (shared.av literal; lazy-mint tree = #660 + eager loop deleted, on main 132bc456; instrumented mint_module logs module, microseconds and the asking query; probe reverted)
84 held modules minted, 501 ms in all (the eager loop spent 860 ms on ~800). time: load 1739, analyze 996, resolve 249, sigs 123, bodies 504, lower 2767 (round 1).
BY FIRST PULL (count, ms):
| first pull | modules | ms | what pulled it |
| Admitted(f) | 12 | 188 | a read file's 'use m.{..}': admission() loops over EVERY file of each used module (written_export modules.av:335, private_named :493) -> items(f) -> mint. Includes @std.avrac.compiler 85 ms, @std.avrac.core 50, compiler.backend 22, commands 13 |
| Methods(d) | 43 | 159 | a type's method table: named_minted(name) mints EVERY module that declares an impl/trait of that name (hold.named_in is name -> modules): @std.http 42 (Methods:6), @std.relation 16, ... mostly many small modules |
| Sig(d) | 4 | 94 | a signature naming a type of another module (declared_type): @std.avrac.features 81 ms (via core/node_trait.av), compiler.store 7, relation.engine 5, errors 0.6 |
| driver (outside any query) | 23 | 51 | commands.tests 19, compiler.format 8.5, families 1.4, memory 2.6 ...: mints issued by the driver (stubs / a bucket reader's held_ensured), no query asked |
| Receivers:0 | 1 | 9 | compiler.lower |
| Visible | 1 | 0.1 | @std.prelude |
LARGEST: Admitted (188 ms), then Methods (159). Admitted is the one whose grain is plainly wrong: it mints a WHOLE module (all its files, every declaration) so that a 'use' can check that names it imports exist and do not clash; the check needs the names the use lists, not the module.
DESIGN (<=25 lines).
1. Names per declaration: a 'use m.{x, y}' asks Names(m, x): the files whose RECORD rows name x (a name -> files index decoded at load_named, same decode as named_in, one line per name) and mints those FILES (mint_file), not the module. 'use m' (whole module) and the clash check on a module's own exports still mint all, but only for modules the read file imports whole. Reach: 12 modules / 188 ms -> the files that declare the imported names (est. 30-40 ms).
2. Methods per file: named_in is name -> modules; make it name -> files, and mint the files holding an impl/trait of that name (mint_file(path) already exists: mint_module is a loop over held files). A method table then reads the impl blocks only. Reach: 43 modules / 159 ms -> a few files per name (est. 30-50 ms).
3. Sig per declaration: declared_type(id) needs one row; mint_file for that row's file (fill_ensured is already per row). 94 ms -> ~10 ms.
4. The recorded dependency a read leaves is the FILE's Items cell (rows_read(f) already records it for a held file at state 2), so a mint of a file the query never read cannot be torn.
WHAT IS REACHABLE. The cone's mint cost is 501 ms and the three reasons above are 441 of it; per-file minting would leave ~100-150 ms: ~0.35 s of a 5.2 s edit (7%). The rest of load (2.2 s on the eager tree) is NOT minting: records decode ~0.1 s, read_why/key parts ~0.5 s (view_parts/reach: PR #613's measurement), store open and file registration ~0.2 s, the held-file bookkeeping in settle_holds. And analyze 0.5 s / resolve+sigs+bodies are what a lazy tree adds on top. So Visible/Resolved/Names per declaration is worth ~0.35 s on the one-edit, more for edits that reach fewer modules; it is not where the 5 s goes. The 5 s: lower 1.8 (decl-lower), load non-mint ~1.5, ast 0.28, analyze 0.5, bodies 0.35, keep 0.15. The add-declaration family is the 12x (60 s -> ~20 s by REPORT 18's seed).
Coordination note for decl-lower.md: this sits above their per-decl Typed/Folded serving (Names/Visible side); nothing here touches unit rows.

[2026-10-13T04:05:05Z] items-kept REPORT 20 — THE GUESS (draft #677, branch guess, base main 444e00b5)
MECHANISM. Attempt carries edit = digest of the files whose text moved since their module's record was written (edit_print, computed once in derived_owing; empty when none). The standing attempt keeps its read list (at.parse: leads + turn-added + remembered) as lines 'path TAB words-of-the-reason' under guess_key(entry, edit) — written in bodies_lowered beside homes_key's row, only when hold && edit != ''. Attempt 0 of the SAME edit starts with them: lead_reads adds a ReadFile per line, filtered by self.there(path) and by what verdict_reads_first already led, wearing Reads.Remembered(the words) (says = the remembered words, so explain/--time print the original reason). Second change, the 'records moved mid-attempt' restart: kept() found held files whose keys no longer stand once keep_interfaces wrote the new record (the new interface exists only after the parse, so attempt 0's holds judged against the old one) and restarted with moved+1; the restart now READS those files (Attempt.adrift appends them as Reads.Adrift) so the standing attempt's list carries them and the guess has them next time. That restart was the third discarded attempt of add-declaration.
WHY NOT #656. Its row was one per entry and accumulated everything: a file read for one edit stayed read for every later edit, so mh/ee/ur/go/gw (which assert that a file stays HELD) failed — not a bug in gw: over-reading. Keyed by the edit's moved files, another edit has no guess; the same edit gets the same reads.
MEASURED (Sprite avra-rb524, cli check, 4 rounds): add a type+impl to shared.av: 69.0 s / 4 attempts / 3 discarded the FIRST time; the same edit again 22.8 / 22.9 / 22.8 s, 1 attempt, 0 discarded (held 410/500). A plain edit on this base is 1 attempt at 5.2 s with or without the guess (lower-regress's 12 -> 6 s was on 02874a27; #658 and later removed that turn).
CHECKS. cache-attacks full: 376 builds / 129 under a hold / 0 failed (gw, mh, ee, ur, go included); avra test packages/std-avrac 8735/8735, 332 programs proved. Attack gg (new): fails on main ('the same edit again turned 2 attempts, wanted 1'), passes here; it also checks that a guess naming a file the next edit no longer needs gives the program and the diagnostics a store with no guess gives.
INVARIANT, honestly. A guess can only ADD reads (a file read from the start that no-guess would read after a turn, or would hold): results are decided by content, never by the read list, so diagnostics, exit and keys are the no-guess ones (gg's unneeded-file step compares output and diagnostic lines). The read LIST differs where the guess over-reads, and a pre-admitted file wears the remembered reason, not a freshly derived one. The remembered-reason-wins rule is why gw/mh/ee stay green. NOT proven: 'every file' and 'empty' rows as direct overwrites — there is no door to write the row from outside; the organic equivalents are covered (empty = the first occurrence; unrelated-existing = gg's step 4). A deleted remembered path: needs the dp fix below first.
DELETED-PATH TRAP (separate small PR, branch dp-fix): reproduced on main 2298eac8 — a file that a kept const verdict read is deleted, held.av edited to stop using it: the next build and the one after trap 'avra: .../z/add.av does not exist'. Cause: read_token (record.av) asks text_digest(read.path) for a recorded read whose file is gone. Fix: a gone read's token is '' (run_said already did that for the plain case). Attack dp passes with the fix (3 builds, 0 failed); full cache-attacks + std-avrac suite running before the PR.

[2026-10-13T04:43:56Z] items-kept REPORT 21 — #677 per the lead's two points
(1) THE KEY was already the SET OF MOVED PATHS: edit_print = digest of the sorted paths of files whose text moved since the record, no content. Evidence: the four add-declaration rounds each added a DIFFERENT type name (IkT<ns>) to shared.av: 69.0 s / 4 attempts, then 22.8 / 22.9 / 22.8 s / 1 attempt each. gg adds a body edit after another edit of the same file: still 1 attempt. No attack needed content.
(2) THE PROOF, inside: compiler/tests/guess_test.av (12 cases, std-avrac 8751/8751) calls the guess reader (guessed_reads) on a memory host and an in-memory store with synthetic rows: no row, empty row, empty edit, another edit's row, a gone path (dropped), an unneeded existing file (answered with the remembered words as its reason), EVERY file of the package plus a gone one (all the files and only the files), an already-led path (not doubled), malformed lines (dropped); and guess_line: a Remembered read is kept with the same words, a consumer's reason keeps its words, a tab path is not kept. Reasons: a read's reason lives ONLY in Derived.read / --time / explain and in the guess row — never in a kept record (record lines carry digests and interfaces), so a remembered reason cannot replace a consumer's real reason in a kept record. READ LIST: a stated superset — the guess can add reads, never remove one; the extra reads can only over-invalidate (a file read that no-guess would hold is analysed afresh, whose answer is content-decided). The derivation-level equality (exit, output, diagnostic lines vs a store with no guess) is the shell attack gg, whose steps now include a deleted remembered file (on top of #687's fix) and the unneeded-file step. Not done: a derivation-level in-compiler test of 'final key equal' — gg compares output and diagnostics, not the key itself.
Pushed once (force, rebased on f495de39, includes #687's commit until it lands); batcher told.

[2026-10-13T05:03:42Z] items-kept REPORT 22 — DB 07 d+e: §6.2 STEPS 2–6 ON MAIN f495de39/69522c3d, AND THE FIRST SLICE (read-only; no Sprite; DB_AUDIT.md had not landed)
1. WHAT SERVES EACH STEP, WHAT IS ABSENT.
 step 2 inputs first: PARTIAL. DB 04's door names every world read; text_digest is BLAKE3, once per file (#595, #624); there is no digest-by-durability-tier compare and no manifest of 'the inputs the records name' — every run digests all ~730 sources (cheap, 0.9 ms of 'digest' in read_why) but then re-derives every hold key from them (KeyParts, view_parts/reach: ~0.5 s). Absent: the manifest + tier confirm (DB 05 remainder).
 step 3 reverse index → suspect set: ABSENT. The kernel keeps FORWARD deps per cell (kernel.av) and verifies by pulling (verified/changed_at) inside one process; Fixpoint has group-scoped reverse edges only. A cold process starts with no cells, so there is nothing to mark suspect: the hold's per-file key judgement (read_why → stands_in) IS today's step 3-5 at file grain, recomputed from scratch each run.
 steps 4–5 ask roots, non-suspect stands, verify by read digests, early cutoff: EXISTS in-process (cells, fingerprint cutoff) and PERSISTED only for DB 06's first formats: keep_reading/get_valid with reads as (name, digest) pairs (#618), a saved @query answer that carries what it stood on (#642), the durable workspace Db for input-only scan queries (db06 4b, #678 draft). NOT persisted: Parsed/Resolved/Typed/Folded/Lowered/Sig-of-a-decl — the compiler's heavy families are still the hand formats (KeyParts, stands_in, kept-settle lines, units/warn rows).
 step 6 load by name on demand: ABSENT. Load is load_interface (decode every record), settle_holds (mint), admit_all. My lazy-mint experiment (REPORT 16) showed minting only MOVES: the read cone of a one-edit (Visible/Resolved/Sig/Methods over whole-module namespaces; REPORT 19) touches ~all modules. Names: Decl has a durable key (path, name, kind, owner, maker, enclosing, sibling) but nothing loads by it.
2. FIRST LANDABLE SLICE THAT DOES NOT GO THROUGH THE HOLD. Express ONE file's 'held' judgement as a saved answer, beside the hold: a @query FileSaid(file) -> the file's Said (warnings, rule findings, code facts ref) whose recorded reads are (name, digest) pairs: its own text digest, each seen module's interface digest (today's KeyParts.seen), each compile-time run's read digest (KeyParts.runs), its gathered set — exactly KeyParts' parts, written as READS instead of as a hand-folded key, via the #618/#642 API. A body-edit check: changed inputs = the files whose digest moved (step 2); for each file the answer is stored under its name, verify = compare the recorded reads' digests now (get_valid), early cutoff when the recomputed answer's digest is unchanged. It runs BESIDE stands_in on every run under AVRA_DB_VERIFY=1: both decide whether the file is held, a disagreement is the finding (the held set, file by file, must be equal; the first run lists where they differ). Deleted when equal on the edit corpus: stands_in, held_okey, KeyParts/key_of_parts, view_parts/reach (#613's subject), parts/seen rows, KeptReach. It buys no speed on its own (verification is still O(files x reads) ~ today's read_why); it is the shape that lets steps 2–3 make it O(changed).
3. NEEDED FROM OTHERS. db06: (a) the input manifest + reverse index in the store (step 2–3): per input its digest and the list of answers that read it, appended with the answer, so a changed input yields suspect ids with nothing decoded — that is the piece that turns the slice from 'same speed' into O(changed); (b) the saved-answer rule for answers that READ DECL ROWS (4b design item 4: they restore only after the rows exist = after the parse the restore exists to skip) — FileSaid reads only digests, so it is outside that limit; (c) a producer stamp covering lowering/typing for FileSaid's code hash (db06 UNIT scope item 5-6: the memory-pass fold). decl-lower (07b): per-declaration Typed/Folded/Resolved answers so FileSaid decomposes into per-declaration answers and a one-body edit reaches one declaration (below file grain); not needed for the first slice. The Receivers split and per-file mint are 07c/07a leftovers and stay parked behind these.
Ping: waiting for your go on the slice; nothing built or pushed.

[edit-path 2026-10-13T05:29Z] ROOT MECHANISM, so we write ONE: my DB 08 slice 1 (branch linked, draft not pushed yet) uses ONLY the store's own door — Store.keep_reading(family, key, bytes, reads: List<Read{name,digest}>) to keep and Store.get_valid(family, key, now: fn(name)->digest?) to read back (#618), no new root type or row kind. The 'Linked' answer is the build's host-fns row (its bytes) kept with reads = the tools as one named read + each linked file by path; `now` is a closure over the current toolchain. It deletes the links witness (links_key/links_text/links_unchanged) and the tools row (tools_key), net -12 lines in build.av. program_key (format 4) stays for now: check/suite/build share it, so it dies with the Verdict root for check — your FileSaid/M2 shape, which can use the same two calls (reads = text digest, seen interface digests, ...). If you want a shared helper (reads from a list of names + a digest closure), tell me its signature and I will use yours; I will not add one.

[decl-lower 2026-10-13T06:09Z] db-registrations f08b9abd (no PR): Sig, Marks, Methods (by decl wire), Parsed/Items/Visible/Resolved (by path), Named (by bucket name) registered as AnswerRefs on decls.rows_db AFTER arm_recording; Kernel.hash_forced forces lazy folds. AVRA_LEAVES=1 reports Typed-on-names: std-http 3439/4633, cli 8349/16149, std-avrac 16842/25509. Touches: std-relation db.av (export AnswerRef, answers_forgotten), engine/kernel.av (folds, hash_forced), features/decls.av (bucket_label, bucket_standing, let_go), compiler/{leaves.av new, workspace.av one call, program.av report}, core/debug.av flag.

[decl-lower 2026-10-13T06:10Z] HOOK PROPOSAL for the consuming step (a Typed whose reads still hold is skipped), on edit-path's door: ONE saved answer per declaration, family TypedSaid(decl): value = the encodable pieces of Typed(d) {diagnostics as RelLoc facts (#651 rel_loc), outgoing refs as decl wires, rule findings, the Typed digest}; reads = for each Leaf of rdb.leaves_of(kernel.deps_of(Typed(d))) one Read{name: leaf.id() (family\tspelled), digest: leaf digest} — exactly what db-registrations now makes available (AVRA_LEAVES counts how many Typed have ALL their leaves nameable). KEEP: at the end of a check, per Typed(d) whose leaves are all nameable, Store.keep_reading(TypedSaid, decl_ref(d), bytes, reads). SERVE: before Workspace.typed(d) computes, Store.get_valid(TypedSaid, decl_ref(d)); valid means every read's CURRENT digest (AnswerRef.arg(spelled) then hash_forced) equals — the validation asks the callee Sig/Parsed/Resolved/Named answers, which the edited file's own analysis settles first; an unasked-yet answer is asked (cheap sigs) or the answer is refused (never served unvalidated). A served decl skips Folded/Typed for it; consumers that read its TypeFacts today (file_refs, rule_findings, Folded) must read the saved pieces instead — THAT is the M4/07b work and the reason serving cannot be a flag. Receivers (Writes) is store-tw's; a Typed with an unnameable read is not kept. Tell me if your FileSaid already has a different seam and I will use that.

[2026-10-13T06:27:32Z] items-kept REPORT 23 — M1: FileSaid beside the hold (branch filesaid, local commit, NOT pushed per CI_RULE; base main 69522c3d)
BUILT. compiler/filesaid.av: FileRead {Text, Run(j), Runs, Gathered, Seen(module), SeenSet} named answers; keep_filesaid at derive.keep_parts files a Stored.Unit row 'filesaid/<path>' via Store.keep_reading (the #618 shape: (name, digest) pairs, digest = digest_of(the part)); its value is the okey the hold's rows are filed under (held_okey). filesaid_judged in record.read_why, after stands_in, only under AVRA_DB_VERIFY (core/debug.av db_verified, a licensed debug flag): saved = reads all still equal AND the rows under the recorded key exist; logs 'Q verify <path> hold <b> saved <b> <first moved read>'. 
DISAGREEMENTS (Sprite avra-rb524, cli, fresh store, AVRA_DB_VERIFY=1 AVRA_QTRACE=1; compared = files that reached stands_in, counted per attempt): cli unchanged 0 compared (a cache hit asks no file); body literal 485 compared / 0 disagree; add fn 1926 / 0; add type+impl 1942 / 0; types.av method-body edit 481 / 0 (held 433/501).
FINDINGS ON THE WAY (each real). (1) obj_key_cached's memo and key_parts_cached's memo disagree after resolve_pending_reads (derive.av:901 rewrites object_parts, not object_keys): in a body edit 484 of 485 held files read key_of_parts(current parts) != the memo'd okey; rows are filed under the memo'd one, so the hold is consistent with itself, but a comparison of 'the key' with 'the parts now' is not — FileSaid's value is therefore held_okey, not key_of_parts. (2) first count had 1 disagreement per run: my codec lost the ROOT module (name ''), 'seen ' — fixed; it is the only 'missing read' class found, and it was a codec bug, not a hold one. (3) 0 'hold over-reads' and 0 'read list missing a read' once (1)-(2) were accounted for.
LIMIT, stated. The reads are KeyParts' own parts named, so equality with the hold's decision is close to tautological; what the count proves is that the set/names/codec lose nothing and that the rows-present half agrees. It does not yet prove completeness against what a file's answer truly depends on (that is M3's job: recompute one file and compare bytes). No speed claim.
NEXT. I do not have the db-slice M2/M3 spec (no .lead/lanes/db-slice.md exists): please send it or say go for: M2 = the unchanged check decided by FileSaid alone (the hold's stands_in not consulted) on cache-attacks' edit sequences; M3 = a body edit re-derives only the file whose reads moved.

[decl-lower 2026-10-13T06:28Z] db-registrations updated: Sig (held/builtin sigs digested as the sig), ConstTyped (spelled by the const decl wire + seat fps; expression roots unnamed) registered; leaves meter generalized (Workspace.leaves_meter(fam, count) — one call per family: edit-path adds Lowered); `make leaves` (tools/leaves.sh --check, baseline tools/leaves.baseline). Counts: cli 8482/16155 Typed on names (Receivers 7633, Input 12, Lifted 47, Manifest 3); std-avrac 16962/25515 (Receivers 8478, Lifted 75, Input 25, Manifest 3).

[2026-10-13T06:33:30Z] items-kept REPORT 24 — M2 NUMBER AND WHAT M3 NEEDS (branch db-slice = origin/main + filesaid; nothing pushed)
M2. An unchanged cli check ALREADY answers from saved roots and never enters holding()/load/admit: Workspace.checked (derive.av:326) computes program_key and reads three rows (warn/findings/licenses) and returns reused:true. Measured on the Sprite (compiler of this tree): cli unchanged 214 / 222 / 244 / 208 ms; a tiny package unchanged 63-67 ms; process start (--help) 24 ms. So the ~150 ms above the tiny package is the per-file work of program_key: listing, reading and digesting ~730 sources every run. The ONE missing piece is db06's input manifest with the stat-tier compare (path, size, mtime -> the digest kept last time; read+hash only a file whose stamp moved) — the old Stored.Fp stamps row existed and was deleted. Not built here (the rule: say the missing piece, no workaround).
M3. A body edit re-deriving ONLY the edited file needs three things I do not have: (1) the hold's key work (read_why 0.5 s: KeyParts + view_parts/reach) replaced by FileSaid reads verified through db06's reverse index, otherwise it stays O(files x reads); (2) rows filed under a stable name instead of okey: held_okey/obj_key_cached are used at 26 sites (objects, asks, codes, unit rows, const units, instances) — FileSaid can replace the KEY only by moving all 26 to 'filed under filesaid/<path>, valid while its recorded reads hold' (that move is what deletes KeyParts, key_of_parts, obj_key_cached, object_keys/object_parts and the parts+seen rows; ~600 lines by count of record.av 1097-1306 + derive keep_parts + interface key fns); (3) by-name loading of what the edited file's typing asks (decl-lower's registrations; today load_interface + settle_holds + mint cost ~1.9 s of 5.2 s and the cone mints ~all modules, REPORT 16/19).
PROPOSAL (smallest correct step, deletes code): do (2) now, behind the verify switch's agreement: file every per-file row under stable 'filesaid/<path>' with keep_reading, drop okey, and the hold's decision becomes get_valid on that row. No speed claim until db06's manifest/reverse index. I can have it in about 3 hours; M3's speed waits on db06 (1) and decl-lower (3).

[2026-10-13T06:50:31Z] items-kept REPORT 25 — db-slice pushed (branch only): origin/main 69522c3d + filesaid (M1) + origin/db-registrations 8c012d99 + attack um
M1 numbers as REPORT 23 (0 disagreements on five scenarios). M2 as specified (manifest confirms inputs -> suspect set empty -> FileSaid roots stand): BLOCKED on one piece, db06's Store.suspects + input table — origin/db-store-inplace does not exist, no suspect code on any origin branch; asked in .lead/lanes/db06.md with the exact calls I will make. What holds today: attack um (cache-attacks): a cold check then an unchanged one with AVRA_DB_VERIFY=1 AVRA_QTRACE=1 prints 0 attempt/parse/verify/mint events (passes on the merged tree). Number unchanged: 208-244 ms vs 220; the cost is program_key digesting ~1,415 sources (db06: store open 14 ms; process 24 ms), which only the manifest's stamp tier removes. M3: blocked on the same piece. Deleted lines so far: 0 (nothing is covered yet). The stale memo (derive.av:901): FileSaid works around it (value = held_okey); it dies with KeyParts when the okey sites move (REPORT 24 step 2), so I am not fixing it.
Merge note: debug.av conflicted (AVRA_DB_VERIFY vs AVRA_LEAVES flags), kept both; the first-gen build of the merged tree took 844 s (leaves.av) vs 160 s before.

[2026-10-13T06:51:47Z] items-kept REPORT 26 — step (2) read through; the merge of fn-add-verdicts is clean (db-slice db10bd72, pushed); db-store-inplace is still not on origin
STEP (2) IS NOT ONE CHANGE, and the reason matters before I cut. The okey (key_of_parts) is not only the hold's key; it is the CONTENT ADDRESS that four more row families derive their own keys from: unit rows for instantiations (workspace_analysis.av:482 inst_key_of(held_okey(home file), shapes, symbol)), const units (interface.av:119 ['const', okey, name]), const-unit presence in read_why, objects (build.av:745/796 object_key_of_parts, Stored.Obj) and db06's answers (answers.av:14 key_of_parts). They stay valid today BECAUSE their key moves when the file's parts move. If I file the said/asks/codes rows under a stable 'filesaid/<path>' and gate them by get_valid, those four families would still hang off a key that no longer moves: a stale instantiation unit, const verdict or object would be served after the home file changed. So a stable name needs EVERY derived row to be kept with the file's reads (keep_reading) and served through get_valid: units, const units, instances, objects, answers — 26 sites, six families — in one change, or in an order where each family converts and its key fold dies (objects last: a content-addressed object is also what DB 11's shared store wants).
THEREFORE THE ORDER I PROPOSE, each landing alone, each deleting: (a) said/rules/findings + asks/codes rows -> stable name + reads, validity = get_valid, gated where stands_in gates today; keeps a SECOND key (the content okey) alive for units/consts/objects until (b)/(c), so (a) deletes parts+seen rows and explain's PartMoved only if FileSaid's moved-read names replace them (explain --why prints 'moved module X's interface' from those rows today); (b) const units + instantiation units + answers.av -> reads; (c) objects -> reads, then key_of_parts/obj_key_cached/object_keys/KeyParts die in one deletion (est. ~600 lines, record.av 1097-1306 and 1678-1850, derive keep_parts, the interface key fns, Keys/Hold fields; real count when done). That is ~3 landings and a day, not an afternoon, and none of it is faster until the suspect set (db06) skips the recomputation — which I can use the moment origin/db-store-inplace exists (M3).
ASK: (1) confirm the order (a)->(b)->(c), or tell me objects stay content-addressed (then KeyParts survives for them and only the hold/said/asks/codes/units move); (2) push db-store-inplace.

[2026-10-13T07:56:56Z] items-kept CORRECTION to REPORT 23 finding (1): there is NO stale memo at derive.av:901. obj_key_cached returns object_key_of_parts = node_key(Stored.Obj, [compiler_id, key_of_parts(k)]); my verify compared the recorded value against key_of_parts(k) — two different functions — so '484 key moved' was my comparison, not a defect. derive.av:901 updates object_keys and object_parts together. Retracted.

## db06 -> items-kept (db-slice)
- Suspect set: branch `db-store-inplace` @109deb5d (pushed). `Store.suspects(moved: List<string>) -> List<string>`: record keys of rows that read any moved input name; ids only, no value fetched, no row decoded. Empty `moved` -> empty. First call 15-19 ms incl. pack open, next 2-3 ms (8,450 rows). Body v4 persists the reverse section.
- Input manifest: build.av `confirmed_key` / `keep_manifest` (no-op cli check ~30 ms faster).
- #678 state: branch `db06-4b`, draft, CI run cancelled by lead. Decls over `durable_db(answer_hooks(slot))`, `Stored.Answer`, `@input file_text` + `Workspace.stage_text` (compiler/answers.av), answers_test 4/4. Cross-binary reuse needs #670 (toolchain stamp arm for Stored.Answer). Open: whether `keep_answer` gets a live store.

## REPORT 27 (2026-10-13) step (a) done, db-slice d7767c6d pushed
- said/rules/findings/asks/codes rows are named by file path, valid by recorded reads (`keep_reading`/`get_valid`); old okey keys, dual write, AVRA_DB_VERIFY, M1 FileSaid row deleted.
- Verify before deletion: 0 disagreements (body 487, add-fn 487, add type+impl 1950, types.av method 483; unchanged 0 compared).
- Net vs previous two commits: +106/-121 (-15). Real deletion comes with (c): KeyParts/key_of_parts/obj_key_cached; parts/seen rows + PartMoved stay until moved-read names replace them.
- Gates: cache-attacks 386 builds / 133 held / 0 failed; std-avrac 8744/8744, 334 programs; fmt clean.
- Timings (cli, Sprite): noop 833 ms, body edit 4.7-6.3 s (0 attempts), add fn 5.5-7.1 s.
- RULING NEEDED: stable-name rows are latest-only, so no undo-history caching (content-addressed rows survived excursions). Attack `mh` line "show.av held" dropped for that reason (comment in tools/cache_attacks.sh).

## REPORT 28 (2026-10-13, partial) M3 wired, merged db-store-inplace 109deb5d into db-slice
- Rows' reads are now globally named ("text <path>", "run <path> j", "runs/gathered/seen-set <path>", "seen <module>"). Workspace.suspect_rows: files whose text differs from their row's recorded digest, then every file seeing a module those sit in, to a fixpoint, through Store.suspects. Store.unsuspected = packed, not aside, present, not in the set. AVRA_DB_VERIFY judges both and traces `suspect-missed`; AVRA_DB_FAST lets an unsuspected row stand with no key_parts.
- cli body edit (Sprite): suspects 355 rows of 503 files x5 rows = ~71 files (not "1"; a body edit moves its module's `seen`, readers are suspect until the interface digest is judged). Verify: 0 disagreements on body edit and add fn.
- Wall: FAST 4.7 / 7.5 / 5.2 s vs plain 4.7 / 7.7 / 5.3 s => NO wall gain: judging ~430 standing files costs nothing measurable; the 2.2-2.4 s `load` is not key_parts.
- Found: a suspect set computed while only the entry file is admitted is unsound (url files in attack `ur`); set now recomputed when the admitted file count changes. Full cache-attacks under FAST re-running.

## REPORT 29 (2026-10-13) db-slice de0bf1f4 pushed (M3 wired, behind AVRA_DB_FAST; std-avrac 8748/8748, cache-attacks 386/0 under FAST+VERIFY, 0 suspect-missed)
- NOOP: 833 ms was ONE sample, the first noop after a cold build (it also wrote the manifest/pack). Every noop since, same tip, Sprite: 196, 278, 296, 312 ms (db06: 247-265). Verify was off. No regression to chase; I will log noop as median of 3 from now on.
- Soundness found while verifying FAST: a file with NO kept row must count as moved (a new file changes its module's interface). Fixed. Still unsound by design: a file REMOVED from a module (not in all_files, no text to compare) -- needs a per-module membership input; attacks did not catch it.
- Suspects on a cli body edit: 71 files (355 rows) because `seen <module>` of the edited module is assumed moved. Early cutoff (judge the edited file, then decide readers by its new interface digest) is the way to ~1-5.
- Step 1 (admit only suspects) blockers, 5 lines: (1) admission is driven by `use` reaches from the entry, not by the store, so an unsuspected file is admitted before anyone asks if it stands; (2) its decls are needed to type suspects' bodies (types, sigs) -- they must come from the kept SIGS (db registrations), which is decl-lower's unfinished repair (6cf3ab81); (3) lazy-mint2 gave no gain because the cone of a leaf edit reached ~all modules; with a 1-5 file suspect set that reason no longer holds, so it is worth redoing AFTER early cutoff; (4) `Said` for an unsuspected file is already in the store (said/findings rows), so the check answer needs no load for it; (5) order: early cutoff first (mine, filesaid.av), then lazy admit (needs decl-lower's registrations).
- Next: early cutoff.

## from decl-lower (2026-10-13): d2 of the discarded attempts, the ORDERING (yours)
- Measured (cli, no verify): after attempt 0 reads the edited file and writes the records, d2 is "reads the records again, moved under it" (6.2 s on an attack.av body edit, 12.1 s on a shared.av signature edit): Reads.Adrift, `Turn` at derive.av ~98 (`moved >= 2` refuses).
- Which keys move at the write: held_okey of each held file that SEES a module whose record was just rewritten — KeyParts.seen carries that module's interface digest, and the edited module's interface is known only after its parse, so every held file seeing it has a new key than the one the hold judged by (stands_in false). Same cause #677 names ("holds' keys moved when the records were written").
- The fix is your order: derive the new interface digests (suspects by text) BEFORE judging holds, so the key the hold uses is the post-write key; d2 then has nothing to move.

## REPORT 30 (2026-10-13) db-slice be227565: db-registrations merged, membership input, ordering finding
- Merged origin/db-registrations (3ba9448d lineage) into db-slice: Keys is the union of both lineages' fields; my first_moved renamed moved_read (leaves.av owns first_moved). Plain cache-attacks 386/0, FAST 386/0, stable over 2 runs. (AVRA_DB_VERIFY now also turns on decl-lower's verify, which currently trips `loweredsaid mismatch` in attacks c/a/b/d -- theirs, not mine; I run FAST without it.)
- Removed-file hole: module file lists are kept (Unit row "members", written in kept()); a module whose list differs makes readers of `seen <module>` suspect. Attack `rmv` (impl file removed -> check refuses; returned -> reader stands) passes plain and FAST. WITNESS NOT OBTAINED: with the membership check disabled the attack still passes, because the refusal comes from whole-program passes and the held reader's diagnostics are not the ones that change. So the hole is unproven either way; the code is in, the attack does not bite. A biting case needs a removed file whose only effect is on a held reader's OWN diagnostics.
- ORDERING (your priority) -- finding, before I touch derive.av: the current flow is OPTIMISTIC, not wrong. Readers are judged (stands_in) against the OLD record before the edited file is parsed; if its interface then moves, kept()'s adrift check turns the attempt (the discard). For a body edit the interface does not move: 0 attempts, 0 discards, held 501/503 (measured). So "judge readers after the new interface digests" changes only the interface-moved case (it would replace a discarded attempt by a lazier judge); it does nothing for the 3 s body edit.
- Where the body-edit time is (explain --stats --time, cli, leaf body edit, Sprite): load 3723 ms, lower 947, analyze 616, keep 430, bodies 431, ast 283, sublang 152. `load` = holding(): load_interface for EVERY held module (record decode + mint of ~500 files), settle_holds minting every held declaration. That is the O(program) cost; judging is not in it.
- So the actionable design step is: holding() loads only modules a suspect (or the entry) reaches, rest by name on demand, AND the whole-program families that read every decl row (Receivers 229 reads, References 358, MethodDiags 1224, Settled 2128, CancelReach 230 -- from the same explain output) must stop reading them. That is lazy-mint2 again; it gave no gain because those families pull every module back in. Needs: suspect-keyed versions of those families (db06/decl-lower) before lazy load can show a number.
- Receipt for 'suspects 71 -> N' not produced: the cutoff needs the edited file's record, i.e. after parse; implementing it in derive.av would save judging (measured ~0), not load.

## REPORT 31 (2026-10-13) turn-loop measurement, cli first leaf edit (attack.av literal), db-slice be227565, Sprite, QTRACE
- 1 discard (attempt 0 -> attempt 1 "reading 417"), held 498/504, load 3279 ms. Q unkept lines at the adrift check: 0. So the turn is NOT `adrift` (d2): it is `having_read` adding 417 files, i.e. d1 (const verdicts), which is decl-lower's `lead_reads`.
- d2 (records moved under the hold) only shows once d1/d3 are removed from attempt 0, per decl-lower's own log (it appears at attempt 2). I cannot measure or fix d2 before their lead_reads PR lands; starting derive.av work on it now would be guessing.
- Next: when decl-lower's lead_reads is on main (or its branch sha is named), merge it into db-slice, rerun this script (tools/_ik_m3c.sh), and read the d2 causes from `Q unkept ... <first moved read>`. Standing by for that sha.

## REPORT 32 (2026-10-13) db-slice: verify split, rmv decided
- AVRA_DB_VERIFY=filesaid|typed|lowered|all (`1` = all); mine (filesaid) no longer trips theirs. The four+ loweredsaid-mismatch attacks and unit names are in edit-path.md.
- rmv: made it bite three ways (type removed; trait impl removed; inherent method impl removed, called only in a reader's body) with the membership check DISABLED and rebuilt each time: all three attacks still pass under FAST (390 builds / 0 failed). Reason: a module's record that names a file the module no longer has is refused whole (record_fault, load_named), so the module is read and its importers' imports re-resolve; the removal never reaches the suspect set's judgement as a stand. So the membership input was dead code; DELETED (net -40 lines). rmv stays as the attack that pins the record-fault path under FAST.
- d2 + on-demand holding(): d2 waits on decl-lower's lead_reads (not on main / not on origin/decl-lower*); I need that sha to measure d2's causes.

## REPORT 33 (2026-10-14) db-slice 88fef451 pushed: WIP triaged, files-loaded receipt (511 of 511), lead-exact merged; cache-attacks + std-avrac RED from the `Writes` family (pre-existing)

1. WIP STATE (worktree avra-items-kept, branch db-slice; origin/db-slice 9a50bf32 -> 88fef451, pushed, NOT armed).
- SOUND, committed c20ae137 `explain --stats: files loaded, of the program's own — the on-demand load's receipt`: `Workspace.loaded_files()` = `records.met_files` count, `program_files()` = `decls.file_count()` (whole.av), and the `--stats --time` row `files loaded N of M` (commands/explain.av).
- SOUND, committed f4be8b29 `cache-attacks: close the um section, so lz is a section of its own`: the WIP's missing `fi` after the `um` attack (lz was nested inside um).
- DROPPED as scratch/moved aside to /tmp (never `git checkout --`): uncommitted `tools/fs_ik.sh`, `tools/ta_ik.sh` (AVRA_DB_VERIFY tally / wall_ms probes; superseded by the committed `_ik_*` receipts). `_ik_*.sh` are .gitignored local scratch.
- MERGED origin/lead-exact (3b8e4804) into db-slice -> 88fef451, clean; d2's prerequisite is pushed (see 4). One generation built with the standing binary; `fmt --check: 2 examined, 0 differing, 0 refused`.

2. THE RECEIPT: `./avra explain --stats --time packages/cli` and `./avra check --time packages/cli` after a fresh cache, a leaf body edit of cli/commands/attack.av (`fn attack_cap() -> int { 500 }` -> 501/502/503), on avra-rb524.
BEFORE (WIP only, f4be8b29):
    explain --stats --time  noop/body.1/body.2/body.3: `files loaded    511 of 511`  (each)
    body.3 phases: `time ast 177ms, sublang 166ms, parse 2ms, resolve 494ms, sigs 6ms, bodies 493ms, load 2167ms, admit 322ms, analyze 1129ms, lower 1043ms, keep 917ms`
AFTER (origin/lead-exact merged, 88fef451):
    noop   `files loaded    511 of 511`  `time ast 81ms, sublang 92ms, parse 0ms, resolve 29ms, sigs 0ms, bodies 996ms, load 2348ms, admit 95ms, analyze 1224ms, lower 1041ms, keep 391ms`
    body.1 `files loaded    511 of 511`  `time ast 186ms, sublang 255ms, parse 3ms, resolve 550ms, sigs 5ms, bodies 481ms, load 2604ms, admit 180ms, analyze 1175ms, lower 1036ms, keep 889ms`
    body.2 `files loaded    511 of 511`  `load 2704ms`
    body.3 `files loaded    511 of 511`  `load 2704ms`
    check --time (the edit's own derivation) body.1: `held 505/511, attempt 0, discarded 1, refused 0, load 2612ms`; `check --time` fresh-cache first edit: `held 509/511, attempt 0, discarded 0, refused 0, load 2359ms` (lead-exact took the body edit's turn to 0 discarded).
READING: every file the program knows (511, not 503 — the cli workspace carries its test files) is supplied by a record; NOTHING is on demand yet. `load` ~2.2-2.7 s, unchanged by the merge. The receipt is the baseline an on-demand `holding()` must move, and it has NOT moved.

3. WHAT IT CHANGES / NEXT STEP. The on-demand `holding()` load is NOT implemented in this WIP: `holding()` still calls `load_interface` for every `held_module` (derive.av:640) and `settle_holds` mints every held declaration. The instrumentation is the receipt; the load is the target. NEXT: load only modules a suspect (or the entry) reaches, rest by name on demand — blocked by the whole-program families reading every decl row (Receivers 409 edges, References 784, MethodDiags 1135, Settled 1055, CancelReach 365 from the same --stats output), so their suspect-keyed narrowing must land first; lazy-mint2 already showed no gain for that reason (REPORT 16). Then re-run the receipt (goal: `files loaded` << 511, load < 1 s).

4. d2: NOT BLOCKED — origin/lead-exact IS pushed (git ls-remote: `3b8e4804 refs/heads/lead-exact`), merged at 88fef451. It is read at:
    - `packages/std-avrac/src/compiler/derive.av:720` — `let adrift = [path for path in held_paths(self) if !self.stands_in(store, path, at.want)]`
    - `packages/std-avrac/src/compiler/derive.av:721` — `if !adrift.is_empty() { fail at.adrift(adrift) }`  (the held okey is read inside `stands_in`, derive.av:478; the turn is `fn adrift`'s `moved >= 2` refusal, derive.av:98-99)
    Post-merge a leaf body edit shows `attempt 0, discarded 0` (fresh cache): d2 does not fire there.

5. BLOCKERS (both RED, both PRE-EXISTING on db-slice, NOT from lead-exact and NOT from the WIP).
(a) `make cache-attacks`: `cache-attacks: 449 builds through one store, 145 under a hold, 0 failed` then cache-attacks-b fails:
    `FAIL  an unrelated fn beside a collect's members: w/table.av was read`
    `FAIL  an unrelated fn beside a collect's members: an attempt was thrown away: time: ast 1ms, sublang 0ms, parse 0ms, resolve 0ms, sigs 0ms, bodies 0ms, held 8/12, attempt 1, discarded 1, refused 0, load 2ms, admit 2ms, analyze 1ms, lower 0ms, keep 4ms`
    `fn-add-attack: 43 checks, 2 failed` / `make: *** [Makefile:613: cache-attacks-b] Error 1`
    WITNESSED PRE-MERGE: the same two lines on a build of f4be8b29 with the lead-exact merge REVERTED (tools/fn_add_attack.sh alone). So the merge is not the cause.
(b) `avra test packages/std-avrac`: `8807/8811 tests passed` then `STOPPED — .../packages/std-avrac/build/suite reported a failure above; the rest of the suite never ran` (TEST_RC=1). The four:
    - `decl_grain_test.av:183` "a declaration added keeps every query of main's, answering alike"
    - `decl_grain_test.av:188` "`two`, ... renamed keeps them" — frontier `actual: ...,Typed,Visible,Writes` vs `expected: ...,Typed,Visible`
    - `family_reflect_test.av:9` "are minted as variants in name order"
    - `family_reflect_test.av:12` "each answers the word it was declared with"
    SUSPECT: db-slice commit `5db788cd` ("receivers: a fn's write bit is its own answer (Writes)...") added `@family("DeclId", "int") type Writes = {}` (compiler/families/families.av) without touching either test; `family_reflect_test.av` hardcodes 37 names and `Family.all().length == 37` (now 38 incl. Writes), and `decl_grain`'s live frontier comparison now carries Writes. Not in origin/main. Recorded green was REPORT 29 (`std-avrac 8748/8748`) at de0bf1f4, so the break is between de0bf1f4 and 88fef451; the `Writes` family is the common cause of (a) and (b) (both are "an unrelated addition moves a query"), and it is the receivers lane's to judge — do NOT paper over decl_grain with a Writes-added expectation until that is answered.
(c) On-demand load itself: blocked on the whole-program families' narrowing (3) and, per REPORT 29, decl-lower's kept SIGS registrations for typing suspects' bodies.

## REPORT 34 (2026-10-14) db-slice 86df6e81 pushed: MethodDiags narrowed to its own methods' tables

1. WHAT LANDED. `method_diagnostics(f)` no longer scans the whole type table. `file_method_clashes(f)`
   (workspace_analysis.av) walks `decls_of_file(f)` alone, finds each method's target type
   (`method_target`: its impl's target, or the declaring record) and asks `Methods(target)` — a clash
   is recorded at the LATER method of a type's namespace, so f's clashes are exactly those at f's own
   methods. Deleted with it: `touch_method_tables`, `method_clash_index`, `type MethodDiagIndex`, the
   `method_diags` memo Cell, the now-dead `is_type_decl`, and the `Clash` import. Net -37 lines.

2. RECEIPT — `./avra explain --stats --time packages/cli`, fresh store (`mv .avra-cache` aside), leaf
   body edit of `cli/commands/attack.av` (`fn attack_cap() -> int { 500 }` -> 601/602), Sprite
   avra-rb524, gen-2 product (route's gen-1 + `make avra`). Output quoted verbatim:

   BEFORE (88fef451):
     noop   files loaded    511 of 511   time ... load 12595ms
            MethodDiags      1  1111  1111  1111  1111      Methods  1111  1322 ...
     body.1 files loaded    511 of 511   time ast 182ms, sublang 258ms, parse 3ms, resolve 495ms, sigs 5ms, bodies 495ms, load 2725ms, admit 181ms, analyze 1159ms, lower 1218ms, keep 922ms
            read calls 4080635   abandoned frames 3
            MethodDiags      6  6810  1135  1135  1135
            Methods       1135  1418     1     4    15
            Receivers        1   409   409   409   409
            References       1   784   784   784   784
            Settled          2  1055     0     0  1055
            CancelReach      1   365   365   365   365
            Writes          99    99     1     1     1
            total        18818 18339
     body.2 same as body.1 (load 2792ms)

   AFTER (86df6e81):
     noop   files loaded    511 of 511   time ... load 3604ms
            MethodDiags      1     1     1     1     1      Methods      1     1 ...
     body.1 files loaded    511 of 511   time ast 174ms, sublang 250ms, parse 3ms, resolve 464ms, sigs 5ms, bodies 14ms, load 2626ms, admit 182ms, analyze 770ms, lower 1068ms, keep 932ms
            read calls 863390   abandoned frames 3
            MethodDiags      6    76     1     8    63
            Methods         7    38     4     8    15
            Receivers        1   409   409   409   409
            References       1   784   784   784   784
            Settled          2  1055     0     0  1055
            CancelReach      1   365   365   365   365
            Writes           99   99     1     1     1
            total        17688 10225
     body.2 same as body.1 (load 2636ms)

   READ: MethodDiags edges 6810 -> 76 (-99%); its longest read 1135 -> 63. Methods cells 1135 -> 7,
   edges 1418 -> 38 — the whole method-table scan is gone from the derivation (read calls
   4,080,635 -> 863,390; `bodies` 495ms -> 14ms). `files loaded 511 of 511` and body-edit `load`
   ~2.6s are UNCHANGED: on-demand `holding()` is still NOT implemented; this removes one of the
   whole-program families that would pull every module back in. Receivers (409), References (784),
   Settled (1055), CancelReach (365) are untouched — the next cuts.

3. VALIDATION. `avra test packages/std-avrac/src/compiler/tests`: 1387/1391 — the SAME 4 pre-existing
   (decl_grain_test.av:183/188, family_reflect_test.av:9/12; lower-cold's Writes family).
   `make cache-attacks`: `cache-attacks: 449 builds through one store, 145 under a hold, 0 failed`;
   fn-add-attack the SAME 2 pre-existing (below). `fmt --check`: 3 examined, 0 differing, 0 refused.
   Idioms `check packages/std-avrac --baseline tools/idioms.baseline`: 21 NEW sites, ALL pre-existing
   on db-slice (leaves.av, workspace.av `writes_verified` free_state_verb, body.av, fp.av, decls.av,
   kernel.av, db.av) — none in this change; the one I introduced (`structs.index_compared`,
   `c.file.index == f.index`) is fixed by comparing the FileId (`c.file == f`). The branch's 21 are a
   pre-existing gate blocker for whoever lands next.

4. THE 2 cache-attacks FAILURES — REAL defect, not a stale attack; same owner as the 4 std-avrac tests.
     FAIL  an unrelated fn beside a collect's members: w/table.av was read
     FAIL  an unrelated fn beside a collect's members: an attempt was thrown away: time: ast 1ms,
           sublang 0ms, parse 0ms, resolve 0ms, sigs 0ms, bodies 0ms, held 8/12, attempt 1,
           discarded 1, refused 0, load 3ms, admit 2ms, analyze 1ms, lower 0ms, keep 4ms
   Exact checks: `tools/fn_add_attack.sh` check 10, second half — `add w/members 'fn zz_beside_members()
   -> int { 1 }'` then `not_read "an unrelated fn beside a collect's members" n/count.av w/table.av`
   and `no_discard`. Not stale: the branch's OWN invariant ("a fn nobody spells moves nothing",
   #639/#681, store-tw) is violated, and store-tw ran this attack GREEN at 43/43 on its branch — so
   this is a regression from merging the `Writes`/receivers-split lineage into db-slice. The shape:
   `writes_of(d)` (receivers.av:75) computes a per-declaration answer by running the WHOLE-program
   `receivers()` survey, so a `Writes(d)` cell reads every unheld fn's Syntax/Sig; a reader standing
   on any write bit then stands on the whole program, and an unrelated fn added anywhere moves its key
   (the discard). The fix is the `Fixpoint<List<bool>>` member split store-tw already DESIGNED
   (store-tw.md 06:27Z): own = summary(d).own, edges = Flow, reads its callees' members only. I did not
   isolate further inside this lane's budget; named precisely for the lead. Same `Writes` family as the
   4 std-avrac stale tests — lower-cold.

5. PUSH. `origin/db-slice 88fef451 -> 86df6e81` (fast-forward, NOT armed); sha
   `86df6e8132650cbc5519b6e7dccdab196fc3cb5b`.

6. BLOCKERS. (a) On-demand `holding()` waits on the remaining families: Receivers 409 (store-tw's
   Fixpoint split, above), References 784 (edit-path's refs-per-name, WIP/DO NOT MERGE — merge,
   do not redo), Settled 1055, CancelReach 365 (store-tw's CancelBits per-decl). (b) the 21
   pre-existing idiom sites must be baselined or fixed before the gate.

## REPORT 35 (2026-10-14) db-slice 86df6e81: Settled's 1055 traced to the kept-verdict view — STOPPED, not edited (slow-gen1/keys own it)

0. OUTCOME. Per the task's coordinate clause, I did NOT edit. The reads that make `Settled`
   whole-program on a leaf body edit live in `kept_settle.av` (slow-gen1, #751) and in the
   `fn nobody spells` view narrowing (keys lane, #639/#681). Tree left clean at 86df6e81;
   nothing pushed. Receipt and mechanism below.

1. WHICH READS. `./avra explain --stats --time packages/cli`, fresh store, leaf body edit of
   `cli/commands/attack.av` (`fn attack_cap() -> int { 500 }` -> 601), Sprite avra-rb524,
   one-generation product. Baseline (86df6e81), quoted from `tools/_ik_fam.sh base`:

     noop   files loaded 511 of 511   read calls 321608   (no `Settled` row: 0 cells)
     body.1 files loaded 511 of 511   read calls 863390
            Settled   2  1055  0  0  1055
            total 17688 10225
     body.2 same as body.1

   The two cells (instrumented `--stats` detail, `AVRA_FAM_DETAIL=Settled`):

     Settled(unit 0)   .../std-avrac/src/compiler/codes.av~const~~builtin_codes#   edges 0
     Settled(unit 25)  .../packages/cli/src/commands/attack.av~const~~attack#       edges 1055

   `attack` is the exported `export command attack { ... run: AttackCmd {} }` value. Its direct
   reads, counted by family (`AVRA_FAM_READS=Settled`):

     Input 901, HeldSig 79, Syntax 40, LiftLowered 9, Typed 9, Sig 8, Parsed 5,
     Items 2, Analysis 1, Manifest 1

2. MECHANISM — two halves, both outside the `Settled` family's own code.
   (a) THE CONST GENUINELY REACHES THE PROGRAM. `run: dyn Runnable` packs a vtable over every
       `impl Runnable`; lowering it enters `AttackCmd.run`'s body, which calls `avra()` (the
       assembled language) — the reads `Syntax/Typed(avra · mod.av)`, `LiftLowered(unit 6)`,
       `Syntax/Typed(eprintln · prelude.av)`, `command.*`/`CliResult.arg` — and every held
       module's `HeldSig` (79). This half is inherent to the value; it cannot be made
       per-declaration.
   (b) THE RE-SETTLE ITSELF IS THE DEFECT. The const should have been SERVED: its own syntax
       did not move (`attack_cap`'s body did). But `kept_verdict` -> `view_stands` ->
       `kept_file_stands(attack.av)` fails, because the `v` view's file line holds
       `outline_values(attack.av)`, and `outline_syntax` for a `.Fn` is `self.syntax(d)` — the
       WHOLE declaration, BODY included. A bystander fn's body edit moves the file outline and
       so the const's verdict, and the whole-program settlement re-runs. The same keep path
       then re-scans every file's tokens (`keep_verdict` -> `seen_view` -> `narrow_names_digest`
       -> `tokens_of`), which is where the mass of the 901 `Input(text)` reads come from.

3. THE PROBE (temporary, reverted). Neutralizing `narrow_module_names`'s token scan
   (`let sees = own`) and re-running the same receipt:

     body.1  Settled 2 913 0 0 913   read calls 831311
     reads by family: Input 759, HeldSig 79, Syntax 40, LiftLowered 9, Typed 9, Sig 8, ...

   So the token scan is ~142 of the 1055; the ~840 remaining are the const's genuine reach plus
   the per-unit `outline`/`text_digest` of every unit the run entered. The decisive fix is not
   here at all: if the file outline held a fn's SIGNATURE rather than its body, the verdict would
   STAND and no `Settled` cell would exist on the body edit.

4. COORDINATION / WHERE THE FIX LIVES. All of the above is in `packages/std-avrac/src/compiler/
   kept_settle.av` (`keep_verdict`, `kept_verdict`, `view_stands`/`kept_file_stands`,
   `outline_values`/`outline_syntax`, `seen_view`/`narrow_names_digest`/`tokens_of`,
   `narrow_module_names`) — slow-gen1's #751 path — and the same `sees`/spelled-names narrowing is
   the keys lane's #639/#681 (`fn nobody spells`). Per the task's explicit clause I did not touch
   it. ASK: whichever lane lands the view narrowing should also drop a bystander fn's BODY from
   `outline_values`, which converges the `fn-add-attack` failure (report 34 §4) and removes the
   `Settled` re-settle together — they are one mechanism seen from two sides.

5. GATE / PUSH. No code change, so no new gate run and no push: `origin/db-slice` stays at
   `86df6e8132650cbc5519b6e7dccdab196fc3cb5b`; the gate is report 34's (pre-existing red:
   `fn-add-attack 43 checks, 2 failed`; 4 std-avrac tests; 21 idiom sites).

6. BLOCKERS. (a) `Settled` 1055 cannot be narrowed from this lane's files — it is the const's
   whole-program reach plus the kept-verdict view, both `kept_settle.av`. (b) Receivers 409,
   References 784, CancelReach 365 are unchanged and still unclaimed/other-lane. (c) The receipt
   probe script is `tools/_ik_settle.py` (gitignored scratch); the instrumentation patch is at
   `/tmp/ik-instrument.patch`.

## REPORT 36 (2026-10-14) db-slice ec276593 pushed — the on-demand holding() load landed; files loaded 511 -> 131 (2 on a no-op)

1. MERGE STATE — the required narrowing was attempted and DOES NOT APPLY; per the task's clause it
   is reported, not guessed. `origin/refs-per-name` (5e8209fa) merges TEXTUALLY CLEAN (no conflicts)
   but is SEMANTICALLY incompatible with db-slice: the merge alone, with the load files reverted,
   gives `avra test packages/std-avrac/src/compiler/tests` = **1365/1392, 27 failures**, of which 23
   are new — cache_walk_test:74/84, decl_rows_test:59/62/65/72/75/78/86/95/116, facts_family_test:50/60,
   held_sig_test:58/65, method_rows_test:34/38/51, names_family_test:48/58, readmit_test:166,
   syntax_failures_test:57, syntax_receivers_test:56, written_where_test:60/69 — plus the 4
   pre-existing (decl_grain:183/188, family_reflect:9/12). Cause: refs-per-name's head drags the
   `9de94c27` "digests: canonical format" lineage (bd5172f5..9de94c27) that db-slice's base does not
   carry, so its dependency-list behaviour is not db-slice's; its own commit 5f49d9a4 is marked
   "(WIP, DO NOT MERGE)". `origin/lower-cold-parsecut` (bd5e990d) merges with three conflicts
   (cache_walk.av, workspace.av, family_reflect_test.av — family arms, resolved as unions) and the
   union tree is 1371/1396, 25 failures, verified NOT the load's (the load files reverted to 04f2c47
   give the identical 25). Both branches were dropped; db-slice = 86df6e81 + the load.

2. ON-DEMAND LOAD + RECEIPT. `holding()` no longer calls `load_interface` for every held module.
   `record.av` gains `bare_interface` — the record walk that registers every file and indexes every
   module's impl/trait names WITHOUT loading an interface or meeting a file; `derive.av holding()`
   calls it for the root modules, computes the suspect set (`suspect_rows`, the store's reverse
   index), and loads for real only the modules a file whose kept rows no longer stand sits in. Every
   other file is `hold_only`'d and contributes its FileSaid rows (`filesaid.av file_rows_stand`,
   `store.unsuspected` over Warn+asks+codes). The whole-program families may still MINT those files
   lazily (`file_ensured`/`named_minted`), which never increments `met_files` — so `files loaded`
   drops while the derivation's reads do not. Quoted (`avra explain --stats --time packages/cli`,
   fresh store, leaf body edit of `cli/commands/attack.av` `fn attack_cap` 500 -> 601, Sprite
   avra-rb524, gen-2, gated sha):

     BEFORE (86df6e81, report 34): files loaded 511 of 511; body load ~2725ms; noop load ~3604ms
     AFTER  (ec276593):
       noop  files loaded 2 of 511    time ast 105ms, sublang 119ms, parse 0ms, resolve 35ms, sigs 0ms, bodies 1ms, load 1967ms, admit 121ms, analyze 1086ms, lower 1236ms, keep 446ms
       body  files loaded 131 of 511  time ast 247ms, sublang 343ms, parse 4ms, resolve 946ms, sigs 7ms, bodies 22ms, load 2574ms, admit 253ms, analyze 1384ms, lower 1775ms, keep 1038ms

   Target met: N = 2 / 131 < 511. `load` falls ~0.8-1.6 s; read calls are unchanged (863683 vs
   863390), so the same work is done and only the load stops paying for files whose rows stand. The
   remaining `load` is the names-only record walk + the suspect hash, not `load_interface`; a
   producer index (07a) is what would cut it below ~1 s.

3. GATE (ec276593, Sprite).
   - `make cache-attacks`: `cache-attacks: 449 builds through one store, 145 under a hold, 0 failed`
     (main section green, same as baseline). `fn-add-attack: 43 checks, 2 failed` — the SAME two
     PRE-EXISTING failures:
       `FAIL  an unrelated fn beside a collect's members: w/table.av was read`
       `FAIL  an unrelated fn beside a collect's members: an attempt was thrown away: ... held 8/12, attempt 1, discarded 1 ...`
     Not mine: identical on 86df6e81 and on the lower-cold merge with the load reverted.
   - `avra test packages/std-avrac`: `8807/8811 tests passed` then `STOPPED — .../build/suite
     reported a failure above; the rest of the suite never ran` — the SAME 4 PRE-EXISTING failures
     (decl_grain_test.av:183/188, family_reflect_test.av:9/12; lower-cold's Writes family). The
     compiler-tests subset alone is `1387/1391`, also the same 4: the load adds ZERO failures
     (witnessed: the subset with the load files reverted is identical).
   - `avra fmt --check` on the three changed files: `fmt --check: 3 examined, 0 differing, 0 refused`.

4. SHA. `origin/db-slice 86df6e81 -> ec276593` (fast-forward, NOT armed):
   `ec27659383d698d0b9d23543bbd4890cc12c1b18`. Worktree clean; only `_ik_*.sh` scratch is untracked
   (gitignored).

5. BLOCKERS. (a) refs-per-name / lower-cold-parsecut do not apply to db-slice (step 1): the first is
   a DO-NOT-MERGE WIP carrying an unreconciled digests/leaves lineage, the second's union leaves 25
   spec failures. Landing the `9de94c27` lineage onto db-slice needs the dependency-list tests
   reconciled in the same change. (b) The two `fn-add-attack` failures are the `Writes`/`receivers()`
   whole-program survey (store-tw.md 06:27Z's `Fixpoint<List<bool>>` member split — the task's
   "Writes -> lower-cold"); untouched here, and the remaining reason `make cache-attacks` is not 0
   failed. (c) `Settled` (keys #639), `CancelReach` (store-tw) and `References` (refs-per-name) are
   still the families whose per-decl narrowing would let the names-only walk itself shrink; the load
   already stops `load_interface` for every file whose rows stand regardless of them.

[2026-10-14T10:16:36Z] items-kept REPORT 37 — the walk's cheapest cut is a PREFETCH, REFUTED; headline measured; gate clean; NO PUSH (db-slice stays ec276593)

1. HEADLINE. `tools/warm_edit_bench.sh` on Sprite avra-rb524, host linux-x86-64-amd-epyc, least-of-3,
   `check packages/cli`:
     baseline (db-slice ec276593, branch store from report 36): `warm unchanged 170` / `warm edit 6297`
     baseline (rebuilt after the revert, fresh store):        `warm unchanged 178` / `warm edit 6478`
     WITH the attempted cut:                                   `warm unchanged 192` / `warm edit 6659`
     WITH the attempted cut (second run):                      `warm unchanged 226` / `warm edit 6701`
   `explain --stats --time packages/cli` phase rows with the cut: noop `files loaded 2 of 511`,
   `time ast 94ms ... load 1909ms`; body edit `files loaded 131 of 511`, `load 2530ms`. Report 36's
   pre-cut rows: noop 2 of 511 / load 1967ms; edit 131 of 511 / load 2574ms. THE NO-OP'S OWN
   `warm unchanged` moved 170 -> 178 -> 226 (~27%) across runs, so the ~180-200ms edit delta is at or
   under the benchmark's environmental spread: the cut does NOT show on the owner's number and may be
   a small regression.

2. THE ATTEMPTED CUT, AND WHY IT IS REFUTED. `load_named` (record.av) computed `record_places` for
   every names-only module; `record_places` is used there only by the file loop's `places.get(f)`
   filter, and the `file_id` expansion registers a module whole anyway, so the filter never changes
   the registered set. I deferred `record_places` to the MEETING walk (`meet == true`). Measured `bare`
   (the names-only walk) fell 863ms -> 603ms (noop) and 848/949 -> 594/650 (edit), matching its
   instrumented cost (`places 254343us over 819 calls`). BUT the warm edit did not improve (6478
   baseline vs 6659/6701). MECHANISM: `record_places` IS needed on a `check` — `unruled` -> `held_okey`
   -> `obj_key_cached` -> `key_parts` reads `record_places(...).get(path)` for EVERY held file
   (record.av `key_parts`). The walk computes it OUTSIDE any query; deferring it computes it INSIDE
   `unruled`/the interface queries, where the kernel records reads — so the walk's decode is a
   PREFETCH, not waste, and deferring it is a wash-to-regression. No safe cut of the walk improves
   `check`.
   Instrumented per-module breakdown of the 819 `load_named` calls (818 names-only): imports 3.17s
   (nested, includes children), files (file_id registration) 505ms, places 254ms, fields 87ms, text
   79ms, fault 35ms. Both `files` registration and the record decode are needed by `check`.

3. GATE. `make cache-attacks-a`: `cache-attacks: 449 builds through one store, 145 under a hold, 0
   failed`. `make cache-attacks` then reached `cache-attacks-b` and stopped on the 2 PRE-EXISTING
   `fn-add-attack` failures (reaching b proves a passed): `fn-add-attack: 43 checks, 2 failed` —
   `FAIL  an unrelated fn beside a collect's members: w/table.av was read` and `FAIL  an unrelated fn
   beside a collect's members: an attempt was thrown away: ... held 8/12, attempt 1, discarded 1 ...`.
   Every other b-attack reported 0 failed (link, turn-memory, gathered, store-reads, static-names,
   moved-tree, held-runs, store-quiet, store-seal, store-index).
   `./avra test packages/std-avrac/src/compiler/tests`: `1387/1391 tests passed`, the SAME 4
   PRE-EXISTING failures (decl_grain_test.av:183/188, family_reflect_test.av:9/12). `./avra test
   packages/std-avrac` (the full suite) did not finish inside an 1800s run bound on the Sprite (it
   reached only "205 rule examples proved"); the compiler-tests subset is the reported one.
   ZERO-NEW-FAILURES PROOF (revert-diff): reverted the change (`git apply -R`), rebuilt, ran the same
   subset: `1387/1391 tests passed` with the IDENTICAL 4 failures.
   `./avra fmt --check packages/std-avrac/src/compiler/record.av`: `fmt --check: 1 examined, 0
   differing, 0 refused`.

4. SHA. No change landed — the attempted cut was reverted and the tree is clean: `origin/db-slice`
   stays `ec27659383d698d0b9d23543bbd4890cc12c1b18`. Nothing to push.

5. BLOCKERS / NEXT. (a) The names-only walk's record decode is a prefetch `check` needs; the only
   cut left is the producer index PROPER (07a: rows/buckets as named parts of their producer's answer,
   or a durable per-file names/runs index) so `load_named` can register files and answer names WITHOUT
   decoding every record — not a deferral of a decode that is needed anyway. (b) The other cost center
   is `unruled`'s per-held-file `held_okey`/`key_parts_cached` (the ~900ms of `load` outside the
   walk/suspect segments), also not safely cut by deferring the decode. (c) The two `fn-add-attack`
   failures stay pre-existing (`kept_settle.av` outline grain, #639), not this lane's.

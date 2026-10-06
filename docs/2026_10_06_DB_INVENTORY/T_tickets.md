# T_tickets — disposition inventory of the compiler-DB ticket tree

Source: `/Users/tristan/projects/tristanMatthias/avra/.tasks/avra.db`, read READ-ONLY via `sqlite3 -readonly` (tasks, comments, dependencies), 2026-10-05.
Code reference for spot checks: `/Users/tristan/projects/tristanMatthias/avra-db-design` @ `05fe643` (origin/main).

**How this was produced.** The DB was dumped to `T_raw_57.txt` (263 tickets: avra-8sb5.57 + every descendant, 413 KB incl. all comments) and `T_raw_other.txt` (186 tickets: .65*, .44*, .67–.78, .36, .76, .34, plus every ticket whose title matches cache/hold/held/kept/kernel/query/relation/db/store/witness/warm/memo/stamp/fingerprint/incremental). Seven reader agents each read one slice in full and wrote `T_part_57_p1..p4.md` and `T_part_other_p1..p3.md`. Sections 1, 3 and the defect tables below are those extractions, appended verbatim (Appendices A–C). Sections 0, 2, 4, 5 are my synthesis; section 5's spot checks are my own greps. Everything quoted from a ticket is the TICKET'S CLAIM unless marked VERIFIED (grep in avra-db-design, file:line given).

Counts (MEASURED, sqlite): epic avra-8sb5.57 tree = 263 tickets: 252 closed, 3 in_progress (.57.9, .57.12, .57.101), 8 open (.57, .57.9.7, .57.12.5, .57.101.11, .57.101.12, .57.163, .57.164, .57.165). Tickets created per day: 09-26: 19, 09-27: 94, 09-28: 61, 09-29: 31, 09-30: 28, 10-01: 24, 10-02: 2, 10-05: 2, 10-06: 1 (ticket clock; .165 is stamped 10-06).

NOTE: the townhall doc `docs/2026_09_26_COMPILER_DB_TOWNHALL.md` is NOT in origin/main (absent from `avra-db-design/docs/`); the only copy found is the untracked file in the stale checkout `avra/docs/` (174,442 bytes, mtime Sep 29 17:17). Citations "townhall:LINE" below are to that file.

---

## 0. Vocabulary decoder (what the tickets mean by each term)

| term | meaning | evidence |
|---|---|---|
| M0 | "Db is an identity — tables behind Cell, sweep 6 copy sites, delete side caches beside rows" | .57.1 title |
| M0b | "every durable row is keyed by its producing compiler (§4.3 now)" | .57.25 |
| M1 | "Relation<T> in query/; 22 memo fields -> Db.families; last-reader stamp" | .57.2 |
| M2a | "WRAP directive; annotation uses count as references (.25.70); refuse same-name twins (2hij)" | .57.3 |
| M2 | "@relation/@query derives — marks id/@key/@unique/@index, key records, stable hashes, codecs" | .57.4 |
| M3a / M3 | "the pack's mmap runtime row, landed alone as Unhosted" / "durable witnesses — settle writes deps as (stable name, hash); packed per-package append-only file" | .57.5 / .57.6 |
| M4 | "held-file reads record Sig deps; bypass lint inside query brackets" | .57.7 |
| M5 | "Decls tables -> relations; indexes declared; collect as a Db query (N1, N2)" | .57.8 |
| M5b | "the AST and pass facts as relations — arena and column storage" | .57.18 |
| M6 | "projections — ErrorSite/Raised + topology; docs via Decl index; Canon via witness" | .57.9 |
| N1 | "A comprehension over a relation IS a query, and the compiler picks the declared index" | townhall:2793; .57.10 |
| N1b | "joins — a comprehension with two for heads, over relations and @model alike" | .57.17 |
| N2 | "A multi-valued `@index` over a `List` field"; "collect then lowers to N1 over Decl" | townhall:2842-2845; .57.11 |
| N3 | "`collect enum`" — synthesize Family/DbKind | townhall:2864; .57.12 |
| N4 | "WRAP directives (M2a)" — defined ONLY in the townhall (townhall:2872); the string "N4" appears in no .57 ticket (grep count 0 in T_raw_57.txt). Its ticket is .57.3. | townhall:51, 2872 |
| N5 | "`@query(fixpoint)`" — "semi-naive worklist over set-growing recursive groups" | townhall:2877; .57.13 |
| N6 | "`avra explain why <query>(<args>)`. It prints the witness tree" — built as `avra cache` | townhall:2902; .57.14 |
| N7 | "`@input` on a Db accessor" (`db.file_text`, `db.env`) | townhall:2908; .57.15 |
| N8 | "More of the compiler as declared relations" — Reference/Finding relations | townhall:2913; .57.16 |
| townhall §4 | the lead's 10 numbered decisions (one Db per command; dense addressing; witness covers everything read + compiler digest; Db is an identity behind a Cell; witness = (stable name, value hash); durable row reads only through `ask`; row + witness settle in one step; compiler DB is not an @std/db instance; accessors are static fns on the relation; a field's type decides hash/codec, `<T>Stored`, `@local`) | townhall:2063-2118 |
| townhall §6.5a | "Measured: kernel grain cannot persist." … "**Decision (lead).** The durable witness is the hold path's `KeyParts`: a file's text plus each module it imports' interface digest, per file. … Kernel-grain deps stay in-process. Fine-grained recording happens lazily, only when `avra cache why` asks. The flattened recording and its switch are deleted." The exact phrase "nothing kernel-grain persists" appears in NO ticket and not in the townhall; the nearest wordings are "kernel grain cannot persist" (townhall:2427) and "kernel-grain deps stay in-process" (.57.55 receipt). | townhall:2402-2446 |
| townhall §6.6 | "Performance rules (from PERF, binding)": one packed append-only file per package, shape fingerprint per record header, codec, "Dense `(family, arg)` addressing on every hot path", "Every phase lands with a `make census` before/after for `check packages/cli`". "§6.6" is cited in NO .57 ticket (grep count 0). Its pack was built (.57.6.2) then deleted (.57.149/.150). | townhall:2448-2520 |
| §6.11 | "the relation is the INTERFACE, the arena is the STORAGE"; reads record at the OWNING QUERY's grain | .57.2, .57.18 |
| hold / held / kept | a file (or module) reused warm from its kept record without re-reading; "held N/M" counts; "the hold was refused … built from its sources" is a load-bearing phrase for tools/cache_attacks.sh and tools/hold_sweep.sh (.57.44) | .57.40, .57.6.5, .57.44 |
| KeyParts | "file text + each imported module's iface digest, stands_in root-down" — since 10-01 THE durable witness | .57.4.6, .57.55 |
| witness | three senses: (a) kernel dep witness "(stable name, hash)" (built 09-28, deleted 10-01); (b) a test witnessed failing; (c) scripts `tools/witness_*.sh` | .57.6, .57.55 |
| families | kernel query families (memo spaces keyed `(family, arg)`); count drifts 12→13→19→22→26→27→28→30 across tickets; VERIFIED 32 `@family` markers today (families.av) | see §5 |
| stamps | (a) kernel last-reader stamp (edge dedup, .57.2/.30/.31/.56); (b) file size/time/inode stamp trusted over bytes — DELETED (.57.19: "text_digest always hashes, stamp cache deleted"); (c) std-relation "stamp+sweep" owner runs (.57.8.2) | |
| ARM / armed | not a milestone: "arming" = wiring std-relation `Db.Hooks` to the kernel (`relation_hooks(kernel)` vs `quiet_hooks()`); "Arming turns on write-once-after-read (revision >= 0)" (.57.4.7); ~1% cold cost "Accepted cost (lead's call)" (.57.137) | |
| S3 | THREE different things: N6 S3 (interface forms kept by iface digest, landed 1936811, .57.14); M5 S3a/S3b (`Decls.seats`, ERRORS' chain, .57.83); M5b S3 (per-declaration durable reuse — "CLOSED AS A RECORDED FINDING … not built", .57.18) | |
| kept binary | `avra build`'s whole-program hit: "avra BUILD reuses through the HELD-OBJECT path (records + kept objects), not witnesses" (.57.85); "an embedded file's edit moves the kept binary and the kept const" (.57.164) | |
| consume | R3 consuming-seat inference (`consumed_seat` in records; .57.73/.74/.91/.140) — a memory-pass fact that leaked into hold stability, not a DB verb | |
| collect | `collect enum` language feature (N3, .57.12) + collect's member set as a Decl-bucket query (`gathered`, .57.11.2) + `by … dense` ordering (.57.159) | |
| "Row", "Kernel→Db", "Workspace shrink" | NOT a decision recorded in any .57 ticket (one hit, inside .57.109 as a quoted memory note). The user memory file says the full Row/Kernel→Db/Workspace-shrink "was never committed despite being reported as done". | T_part_57_p3 §B |

---

## 2. Timeline of design decisions (by date)

Who = comment author field is almost always `tristan` (one shared actor); the SESSION named inside the text is given. "↩" = reversed/superseded by.

| date | ticket | session | decision (exact quote) | later fate |
|---|---|---|---|---|
| 09-26 | .57 | owner / COMPILER DB DESIGN (lead) | "The compiler's fact store as a real database; every tool a thin query. … Owner: top priority for the whole team (2026-09-26)." | open epic |
| 09-26 | townhall §4 | lead | 10 decisions (see §0). #5: "A witness is a list of (stable name, value hash). Never a dense id". #6: "A durable row reads only through `ask`." | #5 kernel-grain form ↩ §6.5a (10-01); surviving form = KeyParts |
| 09-26 | .57.2 | PERF (M1) | "arena/column relations must record reads at the OWNING QUERY's grain (none within the owner; one edge per query per owner otherwise), not per node" | stands (§6.11) |
| 09-26 | .57.18 | owner | "Owner-approved 2026-09-26: rename NodeStore -> SyntaxArena … 'Store' stays the on-disk artifact cache" | landed (.57.18.4) |
| 09-27 | .57.22 | LEAD | "LEAD RULING: module-qualify. Stable name = fully qualified dotted import path … No refusal of same-named relations across modules. Recorded in §6.4." | landed 15573ed |
| 09-27 | .57.12 | owner go | "Pulled forward (owner go, 2026-09-27): the LANGUAGE feature 'collect enum' lands now, standalone … Applying it to Family/DbKind waits on M1." | Family half landed 10-02 (#192); DbKind half OPEN (.57.12.5) |
| 09-27 | .57.12 (descr) | lead | "Variants keyed by stable name, never a dense ordinal" | ↩ .57.12.4: "rank dense 0..29"; ordinal = declaration place, guarded by tools/families.py |
| 09-27 | .57.25 | cacheprint / lead | "record_key, Scan, canon_key, program_key now carry compiler_id; UNNAMED store per process"; "compiler_print hashes bytes (never trusts a stamp)" | landed 2b3e5ac |
| 09-27 | .57.19 | cacheprint / lead | "text_digest always hashes, stamp cache deleted, no measurable cost." | landed 92b24db |
| 09-27 | .57.26 | lead | "package scope admits every file of its package; closure stays reachability per lead ruling" | landed d754618 |
| 09-27 | .57.40 | lead | "9ecc31d (don't mark a not-yet read) REJECTED by lead: it silences the write-once-after-read guard for exactly the reader whose answer changes." | — |
| 09-28 | .57.6 | lead | "witnessed_check/open_pack are not wired into avra check yet … M3 part 2 is a library." | library ↩ deleted 10-01 |
| 09-28 | townhall §4.9 / §4.10 | lead (ORM, ERRORS) | "Accessors are static fns on the relation, and the relation holds its rows." / "A row decoded from disk is a DIFFERENT TYPE, `<T>Stored`, with no `@local` columns" ("adopted 2026-09-28") | stands (.57.76/.79) |
| 09-28 | .57.81 | lead ("Decision 9/10 amendment (4)") | "a query reading rows it OWNS is REFUSED (the voice names prior()), unless it reads through prior(); never a silent skip." | landed 1c20088 |
| 09-28 | .57.7 | lead | "Bracket lint parked: static reach from a query bracket covers the whole typer (~3,550 fns). Replaced by M5's dynamic AVRA_DEP_AUDIT" | ↩ 09-29 .57.7.3 (rule `compiler.bypass_outside_bracket` + `@bracket` markers landed) |
| 09-28 | .57.8 | lead | "M5 to ERRORS. Step 1 = AVRA_DEP_AUDIT …" | ownership ↩ 09-29 "moves to IDIOMS" |
| 09-28 | .57.55 | PERF | "Flattened witnesses measured +62..216%; switching to direct-dep red-green (townhall 6.5a)" | ↩ 10-01: not even direct-dep persists |
| 09-28 | .57.72 | lead | "make bootstrap ends at gen-2 … every PERF census must compare fixed point to fixed point" | stands |
| 09-28 | .57.90 | IDIOMS | "in an identity struct, a field whose type is not Cell<...> (or another identity struct) is refused" (`@identity`) | landed 4ee69c3 |
| 09-29 | .57.8.1 | lead ruling A | "S2 (Decl as @relation) = option A: ONE RECORDER. decl(d) keeps the kernel's recorded read (rows_read -> record_dep, per-frame dedup) … ORM's recorded get_from measured ~938 instr/repeat read vs ~90 raw, so a second recorder of the same file-grain edge is the defect." | landed 31b8e21 / 2e99559 |
| 09-29 | .57.105 | ORM (lead's ask) | "Db rows live under Stored.Rows" — "Decl/Sig/Warn/Scan/Canon/Licenses/Findings live under Stored.Rows via Db.insert/get"; Unit and Warn families stay raw | landed 3ccf761 |
| 09-29 | .57.106 | IDIOMS / lead | "Six families settle on real content fingerprints, folded lazily (settle_lazy …)"; fact: "within one process the revision never moves" | landed 3312554 |
| 09-29 | .57.107 | ORM | "held ref lines carry the target's decl_wire (path~kind~owner~name) and resolve with wire_decl; one durable declaration identity." | landed 70667b9 |
| 09-29 | .57.14 | ORM | N6 "Built by ORM as `avra cache` (renamed from explain)"; "store +12.9% (lead approved)" | pack-backed modes ↩ rebuilt as one in-process walk (.57.150) |
| 09-29 | .57.18.1 | IDIOMS | "No @relation storage mode added" | ↩ 10-01 `@arena`/`@side` added (#89) ↩ 10-01 `@arena` "a checked mark only" (#118) |
| 09-30 00:17 | .57.4.6 | PERF / lead | "BLOCKER CHANGED. The .55 witness wire is being deleted (perf/witness-delete); kernel deps stay in-process (≥51.6M deps on cli). A persisted @query row is keyed and validated by its FILE's KeyParts … same grain as the hold path. Townhall §6.5a." | THE pivot: reverses M3 (.57.6) |
| 09-30 | .57.4.6 | ORM | "Only no-row-writing first runs persist; owned rows stay in-process." + named deadline: "a query DECLARED in an imported module whose body changes without its interface moving is read back stale" | open deadline |
| 09-30 | .57.4.7 | ORM / lead | "lead ruled NO pass-2 re-analysis."; "moved_in refuses a late write (returns false) instead of bumping" | landed #72 (51bfc7d) |
| 09-30 | .57.119 | HTTP LEAD | "a module keeps seeing its OWN module whole. Every other module is now keyed on the interface lines of the files it reaches, never on that module's aggregate." "Nothing in the key reads the package table." | landed #54 (8a85aec) |
| 09-30 | .57.8.3 | lead | "Left as hand tables ON PURPOSE: file_decls and decl_ids." | ↩ 10-01 (#99 `@side`, #101 deleted) |
| 09-30 | .57.9.6 | lead | "closing as blocked is not done. The defect is live (Canon's key omits provider block words). Fix it directly" | landed e6290f0 |
| 09-30 | .57.141 | lead | "DEFERRED (lead 2026-09-30)" kept settlement with RUN print + REACH print | built anyway (VERIFIED `compiler/kept_settle.av` exists; #119 68d33f2) |
| 10-01 10:41 | .57.55 | PERF (PR #104) | "per townhall §6.5a the durable witness `avra check` reads and writes IS the hold path's KeyParts (a file's text + each seen module's interface digest), kernel-grain deps stay in-process, and the flattened recording and its switch are DELETED" | landed 85f1046; makes .57.48–.54/.57/.58 moot |
| 10-01 | .57.8.2 | IDIOMS | "A file's admission is ONE RUN of a named owner in the declaration Db (std-relation: owner_named / opened_run / closed_run / put_owned — the same stamp+sweep law a @query uses, no second mechanism)." | landed #101 (d4a9796); reverses "relation rows are never removed" |
| 10-01 13:00→13:51 | .57.18 | lead | 13:00 "Lead approved IDIOMS' CHECK-mode-only cut for S3"; 13:51 "S3 CLOSED AS A RECORDED FINDING (per-decl check-mode durable reuse, not built)" — "worth ≤~5-15% of warm-check wall time" | not built |
| 10-01 14:15 | .57.18 | lead ("paradox-collapse") | "arena_generated now emits an empty impl; @arena is a checked mark only"; NameFacts/TypeFacts: "nothing to build for either" | landed #118 (51d36f4) |
| 10-01 | .57.101 | "BOSS decision on slice-2" | "ABANDON the view_print fingerprint — it is a second, incomplete spelling of the dependency set the kernel already writes as (stable name, hash) witnesses at settle (M3, .57.6)." "Do not re-attempt view_print." | premise ↩ 10-02 (.57.101.11) |
| 10-01 | .57.151 | (P0) | "the family hook must store, per (family, cell), the revision at which the verifier's hash last moved, and answer THAT revision to the kernel" | landed #111 (3f073ba) |
| 10-01 | .57.153 | — | "Store carries `keeping: Keeping` … `.Disk`, or `.Aside(Cell<Map>)`"; "Inspection mutates the thing inspected (P7: inspectable means read-only)." | landed #113 (11fd2d4) |
| 10-01 | .57.154 / .155 | — | "`Marks(d)` (ordinal 27)"; "`Kernel.abandon(key)`"; then "name-bucket grain" for Decl row reads; "per-row Decl recording is §6.5's future, not this slice" | #114 (46d8154), #173 (a6f9072) |
| 10-01 | .57.148 | collect159 / families (BOSS-approved) | "The 28 families do NOT fit that form [townhall `@query fn q(db: Db, k) -> T`]"; "STORAGE-WORD QUESTION — RESOLVED, no storage word … Keep @family(rank, key, answer) for all 28." | landed as internal `@family` markers |
| 10-01 | .57.137 | ERRORS / lead | armed relation hooks ~1%: "Accepted cost (lead's call)." | stands |
| 10-02 | .57.12.4 | families2 | "Family is now the collect enum over the 30 @family markers (rank dense 0..29) … DbKind stays hand-written meanwhile." | #192 (07e0d70) |
| 10-02 | .57.101.11 | warm4 | "CORRECTION (warm4, 2026-10-02): the original premise is FALSE on main. (1) The M3 witness layer does not exist: Stored has no dep kind, Db.deps_of is in-process dense Keys, there is no pack/witnessed_check anywhere" — "PARKED -- no PR." | open |
| 10-02 | .57.101.12 | warm4 | "NEEDED: the M3 layer itself -- at settle (or at keep), write a cell's deps as (stable name, hash) into a durable row, plus a stable-label -> Key codec to re-ask them." "Write at settle, never memo." | open — directly contradicts §6.5a's "kernel grain cannot persist" unless scoped to kept VIEWS only |
| 10-02 | .57.9.7 | db47 / BOSS | "PARKED by BOSS's bound. Reverted cleanly" (doc facts as relations) | open |

### The witness story in one line each
1. 09-26 townhall §4.5/§6.5: witness = kernel deps renamed to (stable name, hash), packed per package (M3).
2. 09-28 built as a library + pack + flattened recording, switch `witness_enabled=false` (.57.6, .57.6.1/.6.2, .57.48–.58, N6 `avra cache` over the pack).
3. 09-28 measured: "+62..216%", pack 279 MB, 33.3 M edges (townhall §6.5a; .57.55).
4. 09-30/10-01 deleted (PR #104 85f1046): durable witness = hold KeyParts; kernel deps in-process only.
5. 10-01 pack.av/explain.av/witness.av deleted, `avra cache` = one lazy in-process walk (`compiler/cache_walk.av`) (.57.149/.150).
6. 10-01 BOSS abandons `view_print` *assuming* M3 witnesses exist; 10-02 warm4: they do not; .57.101.12 re-asks for "the M3 layer itself". UNRESOLVED.

---

## 3. Measurements — headline table (full tables in Appendix B)

All values are TICKET CLAIMS (MEASURED by the named session; not re-run here).

| what | value (quote) | command / base | ticket, date |
|---|---|---|---|
| one Db per command | "cold check-cli 590.5B -> 338.7B instructions (-42.6%), peak ~1.95 GB -> ~816 MB" | check cli, 514c5f9 | townhall:2069 |
| warm no-edit check | "251.8B -> 125.7B (one workspace) -> **0.36B** instructions … peak 1.18 GB -> 7 MB" | check packages/cli, 1c0cad6 | townhall:2497 |
| M1 | "Cold check-cli 327.9B -> 325.8B, warm 0.391B -> 0.366B, peak -12%" | check cli | .57.2 |
| flattened witness size | "median of 74,600 edges per file and 33.3 M edges in all … The pack is 279 MB" | cold check packages/std-avrac, ef0d957 | townhall:2407 |
| flattened witness cost | "cli cold +62%, cli edited +38%, std-avrac cold +116%, std-avrac edited +216%. RECORDING is 88–90% of that." | witness ON vs OFF | townhall:2410; .57.55 "+62..216%" |
| kernel-grain graph size | "≥2.54 M distinct keys with ≥51.6 M direct deps (still climbing when stopped)" | check packages/cli | townhall:2431; .57.4.6 |
| witness ON, edit | "edited 95-150s, leaf edit OOM 4.4GB vs main edited ~5s" | .57.55 | 09-28 |
| hold KeyParts reach | "397/399 on a warm cli edit at near-zero cost" | — | townhall:2438 |
| kernel read cost | unrecorded "~125" instr, stamped HIT "~315", new dep "~1900"; after .31 "hit 330->251, new dep 1907->1453" | /tmp/kbench | .57.30/.31 |
| relation read cost | "~938 instr/repeat read vs ~90 raw" (ORM recorded `get_from`) | — | .57.8.1, 09-29 |
| accessor condition | "PERF cuts the store reach from ~226 instructions to at most 40 … A recorded read must come in at or under ~350 all-in." | — | townhall:2106 (§4.9) |
| Decl as @relation | census "+0.95% (from +19.27%)"; PR #101 "retains -2.95%, list writes +1.32%, wall -2.3%" | check cli census | .57.8.1/.8.2 |
| warm check times | "cold 41.2s; no-op 0.22s; body edit 5.1s held 404/408; new declaration 13.2s held 346/408 (was 52.7s, 0/408, hold refused)" | check packages/cli, one Sprite | .57.6.5, 10-01 |
| warm check phases | "cold 35044 ms, warm (one comment edit) 5190 ms; typing 1875 ms (36%), lowering 604 ms (12%), load+admit 1781 ms (34%)" | check cli | .57.18, 10-01 |
| warm one-line edit | wall 4.43 s (ast 996 ms, sublang 1021 ms, load 1422 ms, admit 1132 ms); slice 4: "parses 48 to 6, load 6415ms to 708ms" | check packages/cli | .57.101, 10-01/02 |
| view_parts cost | 451 ms of a warm check across 70 modules; 0 of 70 view cells settled when the key is asked | — | .57.101 |
| held path fix | "warm edit 274.6B → 25.3B instructions, 20.9 s → 2.33 s" | — | .57.136 |
| fixpoint | one-fn edit 2.91B instr vs 2.86B cold — "zero incrementality" | Raised | .57.9.6 |
| scan vs lookup | `scan_floor` 1000 ("24 ns/row scan vs 145 ns lookup") | — | .57.10.4 |
| arming memory | cold cli build peak 1677 MB; dropped fix "6.9 GB/30 min" | — | .57.4.7 |
| armed hooks | ~1% cold build | — | .57.137 |
| store size | "+12.9% (S2), +16.2% (S3)" (N6); "25.10 -> 22.24 MB" (.57.105; description said "15.79 -> 18.35 MB") | cold check packages/cli | .57.14, .57.105 |
| disk shape | "today's `Store` holds 2,699 files, median 1 byte, 5.9 MB of content in 11 MB on disk" | 23a704f | townhall:2450 |
| .avra-cache total | "~15.9 GB" across about 140 worktrees | — | .57.18.4, 09-29 ("du -sc over ~140 avra-* worktrees") |
| held counts | 607→643 of 717 (.60); 260→710 of 759 (.91); 815/818 (.119); "held 0/715", "0/734" during .40 regression | one-file edit | various |
| cold build | 69 s vs target < 40 s (title: "build 97s back under 40s") | build cli | .57.101 |
| partly-held peak | "3442/3371 MB against 2168/2177 MB cold, and one was killed at 4227 MB"; load 1128 ms, admit 4290 ms | make avra warm | .57.163, 10-05 |
| newly_read hoard | "363 MB in 5.1 M boxes, all live" in `query.Kernel.newly_read`; ~115 of 460 files re-read; 3371–3518 MB | AVRA_MEM_STATS | avra-8sb5.76 |
| test file→dir | "memory ceiling exceeded: 5000 MB"; cold 2.2–2.9 GB, clean warm 552 MB | avra test <file> then <dir> | avra-8sb5.78 |
| cache/cas campaign | build no-op 0.08 s, one edit 0.38–0.42 s, cold ~13 s | 86d7009 (09-21) | avra-8sb5.23 |
| cache-attacks receipts | 113 builds/41 held → 181/66, 0 failed; then 2/186 failing | tools/cache_attacks.sh | .57.119…/.165 |
| seed | 547,374 → 557,782 lines | bootstrap/seed.ll | .57.162 |

NOT FOUND in any ticket: memory PER ROW or PER EDGE in bytes (only instruction counts per read, and the aggregate 363 MB / 5.1 M boxes ≈ 71 bytes/box — ESTIMATED by division, avra-8sb5.76); bytes of persisted KeyParts dependency lists.

---

## 4. Open tickets by theme, and live defects

### 4.1 Open, inside the epic
| theme | ticket | status | what remains / blocks |
|---|---|---|---|
| Durable dep witness (the M3 hole) | .57.101.11 | open, PARKED | key a kept view on kernel witness deps — premise false: no witness layer on main |
| | .57.101.12 | open | build "the M3 layer itself": deps as (stable name, hash) at settle + label→Key codec. Conflicts with §6.5a unless scoped |
| Speed P0 | .57.101 | in_progress | cold build 69 s vs < 40 s; warm slices landed (#182 VERIFIED on main 93acdd3) |
| N3 DbKind half | .57.12 / .57.12.5 | in_progress / open | "blocked on the enum-variant splice" (an enum-variant list refuses a spliced `List<Code>`); DbKind + `DbRow.kind()` are two hand 24-arm matches (VERIFIED db.av:160, :275) |
| M6 projections | .57.9 / .57.9.7 | in_progress / open | doc facts as relations PARKED: `@key` derive "generates nothing" silently; `put_in` past `next_id` breaks Rows' sequential-id invariant |
| Memory | .57.163 | open | partly-held rebuild 1.6× cold; not investigated |
| Kept binary | .57.164 | open (stale status) | fix IS on main: 04a6a89 "embed: … an edit to it rebuilds (#282)"; VERIFIED `embeds_key` build.av:538 |
| Keepers | .57.165 | open | cache-attacks 2/186, fmt-lossless 5 files, codecs 2 pairs red; none in checks.yml (VERIFIED: `.github/workflows/checks.yml:110` keeper loop is `for k in fingerprints vocab families cited externs dogfooding-rules ui-host ui-host-test ui-board` — no cache-attacks / fmt-lossless / codecs; `Makefile:506 cache-attacks:` exists) |

### 4.2 Open, outside the epic (cache / kernel / store)
| theme | ticket | what |
|---|---|---|
| Kernel memory | avra-8sb5.78 (P1), avra-8sb5.76 (P1) | `Kernel.newly_read` hoard; 5 GB trap on file-then-dir test; likely same cause as .57.163; the three are not cross-linked |
| Stale answers | avra-knya (P1) | stale `.avra-cache` served swapped struct identities after an `Expr` variant + feature dir were added (hypothesis: held fact keyed without DeclId layout) |
| | avra-zsc2 (P1) | `.avra-cache` served an object built by an older compiler binary (title only) |
| | avra-8sb5.31 (P1) | deleted test file still named by `unit/` and `sig/` entries; suspect `closure_key` |
| | avra-8sb5.25.20 | held object links against stale asks; seen twice, attack unwritten |
| | avra-8sb5.70 | ui-board hold refused on every edit ("likely" .36, unconfirmed) |
| Hash strength | avra-8sb5.79 | linear fold `h*131+v+7`: `f(g(x))`/`g(f(x))` share one `stmt_fingerprint`; fix restamps every space |
| | avra-8sb5.46 (P1) | 30-bit un-keyed `fp_mix` behind memo early-cutoff and store keys; untriaged |
| | avra-8sb5.9.2 (deferred) | `parsed` early cutoff on structural fps while value carries text+spans; "no non-one-shot host exists" audit predates the persisted cache |
| Key coverage | avra-8sb5.68, .69 | wasm-opt keyed by presence; linker path/CC/CCC_OVERRIDE_OPTIONS/sysroot in no key |
| | avra-8sb5.1.28.8, .1.35, .11.236 | suite/test binary key omits package C objects (three tickets, one defect) |
| Cache root | avra-8sb5.37, .40.17, .11.300 | root location; nested worktree climbs to highest `.git`; tree-root `.avra-cache` kills `make avra` at "4012-4046 MB" |
| Tests | avra-8sb5.72, avra-9vy7 | `anew()` case never calls `anew()`; no held-package harness for interface records |
| Kernel asks | avra-8sb5.11.58, .9.14, .10.136, .11.120, .11.249/.250 | cross-family cycle verdict; passes as a uniform trait (13 `new_memo<`); hand-numbered `@relation` index doors; `let _ = store.keep(…)` ×391; twelve hand-cleared memo cells |
| Planner | avra-8sb5.65.3.2.1 | relation planner narrows comprehension heads only; `rows.filter(…)` chains do not reach `by_tag` |
| ORM | avra-8sb5.44, .44.6.* | `@model` held "per owner, not landing"; typed `sql{}` "Parked 2026-09-26 for Compiler DB M2"; .44.6.1 const budget owner decision pending |

### 4.3 Live defects — symptom / root cause / status
| ticket | symptom | root cause | status |
|---|---|---|---|
| .57.163 | "partly-held rebuild peaks 3442/3371 MB vs cold 2168/2177 MB; one killed at 4227 MB" | not investigated; .76 names `Kernel.newly_read` "363 MB in 5.1 M boxes, all live" (VERIFIED fn exists kernel.av:588) | OPEN |
| .57.165 | cache-attacks 2/186 ("a compile-time value did not cross as Line" — the same 2 are "pre-existing" in .57.101 since 10-01); fmt-lossless 5 files; codecs 2 pairs | not stated | OPEN |
| .57.164 | stale binary after `embed()` file edit | program key + kept const verdict named no embedded file | FIXED on main (#282 04a6a89); ticket still open |
| avra-8sb5.78 | file-then-dir `avra test` > 5 GB | `Kernel.newly_read` top site | OPEN |
| avra-8sb5.76 | title: "the compiler compiles what a program reaches — not every declaration"; comments carry the 3.4 GB partly-held finding | — | OPEN |
| avra-8sb5.36 | hold reads a shifted declared type after a type is inserted above | positional wire; closed on DETECTION: "kept()'s adrift re-check and all_said's held_okey re-derivation both detect the moved interface … Root rewrite = townhall decision 10" (later `decl_wire` path~kind~owner~name, .57.107) | closed 09-28 |
| avra-8sb5.67 | wasm link handed native objects | `Workspace.anew` dropped `keys.build_mode` | FIXED, VERIFIED workspace.av:686 `fresh.keys.build_mode.set(...)`; #272 126552a on main |
| avra-8sb5.68/.69 | wrong tool reuse | tools not in key | OPEN |
| avra-8sb5.70 | ui-board hold refused each edit | unconfirmed | OPEN |
| avra-8sb5.71 | `.staged` left after failed wasm link | reporter retracted the observation | open (stale) |
| avra-8sb5.72 | test never calls `anew()` | — | OPEN |
| avra-8sb5.73 | `avra run`: map filled by `set` quadratic in memory (867 MB vs 2 MB) | evaluator | OPEN (not DB) |
| avra-8sb5.74/.75/.77 | guard_ledger macOS; test leaves build/suite; Sprites stall | — | open (not DB) |
| .57.4.6 deadline | imported `@query` body change read back stale | key = CALLING file's KeyParts | latent ("before any consumer arms Db.answers") |
| .57.154 aside | `loc(d)` reads spans through `Items`, whose print nulls spans | by design | latent |
| .57.25 side | `interface.av` `minted()` trusts held `row.root` with no bound | fix 5cff9ea reverted (da63bf8) | OPEN per text |
| .57.119 | comprehension whose 2nd `for` bound reads the 1st binder types `<error>` silently | not stated | found, not fixed |
| .57.9.7 | `@key` relation derive generates nothing, no diagnostic | — | OPEN |

---

## 5. Contradictions, and spot checks against avra-db-design @ 05fe643

### 5.1 Tickets that decide opposite things
1. **M3 durable witnesses: done vs deleted vs never existed vs needed again.** .57.6 closed as M3 done; .57.6.1/.6.2 "Landed on main: M3 (verified 2026-09-29)"; .57.55 (10-01) "the flattened recording and its switch are DELETED"; .57.101 BOSS (10-01) "the kernel already writes as (stable name, hash) witnesses at settle (M3, .57.6)"; .57.101.11 (10-02) "The M3 witness layer does not exist"; .57.101.12 "NEEDED: the M3 layer itself". VERIFIED: `witnessed_check|witness_enabled|leaves_below|record_witness|reused_check` → 0 hits in packages/ and tools/; `compiler/store/` holds only `store.av`; `Stored` variants are `Sig, Fp, Unit, Obj, Bin, Warn, Rows` (store.av:21-…, no dep kind); `Db.deps_of` is `self.kernel.deps_of(key)` (db.av:618). warm4's 10-02 statement is the true one.
2. **§6.5a vs .57.101.12.** §6.5a: "Measured: kernel grain cannot persist. … Persisting it cannot meet a 1% gate." .57.101.12: write "a cell's deps as (stable name, hash) into a durable row". No ticket reconciles them (a per-kept-view dep list is not the whole graph, but no ticket says so).
3. **Townhall §6.2/§6.3 query form vs families.** Townhall: families become `@query` declarations; .57.148: "The 28 families do NOT fit that form" → internal `@family(rank, key, answer)` marks. .57.148's own title still says "@query declarations".
4. **Stable names vs dense ordinals.** .57.12: "Variants keyed by stable name, never a dense ordinal"; landed: `collect enum Family = @family in self by it.mark.args[0] dense` (VERIFIED families.av:149). Durable rows keyed by family ordinal rely on tools/families.py + tools/families.order (VERIFIED both exist).
5. **`@relation` storage modes** — three positions in three days (.57.18.1 "No @relation storage mode added" → #89 `@arena`/`@side` generate accessors → #118 "@arena is a checked mark only").
6. **NameFacts/TypeFacts as column relations** (.57.18 scope) vs "nothing to build for either" (lead, 10-01).
7. **M5b S3** approved 13:00, closed unbuilt 13:51 the same day.
8. **Hand tables on purpose** (.57.8.3, 09-30) vs deleted (#99/#101, 10-01); "relation rows are never removed" vs owner-run sweep.
9. **.57.4.6 title** "kept answers and owned rows survive the process" vs result "Only no-row-writing first runs persist; owned rows stay in-process."
10. **.57.124 "Nothing new persisted"** vs .57.141 persisted RUN/REACH prints; .57.141 "DEFERRED (lead)" yet built.
11. **.57.150 "Known property: … a second mode run sees nothing moved"** vs .57.153 filing it as a bug and fixing it.
12. **.57.36/.cas "a STORE IS ONE COMPILER'S"** (avra-8sb5.23) vs avra-8sb5.34.2 comment "a cache entry made by one compiler generation was reused by another", avra-zsc2, avra-8sb5.11.300.
13. **.57.40 closed 09-28** while .57.55 seven hours later reports "held 0/734 + intermittent 'Bad settled a second time'".
14. **Family count**: 22 (.57.12), 24 lists (.57.2), 26 (.57.148 descr), 27 (.57.18.2/.154), 28 (.57.148), 30 (.57.12.4). VERIFIED today: 32 `@family(` markers in `compiler/families/families.av`.
15. **.57.125** "stale vtable … a wrong binary" (description) vs "stale in its TYPING, never in its dispatch" (10-01); its unexplained hold explained twice differently (.125: draft defect; .127: stale per-Sprite cache).
16. **CLAUDE.md vs tickets**: .65.3.10 reports `for k, v in m` / map `keys`/`values` landed or queued while CLAUDE.md (stale checkout) still says "A MAP CANNOT BE ITERATED AT ALL" (not DB, noted).

### 5.2 Spot check of the load-bearing "done" claims (my greps, avra-db-design)
| # | claim (ticket) | result | evidence |
|---|---|---|---|
| 1 | flattened witness + switch deleted (.57.55, #104) | TRUE | 0 hits for `witnessed_check|witness_enabled|leaves_below|record_witness|reused_check`; `git log origin/main`: `85f1046 … the flattened witness and its switch are deleted (#104)` |
| 2 | store/pack.av, store/explain.av, compiler/witness.av, explain_names.av deleted; cache_walk.av added (.57.149/.150) | TRUE | `ls compiler/store/` → `store.av` only; `compiler/cache_walk.av` exists; `cache.av:58` `ws.cache_walk()` |
| 3 | Family is a collect enum over `@family` markers (.57.12.4, #192) | TRUE, count drifted | `families.av:149: export collect enum Family = @family in self by it.mark.args[0] dense`; 32 markers (ticket: 30); `07e0d70 … (#192)` |
| 4 | hand `family_at`/`family_count`/`family_gap_voice`/`families()` deleted | TRUE | 0 hits in std-avrac (only unrelated `once fn families()` in std-relation tests) |
| 4b | `family_word` deleted by .12.4 (.57.148 comments 21:29/23:01) | **FALSE** | `compiler/workspace.av:523: fn family_word(f: Family) -> string {`; used at `dep_audit.av:160` |
| 5 | DbKind still hand-written, 24 arms (.57.12.5, open) | TRUE | `db.av:160 export enum DbKind {` — 24 variants Source…Answer; `db.av:275 export enum DbRow {` |
| 6 | `revision_of_hash` in `relation_hooks` (.57.151, #111) | TRUE | `workspace.av:573`, `:597`; `3f073ba … (#111)` |
| 7 | `Keeping {.Disk,.Aside}`, `Workspace.opened_store()`, `inspecting()` (.57.153, #113) | TRUE | `store/store.av:63 export enum Keeping {`; `build.av:185`, `:189`; `11fd2d4 … (#113)` |
| 8 | `Kernel.abandon`, `name_key_at`, `record_names` (.57.154/.155) | TRUE | `features/decls.av:1029 fn name_key_at(b: int) -> Key { Key { family: self.record_names.get(), arg: b } }`; `46d8154 (#114)`, `a6f9072 (#173)` — #173 IS on main (ticket said "queued") |
| 9 | std-relation `owner_named/opened_run/closed_run/put_owned` (.57.8.2, #101) | TRUE | `std-relation/src/db.av:241, :296, :304`; `rows.av:298`; `d4a9796 (#101)` |
| 10 | `file_decls`, `impls_by_name`, `collect_index`/`CollectIndex` removed | TRUE | 0 hits in std-avrac/src |
| 11 | `settle_lazy` + real fingerprints (.57.106) | TRUE | `query/kernel.av:488 fn settle_lazy(key: Key, fingerprint: fn() -> int)`; `query/memo.av:118` |
| 12 | `decl_wire`/`wire_decl` (.57.107) | TRUE | `compiler/interface.av:648`, `:845` |
| 13 | `files_iface`/`ifaces_digest` (.57.119); `view_print` must NOT exist (.57.101) | TRUE / TRUE | `record.av:1074`, `:1083`; `view_print` 0 hits |
| 14 | rule `compiler.bypass_outside_bracket` added; `methods_cell_outside` removed (.57.7.3) | TRUE | `rules_table.av:66 bypass_outside_bracket,`; `methods_cell_outside` 0 hits |
| 15 | `Db.answers(store, KeyParts)`, `DbRow.Answer`, `key_of_parts` (.57.4.6) | TRUE | `compiler/answers.av:12 fn answers(store: Store, parts: KeyParts) -> Durable {`; `db.av:323 Answer(name: string, text: string)`; `record.av:1297` |
| 16 | `@relation @arena` on Expr and Stmt (.57.18 S4) | TRUE; PR number in ticket WRONG | `core/nodes.av:333 @arena`, `:877 @arena`; on main as `51d36f4 … (#118)`. Ticket says `@arena` "a checked mark only" landed as PR #117 — `#117` on main is `61721c7 docs(dogfooding): AVRA_QTRACE's declare line…`. `arena_generated` at `std-relation/src/relation.av:537` |
| 17 | `.57.141` "DEFERRED" kept settlement | BUILT | `compiler/kept_settle.av:40,:56`; `68d33f2 perf(warm): a read file's const reuses its kept verdict … (#119)` |
| 18 | M3a mmap runtime row (.57.5) | TRUE, now orphaned | `runtime/avra_rt.h:183-185` `avra_mmap_open/len/slice`; `runtime/tests/mmap_test.c`; commit `5f0fdd5`. Its only planned user (the pack) is deleted — reader of the row NOT VERIFIED |
| 19 | `Fixpoint<T>`, `FixpointRefusal` (.57.13) | TRUE | `query/fixpoint.av:36`, `:81` |
| 20 | `@input` `file_text` (.57.15) | TRUE | `compiler/inputs.av:21-22`: `@input` / `export fn file_text(_db: RelDb, path: string) -> string { read_text(path) catch "" }` |
| 21 | `records.grammar_scanned` kept (.57.1 reversal) | TRUE | `compiler/voices.av:678`, `:691` |
| 22 | `met_files`, `reached_objects`, `hang_bound`, doc_rows `named_decls/exported_decls/keyed_decl` | TRUE | `record.av:671`; `build.av:619`; `cli/src/commands/tests/*`; `doc_rows.av:14,:21,:34` |
| 23 | `findings_key`, held findings from kept rows (.57.126, #61) | TRUE | `compiler/derive.av:141 fn findings_key(okey: string) -> string { node_key(Stored.Warn, ["findings", okey]) }`; read at `:261` |
| 24 | #72, #182, #173 "queued" in tickets | all ON MAIN | `51bfc7d (#72)`, `93acdd3 (#182)`, `a6f9072 (#173)` |
| 25 | avra-8sb5.67 fix "not pushed" | ON MAIN | `126552a … (avra-8sb5.67) (#272)`; `workspace.av:686` |
| 26 | .57.164 "open" | FIXED ON MAIN | `04a6a89 embed: a const embeds a file of its own package; an edit to it rebuilds (#282)` |

Net: of 26 checked, 1 false claim (`family_word` not deleted), 1 wrong PR number (#117), 4 tickets whose status lags main (.57.164, #72/#173/#182 wording, .67). No "done" ticket names a symbol that is wholly absent — the gap is the reverse: **closed milestone M3 (.57.6) describes a mechanism that no longer exists.**

---

# Appendices (verbatim extractions by the slice readers)

Each appendix concatenates the same section from the seven part files. Part files remain beside this report for sections not copied here (E "done claims", F contradictions per slice, and the full dated decision lists B).


## Appendix A — full ticket table (deliverable 1)

Columns for .57 slices: id | status | title | outcome | worktree/branch. Columns for the related-ticket slices add a relevance column (CORE / ADJACENT / IRRELEVANT). Ids in the .57 slices are relative to `avra-8sb5.` where abbreviated.


### Appendix A / slice 57_p1

| id | status | title (≤80) | outcome | worktree/branch |
|---|---|---|---|---|
| 57 | open | Compiler DB: relations + queries, durable by default, every tool a thin query | Epic, open. Only comment: Db-fork root cause fixed at 8120973 (fix/receiver-typename) | fix/receiver-typename |
| 57.1 | closed | M0: Db is an identity — tables behind Cell, sweep 6 copy sites, delete side caches | Committed lane/db 3f0520f; `grammar_scanned` KEPT (not deleted). Main sha not named | lane/db |
| 57.1.1 | closed | Db.rows behind a Cell; get/insert as Cell writes | closed, no text, no sha named | - |
| 57.1.2 | closed | Sweep the 6 Db copy sites | closed, no text, no sha named | - |
| 57.1.3 | closed | Alias-log receipt + red-team + review round | closed, no text, no sha named | - |
| 57.1.4 | closed | Land on main | closed 2026-09-27T02:27, no sha named | - |
| 57.2 | closed | M1: Relation<T> in query/; 22 memo fields -> Db.families; last-reader stamp | Built lane/m1 898a69f + merge 57d8a39 (also e610add per .12); micro-bench NOT delivered; main sha not named | lane/m1 |
| 57.2.1 | closed | Relation<T> in query/ (Memo<T> + index maintenance) | closed, no text, no sha named | - |
| 57.2.2 | closed | Collapse 22 *_memo fields + 24 family lists into Db.families | closed, no text, no sha named | - |
| 57.2.3 | closed | Last-reader stamp for per-query edge dedup | closed, no text, no sha named | - |
| 57.2.4 | closed | Census: stamped vs unrecorded read cost | Closed with the measurement OPEN: "suite floor swamps the stamped-vs-unrecorded delta"; harness owed before M5b | - |
| 57.3 | closed | M2a: WRAP directive; annotation uses count as references (.25.70); refuse twins | Closed 2026-09-30; scope widened to run/name holes; no sha on the parent | lane/wrap |
| 57.3.1 | closed | 2hij: refuse same-name twins | closed, no sha named | - |
| 57.3.2 | closed | Land 2hij on main | closed 2026-09-27T01:43, no sha named | - |
| 57.3.3 | closed | .25.70: annotation uses count as references | Gate-green lane/wrap 4310ea2 (`mark_refs`) | lane/wrap |
| 57.3.4 | closed | A @derive's generated type is declared (no silent drop) | closed, no text, no sha named | - |
| 57.3.5 | closed | Name holes (type, method) + field-list and struct-literal runs | "landed main 4ea2846 (095dc5e)" | - |
| 57.3.6 | closed | Param run hole + template spans never read vs consumer (j2dl) | Part 1 landed 5725492 (Origin.Spanned); rest shrank to fn param-list grammar alt; final sha not named | - |
| 57.3.7 | closed | WRAP directive (Directive.wraps) + expand golden | closed 2026-09-28T14:34, no text, no sha named | - |
| 57.3.8 | closed | WRAP over a method: the wrapper must splice as a method of its target | Ladder built + QUEUED: lane/wrap-bridge 64ef4d2 then lane/wrap-method3 9480ace; main sha not named | lane/wrap2 (../avra-wrap2), lane/wrap-method, lane/wrap-method2, lane/wrap-bridge, lane/wrap-method3 |
| 57.4 | closed | M2: @relation/@query derives — marks id/@key/@unique/@index, key records, hashes, codecs | Pieces on main 6d894d5, 8aaf557; closed 2026-10-02 with .4.7 | - |
| 57.4.1 | closed | @std/relation: stable hasher + codec (tests first) | closed, no text (parent: main 6d894d5) | - |
| 57.4.2 | closed | @relation -> name / shape_hash / stable_hash / encoded + refusals | closed, no text (parent: main 6d894d5) | - |
| 57.4.3 | closed | Red-team: canonical varints, mark refusals | closed, no text, no sha named | - |
| 57.4.4 | closed | Stable name = qualified import path (.22) | closed, no text, no sha named | - |
| 57.4.5 | closed | Key record + key() + decode | "LANDED on main 66f35cd (lane/relation), 2026-09-28" | lane/relation |
| 57.4.6 | closed | @query persisted: kept answers and owned rows survive the process | "LANDED main bc2d64a (lane/query-persist 4c01397)"; open deadline: imported-query body change reads stale | lane/query, lane/query-persist, lane/witness-wire |
| 57.4.7 | closed | Db accessors over Relation<T> | Landed as PR #72 (arm-decl-rows-gh), "finished + landed" 2026-10-01; main 51bfc7d per .9.7 | ../avra-arm-rows lane/arm-decl-rows, arm-decl-rows-gh, lane/kernel-verify-mark |
| 57.4.8 | closed | Rows<R>: the row store in @std/relation (insert/upsert, uniqueness, buckets, read hook) | closed 2026-09-27T07:19, description only, no sha named | - |
| 57.4.9 | closed | @relation: lookup on a field named key beside a @key field crashes the compiler | "LANDED on main 66f35cd (lane/relation)" | lane/relation |
| 57.4.10 | closed | @relation: @unique is not enforced | "LANDED on main 66f35cd (lane/relation)" | lane/relation |
| 57.4.11 | closed | @relation: a hand-written id in an insert literal is silently discarded | "LANDED on main 66f35cd (lane/relation)" | lane/relation |
| 57.4.12 | closed | std-relation Db: inserting into a closed Db resurrects it, registers hooks twice | "LANDED on main 66f35cd (lane/relation)" | lane/relation |
| 57.4.13 | closed | @relation: no way to remove or replace rows | "LANDED on main 66f35cd (lane/relation)" (which answer landed is not stated) | lane/relation |
| 57.4.14 | closed | @relation: header example (id: CallId) and typed-id/enum fields refused | "LANDED on main 66f35cd (lane/relation)" | lane/relation |
| 57.4.15 | closed | @query in a package's own files is refused annotation.wrap_missing | closed 2026-09-29T07:04, no fix text, no sha named | - |
| 57.4.16 | closed | @relation's <T>Key and <T>Stored records are not exported | Partial fix 8d874c9; real fix filed as .57.104; comment said "Leaving this ticket OPEN until .104 lands" yet closed 2026-09-29T17:27 | - |
| 57.4.17 | closed | @std/relation's module header still says enum/typed id/float refused | closed 2026-09-29T08:01, no sha named | - |
| 57.4.18 | closed | @index over a nullable field: a null-aware bucket | "LANDED 1a7df87 (code 541b4e4)" | - |
| 57.5 | closed | M3a: the pack's mmap runtime row, landed alone as Unhosted | closed 2026-09-27T03:04, no sha named | - |
| 57.5.1 | closed | mmap runtime row + C body, hosted Unhosted | closed, no text | - |
| 57.5.2 | closed | C tests: empty, 1 byte, large, out of range, missing, NUL path | closed, no text | - |
| 57.5.3 | closed | Land with seed refresh | closed, no text | - |
| 57.6 | closed | M3: durable witnesses — settle writes deps as (stable name, hash); packed file | Part 2 landed 61e0abb (499df24) as a LIBRARY, not wired into check; closed 2026-10-01T12:13 after PR #104/#108 receipts | - |
| 57.6.1 | closed | Settle writes deps as (stable name, hash) witness | "Landed on main: M3 (verified 2026-09-29)", no sha | - |
| 57.6.2 | closed | Packed per-package append-only file + commit marker | Part 1 lane/m3-pack 3d8928a/acf73a5/2078026; "Landed on main: M3", 4 wiring items left open in text | ../avra-m3pack lane/m3-pack |
| 57.6.3 | closed | Root-down validation, never materializes; missing dep = mismatch | PR #104 (85f1046): pins zp, dt, ds, nr; `record_stands` | m3-close |
| 57.6.4 | closed | Two-process test: edit a callee's E, stale row refused | PR #104 (85f1046): pin ee | m3-close |
| 57.6.5 | closed | Warm check-cli receipt | Receipt met with PR #108 (dcaba11) | m3-close, hold-new-decl |
| 57.6.6 | closed | held path: a new declaration in a commands file refuses the cli check's hold | PR #108 (dcaba11): `record_shape`, `Shape.Collect` | hold-new-decl, m3-close |
| 57.7 | closed | M4: held-file reads record Sig deps; bypass lint inside query brackets | Held-dep half main ecb9f36 (+899e0ea test fixes); bracket lint parked then landed via .7.3 | ../avra-db-errors lane/db-errors |
| 57.7.1 | closed | Held-file sig reads record a Kernel dep (HeldSig) | closed, no text | - |
| 57.7.2 | closed | Land held-sig half | closed, no text | - |
| 57.7.3 | closed | Bypass lint inside query brackets | "Landed main (lane/bracket-lint2)": compiler.bypass_outside_bracket; no sha; 'decls' fence is a follow-up | ../avra-bracket lane/bracket-lint, lane/bracket-lint2 |
| 57.8 | closed | M5: Decls tables -> relations; indexes declared; collect as a Db query (N1, N2) | chain landed 5cde697; S1 31b8e21; S2 2e99559; hand tables PR #101 (d4a9796) | - |
| 57.8.1 | closed | Decl / File / Module as @relation | "Landed main 2e99559 (lane/m5-decl2)"; S1 main 31b8e21 | ../avra-m5-s2 lane/m5-decl, lane/m5-decl2 |
| 57.8.2 | closed | Delete Decls hand tables and CollectIndex | PR #101 (d4a9796); CollectIndex half main 2e99559; decl_ids PR #99 | decl-replace, lane/m5-index2 |
| 57.8.3 | closed | Indexes declared; census | PR #101 (d4a9796); lane/m5-index cfec46b; PR #99 | lane/m5-index |
| 57.8.4 | closed | Collect suites green over relations | "Landed main 2e99559" | - |
| 57.9 | in_progress | M6: projections — ErrorSite/Raised + topology; docs via Decl index; Canon via witness | Prep landed 9e8ace9, 4d533fd; all children closed except .9.7 (open, blocked) | - |
| 57.9.1 | closed | ErrorSite relation from the per-fn walk query | Landed lane/db-errors b4d19e1 ("landing in progress via land.sh") | lane/db-errors |
| 57.9.2 | closed | Raised relation owned by the fixpoint | "Landed on main at 1c20088" | - |
| 57.9.3 | closed | Catch rows + `within` containment | Delivered by 9e8ace9 + 4d533fd on lane/db-errors, "landing now" | lane/db-errors |
| 57.9.4 | closed | chain tree query + day-one invariant tests | Delivered by 9e8ace9 + 4d533fd; N5 "unbuilt design, out of this ticket's scope" | lane/db-errors |
| 57.9.5 | closed | Docs as two @query fns over Decl | PR #37 (squash c1699cd): doc_rows.av | lane/docs-decl-query-v2 (d8180cb), docs-decl-query-v3 |
| 57.9.6 | closed | Canon provider-word dep; fixpoint re-solve measured | "Landed at e6290f0 on main" (after lead reopened it 2026-09-30) | - |
| 57.9.7 | open | docs: render inside the query -- doc facts as relations | OPEN, PARKED: Shape A reverted; blocked on why a @key relation derive "generates nothing" (wall 5); "Awaiting BOSS/owner call" | docs-render |
| 57.10 | closed | N1: a comprehension over a relation IS a query — compiler picks the declared index | closed 2026-09-30T22:03, via children | - |
| 57.10.1 | closed | Comprehension over a relation lowers to a bucket lookup | "Landed on main: N1 slice 1 (verified 2026-09-29)", no sha | - |
| 57.10.2 | closed | Planner: pure field == value conjunctions, invariant side | "Landed on main: N1 planner (lane/planner)", no sha | lane/planner |
| 57.10.3 | closed | Residual only over a narrowed set; refusals name sub-expr | "Landed on main: 32df0e7 (2026-09-28)" | - |
| 57.10.4 | closed | Unindexed-scan warning past a census-named size | "Landed main 6dba4a5 (lane/scan-warn)": type.plan_scan | lane/scan-warn |
| 57.11 | closed | N2: multi-valued @index over List fields; collect's member set becomes a Db query | "Landed on main (445e080)" | - |
| 57.11.1 | closed | Multi-valued @index over List fields | "Landed on main: 445e080" | - |
| 57.11.2 | closed | collect_members as an N1 query over Decl | "Landed main 2e99559 (lane/m5-index2)" | lane/m5-index2 |
| 57.12 | in_progress | N3: collect enum — synthesize Family/DbKind from @relation/@query in closure | Language feature landed main 0f3da07 (also "64b7d41"); header says in_progress WITH a closed date; DbKind half remains (.12.5) | ../avra-n3 lane/collect-enum |
| 57.12.1 | closed | collect enum: grammar + builder | closed, no text | - |
| 57.12.2 | closed | Variants by stable name, ordered by `by`; refusals | closed, no text | - |
| 57.12.3 | closed | Program tests both engines; IDIOMS review | closed, no text | - |
| 57.12.4 | closed | Apply to Family / DbKind (after M1) | Family half landed PR #192 (ordinal half PR #103); DbKind half moved to .57.12.5, blocked | lane/n3-apply (af411a2), lane/n3-family (4262aa6), families2 |


### Appendix A / slice 57_p2

| id | status | title | outcome | worktree/branch |
|---|---|---|---|---|
| .57.12.5 | open | derive DbKind from DbRow (N3's DbKind half) — blocked on the enum-variant splice | OPEN. Blocked: "an enum-variant list refuses a spliced List<Code>"; needs a Many-joining hole for an enum's variant list. Alternative (derive emits 24 @kind types + `collect enum DbKind`) "refused for a P2 cleanup" | - (filed by families2 after #192) |
| .57.13 | closed | N5: @query(fixpoint) — semi-naive worklist over set-growing recursive groups | "N5 LANDED on main at 9c081e7"; done at a4264fc on lane | lane/db-errors |
| .57.13.1 | closed | Kernel fixpoint mode: semi-naive worklist | closed, no text, no sha named (parent: 9c081e7) | - |
| .57.13.2 | closed | Declared join, monotone refusal, speaking turn cap | closed, no text, no sha named | - |
| .57.13.3 | closed | Prove on a reachability query group | closed, no text, no sha named | - |
| .57.14 | closed | N6: avra explain why <query>(args) and avra explain db | landed main b8dc68f (code 2c13cd4); follow-up 8f53267 (code e9d0090); S1 2817050; S2 3725a7b (code 35a442e); S3 1936811; ref-owner fix f27f3a4. "Built by ORM as avra cache" | - |
| .57.14.1 | closed | avra explain why <query>(args): witness tree | "Built by ORM as `avra cache` (renamed from explain)" — 2817050 (S1) | - |
| .57.14.2 | closed | avra explain db: sizes, hit rates, bytes | same as .14.1 (2817050); hit rates "not in the pack format, so explain db omits them" (.14 comment) | - |
| .57.15 | closed | N7: @input accessors (db.file_text, db.env) — inputs as declared queries | "Landed on main: ced9bb2 (verified 2026-09-29)" | - |
| .57.15.1 | closed | @input accessors: db.file_text, db.env | main ced9bb2 | - |
| .57.16 | closed | N8: Reference and Finding as relations; idiom baseline as query diff; DOGFOODING registry as renderer | closed 2026-09-30; children landed (3fd9d7f, 98df3f5, 6dba4a5) | - |
| .57.16.1 | closed | Reference as a relation | main 3fd9d7f (2026-09-28) | - |
| .57.16.2 | closed | Finding as a relation; baseline as a query diff | main 98df3f5 (2026-09-28) | - |
| .57.16.3 | closed | DOGFOODING registry as a renderer | main 6dba4a5; "@query not used" | lane/dogfood-render |
| .57.17 | closed | N1b: joins — a comprehension with two for heads, over relations and @model alike | language half 7975a2b; "N1 slice 2 landed 33f174c" (relation join lowering) | ../avra-joins, lane/joins |
| .57.17.1 | closed | Several for heads: grammar + ordered clause node | closed, no sha named (parent 7975a2b) | - |
| .57.17.2 | closed | Typing + nested-loop lowering, both engines | closed, no sha named | - |
| .57.17.3 | closed | fmt lossless; subset entry deleted | closed, no sha named | - |
| .57.17.4 | closed | Relation / @model join lowering (after N1) | main 46c5207 (2026-09-28) (parent says 33f174c) | - |
| .57.18 | closed | M5b: the AST and pass facts as relations — arena and column storage | S1 PR #89 (9e68842); S2 PR #102 (cd3df92…); S3 part 1 PR #110 (3187fec…); S3 part 2 "CLOSED AS A RECORDED FINDING … not built"; S4 PR #117 (61721c79) + PR #118 (51d36f49). NameFacts/TypeFacts: "nothing to build" | - |
| .57.18.1 | closed | Expr/Stmt as arena relations over the parse arenas | "landed 3d8e30e"; "No @relation storage mode added" | - |
| .57.18.2 | closed | NameFacts / TypeFacts SideTables as column relations | "Closed as already true"; lane work e8d1641 / 6371f8c / b633486 "Queued" (landing sha not named) | lane/m5b-facts, perf/m5b-names |
| .57.18.3 | closed | @index kind / decl on Expr; syntax(d) owner-slice edges | closed 2026-09-30, no text, no sha named | - |
| .57.18.4 | closed | Rename NodeStore -> SyntaxArena | "LANDED on main: 0d3e1ad" (chain 91496ef→947a037→e50da44→648384b→c69e301→9c71cf8→aaab07b→0d3e1ad); bridge 1ff3783; opt b3e16f6 | - |
| .57.19 | closed | warm cache traps the compiler: edit between two 'avra test <file>' runs -> index 221 oob (length 181) | fixed "cacheprint 92b24db": text_digest always hashes, stamp cache deleted; "LANDED by lead" (main sha not named) | lane/relation (repro needs it) |
| .57.20 | closed | annotation given more args than its fn takes TRAPS the compiler | "Fixed on main 15a6bb2 (6da700f)" | - |
| .57.21 | closed | annotation whose receiver refuses still expands | "Fixed on main 15a6bb2 (6da700f)" | - |
| .57.22 | closed | @relation's stable name is the BARE type name | "Done on main 15573ed (551cb0f)": module-qualified | - |
| .57.23 | closed | torn .avra-cache entry from an interrupted native link, read back as valid | "REFUTED against the current durable tier"; no code change; HEAD 0d3e1ad | ../avra-torn-cache, lane/torn-cache-repro |
| .57.24 | closed | Stale .avra-cache from an older compiler traps a newer one: index 221 oob (length 181) | "FIXED on main (lead, d1ef6d6 via e23e15f)"; residual .40 | ../avra-lane-fmt (land/wrap-12), ../avra-gentype (lane/gen-type), ../repro-24, fix/source-stamps, fix/record-view |
| .57.25 | closed | M0b: every durable row is keyed by its producing compiler (§4.3 now) | fixed cdc0f44 (cacheprint); "LANDED on main at 2b3e5ac (lead)" (merged main 9f3e9cb) | lane/land-tools (5cff9ea reverted by da63bf8), avra-land-tools |
| .57.26 | closed | collect silently misses members in files nothing else reached | "landed main d754618 (fc72593)" | - |
| .57.27 | closed | malformed collect reports an unrelated comprehension error | "landed main d754618 (3827ca7)" | - |
| .57.28 | closed | empty collect enum: missing refusal + silent exit 1 in test batch | "Landed on main (c972222); closed in tracker hygiene" | lane/collect-enum |
| .57.29 | closed | a refusal in the test batch exits 1 silently — an unrendered diagnostic | fixed c972222 on lane; "Landing pending" (main sha not named here) | lane/collect-enum-empty |
| .57.30 | closed | Kernel stamp hit costs ~190 instructions over an unrecorded read | "duplicate of avra-8sb5.57.31" | - |
| .57.31 | closed | Kernel: cut the stamped-hit read path (+~190 instr per repeat read) | "landed via land.sh (lane/k31 86db86c)" | lane/k31 |
| .57.32 | closed | test harness: a two-build program test (edit between builds, assert the second) | closed 2026-09-29, no outcome text, no sha named | - |
| .57.33 | closed | seat_takes: spell every DeclKind in the .Fn and .Trait arms (after N3 lands) | closed 2026-09-27, no outcome text, no sha named | - |
| .57.34 | closed | native: a settled cell of a tagged pair started as stack garbage (use-after-free) | "Landed cf97209 (ORM). Final shape 57999f4"; bfbc38d (blanket zeroing) "was wrong" | - |
| .57.35 | closed | Type-argument holes in a derive template: Rows<${t}>, List<${t}>, ${t}?, Map<string, ${t}> | closed 2026-09-27, no outcome text (later .42 cites 25e7137 as present) | lane/wrap, ../avra-fmt-bugs |
| .57.36 | closed | dead_parameter misreads static methods' params (seat offset) | "landed main 8aaf557 (d0ed851)" | - |
| .57.37 | closed | ParamId: move Param.span into a side table keyed by a typed id | closed 2026-09-27, no outcome text, no sha named | - |
| .57.38 | closed | fmt refuses a blank line between two given blocks instead of normalizing it | closed 2026-09-28, no outcome text, no sha named | - |
| .57.39 | closed | grammar: inner @expect hole then expr_stmt's END recover give TWO refusals | "Landed on main 9c973e5 (fix 18aec91)"; close_reason's 5603e38 "is a lane merge, not main" | lane/relation |
| .57.40 | closed | held path: a held enum's settlement read before its declaration settled — hold refused | closed 2026-09-28T14:24; no landing sha in this ticket; 9ecc31d REJECTED by lead | cacheprint |
| .57.41 | closed | store: two avra processes on one cache race — suite links a half-written object set | "Landed on main (a91dcbf); closed in tracker hygiene" | - |
| .57.42 | closed | A name-holed fn's signature types resolve in the consumer, not the template | closed 2026-09-28T08:42, no outcome text, no sha named | ../avra-rel, lane/relation |
| .57.43 | closed | fmt: a bare run says it only printed | "LANDED on main 2026-09-28 as a729afe" (commit 642e941) | lane/docs |
| .57.44 | closed | derive: a refused hold's fallback reads as a crash | main a729afe (commit 96053e3; idiom fix 51c9baf) | lane/docs |
| .57.45 | closed | one-line quote fn '-> ${t} { ${t} { x: 1 } }' fails to parse | "Does not reproduce on main (build/avra at c88c57d)"; "Fixed as a side effect of 095dc5e (.3.5)" | - |
| .57.46 | closed | defect: Cell method on a generated fn's answer ('nameless receiver') | "Fixed on main at 60242a0 (fix/generated-siblings)" | fix/generated-siblings |
| .57.47 | closed | native: generated fn value answering Rows<${t}> into a generic seat fails LLVM verify | main 60242a0 (same root cause as .46/.71/.80) | fix/generated-siblings; repro lane/relation after 4ea2846 |
| .57.48 | closed | witness: an added file is invisible to a reused witness (negative dependency) | closed 2026-09-28T09:19, no outcome text, no sha named | redteam/m3-witness-attacks a644ba4 |
| .57.49 | closed | witness: Parsed edge hashes structure, so a moved span reuses a stale report | closed 2026-09-28T09:19, no outcome text (.57 says Parsed edge is "fp_list([structural, text]) since 0304ce6") | - |
| .57.50 | closed | witness: a stale Manifest edge traps instead of answering unresolved | closed 2026-09-28T09:19, no outcome text, no sha named | - |
| .57.51 | closed | witness: a missing file answers the empty program's hash | closed 2026-09-28T09:19, no outcome text, no sha named | - |
| .57.52 | closed | witness: Methods edges recorded for the first analysed file only | closed 2026-09-28T10:05, no outcome text, no sha named | - |
| .57.53 | closed | witness: stable names depend on admission order (sibling_index) | closed 2026-09-28T10:05, no outcome text, no sha named | - |
| .57.54 | closed | witness: record-shape stamp never compared; pack path shared across compilers | closed 2026-09-28T10:05, no outcome text, no sha named | - |
| .57.55 | closed | M3 wiring: avra check reads and writes witnesses | "PR #104 merged to main as 85f1046": flattened witness recording DELETED (−2299/+487 lines); durable witness = hold path's KeyParts. Open decision left for lead: rebuild `cache why` lazily or delete with pack.av | lane/witness-wire (e4d4420, NOT landed) |
| .57.56 | closed | Kernel: stamp hit still ~125 instr over an unrecorded read | "landed on main 2e99559 (perf/stamp56-rows)" | perf/stamp56-rows |
| .57.57 | closed | witness: per-consumer cutoff for the Parsed edge (comment edits in a sibling) | closed 2026-09-28T12:44, no outcome text, no sha named | - |
| .57.58 | closed | witness: Namespace edge per name read, not the whole module | closed 2026-09-28T11:12, no outcome text, no sha named (NameReads recording later DELETED by .55 / PR #104) | - |

Ticket count: 64 (matches the 64 `=====` headers in the file).


### Appendix A / slice 57_p3

| id | status | title (short) | outcome | worktree/branch |
|---|---|---|---|---|
| .57.59 | closed | explain: reverse edges — what a change to this declaration invalidates | "LANDED on main 2026-09-28 as a729afe (code f2bb038)"; `avra explain dependents <name>`; e2e on a checked package left OPEN pending .55 | lane/docs |
| .57.60 | closed | held path: the same 110 of 717 files are never held | "Landed with fix/held-110 (da1fa34)"; 607->643/717 held; "Remaining 74 are named, not silent" | fix/held-110; fix/held-settle 0282308 (base); logs avra-heldsettle-logs/ |
| .57.61 | closed | flaky: std-http close-unread-request reset case fails land.sh | no close text, no sha named | lane/lint (where it fired) |
| .57.62 | closed | test: concurrent avra test runs share packages/<pkg>/build/suite | no close text, no sha named | - |
| .57.63 | closed | test harness: a program test that expects a trap with a voice (.refuses) | "Landed on main (81a26a7)" | lane/refuses (named in .65, head 4e01072) |
| .57.64 | closed | receiver law warns 'writes through it' on a chained concat | no close text, no sha named | - |
| .57.65 | closed | cli: avra run on one program test in a package with others | "Done on lane/program-door (caeac4c…)"; `Workspace.is_program`; main sha not named | lane/program-door (on lane/refuses 4e01072) |
| .57.66 | closed | cache: a stale .avra-cache answered after a source edit | reproduced; no close text/sha in this ticket (.91 names "c855084 (.66 hole 3)") | lane/parsed-cutoff; avra-parsed-cutoff/.rt/stale/ |
| .57.67 | closed | warm cache drops fn-type seat marks (127 refusals warm) | no close text, no sha named (.68 gives cause: mark_word vs read_type_wire F case) | ../avra-runs; fix/holed-seat 05376e5 |
| .57.68 | closed | keeper: every record encoder round-trips through its decoder (make codecs) | no close text, no sha named | - |
| .57.69 | closed | held: --verify-held diffs every held declaration against a fresh reading | "landed 38ea808" | lane/verify-held (per .84) |
| .57.70 | closed | MAIN RED: a held package's generic serves a new cross-package caller unmonomorphized | no close text, no sha (.71 describes "the P0 fix") | - |
| .57.71 | closed | @relation-generated call to a generic pinned only by its answer carries no substitution | "Fixed on main at 60242a0 (fix/generated-siblings)" | fix/generated-siblings; ../avra-mt (repro) |
| .57.72 | closed | Self-built compiler runs check 2.2% slower than the seed-built one | explained (seed predates thaw commits); ruling "make bootstrap ends at gen-2 … plus a one-off seed refresh"; no sha | - |
| .57.73 | closed | R3: a seat kept only on a cold branch should stay borrowed | "Landed in #70 (consume74)"; census not re-taken | consume74 |
| .57.74 | closed | Consuming inference: consume a seat only when every path keeps it | no close text; same change as .73 (#70) | - |
| .57.75 | closed | memory: a Cell's loaded value freed by a later set of the same Cell (native UAF) | no close text, no sha named | avra-db-gantt/evidence/kernel-held-clear-2026-09-28/ |
| .57.76 | closed | types: a projection type names the fields it lacks, and a read says why | part 1 "main 2363ca2 merge of lane/lacks" (77c35b5); part 2 "at bc2d64a (lane/lacks-2…)" | lane/lacks; lane/lacks-2 (2c528bb) |
| .57.77 | closed | types: a missing static fn on a record says 'not an enum' | "landed c03ea6f" | - |
| .57.78 | closed | A missing static member on a record speaks 'is a record, not an enum' | closed as dup of .57.77 | - |
| .57.79 | closed | A generated type names the fields it deliberately lacks | closed as dup of .57.76 | - |
| .57.80 | closed | Spliced bool literals in a @relation-generated list push as i1 | "Fixed on main at 60242a0 (fix/generated-siblings)" | lane/buckets (../avra-runs) |
| .57.81 | closed | Refuse a query reading rows it owns (unless via prior()) in the armed record hook | "Landed on main at 1c20088" | - |
| .57.82 | closed | A scalar Cell field read costs ~19 instructions, not one load | "landed on main bc2d64a (perf/cell82)" | perf/cell82 |
| .57.83 | closed | errors: an inferred-error fn cannot fail with a parameter's error type | "Already fixed, no new code needed" (stale binary; subsumed by S3b `Decls.seats`) | - |
| .57.84 | closed | held Task<T>/Tasks types decoded to Type.Error | "landed 38ea808" (06dcce9 on lane/verify-held) | lane/verify-held |
| .57.85 | closed | held path: a red control for the callee-edit witness | "landed 766e094" | - |
| .57.86 | closed | verify-held: cover an impl's target | "landed f9e82ac" | - |
| .57.87 | closed | WRAP/@query: a program outside the declaring package re-expands the moved body | "landed f9e82ac" | - |
| .57.88 | closed | linux: std-avrac suite traps after lists/measures on a Sprite | "Landed on main: 59a132e" | Sprite avra-bench |
| .57.89 | closed | keeper: identity structs hold only Cell fields | closed as dup of .57.90 | - |
| .57.90 | closed | keeper: an identity struct's every field is a Cell | "landed 4ee69c3"; half (b) -> .96, name-matching -> .95 | fix/receiver-typename (related fix) |
| .57.91 | closed | warm edit: consumed marks unstable across the hold boundary (held 659 -> 408) | 360f790, 84f9f82, ceeea19 landed; "599bb10, landing"; held 260 -> 710/759; ~49 remaining "classified legitimate" | - |
| .57.92 | closed | land.sh gates: speed, warm reuse, Linux | "landed b460e1b" (speed off, Linux on, warm reuse off until .91) | - |
| .57.93 | closed | cell.get()[i] retains the whole list to read one element | target already met (853b7a7 + 9cdd5ba); UAF fix "landed on main bc2d64a" (perf/view93 7cbba5c) | perf/view93; lane/views2 |
| .57.94 | closed | idioms: shaped patterns for the 15 bare-hole rules | closed not-possible in today's matcher; reasons at f5425e5; engine fix -> .99 | - |
| .57.95 | closed | annotations resolve by declaration, not by name | "landed 45f2bc7" (@dense stays name-based) | - |
| .57.96 | closed | path_copy_law: never open an @identity place | "landed on main 2e99559 (perf/ident96)" | perf/ident96 |
| .57.97 | closed | Resolve grammar terminal names to kind ids at assembly | "LANDED 3f7b96c (code 3884f61)" | perf/parse |
| .57.98 | closed | AssignRoot.decoded releases a borrowed register | "Landed on main: b0fd739" | lane/file-indexes 9f9fbed (origin of AssignRoot) |
| .57.99 | closed | rule index: key a pattern by its root kind even when root's name is a hole | "LANDED 33a0f19 (code 5e5db1b)" | avra-phase-c |
| .57.100 | closed | Files declaring an export rule never hold (const settlement Stored.Unit never lands) | "Landed main f8ebab8" | lane/held-collect (named in .109) |
| .57.101 | in_progress | Speed P0: build 97s back under 40s, warm recheck in seconds | REMAINS: "COLD build 69s (target <40s) still open: lower/emit remain"; slice-4 PR #182 (dacb95f) queued; slice-2 abandoned | ../avra-perf-hold-keys (perf/hold-keys 9a8ac3b); ../avra-perf101-warm (perf101-warm); perf101-loadadmit (38f9b94); ../avra-perf101-slice2 (perf101-slice4, WIP 8ac19eb) |
| .57.101.1 | closed | keep phase: builds stop running idiom rules (15.5s -> 1s) | "landed 9aa321c (ORM)" | - |
| .57.101.2 | closed | parse: static terminal table + doc attach by binary search (23.8 -> 13.6s) | "landed 3efa6fa (ORM)" | - |
| .57.101.3 | closed | emit: inline only paying runtime leaves; lean inlined copies | "landed 79e2ec2 + 873d6539 (PERF)" | - |
| .57.101.4 | closed | idiom rules: cheap test first, per-file indexes, all_cases (check -10%) | "landed 6a24fb4 d4506c8 9f9fbed" | - |
| .57.101.5 | closed | warm recheck (.91): held 229 -> 712 after a body edit | "landed 360f790 84f9f82 ceeea19; failures() fix 599bb10 queued" | - |
| .57.101.6 | closed | land.sh: solo, parallel, skip rules, gates, scratch cleanup, early Linux | "landed 7920690 5bbba36 b460e1b a3ab3c0 0a17b85 02391be af1be1f 9d83863" | - |
| .57.101.7 | closed | warm Sprites: persistent tree + compiler cache | "landed f9fc6b9 019da53" | - |
| .57.101.8 | closed | lower: borrow_outlives scan per managed load (13.5s) — lowerfast | "Landed on main: c23ab5f" | - |
| .57.101.9 | closed | landings keep the warm cache | "Landed on main: 2aaa8dc" | lane/warm-cache |
| .57.101.10 | closed | M5 chain speed fix (.93): a call in an unreached branch is no barrier | "Landed on main: perf/sibling-arm-barrier" (no sha) | perf/sibling-arm-barrier |
| .57.101.11 | open | perf(warm): key a kept view on the kernel witness deps | "PARKED -- no PR"; premise false on main (no M3 witness layer); "[dep blocks] avra-8sb5.57.101.12" | - |
| .57.101.12 | open | perf(warm): a durable dep witness with stable labels (the M3 layer) | not started; needs deps written as (stable name, hash) durable rows + label->Key codec; prereq .155 "landed as #173" | - |
| .57.102 | closed | A passing cli suite prints a fixture's literal 'STOPPED — … trapped' line | "LANDED on main: a755ed6 (source commit 94f738f)" | - |
| .57.103 | closed | fn-typed PARAMETER named like a top-level fn calls the top-level fn | "Landed on main: 7226fcf" | - |
| .57.104 | closed | cross-package export surface computed pre-expansion | "Fixed on fix/generated-surface 502a455"; "Landed on main: fix/generated-surface (12:50)" (no main sha) | fix/generated-surface |
| .57.105 | closed | Records kept by interface: name row -> body keyed by (module, iface) | "LANDED 3ccf761" | - |
| .57.106 | closed | cutoff: six query families fingerprint with the revision counter | "Landed main 3312554" (built on lane/cutoff e5c13ba) | lane/cutoff; lane/m5b-columns 4845183 (finder) |
| .57.107 | closed | One durable declaration identity (decl wire + Reference line folded) | "LANDED 70667b9 (code in lane/identity-fold)" | lane/identity-fold |
| .57.108 | closed | Memory pass: a set-once @identity Cell's view needs no hold across a call | "landed on main bc2d64a (perf/once108)" | perf/once108; lane/written-read (finder) |
| .57.109 | closed | verify-held Reference rows: multi-file impl refs attribute to wrong file's decl | "LANDED 14764b0"; 35 -> 0 mismatches | lane/held-collect (finder) |
| .57.110 | closed | Rule engine: multi-arm rules matched only arm 1; site licenses | "Landed main 4249cfd" | lane/rule-arms (../avra-rule-arms), e200ace |
| .57.111 | closed | Lint: a per-file id matched across a workspace-wide relation | "Landed main 6dba4a5 (lane/lints-111-121)" | lane/lints-111-121; lane/db-errors cba8784 (origin) |
| .57.112 | closed | tools/reclaim.sh: retire merged idle worktrees when disk runs low | no close text, no sha named | - |
| .57.113 | closed | identity_plain license table / quote/lower.av match a TYPE BY NAME | "Step 2 on fix/licenses-step2 b822f6a … queued 01:30"; main sha not named | fix/licenses-by-decl; fix/licenses-step2 |
| .57.114 | closed | tools/watch.sh's tree_rss kills healthy builds under concurrent load | "LANDED on main: 88f3753 (source commit 6f4f02a)" | - |
| .57.115 | closed | A setting written twice cascades three refusals | "Landed on main at e6290f0 (lane/setting-twice, source da7e9ca)" | lane/setting-twice |
| .57.116 | closed | Test files in one package share one module namespace | "LANDED on main: 88f3753 (source commit 3822f8b)"; ruled BY DESIGN, help improved | - |
| .57.117 | closed | A [lib] name that disagrees with its package's own name is accepted silently | "Landed on main at bc2d64a (lane/lib-name-mismatch, source 44daa0f)"; original warm-store symptom -> .57.123 | lane/lib-name-mismatch; lane/ui a0a92df (repro) |
| .57.118 | closed | A bare const / typed-record arg to a DECLARING annotation is dropped silently | "LANDED main bc2d64a (lane/declares-arg 2242b17)" | lane/declares-arg |
| .57.119 | closed | A cross-package importer keys on the WHOLE exported surface | "The fixes landed as #54 (8a85aec…)"; pins "landed as #93"; "#90 was the duplicate and is closed" | lane/db-importer-names (dc0507f); lane/db-impl-reach (d29f413, 87a5662) |
| .57.120 | closed | make census / tools/census.sh print nothing; runtime rebuild drops -DAVRA_CENSUS | "Landed (perf/census120 5d943d3)" | perf/census120 |

Row count: 74 (62 for .59–.120 + 12 for .101.1–.101.12).


### Appendix A / slice 57_p4

| id | status | title (short) | outcome | worktree/branch |
|---|---|---|---|---|
| .121 | closed | one_body_arms suggests merging arms whose binders have different payload types | "Landed main 6dba4a5 (lane/lints-111-121)": joins arms only when same names + same typed payloads (`ArmInfo.binds`); five licenses removed | lane/lints-111-121 |
| .122 | closed | The ./avra shim's watchdog kills a healthy build at 4 GB (status 137) | closed 2026-10-01T21:48, NO close_reason, no sha named | (measured on main 5c08d15 + lane/m5-decl 64c0e09) |
| .123 | closed | warm .avra-cache store silently drops linked objects (@std/http $default symbols) | "Landed on main at e6290f0 (lane/warm-store-drop, source 8b03c6a)" | lane/warm-store-drop; repro in ../avra-lib-name-mismatch |
| .124 | closed | Warm check re-settles the entry's const: reuse a read file's kept verdict | close_reason "#58 merged" | perf/reach-chain; failed attempt perf/verdict124 c0ba862 |
| .125 | closed | Importer's narrowed key misses an impl in an unnamed file: stale dyn vtable | fix landed as PR #54 (8a85aec); pins as PR #93; PR #90 duplicate closed | lane/db-impl-reach (0f3706e on dc0507f); branch importer-reach |
| .126 | closed | warm check: Checked.findings omits held files' rule findings | "Landed PR #61 (2f7f94c)" | fix/warm-recheck 97a9dc2 (on perf/reach-chain 1c7ba69); PR branch held-findings 1818e45 |
| .127 | closed | Open question: unrelated trait impl added in unnamed file leaves importer held | closed as measurement artifact: "stale per-Sprite .avra-cache, not the cache logic"; no pin landed | script avra-http-gantt/scratch/db125/rt125.sh |
| .128 | closed | Division by a nonzero constant calls avra_int_div with a zero guard | "Landed PR #66 (6d8c484)" | - |
| .129 | closed | Two Cells seeded from one empty-list let share a buffer; pushes quadratic | "Landed PR #60 (ff82d5a): already fixed by d7097e2" (#45); regression test only | - |
| .130 | closed | Cell.set_at retains/releases the held list around every write | "Landed PR #81 (ba3a17c)" | branch cell-set-at, base e2793f2 |
| .131 | closed | A reused const value can be stale when it reads a const in another file | closed "Not on main" (only on unlanded perf/verdict124); constraint recorded on .124 | perf/verdict124 c0ba862 |
| .132 | closed | store: the compilers roll races; concurrent sweep of another compiler's store | "Fixed via PR #91"; runtime rows first as PRs #77/#85 + seed refresh #88 | - |
| .133 | closed | decls bracket: fence Decls' pinned Decl relation handles with @bracket | "Landed on GitHub main as PR #38 (9cee431)" | (after lane/m5-decl2) |
| .134 | closed | cli check_witness test fails over a warm .avra-cache (118/119) | closed 2026-09-30T22:03, NO close_reason, no sha named | (seen on main bc2d64a) |
| .135 | closed | watch.sh: set -m fails under dash without tty; Linux tree-kill disabled | "Landed as PR #156" (setsid preferred) | - |
| .136 | closed | Held path: a held row read costs what a read one does (warm edit 20.9 s -> 2.3 s) | close_reason "#48 merged" | perf/held-path e203c0d (main 96fa525) |
| .137 | closed | Trim armed-hooks speed cost on error_sites_db/Raised (~1%) | "Accepted cost (lead's call)" — no code change; cause landed at 1c20088 | lane/arm-error-sites, lane/raised-owned-by-fixpoint |
| .138 | closed | land.sh: branch worktree without build/avra fails fmt-lossless-fast | "land.sh retired by #57" (superseded) | - |
| .139 | closed | A kept package object's key misses its package C (stale std-io object) | "Fixed … PR #73": program_key folds reached_objects' digests | found in avra-land-batch-wt |
| .140 | closed | ir_of lowers after the workspace is disarmed: no consumed seat in any IR test | "Landed as PR #78", "Fix commit ccab7da" | - |
| .141 | closed | Sound kept settlement: a parsed const reuses its value across an edit (P0) | closed 2026-10-01T16:54, NO close_reason, no sha named (description still says DEFERRED) | (perf/kept-settle-141 named in .158) |
| .142 | closed | witness_refusal / witness_stale_manifest tests fail intermittently in trains | "#71 merged (cause: #45, not flaky)" | - |
| .143 | closed | sp: a failed build runs the command on a stale compiler (compiler=unverified) | "fixed by #69 (merged)" | - |
| .144 | closed | fmt --check over a small package queued on the machine build lock | "Queued as PR #84" | - |
| .145 | closed | avra test on a single program-test file passes silently, examining nothing | PR #120 (commit c5da450), "queued" | branch test-single |
| .146 | closed | A deleted file has no un-admit path in Decls | closed 2026-10-02T09:23, NO close_reason, no sha named | asg=declgrain |
| .147 | closed | CLAUDE.md names the deleted impls_by_name | closed 2026-10-01T13:04, NO close_reason | - |
| .148 | closed | M5 proper: query families as @query declarations | landed as #151, #158, #162, #166, #171, #175, #185, #192 (Family is a collect over 30 markers) | ../avra-collect148 (collect148 @ 2834e47, collect148-w2a @ 6b263de, collect161-witness @ e58ed4e); ../avra-db159-collect |
| .149 | closed | avra cache why/changed/dependents/summary: rebuild over the lazy walk; delete the pack | "PR #107 (cc0040d, loud refusal) + PR #109 (83d4877)" | - |
| .150 | closed | avra cache: one lazy in-process walk, every mode a projection; store/pack.av deleted | same as .149: PR #107 (cc0040d), PR #109 (merged 12:45Z) | - |
| .151 | closed | Cache soundness: relation verifiers answer a hash where the kernel compares a revision | "Fixed via PR #111" (`revision_of_hash`) | - |
| .152 | closed | Kernel.changed_after compares a relation's verify hash to a revision via > | closed as duplicate of .151 | - |
| .153 | closed | avra cache modes save what they read, so a second run reports nothing moved | "Landed PR #113 (11fd2d4)" (`Keeping` .Disk/.Aside) | branch cache-readonly 00811b8 |
| .154 | closed | Typed reads an imported file's whole Parsed, not the decl's Sig/Syntax row | "Landed PR #114 (46d8154)" | branch typed-decl-grain dd3e843 on main 9151d48; red worktree typed-decl-grain-red |
| .155 | closed | Decl row reads are recorded per file, so adding a decl re-types every importer | PR #173 "queued at position 5"; squashed commit a943d03 (from 16085e5) | (session db47) |
| .156 | closed | Fingerprint tags 183/184 claimed twice in voices.av | "Landed PR #115 (682e12b)"; gate gap PR #116 (7448088) | - |
| .157 | closed | Family's ordinal has no keeper against a moved registration | no close_reason; text says moved variant "refused by tools/families.py (#127)" (from .148) | - |
| .158 | closed | cli tests bound compiler runs by wall time, and flake under load | closed 2026-10-01T21:48, NO close_reason, no sha named | (seen on perf/kept-settle-141) |
| .159 | closed | collect: `by it.mark.args[i]` with typed comparison, and dense | "Merged as PR #140 (2026-10-01T21:23:29Z)" | db159-collect @ 53a73e8 (../avra-db159-collect) |
| .160 | closed | rule: a read-modify-write through Cell.get is a whole copy | closed 2026-10-02T00:27, NO close_reason, no sha named | asg=declgrain |
| .161 | closed | collect enum: `by it.mark.args[i]` order ignored for members in a foreign module | "RETRACTED — not-a-bug"; witness test landed (PR #157 per .148) | collect148 @ 264d55d / fab8da0; collect161-witness @ e58ed4e |
| .162 | closed | chore(seed): refresh the seed so compiler source can use collect by it.mark.args[i] + dense | "Landed as PR #159" | - |
| .163 | OPEN | Partly-held rebuild of the compiler peaks 1.6x a cold one (3.4 GB vs 2.2 GB) | open; "NOT INVESTIGATED: which of load / admit / the held path holds the memory" | measured on ui-dev |
| .164 | OPEN | avra build keeps a stale binary after an embedded file changes | ticket open; comment says "Fixed on wants-modules, the commit after 8ed3b35" — not landed per text; acceptance (cache attack) not stated done | wants-modules; found on sources-design |
| .165 | OPEN | three keepers red on main, no CI job runs them: cache-attacks, fmt-lossless, codecs | open; acceptance: "each green on main, and each either in checks.yml or deleted" | reported by ui-own-state (base 91a317d) |


### Appendix A / slice other_p1

| id | status | title (≤ 80 chars) | relevance | outcome | worktree/branch |
|---|---|---|---|---|---|
| avra-2y5c.11 | closed 2026-09-23 | Last 24 F2047 growth-wall sites need core to have a sharing primitive | CORE | "LANDED on LOCAL main c9c0ac1 (2026-09-23)": TypeRegistry, NodeStore+Arenas, Decls, Workspace hold tables in Cells; earlier Keys+query.Db 0f3f150, Workspace/Hold/Records 9ee91d7 | std/f2047-residue; std/core-cells (140bcbb, d91fb09); lane STD-CORECELLS |
| avra-2y5c.20 | open | EXPLORE: place WRAPPER type — Cell/Replicated/Remote/Relation as `state`s sharing | ADJACENT | Exploration only; owes a decision on (b)+(c): verbs per wrapper, failure channel. Design docs/2026_10_04_SHARING_MODEL.md §4.5 | none (probed "gen-2, base 3137b8f") |
| avra-8hmj | closed 2026-09-22 | parallel/race collect on stop with NO grace — grandchild loses output | IRRELEVANT | std-process `graced`; main 9ba6203 | ../avra-std-proc, std/proc-drain |
| avra-8sb5.1.3 | closed 2026-09-07 | S2c step 5 — the SCOPE test: tools/libscope.sh | IRRELEVANT | 1bb5684, lane/http 934f395 | lane/http |
| avra-8sb5.1.13 | closed 2026-09-08 | Evaluator: memoize symbol_of per callee | IRRELEVANT (evaluator dlsym memo, not the kernel) | d8f996a; lane/http fcfa831 | lane/http (substrate-2) |
| avra-8sb5.1.14 | closed 2026-09-08 | corpus/bytes-header is the last native-only corpus ("held by" evaluator defect) | IRRELEVANT | 0ef691e on lane/substrate | lane/substrate |
| avra-8sb5.1.19 | closed 2026-09-14 | gate's SUITES list is hand-kept | IRRELEVANT | PR #9, main f6b8238 | toolchain/suites |
| avra-8sb5.1.21 | closed 2026-09-14 | census of hand-kept lists in the arc's tools | IRRELEVANT | PR #10, main 7d698f5 | toolchain/census |
| avra-8sb5.1.24.4 | open | Cell.get hands out the held box: later push/set_at/put writes through it | ADJACENT (Cell is the substrate the Db/Workspace tables sit in) | Waits on evaluator refcounts (.1.24.3) or `get` copying out; "Owner: compiler lane (db47)" | lane/http-hygiene (probe base d7097e2) |
| avra-8sb5.1.24.9 | open | encode the kept seat at lowering, so the evaluator's second pass is unnecessary | IRRELEVANT ("kept" = callee-kept seat) | open | eval-rc branch f234dc7 |
| avra-8sb5.1.26.2 | closed 2026-09-30 | Streaming request body | IRRELEVANT | 6a16fc8 | lane/http-streaming |
| avra-8sb5.1.26.6 | closed 2026-09-30 | Slow-peer and producer-failure laws | IRRELEVANT | 92c5e9a | lane/http-streaming |
| avra-8sb5.1.26.7 | closed 2026-09-30 | Evaluator: Bytes written through avra_fd_write grow memory | IRRELEVANT | dbf1c74 | lane/http-hygiene |
| avra-8sb5.1.28.1 | closed 2026-09-30 | @std/url — Url type, query builder | IRRELEVANT | 76dcb5b | lane/http-client |
| avra-8sb5.1.28.2 | closed 2026-09-30 | DNS — off the event loop, cached with TTL | IRRELEVANT (DNS cache) | bbaaa85; filed .1.28.8 | lane/http-client |
| avra-8sb5.1.28.8 | open | Cached package test binary ignores the package's C object | CORE | OPEN: test-binary cache key covers Avra sources, not `[link] objects`; workaround clear `.avra-cache` | lane/http-client (base 7b7cab9) |
| avra-8sb5.1.29.10 | open | std-db row_ctor and rebuild_derive adopt @std/derive record_of | IRRELEVANT (std-db = ORM) | open | — |
| avra-8sb5.1.29.13 | open | Evaluator: @std/text repeat blows memory | IRRELEVANT | open | lane/http-app df63966 |
| avra-8sb5.1.29.14 | in_progress | Content coding for streamed responses | IRRELEVANT | in progress | http-docs |
| avra-8sb5.1.30.3 | in_progress | Load + soak under fibers | IRRELEVANT | 4142822; 1h soak not completed | conformance |
| avra-8sb5.1.33.3 | open | Route fns: @get/@post … query, extractors | IRRELEVANT (http query) | open, blocked by .1.33.2, .63.3 | — |
| avra-8sb5.1.35 | open | avra test serves a stale suite after a package's C source changes | CORE (same defect as .1.28.8, second reporter) | OPEN: suite cache key does not cover package C sources or built library | h2fix (repro c50791a..h2fix) |
| avra-8sb5.4.1 | closed 2026-09-08 | Static histogram of the four Ins.Retain emitters | IRRELEVANT | 4d494ad | lane C |
| avra-8sb5.5.3 | closed 2026-09-16 | Main's worktree carries 8 uncommitted files every integrate stashes | IRRELEVANT | ruled: detached clean worktree; 9ba70c6 | main |
| avra-8sb5.5.4 | closed 2026-09-15 | Three subset entries held until Bytes lands | IRRELEVANT | PR #18, c66036c | lane/d-subset-bytes |
| avra-8sb5.6.1 | closed 2026-09-08 | Sqlite lead: run sqlite suite on lane/http, migrate seats to Bytes | IRRELEVANT | verified at lane/http 4382c4a | lane/http |
| avra-8sb5.8.6 | closed 2026-09-08 | OWNER: every session exports TASKS_DB=… | IRRELEVANT (tasks db) | done by owner | — |
| avra-8sb5.9.2 | deferred | TRIGGER: `parsed`'s early cutoff covers structural fingerprints only | CORE | DEFERRED; fires on first non-one-shot compile; fix = cutoff PER CONSUMER; last audited 2026-09-15 (main eec73f8) "OPEN — no non-one-shot host exists" | asg LANE C / LANGUAGE-CORE |
| avra-8sb5.9.5 | closed 2026-09-15 | DEADLINE: @std/sqlite close(mut db) idempotence | IRRELEVANT (sqlite; notes "Cell<T> IS landed (features/cells, query/db.av:45)") | PR #21, main 2001b36 | data/handle-cells |
| avra-8sb5.9.8 | deferred | TRIGGER: CLAUDE.md 'subset today' becomes a POINTER ("hand-kept cache") | IRRELEVANT | deferred | — |
| avra-8sb5.9.10 | closed 2026-09-07 | HTTP lead: sweep ROADMAP triggers into this db | IRRELEVANT | swept | — |
| avra-8sb5.9.12 | deferred | OBLIGATION (lane C): grammar type holding an impl | IRRELEVANT | deferred | — |
| avra-8sb5.9.13 | deferred | TRIGGER: unboxed (ptr,len) view | IRRELEVANT | deferred | — |
| avra-8sb5.9.14 | deferred | TRIGGER: passes become a uniform trait only when L6 query engine memoizes them | CORE | DEFERRED, "FIRED-UNPAID": L6 landed 2026-09-02; collapse eligible, not done; re-parented to avra-2y5c | owner unconfirmed |
| avra-8sb5.9.24 | deferred | TRIGGER: struct field-dup law moves home when declaration sigs become feature-owned queries | ADJACENT | deferred; audit says stated gate is the wrong one (seam `type_stmt` already exists) | owner unconfirmed |
| avra-8sb5.10.7 | closed 2026-09-24 | Trailing lambdas for bracket verbs (`db.tx { … }`) | IRRELEVANT | landed as sugar 1 | — |
| avra-8sb5.10.26 | closed 2026-09-24 | Derived structural identity — `fingerprint_expr` is mechanical | ADJACENT | "LANDED: packages/std-avrac/src/core/fingerprint.av implements `@derive(Fingerprint)`, used throughout core/ir.av" | — |
| avra-8sb5.10.31 | open | Fn-typed arguments carry type evidence (the witness-parameter problem) | IRRELEVANT | open | — |
| avra-8sb5.10.70 | open | A multi-line cell, so a diagnostic witness program lives on its DiagCode row | IRRELEVANT (diagnostic witness, language/witnesses.av) | open | — |
| avra-8sb5.10.85 | open | Weak captures — break owner/closure reference cycles | ADJACENT | open; workspace's "query verifiers, its declaration hooks, and its analyses all capture the workspace itself"; `disarmed` is the workaround | — |
| avra-8sb5.10.110 | open | Enumerate an enum's variants (Size.all()) | IRRELEVANT (ui; but see 11.120 #9) | open | — |
| avra-8sb5.10.116 | open | A dyn slot that routes by trait | IRRELEVANT | open | — |
| avra-8sb5.10.136 | open | A relation's unrecorded bucket door named by its field, not its index number | CORE | OPEN ask: @relation generates `Decl.filed_word(rs, v)` / `Decl.index_of(word)`; plus a member-ids door | site features/decls.av, decls_mint.av |
| avra-8sb5.11.9 | open | Early-return null guard should narrow the binding | IRRELEVANT | open | — |
| avra-8sb5.11.16 | open | DECLARE a C prototype beside an extern (keeper) | IRRELEVANT | open | — |
| avra-8sb5.11.30 | open | A REGISTRY ENUM SAYS SO AT ITS DECLARATION | IRRELEVANT | open | — |
| avra-8sb5.11.50 | open | a keeper that reads packages/ has no synthetic root | IRRELEVANT | open | — |
| avra-8sb5.11.58 | open | A CROSS-FAMILY CYCLE VERDICT FROM THE KERNEL | CORE | OPEN ask; interim = `Memo.open` in query/ + hand check at `const_type_at` + F2078 | lane/comptime 2d4663e |
| avra-8sb5.11.91 | open | generic method declared but uncalled traps the compiler (`fn kept<T>`) | IRRELEVANT ("kept" is a fn name) | open; fixed on lane/comptime, live on main 09890e8 | — |
| avra-8sb5.11.120 | open | SURVEY: what the cache layer's beauty audit wanted from the language (11 asks) | CORE | OPEN survey, 11 language asks with sites in the cache layer; one "verified defect, fix pending" (#10) | cache/cas campaign, 2026-09-21 |

Note: avra-8sb5.11.120's body may be cut at the input's end (line 558 ends at ask 11, no comments follow).


### Appendix A / slice other_p2

| id | status | title | relevance | outcome | worktree/branch |
|---|---|---|---|---|---|
| avra-8sb5.11.131 | open | `avra probe <file>` — a base-stamped probe record | IRRELEVANT (probe log tooling; "stamp" = base commit) | survey ask, unbuilt | — |
| avra-8sb5.11.134 | open | `avra query <file>:<line> --json` — type-at-point from the compiler's facts tables | ADJACENT | survey ask: "expose the facts tables the compiler already holds"; unbuilt | — |
| avra-8sb5.11.178 | open | Program tests that assert a memory ceiling, in both engines | IRRELEVANT | survey ask | — |
| avra-8sb5.11.183 | open | The evaluator's memory grows with bytes written through a socket | IRRELEVANT | survey ask | avra-http-gantt scratch |
| avra-8sb5.11.187 | open | The evaluator should count references the way the memory pass places them | IRRELEVANT | survey ask | — |
| avra-8sb5.11.236 | open | the suite cache should key on a package's C | CORE | open: `avra test` answered from `.avra-cache` after package C changed (filed avra-8sb5.1.35) | — |
| avra-8sb5.11.249 | open | Survey (cache-target): a memoized cell that names what it is derived from | CORE | open language ask; names Keys' 12 hand-cleared memo cells; cites avra-8sb5.67 | cache-target @0bdcb6d |
| avra-8sb5.11.250 | open | Survey (cache-target): a fresh instance of a record, per field carried or fresh | CORE | open language ask; `Workspace.anew` dropped `build_mode` = avra-8sb5.67 | cache-target @0bdcb6d |
| avra-8sb5.11.251 | open | Survey (cache-target): a test beside a module cannot call its private fn | ADJACENT | open; `shipped()` in build.av proven only via tools/wasm-cache-attacks.sh | cache-target @0bdcb6d |
| avra-8sb5.11.291 | open | @std/io has no modification time: stamp() answers null for two seconds | ADJACENT (stamp() is the file-stamp door; UI watcher is the asker) | open ask: mtime/size or a watch primitive | std-ui_dev |
| avra-8sb5.11.300 | open | make avra peaks past 4 GB and is killed when a tree-root .avra-cache stands | CORE | open bug; workaround "park `.avra-cache` before every compiler build" | avra-ui-own-state |
| avra-8sb5.23 | closed | CACHE CAMPAIGN DONE on cache/cas — warm build 0.4 s, check 0.3 s, cold 13 s | CORE | "MERGED TO MAIN 2026-09-21: main fast-forwarded to 86d7009 (cache/cas, 236 commits)"; residuals in docs/2026_09_21_COMPILER.md §7a/7b | ../avra-cache-cas, cache/cas |
| avra-8sb5.25 | open | FORMATTER — one rule engine: layout, idiom, lint | ADJACENT (rule findings as "A QUERY keyed by text + interfaces + ruleset print"; "findings ride the Said rows") | open epic; phase 3 = store-keyed findings | lane/formatter; phase/d2 @093ae19 unlanded |
| avra-8sb5.25.3 | closed | Structural matcher over the store: @derive(Shape), At, shape_at, matched | ADJACENT (NodeStore matcher, shallow fingerprints) | lane/formatter 7d7b0ec, c23a1f3, 528e348, 924fceb | ../avra-lane-fmt, lane/formatter |
| avra-8sb5.25.8 | open | Analysed Code: shared_here / in_loop — memory-pass facts keyed to nodes | IRRELEVANT | open; blocked by .25.7 | — |
| avra-8sb5.25.17 | open | memory_host never sets Host.std_root | IRRELEVANT | open bug | — |
| avra-8sb5.25.20 | open | Build cache: a held object linked against stale asks — undefined symbols | CORE | open; seen again 2026-09-25 with `packages/std-avrac/.avra-cache`; attack unwritten | lane/formatter |
| avra-8sb5.25.22 | closed | quote-pattern rewrite: a Held fill's text() covers the whole postfix chain | IRRELEVANT ("Held" = a quote hole fill, not a cache hold) | fixed e415a6c lane/formatter | avra-lane-fmt |
| avra-8sb5.25.50 | closed | Quote-pattern same-binder check trusts a 30-bit fingerprint — exact fallback | ADJACENT (same 30-bit fp_mix as .46) | closed 2026-09-25 (no text) | — |
| avra-8sb5.25.52 | closed | Stale .avra-cache traps check: memo family 3 reused missing key 6 | CORE | closed 2026-09-25T11:50 (no text: fix/sha not recorded) | found on lane/formatter a8c3077 |
| avra-8sb5.25.54 | closed | Native rule finding at lists_test.av:19 flickers with cache state | CORE | closed 2026-09-25T11:50 (no text: fix/sha not recorded) | — |
| avra-8sb5.25.69 | closed | fmt: block words as a stored relation; warm tree check in seconds | CORE | closed 2026-09-26T20:23 (no text: result not recorded) | — |
| avra-8sb5.27 | open | Cache timing receipts unreproducible two ways (identical re-edit = HIT; 288/289) | CORE | open; part 2 partly retracted + confirmed at ce93b0a (docs/hold-command, "awaiting merge"); harness rule still owed | land/c2 vs 9ba6203; docs/hold-command |
| avra-8sb5.31 | open | CACHE SOUNDNESS: deleting a program-test directory makes next `avra test` fail | CORE | open P1; suspect `closure_key` in compiler/build.av; suspect store saved | ../avra-fibers, lane/fibers |
| avra-8sb5.33.2 | closed | S2 within leaves the core (first witness) | IRRELEVANT (mentions "hold bug avra-8sb5.36" as open) | landed main 48a0131 | — |
| avra-8sb5.33.8 | open | Bound traits ride the held record | CORE | open P3: `meets_bound` PARSES a held file; record trait DeclId in held record | — |
| avra-8sb5.34.2 | closed | build cache is not keyed by the runtime library | CORE | fixed 05b679d; tools/link_cache_attack.sh in `make cache-attacks` | hygiene (lane/http-hygiene, NOT VERIFIED) |
| avra-8sb5.34.10 | closed | R4b — inline embedding of value records | IRRELEVANT | main 60f19ce + 48f0dfa (+0c12c7a) | — |
| avra-8sb5.34.30.2 | closed | L2 — IR ownership checker after the memory pass | IRRELEVANT | main 4e98526 | — |
| avra-8sb5.34.30.6 | closed | L1 turns main's cache-attacks red: a seal from another file under a hold | CORE | fixed main 4e98526 (l1 7d247d0); cache-attacks 65/27/0 | l1 |
| avra-8sb5.34.36 | closed | Public benchmark harness (wrk/oha, TechEmpower-style) | IRRELEVANT | cb8d88e lane/http-perf | lane/http-perf |
| avra-8sb5.34.46 | open | Store key: fold AVRA_CENSUS_TYPES into hygiene's codegen_mode | CORE | open; waits on lane/http-hygiene's `codegen_mode` reaching main | lane/http-hygiene |
| avra-8sb5.34.53.12 | open | FLOW 13 — store-table home, tx.send, outbox, flow.dual_write | IRRELEVANT (user-level @store over sqlite) | open; blocked by .34.53.10 | channels-design |
| avra-8sb5.36 | closed | Hold reads a shifted declared type after a type is inserted above it | CORE (must-read) | "does not reproduce as silent corruption on main 9f30b28"; pinned by cache_attacks step (faafc12); "Root rewrite = townhall decision 10" | found on lane/components |
| avra-8sb5.37 | open | Worktree builds share the main checkout's .avra-cache (tree_root skips a .git FILE) | CORE | still OPEN in tracker, though .34.2 says "already fixed on main (has_git uses exists…)"; cites fix 0745613 | bench-link agent |
| avra-8sb5.40.17 | open | tree_root() climbs to the highest .git ancestor; nested worktree shares cache | CORE | open; fix shape named, not designed | found on avra/main nested worktree |
| avra-8sb5.44 | open | ORM — typed models over every good database | ADJACENT (must-read; user ORM, not compiler db) | open epic; @model CRUD works on std-db; "Still holding per owner, not landing" as of last comment; .44.6 parked for Compiler DB M2 | ../avra-orm, lane/orm; lane/orm-grammar; lane/derive-lit; lane/stmt-cache |
| avra-8sb5.44.1 | closed | fix(backend): hollow_of has no float case, PHI type mismatch | IRRELEVANT to cache (one cache trap noted) | "Fixed and LANDED on main" (no sha); 6685/6685 | — |
| avra-8sb5.44.2 | open | bug(impls): two same-named methods in one impl block silently shadow | IRRELEVANT | open; fix = mirror F3003 | — |
| avra-8sb5.44.3 | closed | bug(expand): cross-package derive cannot build a full struct literal | IRRELEVANT | LANDED main (no sha); `use_type` two-tier fallback; 6708/6708 | ../avra-derive-lit, lane/derive-lit |
| avra-8sb5.44.4 | closed | bug(fmt): avra fmt refuses to write std-db/src/db.av (comment count 65->66) | IRRELEVANT | ba957e5 lane/fmt-bugs ("not yet merged — team lead's call") | ../avra-orm; lane/fmt-bugs |
| avra-8sb5.44.5 | closed | perf(sqlite): Db.run/… re-prepare on every call, no statement cache | IRRELEVANT (sqlite stmt cache) | closed 2026-09-25T05:03; .44 says verified 505/505 but "Not landing the stmt cache until" the 2x gap resolved — landing sha not recorded | ../avra-stmt-cache, lane/stmt-cache |
| avra-8sb5.44.6 | open | SQL: typed sql{} checked against @model at compile time (ORM Phase 6) | ADJACENT | "Parked 2026-09-26 for Compiler DB M2"; std-sql parser + resolve_select 46ec5e6; d23eccb on main | ../avra-sql, lane/sql-fast (UNCOMMITTED parser.av change) |
| avra-8sb5.44.6.1 | open | SQL: decide who owns a const's compile-time budget (owner decision pending) | ADJACENT | open P1, owner decision | — |
| avra-8sb5.44.6.2 | open | SQL: land const SQL_PARSER (grammar prepared once) in std-sql | IRRELEVANT | blocked on budget decision; uncommitted | ../avra-sql, lane/sql-fast |
| avra-8sb5.44.6.3 | open | SQL: the compiler parses @grammar_rule texts natively | IRRELEVANT | open | — |
| avra-8sb5.44.6.4 | open | SQL: sql{} block via a raw sublang mode | IRRELEVANT | open | — |
| avra-8sb5.44.6.5 | open | SQL: @std/db execution — run/all/begin/commit, ${hole} binding | IRRELEVANT | open | — |
| avra-8sb5.46 | open | URGENT: un-keyed fp_mix backs memo early-cutoff and build-store keys | CORE | open P1; awaits cache owner triage; options: 64-bit fold or exact fallback at cutoff sites | — |
| avra-8sb5.48 | open | make vocab: same_ins/remapped/fingerprint unregistered Ins consumers | ADJACENT (Ins fingerprint keeper) | open P3 | — |
| avra-8sb5.59.9.3 | closed | wasm32: the target is a first-class store identity | CORE | DONE 2f1d6f9: target folds into compiler_print/compiler_id; target_key deleted | opus-lane |
| avra-8sb5.59.9.5 | closed | wasm32: wrapper hygiene | IRRELEVANT | DONE a3b0a42 | opus-lane |
| avra-8sb5.59.11 | open | P1.3 avra dev — serve web, reload on change | IRRELEVANT | open; blocked by .59.10 | — |
| avra-8sb5.59.14 | open | P2.2 device replica + live queries | IRRELEVANT (compiler computes a screen's read set; user-level) | open; blocked by .59.12/.59.13 | — |
| avra-8sb5.59.27 | open | L4 — state & data: state bindings, @model forms, live queries | IRRELEVANT | state landed (#217,#219,#226,#228,#234,#257); @model forms + live queries open | main 5727f7e |


### Appendix A / slice other_p3

| id | status | title (≤80) | relevance | outcome | worktree/branch |
|---|---|---|---|---|---|
| avra-8sb5.59.27.1 | open | derived state — `derived visible = …` memoized into the read set | ADJACENT (UI memo, not the compiler kernel) | Want only; `derived` is a parse error at 48e8e62 | declarative-board lane |
| avra-8sb5.59.27.2 | open | live queries — a read that stays current as its source changes | ADJACENT (names "the query kernel's memo" as eventual home) | Want only; `query active = …` is a parse error at 48e8e62 | declarative-board lane |
| avra-8sb5.59.33 | closed | restore the L2 derive refusals and the @attribute(.X) override | IRRELEVANT (UI derive) | Done by PR #273 "in a different shape" | — |
| avra-8sb5.59.43.11 | open | components: statement stores one Param per member; event should be own member | ADJACENT (needs fingerprint/rebuild/format arms + `make seed`) | Not started; node reshape under node-variant law | — |
| avra-8sb5.59.43.17 | closed | A dialog on a page is a real modal | IRRELEVANT | Built on ui-dev 2a44aa4 | ui-dev |
| avra-8sb5.59.44.11.5 | open | web projection — keyed names, assets_route(), … CSP | IRRELEVANT (HTTP immutable caching of assets) | Design only (0b5bd64) | ui-assets-design |
| avra-8sb5.59.44.11.11 | open | email, terminal graphics, drawn target, service-worker precache | IRRELEVANT | Design only | ui-assets-design |
| avra-8sb5.59.44.11.12 | open | fetched pinned packages — pin, sha256, avra.lock, offline cache | IRRELEVANT (package download cache `~/.avra/cache/<sha256>`, not `.avra-cache`) | Design only | ui-assets-design |
| avra-8sb5.62.1.1 | open | Raw fragment: pointers, width loads/stores, unmanaged values | IRRELEVANT | Open | — |
| avra-8sb5.62.1.2 | open | Atomics with memory ordering | IRRELEVANT | Open | — |
| avra-8sb5.63.5 | open | Format adapters: JSON, YAML, TOML, forms, multipart, query, … | IRRELEVANT ("query" = URL query) | JSON+TOML landed 8e7c465; rest later | — |
| avra-8sb5.63.11 | open | avra run: a builder push loop is quadratic in memory | ADJACENT (evaluator copy defect; cited by .73) | Open, repro only | — |
| avra-8sb5.65 | in_progress | COLLECTIONS — one vocabulary …; a chain is one loop | ADJACENT | Epic; S0 merged (#53, 755a1fc); S1 partial | lead: COLLECTIONS LEAD |
| avra-8sb5.65.1 | in_progress | BENCH — collections vs Rust, C1–C12 | IRRELEVANT to db | Harness + baseline as PR #83 | ../avra-collections-bench / collections-bench |
| avra-8sb5.65.1.1 | in_progress | C1–C12 harness | IRRELEVANT | d249615, PR #83 "queued"; close on merge | collections-bench |
| avra-8sb5.65.1.2 | open | Baseline run before S1 | IRRELEVANT | dcba9aa committed; quiet-Sprite re-run owed | collections-bench |
| avra-8sb5.65.2 | open | S0 — Map hash: seeded, full length, one probe | IRRELEVANT | Still open in tracker though .65.1.1 says "S0 (#53) merged as 755a1fc" | — |
| avra-8sb5.65.3 | in_progress | S1 — pipeline, inline lambdas, ranges, verbs … | ADJACENT | Partial (see children) | — |
| avra-8sb5.65.3.1 | closed | Pipeline IR: Source, Clause, Sink; comprehensions lower through it | ADJACENT (planner's Lookup moves into pipeline.av) | Closed 2026-10-01; no PR/sha named for the landing (lane commits 13c615c, 0c6bd1c) | ../avra-collections-pipeline / collections-pipeline |
| avra-8sb5.65.3.2 | in_progress | Method chains fold into the pipeline | ADJACENT | #161 merged (adapters); #168 queued (terminals); aggregates local a518aa7+24bcc90 | collections-chains, collections-inline |
| avra-8sb5.65.3.2.1 | open | The relation planner narrows method chains, as it narrows comprehensions | CORE-ADJACENT (relation planner, `features/lists/plan.av`) | Not started; no comments | — |
| avra-8sb5.65.3.2.2 | open | Retire bool_comprehension_* rules | IRRELEVANT | Waits on .3.4 | — |
| avra-8sb5.65.3.3 | in_progress | Inline lambdas at verb seats | IRRELEVANT | Recon only; "Not started — held for a dedicated session" | — |
| avra-8sb5.65.3.4 | in_progress | Range as a value: (lo..hi) as a primary, range methods | IRRELEVANT | Grammar landed; `.any/.find/.all` hit `language.defect` at 48e8e62 | — |
| avra-8sb5.65.3.5 | open | Transform verbs | IRRELEVANT | Blocked on .3.2 | — |
| avra-8sb5.65.3.6 | open | Filter and slice verbs | IRRELEVANT | take/drop WIP **stashed**; blocked on evaluator bug avra-dw89 | (stash in worktree, unnamed) |
| avra-8sb5.65.3.7 | open | Search verbs | IRRELEVANT | Blocked on .3.2 | — |
| avra-8sb5.65.3.8 | open | Aggregate verbs | IRRELEVANT | count/sum/min/max on collections-inline; fold, min_by/max_by remain | collections-inline |
| avra-8sb5.65.3.9 | open | Combine verbs | IRRELEVANT | Blocked on .3.2 | — |
| avra-8sb5.65.3.10 | in_progress | Map verbs: has, remove, keys, values, entries, `for k, v in m` | ADJACENT (contradicts CLAUDE.md "a map cannot be iterated") | #207, #211 merged; #266 queued; entries parked | mapswalks |
| avra-8sb5.65.3.10.1 | open | A built-in Entry<K, V> type | IRRELEVANT | Open; core/types event | — |
| avra-8sb5.65.3.11 | open | Map insertion order as a guarantee | ADJACENT (map-order law) | Comment says "Done: #207 … #260" but status still open | — |
| avra-8sb5.65.3.12 | open | T? answers: index_of (146 sites), pop (64 sites) | IRRELEVANT | Open | — |
| avra-8sb5.65.3.13 | in_progress | String lenses: s.chars / s.bytes as Walk sources | IRRELEVANT | #202 merged; #265 (bytes half) queued; chars held | stringlenses, stringlenses-lens |
| avra-8sb5.65.3.13.1 | open | Codepoints lowering emits IR without bound | IRRELEVANT (memory blowup, emission) | Open | stringlenses-lens |
| avra-8sb5.65.3.14 | open | Migration rules and avra fix, S1 renames | IRRELEVANT | Blocked on .3.5 | — |
| avra-8sb5.65.4 | open | S2 — speed, order, Avra-bodied verbs, int keys, Set, Cursor | IRRELEVANT | Blocked on .65.3 | — |
| avra-8sb5.65.4.1–.4.11 (11 tickets) | open | E3 loads / E4 pre-size / E5 reuse / toolchain pkg / sort / group_by,index_by / int keys / Set / SwissTable / Cursor / migration S2 | IRRELEVANT (.4.6 `index_by`, .4.7 int map keys, .4.8 Set touch what db tables could use) | All open, no comments | — |
| avra-8sb5.65.5, .5.1–.5.3 | open | S3 — Walk and Indexed traits | IRRELEVANT | Open; needs trait type params + F2031 | — |
| avra-8sb5.65.6, .6.1 | open | S4 — streams | IRRELEVANT | Open; design first | — |
| avra-8sb5.67 | closed | the object cache is not keyed by target — wasm link handed native objects | CORE | "Fixed on branch cache-target, commit 0bdcb6d (not pushed)"; .68/.72 call it PR #272 | cache-target |
| avra-8sb5.68 | open | cache: wasm-opt keyed by presence, not identity | CORE | Open | — |
| avra-8sb5.69 | open | cache: linker and its environment are in no key | CORE | Open; "Read from code, not exercised" | — |
| avra-8sb5.70 | open | cache: tools/ui-board's hold is refused on every edit | CORE | Open; "Likely the stale-hold defect avra-8sb5.36; confirm or link" | — |
| avra-8sb5.71 | open | build: a failed wasm link leaves its .staged file | CORE (weak) | Open but reporter RETRACTED the observation; "Reproduce before fixing, or close" | — |
| avra-8sb5.72 | open | test: compiler_print_adversarial_test's anew() case never calls anew() | CORE (test) | Open; rename or make it call anew() | — |
| avra-8sb5.73 | open | avra run: map filled by set in a loop is quadratic in MEMORY | ADJACENT (evaluator; Table/Cell<Map> shapes the db uses) | Open | base ui-arch 2d3bc5c |
| avra-8sb5.74 | open | runtime/tests/guard_ledger_test fails one check on macOS at 92678df | IRRELEVANT | Open | — |
| avra-8sb5.75 | open | avra test leaves tests/<program>/build/suite untracked | IRRELEVANT | Open | — |
| avra-8sb5.76 | open | the compiler compiles what a program reaches — not every decl in closure | CORE (Kernel.newly_read memory; partly-held rebuild) | Open; numbers only, no design | ui-dev (numbers) |
| avra-8sb5.77 | in_progress | Sprites: diagnose and fix why they stall | ADJACENT (per-Sprite compiler cache keyed by compiler source hash) | sprites-fix f22087f + sprites-next 49bfbef (local) | sprites-fix |
| avra-8sb5.78 | open | avra test <file> then avra test <its directory> runs compiler past 5 GB | CORE (P1) | Open; workaround park `.avra-cache` | wants-modules |
| avra-8sb5.79 | open | fingerprint: f(g(x)) and g(f(x)) wear one fingerprint (fold is linear) | CORE | Open; fix = non-linear mix in core/fp.av, rides seed refresh | pipe-op (base 05fe643) |
| avra-9vy7 | open | no held-package test infrastructure exists for Type.Union | CORE (held interface records) | Open | — |
| avra-9xt5 | closed | Lane A: integrate.sh integrates in a DETACHED CLEAN WORKTREE | IRRELEVANT (landing tooling) | LANDED main 812495c | avra-integrate-<lane> |
| avra-b878 | open | the gate loses everything when killed near the end | ADJACENT (per-step receipt keyed on tree hash) | Open | — |
| avra-bybt | open | TRIGGER: Name input_memo, Program.shown and no_manifest at third copy | ADJACENT (`input_memo`: third input family memoized) | Open at main eec73f8; owner unconfirmed | — |
| avra-e21k | closed | Makefile: audit every remaining build redirect for a ceiling | IRRELEVANT (log caps; "witness" = make witness) | main 57a57bd (seed bad112d) | toolchain/caps c870601 |
| avra-egav | open | measure the after-census for the derived fingerprint | CORE (sig_hash hot path) | Open; after-figure never measured | — |
| avra-g10d | open | tools/census.sh deletes build/avra_runtime.o and does not restore it | IRRELEVANT | Open | — |
| avra-kbxq | open | harness kills a gate for low system memory … | IRRELEVANT | Open (title only) | — |
| avra-knya | open | CACHE SOUNDNESS: stale .avra-cache served type facts after declarations shifted | CORE (P1) | Open; hypothesis only | ../avra-fibers (lane/fibers) |
| avra-n1w7 | closed | TOOLCHAIN — std from install root, prelude, … | IRRELEVANT | Closed at main 25cee6b | — |
| avra-xtnx | closed | AFTER make seed carries #11: strip every @std/* path row | IRRELEVANT | main 57a57bd (seed bad112d) | toolchain/after-seed |
| avra-ybs2 | open | WHEN A TIMING FIX SEEMS TO NEED A TIMING TEST … | IRRELEVANT | Open (doctrine note) | — |
| avra-yp6n | open | the Store/Host seam: a lone file's .ll/.plan/.warn go to an IN-MEMORY host | CORE | Open; "FOLD INTO RUNG 4 (per-file modules)" | — |
| avra-zsc2 | open | scratch file's .avra-cache served an object built by an OLDER compiler binary | CORE (P1) | Open; TITLE ONLY in the input (file ends at the title line) | — |


## Appendix B — every measurement (deliverable 3)


### Appendix B / slice 57_p1

All "MEASURED-by-ticket" = the ticket text states it as measured; none re-run here.

| ticket | date | value (exact quote) | what / command | commit / base named | MEASURED-by-ticket |
|---|---|---|---|---|---|
| 57.1 | 2026-09-27T00:14 | "cli 85/85, idioms 0 new" | M0 checks | lane/db 3f0520f | yes |
| 57.2 | 2026-09-27T04:59 | "Cold check-cli 327.9B -> 325.8B, warm 0.391B -> 0.366B, peak -12%" | check cli instructions (unit "B" as written), before/after M1 | lane/m1 898a69f + merge 57d8a39 | yes |
| 57.2 | 2026-09-27T04:59 | "kernel last-reader stamp (3 tests)" | test count | lane/m1 | yes |
| 57.2 | descr | "22 *_memo fields and 24 hand family lists" | Workspace before M1 | - | stated |
| 57.2.4 | 2026-09-27T05:08 | "suite floor swamps the stamped-vs-unrecorded delta" | stamped vs unrecorded read cost — NOT measured | - | NO (explicitly undelivered) |
| 57.4 | 2026-09-27T00:11 | "41/41 + program test eval==native==expected" | @std/relation suite | main 6d894d5 | yes |
| 57.4 | 2026-09-27T08:22 | "insert ~11.9k instr (put 8.2k, 0 clones), identical upsert ~5.5k, by_key ~476 with prebuilt key, by_index ~148/row" | std-relation generated accessors, instr per op | main 8aaf557 | yes ("PERF numbers") |
| 57.4.6 | close | "answers_test 6/6, std-relation 114/114" | @query persist suites | main bc2d64a (lane/query-persist 4c01397) | yes |
| 57.4.6 | 2026-09-30T00:17 | "≥51.6M deps on cli" | kernel deps count (reason witness wire deleted) | - | stated (PERF/lead) |
| 57.4.7 | 2026-09-30T10:07 | "load 28–35" | machine load blocking local runs | - | yes |
| 57.4.7 | 2026-09-30T10:07 | "exactly ONE late write (family 27, cell 0, rev 1→2), then an endless reuse cycle over families 1/2/4 arg 209" | gen-2 segfault trace | lane/arm-decl-rows | yes |
| 57.4.7 | 2026-09-30T10:07 | "'side table bindings holds [0, 899)'" | pass-2 re-analysis trap | lane/arm-decl-rows | yes |
| 57.4.7 | 2026-09-30T20:10 | "blew the cli build to 6.9 GB/30 min" | load_imports mint-everything fix (dropped) | lane/arm-decl-rows | yes |
| 57.4.7 | 2026-09-30T20:10 | "cli build peak ~1.7 GB" | target for witness | - | target, then measured below |
| 57.4.7 | 2026-09-30T23:45 | "build2 exit 0, answers 42"; "open=19/0 = Family.References"; "watch.sh sampled 0 MB — too fast" | held repro; trace; failed peak sample | lane/arm-decl-rows ff60054 | yes |
| 57.4.7 | 2026-10-01T23:05 | "test packages/std-avrac 7628/7628" | Sprite suite | arm-decl-rows-gh (PR #72) | yes |
| 57.4.7 | 2026-10-01T23:05 | "COLD cli build peak = 1677 MB (~1.7 GB, /proc VmHWM sampler)" | cold cli build memory, Sprite | arm-decl-rows-gh, rebased on origin/main | yes |
| 57.4.7 | 2026-10-01T23:05 | "numbered i across before.concat(keys) (12 inner lists) so bucket_of indexed indexes[6] of a 6-index relation" | late_check defect sizes | f6ef163 | yes |
| 57.4.7 | 2026-10-01T19:22/23:05 | "9 commits"; "main had moved 27 commits"; "queued at position 4" | rebase facts | f3b604a, head ca891ab | yes |
| 57.6 | 2026-09-28T08:35 | "0/715 held after a one-file edit"; target "edited held ~714/715" | witness_receipt.sh, CLI | 61e0abb (499df24) | yes (later corrected: that was the .40 held path) |
| 57.6.3 | 2026-10-01T10:41 | "warm check `held 3/5`" | pin zp, 3-module chain, body edit to m1 | PR #104 | yes |
| 57.6.3 | 2026-10-01T10:41 | "warm check exit 0, `held 2/3`" | deleted-import defect probe on main | main (pre-#104) | yes |
| 57.6.3 | 2026-10-01T10:41 | "cache-attacks 161 builds, 61 under a hold, 0 failed (final rebase onto 53110b0: 163 builds, 63 under a hold, 0 failed)" | make cache-attacks | PR #104 / 53110b0 | yes |
| 57.6.4 | 2026-10-01T10:41 | "45 of 163 steps failed in that tree" | red tree: key_of_parts without its seen part | PR #104 | yes |
| 57.6.5 | 2026-10-01T10:41 | cold "42.57s held 0/408" (main d4a9796) / "40.64s held 0/408" (m3-close); 2nd "41.05s" / "39.88s" | cold `check packages/cli`, one Sprite (avra-comptime), identical input | main d4a9796 vs m3-close | yes |
| 57.6.5 | 2026-10-01T10:41 | warm no-op "0.21s whole-check hit" / "0.26s whole-check hit"; 2nd "0.21s" / "0.22s" | warm no-op check cli | same | yes |
| 57.6.5 | 2026-10-01T10:41 | body edit "5.39s held 404/408" / "5.02s held 404/408"; 2nd "5.16s" / "4.87s" | string-literal edit in commands/cache.av | same | yes |
| 57.6.5 | 2026-10-01T10:41 | restored "0.21s hit"/"0.21s hit"/"0.20s"/"0.19s"; after new decl "0.19s hit"/"0.24s hit"/"0.23s"/"0.22s" | restore to whole-check hit | same | yes |
| 57.6.5 | 2026-10-01T10:41 | new decl "50.16s held 0/408 *" / "51.76s held 0/408 *"; 2nd "52.22s *" / "51.81s *" | appended `fn witness_receipt_probe`; hold REFUSED | same | yes |
| 57.6.5 | 2026-10-01T10:41 | "the 4 read files are the edited file, the entry, and the two whose bodies run at compile time" | what a body edit re-reads | same | yes |
| 57.6.5 | 2026-10-01T10:41 | retains "1,006,518,728" -> "1,006,542,952" "+24,224 (+0.002%)" | census, cold check packages/cli, same Sprite | main d4a9796 vs m3-close | yes |
| 57.6.5 | 2026-10-01T10:41 | releases "1,325,361,627" -> "1,325,388,004" "+26,377 (+0.002%)" | same | same | yes |
| 57.6.5 | 2026-10-01T10:41 | list reads "4,682,063,952" -> "4,679,317,978" "-2,745,974 (-0.06%)" | same | same | yes |
| 57.6.5 | 2026-10-01T10:41 | list writes "1,335,891,103" -> "1,335,884,997" "-6,106"; boxes "328,903,397" -> "328,902,278" "-1,119" | same | same | yes |
| 57.6.5 | 2026-10-01T11:35 | cold "41.33s held 0/408" / "41.22s held 0/408"; no-op "0.22s" / "0.22s"; body edit "4.95s held 404/408" / "5.09s held 404/408" | check packages/cli, one Sprite (avra-phase-d), identical source | main 9ff050c vs branch hold-new-decl | yes |
| 57.6.5 / 57.6.6 | 2026-10-01T11:35 | new decl "52.73s held 0/408, hold REFUSED (rules_test.av expr 155)" -> "13.16s held 346/408, no refusal" | same | main 9ff050c vs hold-new-decl | yes |
| 57.6.5 | close | "cold 41.2s; no-op 0.22s; body edit 5.1s held 404/408; NEW declaration 13.2s held 346/408 (was 52.7s, 0/408, hold refused)" | final receipt | PR #108 (dcaba11) | yes |
| 57.6.6 | 2026-10-01T11:35 | "62 read = the commands module's siblings + tests + entry, whose seen interface moved" | files re-read after a new decl | hold-new-decl | yes |
| 57.6.6 | close / 11:35 / 11:57 | "cache_attacks nd: 9 FAIL on main -> 0"; "full make cache-attacks 170+ steps 0 failed"; "170 steps 0 failed" | pin nd | PR #108 | yes |
| 57.6.6 | descr | "held 0/408 and ~50s (cold is ~41s) where the body-only edit of the same file holds 404/408 in ~5s" | defect statement | main d4a9796 | yes |
| 57.7 | 2026-09-28T13:39 | "~3,550 fns" | static reach from a query bracket (whole typer) | - | stated |
| 57.8 | 2026-09-29T03:47 | "+1.55% instr, +10.7% footprint from rows_read's record_dep" | ERRORS chain on the speed gate | chain S1-S3a | yes |
| 57.8.1 | 2026-09-29T18:00 | "~938 instr/repeat read vs ~90 raw" | ORM's recorded get_from vs raw row read | - | yes |
| 57.8.1 | 2026-09-29T20:43 | "identical-input census +0.53%" | S1 File/Module | main 31b8e21 | yes |
| 57.8.1 | close / 2026-09-30T07:30 | "PERF identical-input census +0.95% (from +19.27%)" / "(was +19.27 at 93b2fc6)" | S2 Decl as @relation | 64c0e09; landed 2e99559 | yes |
| 57.8.2 | 2026-10-01T09:31 | "RED on main 6/17 ..., GREEN 17/17"; "make cache-attacks green (138+13 builds, 0 failed)" | readmit_test; cache-attacks | PR #101 | yes |
| 57.8.3 | 2026-10-01T09:31 | "retains 1041.76M -> 1011.03M (-2.95%), releases -2.19%, list reads 4832.7M -> 4699.9M (-2.75%), list writes 1322.7M -> 1340.2M (+1.32%), boxes +0.27%, list buffers +1.06%, wall 69.4/68.8s -> 67.6/67.4s (-2.3%)" | same-input census, check packages/cli | main acf083c's tree, PR #101 | yes |
| 57.8.3 | 2026-10-01T09:31 | "First draft ... was +1.6% retains/+3.4% writes — fixed before landing" | rejected draft (Decl.by_home rows + package_decl scan) | PR #101 | yes |
| 57.8.4 | close | "collects_test 55/55 (red-team cases included), std-avrac 7449/7449 on Sprites" | suites | main 2e99559 | yes |
| 57.9.1 | 2026-09-29T09:57 | "error_sites_test.av 10/10" | test | lane/db-errors b4d19e1 | yes |
| 57.9.6 | 2026-09-29T11:17 | "cold (first check): 2,860,976,266 instructions, 0.89s wall" | 300-fn `?` chain, one file, `/usr/bin/time -l build/avra check <file>` | avra-db-errors' built binary | yes |
| 57.9.6 | 2026-09-29T11:17 | "warm, nothing edited (memo hit): 652,560,176 instructions, 0.07s wall" | same | same | yes |
| 57.9.6 | 2026-09-29T11:17 | "after editing f0's raised type: 2,909,896,168 instructions, 0.57s wall" | same (zero incrementality) | same | yes |
| 57.9.6 | 2026-09-29T11:17 | "9 sites across 4 files, grepped"; "900-line file" | `_`-declared fns in the compiler; fixture size | - | yes |
| 57.10.4 | close | "scan_floor (1000, measured: 24 ns/row scan vs 145 ns lookup)"; "1 true positive in 15 census-marked scans" | type.plan_scan threshold | main 6dba4a5 | yes |
| 57.12 | descr | "Family (22 arms), DbKind (21 arms)" | enum sizes at filing | - | stated |
| 57.12.4 | 2026-09-30T09:10 | "the 26 families"; "the 6 relations" | counts | lane/n3-family 4262aa6 | stated |
| 57.12.4 | 2026-10-01T09:49 | "LiftLowered sits at 24" | ordinal | PR #103 | stated |
| 57.12.4 | 2026-10-02 | "30 markers by rank dense"; "(rank dense 0..29)"; "tools/families.py reads marker ranks (30/30)" | Family after #192 | PR #192 | yes |
| 57.3.8 | 2026-09-29T17:53 | "SIGSEGV, exit 139" | compiler crash, WIP port (reverted) | - | yes |

Not present in this file: memory per row/edge, witness byte sizes, .avra-cache sizes.


### Appendix B / slice 57_p2

All "MEASURED-by-ticket" = the ticket text reports it as measured; ESTIMATE where the text says rough/estimated. None re-measured here.

| ticket | date | value (exact quote) | what / command | commit / base named | status |
|---|---|---|---|---|---|
| .12.5 | 2026-10-02 | "DbKind (compiler/db.av, 24 arms) … 16 one-payload DENSE arms + 8 two-field DURABLE arms" | DbKind/DbRow variant count | after #192 | MEASURED-by-ticket (count) |
| .12.5 | 2026-10-02 | "Family has 30; the other 14 … have no DbRow variant" | Family arms | after #192 | MEASURED-by-ticket |
| .13 | 2026-09-27 | "the cap fires in ~5 turns not 10000"; "9 spec cases" | fixpoint turn cap test | 9c081e7 | MEASURED-by-ticket |
| .14 | 2026-09-28 | "9 spec cases"; then "15 store-level + 3 over a real Analysis entry" | explain.av tests | 2c13cd4 / e9d0090 | MEASURED-by-ticket |
| .14 | 2026-09-29 | "Census cold check cli same input: keep +3.8%, wall/RSS flat, store +12.9% (lead approved)" | N6 S2 cost | 3725a7b (code 35a442e) | MEASURED-by-ticket |
| .14 | 2026-09-29 | "Store +16.2% for the forms rows" | N6 S3 store size | 1936811 | MEASURED-by-ticket |
| .17 | 2026-09-27 | "3-head test expected 311 but 1+10+200=211 (test wrong)"; "4 failures" | joins landing attempt | pre-7975a2b | MEASURED-by-ticket |
| .18 | 2026-10-01 | "unrecorded ~120 instr, stamped repeat ~315, new recorded dep ~1900; per-node recording would cost 2.5x-15x more across typing's millions of reads" | kernel read cost (quoted from townhall §6.11) | - | quoted, "Measured" per text |
| .18 | 2026-10-01 | "NameFacts … 4 SideTable<T> columns"; "TypeFacts … 22 SideTable<T> columns"; "26 columns total" (NB the listed TypeFacts names number 24) | column counts | main at 2026-10-01 | MEASURED-by-ticket |
| .18 | 2026-10-01 | "partition_test.av (6 new spec cases), relation_test.av (37/37) and relation_adversarial_test.av (21/21)" | S1 tests | PR #89 9e68842 | MEASURED-by-ticket |
| .18 | 2026-10-01 | "measured dead across std-avrac (7655/7655), cli (147/147), and make cache-attacks (163+13 builds through one store, 0 failed) with the trap never firing" | S3 part 1 held-file fallback | PR #110 3187fec | MEASURED-by-ticket |
| .18 | 2026-10-01T13:38 | "check cli: cold 35044ms, warm (single comment edit) 5190ms wall, matching the lead's 5.0s reference" | warm vs cold `check cli` | main 2026-10-01 | MEASURED-by-ticket |
| .18 | 2026-10-01T13:38 | "analyze(typing) 1875ms (36%), lower 604ms (12%), load+admit 1781ms (34%, unrelated held-file loading cost) … Phases sum to 8177ms vs 5190ms wall (some overlap/pipelining, flagged as a caveat)" | warm phase breakdown | same | MEASURED-by-ticket (caveat stated) |
| .18 | 2026-10-01T13:38 | "analyze+lower together if BOTH are skipped per decl: 2479ms, 48% of wall" | upper bound of per-decl skip | same | MEASURED-by-ticket |
| .18 | 2026-10-01T13:50 | "'declare' fires for every decl in the whole program regardless of held status (1975 total events)" | QTRACE warm docs.av edit | same | MEASURED-by-ticket |
| .18 | 2026-10-01T13:50 | "101 total Typed computes, 80 total Lowered computes this warm run. docs.av … declares 11 names. … 11/101 ~11% … ~272ms, ~5% of the 5190ms wall" | per-decl attribution | same | ESTIMATE ("count-based, not precisely timed") |
| .18 | 2026-10-01T13:51 | "30% bar (1.56s of the 5.19s wall, out of analyze+lower's 2.48s combined) … ~63% of all typing+lowering work … roughly 6x the average declaration's cost"; "Uniform-cost assumption: ~5% of wall. Generous 3x assumption: ~15%." | sensitivity bound | same | ESTIMATE |
| .18 | 2026-10-01T13:51 | "packages/cli, cold 35.0s / warm 5.19s"; "load+admit (~1.8s, 34% of wall, held-file record loading — PERF's territory)" | finding for the record | same | MEASURED-by-ticket |
| .18 | 2026-10-01T16:07 | "Full std-avrac suite green (7621/7621). Census on check cli measured within ~0.1% of a fresh main baseline (retains/releases/reclaims/list-reads/list-writes all 0.09-0.12%)" vs "the lead's ±1% bar" | S4 census | PR #118 51d36f49 | MEASURED-by-ticket |
| .18.1 | 2026-09-29 | "Census rc/alloc identical" | Expr kind buckets | 3d8e30e | MEASURED-by-ticket |
| .18.2 | 2026-09-30 | "+1.08% instr on cold check-cli" (dropped from batch 3 on the speed gate) | NameFacts per-decl door | lane/m5b-facts e8d1641 | MEASURED-by-ticket |
| .18.2 | 2026-09-30 | "identical-input speed delta +1.78% on current main, unchanged by the name_slice_fp rework (6371f8c …)"; "the family table growing to 27" | same | 6371f8c | MEASURED-by-ticket |
| .18.2 | 2026-09-30 | "Identical input: +0.20%. names_family 4/4." | after perf/m5b-names | b633486 | MEASURED-by-ticket |
| .18.4 | 2026-09-29 | "58 files, 262 occurrences" then landed "59 files, 271 occurrences" | NodeStore→SyntaxArena rename | 0d3e1ad | MEASURED-by-ticket |
| .18.4 | 2026-09-29 | ".avra-cache across sibling worktrees sums to ~15.9 GB (du -sc over ~140 avra-* worktrees) … avra-witness-loadbase 526M, avra-bracket 462M, avra-n3-apply 352M, avra-audit 351M, avra-wrap-outside 334M, avra-witness-gate 329M" | .avra-cache disk | - | MEASURED-by-ticket |
| .18.4 | 2026-09-29 | "make bootstrap fails at the 2048MB safety floor (currently ~1.1-1.2 GiB free, dropping)" | disk floor | - | MEASURED-by-ticket |
| .18.4 | 2026-09-30 | "builds measured at ~700MB via build/avra directly as if they used 4-7GB" (shim watchdog cap unreliable) | build memory | - | MEASURED-by-ticket |
| .18.4 | 2026-09-30 | "avrac_self_any's dual-name lookup measured a real +1.16% instructions-retired regression"; fixed by b3e16f6 "speed gate: OK" | bridge cost | b3e16f6 | MEASURED-by-ticket |
| .19 | 2026-09-26 | "'index 221 is out of bounds (length 181)' after '175 examples proved, as cases'"; clean cache "24/25" | warm-cache trap repro | main 47d72d5 | MEASURED-by-ticket |
| .19 | 2026-09-27 | "text_digest always hashes, stamp cache deleted, no measurable cost" | fix cost | 92b24db | MEASURED-by-ticket (no number) |
| .23 | 2026-09-30 | "181 examples proved"; rerun "exit 0, memcap peak 720MB"; "store_test.av … (7/7 passing)"; "pack_test.av … (11/11 passing)"; "pack_adversarial_test.av (13/13 passing)"; "load average 40-130"; "free disk fell to ~1.5 GiB" | torn-cache refutation | HEAD 0d3e1ad | MEASURED-by-ticket |
| .24 | 2026-09-27 | "test 6890/6890"; "6949/6949"; "23 packages clean"; "a module record with 221 decls … into a 181-decl module" (hypothesis) | test-then-check trap | land/wrap-12 over main 899e0ea; ec1e279 | MEASURED-by-ticket / last is HYPOTHESIS |
| .25 | 2026-09-27 | "decl_ids.length=695 held CONSTANT"; "find packages/std-avrac/src -name '*.av' \| wc -l = 726"; "the 473 Sig-shaped rows list" | .24 trace | lane/land-tools | MEASURED-by-ticket |
| .30 | 2026-09-27 | "unrecorded read ~125 instr, stamped HIT ~315, new dep ~1,900 (stable over N=1e5..1e7)"; target "hit within ~20 instructions of unrecorded" | /tmp/kbench (M1 micro-bench, townhall §3.4) | - | MEASURED-by-ticket |
| .31 | 2026-09-28 | "hit 330->251, new dep 1907->1453, cold check-cli -0.12%" | kbench after fix | lane/k31 86db86c | MEASURED-by-ticket |
| .34 | 2026-09-27 | "Cost -0.09% (noise)" | cold check-cli after alloca init fix | cf97209 / 57999f4 | MEASURED-by-ticket |
| .36 | 2026-09-27 | "(11 false findings)"; "@keeps example 176th" | dead_parameter | 8aaf557 | MEASURED-by-ticket |
| .37 | 2026-09-27 | "Est. 3-5h"; Param "embedded by value in six places" | ParamId scope | - | ESTIMATE |
| .39 | 2026-09-27 | "131 refused_with sites"; "21 cascade-pinning tests updated"; "std-grammar 28/28, std-relation 77/77 + 3 programs, std-avrac 7001/7001" | grammar double-refusal fix | 9c973e5 (18aec91) | MEASURED-by-ticket |
| .40 | 2026-09-28 | "cold held 0/715; one fn appended to features/decls_mint.av -> hold refused with this exact defect, held 0/715, full rebuild" | check, edit, check (witness_receipt.sh) | main 61e0abb + netlink fix, std-avrac | MEASURED-by-ticket |
| .42 | 2026-09-27 | "Fails 'Rows names no type' (type.unknown) at 17 sites" | name-holed fn | main 9c973e5 | MEASURED-by-ticket |
| .51 | 2026-09-28 | "the empty program's hash (272467045)" | missing-file witness | - | MEASURED-by-ticket |
| .53 | 2026-09-28 | "dump: Sig 493117911->0, 0->493117911" | stable-name renumbering | - | MEASURED-by-ticket |
| .54 | 2026-09-28 | "entry stamped 999 reused" | record-shape stamp never compared | - | MEASURED-by-ticket |
| .55 | 2026-09-28 | "Flattened witnesses measured +62..216%" | flattened witness cost | - | MEASURED-by-ticket |
| .55 | 2026-09-28T21:38 | "ON: cold keep 27-38s, edited 95-150s, leaf edit OOM 4.4GB vs main edited ~5s. OFF: edited 11.7-14.5s under heavy load, held 0/734 + intermittent 'Bad settled a second time'" | witness switch on/off | lane/witness-wire e4d4420 | MEASURED-by-ticket |
| .55 | 2026-10-01 | "(−2299/+487 lines)"; "10 test files"; "body edit 404/408 held on both compilers; a new declaration refuses the hold on both" | PR #104 deletion + receipt | 85f1046 | MEASURED-by-ticket |
| .56 | 2026-09-28 | "a stamp hit costs ~251 instr vs ~126 unrecorded (bench: perf-notes/kbench)"; target "within ~20 of unrecorded" (result after fix NOT stated) | kbench | after 86db86c; landed 2e99559 | MEASURED-by-ticket |
| .58 | 2026-09-28 | "features/ is 28 files, 244/759 files reference features" | Namespace edge fan-out | 0304ce6 | MEASURED-by-ticket |
| .29 | 2026-09-27 | "cli 89/89" | stage.av fix | c972222 | MEASURED-by-ticket |
| .43 | 2026-09-28 | "Golden = 5 real-subprocess cases"; .44 "Golden (4 cases)" | fmt note / hold_refusal | a729afe | MEASURED-by-ticket |

Not present in this file: memory per row/edge, witness byte sizes.


### Appendix B / slice 57_p3

All are MEASURED-by-ticket (the ticket's own claim) unless the last column says otherwise. None re-measured here.

| ticket | date | value (exact quote) | what / command | commit / base named | measured? |
|---|---|---|---|---|---|
| .59 | 09-28 | "6 store-level on test-written packs + 8 over real Analysis entries" | tests for explain dependents | f2bb038 | yes |
| .60 | 09-28 | "holds 607/717"; "Same 110 unheld both times"; "Cold denominator 719 vs edited 717" | witness_receipt.sh on std-avrac after a one-file edit | fix/held-settle 0282308 | yes |
| .60 | 09-28 | "607->643/717 held"; "Remaining 74 are named" | same, after fix | da1fa34 | yes |
| .61 | 09-28 | "passed 468/468 twice" | std-http suite | lane/lint merged tree | yes |
| .65 | 09-28 | "8/11 unit cases; 2 positive CLI cases" fail without fix | witness | caeac4c | yes |
| .66 | 09-28 | "cache_after_A 74MB" | .avra-cache size after witness_text_test | lane/parsed-cutoff | yes |
| .67 | 09-28 | "GREEN: 7136/7136"; "127 refusals" (52 + 52 + 1 + 4, "plus 2x language.defect") | cold vs warm `build/avra test packages/std-avrac` after one test-file edit | main 73457cb + holed-seat (05376e5) | yes |
| .72 | 09-28 | "~369.7B instructions" (gen-1) vs "~378.1B — +2.2%" (gen-2==gen-3) | cold check-cli | main d8954e6 | yes |
| .72 | 09-28 | "0 thaw sites" gen-1; "472 (+41% retains) = the +2.2%" | compiler's own body | seed 0876516 | yes |
| .82 | 09-28 | "~19 instructions before the branch"; "doubled decl() (34 -> 68 instructions)"; "+0.69% on cold check-cli across 7 accessors" | Cell<bool> field read, disassembly of Decls.decl | ERRORS' dep-audit census | yes |
| .84 | 09-28 | "peek sig held=fn ^x ^b fresh=fn ^K~i ^b"; after fix "0 mismatches" | --verify-held | 06dcce9 | yes |
| .88 | 09-28 | "~9 min cold per run" | sprite-build compiler rebuild per commit | main a8e57ea | yes |
| .90 | 09-28 | "66 fields"; "13 types marked, 13 set-once fields licensed"; "Workspace.items+420" | Decls clone / @identity survey | 4ee69c3 | yes |
| .91 | 09-28 | "held 659 -> 408/735, admit 2.5s -> 11-26s"; "~250 files Unkept" | one-file warm edit | bisected to c855084 | yes |
| .91 | 09-28/29 | "held 260 -> 710/759 (IDIOMS gate: 712/761)"; "Remaining ~49" | body-edit repro after fixes | 360f790, 84f9f82, ceeea19 | yes |
| .92 | 09-28 | "2x slower per line, warm reuse 659->221 of 753 held"; threshold "+5%"; "land_test 175s->40s" | land.sh gates | b460e1b | yes (threshold = spec) |
| .93 | 09-28 | "77.1M retains per check-cli from rows_read alone" | per-caller census | M5 chain | yes |
| .93 | 09-30 | "retains +0.40% check-cli, +0.72% check-std-http" | cost of UAF fix | perf/view93 7cbba5c | yes |
| .97 | 09-29 | "372.3G instr at main -> 312.4G with the const table (-16.1%)"; "cold cli ast 23.8s -> 13.6s" | fmt over std-avrac | perf/parse | yes |
| .97 | 09-29 | "105.17G -> 93.43G instructions (-11.2%)", 3 runs | cold `fmt --check packages/std-avrac` | 3884f61 | yes |
| .99 | 09-30 | "std-avrac 7343/7343, cli 115/115" | suites | 5e5db1b | yes |
| .100 | 09-29 | "cold -0.10% (noise), warm check -9.35% instr, held 90->98/399 on check (warm build 348->393)"; "7 files re-check on every edit" | PERF census | main f8ebab8 | yes |
| .101 | 09-29 | "warm rebuild 45.3s->16.5s, warm check held 397/399, landings ~7-10 min; COLD build 69s (target <40s)"; title "build 97s" | notes | - | yes |
| .101 | 10-01 | "warm one-line fmt.av edit check 2.28s vs base 2.46s (~8%, load -66ms, keep -110ms)"; "cache_attacks 23 failed vs base 2" | slice-2 (view_print) | perf/hold-keys 9a8ac3b rebased | yes |
| .101 | 10-01 | "BASE WALL 4.43s; phases ast 996ms, sublang 1021ms, load 1422ms, admit 1132ms, analyze 621ms, lower 679ms, keep 160ms, resolve 227ms, bodies 276ms, sigs 24ms" | quiet Sprite, `./avra check --time packages/cli` after one-line fmt.av edit | perf101 base | yes |
| .101 | 10-01 | "refsfresh 3ms, refsstand 118ms, refsrestore 414ms, refssettle 1ms -> refs 538ms"; "refs 650ms vs 662ms base, i.e. noise"; "Ceiling of whole refs path is 0.54s" | instrumented refs() | perf101 | yes |
| .101 | 10-01 | "load=1400-1450ms = h_iface … 1400-1440ms"; "li_meet 626ms (rw_okey 519ms = key_parts_cached…)"; "li_complete 601ms -> ~25ms; load 1420 -> ~760ms across 3 consecutive warm runs" | load_interface breakdown | perf101-loadadmit | yes |
| .101 | 10-01 | "BASE WALL 4.72s / load 1324ms; FIX WALL 4.07s / load 796ms => wall -0.65s (-14%), load -528ms"; "181 builds, 66 held, 2 failed" | same-session A/B on avra-sq-ffi; cache_attacks | 38f9b94 | yes |
| .101 | 10-01 | "base 2 failures, slice-2 3"; "load 1019ms -> 3824ms"; "cache_attacks regress to 15 failures"; "sabotage run correctly FAILS 5 cli cache tests" | slice-2 recovery | 9aabcb1 | yes |
| .101 | 10-01 | "48 parse_program events = packages/cli/src/commands' 24 files x2"; "ast 703ms + sublang 735ms"; "sublang 735->182ms"; "instunitHeld 20->0"; "ast 325ms + sublang 354ms of 2.3s"; "re-parses all 25 commands files + main + cli" | QTRACE, warm one-line fmt.av edit (avra-comptime) | WIP 8ac19eb | yes (note 24 vs 25 files) |
| .101 | 10-02 | "PARSES 48->6"; "ast 799->208ms, sublang 410->161ms, load 6415->708ms"; "181 builds/66 held/2 failed" | warm one-line fmt.av edit | dacb95f on fdb68e3, PR #182 | yes |
| .101.1 | 09-29 | "15.5s -> 1s" | keep phase | 9aa321c | title claim |
| .101.2 | 09-29 | "23.8 -> 13.6s" | parse | 3efa6fa | title claim |
| .101.4 | 09-29 | "check -10%" | idiom rules | 6a24fb4 d4506c8 9f9fbed | title claim |
| .101.5 | 09-29 | "held 229 -> 712 after a body edit" | warm recheck | 360f790 84f9f82 ceeea19 | title claim |
| .101.8 | 09-29 | "13.5s" | borrow_outlives scan per managed load | c23ab5f | title claim |
| .101.11 | 10-02 | "70 view_parts calls … 0 of 70 had any view cell settled"; "witness taken 70/70"; "wall base ~3.90s vs branch ~3.78s (~3%), one-shot load 2231->1667ms"; earlier "extend = sound but 3.7x slower" | warm one-line fmt.av edit, interleaved same-Sprite A/B | unlanded branch | yes |
| .101.12 | 10-02 | "view_parts/reach (record.av) is 451ms of a warm 'check packages/cli' (70 modules; @std.avrac.compiler alone 127ms / 60 deps)" | warm check | main (warm4) | yes |
| .102 | 09-30 | "119/119 tests passed" | cli suite | 94f738f | yes |
| .104 | 09-29 | "Census cold check-cli -3.6% instr." | generated-surface fix | 502a455 | yes |
| .105 | 09-29 | "store +16.2% on a cold check of packages/cli (15.79 -> 18.35 MB; keep and RSS flat)" | N6 S3 forms duplicate | - | yes |
| .105 | 09-29 | "Store 25.10 -> 22.24 MB (-11.4%) on cold check packages/cli, keep/RSS flat" | after fix | 3ccf761 | yes |
| .106 | 09-29 | "16 value pins, 2 witnessed red; cache-attacks 94/94"; "held 685/767, ~12.4s both" | lane/cutoff | e5c13ba | yes |
| .106 | 09-29 | "cold -0.034%, warm -0.11% (eager was +2.16/+2.25)" | PERF census | main 3312554 | yes |
| .107 | 09-29 | "cache 12/12, cache-attacks 94 builds 0 failed, std-avrac 7262/7262, cli 115/115" | suites | 70667b9 | yes |
| .108 | 09-29 | "+1.03% instructions / +4.18% footprint against main (cap: +1.0% / +10%)" | lane/written-read speed gate, `check packages/cli` | - | yes; "Not yet isolated as an exact percentage on its own" |
| .109 | 09-29 | "35 'Reference rows' mismatches"; "16612->19069 held decls, 719->765 files"; "held=165 fresh=0" / "held=111" / "held=20"; after: "35 -> 0 mismatches (16630 held decls, 720 files)" | `avra check packages/std-avrac --verify-held` from clean cache | 14764b0 | yes |
| .110 | 09-29 | "Baseline 187->99, none added; all 88 removals verified licensed." | idioms baseline | main 4249cfd | yes |
| .112 | 09-29 | "disk fell to ~750 MB"; "removed 22 worktrees by hand"; "7 were found" | disk | - | yes |
| .113 | 09-30 | "std-avrac 7344/7344" | suite | b822f6a | yes |
| .114 | 09-30 | "4059 MB, 4059 MB, 4085 MB, and 7016 MB" reported vs "real peak of 689 MB"; "6-10x overreport"; after "707MB peak, status 0" | `build/avra build packages/cli` under watch.sh vs memcap.sh | 6f4f02a | yes |
| .119 | 09-30 | "held 648/790 (floor 785), now 787/790"; "5 of 12 packages were admitted" | land.sh warm_gate_step | d29f413 | yes (local macOS) |
| .119 | 09-30 | "was 581.8G (+4.43%), now 562.9G, +0.43% against 740ddae's baseline of 560.5G. One run" | speed_gate_step | d29f413 | yes; median-of-3 "NOT VERIFIED" |
| .119 | 09-30 | "cache_attacks 123 builds, 0 failed"; "std-avrac suite: 7454/7454 and 186 programs proved"; "13/13 plus 1 program proved" (std-https) | pins | d29f413 | yes |
| .119 | 10-01 | "cold build of packages/cli was +1.1%. It is now +0.53% (490.2G vs 492.8G, two runs each, local macOS)"; "cli 141/141 and std-avrac 7606/7606"; "cache_attacks: 127 builds, 0 failed"; "held 815/818" | receipt 2 | 87a5662 on e2793f2 | yes |
| .119 | 10-01 | "133 builds, 0 failed" (fixed); "3 of 133 failed" on origin/main 755a1fc; with two aimed_file lines reverted "exactly the 4 .125 pins fail" | cache_attacks | PR #90 / #54 / #93 | yes |
| .120 | 09-30 | "9.4M retains vs ~431M on macOS for the same check"; "54s build, no census symbols" | Sprite census served stale store | main 5c08d15 | yes |
| .73 | 10-01 | "The before/after census of check-cli was not re-taken on the landed version." | — | #70 | NOT MEASURED (ticket says so) |

No per-row / per-edge memory figures and no witness-pack byte sizes appear in this file. `.avra-cache` sizes: only "74MB" (.66) and store "15.79 -> 18.35 MB", "25.10 -> 22.24 MB" (.105).


### Appendix B / slice 57_p4

| ticket | date | value (exact quote) | what/command | commit/base | MEASURED-by-ticket |
|---|---|---|---|---|---|
| .122 | 2026-09-30 | "watch: peak 4031 MB, status 137" twice | `make avra` via shim `watch.sh 4000` | main 5c08d15 + lane/m5-decl 64c0e09 | MEASURED |
| .122 | 2026-09-30 | "peaked at 1.14 GB under memcap, with AVRA_MEM_STATS at 1.19 GB live" | same build run directly | same | MEASURED |
| .123 | 2026-09-30 | "Cold link takes 21 objects; warm link takes only 13" ; cold "101/101 tests pass" | packages/std-mcp link | compiler 441d58e, packages from a0a92df | MEASURED |
| .124 | 2026-09-30 | "holds 392-399/401, yet 'lower' takes ~31 s and ~33 s sits outside every named phase. The warm budget is 3 s." | check packages/cli after one-line body edit, Sprite | perf/reach-chain | MEASURED |
| .124/.131 | 2026-09-30 | "FAR 8 native vs 71 eval" ; "3 failures" | cache_attacks | perf/verdict124 c0ba862 | MEASURED |
| .124/.131 | 2026-09-30 | "113 builds / 41 under a hold / 0 failed" | cache_attacks, Sprite avra-phase-c | main 441d58e | MEASURED |
| .125 | 2026-09-30 | "119 steps with 1 fail" | full cache_attacks, local | 0f3706e | MEASURED |
| .125 | 2026-10-01 | "cache_attacks (133 builds) … 0 failed" ; reverted: "4 failed" ; "0 of 133 failing" on main after #54 | cache_attacks | PR #90 on main c6120b0; main after #54 | MEASURED |
| .125 | 2026-10-01 | "the binary prints 4000 (self.v*1000)" | rt harness end-to-end | final tree | MEASURED |
| .126 | 2026-09-30 | "report says 401, examined 8" | warm `check --baseline tools/idioms.baseline` | - | MEASURED |
| .126 | 2026-09-30 | "cold/warm/hit all 67 sites, no diff" | fix/warm-recheck | 97a9dc2 | MEASURED |
| .126 | 2026-10-01 | "cli cold/warm/hit: 57/53/53 on main -> 57/57/57" | findings count | GitHub main / PR #61 | MEASURED |
| .128 | 2026-10-01 | "Retains 1485997593 = 1485997593, releases 1953950833 =, list reads 6608756404 =, list writes 1668192359 =. Boxes differ by 16; base run-to-run noise is 17. Wall time 91.2 s vs 91.0 s." | census check packages/cli, Sprite | identical tree, fast path off vs on | MEASURED |
| .128 | 2026-10-01 | "Call sites … 58 -> 7" ; test "6/6" ; "12 dividends" ; SIGFPE "status 136" | avra_int_div/mod call sites in compiler binary | PR #66 | MEASURED |
| .129 | 2026-09-30 | "1.5M instructions per new dep" | kbench | stamp56 base bc2d64a | MEASURED |
| .129 | 2026-10-01 | "0 clones … read 1000 after 1000 pushes" (old) ; "3 clones at N=1000 and N=3000" (main) | AVRA_ALIAS_LOG native | bc2d64a vs main | MEASURED |
| .130 | 2026-09-30 | "~65 instructions per write" | Cell.set_at | stamp56 | MEASURED |
| .130 | 2026-10-01 | "retains 1,100,001 -> 1; releases 1,300,008 -> 200,008; live 0 at exit both" | bench 1.1M set_at (1M ints + 100k strings) | PR #81 base e2793f2 | MEASURED |
| .130 | 2026-10-01 | "retains 1,048,800,891 -> 973,899,734 (-7.1%); releases 1,381,869,993 -> 1,281,432,455 (-7.3%); boxes 342,885,381 -> 317,350,641 (-7.4%); list reads 5.048G -> 4.851G" | census check packages/cli | main e2793f2 source | MEASURED |
| .130 | 2026-10-01 | "Wall 3 pairs: 36.46/36.55, 37.25/36.81, 39.59/38.85 s (flat to -1%)" | check packages/cli | same | MEASURED |
| .130 | 2026-10-01 | "21.42G -> 18.97G instr" ; "un-memoized recursion was ~17% of check std-relation" | callgrind check std-relation | pre-thaw-fix | MEASURED |
| .132 | 2026-09-30 | "keep newest 4" | store sweep policy | - | stated, not measured |
| .133 | 2026-10-01 | "Rule test 18/18" | bypass_outside_bracket | PR #38 9cee431 | MEASURED |
| .134 | 2026-09-30 | "Cold run: 119/119. WARM second run: 118/119" ; "the landing tree's 98 warm-only defects" | `build/avra test packages/cli` twice | main bc2d64a | MEASURED |
| .135 | 2026-09-30 / 10-01 | "cache-attacks' cold-vs-held output diff fail 2/117" ; "watch: peak 0 MB, status 0" ; "passed — 4 fixtures" | watch.sh on Sprite | PR #156 | MEASURED (full cache-attacks run NOT finished) |
| .136 | 2026-09-30 | "warm one-line receipt.av edit 274.6B -> 25.3B instructions (-90.8%), 20.9 s -> 2.33 s; cold 209.6B -> 205.6B (-1.9%); peak flat" ; "A warm check lowered 4x slower than cold" | census check packages/cli, same input | perf/held-path e203c0d (main 96fa525) | MEASURED |
| .137 | 2026-09-30 | ".81+.9.2 alone +0.95% instructions (borderline pass); grouped with two docs branches in a batch, +1.19% (median of 3, FAIL)" | Mac /usr/bin/time -l, cold build --time packages/cli, 3 runs | 1c20088 | MEASURED |
| .137 | 2026-10-01 | "single-digit total occurrences across ~5600+ tree lines in BOTH samples" ; "Decls.decl 233→379 samples" (S2's +2%) | AVRA_SAMPLE=12 cold packages/cli | armed vs quiet_hooks | MEASURED |
| .139 | 2026-10-01 | "7537/7539, only pre-existing #45 failures" | std-avrac suite | PR #73 | MEASURED |
| .140 | 2026-09-30 | "5/5 probe" ; "consumes_test 7/14 at every commit back to 441d58e" | consumed_seat | - | MEASURED |
| .141 | 2026-09-30 | "a warm fmt.av edit is 5.7 s with lower at 1.5 s, so this saves at most ~1.4 s" ; title "6 of 8 re-read files exist only for the settlement" | warm check after fmt.av edit | after held-path + reach-chain | MEASURED (saving ESTIMATED) |
| .142 | 2026-10-01 | "Four trains failed" (runs 36798270145, 36797879353, 36797878295, 36797848950) | merge-queue trains | - | MEASURED |
| .144 | 2026-10-01 | "lock free 2/2, held 0/2" ; "60 s child timeout" ; "20 held-lock loops x 2 files = 40/40 green" | canon_provider under held AVRA_BUILD_LOCK | PR #84 | MEASURED |
| .145 | 2026-10-01 | "7 thens" ; "all 5 Sprite jobs exit 0 (fmt, 3 suite groups over 42 packages, idioms baseline)" ; std-relation "has 3" .refuses tests | work test | red main 51d36f4, green c5da450 | MEASURED |
| .148 | 2026-10-01 | "26 families" (description) ; "28 arms (workspace.av:468-526)" ; "~16 arms are dense" ; "the 6 relations" ; "10 variant names are already compiler declarations" ; final "30 markers … 30/30" | Family enum census | workspace.av / origin/main fa48f22 | counted |
| .150 | 2026-10-01 | "make cache-attacks 167 builds 63 held 0 failed" | cache-attacks | PR #109 | MEASURED |
| .150 | 2026-10-01 | "base 239393249 retains / 89386723 boxes, walk 239388751 / 89384451 — flat" | census check packages/std-http (identical input) | PR #109 | MEASURED |
| .151 | 2026-10-01 | "red-before (3/5 …) and green-after (5/5)" ; "a 40-edit sweep" | kernel_relation_hooks_test.av | PR #111 | MEASURED |
| .153 | 2026-10-01 | "RED on main 3f073ba: 7/11 failed" → "0/11" ; "store before cache 61 files listing cksum 4284840043, after cache 61 / 4284840043 (identical), after check 85 / 113185496" ; "its text 29.76… -> 39.18…" | cache_attacks cw section | main 3f073ba vs cache-readonly 00811b8 | MEASURED |
| .153 | 2026-10-01 | "181 builds, 66 under a hold, 0 failed; link-cache-attack 0 failed" ; "cli cache_test +3 cases … 23/23" ; "replacing 9 … copies" | make cache-attacks | PR #113 | MEASURED |
| .154 | 2026-10-01 | "RED on origin/main … 2/9 passed" → "9/9; kernel_test 31/31 (3 new abandon cases), family_gap 1/1, cache_walk 6/6, names_family 4/4, syntax_family 4/4" ; "std-avrac 7619/7619" | decl_grain_test | main 9151d48 / dd3e843 | MEASURED |
| .154 | 2026-10-01 | "174 builds, 66 under a hold, 0 failed; link 13, 0 failed" | make cache-attacks | PR #114 | MEASURED |
| .154 | 2026-10-01 | "main: 1,001,145,826 retains 1,318,485,558 releases 4,659,367,085 list reads 1,330,641,012 list writes 327,756,325 boxes / branch: 938,501,083 retains 1,238,360,270 releases 4,321,342,111 list reads 1,278,952,826 list writes 309,927,974 boxes = -6.3% retains, -6.1% releases, -7.3% list reads, -3.9% list writes, -5.4% boxes" | census check packages/cli, identical input, Sprite | main vs typed-decl-grain | MEASURED |
| .154 | 2026-10-01 | "No warm in-process re-check exists to time" | - | - | not measurable |
| .155 | 2026-10-02 | "all 5 groups exit 0" ; "PR #173 queued at position 5" | work test | a943d03 on origin/main 2b051df3 | MEASURED |
| .158 | 2026-10-01 | "bounded each run at 8-60 s wall time" ; "hang_bound() (10 min)" ; "4-core CI runner" | cli tests | - | stated |
| .159 | 2026-10-01 | "ordinals 10, 2, 9 came out ten, two, nine" ; "declared 10/2/9 AND 2/9/10 both collect 2,9,10" | collect order probes | db159-collect @ 4385ae7 / 53a73e8 | MEASURED |
| .160 | 2026-10-01 | "Decls.face: 5B instructions per warm edit" | PERF's #124 | - | MEASURED (by PERF) |
| .161 | 2026-10-01 | "answered \"1 0 2\"" ; controls "201" ; "ORDER_NOMARK count 0" ; witness "(21)" | collect enum rank probe | collect148 @ 264d55d / fab8da0 | MEASURED |
| .162 | 2026-10-01 | "bootstrap/seed.ll 557,782 lines (was 547,374)" | make seed, Sprite avra-reuse | PR #159 | MEASURED |
| .163 | 2026-10-05 | "cold, nothing held (held 0/462) peak 2168 and 2177 MB" | `build/avra build --time packages/cli` under tools/watch.sh, ui-dev | not named | MEASURED |
| .163 | 2026-10-05 | "one cli file edited (held 446/456) peak 637 MB" | same | - | MEASURED |
| .163 | 2026-10-05 | "a quarter read again (held 335/462) peak 3442 MB" ; "(held 349/456) peak 3371 MB" ; "killed at 4227 MB by the 4000 MB watchdog" | same, after edit to commands/shared.av ("about 115 files were read again while about 340 were held") | - | MEASURED |
| .163 | 2026-10-05 | "ast 4781, sublang 511, resolve 644, sigs 202, bodies 1857, load 1128, admit 4290, analyze 2871, lower 2132, keep 926, emit 3345, link 562 ms. A cold run has load 0 and admit 0." | --time for the 3442 MB run | - | MEASURED |
| .163 | 2026-10-05 | "http adds 205 MB cold (1972 -> 2177)" ; "peaks 1.6 times a cold build" | cold build with/without @std/http | - | MEASURED |
| .164 | 2026-10-05 | fix "about 60" lines | - | wants-modules after 8ed3b35 | stated |
| .165 | 2026-10-06 | "make cache-attacks: 2 of 186 fail" ; "fmt-lossless: 5 files differ" ; "codecs: 2 unregistered pairs (reach_wire, use_kind_word)" | keepers on ui-own-state Sprite, near-main binary | base 91a317d | MEASURED by ui-own-state, "not re-run by the lead" |

No per-row/per-edge memory figure, witness size, or .avra-cache byte size appears in this file (only store file counts 61/85 in .153).


### Appendix B / slice other_p1

| ticket | date | value (exact quote) | what/command | commit/base |
|---|---|---|---|---|
| 2y5c.11 | 2026-09-23 | "check cold 9.29s -> 9.29s, build cold 21.75s -> 20.96s, peak 413 -> 412 MB, clones +0.14%" | "Profile (packages/cli, CPU median)" | main c9c0ac1; "Fixed point 8d048e3278d9; gate e759d05911dd" |
| 2y5c.11 | 2026-09-23 | "F2047 std-avrac 165 -> 4, cli 60 -> 1" | deduped by file:line, `./build/avra check packages/cli` | same |
| 2y5c.11 | 2026-09-22 | "30 sites remain on packages/cli … of which 24 are this task's: 23 trace into core/types.av's TypeRegistry … 1 more … NodeStore" | F2047 census | std/f2047-residue (9ee91d7) |
| 2y5c.11 | 2026-09-23 | "std-avrac 6344/6344, 140 programs; gate green" | suite | std/core-cells |
| 1.28.8 | 2026-09-30 | (no number) "a deliberately broken lookup_close stayed green, and after restoring the good C the suite stayed red" | `build/avra test packages/std-net` after C edit | lane/http-client base 7b7cab9 |
| 1.35 | 2026-09-30 | "the old C behaviour (13/13 with the refusal removed); clearing .avra-cache made the same run fail as it must (12/13)" | `build/avra test` alpn_test.av after std_tls.c edit | c50791a..h2fix |
| 9.14 | 2026-09-15 | "13 `new_memo<` lines"; "four entry rituals"; "the twelve families in language/workspace.av" | trigger audit | main eec73f8 |
| 9.2 | 2026-09-15 | commands dir lists "build check emit expand explain grammar ir mod new phase run seats shared staged test — no watch, no lsp, no serve" | `ls packages/cli/src/commands/` | main eec73f8 |
| 11.120 | 2026-09-21 | "~3,000 lines of the cache layer" | beauty audit scope | cache/cas |
| 11.120 | 2026-09-21 | "`let _ = store.keep(…)` appears ~391 times tree-wide (164 in src)" | count | — |
| 11.120 | 2026-09-21 | "Twelve hand-rolled push loops" (settlement_wire.av:111-121, 128-136, 262-272, 278-288) | count | — |
| 11.120 | 2026-09-21 | "written longhand 16 times: compiler/modules.av:24,52,222; compiler/record.av:49,142,154,609,619" | get/compute/set ritual | — |
| 11.120 | 2026-09-21 | "the same 19 variants three times" (Family, compiler/workspace.av) | count | — |
| 11.120 | 2026-09-21 | "raw at 42 sites" (compiler/suite_entry.av IfStart/ArmEnd/RegionEnd) | count | — |
| 11.120 | 2026-09-21 | "about half of all one-parameter lambdas (~69 of 135)" | count | — |
| 11.120 | 2026-09-21 | "Eight throwaway `let none: List<DeclId> = []` pins: features/decls_mint.av:19-25, 36-38, 303, 325-332" | count | — |


### Appendix B / slice other_p2

| ticket | date | value (exact quote) | what/command | commit/base |
|---|---|---|---|---|
| .23 | 2026-09-21 | "build no-op 0.08 s; one body edit 0.38-0.42 s (bar 0.5); a generic home's edit ~1.4 s; cold ~13 s" | cli, "load 10-14" | cache/cas 1372a35 |
| .23 | 2026-09-21 | "check no-op 0.08-0.15 s; one edit 0.28-0.36 s" | `check cli --time` readings (per 09-22 comment) | cache/cas 1372a35 |
| .23 | 2026-09-21 | "test std-json warm 0.25 s. test std-avrac cold 38 s, warm 13 s (all of it RUNNING binaries), one edit 16.7 s with 27 of 28 suites served from the store" | avra test | cache/cas 1372a35 |
| .23 | 2026-09-21 | "a get-then-set cloned the whole map per insert — a third of the compiler's samples" | memory pass fix 7cd2db3 | cache/cas |
| .23 | 2026-09-21 | "62 builds, 27 under a hold" | cache-attack step | f2f955d |
| .23 | 2026-09-22 | "hold 287/289, cache-attacks 62/27/0" | per close-out slice | 05ad4e5 |
| .23 | 2026-09-22 | "main fast-forwarded to 86d7009 (cache/cas, 236 commits)"; "cold build 13 s, warm hit" | merge | main 86d7009 |
| .23 | 2026-09-21 | "434 sites + 82 alias folds" | idioms I51-I55 sweep | seed 4b346b3 |
| .27 | 2026-09-22 | "rep1 'built' at 1.3 s, rep2 'cache hit' at 0.05 s, SAME nominal command" | repeated identical edit | 9ba6203 / land/c2 |
| .27 | 2026-09-22 | "build cli one-edit held 275/289 on BOTH" | build cli | 9ba6203 vs land/c2 |
| .27 | 2026-09-22 | "test std-avrac one-edit held 497/534 (main) vs 499/536 (land/c2) … ratio unchanged at 93.1%" | test std-avrac | same |
| .27 | 2026-09-22 | "check cli one-edit, delta 0.08 s inside a 0.37 s spread"; "memlevel 29-36" | noise | same |
| .27 | 2026-09-22 | "check cli --time cold: held 0/289. … right after build has warmed the store: held 288/289, read: src/main.av … build cli --time: cold held 0/289; warm, cache hit, no count; one edit held 287/289" | check/build cli --time | ce93b0a |
| .25.3 | 2026-09-22 | "`./avra test packages/std-avrac` 5341/5341 … cache-attacks unchanged (62 builds, 27 under hold, 0 failed)" | slice protocol | lane/formatter 924fceb |
| .25.69 | 2026-09-26 | "--check 18.6s cold, --write 40s, every per-file launch 1.3s" | tree-wide fmt (before) | not named |
| .25.20 | 2026-09-25 | "The immediate re-run passed 6798/6798." | avra test std-avrac after stale-object link failure | after merging main, .25.16 landing |
| .34.2 | 2026-09-30 | "pre-fix 5/7 steps failed, post-fix 0/7" | tools/link_cache_attack.sh | 05b679d |
| .34.2 | 2026-09-25 | "gen2..gen5 are byte-identical and all 338 per-unit pre-pass modules md5-match across runs; without clearing, a later generation's __text differed in exactly three functions" | make avra generations, cache moved aside vs not | R15a (layout agent) |
| .34.30.6 | 2026-09-26 | "cache-attacks 65/27/0" | make cache-attacks | main 4e98526 |
| .34.30.2 | 2026-09-26 | "+23% on check so off by default" | AVRA_SOUND_CHECK=1 | main 4e98526 |
| .11.300 | 2026-10-05 | "killed by the watchdog at 4012-4046 MB (status 137)" with tree-root `.avra-cache`; "same source with the cache moved aside built at once" | `make avra` (`./avra build packages/cli`) | worktree avra-ui-own-state |
| .46 | 2026-09-25 | "a 400k-string brute force finding a real pair on the first attempt — birthday bound ~32k tries" | 30-bit fp_mix collision | core/fp.av |
| .44.6 | 2026-09-26 | "16 rules 103s->2s" | memory-pass fix enabling compile-time runs | d23eccb on main |
| .44.6.1 | 2026-09-26 | "20-50M evaluator steps (~5s); default budget is 600k" | std-sql grammar at compile time | — |
| .44.6.3 | 2026-09-26 | "~300x slower than native" | evaluator parsing @grammar_rule text | — |
| .44 / .44.5 | 2026-09-25 | "4.2x slower than necessary (137ms vs 33ms per 20k rows)" | @model insert vs prepared loop | lane/orm |
| .44 | 2026-09-25 | "20ms/20k inserts vs the raw Stmt API … at 10ms/20k" | Db.run with stmt cache vs raw | lane/stmt-cache |
| .44 | 2026-09-25 | "36/36 across three suites (db_test 6, db_adversarial_test 26, db_collision_test 4)" | std-db tests | lane/orm |
| .44.1 | 2026-09-25 | "full std-avrac suite 6685/6685" | landing check | main (no sha) |
| .34.36 | 2026-09-30 | "pipelined plaintext Avra 1.58-2.13 us CPU/req vs floor 0.57-0.64 (3.2x)" | http bench (irrelevant to db) | cb8d88e |


### Appendix B / slice other_p3

| ticket | date | value (quote) | what/command | commit/base |
|---|---|---|---|---|
| .76 | 2026-10-05 | "cold 1972 / 2177 (2168, 2183 on repeats); one cli file edited 339 / 637" PEAK MB without/with dev server | cli build under tools/watch.sh, `.avra-cache` parked for cold | branch ui-dev |
| .76 | 2026-10-05 | "importing @std/http costs the compiler's cold build +205 MB and 30 files" | same | ui-dev |
| .76 | 2026-10-05 | "1132 @std.http symbols … 74 of @std/json, 77 of @std/url, 134 of @std/net"; standalone program "411 http symbols" | `nm` on built compiler | ui-dev |
| .76 | 2026-10-05 | "process peak 2183 MB": "the runtime's own heap peaks 1780 MB and 1828 MB is still live at exit; list boxes 897 MB, list buffers 749 MB, strings 116 MB" | AVRA_MEM_STATS=1, cold, with server | ui-dev |
| .76 | 2026-10-05 | "query.Kernel.newly_read 363 MB in 5.1 M boxes, all live; then two core.side_table sites 254 MB and 151 MB" | atos sites | ui-dev |
| .76 | 2026-10-05 | "a PARTLY-HELD rebuild (about 115 of 460 files read again …) peaked 3371, 3442, 3518 MB and was once killed at 4227 — 1.6x a cold build. avra-8sb5.57.163." | edit to a file every command reads | ui-dev |
| .76 | 2026-10-05 | "took the compiler's own build from 2.4 GB past the 4 GB cap"; "128 exports, 8 needed" (pre PR #275 wasm) | description | — |
| .78 | 2026-10-05 | file run "134/134 pass"; then dir run "traps 'memory ceiling exceeded: 5000 MB' … right after '199 rule examples proved'" | `build/avra test …/fns/tests/fns_test.av` then `AVRA_MEM_CEILING_MB=5000 AVRA_MEM_STATS=1 build/avra test …/features/fns` | 5e05b3d, unmodified, scratch copy |
| .78 | 2026-10-05 | "COLD peaks at 2.2-2.9 GB and passes (723/723), and warm after a directory run peaks at 552 MB" | same dir | 5e05b3d |
| .78 | 2026-10-05 | "list boxes (791 MB at a 1.5 GB ceiling) and list buffers, the top site inside Kernel.newly_read" | AVRA_MEM_STATS | 5e05b3d |
| .78 | 2026-10-05 | "OOM-killed twice ('Killed', under 350 MB free); the same source from a parked .avra-cache built in 169 s" | warm `make avra` on Sprite avra-dev (8 GB) | wants-modules |
| .67 | 2026-10-05 | "build_mode_test.av 15/15 (7 fail unfixed); tools/wasm-cache-attacks.sh 15/15 (7 fail on parent's compiler)" | proof suite | 0bdcb6d |
| .73 | 2026-10-05 | "n=4000 peaks 281 MB in 0.27 s, n=8000 peaks 867 MB in 0.99 s; the native binary … peaks 2 MB" | `/usr/bin/time -l build/avra run` | ui-arch 2d3bc5c |
| .73 | 2026-10-05 | "`mut t: Table` seat (500/1000/2000/4000 entries -> 31/42/86/282 MB)"; "`Cell<Map>.put` (time 54/179/700/2517 ms at 2k/4k/8k/16k)"; "Cell<List>.push … 16,000 pushes in 70 ms" | evaluator | 2d3bc5c |
| .73 | 2026-10-05 | "took the UI diff's interned id table past 6 GB at 2,000 siblings" | — | — |
| .63.11 | 2026-09-30 | "max RSS 2.2 GB (10000: 657 MB, 40000: 5.7 GB)"; native "0 MB peak" | `build/avra run` repeat("[", 20000) | — |
| .77 | 2026-10-05 | "137-269 cached compilers and 68-188 trees per Sprite, 24-63 GB of overlay" | Sprite disk | — |
| .77 | 2026-10-05 | "`build/avra build packages/cli` at 6.9 GB RSS, owner pid dead, run 21 h old" | orphan on avra-phase-d | — |
| .77 | 2026-10-05 | "fresh Sprite to a passed suite 246-271 s (compiler build ~190 s)"; "202 s seeded from main"; "70 s when the tree's compiler sources are that run's" | work test | sprites-fix f22087f / 49bfbef |
| .77 | 2026-10-05 | "Warm rebuild after a one-comment edit: 80-147 s (one make avra is ~70 s on a Sprite, ~35 s on the Mac…)" | — | 49bfbef |
| .77 | 2026-10-05 | "main's checks-run artifact avra-compiler (10.6 MB…)" | — | — |
| .65.1.2 | 2026-10-01 | "C9 0.99x, C10n/C10f linear (0.68x/0.62x C9i per key) … C5 sorts 30-560x … C7 36x, C8m map-of-lists 56x, C12 comprehension spelling linear (217000x)"; "Baseline 4/19 met" | make bench-collections, Sprite avra-comptime (load 2.8) | d249615 |
| .65.3.2 | 2026-10-01 | "std-avrac 7628/7628, 209 programs" | affected suite | PR #161 |
| .65.3.1 | 2026-10-01 | "scoped lower_test 64/64 with the pipeline impl AND 64/64 with origin/main's old impl" | goldens | rebase over 61a408c |
| .65.3.13.1 | 2026-10-04 | "blow >2.5 GB (CI hit 6000 MB…)" | build/run char_walk | stringlenses-lens |
| avra-knya | 2026-09-22 | "suspect store is saved at ../avra-fibers/build/avra-cache-suspect (13 MB)" | — | lane/fibers |
| avra-yp6n | 2026-09-17 | "0.079s miss -> 0.019s no-op"; delete .bin "REBUILDS (0.088s)"; fix "~45 lines / 4 files" | lone-file build | — |
| avra-egav | 2026-09-15 | "rc: 17345771 retains, 20769095 releases, 3428228 reclaims / rc: 13315704 list reads, 14387248 list writes / once: 1808 reads, 1811 pointer compares" (BEFORE only) | `make census CMD="check packages/std-toml"` | avra-lane-comptime ee59901 |
| avra-b878 | 2026-09-15 | gate killed in traps "peak 823 MB"; traps+witness alone "peak 77 MB"; suites "2890/2890, 434/434, 413/413, 108/108, 59/59, 51/51, 41/41, 25/25, 5/5" | make gate | — |
| avra-9xt5 | 2026-09-08 | "1984 tests, 414 goldens, 78 programs eval == native == expected" | gate in clean worktree | main 812495c |


## Appendix C — every defect row


### Appendix C / slice 57_p1

| ticket | symptom | root cause (as stated) | status |
|---|---|---|---|
| 57 | "bare Db field on Decls + insert trapping 'index 21 of length 0'" (Db-fork) | "the receivers pass typing a type-name-rooted place as nothing, marking every argument of a call on such a local as written, so Decls.admit read as a writer and items opened a held Decls" | fixed at 8120973 (fix/receiver-typename), `type_name_type` |
| 57.3.6 | `fn f(${x})` with no written type traps "'a span reaches outside its own text'" | "Param.span rides on the node ... and Rebuilder copies it verbatim" | Part 1 landed 5725492 (Origin.Spanned: refuses cleanly) |
| 57.3 / 57.4 | a @derive's generated type silently dropped; "silent F3000 at the use site" | "a mute Declares door" | .3.4 closed, no sha |
| 57.3.8 | WRAP over a method: type loses the method; `P.raised_s(5)` refuses "'`P` is a record, not an enum'" | wrapper repointed at a TOP-LEVEL fn | ladder lane/wrap-bridge 64ef4d2 + lane/wrap-method3 9480ace QUEUED (landing not confirmed in text) |
| 57.3.8 | any Declares annotation on an impl method mute under check/run | "has_declares/has_marks (compiler/workspace.av) scanned only a file's top-level statements" | "fixed on lane/wrap2 via declaring_stmts" |
| 57.3.8 | method wrapper cannot name its owner ("`P` is not defined"); `self` refuses "this is not a method"; spurious "writes its receiver" warning | template names resolve in template file; meta Fn had no owner; wrapper walked STANDALONE | lane/wrap-method2 794c763 (Fn.owner appended, wrappers walked as impl members) |
| 57.3.8 | DOCS port: `avra check`/`run` segfault "(SIGSEGV, exit 139)" at `is_any_root` (compiler/rules_table.av:124) | suspected (NOT proven): mid-expansion `declare_method` on unsized `self.methods` | reverted, never landed; superseded by wrap-method2 ("registered at signing (no mid-expansion declare_method)") |
| 57.3.8 | candidate compiler building MAIN refuses "'Fn declares nothing where the crossing reads owner' (annotation.meta)" | meta shape grew + read in one landing | bridge `MetaShape.recent` (lane/wrap-bridge 64ef4d2) |
| 57.4.6 | imported @query whose body changes without its interface moving "is read back stale" | "the key is the CALLING file's KeyParts" | OPEN deadline; "Safe only while nothing in the compiler arms a durable Db" |
| 57.4.6 | dependency recording hooks exist "but NOTHING ARMS THEM ... reuse is write-count-coarse" | no owner-armed Db | addressed by .4.7 (PR #72) |
| 57.4.7 | gen-2 over the cli segfaults after arming | "the late-write BUMP is the trigger"; endless reuse cycle over families 1/2/4 arg 209 | Kernel.ask in-progress verify mark LANDED bc2d64a (lane/kernel-verify-mark 0be202b) |
| 57.4.7 | late write: module/file minted inside a query after the relation was read | std/package module first minted during resolve (`std_admitted` via `reaches`) | `admit_used` at admit; `moved_in` refuses late write (PR #72) |
| 57.4.7 | warm rebuild: held file's sibling minted late -> refused | "Workspace.namespace(m) (Family.Namespace): it lists the DIRECTORY module from disk (module_files) and file_id's every file"; also `interface_decls`, `record_of` | `met_files(m)` / `read_here(path)`; settle_holds mints held modules (dfcf9fa) — PR #72 |
| 57.4.7 | cli build "6.9 GB/30 min" | load_imports minted non-held files that admit_all then parsed | fix DROPPED |
| 57.4.7 | sprite build blocker | "SideRows.opened registers through Db.registered (was db.hooks.family, dead once hooks became Cell<Hooks>)" | e46196c |
| 57.4.7 | `bucket_of` indexed `indexes[6]` of a 6-index relation | "Rows.late_check numbered i across before.concat(keys) (12 inner lists)"; "Main never ran late_check (compiler Db revision -1)" | f6ef163, witness `refile_indexed` |
| 57.4.7 | three test Hooks literals lacked the new `moved` field | field added | 0bae420 |
| 57.4.9 | `@key handle` + `@unique key`: "`avra: unwrapped an absent value`, exit 2, no location" | two generated members both named `by_key` | "LANDED on main 66f35cd" |
| 57.4.10 | @unique not enforced: second row inserted, by_<f> answers the first | no check | 66f35cd ("insert -> Result<T, InsertRefused>" per .4.6) |
| 57.4.11 | hand-written id in insert literal silently discarded | store mints id | 66f35cd (which remedy not stated) |
| 57.4.12 | insert into closed Db resurrects it; `set_hashes().length` 2 for ONE relation | "Stores.reach finds the slot null after close, reopens it and calls db.joined again" | 66f35cd |
| 57.4.13 | no remove/replace; projection re-run appends duplicates | missing verb | 66f35cd (answer not stated); later named-owner sweep (57.8.2) |
| 57.4.14 | header example `id: CallId` refused `id_not_int`; typed-id/enum/float `kind_not_carried` | docs ahead of derive | 66f35cd; enum/@dense/@local carried per 57.4.17 |
| 57.4.15 | @query in a ROOT package's own files refused `annotation.wrap_missing` (works in a dependency) | not stated | closed 2026-09-29, fix not described |
| 57.4.16 | generated `<T>Key`/`<T>Stored` not reachable cross-package even with `export` | "module export-surface computation (compiler/modules.av's exported_decls, over workspace.av's items()) reads a PRE-EXPANSION snapshot" | partial 8d874c9; real fix = avra-8sb5.57.104 (status not in this file) |
| 57.4.17 | std-relation module header stale | docs | closed, no sha |
| 57.4.18 | lookup gate refuses `.Opt(_)` for every mark | no null-aware bucket | LANDED 1a7df87 (code 541b4e4) |
| 57.6 | CLI "0/715 held after a one-file edit" | ".40 refuses the hold" (older held path) | superseded by later receipts (404/408) |
| 57.6.2 | pack "commit REWRITES the whole file", "no cross-process invalidation", "mmap_slice unused (Unhosted can't box Bytes)", "compaction 2x threshold unmeasured" | by construction | listed OPEN for wiring; wire later deleted (57.4.6) |
| 57.6.3 | "main's compiler held a file whose import target was deleted" (warm exit 0, cold refuses `resolve.no_module`) | "the store keeps leaf's record (keyed by module name), and bytes_key/files_iface answered its stale interface digest" | fixed PR #104 (85f1046): `record_stands`; pin dt |
| 57.6.6 | new declaration refuses the hold: "a property `length` on `<error>` without a row survived typing in ... rules_test.av at expression 155"; 0/408, ~50s | "a collect was written into its module's record as `opaque` — interface.av's record_line chose the shape through `d.kind is .Const`/`is .Impl`/sig==null" | fixed PR #108 (dcaba11): `record_shape`, `Shape.Collect` |
| 57.7 | held_sig_test.av bugs | "(1) active(key) means 'currently open', not 'was recorded' ...; (2) fixed test cache paths reused across runs ...; (3) hardcoded Family.Failures ordinal" | fixed main 899e0ea |
| 57.7 | bypass reads audited (declared_result_hole, qualified_variant_type, constructed_type, callee_of, type-registry reads, "Db.get/insert string-keyed accessors (ws.db.sig via record_cached) skip the Kernel") | reads not through a recording accessor | lint landed (.7.3) over a narrower verb set; 'decls' fence is "a follow-up (waits on M5 S2)" |
| 57.8 | ERRORS chain "held on the speed gate (+1.55% instr, +10.7% footprint from rows_read's record_dep)" | record_dep retain in rows_read | "fix via PERF's .93" (corrected: ERRORS'); chain landed 5cde697 |
| 57.8.2 | re-admitted file kept old rows (readmit_test 6/17 on main) | "std-relation rows are never removed" | fixed PR #101 (d4a9796) |
| 57.9 | `within` shallow scan: nested re-raise missed, "chain understates" | direct-statement scan | fixed 4d533fd |
| 57.9.6 | "Canon's key omits provider block words" (fmt.av:74 canon_key text-only) | block_words read unkeyed | "Landed at e6290f0 on main" |
| 57.9.6 | fixpoint: one-fn edit costs a full cold check ("zero incrementality") | no per-SCC witnesses | OPEN (N5 unbuilt) |
| 57.9.7 | `put_in` with id > next_id(): gen-2 traps "'index 10 is out of bounds (length 1)'" | "pushes the row at next_id then grows only stamps, so rows/hashes/filed stay short" | OPEN (recorded property; attempt reverted) |
| 57.9.7 | `@local @key decl: DeclId` and plain `@key doc_key: string` both make the derive "generate NOTHING" with "NO relation derive diagnostic" | unknown ("the mechanism is not what it looks like") | OPEN — the blocker |
| 57.9.7 | decls.av:409 comment "names a door that is not there" (no `DocFact.get(db, id)` for @side) | @side needs Decls' cell + SideRows | OPEN |
| 57.12 | "silent-exit fix (.29)"; in-process edit not seen = "Memo.input's one-shot read" | - | .29 landed with 0f3da07; one-shot read "recorded on N7" |
| 57.12.4 | DbKind cannot be collected | "blocked on rows_derive.av's enum-variant splice hole" | OPEN as avra-8sb5.57.12.5 |


### Appendix C / slice 57_p2

| ticket | symptom | root cause (as stated) | status |
|---|---|---|---|
| .19 | warm `avra test <file>` after an edit: "index 221 is out of bounds (length 181)" | "Workspace.kept_digest trusted a size/time/inode stamp over the bytes (durable via Stored.Fp)" | fixed 92b24db (cacheprint), landed by lead |
| .20 | annotation with extra args traps "index 1 is out of bounds (length 1)" | no arity refusal at the crossing | fixed main 15a6bb2 (6da700f) |
| .21 | refused receiver still expands; cascaded "`impl f` serves no declared type" | Declares fn ran over a mismatched receiver | fixed main 15a6bb2 |
| .22 | same-named relations in two modules share hash seed + relation_name | stable name was bare `t.name` | fixed main 15573ed |
| .23 | torn .avra-cache entry from interrupted native link read as valid | HYPOTHESIS; "REFUTED against the current durable tier"; "original incident's true cause (if any) is unrecovered" | closed, no change |
| .24 | test-then-check in one tree traps 221/181; also "'Id's flatness was read before a mut seat sealed it'" | "mut_seat_index read held decls' parse via store(d).fn_parts(stmt) — a held module's minted store lacks those stmts; and the index was built once, missing later-minted modules" (NOT compiler identity, NOT the record-view hypothesis as final cause) | fixed main d1ef6d6 via e23e15f; residual .40 |
| .25 | durable rows not keyed by producing compiler; one 'shared' UNNAMED store | "record_key = node_key(Sig,[root, module]) … Scan/Canon keyed by text digest only … Db.durable_key has no compiler print" | fixed cdc0f44, main 2b3e5ac. NB the description lists Db.durable_key but the fix text names only "record/Scan/Canon/program keys" — Db.durable_key NOT stated as fixed |
| .25 (side) | interface.av `minted()` trusts row.root with no bound ("ExprId { index: 99999 }") | no bound check on a held row's root | 5cff9ea REVERTED (da63bf8); bound check (b) left as suggestion — OPEN per text |
| .26 | collect silently misses members in unreached files; doc names hooks that "do not exist (stale doctrine)" | collect only sees files something reached | fixed main d754618 (package scope); closure scope stays reachability by ruling |
| .27 | malformed collect reports unrelated comprehension error | no @expect/@recover on either alternative | fixed main d754618 (3827ca7) |
| .28 | empty collect enum mints a zero-variant enum; refusing it gave silent exit 1 | see .29 | landed main c972222 |
| .29 | test batch exits 1 with no words | "stage.av judged() answered .Red with a bare 1; first_red stops the run at the first red suite binary" | fixed c972222 (prints "STOPPED — …") |
| .30/.31/.56 | stamped kernel hit +~190 instr over unrecorded read | "Cell.get() and a chunked table lookup before comparing"; then "state_stamp's chunk arithmetic, two bound checks … a Cell<List<int>> get retaining a whole row" | .31 landed 86db86c; .56 landed 2e99559 |
| .34 | native: settled cell of a tagged pair starts as stack garbage; "array_get read a RELEASED box" | backend "zeroed only POINTER-typed allocas"; surfaced after d23eccb | fixed cf97209 / 57999f4 |
| .35 | type-argument holes in derive template dropped (`Rows<${t}>`) | likely core/rebuild.av TypeRef copy | closed (25e7137 implied by .42) |
| .36 | dead_parameter false findings on static fns | "seat_base_of … offset a method's params by 1 for a receiver it does not have" | fixed main 8aaf557 |
| .37 | Param carries span on node; `is_pronoun uses span == null as the IDENTITY of the synthesized it seat` | law debt | closed, outcome not stated |
| .38 | fmt refuses blank line between two given blocks | not stated | closed, outcome not stated |
| .39 | two refusals for one mistake (inner @expect hole + expr_stmt END recover) | recover fires on leftover token | fixed main 9c973e5 (18aec91) |
| .40 | hold refused: "`Bad`'s settlement was read before its declaration settled a second time"; "held 0/715" | "note()'s declared_first hook calls sig(Bad) for a HELD decl, which answers from decls.sigs without settling Bad's layout" | closed 2026-09-28; fix sha not in this file; .55 (09-28T21:38) still reports "held 0/734 + intermittent 'Bad settled a second time'" |
| .41 | two avra processes on one .avra-cache: link fails with undefined av_ symbols | "Store.keep is per-key atomic, but a program's object SET is not" | landed main a91dcbf |
| .42 | name-holed fn's signature types resolve in consumer ("Rows names no type" ×17); one unreproduced trap "unwrapped an absent value" | REASONED: rebuild.av scoped_name marks whole node holed → Origin Here | closed, fix not stated |
| .44 | refused hold's fallback reads as a crash | voice | fixed a729afe; phrase "the hold was refused" is load-bearing for tools/cache_attacks.sh + tools/hold_sweep.sh |
| .45 | one-line quote fn fails to parse | - | fixed as side effect of 095dc5e |
| .46/.47 | "method on a nameless receiver survived typing" / LLVM verify "ret ptr %1 / i64" on generated fns | "a declaring or derive splice of several top-level statements minted every statement's declaration range from ONE lo, so a later sibling's facts overwrote an earlier one's (TypeFacts.absorb lays by id)" | fixed main 60242a0 |
| .48 | witness: added file invisible (reused=true clean=false) | "the module's file LIST has no edge" | closed; mechanism deleted by .55 |
| .49 | witness: moved span reuses stale report (e.av:2:5 vs 3:5) | "Parsed's edge hashes structural fps" | closed (0304ce6 adds text); deleted by .55 |
| .50 | witness: stale Manifest edge traps "index 7 is out of bounds (length 1)" | Manifest keyed by dense ordinal | closed; deleted by .55 |
| .51 | witness: missing file answers empty program's hash | "file_id() mints a phantom on probe" | closed |
| .52 | witness: Methods edges only for first analysed file | "method_diagnostics caches its whole-table scan in method_diags per (revision, decl_count); later files read the Cell with no kernel dep" | closed |
| .53 | witness: stable names depend on admission order | "sibling_index"; Manifest edges named by dense package ordinal | closed |
| .54 | record-shape stamp never compared; pack path shared across compilers | "compiler id joins only the pack header" | closed |
| .14 (S3) | held ref lines collided: "Kind.spelled / Seat.spelled" | "held ref lines named targets by (module, name)" | fixed f27f3a4 |
| .15 | `Memo.input` reads host ONCE per file per Workspace ("the .Present branch never re-runs load()") | one-shot workspace design | N7 landed ced9bb2 (text does not confirm the re-read) |
| .18 (S3 gaps) | "use-line/import changes are invisible to both sig and body folds today"; "structural body fp doesn't move on a pure line-shift, so span-bearing answers … could reuse stale line numbers"; "TypeFacts aren't durable" | - | NOT fixed: S3 not built (matter only if per-decl reuse is built) |
| .18 | relation.av "tag_of wrongly dispatching for .Dense/.Plain kinds alongside .Tagged" | - | fixed by ERRORS PR #106 |
| .18 | `tools/sp` resolves sync tree from script path, not cwd | - | documented, AVRA_SP_TREE must be set |
| .18.4 | generation lag on self-referential rename; land.sh speed gate benches base source; Sprite keeps stale compiler; shim watchdog AVRA_CAP_MB unreliable | checker's string tables frozen at build time | Sprite fix c976eed; follow-up filed for IDIOMS (@plain_field markers by DeclId) |
| .55 | `cache why/changed/dependents` "always read an empty pack" — nothing writes a pack | recording deleted (PR #104) | OPEN: lead decision |
| .55 | witness ON: "leaf edit OOM 4.4GB", edited 95-150s | flattened witnesses | resolved by deletion |
| .12.5 | DbKind + DbRow.kind() are two hand-written 24-arm matches | enum-variant list refuses a spliced List<Code> | OPEN |


### Appendix C / slice 57_p3

| ticket | symptom | root cause (as stated) | status |
|---|---|---|---|
| .60 | same 110 of 717 files never held; cold denominator 719 vs 717 | "719/717 FileId dup"; unheld files had no reason | fixed da1fa34; 74 remain "named" |
| .61 | std-http 'close with the request unread is a reset' flakes in land.sh | timing-dependent verdict | closed, fix not described |
| .62 | concurrent `avra test <pkg>` race on packages/<pkg>/build/suite | shared suite binary path | closed, fix not described |
| .64 | receiver law warns 'writes through it' on a.concat(b).concat(c) | suspect qt94 2d5fcc0 / writes() over chained receiver | closed, fix not described |
| .65 | `avra run/build <file>` refuses sibling program tests' statements | "derived(path, Want.Binary) was never a scoped door cold" | fixed caeac4c (`Workspace.is_program`) |
| .66 | stale .avra-cache after source edit: ICE "nothing declares features.closures.pronoun_lambda — the program is not closed" | not stated here (".66 hole 2", "hole 3" referenced by .70/.91) | closed; fix sha not in this ticket |
| .67 | warm test: 127 refusals fn(LowerCx…) vs fn(mut LowerCx…); "LangNode"/"Lifted" settlement read twice | per .68: "mark_word (record.av, encoder) and read_type_wire's F case (interface.av, decoder) disagreed on width … and consumed was never encoded" | closed; fix sha not named |
| .70 | MAIN RED 4ef9e51: link fails `_av_$40std$2Erelation$2Estores` undefined after cli test then std-relation plugin_guide | held std-relation object serves new caller's generic with no instance | closed same day; sha not named |
| .71 / .80 (+.46/.47) | declares-path generic call carries no substitution; spliced bool pushed as i1 (LLVM verify) | "a declaring or derive splice of several top-level statements minted every statement's declaration range from ONE lo, so a later sibling's facts overwrote an earlier one's (TypeFacts.absorb lays by id)" | fixed main 60242a0 |
| .72 | self-built compiler +2.2% slower than seed-built | seed predates receiver-write thaw commits | explained; process ruling |
| .75 | native UAF: Cell load then set of same Cell, loop reads freed record ("index 2 out of bounds (length 0)") | likely Cell load treated as STANDING; "Not reproduced standalone in 4 tries" | closed; fix not described |
| .83 | inferred-error fn can't fail with param's error type | stale standing binary; already fixed by S3b `Decls.seats` | no code |
| .84 | held Task<T>/Tasks decoded to Type.Error silently | "read_type_wire named no arm for either tag" | fixed 38ea808 |
| .87 | @query/WRAP fails outside std-relation: annotation.wrap_missing 'tagged$body' | moved body re-expands | fixed f9e82ac |
| .88 | Linux: std-avrac suite traps after lists/tests/measures on Sprite | not stated | landed 59a132e |
| .89/.90 | bare `decl_rows: Db` on Decls -> path-open clones Decls (66 fields), 'index 21 out of bounds' | non-Cell field in identity struct; plus misjudged writer opening Workspace's decls slot | 4ee69c3; writer fixed on fix/receiver-typename |
| .91 | one-file edit makes ~250 files Unkept (held 659 -> 408/735) | "consumed_seat answers differently when callees are held vs fresh" (c855084) ; also "empty module_files before admission", "held files' refs missing", "failures() held callee" | fixed 360f790/84f9f82/ceeea19 (+599bb10) |
| .93 | UAF on main: view of a Cell's content freed across a call | "df32ce3's root_handed skipped the hold when a read's chain crossed a Cell" | fixed bc2d64a (7cbba5c) |
| .98 | AssignRoot.decoded "instruction 24 releases r2 — a parameter or a view" under AVRA_SOUND_CHECK=1 | not stated | landed b0fd739 |
| .100 | 7 rule-declaring files never hold (const settlement Stored.Unit never lands) | not detailed | fixed f8ebab8 |
| .101 | slice-2 view_print cache unsound: 21 new cache_attacks failures (mh, nd, nr, ee) | second row with weaker key; records mutate mid-build ("record_known rewrites record_fields") | NOT LANDED, abandoned |
| .101 | "2 pre-existing 'a compile-time value did not cross as Line' defects" in cache_attacks | not stated | OPEN (still 2 failed on 10-02) |
| .101 | warm one-line edit re-parses 48 files | provider path full-parses command files; instance_unit reads held store; `Decls.const_answer` reads a held file's STORE | PR #182 (dacb95f) "queued" — landing not confirmed in this file |
| .101 | cold build 69s vs <40s target | lower/emit | OPEN |
| .101.11/.12 | no durable dep witness: "Stored has no dep kind, Db.deps_of is in-process dense Keys, there is no pack/witnessed_check anywhere" | M3 layer never built on main | OPEN |
| .102 | green cli suite prints 'STOPPED — … trapped' | stage_test.av called judged() which prints | fixed a755ed6 |
| .103 | called fn-typed param named like a top-level fn calls the top-level fn (silent miscompile) | not stated | landed 7226fcf |
| .104 | generated top-level decl can't be `use`d cross-package (resolve.not_exported) | "mint_code_decl carried exported=false"; items(f) memoized pre-expansion | fixed 502a455 (lazy `generated_export` fallback) |
| .105 | voices.av block-word pre-filter never found a record | "raw Stored.Sig read … (Db rows live under Stored.Rows)" | fixed 3ccf761 |
| .106 | six families fingerprint with revision() -> cutoff never fires | `.finish(...)` with `self.db.revision()` | fixed 3312554 |
| .109 | --verify-held: 35 Reference-rows mismatches, multi-file impl | "(module,name,owner) ref resolution picking the first same-named decl"; plus "held collect enum decoded as a plain enum (record.av declared_kind ignored the kind column…)" | fixed 70667b9 + 14764b0 |
| .110 | multi-arm rules matched only arm 1 | root_kind_of indexed by first arm's root | fixed 4249cfd |
| .113 | type matched BY NAME in identity_plain table and quote/lower.av | strings frozen in binary | b822f6a queued; main sha not named |
| .114 | watch.sh SIGKILLs healthy builds (6-10x RSS overreport) | ppid walk + pid reuse | fixed 88f3753 (process group) |
| .115 | setting written twice -> three refusals | — | fixed e6290f0 |
| .117 | [lib] name mismatch accepted silently | — | fixed bc2d64a; original std-mcp warm-store link failure -> "avra-8sb5.57.123, a real store defect" (OPEN as far as this file says) |
| .118 | bare const arg to DECLARING annotation dropped silently | — | fixed bc2d64a |
| .119 | importer keyed on whole package surface | one aggregate interface key | fixed #54 (8a85aec) |
| .119 | warm reuse 648/790 on the branch | reached_files used module_of (package table; 5 of 12 admitted at hold time) | fixed d29f413 |
| .119 | test-std-https exit 2 'ws.av does not exist' — "NOT the branch's bug. main's compiler fails the same sequence" | asked_print -> key_parts -> text_digest -> host.read on a gone home | fixed in same branch (#54) |
| .119 | builtin ref wire names the entry file -> cold key != warm key | builtins minted by entry | fixed (names_builtin) |
| .119 | FOUND (not fixed): comprehension whose 2nd `for` bound reads 1st binder types as <error> silently, then mint-order defects | not stated | OPEN |
| .119 | KNOWN GAP: dyn vtable for an impl in an unreferenced file not reached | pre-existing | pins landed #93 (.125) |
| .76 | computed arg `@lacks(F, …)` reads the NAME 'F' not its value (shared with @plans) | — | OPEN per 09-30 comment (.118 may cover; not stated) |
| .120 | make census prints nothing, exits 0; runtime rebuild drops -DAVRA_CENSUS | census.sh deleted build/avra first; .sha stamp ignored CFLAGS | fixed 5d943d3 |
| .120 | Sprite census has no cold-cache switch (stale store served) | persistent compiler store | not stated as fixed |


### Appendix C / slice 57_p4

| ticket | symptom | root cause (as stated) | status |
|---|---|---|---|
| .121 | lint one_body_arms proposes an or-run refused by type.or_binds | lint did not check binders' payload types | fixed, main 6dba4a5 |
| .122 | shim watchdog kills healthy build "peak 4031 MB, status 137" while real peak 1.14 GB | unknown ("a child counted twice? compressed pages? a different metric?") | closed, no fix recorded in text |
| .123 | warm store link missing @std/http objects (13 vs 21 objects) | record lookup by spelled file path, but record stored under directory module name; file never registered | fixed, main e6290f0 |
| .124 | warm check: lower ~31 s + ~33 s unaccounted; entry const re-settles every warm check | bodies_lowered runs settle_consts; entry main.av always read (hypothesis) | closed "#58 merged" |
| .125 | importer held after impl-file change; removal case → link failure "undefined reference to av_@rt.mhl.Pt.say" | .119's narrowed importer key did not reach impl files of reached types | fixed PR #54 (8a85aec), pins PR #93 |
| .125 (draft) | draft 0f3706e "left the store linking broken objects" (pa/pd undefined Pt.say/Pt.twice) | "reached_files naming a file's module by module_of, from the package table" | fixed in 2eec21c (in #54) |
| .126 | warm check reports fewer lint findings (gate hole for `make idioms`) | Checked.findings omitted HELD files' findings | fixed PR #61 (2f7f94c) |
| .127 | importer "held" after unrelated impl added | not a defect: stale per-Sprite .avra-cache (sprite-build.sh rsync excludes .avra-cache/build) | closed, artifact |
| .128 | `x / const` pays a guarded call; `avra_int_div(INT_MIN, -1)` C UB (SIGFPE 136 on x86) | backend always called guard | fixed PR #66 (6d8c484) |
| .129 | pushes quadratic when two Cells share one empty-list seed | pre-d7097e2 Cell.new put ONE buffer in both cells | already fixed by d7097e2 (#45); test PR #60 |
| .130 | Cell.set_at retain/release per write; also pre-fix guard trap "array_get read a RELEASED box" witness | aliased_write read a write INTO the list as re-pointing the cell | fixed PR #81 (ba3a17c) |
| .131 | reused const value stale across files (FAR 8 vs 71) | kept value keyed on own runs, not the read const's runs | not on main; branch perf/verdict124 unlanded |
| .132 | `compilers` roll lost updates; sweep rm's a store mid-read; "compiler_print hashes the FILE at the binary path lazily, not the running image" | unlocked read-modify-write + sweep | roll+sweep fixed PR #91; the lazy file-hash point is NOT addressed in the close text |
| .134 | cli check_witness 118/119 over a warm .avra-cache | suspect: fixture cache root not isolated per run | closed, no resolution text |
| .135 | watch.sh `set -m` no-tty line under dash; tree-kill off; cache-attacks 2/117 | /bin/sh is dash; job control needs a tty | fixed PR #156 (full cache-attacks not re-run) |
| .136 | warm check lowered 4x slower than cold | per-read HeldSig ask; KernelState copied per hit; restored_refs per ROW (quadratic) | fixed "#48 merged" |
| .137 | ~1% cold-build cost from armed relation hooks | diffuse per-row bookkeeping | accepted, not fixed |
| .139 | warm tree links kept std-io object built against other C ("_avra_io_compile_slot undefined") | object/record key missed package C | fixed PR #73 |
| .140 | every ir_of/analyze_source test & IR golden sees code WITHOUT consumption | Decls.disarm resets ensure_consumed before Analysis.lowered() | fixed PR #78 (ccab7da) |
| .142 | witness_refusal_test:233 / witness_stale_manifest_test:7 fail in trains | "cause: #45, not flaky" | fixed "#71 merged" |
| .143 | sp runs command on stale compiler after failed build | sprite-build fallback to cached compiler | fixed #69 |
| .144 | canon_provider_test :41/:45 flake | `fmt --check <dir>` queued on Sprite-wide /tmp/avra-build.lock; 60 s timeout fired | PR #84 queued |
| .145 | `avra test <program-test file>` exit 0, prints nothing | Workspace.suite: programs [] when `only` set; refuses_tests() unscoped | PR #120 (c5da450) queued |
| .146 | deleted file keeps its Decl rows | no un-admit verb in Decls | closed, no resolution text |
| .151/.152 | kernel query may reuse stale answer over a relation cell (negative hash reads unchanged); positive hash → needless re-runs | relation verifiers answer content hash; `changed_after` compares `verify(arg) > since` revision | fixed PR #111 |
| .153 | `avra cache` modes save what they read; second run says nothing moved | hold_report keeps rows | fixed PR #113 (11fd2d4) |
| .154 | Typed(main) reads Parsed(a) whole; any edit to a.av re-types main | `computed_marks` uncached foreign parse; `methods()` reads before opening its frame | fixed PR #114 (46d8154) |
| .155 | adding/renaming any decl in a.av re-types every importer | Decl row reads recorded per FILE | PR #173 queued (a943d03) |
| .156 | fingerprint tags 183/184 claimed twice (opt_decl_fp, opt_dispatch_fp); gate did not run `make fingerprints` | - | fixed PR #115 (682e12b), gate PR #116 (7448088) |
| .157 | no keeper against a MOVED Family variant; durable rows keyed by ordinal would read wrong family | - | keeper tools/families.py (#127 per .148) |
| .158 | cli tests flake under load | 8–60 s wall bounds | closed, no sha |
| .159 | `by it.mark` / component field silently file-orders; `by it.mark.args[0]` parse error | key "" for non-generic word; stable sort | fixed PR #140 |
| .161 | collect enum order "ignored" for foreign members | NOT A BUG — test expectation wrong | retracted |
| .154 (aside) | `loc(d)` reads facts.span through Items, whose print nulls spans | by design; "latent only while compiles are one-shot" | pre-existing, unchanged, OPEN deadline |
| .150 (aside) | `make census refuses on Linux` (.128): tools/census.sh greps nm for '_note_retain' (macOS underscore) | - | not stated fixed |
| **.163** | partly-held rebuild peaks 3442/3371 MB vs cold 2168/2177 MB; one killed at 4227 MB | NOT INVESTIGATED (load / admit / held path) | **OPEN** |
| **.164** | `avra build` binary stale after embedded file edit (`embed("x.txt")`); "parking .avra-cache cures it" | "build_inputs lists no embedded file and a kept settlement has no line for one" (unverified); later: program key + kept const verdict (kept_settle) | **OPEN** (fix on wants-modules, unlanded per text) |
| **.165** | cache-attacks 2/186 fail ("a compile-time value did not cross as Line"); fmt-lossless 5 files differ (fmt parenthesises a within-instance in operand position); codecs 2 unregistered pairs | none of the three in .github/workflows/checks.yml | **OPEN** |


### Appendix C / slice other_p1

| ticket | symptom | root cause if stated | status |
|---|---|---|---|
| 1.28.8 | `avra test <pkg>` reuses cached suite binary after a package C object change; green/red both stale | "The test binary's cache key covers Avra sources but not the package C objects named in [link] objects" | OPEN |
| 1.35 | `avra test` answers from `.avra-cache` after `std_tls.c` edit + lib rebuild (13/13 vs true 12/13) | "The suite's cache key does not cover the package's C sources (or its built library)" | OPEN (duplicate cause of .1.28.8; neither links the other) |
| 9.2 | reindent "leaves every later span stale and certified fresh" | `parsed` settles on structural fingerprints; value carries TEXT and SPANs | DEFERRED (latent "while compiles are ONE-SHOT") |
| 11.58 | "const X = X cycled through ConstTyped AND Typed; each family saw only its own re-entry, Typed's start_recursive answered a smaller view in silence" | kernel has no cross-family cycle verdict | Worked around (`Memo.open` + hand check + F2078); ask OPEN |
| 11.120 #10 | "two hand scans in compiler/interface.av disagree on the miss (one answers -1, one answers 0 — the second is a silently wrong declaration reference; verified defect, fix pending)" | hand-rolled find_index | "fix pending" as of 2026-09-21; later state not in file |
| 10.136 | "A field reorder silently re-aims every hot unrecorded lookup" (hazard, not observed failure) | hand-numbered index constants in features/decls.av; `known_file_id/known_module_id hard-code 0` | OPEN |
| 10.85 | workspace never dies (reference cycle) | verifiers/hooks/analyses capture the workspace | OPEN (workaround `disarmed`) |
| 1.24.4 | `let g = c.get(); c.push(2); c.set_at(0, 9)` "leaves g at length 2 with g[0] == 9 in both engines" | in-place cell writes "assume the cell is the held box's only holder; get hands the same box out" | OPEN, waits on .1.24.3 |
| 2y5c.11 | 1 F2047 left: "the interpreter's `whole` (interp_tasks.av:103)" | — | left at close |


### Appendix C / slice other_p2

| ticket | symptom | root cause if stated | status |
|---|---|---|---|
| .36 | held file reads wrong declared type after a type inserted above ("argument 7 of build_named wants Instancing, found BlockWords"); types print as method names; held fn type's seat marks lost. "rm -rf .avra-cache clears it every time" | "Suspect: a record names a declared type by its ordinal within the file"; confirmed wire "still positional (interface.av decl_wire: path~ordinal)" | CLOSED 09-28: no longer silent (adrift re-check forces unheld re-derivation); root rewrite deferred to "townhall decision 10" |
| .25.20 | `make test` LINK "Undefined symbols" for @std/toml in compiler/host; again 09-25 (`_av_...emit_then_error`, `core.flatten$…`, `BuildError.describe`) | "a held object whose ASKS (libraries/externs) no longer match the closure"; second time `packages/std-avrac/.avra-cache` held stale objects | OPEN; attack not written |
| .25.52 | "avra: defect: memo family 3 reused missing key 6" (exit 2) from `avra check` over stale cache | not stated | closed, no fix text |
| .25.54 | finding `loops.push_loop` at lists_test.av:19 present/absent by cache state; `--accept` pruned it repeatedly | "Suspect: a warm .avra-cache check hit (kept warnings) or a cached check that examines nothing drops this finding" | closed, no fix text |
| .31 | after deleting a program-test dir, `avra test` exit 2 "`.../zz_attack/zz_attack.av` does not exist"; name found in a `unit/` and a `sig/` entry | "suspect: the build closure, `closure_key` in compiler/build.av … served without re-checking which files still exist" | OPEN P1; sibling avra-knya |
| .34.2 | lib-only runtime change hands back old binary | linked FILES (archive, `[link]` objects) not keyed | FIXED 05b679d |
| .34.2 (comment) | scratch pkg: "a stale .avra-cache served a binary that segfaulted" | not stated | not addressed |
| .34.2 (comment) | R15a "intermittent non-fixed-point" compiler; "a cache entry made by one compiler generation was reused by another. The cache key misses something the output depends on." | "a different key (compiler print)" | "not addressed here" — no ticket named |
| .37 | worktree builds read/write MAIN checkout's `.avra-cache` | `tree_root()` skips a `.git` FILE | ticket OPEN; .34.2 says "already fixed on main (has_git uses exists, a file counts)"; fix 0745613 |
| .40.17 | nested worktree (`avra/main`) shares parent's `.avra-cache`; "avra/main/.avra-cache does not exist on disk at all" | `tree_root()` picks the HIGHEST checkout-looking ancestor | OPEN |
| .34.30.6 | cache-attacks red: "the hold was refused: error[language.defect]: Tick's flatness was read before a mut seat sealed it" | hold's drift bookkeeping read flatness tracked | FIXED main 4e98526 |
| .11.300 | `make avra` killed at ~4 GB when tree-root `.avra-cache` from check/test stands | not stated | OPEN |
| .11.236 | `avra test` answered from `.avra-cache` after package C changed | suite cache key does not cover package C | OPEN (see also avra-8sb5.1.35) |
| .46 | potential: 30-bit un-keyed fp_mix collision ⇒ "a stale build or a stale memoized answer with NO error"; sites "query/db.av's settle, compiler/record.av, bytes_keyed" | hash width / un-keyed | OPEN P1, untriaged |
| .25.50 | quote same-binder compares `subtree_fp` alone; `${x} == ${x}` could match `a == b` | same fp_mix | closed, no text |
| .23 (comment) | "'avra test <file>' under a whole hold was broken three ways (entry typed over a registry copy -> LLVM refused the module; held cases undeclared -> 'program is not closed'; prelude never admitted -> link failed)" | as quoted | FIXED f2f955d |
| .23 (comment) | seed-check FAILED at 1372a35 (hashed source changed without `make seed`) | as quoted | FIXED 963556d |
| .33.8 | `TypeCx.meets_bound` "PARSES a held (cached) file" | bound trait not in held record | OPEN P3 |
| .11.249/.250 (avra-8sb5.67) | "a wasm restart read the host store"; "a print asked before the mode was set kept the host answer" | `Workspace.anew` never carried `build_mode`; memo cells not tied to inputs | fixed by hand reset (cache-target 0bdcb6d, per ticket); language asks open |
| .44.1 (comment) | fixed-point check false "non-identical" on first attempt | stale `.avra-cache` | n/a (process note) |
| .44 | two same-named @model types in different modules "silently wrote into the SAME physical SQLite table" | bare type name as table name | FIXED via `__avra_models__` registry (unlanded at last comment) |


### Appendix C / slice other_p3

| ticket | symptom | root cause (as stated) | status |
|---|---|---|---|
| .67 | wasm link handed cached NATIVE objects ("wasm-ld: unknown file type") after a native test run + edit | "Workspace.anew (workspace.av) carried keys.keeping and dropped keys.build_mode, so a wasm build that RESTARTED its derivation (moved generic home, refused hold) derived the host's compiler print/store root" | closed; fix 0bdcb6d "not pushed" at close, later cited as PR #272 |
| .67 (2nd) | "a fresh wasm build published the shrunk module but KEPT the unshrunk one (reuse served different bytes) and leaked a .staged file per build" | — | fixed by `shipped()` |
| .68 | swapping WASM_OPT "served the module the first tool made" | "only presence keyed" | open P2 |
| .69 | different clang/sysroot can reuse a linked artifact; "opt level keyed only on the program object" (.67) | linker path, CC, CCC_OVERRIDE_OPTIONS, sysroot "not in any key" | open P3, unexercised |
| .70 | "the hold was refused (error[type.list_element]: this list holds dyn View, this is column); built from its sources" on EVERY edit (ui-board; also std-ui "dyn View, found image/button") | "Likely the stale-hold defect avra-8sb5.36" (unconfirmed) | open P2 |
| .71 | failed wasm link leaves `.staged` | retracted: "I did not observe a failed link leaving a .staged file"; but "linked() returns LinkFailed without removing whatever the linker wrote" | open P3, unverified |
| .72 | test named for anew() "builds two separate workspaces, so it missed avra-8sb5.67" | name ≠ scope | open P3 |
| .73 | evaluator: `Map.set` in a loop quadratic in memory | "Each insert copies the map … AND the copies are not freed while the loop runs" | open P2 |
| .74 | guard_ledger_test fails 1/6 on macOS at 92678df; later runtime tests unrun | "Under AVRA_RC_GUARD a released map leaves bytes in avra_mem_live()" | open P2 |
| .75 | `avra test` leaves `tests/<program>/build/suite` untracked | package-shaped program tests' build/ not ignored | open P3 |
| .76 | unreached dependency code parsed/typed/lowered/linked; partly-held rebuild 1.6x cold, killed at 4227 MB | exported fns are roots; dir = one module; `dynamic_symbols` keeps all; `Kernel.newly_read` 363 MB live | open P1 |
| .77 | Sprites stall/orphans | `setsid -w` orphans; unbounded waits; pid-only leases | in_progress |
| .78 | file test then directory test → compiler >5 GB; also plain warm `make avra` OOM | "the rows a single-file test run keeps send the directory run's derivation somewhere unbounded"; top site `Kernel.newly_read` | open P1 |
| .79 | `f(g(x))` and `g(f(x))` same `stmt_fingerprint`; also `x |> f |> g` vs `x |> g |> f` | "fp_mix is h*131+v+7 mod P, so fp(tag, parts) is linear in each part" → "an early cutoff keyed on the statement fingerprint certifies a swapped call chain as unchanged" | open P2 |
| avra-knya | stale `.avra-cache` → phantom type errors in unchanged file ("wants List<Arrow>, found List<SeatMark>"), two struct identities swapped, after adding an Expr variant + feature dir | hypothesis: held fact keyed without DeclId layout | open P1 |
| avra-zsc2 | scratch file's `.avra-cache` served an object built by an OLDER compiler binary | none in input (title only) | open P1 |
| avra-yp6n | lone file's `.ll/.plan/.warn` go to in-memory host and vanish; only `.bin` + `recent` on disk | Store collapsed into Host | open P3 ("WITNESSED INERT") |
| avra-9vy7 | no held-package test for Type.Union through `compiler/interface.av` record lines | no harness | open P3 |
| .63.11 | evaluator builder push loop quadratic in memory | "write-through or copy defect" | open |
| .65.3.4 | `(0..5).any(it == 2)` → "defect: a row without its seat survived typing" | scan verbs lower wrong | open |
| .65.3.6 / avra-dw89 | eval answers 2 where IR says 6 for filter().take(2).sum() | interpreter `break` nested in two region arms | open |
| .65.3.13.1 | `s.chars()` build/run >2.5 GB | Codepoints emission unbounded in features/emit.av | open |
| avra-g10d | census.sh deletes build/avra_runtime.o | tool does not restore | open |


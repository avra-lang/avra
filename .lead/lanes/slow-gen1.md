# slow-gen1
BLOCKED (no measurements yet): `sh tools/work new slow-gen1` created no worktree: "every Sprite is bound to a lane — `work done` in one frees its Sprite".
`work sprites` shows all ~50 Sprites bound. Ones that look stale/idle (not answering, "NO"): avra-1gen, avra-attr, avra-rtmut, avra-rb484, avra-poison, avra-dev, avra-vd, etc. Idle but answering: avra-07d, avra-evalto, avra-phase-d, avra-sgate, avra-triage (running "-").
Need from lead: free one Sprite (work done in a finished lane, or `work bind <sprite>` for me) — I will not touch another lane's binding.

## Report 1 (partial) — worktree ../avra-lower-regress, branch slow-gen1, Sprite avra-sgate
- Sighting #5 came free: the Sprite's prep of lower-regress's OLD binary (lane lower-attempt0, long-used cache) building main eadf455: `make -s avra` 420 s, next 110 s. (730-class sighting reproduced: 530 s for the pair.)
- Controlled repro, main (6681fe55) source built by an e3d6b7c8 binary from `make bootstrap` (gen1, NOT gen2+), `./avra build packages/cli`:
  - case A, kept .avra-cache of the e3d build: 146 s, peak 2198 MB
  - case B, cache moved aside (cold): 176 s, peak 2093 MB
  - first prep generation (probe=one, same as A): 146 s
  => NEITHER is slow. #671/#675 do NOT by themselves make a clean old binary slow on the new source. Kept cache even helps slightly (146 vs 176).
- QTRACE counts: 'Q ask' lines identical A vs B (2.30M Namespace asks, 429k Parsed); the `Q attempt`/`Q parse` greps found 0 — those lines don't appear at all in this build's trace (3.1M lines, all `Q ask`).
- Hypothesis now: the slow case needs what a lane has and my repro lacks: (1) a gen2+ binary, (2) a cache fat with history (suite/test runs, many compiler digests). Testing (1) next, then (2).

## Report 2 — REPRODUCED (avra-sgate, same binary 7beca863 = e3d6b7c8 bootstrap product throughout)
- gen2 at e3d (make avra) over a cache left by a cold build of MAIN 6681fe55 by the same binary: 771 s (gen3 right after: 126 s).
- Controlled: cold main build 131 s -> cache saved; then e3d source, SAME binary, that cache, QTRACE+MEM_STATS: 991 s, peak 4356 MB.
  Ask counts: 5.53M Namespace asks (vs 2.30M in the 146/176 s runs), Parsed split across revisions 1,2,3,5 (176k/109k/79k/76k).
- Contrast: OLD cache -> NEW source (my case A) 146 s. The slow direction is a cache holding rows judged against a DIFFERENT source tree than the one being built, built with the binary that wrote them.
- Pending: same source with cache moved aside (run F), then name the function.

## Report 3 — DECISIVE PAIR (same binary 7beca863, same source e3d6b7c8, packages/cli build, QTRACE on both)
- cache = a cold main-source (6681fe55) build's cache (2.2-2.4 GB): 991 s, peak 4356 MB, 5.53M Namespace asks, 2771 parses, 7 `Q attempt` lines.
- cache moved aside (cold): 149 s, peak 2138 MB, 2.28M Namespace asks, 606 parses, 2 `Q attempt` lines.
- The E trace: second derivation turns FIVE times (derive.av's Attempt/Turn loop):
  attempt 0 (hold, homes false), 1 (homes, reading 394), 2 (reading 395), 3 (reading 408), 4 (moved 1) — at trace lines 99120 / 100934 / 633066 / 3272952 / 4266193. Attempt 3 alone spans ~2.6M trace lines, i.e. most of the time. Cold never turns past attempt 0.
- MECHANISM (named): a kept cache from a DIFFERENT tree gives the derivation held files whose records are stale; each discovery of "more must be read" (`Attempt.having_read` at derive.av ~607, 682-688, 699: bodies_asked / gathered_moved / read_held_asks / read_held_codes) and each `adrift` (derive.av ~716, records moved under it) fails the whole attempt and `tried_anew` re-derives the program from scratch in a fresh workspace. Cost ≈ turns × a full derivation (~150-200 s each) instead of one.
  A lane after merging main is exactly that: the cache holds the pre-merge tree's records.
- Not measured: per-attempt seconds (running `build --time` over the restored cache as run G, result next), nor the fresh-Sprite control (owner/lead asked for it, then asked to resume the pair; I resumed the pair on avra-sgate and did NOT replace it).

## Report 4 — per-phase (run G: e3d source, same binary, main-source cold cache, `build --time`, no QTRACE) ~765 s
- Discarded attempts: 1.5 s + 34 s + 116 s + 72.6 s = 224 s (4 turns; reads 394 more, 1 more, 13 more, then "records moved").
- The attempt that STOOD: ast 23 s, resolve 4.8, bodies 7.2, load 3.7, admit 25.9, analyze 13.3, **lower 398 s**, keep 11.8, emit 42.6, link 10 => ~540 s. Held files: 4 of 461.
- So two costs: (a) 224 s of turns; (b) a `lower` phase of 398 s even in the attempt that stood (discarded attempt 3 also spent 79.6 s in lower; attempt 4 29.6 s). Cold equivalent is a ~35-45 s lower (cf. #671's cold lower 35 s); not re-timed in this run.
- Why each turn "reads N more": the log lists ~455 files with reasons "nothing kept stands in: what it sees moved, or it was never built" / "a home of instantiations owed" / "a compile-time run called one of its bodies" — i.e. the stale cache's held files are judged non-standing, one discovery batch per turn.
- Where lower's 398 s goes is the next measurement (kept_settle.av per-unit judging vs per-declaration kept units #605/#600), not done. Fresh-Sprite control not done (Sprite not replaced; conflicting lead messages, latest said resume).

## From db06 (2026-10-13): consts settled lazily inside lowering = 6.3% of a COLD CHECK
Counted once, here. In the cold-check sample (`/tmp/db06-sample-cold-check.txt`, 47,607 main-thread samples), `Decls.union` -> drained -> lower_unit -> lower_fn -> Ident.lower -> const_decl_reg -> settled_value_reg -> Workspace.settled -> const_settlement -> settle_run is 3,013 samples = 6.3% of the run (51% of union's 12.4%). It is part of the 20.8% `const_settlement` total (9,906 samples), not an addition to it. In the cold build the same chain is a share of the 16.0%. Reader: `python3 .lead/db06_incl.py <sample> under:Decls.union 30`.

## Report 5 — follow-ups
(1) PER-ATTEMPT, QTRACE-free `build --time` (e3d source, same binary, other tree's store), 765 s:
  turn 1: 1.5 s (load) -> next reads 394 more (the instantiation HOMES: `having_read`, files "a home of instantiations owed")
  turn 2: 34 s (ast 19, load 22, analyze 8.8) -> next reads 1 more (../std-relation/src/query…: `having_read`)
  turn 3: 116 s (lower 79.6) -> next reads 13 more (../std-h…: `having_read` from bodies_asked/read_held_*)
  turn 4: 72.6 s (lower 29.6, keep 5) -> "reads the records again, moved under it" (`adrift`, moved 1)
  stood: 540 s (lower 398, emit 42.6, admit 25.9, ast 23, analyze 13, keep 11.8, link 10). Held 4/461.
  So: 3 `having_read` turns (394 + 1 + 13 files) and 1 `adrift`.
(2) KEEPER: draft PR #737 (branch cache-attack-other-tree, off origin/main 88ccbdec), section `ot` in tools/cache_attacks.sh. Fixture: copy of packages/, `check std-http`, append a unique exported fn to every src file (580 files), check again through the same store, assert discarded <= cold's. Witnessed FAILING on main: warm discarded 2, cold 0 (a ~80 s run). Title says red until items-kept's fix. (A hand-made 14-module fixture did NOT reproduce: 0 vs 0 — real components/derives/instantiations matter.)
(3) RECIPE, measured: lane after merging main, FIRST build:  mv .avra-cache "/tmp/old-$(date +%s)-$$"  then make avra.
  Measured on avra-sgate: with the stale store the compiler-build prep hit its 1200 s bound (killed, exit 125); with the store moved aside the same prep `make -s avra` took 132 s (cold). (Also 149 s / 176 s earlier.)

## Report 6 — CONST SETTLEMENT: what repeats (measure only; no edits)
Sources: (a) db06's cold `check packages/cli` frame-pointer sample (/tmp/db06_cc_incl.txt, 47,607 main-thread samples, inclusive); (b) my cold `check packages/std-avrac` with AVRA_QTRACE on avra-sgate (1059 files, 1,147,393 trace lines; analyze 42.8 s, lower 29.1 s); (c) source count of std-avrac consts. NOT done: per-const seconds (top 20) — no clock in the trace and no valgrind on avra-sgate; a one-line timestamp in `settle_run` would give it.

### Counts (b)
- 462 `const_verdict` lines, 0 stood (cold) = 462 settlement runs (`Settled compute` = 462).
- 10,230 `Settled` asks for those 462 consts: 22 asks per const, 9,768 of them `reuse` (memo hits). Cheap each but they are ~97% of the Settled asks.
- 63,063 `settle` lines (kernel settle events), 25,853 `unit lowered` (whole-check lowering; consts' share not separable in the trace).
- Parsed: 335,538 reuse asks; the most-asked file got 17,295 asks (next 7,044 / 6,624 / 5,229). All reuse — each one still pays Kernel.record_at (4.8% inclusive in (a)).
- Source (c): ~381 consts declared in std-avrac, ~189 (50%) are plain literals (int/float/string/bool/[]/{}), the rest lists/records/tables and a handful of calls (`joined(...)`). The evaluator is needed by perhaps a dozen.

### Ranked: where const_settlement's 20.8% of a cold check goes (inclusive % of main thread, (a))
| # | what | % | note |
|---|------|---|------|
| 1 | closure lowered AGAIN per const: `reach_probe`/`settlement_until` 4.1 + `run_lowered_for` -> `Decls.settlement` 4.3 | ~8.4 | each const lowers+unions its reachable body closure twice (probe, then standalone); bodies are shared `Lowered` queries but the closure is re-assembled (`bodies.concat` in settlement_until) per const |
| 2 | `memory()` over the const's assembled closure | 4.7 | memory pass (twin_table 2.4, read_outlives 2.3, borrow_outlives 2.1) re-run on the whole closure for EVERY const; run_lowered_for line 742 |
| 3 | `recorded_reads` -> `distinct_reads` -> `read_wire` -> `core.hex` | 5.5 (distinct_reads 5.3, hex 5.2) | `settle_run` re-dedupes the reader file's CUMULATIVE read list (`before.concat(read)`) after every const, recomputing each read's hex wire: O(consts-in-file x reads), quadratic per reader file; `recorded_reads` also does decl_read per body of the closure, twice (probe path and main path) |
| 4 | `keep_verdict` (store.settle 2.0, pack) | ~5.0 | writes a verdict + lines per const, literals included |
| 5 | the evaluator itself, `run_settle` | 0.5 | negligible; `world_in` 0.3 |
(rows overlap — they are inclusive; 1+2+3+4 ≈ the 20.8%.)

### The one or two fixes (measured shape, not tried)
A. LITERAL FAST PATH: a const with no seats whose initializer is a literal (int/float/string/bool/empty list/map) settles straight from the node through the value protocol — no reach_probe, no standalone, no memory(), no interpreter, `reads = []` (so no recorded_reads/distinct_reads). ~50% of consts; they skip rows 1-3 entirely. Expected: a third to a half of the 14% in `settlement_of`+`recorded_reads`, i.e. roughly 5-8% of a cold check (3-4 s of 57 s). Needs a new probe-by-literal check; the helper is `settle_run`/`const_settlement` in kept_settle.av.
B. DEDUPE READS INCREMENTALLY: keep a per-reader `Map<wire, true>` (or a set cell next to `hold.runs`) and append only unseen reads; stop recomputing `read_wire`/hex for the whole list per const. This is the fix for row 3 (5.3%) alone and is independent of A; ~15 lines in `settle_run` (workspace-side), no derive.av.
C. (bigger) memory-pass each shared body once and assemble settlement closures from already-passed bodies (row 2, 4.7%).

## Report 7 — stale-cache `lower` (398 s vs ~35-45 s): COUNTS from the 991 s QTRACE run (E) vs cold (F), same binary/source
Per-attempt segments of E (trace lines between `Q attempt` markers) vs cold F:
| segment | unit.lowered | Lowered.compute | Typed.compute | const ran / stood | store.value |
| attempt 2 (633k-3.27M) | 10533 | 9101 | 9567 | 279 / 12 | 263 |
| attempt 3 (3.27M-4.27M) | 10697 | 9584 | 10186 | 106 / 239 | 85 |
| attempt 4 = the one that STOOD (4.27M-7.23M) | 15421 | 13738 | 15344 | 328 / 247 | 2191 |
| cold F | 15810 | 13817 | 15452 | 577 / 0 | 647 |
Whole run: units lowered 37230 (14341 distinct, ~2.6 lowerings each over the 5 attempts) vs 15810 cold; const_verdict lines 1227 (575 distinct consts, up to 5 verdicts each) vs 577; Typed.compute 44874 vs 15452; Settled compute 1248 vs 577.
HYPOTHESES:
 (a) stale unit row read+decoded per ask — KILLED for lower: `served` units = 0 in both runs; all 2191 `store value` reads of the standing attempt sit in the last ~300k trace lines (the keep/seal tail), none during lower. 
 (b) refused rows rewritten one by one — not visible in lower (the writes are the tail's); not confirmed.
 (c) instantiation homes lowered per owing file — KILLED: the standing attempt lowers 15421 units vs 15810 cold; no duplication INSIDE the attempt. The duplication is ACROSS attempts (each of 5 re-lowers ~10-15k units: that is the 224 s of discarded + part of the multiplier).
FOUND: the standing attempt does the same lowering work as cold (15.4k vs 15.8k units) but asks `Settled` 81,067 times vs 7,515 cold (~140 asks per const vs ~13; 10.8x) and runs 247 consts through the KEPT-verdict path (stood) beside 328 that run. 398 s / 35 s = 11x, the same ratio. Sources of Settled asks per const that exist only with kept rows: kept_settle.av `kept_verdict` (view_stands/rows_stand over every `v`/`m`/`f` line, decode of every `r` read), `forced_runs`, `ask_kept_reads` (distinct_reads(read.concat(flatten([ran_by(store, p.path) for p in read]))) — a record decode per read, and `distinct_reads` re-hexes every read: the same read_wire/hex cost as report 6 row 3), run once per verdict and (via the turns) up to 5x.
NOT PROVEN: which of those is the multiplier — the trace carries no clock, and the compiler that would carry one must be built on the stale tree. One-line next step: add `self.clock()` to the `Q const_verdict` line in kept_settle.av (const_settlement) and the `Q unit` line (workspace_analysis.av:449), bootstrap, redo the stale pair (~35 min on the Sprite): the gap between consecutive timestamps names the phase. Until then the confirmed statements are the counts above (5x derivations, 10.8x Settled asks, equal unit counts), not a function-level cost.

## Report 8 — THE MULTIPLIER, WITH A CLOCK (slow-gen1, 2026-10-13)

Per the report-7 next step: `self.clock()` on the `Q const_verdict` line
(`kept_settle.av` `const_settlement`) and the `Q unit` line
(`workspace_analysis.av:449`), plus explicit elapsed fields — `kept_ns=` on the
verdict line and a new `Q ask_kept <name> <ns>` line around `ask_kept_reads`.
Bootstrap on `avra-sgate`: binary `8bdf77aab331`, source `3a0d328e3bf8`
(`sh tools/work run --for 40 'sh tools/_sg_36.sh'`, 611 s, passed).

THE STALE PAIR IS CONTROLLED. A store is keyed by the compiler's own print
(its binary bytes), so the old `build/cache-main-cold` can NOT be read by the
clocked binary. A foreign cache it CAN read was made by perturbing every
`packages/**/src/**/*.av` with a marker fn, COLD-building that source with the
clocked binary (`build/cache-pert-clock2-1791926695`, 137 M), restoring the
real source, then building `packages/cli` WITH that cache vs with the cache
moved aside. Same binary, same source in both arms.

### (1) The pair — `build packages/cli`, as printed (`build/sg2_stale.err` / `build/sg2_cold.err`)
the `time:` rows:
| phase | WITH C_pert (stale) | cache aside (cold) | delta |
|---|--:|--:|--:|
| lower | 79427 ms | 21126 ms | +58301 |
| admit | 22702 | 0 | +22702 |
| analyze | 10898 | 33572 | -22674 |
| parse | 138 | 23521 | -23383 |
| emit | 35093 | 34568 | +525 |
| keep | 12504 | 11853 | +651 |
| link | 8439 | 1362 | +7077 |
| bodies | 6760 | 6134 | +626 |
| ast | 20063 | 20232 | -169 |
| resolve | 3447 | 3367 | +80 |
| load | 1997 | 1 | +1996 |
| sublang | 1698 | 3984 | -2286 |
| sigs | 550 | 547 | +3 |
wall 183 s vs 105 s. Identical work: 16601 timestamped events and 585
`const_verdict`s each (all `ran`), 16015 `unit.lowered` each.

INSIDE `lower`, the explicit clocks over those 585 consts:
| sub-phase | stale | cold | delta | share of +58.3 s |
|---|--:|--:|--:|--:|
| `ask_kept_reads` | 41525.3 ms | 2.1 ms | +41523 | 71% |
| `kept_verdict` | 16838.7 ms | 12.1 ms | +16827 | 29% |
the two sum to +58.35 s, the whole lower delta.

The raw consecutive-timestamp gaps (each interval charged to the event that
STARTED it = its self time), which is what the two requested clock lines give
before any extra instrumentation:
| interval starting at | stale | cold |
|---|--:|--:|
| `Q unit` (lowered, n=16015) | 48530.6 ms | 31071.6 ms |
| `Q const_verdict` (ran, n=585) | 41595.3 ms | 41.2 ms |
| (gap immediately BEFORE a `const_verdict`) | 27604.6 ms | 10954.7 ms |
Top consts by `ask_ns`:
`idioms$const621` 2809 ms, 620 1717, 615 1599, 616 1562, 623 1397, 599 1204,
617 1010, 622 896, 619 880, 618 834 — ten consts of the
`@std.avrac.compiler.idioms` table are about 15 s of the 41.5 s. Top by
`kept_ns`: `lists.plan$const6` 1290 ms, `collects.check$const5` 271,
`dev.witnesses$const50` 124.

### (2) The named multiplier: `ask_kept_reads`, then `kept_verdict`; NOT `forced_runs`
`kept_settle.av:200`, body line **203**:
`let all = distinct_reads(read.concat(flatten([self.ran_by(store, p.path) for p in read])))`.
`distinct_reads` (`record.av:1838`) re-hexes every read (`read_wire`) on every
call, so a reader file's reads are hexed once per const — O(consts x reads) —
and the idioms table is the biggest reader. This is 71% of the stale lower's
excess. `kept_verdict` (`kept_settle.av:322`) is second at 29% (it decodes
every `r` read and judges every `v`/`m`/`f` line). `forced_runs` is NOT on this
path: its one caller is `derive.av:1039`, in the hold/admit phase — and `admit`
is separately +22.7 s stale, a DIFFERENT stale cost, not the `lower` one.
Note the branch's `7c3dafe9` already fixed `closed_reads` with the
generation-keyed `seen_first`/`unseen_reads` (`workspace_analysis.av:650/656/678`);
`ask_kept_reads` and `forced_runs` still call `distinct_reads` directly, so the
multiplier is live on this branch.

### (3) Next step
Fix line: `kept_settle.av:203` (twin at `kept_settle.av:190` in `forced_runs`) —
dedupe through the same generation key `seen_first` provides, or memoize the
deduped list per read-list generation, so a run's reads are hexed once, not once
per const. Owner: items-kept / the #737 author; this lane only measured.
(This tree's +7 clock lines shift it; on a clean tree the fn `ask_kept_reads` is
at `kept_settle.av:195` and the `distinct_reads` call at `198`, the `forced_runs`
twin at `185`. Both are functions, not line numbers, for exactly this reason.)

### (4) Blockers / caveats
- The full 5-turn / 398 s severity was NOT reproduced: this tree perturbed is a
  milder foreign cache, so stale is 4 attempts / 1 discard / 79.4 s lower vs
  2 attempts / 0 discarded / 21.1 s. The absolute 398 s used `cache-main-cold`,
  keyed to the OLD binary's print, which the clocked binary cannot read. Ratio
  and attribution are stable across the two pairs run here (sg_ and sg2_).
- The instrumented `self.clock()` calls run unconditionally; only the qtrace
  lines are under `traced()`. The clock edits are UNCOMMITTED in
  `../avra-lower-regress` (branch `settle-literal-fastpath`), beside the lane's
  own uncommitted literal-fastpath work. Nothing pushed, nothing armed.
- `admit` (+22.7 s stale) and `link` (+7.1 s) are other stale costs outside
  `lower`; not part of this question.

## Report 9 — THE QUADRATIC FIXED AND MEASURED (slow-gen1, 2026-10-13)

Branch `settle-literal-fastpath`, commit `b3eea108`, draft PR #751 (not armed).
Worktree `../avra-lower-regress`, Sprite `avra-sgate`. A controlled pair: one
binary, one source; the store is a cold build of the same source with a one-line
marker appended to every `packages/**/src/**/*.av` (perturb, build, restore), so
the only difference between the arms is a foreign store. Both arms run
`build packages/cli` with explicit clocks on `kept_verdict` and `ask_kept_reads`.

### (1) before / after — the sub-phase table (quoted from `_sg_attrib.py`)
| sub-phase (stale, 585 before / 586 after consts) | BEFORE | AFTER | delta |
|---|--:|--:|--:|
| `ask_kept_reads` | 41525.3 ms | 16685.9 ms | -24839 |
| `kept_verdict` | 16838.7 ms | 16315.3 ms | -523 |
| `lower` (whole phase, stale) | 79427 ms | 55484 ms | -23943 |
| `lower` (cache aside) | 21126 ms | 24323 ms | — |
| lower delta (stale − cold) | +58301 ms | +31161 ms | -27140 |
Top consts by `ask_ns` (BEFORE → AFTER): `idioms$const621` 2809 → 2060,
`$const620` 1717 → 1331, `$const615` 1599 → 1431, `$const616` 1562 → 1181,
`$const599` 1204 → 822, `$const623` 1397 → 804, `$const617` 1010 → 707,
`$const622` 896 → 591, `$const619` 880 → 578, `$const618` 834 → 572.

The fix: `ask_kept_reads` dedupes a read's expansion through the read generation
(`seen_first`/`unseen_reads`) under its own ask generation, and reads back the
verdict's already-decoded reads instead of decoding twice; `forced_runs` dedupes
by PATH and never hexes a wire. So the per-const re-hexing (`distinct_reads` over
`read ++ closure(read)`) is gone.

### (2) gates (Sprite, `_sg_44.sh`, binary `eab5f2d4470a`)
- `make cache-attacks`: exit 0, **0 failed**.
- `avra test packages/std-avrac`: `8807/8809 tests passed`, then
  `STOPPED — .../build/suite reported a failure above; the rest of the suite never ran`.
  The 2 failures are both `compiler/settle — a reused unit's const reads are each
  run's` (`compiler/tests/unit_reads_test.av:49` and `:56`).
- ATTRIBUTION: building the same tree with this dedupe REVERTED (binary
  `7e56d86486f1`) runs the same two cases and fails them identically (`0/2 tests
  passed`). They are PRE-EXISTING on this branch, from the reads-dedup commit
  `7c3dafe9` — the test is `read_by`/`closed_reads` recording, which this fix does
  not touch. So the fix is cache-sound; the branch is red on `7c3dafe9`'s account.
- The 31 cache-attack failures seen in a first pass were the previous run's clock
  instrumentation, which moved `Q unit`/`Q const_verdict`'s fields and broke the
  attacks' `awk` parse; those clock lines are DROPPED from this commit.

### (3) head
`b3eea108fecc57c9f8dd94cb20ef1f7e5cf90381` on `settle-literal-fastpath`
(draft PR #751, not armed; also carries the lane's literal-fastpath scaffolding
that stood uncommitted before this change).

### (4) blockers / what is left
- The branch is red on `unit_reads_test` from `7c3dafe9`; the fix cannot be judged
  green until that read-crediting regression is fixed. Next item.
- `ask_kept_reads` is 16.7 s, not ~0: the remainder is `ran_by` closure expansion.
  The closure's reads are deliberately NOT marked seen — a path expanded as a RUN
  (`followed` = nothing for a fn read) is not the same expansion as the same path
  expanded as a READ (`ran_by(path)` walks the whole file), so marking closure
  paths drops held reads and is unsound. The safe next step is a per-attempt
  `ran_by` memo (its state changes as runs record reads, so it needs care).
- `kept_verdict` (~17 s) is a separate stale-lower cost: it decodes every `r` read
  and judges every `v`/`m`/`f` line per const. Not addressed here.
- The full 398 s severity was not reproduced (the perturbed foreign cache is
  milder than `cache-main-cold`, which a new binary's print cannot read); the
  ratio and attribution are stable across the pairs.

## Report 10 — #751 SPLIT, FIXED, GREEN, SINGLE-TOPIC (slow-gen1, 2026-10-14)

### (1) branch layout after the split
- `settle-literal-fastpath` (PR #751) = ONE commit `98fef145`, based directly on
  `origin/main` `7a5b4b78`. Read-dedupe only: `kept_settle.av`,
  `workspace_analysis.av`, `workspace.av`, `run_reads_test.av` (143+/16−, 4 files).
  It squashes the old lane branch's `7c3dafe9` (a reader's reads deduped once per
  read, under the list's generation) with the read-dedupe half of `b3eea108` (a kept
  verdict's reads asked once per attempt), plus the reader-key fix below. One topic,
  one PR, self-contained on main (no unlanded base).
- `settle-literal-scaffold` (branch only, pushed, no PR) = `98fef145` + one commit
  `87ec7e2b` carrying the literal-fastpath scaffolding the old `b3eea108` mixed in
  (`settlement_or_literal`/`literal_settlement`, `scalar_literal`, `settled_literal`,
  `settle_diff`, `literal_settle_test.av`). VERIFIED to build on batch #12 and its
  own spec passes `3/3 tests passed` (compiler `4000847e15d6`); its suite was not run.
- `settle-reads-incremental` (PR #744, head `7c3dafe9`) is now a STRICT SUBSET of
  #751 — it carries neither the fix nor the `ask_kept_reads` half. Recommend the lead
  CLOSE #744 (I did not; closing is the lead's call). Local `sg-b3eea108-backup`
  keeps the old `b3eea108`; local `sg-dedupe-tmp` is the throwaway snapshot.
- The PR body was rewritten via `gh api` (this token lacks `read:project`, so
  `gh pr edit` refuses). Not armed; the lead arms.

### (2) the fix + suite last-line
`unit_reads_test` "a reused unit's const reads are each run's" was RED from
`7c3dafe9`: `seen_first`'s dedupe key was `${gen}|${read_wire(r)}` and `read_gen`
starts every reader at generation 0, so after A's scope closed at gen 0 and marked
`0|<k.av>`, B's close at gen 0 found the SAME key and dropped its read — two readers
that read one file hid each other's read. The key now names the reader:
`seen_first(reader, gen, r)` / `"${reader}|${gen}|${read_wire(r)}"`. The test asserts
the law, so the CODE was fixed, not the test.
- spec: `2/2 tests passed` (was `0/2`).
- suite: `8850/8850 tests passed` (not the task's 8809: batch #12 landed on main and
  added 44 cases; the 3 literal-set cases are on the scaffold branch, so this branch
  is 8806 + 44 = 8850, all green).

### (3) cache-attacks last-line
`cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected` — `FAIL count: 0`,
exit 0.

### (4) head
`98fef145afdf0aa23df736479e6c2d9d4e6d3cc5` on `settle-literal-fastpath`
(PR #751 draft, base main `7a5b4b78`, not armed). Scaffold `87ec7e2b`.

### (5) blockers / what is left
- The gate ran on the REBASED tree (origin/main `7a5b4b78` + the one commit) on
  avra-sgate: build OK, spec 2/2, cache-attacks 0 failed, suite 8850/8850.
  (`_sg_52.sh` hit its 30 min bound inside the suite; `_sg_53.sh` finished it warm —
  build+attacks in `sg52`, suite in `sg53`, compiler `1e8a7e1fdd4a`.)
- #744 is superseded (above); one close needed from the lead.
- Item 4 (per-attempt `ran_by` memo, the remaining ~16.7 s of closure expansion) was
  NOT attempted: 1–3 went green, but the memo needs its own perturbed-cache pair and
  re-gate, and the branch is clean now. The report-9 next step stands: memoize `ran_by`
  per attempt WITHOUT marking closure reads seen (a fn read expands differently as a run
  than as a read, so marking it drops held reads).
- `kept_verdict` (~17 s stale) remains a separate cost, untouched.

## Report 11 — THE REMAINING STALE-LOWER COSTS (slow-gen1, 2026-10-14)

Branch `ran-by-memo` off `settle-literal-fastpath` (`98fef145`); head **`e9818e91`**;
worktree `../avra-lower-regress`, Sprite `avra-sgate`; draft stacked PR **#755**
(base `settle-literal-fastpath`, NOT armed). #751 untouched. Scripts `_sg_60`/`_sg_61`/
`_sg_62`/`_sg_rb.py` untracked in `tools/`.

### (1) Item 1 DONE — `ran_by` per-attempt memo (the 16.7 s of closure expansion)
`followed` (`interface.av`) is memoized per read for the attempt, keyed by path+ref,
invalidated only when THAT path's recorded runs move (`runs_gen`, bumped by
`record_runs` — the one door `read_by`/`opened_reads`/`closed_reads` write runs
through). A closure read is never marked seen: a fn read inherits nothing, and the
same path expanded as a run walks its whole file. The first draft gated on
`read_here` and got **0 hits** — every read reached in the lower phase is a file
this build MET; the per-path run generation is what makes it valid across settlements.

Controlled pair (one binary, one source): a marker fn appended to every
`packages/**/src/**/*.av`, cold-built, real source restored, then `build packages/cli`
with that store vs with the store aside; explicit clocks. Quoted from
`tools/_sg_rb.py`:

| sub-phase (stale) | BEFORE | AFTER | delta |
|---|--:|--:|--:|
| `ask_kept_reads` | 16041.7 ms | 6656.7 ms | -9385 |
| `kept_verdict` | 16628.2 ms | 16172.3 ms | -456 (noise) |
| `lower` (stale) | 58883 ms | 46764 ms | -12119 |
| `lower` (cache aside) | 21316 ms | 22303 ms | — |
| lower delta (stale − cold) | +37567 ms | +24461 ms | -13106 |

Memo hits **129264** over 133282 node visits (1187 roots); `ran_by` calls unchanged.

### (2) Item 2 NAMED — `kept_verdict` IS `view_stands`
Cumulative sub-clocks over 586 consts: `kv_get` (store gets + split) **50.8 ms**;
`kv_view` (`view_stands`) **15292.8 ms**; `kv_rows` **0**; `kv_dec` **0**; `kv_value`
**0**; `kept_verdict` total 15361.7 ms. So **99.5% is `view_stands`**
(`kept_settle.av:423`), which re-reads the same kept view and re-judges every line of
it once per `v` row (once per const), and it fails for all 585 "ran" consts so
`rows_stand` never runs at all. Plan: memoize `view_stands` per view id for the
attempt (invalidated on the facts it reads moving), or hoist the `v` check out of the
per-const loop. NOT fixed here.

### (3) Gates (Sprite, clean memo binary)
- `make cache-attacks`: exit 0, **FAIL count 0** (`cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`).
- `avra test packages/std-avrac`: **`8850/8850 tests passed`**.
- spec `unit_reads`: **`2/2 tests passed`**.
- `avra fmt --check`: 3 examined, 1 differing (`workspace_analysis.av`) -> re-wrapped to
  the formatter's output; the gate build ran before that edit, a re-gate is owed.

### (4) Head / blockers
- `e9818e91faf41ef678f7ea75ee853e2093c176b8` on `ran-by-memo`, draft stacked PR #755
  (base `settle-literal-fastpath`), pushed, not armed.
- The gate build preceded the fmt re-wrap; the re-wrapped tree is byte-different from the
  gated commit only in whitespace, but a confirmatory `make cache-attacks` + suite on the
  final commit is the honest receipt and was NOT re-run here (each Sprite run pays a
  ~130 s merge-base rebuild when the source hash moves).
- `kept_verdict`/`view_stands` remains open; #755 is stacked on #751 and cannot land
  before it.


## Report 12 — `view_stands` MEMOIZED (slow-gen1, 2026-10-14)

Branch `ran-by-memo` off `settle-literal-fastpath` (`98fef145`); head
**`ec2eae30`**; worktree `../avra-lower-regress`, Sprite `avra-sgate`; draft
stacked PR **#755** (base `settle-literal-fastpath`, NOT armed). #751
untouched. Scripts `_sg_70`/`_sg_71`/`_sg_72`/`_sg_kv.py` untracked in `tools/`.

### (1) the memo + the clocked stale pair

`view_stands` (`kept_settle.av`) re-read a view's kept lines from the store and
re-walked every module and file line of it for EVERY const that named that view
— 586 calls in a controlled stale-cache `build packages/cli`, 585 of them
failing, so `view_stands` was 99.5% of `kept_verdict` (report 11). It is now
memoized per view id for the attempt, on the attempt's `Hold`: keyed by the
FILE COUNT and the BODY-ASK COUNT it was judged under, so a file minted or a
body asked while the attempt runs is a fact moved and the standing is not
reused. A fresh attempt's workspace starts the map empty, so nothing carries
across a turn — the memo is per attempt and cannot survive a restart.

The invalidation key is those two counters, NOT `db.revision()`: the revision
bumps as unrelated rows settle (a const's own `Settled` row), which would have
defeated the memo; the file set and heldness are exactly the facts
`view_stands` reads that can move within an attempt, while text digests, the
parsed declarations and the store are fixed for the attempt.

**ONE binary and ONE perturbed foreign store** (the memo plus a temporary
`AVRA_NO_VIEW_MEMO` toggle; the store's print is the binary's bytes, so one
binary is one store). BEFORE = memo off, AFTER = memo on, then the COLD arm of
the real source. Quoted from `tools/_sg_kv.py` (`build/rb70_1791949213_*`):

```
===== ..._before.err =====
const_verdict calls  = 586   kept_ns sum = 14347.1 ms
    kept_ns   =       66.6 ms
    kv_get    =       53.0 ms
    kv_view   =    14277.0 ms
    kv_rows   =        0.0 ms
    kv_dec    =        0.0 ms
    kv_value  =        0.0 ms
    vhit      =          0
    vmiss     =          0

===== ..._after.err =====
const_verdict calls  = 586   kept_ns sum = 1062.0 ms
    kept_ns   =        0.0 ms
    kv_get    =       50.5 ms
    kv_view   =     1006.1 ms
    kv_rows   =        0.0 ms
    kv_dec    =        0.0 ms
    kv_value  =        0.0 ms
    vhit      =        588
    vmiss     =         49

===== lower phase (stale) =====
BEFORE lower = 43560 ms
AFTER  lower = 30324 ms
stale delta  = -13236 ms
COLD   lower = 22522 ms
BEFORE lower delta (stale-cold) = 21038 ms
AFTER  lower delta (stale-cold) = 7802 ms
```

| sub-phase (stale, 586 consts) | BEFORE | AFTER |
|---|--:|--:|
| `kept_verdict` sum | 14347.1 ms | 1062.0 ms |
| `kv_view` (`view_stands`, cumulative) | 14277.0 ms | 1006.1 ms |
| `kv_get` (store gets + split) | 53.0 ms | 50.5 ms |
| view-memo hits / misses | 0 / 0 | 588 / 49 |
| `lower` (stale) | 43560 ms | 30324 ms |
| `lower` (cold) | 22522 ms | 22522 ms |
| lower delta (stale − cold) | +21038 ms | +7802 ms |

`view_stands`'s 14.3 s → 1.0 s. The residual ~1 s is the 49 DISTINCT views'
one judgment apiece, not a repeat. `kv_rows`/`kv_dec`/`kv_value` stay 0 because
the verdict is still refused — the memo removes the repeat of the refusal, not
the refusal.

The commit also carries the branch formatter's re-wrap of a PRE-EXISTING line
in `kept_settle.av` (the multi-line `use features.{…}` collapses to one line);
`_sg_71`'s `fmt --check` flagged the file before the rewrite and cleared after.

### (2) gates — FINAL sha `ec2eae30`, Sprite `avra-sgate`, compiler `f0ace8bf9e305c97`

The gate built from the COMMITTED tree (working tree clean), so these are the
final sha's numbers, not a pre-fmt tree's:
- `make avra` exit 0 (106 s).
- `avra fmt --check kept_settle.av workspace.av` exit 0:
  `fmt --check: 2 examined, 0 differing, 0 refused`.
- `make cache-attacks` exit 0, `FAIL count: 0`; last line
  `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`.
- `avra test packages/std-avrac` exit 0: **`8850/8850 tests passed`**.

### (3) head

`ec2eae3048d659ce5ffa968b02b6c78e12c680b1` on `ran-by-memo`, pushed, updates
draft stacked PR #755 (base `settle-literal-fastpath`, `autoMergeRequest`
null — NOT armed). No new PR opened.

### (4) blockers / stack note

- #755 is STACKED on #751 (`98fef145`), which is banned as a landable PR; kept
  on `ran-by-memo` as asked — the lead un-stacks (rebases onto main) after #751
  lands. Nothing armed, nothing new opened.
- The measurement store came from a perturbed tree; the restore logged
  `markers left: 1`. That one residual marker is IDENTICAL in both arms (same
  store, same binary) and in the cold arm, so the A/B and the delta stand.
- The remaining ~1 s of `view_stands` is one judgment per distinct view (49);
  a deeper cut needs the view's line facts themselves memoized, a separate
  slice.


## Report 13 — RESIDUAL CLOCKED; UN-STACK PREPARED (slow-gen1, 2026-10-14)

Worktree `../avra-lower-regress`; Sprite `avra-sgate`. One-shot; nothing armed.
Scripts `_sg_80.sh`/`_sg_ak.py` (measurement) and `_sg_82.sh` (gate) untracked in
`tools/`.

### (1) Residual clocked — top cost `ran_by` (per-attempt closure expansion)

Controlled pair: ONE instrumented binary (temporary `self.clock()` cells around
`kept_verdict` and inside `ask_kept_reads`), ONE perturbed foreign store (a
marker fn appended to every `packages/**/src/**/*.av`, cold-built, source
restored). Stale arm = that store; cold arm = the store moved aside. Same source
(`945482f8` + instrumentation), same binary, `build packages/cli --time`.

Phase rows (`_sg_80.sh`, run `ak80_1791952504`, stale vs the real-source cold):

| phase | stale | cold | delta |
|---|--:|--:|--:|
| lower | 28804 ms | 23108 ms | **+5696** |

(The perturbed-cold build's own lower is 20833 ms; the real-source cold arm is
the proper control, so this pair's residual is +5.70 s. Report 12's pair read
+7.8 s; the ratio and attribution are stable.)

Sub-phases of that residual (cumulative over 586 consts):

| sub-phase | stale | cold | delta | share |
|---|--:|--:|--:|--:|
| `ask_kept_reads` total | 3719.8 ms | 4.0 ms | **+3715.8** | 65% |
| `kept_verdict` (≈ `view_stands`) | 1209.3 ms | 14.4 ms | +1194.9 | 21% |
| other `lower` | — | — | +785 | 14% |

`ask_kept_reads` internals (cumulative, `Q ak` clocks):

| sub-phase | ms | % of ak |
|---|--:|--:|
| `ran_by` (closure expansion) | **3302.4** | **89.0%** |
| `unseen_reads` (wire hex) | 252.3 | 6.8% |
| `get(read)` | 130.7 | 3.5% |
| `held_path` | 24.6 | 0.7% |

Rows: read-empty 377, all-seen 41, fresh 168; 13857 reads examined, 1187
distinct fresh. `kept_verdict` is essentially `view_stands` (report 12: 1006 ms
of 1062), one judgment per distinct view.

**THE TOP COST is `ran_by` in `ask_kept_reads` (3302 ms, 89% of ak; 58% of the
residual).** It is the already-memoized per-attempt closure expansion
(report 11). In this pair the stood attempt holds ZERO files (`time:` row
`held 0/470`), so the `held_path` filter finds nothing and the whole 3.3 s is
overhead — a `held == 0` guard at the top of `ask_kept_reads` would cut it whole.
That is a behaviour guard, not a micro-optimisation; NOT built here (one-shot;
it needs its own pair + gate, and whether a real merge ever holds zero files
should be measured before the guard is trusted).

The only genuinely REPEATED work left is `unseen_reads` wire-hexing at 252 ms;
`view_stands`' 1.0 s is one judgment per distinct view, not a repeat.
**VERDICT: the residual's repeat is <1 s (diminishing returns); the single
largest remaining item is a 3.3 s guard opportunity, reported not built.**

### (2) Un-stack branch `ran-by-memo-main` — rebased CLEAN, no PR opened

`git checkout -b ran-by-memo-main origin/main` (`b3424dd4`, batch #13) then
`git cherry-pick 98fef145 e9818e91 ec2eae30` — **no conflicts**. patch-ids are
unchanged vs the originals, so no semantic drift:
`78831d82…` / `62be6090…` / `d404de42…`. Head
**`945482f81b251b4c0558ea4e3854fd373e727a5c`**, pushed to
`origin/ran-by-memo-main`. NO PR opened (a PR now would overlap #751's first
commit); #751 and #755 left untouched; #744 is already CLOSED.

**BLOCKER for the stated plan:** #751 cannot land as-is. Its `gate` and
`keepers-a` checks are RED on `fmt-lossless` at
`packages/std-avrac/src/compiler/kept_settle.av`
("fmt --check: 4 examined, 1 differing"). The re-wrap lives in `ec2eae30` and is
therefore ON `ran-by-memo-main` — that branch is fmt-clean. So the lead can:
(a) arm `ran-by-memo-main` directly as the single topic (it carries read-dedupe +
ran_by + view_stands + the fmt fix), or (b) refresh #751 with the re-wrap, land
it, then rebase `ran-by-memo-main` onto the new main (its first commit becomes a
no-op).

### (3) Gate — FINAL sha `945482f8`, Sprite `avra-sgate`, run `ak82_1791953320`

Built from the committed tree (working tree clean), compiler `52b0744dd9ef`:

- `make avra` exit 0 (105 s).
- `avra fmt --check` (5 changed files) exit 0:
  `fmt --check: 5 examined, 0 differing, 0 refused`.
- `make cache-attacks` exit 0, `FAIL count: 0`; last line
  `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`.
- `avra test packages/std-avrac` exit 0: **`8851/8851 tests passed`** (the task
  said 8850; batch #13 landed on the base and added one case — 8850 on the older
  base + 1). Last line `1 program proved`.

### (4) shas

- `ran-by-memo-main` (pushed) `945482f81b251b4c0558ea4e3854fd373e727a5c`
  = `origin/main` `b3424dd4` + `a2301ce6` + `64831785` + `945482f8`.
- Originals unchanged: `ran-by-memo` `ec2eae30`, #755 base `settle-literal-fastpath`
  `98fef145`, #751 head `98fef145`.

### (5) blockers / notes

- #751 is fmt-RED (above) — it cannot land without the `ec2eae30` re-wrap; the
  un-stack branch already carries it.
- #755 remains a draft stacked PR, untouched and unarmed.
- The `held == 0` guard (3.3 s in this pair) is the named next slice for the
  residual; I did not build it, per the one-shot scope and because it needs its
  own pair + gate.
- Sprite `avra-sgate` is free (run ended 0).


## Report 14 — THE `held == 0` GUARD IS WRONG: A REAL MERGE HOLDS FILES (slow-gen1, 2026-10-14)

One-shot. Worktree `../avra-lower-regress` (branch `ran-by-memo-main`, HEAD
`945482f8`), Sprite `avra-sgate`. Scripts `tools/_sg_91.sh` +
`tools/_sg_91_builders_after.av` (main's `builders.av`) untracked; the gate
re-ran `tools/_sg_82.sh`. NOTHING PUSHED, nothing armed.

### (1) The real-merge pair: the stood attempt holds 412/470

Report 13's `held 0/470` came from a PERTURBED foreign store (a marker fn
appended to every `packages/**/src/**/*.av`, cold-built, source restored), so
every file's text differed from its record and nothing stood. A real main merge
is not that.

The pair: ONE binary (`work run`'s prep for HEAD `945482f8`, binary
`52b0744dd9ef7ffb`), ONE store. The store was moved aside, `packages/cli` built
to write the PRE-merge store (cold, held 0), then `origin/main`'s REAL
production delta applied to the working tree and the SAME binary rebuilt over
that store. `origin/main` was `edc39f1a`, one commit past the branch's base
`b3424dd4`; its only non-test change is
`packages/std-avrac/src/features/grammar_lit/builders.av` (13+/2−; the other
file is its test, and it is not built by `packages/cli`). No git on the Sprite,
so the delta was applied as file content.

Raw `time:` rows (`sg91_1791955698`):

```
warm/cold (store aside):    held 0/470,   attempt 0, discarded 0   lower 20822ms, analyze 34588ms, parse 24418ms, wall 102s
merge-stale (main's delta): held 412/470, attempt 1, discarded 1   lower  3504ms, analyze  4449ms, parse     7ms, wall  54s
```

So a real main merge HOLDS 412 of 470 files (58 read: the changed file, its
readers, and the run-by closure). The stale build is FASTER than the cold one
(54 s vs 102 s) because 412 files came from the store.

### (2) VERDICT: the guard is wrong — STOP, no code change

`held == 0` requires EVERY file's record to have moved, which is exactly what a
cold store (the warm arm above) or the perturbation produces — never a merge.
Across the real deltas on record the stood attempt holds 4 (report 3/4: main
store vs e3d source, 4/461), 412 (this one), and never 0. A `held == 0` guard at
the top of `ask_kept_reads` would therefore never fire for a real merge and would
cut the 3.3 s only in the perturbed pair Report 13 used to find it. The task's
condition is met — a real merge holds files — so I STOPPED: no guard, no commit,
nothing pushed.

The corollary worth keeping: the +5.7 s residual of Reports 12/13 was measured
on a perturbed (held 0) store; a real small merge holds 412 and its lower is
FASTER than cold. `held 0` is a property of the instrument, not of a lane after
merging main. (A LARGE cross-tree delta, report 3/4, holds 4 and is slow — but 4
> 0, so the proposed guard does not reach it either.)

### (3) Gate on the FINAL sha `945482f8` (unchanged; re-run for first-hand lines)

`tools/_sg_82.sh`, run `ak82_1791956007`, compiler `52b0744dd9ef7ffb`:

- `make avra` exit 0 (112 s).
- `avra fmt --check` (5 changed files) exit 0: `fmt --check: 5 examined, 0 differing, 0 refused`.
- `make cache-attacks` exit 0, `FAIL count: 0`; last line
  `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`.
- `avra test packages/std-avrac` exit 0: `8851/8851 tests passed`; last line
  `1 program proved`.

### (4) sha

No new commit. `ran-by-memo-main` stays
`945482f81b251b4c0558ea4e3854fd373e727a5c`. PR #759 is a draft and unarmed;
#751/#755 untouched.

### (5) blockers / notes

- Available main advanced by one commit (`edc39f1a`) and one production file; a
  larger real merge was not rebuilt here (report 3/4 supply the large-delta
  data point, held 4 > 0). The same script applies any set of main's files.
- The 3.3 s `ran_by` expansion is real work whenever a reached path is held
  (412/470 here); no honest short-circuit exists at that site beyond the dead
  `held == 0` one.
- The Sprite `avra-sgate` is free after the gate (run ended 0).


## Report 15 — WARM UNCHANGED CHECK: WHERE THE ~336 ms GOES, AND A CUT (slow-gen1, 2026-10-14)

One-shot, NEW AXIS (warm unchanged `check packages/cli` toward 60 ms).
Worktree `../avra-lower-regress` (branch `ran-by-memo-main`), Sprite `avra-sgate`.
Scripts `tools/_sg_100..104.sh` untracked. Instrumented runs used temporary
`now_ns()` clocks in `checked`/`program_key`/`source_inputs`, removed before the
commit.

### (1) The warm-unchanged clock — the phase rows do NOT cover it

`check packages/cli --time` on a HIT prints no phase table (`time: check · cache
hit`); `explain --stats --time` DERIVES every time (66–70 s) and is not the warm
path. So the clock is a counted receipt from temporary clocks on the warm path:
`checked()` = `nothing_to_check` + `opened_store` + `program_key` + three store
gets. Warm HIT, five rounds, pre-cut tree (binary `1c3082276da5`):

```
UNC opened_store 0ms
SI covered 20  closure 14ms  engine 0ms  allfiles 35ms  files 1470
PK files 1470  source_inputs 51ms  lines 76ms  objects 1ms  compiler_id 0ms  fold 0ms
UNC program_key 130ms
UNC gets 0ms
UNC total 130ms HIT        (wall ~170 ms)
```

process start is separate: `./avra --help` = **20–24 ms** measured. So the warm
check puts ~40 ms outside `checked` (process + workspace/manifest setup) and
~130 ms inside, and **`program_key` is the whole inside**: walking 20 package
trees (35 ms), decoding the remembered closure (14 ms), then reading+digesting
**1,470 files** (76 ms). Store open and the three `get`s are 0 ms. Files 1,470
for a check that reads 510 (`time: … held 0/510`).

### (2) The cut: a dependency's tests are no input

`source_inputs` (`modules.av`) walked EVERY `.av` under every reached package,
tests included. Only the ROOT package's tests are ever derived, so a dependency's
test tree was 919 files of pure over-cover (grep: no non-test file imports a
`.tests.` module; the only cross-`tests.` imports are std-ui's own tests, kept
because std-ui is the root there). The key now walks the root package whole and
every dependency with `all_files_no_tests` (the walk never descends into `tests/`).

Warm HIT breakdown after (binary `01bda70f6ed3`, `_sg_102`):

```
SI covered 20  closure 15ms  engine 0ms  allfiles 6ms  files 565
PK files 565  source_inputs 22ms  lines 42ms  objects 1ms  compiler_id 0ms  fold 0ms
UNC program_key 66ms
UNC gets 0ms
UNC total 66ms HIT        (wall ~105 ms)
```

| | files | program_key | source_inputs | lines | wall (instrumented) |
|---|--:|--:|--:|--:|--:|
| before | 1470 | 130ms | 51ms (closure 14 + allfiles 35) | 76ms | ~170ms |
| after  | 565  | 66ms  | 22ms (closure 15 + allfiles 6)  | 42ms | ~105ms |

### (3) The speed keeper, quoted (`tools/warm_edit_bench.sh`, same host, same store discipline)

BEFORE (branch HEAD `945482f8`, binary `517e9e2b11fc`):
```
host linux-x86-64-amd-epyc
warm unchanged 171
warm edit 4418
speed: PASS: warm unchanged: 171ms vs ceiling 23789ms (limit 47578ms), goal 60ms
speed: clean — 2 warm scenario(s) within the ticket's ceiling
```
AFTER (sha `a98d8624`, binary `6ee309eed233`):
```
host linux-x86-64-amd-epyc
warm unchanged 114
warm edit 4310
speed: PASS: warm unchanged: 114ms vs ceiling 23789ms (limit 47578ms), goal 60ms
speed: clean — 2 warm scenario(s) within the ticket's ceiling
```

`warm unchanged` **171 → 114 ms** (same script, same Sprite). The CI runner's
ceiling is the budget's `ci-warm warm unchanged 314` (the owner read 336). `warm
edit` barely moves (4418 → 4310 ms): the key is a small share of an edit's cost,
which is the discarded attempt / derivation (this lane's other axis), not the key.

### (4) Gate — final sha `a98d8624`, clean tree (instrumentation removed), run `tsg_1791959850`

- `make avra` exit 0 (~105 s); binary `6ee309eed233`.
- `avra fmt --check packages/std-avrac/src/compiler/modules.av` exit 0:
  `fmt --check: 1 examined, 0 differing, 0 refused`.
- `make cache-attacks` exit 0, `FAIL count: 0`; last line
  `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`.
- `avra test packages/std-avrac` exit 0: **`8851/8851 tests passed`**; last line
  `1 program proved`.
- warm unchanged rounds on the clean tree: `76774 / 138 / 129 / 133 / 131 ms`
  (round 1 cold: the suite store held no `check` verdict for this print).

### (5) Where the floor is

After the cut the warm path is: **~40 ms fixed** (20–24 ms process, ~16 ms
workspace/manifest setup) + **~66 ms `program_key`** = closure decode 15, walk 6,
read+hash 565 files 42, fold/objects 1. The per-file read+hash is the design's D9
(sources are always read and hashed, no stat-trust) and the key's remaining INPUT
SET is A16's hand format 4, deleted by **DB 08**. So the next cut is the DB
design's own: the check verdict as a ROOT whose validity is its **recorded read
list** (DB 06/07/08) — 510 reads, no tree walk, no closure decode. That, plus the
DB 05 store split for the fixed half, is what carries 114 ms on toward 60; nothing
in `program_key` itself is ours to micro-optimise.

### (6) sha / blockers

- `a98d86243efaa5fc4920a9212842f50c6ca7e1b8` on `ran-by-memo-main` (pushed; one
  file, `modules.av`, +19/−5), DRAFT PR **#759** (base main, `autoMergeRequest`
  null — NOT armed).
- BLOCKER / call for the lead: #759 is now TWO topics — the read-path commits
  (Reports 11–14) and this key-granularity cut. They are independent (this one
  touches only `modules.av`); recommend the lead move `a98d8624` to its own PR
  (cherry-pick onto main is clean) or land the read path first. I did not split
  it, per the lane's one-branch brief.
- The cut's soundness rests on "no non-test file reads a dependency's test" —
  grepped true across the tree today; the DB read-list (DB 07/08) makes it
  structural rather than greppable.

## 2026-10-14 — the warm-key split lands: two branches, two draft PRs

### (1) Branches, heads, PRs

- `warm-key-cut` = `5e34f6b4f54357b312fa685465b38302a6118742` — off `origin/main`
  (`98a3c688`), a cherry-pick of `a98d8624` — DRAFT PR **#762** (base main, NOT
  armed):
  "program_key: dependencies walk without their tests, so the unchanged check
  reads 565 files not 1470 (warm unchanged 171 → 114 ms)".
  `gh pr diff 762 --name-only` = `packages/std-avrac/src/compiler/modules.av` only.
- `ran-by-memo-main` = `945482f81b251b4c0558ea4e3854fd373e727a5c` — the READ PATH
  ALONE (`a2301ce6`, `64831785`, `945482f8`), force-pushed — DRAFT PR **#759**
  retitled:
  "read path: a verdict's reads are asked once, a read's expansion and a view's
  standing memoized per attempt".
  `gh pr diff 759 --name-only` = `interface.av`, `kept_settle.av`,
  `tests/run_reads_test.av`, `workspace.av`, `workspace_analysis.av`.
- `origin/ran-by-memo-main` and `origin/warm-key-cut` equal their local heads
  above.

### (2) range-diff / patch-id proof

`git range-diff b3424dd4..a98d8624 b3424dd4..945482f8` (#759 before vs after):

```
1:  a2301ce6 = 1:  a2301ce6 settle: a reader's reads are deduped once per read…
2:  64831785 = 2:  64831785 settle: a read's expansion is memoized per attempt…
3:  945482f8 = 3:  945482f8 settle: a kept view's standing is memoized per attempt…
4:  a98d8624 < -:  -------- perf: a program's key covers a dependency's sources…
```

`git range-diff a98d8624~1..a98d8624 5e34f6b4~1..5e34f6b4` (the split):

```
1:  a98d8624 = 1:  5e34f6b4 perf: a program's key covers a dependency's sources, never its tests
```

The patched change is identical: `git diff a98d8624 5e34f6b4 -- packages/std-avrac/src/compiler/modules.av`
is empty, and both patch-ids are `69da90a76038ab9b8d13581683509662b03b7cf6`. Nothing lost.

### (3) Warm receipt + gate last-lines (Sprite `avra-sgate`, `build/avra` binary `7cedc8c46c64`)

- `sh tools/warm_edit_bench.sh` (warm-key-cut compiler): host
  `linux-x86-64-amd-epyc`; **`warm unchanged 120`**, `warm edit 4204`;
  `speed: clean — 2 warm scenario(s) within the ticket's ceiling`.
- `make cache-attacks`: **0 failed** across every section —
  `cache-attacks: 433 builds through one store, 140 under a hold, 0 failed`;
  `link-cache-attack: 13 builds through one store, 0 failed`;
  `turn-memory-attack: cold peak 67 MB, 12 turned attempts peaked at 72 MB under a 201 MB ceiling, 0 failed`;
  `gathered-cache-attack: 7 runs through one store, 0 failed`;
  `store-reads-attack: 8 steps passed`;
  `cancel cache attack: 11 step(s), 0 failed, 2 file(s) inspected`.
- `./avra test packages/std-avrac`: **`8889/8889 tests passed`**, status 0
  (`watch: peak 939 MB, status 0`; `sprite-run: ended 0`). 8851 was the count on
  the older base; current main carries more.

### (4) Comments checked (coherence)

`a98d8624`'s two added comments state the invariant, not a symptom, and match the
code: `all_files_no_tests` skips only a directory named `tests` and is used only
for non-root packages; `source_inputs` walks `all_files(root_src)` whole (root
first, `packages()[0]`) plus deps without their tests. No overstatement.

### (5) Blockers

- None for the split or the receipts.
- Note for the record: `gh pr edit` refused this token with `missing required
  scopes [read:project]`, so both bodies were corrected with `gh api … PATCH`;
  titles set the same way. `gh pr create` itself worked.

## Report 16 — PR #759 `nullable.repeated_unwrap` FIXED, RE-GATED, PUSHED (slow-gen1, 2026-10-14)

### The fix
PR #759's `gate` job refused one NEW idiom:
`packages/std-avrac/src/compiler/kept_settle.av  [nullable.repeated_unwrap]`.
The rule (`features/nullable/idioms.av`) refuses a plain `let` LOCAL forced open
(`!`) three or more times within its own declaration; `view_stands` forced
`known` three times in one short-circuit condition. The rule's own words —
guard once, bind once, read the name — give:

    let known = self.hold.view_standing.get().get(r[1])
    if known != null {
        let stood = known!
        if stood.files == files && stood.asks == asks { return stood.stands }
    }

Semantically identical (`known!` is reached only when `known != null`): one
force on `known`, none on `stood`. Baseline untouched.

### Gate last-lines (Sprite `avra-sgate`, worktree `../avra-lower-regress`)
- base `origin/main` `09c9c7d3`; branch tip `8b0be185` (main IS an ancestor of the
  branch — no rebase owed); fix commit `e3cf09339`. Changed `.av` vs
  `origin/main`: `interface.av`, `kept_settle.av`, `tests/run_reads_test.av`,
  `workspace.av`, `workspace_analysis.av`. Affected closure = EVERY package (the
  compiler changed), so the gate ran the whole idiom sweep.
- `gate_changed --files … --packages … --no-keepers --pr-minimum` (the PR gate's
  own shape; no git on the Sprite, so files/packages were computed locally):
  **exit 0** — `gate_changed: clean — changed .av and affected idioms hold`.
  The two `repeated_unwrap` lines left in its output are PRE-EXISTING baseline
  sites (`std-net/src/tests/net/net.av:23`, `net_sizes.av:24`); the `kept_settle`
  site is gone.
- `make -s keepers-static`: **exit 0 run LOCALLY** (`watch: peak 492 MB, status 0`;
  `fetch_compiler: self-test clean — 12 case(s)`). On the Sprite it exits 2 for ONE
  environmental reason: the synced tree has no `.git`, so
  `fetch_compiler.sh --self-test`'s four git cases fail (`no git repository here`).
  The GitHub `keepers-static` job runs on a checkout and passed on the previous
  head; this change touches neither `tools/fetch_compiler.sh` nor
  `tools/pr_watcher.py`.
- `make cache-attacks`: **exit 0, `FAIL count: 0`** (`store-seal`, `small/medium/large`,
  `store-index`, `cancel cache attack: 11 step(s), 0 failed`).
- `avra test packages/std-avrac`: **exit 0, `8910/8910 tests passed`** (includes
  `tests/run_reads_test.av`, the read path's own).
- `avra fmt --check` on the 5 changed files: **exit 0**, `fmt --check: 5 examined,
  0 differing, 0 refused`.
- Sprite run: `sprite-run: ended 0; the Sprite's available memory was never under
  3242 MB`; `work: avra-sgate — passed, 2492s`.

### Read-path receipt
NOT re-measured. The stale-lower pair needs the perturbed-store fixture (~40 min:
perturb every src, cold-build, restore, stale vs cold with the clocked binary).
The fix is a source-level control-flow restructure with identical semantics — it
moves no memo key, no cache key and no store row — so the receipt cannot move;
`8910/8910` on std-avrac (read-path tests included) is the functional receipt.

### Push
Fast-forward (no rewrite): `8b0be185..e3cf09339  HEAD -> ran-by-memo-main`. New
head sha **`e3cf09339363c7e38ad170ead0223d86640f8d6f`**. Auto-merge still armed
(`enabledAt 2026-10-14T14:46:16Z`); a new `checks` run (`38596770876`) is queued.

### Blockers
None. The Sprite `keepers-static` no-git failure is environmental; it is green
locally and the CI job has a checkout.


# Finishing the hold deletion — state and plan (2026-11-04)

## Where the work stands

Base: `origin/hold-out` **c7c6feb8**. The hold is CUT — nothing is held — and the
saved answers that replace it are partly in.

| landed on hold-out | what |
|---|---|
| 0fea5d75 / 4bb070a0 | `Attempt.hold`, the holding block, `is_held`/`hold_only` and every held branch deleted (−906/+90, 31 files) |
| 215eef3b | nothing mints from a record: listed-mint hook, `load_interface`, `decl_row_filled`, row fills, restored refs (−273) |
| 89515bae / 26a14e5d | a declaration's signing is a saved `@query` (`signed`), asked once per signing |
| 65b3f9a6 | `parse_said`'s parse is made unheard, so its record names only source and block words |
| 3b06bacb | `@lasting`; `text_digest_of` and `module_listed` are saved answers (10k/25k reuses) |
| c7c6feb8 | `Visible` is a saved `@query`; a query's key is labelled by the seat's id kind |

**Numbers at 4bb070a0 (L-hold, `check packages/cli`, local):** unchanged **0.20 s**
(goal ≤60 ms · met), one-edit **117 s** (goal ≤300 ms). Restores: `parse_said`
80 reuse / 274 asks, `file_said` 0 / 194. Leaf misses by kind: `Syntax` 17111,
`Names` 13983, `Visible` 47 (paid at c7c6feb8), `Writes` 45, `marks_of` 17,
`ConstTyped` 9.

**Why an edit is 117 s.** The hold answered "may this file's answers stand?".
With it gone every file is read and every answer that never became a saved
answer recomputes — per-declaration syntax fingerprints and per-module names
above all — and `unheard` still leaks leaves, so `parse_said`/`file_said` do
not restore at all. Speed and deleting the hold are the same work.

## Work in flight at the cut (uncommitted or unpushed)

| worktree | branch / sha | state | piece |
|---|---|---|---|
| `avra-L-hold` | `cut-hold-2` 215eef3b | dirty: kernel `outers`, `words_print`, qtrace debug | **P1** the `unheard` fix |
| `avra-L-driver` | `L-syntax` 215eef3b | dirty, complete | **P2** `Syntax` → `@query` |
| `avra-L-driver2` | `L-driver2` 6cef1c6f | clean, 5 commits, untested | **P4** lowering deletions (`Lowered` @query, asks/codes rows, stubs) |
| avra-speed2 | `L-typed-names` 9c466570 | dirty | **P3** `module_exports` saved answer |
| avra-names | `s-names` de7660f3 | dirty + 2 new files | **P3** `module_names` @codec + `resolve_said` |
| avra-const | 35c71178 | dirty | **P5** `ConstTyped` @query, `const_floor` test |
| avra-answers | `L-typed-carried` f10871c2 | staged | `@lasting` (superseded by 3b06bacb) |

## Plan — one piece at a time, each gated on hold-out

| # | piece | proof |
|---|---|---|
| P1 | the `unheard` fix: `Kernel`'s reader stack restores the OUTER reader, so a nested ask closed inside `unheard` hands back "no frame" and no leaf leaks | `parse_said_test` 3/3, `file_said` restores > 0 |
| P2 | `Syntax` is a lasting `@query` (`syntax_in`), family deleted | compiler suite; warm trace `Syntax` misses 0 |
| P3 | `module_names` a saved answer + `resolve_said` | compiler suite; warm trace `Names` misses → 0 |
| P4 | `Lowered` a lasting `@query`; asks/codes rows, `held_okey`/`held_objects`, stubs deleted | compiler suite + cache_attacks |
| P5 | `ConstTyped` a `@query`; `Settled` a named saved answer; **`kept_settle.av` deleted** | compiler suite + const_floor |
| P6 | hold leftovers: `record.av`'s writer side and interface digests, `held_paths`, the `Hold` struct fields, `compiler/db.av` | 0 hold/held mentions in `compiler/`; suite + cache_attacks |
| P7 | the hold-out gate, then land on hd-clean → main; close branches | `sh tools/work land`, green |

Done means (from `GOAL_2026_10_30.md`): unchanged ≤60 ms (met), one-edit ≤300 ms,
build-after-edit ≤500 ms, `std-avrac` edit ≤600 ms, 0 hold/held in `compiler/`,
`kept_settle.av`/`verify_held.av`/`compiler/db.av` gone (verify_held is already
deleted), `@family` → 0, and every branch/worktree/PR landed or closed.

## Mechanics

- Build: `cp <hold-out product> build/avra`, then `make try` (one generation per
  build; a tree the standing binary cannot READ needs the hold-out product).
  The product at the base is `avra-ho/build/avra` (c7c6feb8).
- Every heavy step under `sh tools/watch.sh <cap_mb> …`, `AVRA_BUILD_SLOTS=1`.
- Unit proof: `./avra test <dir|file>`; whole proof: `sh tools/cache_attacks.sh`.
- Measure: `sh tools/db_measure/warm_edit.sh 1` (clears stores, cold, then one edit).
- A lane pushes its own branch; the lead integrates onto `hold-out` and verifies
  there, so no two lanes write the base at once.

## Measured baseline (lead, 2026-11-04, base c7c6feb8, `check packages/cli`, clean store)

| run | wall | the compiler's own phases |
|---|---|---|
| cold | **80.4 s** | ast 8.1, parse 9.8, resolve 7.0, sigs 4.4, bodies 16.9, analyze 38.0, lower 24.3, keep 10.8 |
| unchanged | **206 ms** (`cache hit`; inputs 126 ms, judge 147 ms) | goal ≤60 ms |
| one body edit | **58.1 s** | sublang 0.8, ast 6.3, parse 8.0, resolve 7.6, sigs 3.1, bodies 15.4, analyze 34.2, lower 13.1, keep 9.1 |

`held 0/583` on both runs. The edit is 194× the 300 ms goal, and the hold is already
gone — what stands in the way is restores, exactly as the goal says.

## P6 — what is left of the hold, in deletion order (from L-hold's own list)

| # | what | blocker before it can go |
|---|---|---|
| 1 | `held_paths()` (record.av:2218, always `[]`) and its eight call sites' loops (workspace_analysis 507/598, build.av 882, derive.av 341/628/728/808) | none — the loops are dead once it answers `[]` |
| 2 | `record.av`'s writer side — `record_of`, `keep_interfaces`, `keep_uses`, `keep_asks`, `keep_codes`, `keep_unit_rows`, `keep_instances`, the interface digests — and `references.av`'s held-`ref` cluster (`held_sources`, `held_refs_to`, `held_target`, `kept_refs`) | the saved answers that replace what the records cache: `file_said`, `sig_said`, `parse_said`, `resolve_said`, `Parsed`, `Typed`, `Sig` (P1–P3) |
| 3 | `kept_settle.av` (903 lines) with the `Settled` saved answer | P5 |
| 4 | the `Hold` struct's ~45 fields, field by field to a fixpoint (workspace.av:340, `new_hold`) | 1–3 |
| 5 | `compiler/db.av` (627 lines) — the dense `Db`/`DbRow`/`DbKind` registry | `@family` → 0 (the DB 12 epic), not the hold alone |

### P6 item 2 is bigger and easier than it looked

`record.av`'s whole READING chain is already unreachable on the base: `load_named`
(record.av:761) is called only by `load_imports` (828) and `load_gathered` (839, 874),
and nothing outside `record.av` calls either — the cut deleted `load_interface`, their
entry point, and left the children standing. So the record writers
(`keep_interfaces`, `record_known`, the exact-row fills) write rows nothing reads, and
`keep` costs ~9–10 s of every build and every edit. The deletion is mechanical:
`load_named`/`load_imports`/`load_gathered`, the writer side, the `records` cells, then
`record_cached`/`record_places`/`record_lines`/`record_fields` once their three readers
(`producers.av:454`, `interface.av:246`, `derive.av`'s `edit_print`) answer otherwise.

`held_paths()` (record.av:2218) already answers `[]`; its eight call sites' loops
(workspace_analysis 507/598, build.av 882, derive.av 341/628/728/808) are dead.

## After the restores: the driver slices (why 300 ms needs more than P1–P5)

`WARM_PATH.md`'s measurement is the law here: the cost is PER-FILE WORK — a call per
file in each phase — so removing leaf recomputation alone leaves seconds, not 300 ms.
The unchanged run's floor is already 206 ms (inputs 126 ms staging every file's text,
judge 147 ms), and an edit re-enters `admit_all`/`analysis`/`lower` for the whole
program. The three driver slices are un-started:

1. rows stand → ROOT asks: `holding()` stops walking every module/file; the run is
   `diagnostics(f)` per file of the entry's program + `linked(entry)`, and an answer
   whose reads stand is not asked at all.
2. per-root admit/analyze: declarations of unread files are minted on first read.
3. lazy `bare_interface`: no `bare_interface` phase over every module.

Plus `package_digest(p)` (one digest per package over its listing + file digests, a
durability-HIGH revision), which is what takes the unchanged run's 126 ms to ~20 ms.

## The witness is stale: cache_attacks fails 92 times on the base

`sh tools/cache_attacks.sh` on c7c6feb8: **529 builds through one store, 92 failed**
(the old count line still says "8 under a hold"). Triage of the 94 FAIL lines:

| kind | count | what it is |
|---|---|---|
| expected output wrong | 40 | `ur` (18: "a body edit lowers that body alone / alpha was lowered afresh" — unit-level reuse, P4's subject) and `kg` (8: a collect's member added) |
| cost claim: lowering | 15 | same `ur` family — the lowering is redone for a whole file where a unit's answer should stand |
| read-list claim | 13 | `nd`/`tw`/`lm`/`go`/`gc` — assertions phrased in the hold's own words ("was not read", "stays held") |
| other | 15 | hold-era claims: `hs` "the held set was not read", `zp` "a body edit held nothing ... the parse count attacks nothing", `rx` "a derivation held nothing", `sl` seal records, `abw` "the check was not a cache hit" |
| engines disagree | 4 | `kg`: native `a=0 r=0 c=0` vs eval `a=0 r=1 c=0` — a REAL wrong answer |
| did not build / defect | 2 | `dt`: "a source text was read before the workspace staged it" (the compiler's own defect voice); "a library check after an app's build speaks otherwise than a cold one" |

So two jobs, in this order:
1. **P7a — port the harness** (harvest PR #1303, `origin/cache-port` e3f66d8b + ab6ae263:
   "hold bookkeeping becomes cost claims — parses and settles, never attempts or held
   counts", plus `check --counts` reporting `cas_bytes_read`). A claim about a mechanism
   that no longer exists is not a witness; it is a stale assertion that reads as a defect.
2. **P7b — fix the defects the ported harness still reports**: `kg`'s native/eval
   disagreement first (a wrong answer), then `dt`'s staged-text defect, then the
   library-vs-app divergence, then the `ur`/`nd` cost and read-list claims the port
   re-expresses.

## Progress (2026-11-04, second session)

| piece | state | proof |
|---|---|---|
| `vocab` keeper red (named `fill_shape`, deleted with the record fills) | **on `L-record`** | `make keepers-static` green |
| **P6.1** record's loading walk (`load_named`, `load_imports`, `load_gathered`, `meet_file`, `read_why`, `import_stands`, `gathered_files`) | **on `L-record`** (−190 net) | suite 1820/1822, same two reds |
| **P6.2** the held-reference cluster (`refs_into`, `held_sources`, `refs_of_source`, `held_refs_to`, `held_target`, `kept_ref_rows`, `resolved_ref`, `file_stands`), its `arm_held_refs` hook and two `Hold` cells | **on `L-record`** (−75 net) | suite 1820/1822, same two reds |
| **P5** `ConstTyped` → lasting `@query`; family, verifier, `DbRow/DbKind`, `Decls.const_types` deleted; one writer (`TypeFacts.const_types`) | **`L-typed-const` 902ccc94**, merged in the integration tree | 1762/1764 on `compiler/tests` (base 1753/1764), same two reds; `const_floor` `6 7 a-b-c5`; `@family` 19→17 |
| **P2** `Syntax` → `@query` (`L-syntax` caf26c37) | **NOT landable** | edit 58.1 → 35.0 s but the first post-cold edit FAILS `type.match … found TomlValue`; base+record-slice is clean at 62.0 s |
| **P3** `Names` → `@query` (`L-names` 28308899) | **NOT landable** | `names_family_test` 4/4 but checking `features/expr_spine/type_lit.av` reports `defect: a method find on a nameless receiver <error> survived typing` → `register r69 defines out of mint order`; base checks that file clean |

### Measured (isolated `AVRA_CACHE_DIR`, clean tree store, `check packages/cli`)

| tree | cold | unchanged | one edit |
|---|---|---|---|
| base c7c6feb8 | 80.4 s | 206 ms | 58.1 s (clean) |
| base + P6.1+P6.2 (`L-record`) | 72.6 s | 316 ms | 62.0 s (clean) |
| base + P5 `ConstTyped` | 81.4 s | 239 ms | 73.0 s (clean) |
| base + P2 `Syntax` | 73.5 s | 156 ms | **35.0 s (WRONG ANSWER)** |

### The blocker now, in one sentence

Both remaining conversions halve or better the edit's cost and both make a *restored* answer silently wrong in typing — the deleted `<family>_verified` was not only a check: its `touch(...)` materialised what the verifier read, and the `@query` that replaced it records only the leaves its body reads.

### Lane facts worth keeping

- `AVRA_SOUND_CHECK=1` is REQUIRED for `avra test` on this tree (without it, `defect: a source text was read before the workspace staged it` fires after ~30 suites) and it is PRE-EXISTING on the base.
- The shared `$HOME/.avra/cache` is polluted across lanes; a per-lane `AVRA_CACHE_DIR` is the difference between that defect and a clean run. Every measurement needs one.
- `tools/cache_attacks.sh` is 92-failed on the base (list: `/tmp/base_attack_fails.txt`); the port is PR #1303 (`origin/cache-port` e3f66d8b/ab6ae263: hold bookkeeping → cost claims from `check --counts` + `Q parse` trace lines).

## P1 proven (integration tree `avra-ho`, merge 8b94ccdd)

- `parse_said_test.av:53` ("a second process restores it without parsing") is **GREEN**.
- Compiler suite: **1821/1822** — only `decl_grain_test.av:189` stands (the whole-program
  `refs_index` read; its own ticket: per-file refs answers).
- So the warm path now has: nothing held, `parse_said` restores, `ConstTyped` a saved query,
  and the hold's record-loading walk + held-reference cluster deleted.

Remaining red on the tree: `decl_grain_test.av:189` (refs projection), and the two big
conversion pieces are blocked on one wrong-answer bug (a restored `Sig` losing an enum's
variants: `TomlValue has no static fn Bool`), which the engine lane owns.

**Timing caveat:** single warm runs under a loaded machine swing 58–85 s for the same tree.
Numbers only count when the machine is quiet and the run is repeated; the only large effect
measured so far is `Syntax` (58 → 35 s) and it is not correct yet.

## Integration state at the end of the second session

`avra-ho` (branch `ho-base`, merged `908e615` line → pushed as `hold-integrated` earlier, re-pushed below):

pieces in, in this order — `vocab` keeper fix, `L-typed-const` (ConstTyped), `L-hold-unheard`
(kernel `outers`, places-as-offsets, the cycle/placeholder signing fix), `L-record`
(P6.1 record loader + P6.2 held references), `L-driver2` (Syntax + the six-commit lowering stack).

- build: green.
- suite: **1818/1820**, reds = `decl_grain_test.av:189` (known, refs projection) and
  **`check_every_test.av:16` (NEW)** — "a reached body speaks under both".
- **bisected**: the same test is 3/3 on `avra-hd-rec` (base + P6.1 + P6.2), so the new red is
  NOT the record deletion. It arrived with ConstTyped or the `unheard`/offsets fix or the
  lowering stack; the narrowing command is one file, ~40 s:
  `./build/avra-try test packages/std-avrac/src/compiler/tests/check_every_test.av`
  on a tree built at `ab4119cf`+ConstTyped, then +P1, then +L-driver2.
- warm path (one comment edit after a cold run, isolated store): **0 errors** on the merged
  tree, i.e. the `TomlValue` wrong answer is gone with the signing fix.

Next after this red is cleared: merge onto `hold-out`, quiet-machine measurement, then P6.3
(`held_paths` + its eight dead loops + the `Hold` struct's fields, now unblocked because the
lowering lane deleted the asks/codes rows), then the `@family` sweep (16 left) that lets
`compiler/db.av` die, then the hold-out gate and the landing.

## Correction, 2026-11-04 (third session): the signing fix was never in the tree

`avra-ho` at `6e45022f` did NOT contain `f03ce906` ("a cycle's answer is not a signing").
The re-pushed `hold-integrated` was built from a ref that stopped at `fc6e1cf6`, so the
`TomlValue` wrong answer this ledger reported as fixed was live the whole time — and the
"0 errors" line above was a reading of a store that could not have shown it. Measured, not
read: `908d9341` (the tree the claim was made on) yields the same **15 errors** on the first
edited warm check.

Two fixes now in `hold-integrated` = **`4de44a4e`**:

- `70a9213e` — a settlement's refusal speaks once in each LOWERING PASS, never once per
  workspace. The cached `Unsettled.Spoken` collapse outlived its pass, so a second lowering
  of the same program in one workspace (`check`, then `check_every`) found the cached
  refusal, stayed silent and kept a unit that had spoken nothing. Cleared by
  `spoken_settles` where a lowering pass begins. `check_every_test.av` 3/3.
- `4de44a4e` — merge of `f03ce906`.

State on `4de44a4e`, quiet machine, isolated store (`check --time packages/cli`):
cold **105.8 s**, unchanged **209 ms**, one comment edit **99.5 s** (status 0, 0 errors).
Suite **1819/1820**, the only red `decl_grain_test.av:189`.

Where the edit's 99.5 s goes: `analyze 34.9 s`, `lower 49.1 s` (cold: analyze 36.0, lower 52.5).
Lowering is the whole gap — restored units are not restoring, and the dominant leaf miss is
`Names` (~14k), which is still a dense verified family. `L-names` (`28308899`) is being
re-ported on top of `4de44a4e` now that its blocking defect (the signing cycle) is merged.

Disk: 100% used, ~6.8 GiB free. Lane caches are disposable; `df` breathes by gigabytes with
nothing deleted (macOS swap), so one reading is not a decision.

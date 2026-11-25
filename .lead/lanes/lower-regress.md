
## 2026-10-12 — counters on the verdict walks (main 91eba563), one cold check, gen-2 probe build

- `names_digest` calls: 583 (~ one per settlement). Modules walked by `module_decl_names`: 25,563 (~44 per digest).
- `file_decl_names` calls: 107,219; declarations walked (`decls_of_file` length, summed): 3,837,037.
- `outline_values` calls: 100,204; declarations walked (summed): 3,516,571.
- Total declaration walks from the two verdict paths: ~7.35 M, each with `decl(d)` reads (`.name`/`.kind` twice in the comprehensions).
- Counters were temporary `eprintln` probes; reverted. Build was `make avra` (probe build), not a bootstrap; the numbers are counts, not times.

## 2026-10-12 — the verdict-walk memos, each measured alone (main 91eba563, gen-2, spent.py, held 0/N)

Base (main 91eba563), not re-measured this round: lower ~76–78 s, keep ~48 s, analyze ~33–36 s, wall ~158–163 s (earlier rounds on the same base).

- `outline_values` memoised per path on the hold: wall 167.4 s / 162.8 s; lower 77.2 s / 77.9 s; keep 53.0 s / 47.1 s; analyze 36.5 s / 36.6 s. cache-attacks: 0 failed (346 builds).
- `module_decl_names` memoised per module on the hold: wall 169.0 s / 164.6 s; lower 80.8 s / 79.0 s; keep 50.3 s / 46.7 s; analyze 36.9 s / 38.0 s. cache-attacks: 0 failed (346 builds).

Reading: neither memo moves lower; the ~7.35 M declaration walks from the verdict paths are not what costs time. Probe counts from the earlier run stand (names_digest 583, module_decl_names 25,563 module walks, file_decl_names 107,219 files / 3,837,037 decl walks, outline_values 100,204 calls / 3,516,571 decl walks).

## 2026-10-12T17:26Z — phase table across the bisect points (from logs already on disk; no new runs)

Times in ms unless marked s. Each row is one cold gen-2 `check packages/cli --time` from the bisect (held 0/~492). Phase names as the `time:` line prints them.

| commit | ast | parse | resolve | sigs | bodies | analyze | lower | keep | wall |
|---|---|---|---|---|---|---|---|---|---|
| 05fe643 (good) | 16674 | 19072 | 1565 | 1273 | 4540 | 26452 | 14006 | 6568 | 51 s |
| b8052344 (good) | 19032 | 21755 | 1682 | 961 | 5115 | 29515 | 15417 | 8142 | 53 s |
| 8fb7c9d0 (good) | 20013 | 22845 | 1876 | 1066 | 6142 | 31932 | 17081 | 73339 | 123 s |
| 5ef795a0 (good) | 20135 | 22943 | 2393 | 530 | 6027 | 31896 | 21517 | 81807 | 136 s |
| bfdb6199 (good) | 20355 | 23234 | 2528 | 577 | 6143 | 32484 | 22369 | 82504 | 138 s |
| 107bde7e (good) | 19626 | 22337 | 2448 | 566 | 5601 | 30954 | 21298 | 82827 | 136 s |
| 64c9b364 (good) | 19400 | 22142 | 2322 | 519 | 5737 | 30723 | 22455 | 82767 | 137 s |
| 8f5eb9e1 (bad, #492) | 19815 | 22569 | 4069 | 3139 | 6864 | 36643 | 329009 | 84212 | 450 s |
| 06040202 (bad) | 18611 | 21247 | 4082 | 3049 | 7031 | 35411 | 319201 | 81741 | 438 s |
| 1ddf3440 (main, first cold run) | 19610 | 22550 | 4008 | 459 | 5850 | 32870 | 183414 | 44103 | 261 s |

Reading:
- The second regression (wall 53 s -> 123 s) sits between **b8052344 and 8fb7c9d0**, and it is **keep**: 8142 -> 73339 ms (+65 s). Every other phase at 8fb7c9d0 is within 1–2 s of b8052344. Lower is flat there (15 -> 17 s).
- Wall 123 -> 136 s between 8fb7c9d0 and 5ef795a0 is lower (+4 s) plus keep (+8 s).
- **keep stays at 73–84 s from 8fb7c9d0 onward**, so keep is a second regression with its first bad commit in the b8052344..8fb7c9d0 range. That range was not bisected (the bisect only took the lower > 60 s criterion). Its commits are 8fb7c9d0's parent chain between those two points.
- The #492 step (8f5eb9e1) is lower 21 s -> 329 s (+308 s); keep is unchanged by it (82.8 -> 84.2 s), and resolve, sigs and analyze rise by 1.5–3 s each.
- Main (1ddf3440) lower 183 s, keep 44 s: keep *fell* from ~84 s back to 44 s somewhere between 06040202 and main. Not bisected: this is inferred from two points, and the commit that fixed it is not identified.
- 17:37Z keep-bisect: 08849d93 keep 9.7 s, held 0/490, wall 59 s — GOOD. Range 08849d93..8fb7c9d0.
- 17:46Z keep-bisect: e110d897 keep 74.5 s, held 0/492, wall 126 s — BAD. Range 08849d93 (good) .. e110d897 (bad).
- 17:53Z keep-bisect: cd37644d keep 9.5 s, held 0/492, wall 58 s — GOOD. Range cd37644d (good) .. e110d897 (bad): 757d4a01, 8fdc9037, e8f72f8e, e110d897.
- 18:01Z keep-bisect: 8fdc9037 keep 76.4 s, held 0/492, wall 127 s — BAD. Range cd37644d (good) .. 8fdc9037 (bad): 757d4a01, 8fdc9037.
- 18:11Z keep-bisect: 757d4a01 keep 78.2 s, held 0/492, wall 131 s — BAD. Parent cd37644d good. FIRST BAD (keep): 757d4a01 (#443 code hash: a type is hashed by its shape). code_facts calls the UNCACHED type_shape per distinct TypeId per call. Main repairs this site in 5ef6c8ae (#503, type_shape_cached in code_facts) — partial repair.
- 18:28Z keep qtrace, cd37644d (good, keep 9.5 s) vs 757d4a01 (bad, keep 78 s), same input, gen-2: family compute counts are equal within 0.1% (Typed 15046 vs 15050, Lowered 13552 vs 13556, Settled 543 both, TOTAL compute 36555 vs 36563); reuse counts equal within 0.1% (TOTAL 681872 vs 682061). So 757d4a01 adds per-computation cost, not more computations.
- Mechanism (from the diff): 757d4a01's `code_facts` (lower/code_hash.av) computes each type's shape with the UNCACHED `type_shape` once per distinct TypeId per call; `code_facts` runs per kept code/instance. The same uncached walk was the lower regression fixed in #492-follow-up (#602). Main's keep (44 s) already has the partial repair of this site from 5ef6c8ae (#503: top-level shape cached per TypeId build-wide).
- Next (not run): keep at main (44 s) vs 9.5 s good parent — remaining difference not yet attributed.
- 18:29Z keep bisect stopped at lead's direction (nodes-shape-defaults takes it over; first bad 757d4a01 confirmed by them). Now: per-function census differential, 64c9b364 vs main 216f3c10, and type_shape_cached hit/miss.

## 2026-10-12T19:16Z — per-function census differential, good 64c9b364 vs main 216f3c10 (same input, census.sh, retain counts)

Census tool note: the census attributes each retain to the **function whose body performs it** (the performing site), not to its callers. It has no caller table, so the per-caller answer comes from probes (below), not from the census.

| function (performing) | 64c9b364 (good) | 216f3c10 (main) | ratio main/good |
|---|---|---|---|
| `Workspace.ran_by` | < 24 M (not in good's top 12) | 126.2 M | >= 5x |
| `Decls.decl` | 83.4 M | 97.2 M | 1.17x |
| `lower.declared_shape` | 66.5 M + 24.1 M = 90.6 M | 11.4 M | 0.13x |
| `Kernel.ask` | 32.2 M | 13.4 M | 0.42x |
| `lower.shape_in` | 26.3 M | < 11 M (not in top 50) | < 0.4x |
| `DeclSig.record_sig` | 24.3 M | < 11 M (not in top 50) | < 0.4x |
| `Workspace.sig` | 30.1 M | < 11 M (not in top 50) | < 0.4x |
| `Decls.sig` | 28.6 M | < 11 M (not in top 50) | < 0.4x |
| `array_append` (C row) | 67.8 M | 119.4 M | 1.76x |
| `avra_insist` (C row) | 122.8 M | 108.9 M | 0.89x |

Read: the 2–4x `declared_shape`/`shape_in`/`record_sig`/`Kernel.ask` gap I reported against 1ddf3440 is GONE on main 216f3c10 (those functions are now at or below the good commit). The retains that grew are `Workspace.ran_by` (>= 5x) and `Decls.decl` (1.17x).

### Caller table, `Workspace.ran_by` (probe: count calls and worklist length, one cold check on main)
- `ran_by` calls: 504 top-level entries (one per `ran_by(store, path)`), worklist entries summed: 12,944; largest single worklist: 898.
- Callers (by source): `kept_settle.av` `ask_kept_reads` (line ~129) and `forced_runs` (~117), and `interface.av` line ~510 (the file record). Caller-tagged probe: `ask_kept_reads` hit 594 times; `forced_runs` not hit at all.
- The multiplier is INSIDE `ran_by`: a worklist `seen` whose membership test is `seen.any(it.path == q.path && it.ref == q.ref)` (a closure per element, two record-field reads, each a retain). At 64c9b364 the same function used `seen.contains(q)` on a `List<string>` (one memcmp). That element-type change came in **a322a354** (#218 part 2, "a run's read names the declaration it read"), which is after 64c9b364 (45 commits).

### `shape_texts` hit/miss (main 216f3c10, one cold check, probe on `type_shape_cached`)
| event | count |
|---|---|
| hit | 300,336 |
| miss (`fresh_shape`, which walks the type) | 3,231 |
| fresh walks | 3,231 |
- So 99.0% of lookups hit. Misses are 3,231 walks, one per (TypeId, Decls instance) that was not yet filled. The lead's hypothesis (empty per fresh workspace) is not what dominates: 3,231 is small next to 300k hits. The table is per `Decls`; `anew()` builds a fresh one, but the number of `anew`s in one cold check is not counted here.
- main 216f3c10 cold, same run: lower 79.5 s, keep 50.6 s, analyze 35.5 s, wall 168 s, held 0/501, peak 2358 MB.

### Open
- Not yet done: the change that would test "a322a354's `ran_by` is the lower gap" (a membership test on a path+ref key, not a `seen.any` scan). That is the next experiment; it is a measurement, not yet a fix.

## 2026-10-12T19:58Z — PR #606 head fa9fc431 (ran-by): cold gen-2, census, counters

Cold gen-2 (spent.py, one run): wall 94.0 s, lower 44.9 s, keep 12.2 s, analyze 36.3 s, peak in spent log (not recorded this round).

### Per-function census, #606 head vs 64c9b364 (good), same tool; retains by performing function
| function | 64c9b364 (good) | #606 head | ratio #606/good |
|---|---|---|---|
| `array_append` (C row) | 67.8 M | 120.8 M | 1.78x |
| `Decls.decl` | 83.4 M | 97.7 M | 1.17x |
| `avra_insist` (C row) | 122.8 M | 110.0 M | 0.90x |
| `Kernel.ask` | 32.2 M | 13.4 M | 0.42x |
| `lower.declared_shape` | 90.6 M (66.5 + 24.1) | 11.4 M | 0.13x |
| `lower.shape_in` (copies) | 119 M copies | 20.4 M copies | 0.17x |
| `Workspace.ran_by` | under 24 M | not in top 30 | gone |
| `DeclSig.record_sig`, `Decls.sig`, `Workspace.sig` | 24–30 M | not in top 30 | under ~0.4x |

Read: the ran_by element-type regression is GONE on #606. What grew is `array_append` (1.78x) and `Decls.decl` (1.17x). Caller tables for those two are NOT in the census (it reports the performing function only); they need call-site probes, not done.

### Counters, #606 head, one cold check
| counter | value |
|---|---|
| `type_shape_cached` hits | 271,288 |
| `type_shape_cached` misses (fresh walks) | 3,255 |
| `type_shape_key` hits | 29,202 |
| `type_shape_key` misses | 3,254 |
| `shape_in` calls | 20,803,431 |
| `shape_in` top-level calls (empty path, one per fresh walk) | 3,255 |
| `shape_in` calls inside a walk (recursion, under `declared_shape` and the nested constructors) | 20,800,176 (99.98%) |
| shape text bytes built (sum over fresh walks) | 146,341,482 B (146 MB), mean 45 KB per walk |
| `new_decls()` calls in one cold check | 2 |
| distinct TypeIds among the 3,255 misses | 3,255 (no TypeId missed twice) |

Read:
- The `shape_texts` table misses once per TYPE, not once per workspace: 3,255 misses and 3,255 distinct TypeIds in a check that builds 2 Decls. So "empty in each fresh workspace" does not produce repeated misses here. The second Decls walked no type that the first had not.
- The cost is INSIDE each walk, not in the misses: every fresh walk (one per type) makes ~6,390 nested `shape_in` calls and builds ~45 KB of text, 146 MB in total. `shape_in` has no table for nested types, so a shared subtype is re-expanded under every type that reaches it (a DAG expanded as a tree). That is the lead's hypothesis, and these numbers support it.
- `type_shape_key` hits + misses (29,202 + 3,254) are fewer than `type_shape_cached` ones because a key miss calls `type_shape_cached` once; #606 still builds the full text to digest it, so the 146 MB is paid before the key exists.

## 2026-10-12T20:17Z — TIME, not retains: ns timers across the cold lower phase, #606 head (fa9fc431) vs 64c9b364 (good), one cold gen-2 run each

Clock: the workspace's own clock (ns, real). Timers are temporary eprintln lines, reverted after the runs. Units `U` and settlements `S` are INCLUSIVE (a unit's lowering can settle, and a settlement can lower), and `S` counts EVERY settlement in the process, not only those inside lower (analyze and keep also settle), so `S` is not a lower-only number.

| sub-step | 64c9b364 (good), ms | #606 head, ms | delta ms |
|---|---|---|---|
| lower phase total (time line) | 23,250 | 44,763 | +21,513 |
| `references()` | 830 | 934 | +104 |
| `cancel_reach()` (not timed at good: not in that tree's lowered_bodies) | — | 588 | +588 (new in the timed head) |
| `record_schedulers` | — | 5 | ~0 |
| `decls.union(...)` (contains unit lowering and any settlements inside it) | 15,552 | 27,208 | **+11,656** |
| `memory(...)` | 836 | 1,070 | +234 |
| sum of the five timed steps | 17,218 | 29,805 | +12,587 |
| "everything else" in lower (lower total minus the timed steps) | 6,032 | 14,958 | **+8,926** |
| unit lowerings `U` (inclusive) — count / ms | 13,752 / 9,926 | 14,261 / 16,221 | +509 units / **+6,295** |
| settlements `S` (inclusive, ALL phases) — count / ms | 546 / 11,654 | 583 / 28,703 | +37 / **+17,049** |
| `code_facts` in `unit_kept` (CF) | not reached | not reached | — |

Read:
- The growth is inside `union`: +11.7 s of the +21.5 s lower growth (unit lowerings +6.3 s inclusive, settlements +17.0 s inclusive, across all phases).
- "Everything else" grew +8.9 s and is NOT timed by these five steps; it is the work between them in `lowered_bodies`'s callers (`lowered_as`: host fn voices, diagnostics, the checked wrappers). It needs its own timers before anyone reads it.
- `cancel_reach()` is +0.6 s and exists only on the head; `references` and `memory` barely moved.

Limit: `S` and `U` are inclusive and overlap `union`; the table gives the growth, not a partition.
- 21:17Z NEW TICKET (B) leaf attack.av body literal: origin/main 64bbcd82, gen-2, warm store then one edit; explain --why, check --time, QTRACE. Started; (A) core/types.av is left to items-kept.

## 2026-10-12T21:49Z — (B) leaf body literal, `cli/src/commands/attack.av`, origin/main 64bbcd82, gen-2

Method: warm store on the original tree (one cold check, 759 s on the Sprite), then one fresh edit (the scenario's `firststr` edit, a fresh token), then `explain --why packages/cli` BEFORE the check, then `AVRA_QTRACE=1 check` (counts) and `check --time`. Edit restored afterwards.

Numbers (fresh edit):
- `check --time`: lower 6,646 ms, load 2,453, analyze 1,533, keep 2,166, held 464/505, attempt 0, discarded 1, wall 328 s (sprite-run wall, includes provisioning). The scenarios.md row (16 s, 2 attempts, 26 parsed) was measured on a warm base. Here the time line reports 1 discarded attempt; QTRACE on a second fresh edit reports 97 `Q parse` lines and 2 `Q attempt` lines.

### `explain --why` (fresh edit, before the check)
`505 files a check reads, 464 held, 41 read / 2 attempts judged the hold, 1 discarded / no input moved since the kept state`

| reason (verbatim from explain) | files | count | 3 examples |
|---|---|---|---|
| read: no record of its module is kept — it was never built here | `src/commands/tests/*.av` (and `src/tests/stage_test.av`) | 39 | `src/commands/tests/build_report_test.av`, `src/commands/tests/check_test.av`, `src/commands/tests/shared_test.av` |
| read: a compile-time run called one of its bodies | `../std-meta/src/meta.av` | 1 | `../std-meta/src/meta.av` |
| read: the entry | `src/main.av` | 1 | `src/main.av` |

- The edited file itself, `commands/attack.av`, is NOT listed as a read or as a hold loss: it is the changed input and is re-typed as the edit, as expected.
- "no input moved since the kept state" is the explain's own answer: the discard is NOT a moved input.

### Why attempt 0 is discarded
- QTRACE: `Q attempt 0 hold true homes false moved 0 reading 0` and `Q attempt 1 hold true homes false moved 0 reading 1`. Both report 0 moved inputs. The attempt count rises from 0 to 1 reads, so attempt 0 was redone because it read a file it had not yet recorded; that is the `reading` counter, not a moved input.
- What the trace does NOT say: which read turned attempt 0. Next: a QTRACE line at the discard site (not yet written), or a read on attempt 0 printed by name.

### Count breakdown (QTRACE, fresh edit)
- `Q parse` 97 (every parse appears about twice: once per attempt, and the test modules are parsed by both).
- `Q ask` 36,743, `Q declare` 6,641, `Q settle` 5,052, `Q store` 3,381, `Q unit` 1,357, `Q const_verdict` 36 (its own `stood`/`ran` split not tallied here), `Q named_type_fail` 3.

Read: the 39 test files are the bulk of the "losses" (read, not held, reason: never built here). They are parsed in both attempts. The two things the trace leaves open are which file turns attempt 0 and why the test modules are never built in this check.

## 2026-10-12T22:15Z — (B) follow-up: the 39 test files, and the attempt-0 discard

Method: probes in `keep_interfaces` (record.av), reverted after. Tree origin/main 5f1669e1, gen-2 `make avra` probe build, warm store, fresh single-token edits to commands/attack.av.

Findings:
1. The 39 unheld test files are NOT in a module of their own. `module_of` names the whole tests directory: the records written are `commands.tests` (678,132 B) and `tests` (5,423 B). `moved` in `kept` is exactly four modules per check: `@std.meta`, `""` (root), `commands.tests`, `tests`.
2. `@std.meta` and the root record STAND across checks (made == prior). The two test-directory records do NOT: every check that derives writes them again (`made != prior`, prior = 0). That was 4 of 4 derivations (kp1, x1, x3, x4).
3. Within one derivation the write reads back (KW probe: readback 64 = the digest length), so the sig is in the derivation's store. The NEXT derivation's `record_cached` finds nothing. So the row is lost between derivations (not a key mismatch: the `iface` line is present, `iface_of` is non-null).
4. Consequence: explain's 39 "read: no record of its module is kept — it was never built here" are these two directory records, absent when explain runs. After a check runs, explain shows 504 held, 1 read, 0 discarded (x12): the record exists right after the check's kept step, then is gone for the next run's derivation.
5. Attempt 0 discard: `kept` writes the test-directory records AFTER attempt 0 has read the test files as "unrecorded". That write moves the module record the attempt has already judged (its held set grew), so attempt 0 turns. Only one `KI commands.tests` line per check, so the second attempt is the one that writes. (Not proven line by line: the attempt-0 turn site is not yet printed; that is the next probe.)

Not yet found: why the row written in one derivation is absent from the next one's store (the store is discarded or the directory module key is never persisted). The next probe is `db.sig` / `record_bodies().body` on a SECOND check against the store file, and a `Q attempt` line at the `Turn.Again` site.

## 2026-10-12T22:41Z — store soundness probe (lead's (a)/(b)/(c)); no fix written

- (b) per-run key: refuted for the test records. `record_key`/`record_bodies().key` take the module name and the interface digest only (no attempt number).
- The test record does NOT depend on the edited file's text: `commands.tests` record has 0 lines naming `attack`; `@std.meta` 0; root record 2 (its own file lines). So an edit to `attack.av` moves the root record, not the test records.
- Every fresh-edit derivation writes `commands.tests` and `tests` (made != prior, prior = 0), 4 of 4 runs. Within the derivation the write reads back (64-char digest).
- The root record and `@std.meta` show made == prior in the same runs. I did NOT establish that they persist by the same mechanism: they may have been written by an earlier build, not by a check's `kept`. So "the row vanishes between derivations" is not yet a proof for the test records alone.
- (a) sealed-store: `settle()` runs `pack_settle` at derivation end, and `seal` reads `pack.records`; I did not yet check whether a row written by `keep_interfaces` reaches `pack.records` before the seal. That is the next probe: print `pack.records` size before and after `settle()`, and the key list after the process exits (two runs).
- Explain runs in `inspecting()` (Aside): it keeps nothing, so explain's own derivation cannot be the writer. Confirmed by code (cache_walk.av:128,147,155).
- Crash note: a probe that split the 678 KB record three times blew the Sprite's memory (run lost, exit 75). Probes on record text must be counted once, not repeated.

## 2026-10-12T22:45Z — hypothesis (d): full keys across two fresh-edit runs (origin/main eaff334c)

Probe: one line per kept module (`KK`): full record key and the interface digest. Two fresh edits (tokhA, tokhB), each check after its own `make avra`-free run except A, which followed a rebuild.

Results:
1. Interface digest (`iface=`) of `commands.tests` is IDENTICAL across all fresh edits seen: `f960336194b5…` in x1, x3, and run A. So the interface digest does NOT move with an edit to attack.av. Hypothesis (d) as stated is refuted.
2. The record key is `node_key(Stored.Sig, [compiler_id(), root, module text])` (record.av:51). It includes `compiler_id()`. Run A's key for `commands.tests` was `d1d92cd6…`; x4's (a rebuilt binary) was `3ea425a6…`. So the key changes when the compiler binary changes. Every `make avra` is a new compiler_id, so my probe builds start with an empty record lookup for their keys. That is a cold store for the new binary, not an edit effect.
3. Run B (same binary as A, one more fresh edit) printed NO `KK` line for `commands.tests` or `tests`. Its kept set was a different list of modules (`@std.prelude`, `@std.cli`, `@std.avrac.compiler`, `…dev`, `commands`, root). Run A's kept set was only four modules (`@std.meta`, root, `commands.tests`, `tests`). So the program the derivation sees differs between A and B. That is the open question, not the key.
4. So "the same key across two runs" could not be compared for the test records: B did not write them at all.

Next probe (one print, no splitting): in each derivation, print the length and first three paths of `p.files` (the program's files) and whether each test file is in it. That decides whether the tests are missing from the program in B, which would explain the absent KK line.

Lead's second witness (build-then-check, 21.7 s / 41 files / 1 discard on main): not re-measured in this lane.

## 2026-10-12T23:10Z — protocol run: ONE fixed binary, no probes (origin/main eaff334c, gen-2 from `make bootstrap`, clean `.avra-cache`)

Binary built by `make bootstrap` on the pinned commit; copied to `build/avra.fixed`; no rebuild between steps. Edits: a fresh single-token literal edit to `commands/attack.av` per step.

| step | what | wall | held | attempt (time line) | discarded | "never built here" |
|---|---|---|---|---|---|---|
| s1 | cold check, no edit | 22 s | 464/505 | 0 | 1 | — |
| s2 | unchanged check | 0 s (store hit) | — | — | — | — |
| s3 | explain after edit 1 | — | 499 held, 6 read | — | — | **0** |
| s4 | check after edit 1 | 12 s | 499/505 | 0 | 1 | — |
| s5 | explain after edit 2 | — | 499 held, 6 read | — | — | **0** |
| s6 | check after edit 2 | 12 s | 499/505 | 0 | 1 | — |
| s7 | explain after edit 3 (tkc) | — | 499 held, 6 read | — | — | **0** |
| s8 | check after edit 3 | 11 s | 499/505 | 0 | 1 | — |
| s9 | explain after edit 4 (tkd) | — | 499 held, 6 read | — | — | **0** |
| s10 | check after edit 4 | 12 s | 499/505 | 0 | 1 | — |

Notes:
- The time line's "attempt N" is the index of the attempt that stood, not a count. The attempt count is in the QTRACE `Q attempt` lines; not counted here.
- "discarded 1" appears on every check, cold and after an edit: it is a constant one-discard on this path, not the 39.
- No "never built here" reason appears at any step on this binary and this cache. The 39 unheld files of earlier steps do NOT reproduce under the lead's protocol.
- Earlier probe runs that showed 39 were on binaries built with probes (`make avra`) or on the 64bbcd82 gen-2 (scenario binary). That is consistent with the store being keyed by the producing compiler (record.av:51 includes compiler_id), so a new binary starts with a cold lookup. So the defect, as stated, is either per-binary or a probe artifact; not reproduced here.
- Note (my error, fixed): an earlier step script used tokens with digits, which broke `attack.av` (the literal regex stops at digits), so s7/s8 of the first run are invalid and were rerun with letter tokens (s7–s10 above).

## 2026-10-12T23:25Z — five-step table, ONE fixed binary (origin/main eaff334c, build/avra.fixed), own cache cleared (clear script embedded, verified by a cold 104 s step)

| step | wall | files read | "never built here" | attempts (Q lines) | parses (Q lines) | time line: held, attempt, discarded |
|---|---|---|---|---|---|---|
| 1 cold | 104 s | 505 read (0 held) | 505 | 1 | 650 | held 0/505, attempt 0, discarded 0 |
| 2 unchanged | 0 s | 1 read | 0 | 0 | 0 | (store hit, see below) |
| 3 edit 1 (tka) | 11 s | 6 read | 0 | 2 | 22 | held 499/505, attempt 0, discarded 1 |
| 4 edit 2 (tkb) | 11 s | 6 read | 0 | 2 | 22 | held 499/505, attempt 0, discarded 1 |
| 5 edit 3 (tkc) | 12 s | 6 read | 0 | 2 | 22 | held 499/505, attempt 0, discarded 1 |

- "never built here" in step 1 is ALL 505 files, because a cold store holds no record for any module: the reason is the cold-store fallback, not a test-dir property.
- Step 2 "unchanged" shows 504 held, 1 read in explain (the store-hit path). Its time line did not print a held field in the captured stream; I did not recover it.
- Steps 3–5: 2 Q attempt lines and 22 parses, against 1 attempt and 650 parses on the cold step. The 22 parses are the 6 read files, parsed in both of the two attempts (the 39-test-file set is not parsed here at all).
- The second attempt is the one that stands (time line "attempt 0" is the standing index); "discarded 1" means one attempt turned.
- Earlier "39 never built" observations do not appear on this binary with a cleared cache.

## 2026-10-12T23:27Z — CLOSED: the 39 "never built here" (per-binary cold key, not a defect)

The 39 unheld test files appeared only on binaries whose store was cold for their compiler identity (record.av:51 keys the record by compiler_id). On the fixed binary, after a real cold check, the test files are held after the first edit. Closed.

## 2026-10-12T23:27Z — the one-edit discard: what turns attempt 0 (origin/main eaff334c, build/avra.fixed, no rebuild)

Correction first: the earlier "cold check 22 s, held 464/505" was NOT cold. The cache clear had not run on the Sprite (the clear script was read there, where it does not exist), so the store was warm from earlier steps. The true cold check is 104 s, held 0/505, 1 attempt, 650 parses (the five-step run with the embedded clear).

Single fresh edit (token tkm) to `commands/attack.av`, QTRACE + `--time`, explain before the check:
- Q attempt lines: `attempt 0 — hold true homes false moved 0 reading 0`; `attempt 1 — hold true homes false moved 0 reading 416`.
- The discarded attempt, verbatim from the time output: `discarded: 4915ms — ast 105ms, sublang 146ms, parse 1ms, resolve 43ms, sigs 1ms, bodies 400ms, load 2465ms, admit 146ms, analyze 509ms, lower 1794ms — next reads 416 more (… attack.av …; … cli.av …) — nothing kept stands in: what it sees moved, or it was never built`.
- The standing attempt is the time line itself: held 499/505, attempt 0, discarded 1; its phases sum to about 7.0 s (load 2385, lower 2104, keep 688, analyze 572, bodies 336, admit 345, ast 198, resolve 171, sublang 164, sigs 8, parse 3). The check wall was 11 s.

(1) Attempts: 2 (attempt 0 turned, attempt 1 stood).
(2) What turns attempt 0: the edited file's compile-time runs read a different set than the kept state — the `moved` line in explain is "moved what its compile-time runs read: 59182465,…  -> 139545377,…" — so attempt 0 is turned by "reads 416 more": the new text's runs reach 416 files the kept state does not hold, and attempt 0 cannot stand on a read set it does not have. The 6 files explain names are the reads the turn leaves behind:
  - `../std-prelude/src/prelude.av`, `../std-cli/src/cli.av`, `../std-avrac/src/compiler/mod.av`, `../std-avrac/src/compiler/dev/attack.av` — "a compile-time run called one of its bodies" (in the unchanged state these were NOT read: 504 held, 1 read);
  - `src/main.av` — "the entry"; `src/commands/attack.av` — "its text moved".
  So these 5 extra reads are induced by the edit, not by the test directory.
(3) Wall: the discarded attempt 4.9 s of an 11 s check; the standing attempt about 7.0 s by its phases. QTRACE has no timestamps; the discarded wall comes from the `discarded:` line, which is printed by the derivation's own timer.
(4) No probe build was needed: the time output already names the turn (`next reads 416 more … nothing kept stands in: what it sees moved`). The probe was skipped on purpose; if the 416 must be named, the next step is a probe that prints the first five of the 416 paths at the `Turn.Again` site (derive.av:70, `having_read`), warmed with one cold check of the probe binary first.

Defect as stated: every one-edit check spends its first attempt on a read set it cannot stand on, because the edited file's compile-time runs reach 416 files the kept state does not hold. Cost: 4.9 s of an 11 s check.

## 2026-10-12T23:35Z — the turning read: probe at `having_read` (derive.av:70), probe binary warmed by a cold check first

Probe binary (`make avra` of eaff334c + one PROBE line at `having_read`), cold check (warm-up), then one fresh edit (tkp):
- `Q attempt 0 — hold true homes false moved 0 reading 0`
- `Q attempt 1 — hold true homes false moved 0 reading 416`
- `PROBE turn turned=0 reads=4 first=std-cli/src/cli.av | std-avrac/src/compiler/mod.av | std-prelude/src/prelude.av | std-avrac/src/compiler/dev/attack.av`
- time line: held 499/505, attempt 0, discarded 1, load 2363 ms, lower 2151 ms, keep 657 ms, wall as before.

Reading the numbers:
- The turn is `having_read` with 4 reads: the four compile-time-run files of the EDITED text. `main.av` and `std-meta/src/meta.av` are NOT in the turning set. The hypothesis (meta.av or main.av turns attempt 0) is killed.
- The 416 is not 4 reads: attempt 1's parse list is 4 (turn) plus 412 lead reads that `tried_anew` adds to EVERY attempt (`fresh.lead_reads(at)`). The Q line prints the length after the lead reads, so attempt 0's Q line (taken before them) says 0.
- So attempt 0 lacks exactly the four files that attack.av's new text's compile-time runs read.

Why it recurs on every edit: each fresh literal changes attack.av's text, so the run reached from that text has a new key and its reads are not in the kept state; attempt 0 cannot know them without running. A literal edit that does not change WHICH files the runs call still turns attempt 0, because the run's reads are keyed on the file's text, not on the run's code. That is the design point, not a missing read in attempt 0.

Candidate fix (not implemented): key a compile-time run's read set on the run's own body, so an edit that keeps the run's body and reads leaves attempt 0 with the reads it needs. Scope: a store/record change in the run key. Not a one-line fix; a sonnet-level design task.

## 2026-10-13T00:02Z — FIX (attempt 0 starts with the standing attempt's read set): measured

Change (derive.av, uncommitted in ../avra-lower-regress on origin/main 5f1669e1-based tree): a `runs_key(entry)` row written with the standing attempt's `at.parse` paths in `bodies_lowered`, read in `lead_reads` (filtered by `there`). Same `remember`/`remembered` format as `homes_key`. No change to holding()/homes.

Measured (one fixed binary built from this tree by make avra; cache cleared with the clear script embedded; QTRACE attempts):
| step | wall | Q attempt lines | time line |
|---|---|---|---|
| cold0 | 101 s | 1 (reading 0) | held 0/505, attempt 0, discarded 0 |
| edit_q (first after cold) | 12 s | 2: attempt 0 reading 0; attempt 1 reading 199 | held 499/505, discarded 1 |
| edit_w (second edit) | 6 s | 1: attempt 0 reading 0 | held 499/505, discarded 0 |
| edit_e (third edit) | 6 s | 1: attempt 0 reading 0 | held 499/505, discarded 0 |

Read: once one attempt has stood on a text, the next edit starts attempt 0 with the remembered read set: 1 attempt, 0 discards, 12 s -> 6 s. The FIRST edit after a cold check still turns once: a cold check writes no run-read set (its attempt has no parse list), so there is nothing remembered yet. Limitation, not yet fixed.

Attacks still owed: (a) a remembered path whose file is deleted must not trap (the filter `there` is in place; not yet exercised); (b) an edit that ADDS a new compile-time read must still turn once and end correct (not yet built). Not yet a draft PR.

## 2026-10-13T00:22Z edit-path — build-then-check numbers for your fix to test against (main eaff334c, Sprite, packages/cli)
- cold `build --time`, then immediately `check --time` (no edit): check wall 21.7 s, 'held 464/505, attempt 0, discarded 1', ast 0.85 s parse 0.79 s load 2.3 s admit 0.2 s analyze 1.5 s lower 5.4 s keep 0.76 s. A check after a CHECK is ~0.4 s (cache hit). Expect ~0.4 s after a build once the defect is fixed.
- Same sequence with the (parked) #636 branch where a build keeps no rule rows: check 89.3 s, held 0/505 — useful as the worst case.
- Reproduce: rm .avra-cache dirs; build/avra build --time packages/cli; build/avra check --time packages/cli. (tools/ep_ba.sh pattern; one run each.)

## 2026-10-13T00:26Z — draft PR for the attempt-0 read set: https://github.com/avra-lang/avra/pull/656 (DO NOT MERGE, draft)

Branch lower-attempt0 (246f2f0b on 02874a27). Change: derive.av only (runs row, lead_reads read-back, on_disk host check).
- Measured: cold 101 s 1 attempt; first edit 12 s 2 attempts 1 discard; second and third edits 6 s, 1 attempt, 0 discards.
- Attack (b), a new compile-time read (const from std-text): status 0, 1 attempt, 0 discards.
- Attack (a), a deleted remembered path: with the memoised Exists check the change TRAPPED (`does not exist`); the unfixed binary passed; with the direct host check: status 0, 2 attempts. Witnessed failing before the fix.
- Deviation from the ticket: the row is keyed by ENTRY, not by the edited file's path. Per-file keying needs the reader file for each run read, which the record does not carry; the entry-keyed set is the same guess set for this scenario.

## 2026-10-13T01:44Z — PR #656 updated: cold remember + section ra; NOT GREEN

- Measured (3 rounds, before = origin/main, after = branch): cold 102–105 s, 1 attempt both. First edit after cold: 2 attempts, 1 discard, 11–12 s both (the cold attempt admits every file, so it records no run reads to remember). Edits 2–3: 2 attempts/11–12 s before → 1 attempt/0 discards/5–6 s after; parses 22 → 15.
- `ra` section: green on the branch.
- `make cache-attacks`: branch 376 builds, 131 holds, 1 FAILED (`gw`: a member module added under a collector, read for what it gathers: no, wanted yes). origin/main: 376 builds, 131 holds, 0 FAILED. So this branch causes the gw failure. Not fixed; PR stays DRAFT, DO NOT MERGE.
- Probe lessons: a `PRB` probe showed the remembered set holds ~199 entries of which 4 are on disk; most are not files (key-like paths). The filter is needed.
- Earlier one-off remembers at `bodies_lowered` vs the builder: both gave the same edit 2–3 behaviour; the builder version also covers cold attempts (cold has no having_read set, so this is the same as before for the first edit).

## 2026-10-13T02:39Z — PR #656: CI-blocking items, and the trade-off found

- Keepers: `inputs.py` 0, `make keepers-static` 0, idioms (std-avrac, cli) 0 — after dropping the direct host read (idioms rule `compiler.host_asked_directly` and the inputs keeper each need the licence on the line directly above the site, and one site cannot carry both).
- Deleted-path check: the direct host read was the only filter that passed it. Cell `there` and listing filter both still trap "does not exist" — the trap comes from a KEPT CONST VERDICT that reads the deleted file, which origin/main also traps on. So the deletion case is a pre-existing defect, not this change's.
- `cache-attacks` with ALL attempt reads remembered: 1 FAILED (gw). With ONLY run reads remembered: 376 builds, 0 FAILED. Pushed the run-only variant (force-with-lease over my own draft branch, 8a0579c2).
- Trade-off: the run-only variant does NOT save the first/second edit attempt (qa, qb: 2 attempts). The speed-up needed the attempt-level reads; they are what makes gw fail. So #656 as a speed win and a green gate are currently in conflict. I have not found the cause of the gw failure in the attempt-read set.

## 2026-10-13T02:55Z — gw: two cycles, not understood; handed on

Reproduced standalone (the gw block of tools/cache_attacks.sh, all-attempt-reads variant, probe build): the step "a member module added under the collector" fails. The probe at the lead-read site shows the collector's own file `gk/src/c/lib.av` and `gk/src/k.av` are PRE-ADMITTED as lead reads (`LR`), before the collector's gather read (`having_read(gathered_moved())`, whole.av:278 / derive.av:702) is produced. No `FR` (force_read) line fired in any build of the fixture, so the gather read does not go through `force_read`.

Tried: `reading(more)` now replaces a parse entry with the same path (the consumer's reason wins). gw still fails: the explain read list still shows `lib.av — nothing kept stands in` (the Unkept reason). So the reason is recorded on a path other than `parse` or `reading`, and I did not find it. Reverted the probe and the reading change; branch 8a0579c2 (run-only reads, cache-attacks 0 failed) is unchanged.

Open question for the next lane: where the explain read list's reason for a path is taken from when the path was pre-admitted (`read_files`, `forced`, or `Derived.read`), and why the gather's reason is not written there.

## HANDOFF (lower-regress, final) — PR #656 and the remembered-guess mechanism

1. Variants. (A) all-attempt reads: runs row keyed by entry holds every path of the standing attempt's `parse` plus its RunBy read_files. Gives 1 attempt, 0 discards, 6 s on edits 2–3, but `gw` fails. (B) run-only reads: row holds only RunBy paths (`run_read`). `make cache-attacks` 376 builds, 0 failed, but edits 2–3 stay 2 attempts. Commits on origin/lower-attempt0: 9ab28e9f (A, first), e3d7ce7a (A + cold remember + ra section), 8a0579c2 (B, current head). Force-pushed once over my own draft branch.
2. gw repro: `sed -n '/^gw=\$(mktemp -d)/,/^rm -rf \$gw$/p' tools/cache_attacks.sh > g.sh`, then run g.sh with `steps=0; fails=0; holds=0` defined and `./avra` = build/avra of variant A. Step "a member module added under the collector" prints the FAIL.
3. gw: probe at the lead-read site shows `gk/src/c/lib.av` and `gk/src/k.av` pre-admitted (LR) before the gather read; no force_read fires. Tried: `reading()` replaces a same-path parse entry with the consumer read (consumer reason wins): gw still fails. Reverted.
4. Open question: where the explain read list takes a pre-admitted path's reason (read_files / forced / Derived.read), and why the gather's `Reads.Gathered` (whole.av:278, consumed at derive.av `having_read(gathered_moved())`) is never shown for that path.
5. Fixed protocol (per round): clear cache, then cold check, then 3 fresh literal edits to commands/attack.av, each with `AVRA_QTRACE=1 check packages/cli --time` and attempts = `grep -c -P '^Q\tattempt'`. Clear embedded, never `$(cat build/clear_cache.sh)` inside a Sprite command (that path does not exist on the Sprite; the clear silently does nothing). Edit tokens letters only (the literal regex stops at digits). Baseline numbers: cold 102–104 s; edits 11–12 s, 2 attempts, 1 discard.
6. Deleted-path case, main traps too: a const `probe_v: int = probe_pv()` in commands/attack.av (with `use commands.probe_fn.{probe_pv}`, probe_fn.av = `export fn probe_pv() -> int { 7 }`) makes a kept verdict read probe_fn.av; delete probe_fn.av and revert attack.av; the next check fails `avra: …/probe_fn.av does not exist` (status 2). Same on origin/main's binary: a kept const verdict still reads the deleted file. Repro: `./avra build <pkg>` after deleting a file that a kept verdict read. Not caused by #656; the remembered-set filter does not cover kept verdicts.
7. Guess filters: `Cell there` (memoised Exists) and the listing filter (`all_files`) both still trap on the kept-verdict case above; only the direct host read (`host.there`) passed the attempt-level case, and idioms refused it (`compiler.host_asked_directly` needs its licence on the line directly above, which the inputs keeper's `input.` licence cannot share). Dropped.
8. Garbage-guess attack: NOT RUN. Owed: remembered row set to nonexistent paths, unrelated existing files, every package file, and empty; diagnostics, exit status, kept read lists and final key must match a run with no row.
9. Cold check writes the row too, but a cold derivation has no run reads to remember (all files admitted up front, 650 parses, no turn), so the first edit after cold stays at 2 attempts. Stated limitation.
10. main moved after my last rebase (unit_rows.av differs). Rebase onto current origin/main before any landing; the branch is DRAFT and DO NOT MERGE.

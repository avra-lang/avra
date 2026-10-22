# Small wins ledger (owner, 2026-10-13: "lots of smaller wins add up — do not throw away what is within noise")

Rule: a win too small for the stopwatch (Sprite edit noise is ±1 s on 4–6 s) is still a win. Prove it with an
EXACT receipt, not wall time: sample share before/after on the same scenario, `make census` counts
(retain/release/list writes), callgrind instructions (once #724 lands), or a call count from `explain --stats`.
Never drop a measured improvement for being small. Skip only work on a mechanism the design's A16 ledger deletes.
Scenario for shares: cli, warm store, leaf body edit of `cli/commands/attack.av`, `check` (db06's FUNCTION PROFILE, 6,897 samples).

Profiles (db06, frame-pointer Mac build): `.lead/lanes/db06.md` sections "EDIT RE-SAMPLE WITH FRAME POINTERS", "COLD CHECK PROFILE", "COLD BUILD PROFILE", "COLD: WHAT TO CUT". Raw samples /tmp/db06-sample-fp.txt (edit), /tmp/db06-sample-cold-check.txt, /tmp/db06-sample-cold-build.txt (Mac `sample`); reader `/tmp/db06_incl.py <sample> top N | under:<fn> N`. Reproduce with PR #726 (AVRA_FRAME_POINTERS=1, build twice).

| # | Site | Measured | Fix | Owner | Status |
|---|---|---|---|---|---|
| 1 | `fp_str` + `char_code` (per-char Avra loop) | 7.6% | one runtime call | db06 | PR #728 draft (existing avra_str_word_at row; core 290/290) |
| 2 | `unhex` (char-by-char hex decode) | 5.2% | core/digest hex decode, one bytes read per octet (no substring/index_of) | squeeze | PR #735 draft. Cold cli census: retains -15.1M (-1.0%), releases -37.9M (-1.8%), list writes -36.2M (-1.6%); row not isolated (unhex runs on warm store reads only) |
| 3 | `blake3_hex` (digest → hex text) | 2.5% | hex encode already one C pass; Avra side is a Bytes adopt + text copy per digest. Needs C-built text (package C, no rt_sigs row). PROPOSAL only | squeeze | proposal |
| 4 | `text_before`, `wire_fields`, `joined`, `read_fields` | 2.6 + 2.2 + 1.9 + 1.4% | joined → xs.join (one runtime call; was pairwise Avra merge): PR #735 draft. wire_fields/text_before/read_fields left: wire_fields dies with KeyParts; text_before already word-wise | squeeze | PR #735 draft (joined); rest measured, dropped |
| 5 | `Names.intern`, `kept_ref_rows`, `Opened.span`, `read_bytes` | 2.2 + 2.3 + 1.2 + 0.9% | — | squeeze | open, look |
| 6 | `decls_so_far`, `seen_by_name`, `reexporting_files`, `typed_index` | 2.3 + 1.5 + 1.3 + 1.3% | — | squeeze | open, look |
| 7 | `reverse_section` rebuilt at every seal | 1.8% (~120 ms) | incremental | db06 | queued (now 2.2% of the FP edit sample; Names.intern 8.2% in the same seal) |
| 8 | ComponentScan store-answered | 262 → 241 ms; load 2,343 → 1,880/1,942 ms | commit was dropped — RESTORE | db06 | PR #731 draft (store hit rows 178 -> 680: +502 scans served) |
| 9 | runtime self time 72% (rc retain/release, streq, array_get, memmove) | — | `make census` per-caller tables on the scenario | squeeze | open, measure first |
| 10 | #721 re-entrant Expanded once | 173 → 3 settles; cold 132 → 109 s on its stack | — | nodes-self | draft |
| 11 | #685 emit width = cores | cold emit 37.4 → 25–29 s @8 | — | edit-path | red keeper, fix |
| 12 | #670 store shared by producer hash | second compiler 64.7 → 58.4 s | — | db06 | rebased e8c5a9a3 (green by name) |
| 13 | `Names.intern` in `body_payload` (seal) | 8.2% of an edit run; 4.1% of a cold check | linear intern with array appends per row; hash it | db06 | open (squeeze row 5 overlaps) |
| 14 | `store.seal` as a whole | 14.5% of an edit run (885 of 6,092 samples), 5.8% cold check | write only the rows that moved | db06 | open |
| 15 | cold: `parse_program` (generic PEG, run_as) | 27.9% cold check, 17.0% cold build | fan out across files/processes; cache by text digest across worktrees | — | open |
| 16 | cold: `const_settlement` / `settle_run` (interpreter) | 20.8% cold check, 16.0% cold build | per-const independent: fan out; cache by const digest | — | open |
| 17 | cold: `Decls.union` + `lower_fn` | 12.4 + 11.3% cold check | per-unit independent: fan out | — | open |
| 18 | cold: LLVM tail-merge/identical-instr | 6.3% of all cold-build samples | LLVM option / -O level for dev builds | — | open, look |
| 19 | cold: main thread idle in `psynch_cvwait` while emit workers run | 13.5% of cold-build samples | overlap lowering with emit | — | open |
| 20 | refcount + free self time (rc_release/retain, release_dead, box_free) | 26% cold check, 11.7% cold build | census per caller | squeeze | open |
| 21 | cold `kept`: idiom RULES engine run cold inside `all_said` (rule_findings/node_candidates) | 6.0% of a cold check | only when rules are asked? cache by text digest | — | open, look |
| 22 | cold `kept`: row writes (`pack_put` 9.1%: append 2.7, syscall fd_write 2.1) | 9.1% cold check | batch frames (squeeze #742 chunked Writer overlaps) | squeeze | open |
| 23 | cold `kept`: text codecs (decl_wire, read_of_wire, unhex_text, joined, wire_siblings, wanted_list_wire) | ~5% cold check | dies with KeyParts / squeeze | squeeze | open |
| 24 | cold `kept`: keep_interfaces + keep_moved + keep_parts + key_parts | 6.5 + 1.7 + 1.8 + 2.0% | KeyParts deletion (items-kept c) | items-kept | open |

## Dedupe as you go (owner, 2026-10-13)
"there are probably a lot of duplicate handwritten things too… consolidate this stuff to core libs and dedupe."
Every site touched: list its twins (file:line), pick ONE home (`@std/*` if general, std-avrac `core/` if compiler
infrastructure), move callers, delete copies. Receipt adds "copies N → 1, lines −K". A dedupe with no speed change
is still wanted. Running table: `.lead/lanes/squeeze.md`.

## callgrind baselines (main 88ccbdec)
Measured with `sh tools/profile.sh build/avra check <pkg>` on a Sprite (Ubuntu 26.04, valgrind 3.26), the
store moved aside first so each run is cold. Total Ir is the exact receipt; self top lists exclusive cost.
The compiler forks a worker per core: these are the parent process only (`--child` reads a worker).

- cold `check packages/std-text`: total Ir **1,395,748,215**. Self top 10:
  array_made 6.52%, box_free 5.62%, avra_rc_release 4.77%, blake3_hash_many_avx2 4.14%,
  avra_release_dead 3.94%, avra_streq 2.93%, avra_release_dead'2 2.47%, takes_masked (Token lexer) 2.25%,
  starts_at_masked (Token lexer) 2.25%, avra_slot_unique 2.19%.

- cold `check packages/cli` under `tools/profile.sh` (main 88ccbdec, Sprite, store moved aside): **did not fit** its 60-minute bound under callgrind; stopped by the Sprite's bound with no profile written. Retried on `packages/std-http` (see below).

## Cold `kept` one level down (db06, cli cold check, 24.7% of the run) — rows to take
| # | Site | Measured (of cold check) | Fix idea | Owner | Status |
|---|---|---|---|---|---|
| K1 | `Store.keep` → `pack_put`: `fd_write` per row, `append` | 9.1% (syscalls 2.1, append 2.7) | buffer rows, one write per seal/segment | db06 | open |
| K2 | `all_said` → `rule_findings` (idiom rule engine over every statement) | 6.0% | per-rule first-token/kind prefilter; skip rules with no matching node kind in the file | squeeze | open, measure first |
| K3 | `keep_interfaces` | 6.5% | breakdown needed | db06 | open |
| K4 | `store.seal` (Names.intern 3.0) | 5.4% | Names.filled + single-pass reverse_section (branch db06-seal) | db06 | in test |
| K5 | `keep_instances` / `keep_codes` / `keep_const_units` | 3.4 / 2.3 / 2.1% | — | — | open |
| K6 | chunked stable Writer (#742) | −5.3% Ir on cold check std-text | landed as draft | squeeze | draft #742 |

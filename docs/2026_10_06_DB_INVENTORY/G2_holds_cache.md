# G2 — holds / warm / cache worktrees: what is NOT on origin/main

Reference: `avra-db-design` = origin/main `05fe643` (2026-10-05). All trees under `/Users/tristan/projects/tristanMatthias/`.
Method per tree: `git log origin/main..HEAD`, `git cherry origin/main HEAD` (`+` = not on main by patch-id, `-` = on main),
subject grep on origin/main (squash merges), key-symbol grep in `avra-db-design`, `git status --porcelain`, `git diff`.
Raw survey: `dbd/g2_raw.txt`; commit bodies: `dbd/g2_msgs.txt`.

Headline: of 42 trees, **only three hold DB/cache-layer work that is not on main**:
`avra-warm-memory` (active, 5 wip commits), `avra-warm101-11` (uncommitted reach-witness, parked by decision),
`avra-perf-hold-keys` (`9aabcb1`, abandoned by decision as unsound). Everything else is landed under a squash, superseded, or scratch.
No worktree's branch touches `docs/*.md` or a root `*.md`; no untracked notes or measurement logs exist in any of them
(only helper scripts). Every measurement below comes from a commit body or a ticket comment.

Docs check (all 42): no doc differs because of a branch. Only stale-base artefact: `docs/2026_10_02_PROVIDE_ENV.md`
exists in `avra-warm-settle`, `avra-warm101-11`, `avra-warm4-base` (tracked at their base, since deleted on main) — not DB-relevant.

---

## Same-commit groups (treated once)

| Group | Trees | Fact |
|---|---|---|
| A | `avra-kept-settle` ⊃ `avra-warm-diag` ≈ `avra-perf-g1merge` | share `1c7ba69`, `5b9d1f8`; warm-diag/g1merge add `811eab7`; kept-settle adds `1378487`, `25b4780` |
| B | `avra-held-path` `e203c0d` = `avra-kept-settle` `1378487` | same subject, landed as #48 |
| C | `avra-link-c004703` ⊃ `avra-link-8d1149b` ⊃ `avra-lone-0448e89` ⊃ `avra-lone-6a7d90f`; `avra-lone-main` = their base line | one stack, 4 detached bisect points |
| D | `avra-cb-0600b2c`, `-33dcdb5`, `-441d58e`, `-c3275b7`, `-e8d1641`, `avra-stamp56-base` | detached at main commits, one identical untracked test (md5 `e08aded9…`) |
| E | `avra-warm101-11`, `avra-warm4-base` | both exactly `0e67451` (main, #171); A/B pair |
| F | `avra-mh-held` = `avra-witness-delete` commit `7754472` mid-rebase | |

---

## 1. avra-warm-memory — ACTIVE (read-only look; it moved while I read: HEAD went `6020fb0` → `9437242`)

- Branch `warm-memory`; base = origin/main `05fe643`; ahead 5, behind 0; clean tree; no notes/logs in tree.
- `origin/main..HEAD` (all `+`, none on main):
  - `235673b` 2026-10-05 19:20 wip: a turned attempt's workspace gives back what it derived
  - `d2c3fc9` 19:35 wip: one derivation alive at a time
  - `cbfef4e` 19:37 wip: the evaluator's hearing lets a quarrelling derivation go
  - `6020fb0` 19:45 wip: a discarded workspace closes its relations
  - `9437242` 19:52 wip: the registry's declare hook lets its table go
- Ticket: none named in commits (bodies are empty). NOT VERIFIED which ticket.
- What the diffs say it found (`git diff origin/main HEAD`, 8 files +238/−59):
  1. **Several whole derivations stand side by side in one process.** `derive.av`: old `derived_reading` ran `attempted` (held), then
     `checked_whole` → `d.program.ws.whole(d, [])` (a second, fully lowered derivation) while the first was still referenced, and on
     refusal `from_sources` (a third). New `derived_owing`/`stood_first`/`under_hold`/`tried_anew`; doc: "ONE DERIVATION IS ALIVE AT A
     TIME: the one that owes is let go before the whole one begins, so asking again never stands two programs side by side."
  2. **A workspace never dies on its own** (hooks capture it; relation rows live under their Db until closed). New
     `Workspace.discarded()` (`workspace.av`): `for f in Family.all() { self.relation(f).evict() }; self.db.disarm(); self.decls.let_go(); self.failures_db.get().close()`.
     New `Decls.let_go()` closes `decl_rows`, `refs_db`, resets 5 hooks; doc: "a relation's rows stand in the process under their Db until it closes".
  3. `query/kernel.av` `disarm()` now also clears the audit's four cells ("Verifiers and the audit's judges capture their workspace").
  4. `core/types.av` `disarm_declare()` — the TypeRegistry's declare hook captured the table.
  5. `suite.av`: nested suites, `rules_checked` (now `rules_proved` in a fresh workspace) and the evaluator's "quarrel" path each kept
     a prior workspace alive; each now calls `discarded()`. `build.av`: the link's "does this owe a whole derivation" question
     (`link_owes`) is asked where the derivation is made, so no second derivation at link.
  6. `tools/memsites.py` (new): names `AVRA_MEM_STATS` `site 0x…` lines from `nm` (Linux has no `atos`).
- `Kernel.newly_read` is NOT touched by any of the five commits. On main it is
  `mut s = self.snapshot(); … s.pending.last()!.push(key); self.replace(s)` (`avra-db-design:packages/std-avrac/src/query/kernel.av:588-594`),
  i.e. where the bytes are allocated; the diffs treat the cause as lifetime (who keeps a workspace/kernel alive), not that function. NOT VERIFIED (no notes; inference from diffs).
- No numbers in the tree. Related prior number: ticket `avra-h1st` comment 2026-09-22: "no disposal grows ~30 MB/iter; with disarmed() per build ~0.84 MB/iter still accumulates".
- Value for the design: **high**. It is the first enumeration of everything that pins a derivation's state (kernel verifiers, audit cells, 6 Decls hooks,
  TypeRegistry declare hook, relation Dbs with process-global rows, `failures_db`). A design with one query door needs one owner whose
  close frees all of it; today it takes a hand-written list in three files.
- Verdict: **KEEP** (in flight; do not disturb). Design note to take: relation rows live outside the workspace value, so "discard" must be a kernel verb.

## 2. avra-warm101-11 (= base `0e67451`, group E) — uncommitted reach witness

- Branch `warm101-11`, HEAD `0e67451` 2026-10-02 (main #171); ahead 0, behind 98.
- Uncommitted: `M record.av` (+82), `M workspace.av` (+2/−1); untracked `tools/w101_ab.sh`, `w101_phases.sh`, `w101_view.sh` (A/B + QTRACE counters, no outputs saved).
- Ticket: `avra-8sb5.57.101.11` (open, P2), blocked by `.101.12`.
- What it does (diff): `view_parts` answers from a persisted **`ReachWitness { seen: List<WitnessMod{module,digest}>, deps: List<WitnessDep{dep,files}> }`**
  stored under `reach_key(module)` = `node_key(Stored.Unit, ["reach", module])`. Valid iff every recorded module's WHOLE-record digest still matches
  (`w.seen.all(s.digest == record_digest(self, store, s.module))`) and every listed file exists. Wire lines: `h\t<module>\t<digest>`, `d\t<dep>`, `f\t<dep>\t<file>`.
  Comment: "The WHOLE record, never its interface alone: the walk closes over typed and impl rows, which the interface digest never folds."
- How far: built and working, never committed. Ticket comment 2026-10-02 06:22: "The persist-the-reach form WAS built and works (witness taken 70/70)
  but the win evaporates: interleaved same-Sprite A/B wall base ~3.90s vs branch ~3.78s (~3%), one-shot load 2231->1667ms. Validating the reach costs ~what
  the walk saved, because full-record digests are required". Same comment: "0 of 70 [view_parts calls] had any view cell settled … key_parts is asked during
  load_interface/keep_const_units BEFORE those modules are analysed"; and "The M3 witness layer does not exist [on main]: Stored has no dep kind, Db.deps_of is in-process dense Keys".
- Not on main: `ReachWitness`, `reach_key`, `witnessed_view`, `record_digests` (grep in avra-db-design: 0 hits).
- Value: this is the saved-answer rule written by hand for one answer (value + inputs read + their digests, valid iff all match). It measured the rule's cost when
  inputs are coarse (whole records): validation ≈ recomputation. It also shows a key is computed before the kernel has any deps for it.
- Verdict: **REWORK** — do not land; reuse the shape and the two findings (input grain decides whether a saved answer pays; ordering problem) in the kernel-written rule.

## 3. avra-perf-hold-keys

- Branch `perf/hold-keys`, HEAD `9aabcb1` 2026-10-01; base `2cb30a5`; ahead 1, behind 151. `git cherry`: `+ 9aabcb1`. No subject on main; `view_print` 0 hits on main.
- Untracked: `tools/callgrind_warm.sh`, `view_sabotage.sh`, `wall_ab.sh` (scripts only).
- Ticket: `avra-8sb5.57.101` slice 2.
- What: `record.av` keeps `view_parts` under `node_key(Stored.Unit, ["view", m.text(), self.view_print(store, m)])`, where `view_print` is a hand-rolled digest
  of each seen module's `db.sig`, imports, files and file text digests.
- How far: committed; measured; rejected. Ticket `.101` comments 2026-10-01: "warm one-line fmt.av edit check 2.28s vs base 2.46s (~8%, load -66ms, keep -110ms). BUT it is
  UNSOUND: cache_attacks 23 failed vs base 2"; extended key "sound but … load 1019ms -> 3824ms"; per-build memo "15 cache failures (records mutate mid-build)".
  Decision 22:22: "ABANDON the view_print fingerprint — it is a second, incomplete spelling of the dependency set the kernel already writes".
- Value: a recorded stale-cache post-mortem — a hand-written validity key that omitted inputs (`reach`/`typed_index`/`reexporting_files`/`place_files` reads). The failing
  attacks are named: `mh` signature moves, `nd` appended declaration, `nr` gone record, `ee` moved E.
- Verdict: **ABANDON** (code); keep the post-mortem as the case against hand-written validity checks.

## 4. Group A — avra-kept-settle / avra-warm-diag / avra-perf-g1merge

| Tree | Branch | HEAD | ahead/behind | dirty |
|---|---|---|---|---|
| avra-kept-settle | `perf/kept-settle` | `25b4780` 2026-09-30 | 6/312 | `?? tools/warm_split_exp.sh` |
| avra-warm-diag | `fix/warm-recheck` | `3fcf3a3` 2026-09-30 (merge) | 5/312 | `?? corpus/` (5 probe scripts) |
| avra-perf-g1merge | detached | `9aa59b8` 2026-09-30 (merge) | 5/331 | clean |

| Commit | cherry | On main? evidence |
|---|---|---|
| `1c7ba69` structural refusal lowers only until it reaches the world; warm edit timed | `+` | YES by content: #58 `c3b06fe` touches the same files; `settlement_until` at `lower/lower.av:607`, `reach_probe` at `workspace_analysis.av:648`. Its `tools/land.sh` half is not (land.sh retired; `AVRA_LAND_WARM_WALL_S` 0 hits) |
| `5b9d1f8` Wanted built by one constructor | `+` | folded into #58 (same file `workspace_analysis.av`). NOT VERIFIED line by line |
| `1378487` held row read costs what a read one does | `+` | YES: #48 `1ce3ee6` |
| `25b4780` refused hold rebuilds quietly | `+` | YES: #58; `hold-refused.log` at `derive.av:314` |
| `811eab7` held file's rule findings reach Checked.findings | `+` | YES: #61 `2f7f94c`; `findings_key` at `derive.av:141` |

- Tickets: `avra-8sb5.57.124`, `.57.126`.
- Measurement (`1c7ba69` body, Sprite, 2026-09-30): "warm check-cli after the fmt.av:275 edit: held 393/401 (main 98), discarded 0, wall 32 s (69.8 s with the double derivation). The rest is 'lower' (~28 s …)".
- Post-mortems in bodies: (a) settling a const lowered its whole transitive reach (~300 files), every lowered body counts as read → held 98/401;
  (b) "recording only the chain left a held file whose body the probe asked unread, and the derivation turned and ran twice";
  (c) `811eab7`: `Workspace.checked` built findings from files read this run, so a warm ratchet judged a subset; (d) `25b4780`: a refused hold printed the held attempt's
  diagnostics so "a condition the compiler handles read as a miscompile (the F0900 'defects' a warm landing tree printed all night)".
- Verdict: **ABANDON** all three trees (landed). Scratch scripts are disposable.

## 5. avra-held-path (group B)

- `perf/held-path`, HEAD `74f963b` 2026-09-30 (merge); own commit `e203c0d` (`+`), on main as #48 `1ce3ee6`. Clean.
- Body numbers: "check packages/cli, same input: a warm one-line edit 274.6B -> 25.3B instructions (-90.8%), 20.9 s -> 2.3 s; cold 209.6B -> 205.6B (-1.9%), peak flat."
- Causes found: per-row kernel ask for the module's HeldSig; `Kernel.hit/miss` copied the whole `KernelState` to bump a counter; restored refs stood the target module up once per ROW.
- Verdict: **ABANDON** (landed).

## 6. avra-heldsettle

- `fix/held-settle`, HEAD `6469b85` 2026-09-28 (merge); ahead 1 (the merge only). Own commits `15138ec`, `258500c`, `0282308` (and `9ecc31d` + its revert `5b48fd0`) are ancestors of origin/main (`merge-base --is-ancestor` true). Clean.
- Ticket: `avra-8sb5.57.40`.
- Post-mortem (commit bodies): a held declaration's fact was read before its record row was filled → "settled a second time" refusal → every warm run fell back to a full rebuild.
  First fix (don't mark a "not yet" read) reverted as "Wrong layer: … silences the write-once-after-read guard for exactly the readers who acted on an answer that later changes".
  Real fix: `sig()`'s held branch fills the row first; then three more doors that read held facts without that door (`const_type_at`, `Decls.target_of`, `settled_at`).
  `9ecc31d` body: held path "~0.5s warm, where the fallback path costs a full re-analysis".
- Verdict: **ABANDON** (landed). Lesson for the design: four separate doors read a held fact; one query door removes the class.

## 7. avra-held-findings

- `held-findings`, HEAD `9ba5fd5` 2026-09-30; cherry `-`; on main #61 `2f7f94c`. Clean. Ticket `.57.126`.
- Body: "The cli's cold, warm-edit and hit checks each give 57 sites with no diff (53 warm before)"; witness "exit 0 before, exit 1 after".
- Verdict: **ABANDON** (landed).

## 8. avra-mh-held (group F) and avra-witness-delete

- `avra-witness-delete`: `perf/witness-delete`, HEAD `14e1a47` 2026-09-29 (merge); own `7754472` (`+`, not an ancestor of main). Clean.
- `avra-mh-held`: detached at main `bc2d64a`, **interactive rebase of `perf/mh-held` stopped in conflict** (`UD witness.av`); 35 staged paths = `7754472` re-applied; next pick `4fef2a3`.
- Ticket: `avra-8sb5.57.55`, `.57.6.4`, `.57.119`.
- `7754472`: deletes `compiler/witness.av` (1059 lines), `store/pack.av`, `store/explain.av`, NameReads tracking. Reason in body: "COMPILER DB townhall §6.5a: the durable witness is the hold
  path's own file-grain KeyParts … kernel-grain deps stay in-process. witness_enabled was already false — this machinery has computed nothing since it landed."
  On main the same files are gone via #109 `83d4877` (`ls witness.av` → no such file; `store/` holds only `store.av`). Superseded.
- `4fef2a3` (not on main; `MHC` 0 hits in main's `tools/cache_attacks.sh`): post-mortem of a test confound — `--time`'s "read:" list "unconditionally names the entry file whenever the build does
  any work at all", so four assertions "measured nothing real". Corrected finding: a body-only edit in another package holds the importer; a signature edit to an export the importer
  never calls re-reads it, "because an importer keys on its package's whole exported surface, one digest per package". Also: `cache held` right after a `.Binary` build reports every file
  "read" because rule-finding rows were never written.
- Witness format that was deleted (still readable at `avra-fix-witness-base:packages/std-avrac/src/compiler/witness.av` and `store/pack.av`, commit `5725537`):
  entry = `{ name: string, fingerprint: int, hash: int, edges: List<Edge{name, hash}>, payload: Bytes }`; header doc: "a settled query's stable name and its deps' (stable name, value hash)
  pairs go into the package's `Pack` beside its answer. A later process … reuses the stored answer only when every one still matches"; an unresolvable dep "is a MISMATCH, never 'nothing to check'".
  Only 5 families could re-validate (Parsed, Namespace, Sig, Manifest, Methods).
- Verdict: `avra-witness-delete` **ABANDON** (superseded by #109). `avra-mh-held` **ABANDON the rebase**; **KEEP the `4fef2a3` finding** (entry confound; package-grain interface key).
  The deleted `witness.av`/`pack.av` are the closest prior art to the target saved-answer rule — recover from history, not from these trees.

## 9. avra-hold-new-decl

- `hold-new-decl`, HEAD `bc049cd` 2026-10-01; cherry `-`; main #108 `dcaba11`. Clean.
- Post-mortem: a `collect` was written to its module record as `opaque` (kind "fell through a chain of `is` tests"), so a held collect had no type; a re-read file naming it typed `<error>`
  silently; "the warm check fell back to a full rebuild (held 0/408, ~50 s)". Fix: one exhaustive `record_shape` match.
- Verdict: **ABANDON** (landed).

## 10. avra-warm-settle

- `warm-settle`, HEAD `dd33cdc` 2026-10-02; cherry `-`; main #195 `0f78ee7`. Untracked `tools/ws_build.sh`, `ws_repro.sh`, `ws_repro2.sh` (repro: a run that fails to link writes the hold, a warm run after restoring the object fires the defect).
- Ticket `avra-8sb5.34.21` (as cited in the body). Body: "before: 1 `Exchanged` settlement defect; after: 0 defects, 127/127."
- Verdict: **ABANDON** (landed). `avra-warm4-base` carries copies of the two repro scripts only → **ABANDON**.

## 11. avra-perf101-slice2

- Branch `perf101-slice4`, HEAD `be10ece` 2026-10-01; cherry `-`; main #182 `93acdd3`. Untracked: 5 A/B scripts.
- Numbers (body): "Warm one-line edit: 48 -> 6 parse_program events …; ast 799 -> 208ms, sublang 410 -> 161ms." Ticket comment adds "load 6415->708ms".
- Cause: three reads of a held file's parse/store when the record already had the answer (`line_words`, `instance_unit`, `const_answer` — "reading a held file's store parses the whole file").
- Verdict: **ABANDON** (landed).

## 12. avra-perf101-warm

- Branch `perf101-loadadmit`, HEAD `9add691` 2026-10-01; cherry `-`; main #142 `890d893`. Clean.
- Numbers (ticket `.101` 2026-10-01 21:12): "BASE WALL 4.72s / load 1324ms; FIX WALL 4.07s / load 796ms => wall -0.65s (-14%)"; "cache_attacks.sh = 181 builds, 66 held, 2 failed" (pre-existing).
- Verdict: **ABANDON** (landed).

## 13. avra-perf-warm-124

- Branch `perf/kept-settle-141`, HEAD `e61260b` 2026-10-01; cherry `-`; main #119 `68d33f2` (`kept_settle.av` exists on main, 324 lines; differs from branch by +6/−3). Untracked: 9 probe scripts.
- Tickets `.57.124`, `.57.141`.
- Numbers (body): warm one-line fmt.av edit, six interleaved rounds, one Sprite: "main 8391 8068 7749 8196 8059 7936 ms (median 8.06 s) / branch 6402 5733 5965 6221 5827 5935 ms (median 5.93 s), -26%. Files read on that edit: 20 -> 2".
  Sabotage: "validation trusts every row … (2/7 pass)"; "no reuse at all … (6/7 pass)"; as written 7/7.
- Design relevance (on main): `kept_settle.av` is a large hand-written validity check — per-line rules `kept_row_stands`, `kept_unit_stands`, `kept_file_stands`, `kept_const_stands`
  ("validates by replay — a unit by its file's text, else its declaration's syntax, else … its call shape lowered again"). It is the biggest single thing the one-saved-answer rule would replace.
- Verdict: **ABANDON** tree (landed); flag `kept_settle.av` on main as a migration target.

## 14. avra-perf-warm-parse

- `perf/warm-parse`, HEAD `fb53cec` 2026-09-30; cherry `-`; main #94 `5dedc2e`. Clean.
- Numbers: "check packages/cli after a warm fmt.av edit, callgrind on a Sprite: 36.5B -> 26.5B instructions (-27%)"; "80 lines, ~87M instructions each"; "75K refs".
- Verdict: **ABANDON** (landed).

## 15. avra-perf-m5b-cand

- `perf/m5b-names`, HEAD `b633486` 2026-09-30; cherry `+ 6371f8c`, `+ b633486`.
- `6371f8c` on main as #40 `0531e8b`. `b633486` on main by content: `voices.av:936-939` reads "The cells alone: the namespace is the file's, and `Visible` fingerprints it once per file" and
  `name_slice_fp` has no `namespace_fp` term (now 5 columns). NOT VERIFIED which PR carried it.
- Number: "packages/cli check, same input, 3 runs: +1.78% -> +0.20% instructions over base."
- Verdict: **ABANDON** (landed).

## 16. avra-perf-load-named

- `perf/load-named`, HEAD `81cc3d9` 2026-10-01; cherry `-`; main #124 `b8311ee`. Untracked 2 scripts.
- Numbers: "main 6905 6870 6026 6208 6231 6400 ms (median 6.30 s) / branch 4701 4231 4239 4264 4309 4476 ms (median 4.27 s), -32%"; "Instructions on main before #119: 34.16B -> 29.00B (callgrind)". Base main `57a35d8`.
- Cause: `mut t = c.get()` / write / `c.set(t)` copied the whole doc table per minted declaration.
- Verdict: **ABANDON** (landed).

## 17. avra-cache-* (5 trees)

| Tree | HEAD | cherry | main | Note |
|---|---|---|---|---|
| avra-cache-walk | `a1da8fe` 2026-10-01 | `-` | #107 `cc0040d` | cache modes refuse rather than read an empty pack |
| avra-cache-walk-2 | `7b45fa1` 2026-10-01 | `-` | #109 `83d4877` | pack/explain/witness deleted; `cache_walk.av` added; "The hold's kept KeyParts are the durable witness" |
| avra-cache-readonly | `00811b8` 2026-10-01 | `-` | #113 `11fd2d4` | `Keeping.Disk`/`Keeping.Aside`; `opened_store` at `build.av:185` on main |
| avra-cache-dead-param | `601efc4` 2026-10-01 | `-` | #123 `1a16888` | one dead parameter |
| avra-cache-red | detached `3f073ba` (main #111) | — | — | untracked `tools/cw_witness.sh` (47 lines) |

- `00811b8` post-mortem: "A cache mode derived the program under the hold as a check does and wrote the store as a check does, so after one `cache changed` the next said nothing moved … red on main (7 of 11 steps)".
- `cw_witness.sh` (untracked, cache-red): standalone copy of that attack — check, edit, run every `avra cache` mode in its own process, assert `changed` twice is identical and the store's
  bytes (`find … | xargs cksum`) are unmoved. The same steps were landed inside `tools/cache_attacks.sh` by #113 (per its body). NOT VERIFIED line-for-line.
- Verdict: all five **ABANDON** (landed / scratch). Design note: "reading the cache must not write it" was a real bug; with one saved-answer rule, inspection is a read of relations.

## 18. avra-fix-kept-package-key

- `fix-kept-package-key`, HEAD `51767ad` 2026-09-30; cherry `-`; main #73 `a20e7cb` (`reached_objects` at `build.av:619`). Clean. Ticket `.57.139`.
- Post-mortem: "program_key only ever hashed .av sources, manifests and engine files — never the compiled .o a package's manifest names. A C-only edit … moves no .av digest, so kept_binary reused a
  binary linked against an object that no longer existed". Fix adds each reached package's object bytes (`object_line` uses `digest_of_binary`).
- Verdict: **ABANDON** (landed). Lesson: an unrecorded input (a `.o` on disk) — exactly what "one input door" is for.

## 19. avra-fix-witness-base

- Branch `fix-witness-base`, HEAD = main `5725537`; uncommitted `M compiler/tests/witness_test.av` (−5/+2): replaces a per-run `/tmp/avra-witness-test/${now_ns()}` dir with a fixed path
  ("a witness spans two processes, which must name one pack"). The file was deleted on main by #109.
- Verdict: **ABANDON**. (Useful only as a checkout that still contains `witness.av` + `pack.av`.)

## 20. avra-srcstamps

- `fix/source-stamps`, HEAD `8016ea7` 2026-09-27; base `92b24db`; cherry `+ 8016ea7`; subject not on main; behind 1287.
- `8016ea7`: `Decls.mut_param_names` returned `[]` for a held declaration instead of reading `fn_parts(x.stmt)` — "a held (minted) declaration has no parse … `x.stmt` is the statement ordinal a
  STRANGER'S RECORD wrote" → trap "index 221 is out of bounds (length 181)" (ticket `.57.24`). Repro: clean cache, `avra test packages/std-avrac` then `avra check packages/std-avrac`.
  On main `mut_param_names` no longer exists (0 hits); the index is fed from the record: `decls_mint.av:500` `for name in f.mut_seats { self.mut_seat_index.put(…) }`. Superseded by a different fix.
- The branch's namesake fix is its base `92b24db` (ancestor of main): **source stamps decision** — "Workspace.kept_digest trusted a durable size/time/inode 'stamp' match to skip re-reading a
  source file … a file edited between two workspace constructions still answered its OLD digest" (`.57.19`, same shape as `.57.25` for the compiler binary). Fix: always read and hash.
  "Measured … warm `check packages/cli` (37 files) and `check packages/std-avrac` (730 files) both sit at ~36-42ms before and after". On main: `build.av:638-652`
  "A stamp match is a claim about the bytes, never the bytes; only the digest is."
- Verdict: **ABANDON** (superseded). The stamps decision is already main's law: digest, never mtime.

## 21. Group D — avra-cb-{0600b2c,33dcdb5,441d58e,c3275b7,e8d1641} and avra-stamp56-base

- All detached at commits on main (ahead 0). Each has one identical untracked `compiler/tests/consumes_probe_test.av` (73 lines; not on main): 14 cases for which fn seats the consumes
  pass marks consumed vs borrowed. `avra-stamp56-base` additionally has 3 `eprintln("DBGC …")` debug lines in `consumes.av` and `kb/wall.sh` (3 cold `check packages/cli` wall runs, no output saved).
- Purpose: a bisect of consumed-mark behaviour across M5 commits (likely ticket `.57.91` "consumed marks unstable across the hold boundary (held 659 -> 408)"). NOT VERIFIED.
- Verdict: **ABANDON** all six. The probe test is not cache-layer work; hand to whoever owns consumes if wanted.

## 22. Group C — avra-link-c004703 / avra-link-8d1149b / avra-lone-0448e89 / avra-lone-6a7d90f / avra-lone-main

- All detached; base `5a4c3cf` (lone-main = main `61721c7`); each has untracked `tools/.l.sh` (bootstrap + one test; no outputs).
| Commit | cherry | On main? |
|---|---|---|
| `6a7d90f` the compiler's relation Db records through the kernel (`.57.4.7`) | `+` | YES #72 `51bfc7d` |
| `0448e89` embed()'s file is admitted at parse | `+` | YES by content: `admit_embeds` at `whole.av:158,171`, `embed_computed_path` at `fns/check.av:651`; later reworked by #282 `04a6a89` |
| `8d1149b` admit lists a module's files uncached | `+` | YES by content: `listed_files` at `modules.av:97`; `workspace.av:1016` |
| `c004703` a file is data only when an embed named it | `+` | Reworked: `reads_as_source` is a Workspace method on main (7 hits); `embedded_file` name gone |
- Post-mortems worth keeping:
  - `0448e89`: a const's Settled query "minted embed()'s File row lazily, mid-read — … a row filed after the whole relation was already read this revision traps the write-once-after-read law".
    Fix = declare the input up front (scan parsed statements for literal `embed("…")`), refuse computed paths.
  - `8d1149b`: "its cache would answer the query that later reads the module, which then records no edge on the manifest" — a memo in front of the kernel swallowed a dependency edge.
  - `c004703`: `.av`-suffix test dropped a lone program's `<source>` — a string-shaped rule standing in for a recorded fact.
- Verdict: **ABANDON** all five (landed/reworked). The first two are the best in-tree examples of why outside reads need one recorded door.

## 23. avra-hashfix, avra-fp-tags, avra-mem-ceiling (not cache-layer)

| Tree | HEAD | Status | Note |
|---|---|---|---|
| avra-hashfix | `be776a2` 2026-09-30 `fix/map-hash` | `-`, main #53 `755a1fc` | runtime map hash; no DB content |
| avra-fp-tags | `2eb7da5` 2026-10-01 | `-`, main #115 `682e12b` | `opt_dispatch_fp` and `opt_decl_fp` shared tags 183/184 → two absences fingerprinted alike |
| avra-mem-ceiling | `67eefdb` 2026-09-30 `perf/mem-ceiling` | 4 `+`; all in #39 `1488379` (subjects in its body; `malloc_zone_statistics`/`mallinfo2` at `runtime/avra_runtime.c:579-582`) | "a 6000 MB ceiling once tripped with 894 MB in use" — the live-bytes ledger drifts from the allocator |
- Verdict: all **ABANDON** (landed).

---

## Ranked: most valuable unlanded pieces

1. **`avra-warm-memory` `235673b..9437242`** — the full list of what pins a derivation in memory and a single `discarded()` verb. Only live unlanded work in the slice. KEEP.
2. **`avra-warm101-11` uncommitted `ReachWitness`** — a working, measured instance of "saved answer = value + inputs + digests"; result: ~3% wall because inputs were whole-record digests,
   and the answer is asked before any kernel deps exist. REWORK into the kernel rule.
3. **`4fef2a3` (perf/mh-held, in `avra-mh-held`'s rebase todo)** — entry-file confound in `--time`'s read list; importer keys on a package's whole exported surface (`.57.119`). Finding only.
4. **`9aabcb1` + ticket `.101` comments** — three failed attempts at a hand-written view key (unsound → 3.7× slower → stale memo). The evidence for "no hand-written validity checks".
5. **Deleted `witness.av` / `pack.av`** (at `5725537`, e.g. `avra-fix-witness-base`) — prior implementation of (stable name, hash) edges per saved answer; disabled from birth, deleted by townhall §6.5a.
6. **`cw_witness.sh`** (`avra-cache-red`, untracked) — small standalone "inspection keeps nothing" attack; probably duplicated in `cache_attacks.sh`.

Already-landed code that the target design would replace (seen while checking): `compiler/kept_settle.av` (per-line replay validity), `record.av` `view_parts`/`seen_key`/`KeyParts`,
`build.av` `program_key`/`reached_objects`/`text_digest`, `derive.av` `findings_key`/`rules_key`.

## All measurements found

| # | What | Before | After | Command / setup | Commit · date | Source |
|---|---|---|---|---|---|---|
| 1 | Warm check-cli after fmt.av:275 edit, files held | 98/401 | 393/401 | `check packages/cli`, Sprite | `1c7ba69` · 2026-09-30 | commit body |
| 2 | same, wall | 69.8 s (double derivation) | 32 s (lower ≈ 28 s) | same | `1c7ba69` | commit body |
| 3 | Warm one-line edit, instructions | 274.6B | 25.3B (−90.8%) | `check packages/cli`, same input | `e203c0d` (#48) · 2026-09-30 | commit body |
| 4 | same, wall | 20.9 s | 2.3 s | same | `e203c0d` | commit body |
| 5 | Cold, instructions | 209.6B | 205.6B (−1.9%), peak flat | same | `e203c0d` | commit body |
| 6 | Warm fmt.av edit, callgrind | 36.5B | 26.5B (−27%) | `check packages/cli`, Sprite | `fb53cec` (#94) · 2026-09-30 | commit body |
| 7 | Warm fmt.av edit wall, 6 interleaved rounds | 8391 8068 7749 8196 8059 7936 ms (med 8.06 s) | 6402 5733 5965 6221 5827 5935 ms (med 5.93 s, −26%) | `check packages/cli`, one Sprite | `e61260b` (#119) · 2026-10-01 | commit body |
| 8 | Files read on that edit | 20 | 2 | same | `e61260b` | commit body |
| 9 | Warm fmt.av edit wall, 6 rounds, base `57a35d8` | 6905 6870 6026 6208 6231 6400 ms (med 6.30 s) | 4701 4231 4239 4264 4309 4476 ms (med 4.27 s, −32%) | same | `81cc3d9` (#124) · 2026-10-01 | commit body |
| 10 | Instructions before #119 | 34.16B | 29.00B | callgrind | `81cc3d9` | commit body |
| 11 | parse_program events on warm edit | 48 | 6 | QTRACE, warm fmt.av edit | `be10ece` (#182) · 2026-10-01 | commit body |
| 12 | ast / sublang phase | 799 / 410 ms | 208 / 161 ms | same | `be10ece` | commit body |
| 13 | load phase | 6415 ms | 708 ms | same | #182 · 2026-10-02 | ticket `.57.101` |
| 14 | Record-fault memo: wall / load | 4.72 s / 1324 ms | 4.07 s / 796 ms (−14%) | `./avra check --time packages/cli`, fresh edit, Sprite avra-sq-ffi | `9add691`/`38f9b94` (#142) · 2026-10-01 | ticket `.57.101` |
| 15 | `li_complete` | 601 ms | ~25 ms | same | same | ticket `.57.101` |
| 16 | Warm-edit phase table (base) | wall 4.43 s: ast 996, sublang 1021, load 1422, admit 1132, analyze 621, lower 679, keep 160, resolve 227, bodies 276, sigs 24 ms | — | `./avra check --time packages/cli`, quiet Sprite | main · 2026-10-01 | ticket `.57.101` |
| 17 | refs path | refs 538 ms (fresh 3, stand 118, restore 414, settle 1) | hoist: 650 vs 662 ms (noise) | same | — · 2026-10-01 | ticket `.57.101` |
| 18 | `view_print` key (unsound) | 2.46 s | 2.28 s (~8%; load −66 ms, keep −110 ms); cache_attacks 23 failed vs 2 | warm fmt.av edit | `9aabcb1` · 2026-10-01 | ticket `.57.101` |
| 19 | `view_print` extended (sound) | load 1019 ms | load 3824 ms | same | uncommitted · 2026-10-01 | ticket `.57.101` |
| 20 | `view_print` + per-build memo | — | cache_attacks 15 failed | same | uncommitted | ticket `.57.101` |
| 21 | Reach witness (warm101-11) | wall ~3.90 s; load 2231 ms | wall ~3.78 s (~3%); load 1667 ms; witness taken 70/70 | interleaved same-Sprite A/B, warm fmt.av edit | uncommitted on `0e67451` · 2026-10-02 | ticket `.57.101.11` |
| 22 | view_parts calls with any settled kernel cell | 0 of 70 | — | QTRACE, warm fmt.av edit | same | ticket `.57.101.11` |
| 23 | Name slice fingerprint cost over base | +1.78% | +0.20% instructions | `check packages/cli`, same input, 3 runs | `b633486` · 2026-09-30 | commit body |
| 24 | Held collect bug: warm check | held 0/408, ~50 s | holds | add/remove a decl in cli commands module | `bc049cd` (#108) · 2026-10-01 | commit body |
| 25 | Rule findings, cold vs warm-edit vs hit | 53 warm vs 57 cold | 57 / 57 / 57 | `check --baseline` packages/cli | `9ba5fd5` (#61) · 2026-09-30 | commit body |
| 26 | same, earlier draft | — | 67 sites each | same | `811eab7` · 2026-09-30 | commit body |
| 27 | Stamp cache removed: warm check | ~36–42 ms | ~36–42 ms | warm `check packages/cli` (37 files), `check packages/std-avrac` (730 files) | `92b24db` · 2026-09-26 | commit body |
| 28 | Held path vs fallback | full re-analysis | ~0.5 s warm | `test` then `check packages/std-avrac` | `9ecc31d` (reverted) · 2026-09-27 | commit body |
| 29 | `cache changed` twice attack | red 7 of 11 steps | green | `tools/cache_attacks.sh` | `00811b8` (#113) · 2026-10-01 | commit body |
| 30 | kept-settle sabotage | trust-all 2/7 pass; no-reuse 6/7 | 7/7 | `kept_settle_test.av` | `e61260b` | commit body |
| 31 | cache_attacks baseline | — | 181 builds, 66 held, 2 failed (pre-existing "did not cross as Line") | `tools/cache_attacks.sh` | main · 2026-10-01/02 | ticket `.57.101` |
| 32 | Memory ledger drift | 6000 MB ceiling tripped | 894 MB actually in use | runtime | `67eefdb` (#39) · 2026-09-30 | commit body |
| 33 | Settlement defect E2E | 1 `Exchanged` defect | 0, 127/127 | `avra test packages/std-action` after failed-link run | `dd33cdc` (#195) · 2026-10-02 | commit body |
| 34 | Drive harness leak (context) | ~30 MB/iter no disposal | ~0.84 MB/iter with `disarmed()` | `AVRA_DRIVE=8 … ./avra build packages/cli` | `69ece15` · 2026-09-22 | ticket `avra-h1st` |

All rows are MEASURED by their authors (quoted); none re-run by me. No memory (RSS/peak) number exists in any of the 42 trees for the warm-rebuild blowup.

# Handoff — lane `avra-lane-parity-wrong-answers`

Branch and file stem must be exactly `avra-lane-parity-wrong-answers`
(bundle sent as `/work/avra-lane-parity-wrong-answers.bundle`). Repo: `/work/avra`.

## Scope (as the lead set it, in order of arrival)

1. Parity: wrong answers and traps of the program layer vs the old path (`AVRA_PROGRAM=0`),
   RUN-ONLY programs, `type.struct_fields`, and a tail list of unheld "B" kinds — DONE up to
   batch 45c; the remaining tail singles are PARKED by the lead.
2. **The exact-count gate** (`make cost`, gate slice `cost`) — DONE, landed as one commit.
3. **`avra census --candidates`** (docs/ZERO_COST.md's classifier), phase 1 = techniques 1–7 —
   IN FLIGHT (WIP commit).

Kinds held by OTHER lanes (never take): lambda, variant_lit, unknown_prop, match, pattern (values);
mismatch (types); method, list_element, variant_arity, the `{}` map-verb voice (resolve-2); spread,
seat, list, alias_copy, record_pattern, spread_nullable, component_event (layer-commands); words /
false-refusals (C); the three arity traps (parity-types).

## Base

`batch53` = `d5062c32741cba87a5cb7964cb86e0a2768d5c1a` (from `/work/batch53.bundle`, prerequisite
d750dfa7). Every earlier commit of this lane has landed inside batch 53.

## Commits ahead of batch53

- `451ad9b8` The exact-count gate: every counter of fixed workloads held to its row — SENT to the
  lead (bundle batch53..451ad9b8), receipts all green, `GATE cost PASS` 42 rows 0 over 0 fell.
- `d56b77e5` WIP: avra census --candidates, phase 1 (techniques 1-7), and the cost gate's hardening —
  NOT sent, NOT through receipts.

`/work/handoff/lane.bundle` = `avra-lane-parity-wrong-answers ^batch53` (both commits).
`/work/handoff/uncommitted.patch` is empty (nothing uncommitted).

## The exact-count gate (landed design, for orientation)

- `tools/cost.sh`: builds the census compiler (`tools/census_compiler.sh`, builder `CENSUS_BUILDER`,
  default `build/avra`), `git archive`s the pinned snapshot (`snapshot` row of `tools/cost.baseline`)
  into `build/cost/src`, puts the census compiler at `src/build/avra` (so std resolves INSIDE the
  snapshot) plus the build's `*.o/*.a/avra_hot.*`, and runs, each cold, bare, one core
  (`taskset -c 0`), `AVRA_WORK_AHEAD_OFF=1`, `sleep 3` first (io.stamp's 2 s window):
  `check --counts packages/cli`, then the warm edits over its store, then `build packages/cli`,
  `check --counts packages/std-program`.
- Warm rows: the warm lane's `count.py` protocol exactly (`tapes --findings packages/cli`,
  `worked:` line, 8 edits of `cli/src/commands/cache.av`, each edit then a warm-back run).
- `tools/cost_ratchet.py`: tolerance 0.05% (lead's ruling), falls reported past 0.005%; accept only
  lowers rows over the same snapshot; `COST_SNAPSHOT=<sha> make cost-accept` moves the snapshot and
  records everything. `--edit` applies one edit; `--self-test`.
- Determinism (proven): checks and warm rows IDENTICAL run to run; cold build ±4 retains/±14 list
  reads (a file it writes and reads back inside the stamp window). Fixes that were needed: one core
  (emit forks one process per core otherwise and the census counts the parent only), clearing the
  build's leftover product binary (+86 boxes otherwise), `AVRA_MEM_STATS=1` (no report without it).
- Baseline: batch53's compiler over snapshot d5062c32 (lead: it carries a regression being bisected;
  the fix lowers the rows through cost-accept). Bisect: `COST_COMPILER=<census compiler of X>
  sh tools/cost.sh && python3 tools/cost_ratchet.py --judge build/cost`.
- Slice cost ≈ 17 min (census compiler 2.5 + cli check 4.6 + warm 3.5 + build 5.5 + program 0.6);
  with the candidate tables on, ≈ +18%. CI keepers job limit is 30 min — watch it.

## In flight: `avra census --candidates` (WIP commit d56b77e5)

Done in the commit:
- runtime (census-only, `runtime/avra_runtime.c`, `avra_hot.c/.h`): `streq:` site table (avra_streq
  callers), `move:` pairs (a retain then the release of that box with no rc op between; `note_retain(box,
  site)`/`note_release(box, site)`), `reuse:` pairs (a free — set in `death_noted`, needs
  AVRA_CENSUS_DEATHS=1 — then the next alloc of the same size_row, in `note_made`), generic `pair_in` /
  `report_pairs`. Compiles with and without -DAVRA_CENSUS.
- backend: `compiler/backend/strided_census.av` — `census_tags` = frame tags + `flat-pushed` on a
  record minted by `avra_array_sized`, filled by `avra_array_push*` of word/real/truth values only, and
  pushed into a list; `llvm.av` uses `census_tags`.
- cli: `packages/cli/src/commands/census.av` — `avra census --candidates [--root <tree>] <report>…`;
  registered in `main.av`. Prints `candidate: <technique> <count> <fn> <file>:<line>`, top 10 per
  technique; symbols `av_…$XX…` decoded; fn line found in the file under `--root`. Tested by hand
  (all 7 kinds, summing, pair-of-two-fns skipped, missing report → exit 1).
- `tools/cost.sh`: every run with `AVRA_CENSUS_SITES=1 AVRA_CENSUS_DEATHS=1 AVRA_CENSUS_TOP=1000000`,
  own empty `HOME`, `AVRA_MACHINE_STORE(_DIR)` unset; `resolved()` rewrites each cold run's site lines
  to symbols (`<w>.sites`, addr2line on `src/build/avra`); writes `build/cost/candidates.txt`.
- `tools/cost_ratchet.py`: `candidates_said` — prints `cost: new candidate: …` for each
  (technique, fn) not in `tools/cost.candidates` (REPORT-ONLY, lead's permanent ruling), and the
  accept writes that file.

How far: a full `CENSUS_BUILDER=build/avra-try make cost` with a fresh census compiler was running
at handoff (started 08:46, log `/tmp/cost-cand.log`, outputs in `build/cost/`). The cold cli check had
finished: tables populated (54,231 site lines; 7,919 move/reuse/streq; 6 `flat-pushed` sites), and
its counters were +1,210 boxes / +1,810 retains over the batch53 baseline (≈1e-6, within 0.05%, NOT
identical). Likely cause, unproven: the census compiler now runs the strided tag pass while compiling
the snapshot (census types are on in that binary), i.e. real extra compiler work, not noise.

## Next 3 items, in order

1. Finish the proof run: `CENSUS_BUILDER=build/avra-try make cost` must say 0 over (rises ≤ 0.05%
   pass). Confirm the +1e-6 drift is the strided pass (e.g. compare a census compiler built without
   `census_tags`' flat_pushed). If it is, record it (`make cost-accept` over the same snapshot cannot
   raise rows — so either leave the baseline as is, since it passes, or ask the lead whether to
   re-record). Check `build/cost/candidates.txt` looks right (≤ 10 per technique, real file:line).
2. Write `tools/cost.candidates` from that run (`python3 tools/cost_ratchet.py --accept build/cost`
   writes it, and also lowers rows — only acceptable if no row fell for a spurious reason), then turn
   the WIP into a proper commit (message without "WIP", idioms `check packages/std-avrac` and
   `packages/cli` with `--baseline tools/idioms.baseline`, fmt), add `avra census` to docs/ZERO_COST.md
   if needed, run full receipts, bundle `batch53..HEAD` (or newest batch), post ≤ 12 lines.
3. Phase 2 of the classifier: deforestation (a list made and walked once — needs per-list read counts
   at death) and devirtualization (an indirect call with one target — needs a census hook at each
   `CallPtr` in emitted code). Then the parked tail singles if the lead re-opens them.

## Open rulings / asks waiting on others

- None blocking. Given: tolerance 0.05%; one commit; baseline at batch53's compiler; candidates
  report-only permanently; the warm rows (all work, one process) are the measure, and the warm lane
  re-bases its design budgets on them (lead told it).
- Parked: `table<int>` / literal under an owned type — wait for parity-resolve-2's voice "`X` is a
  type the language owns; a record literal can't make one" to land, then check it once (layer must
  say it for int/float/…/ptr/void/Bytes/Range; pin known-to-differ vs the old path's wrong words).
- Tail singles left (parked by the lead): param_default in a trait, `Self` in a trait static fn,
  map_entry ×2, within ×2, select, spent_arm, chain, propagate, applied, binding (dyn), catch,
  coalesce_never, impl, infer_result, interp_hole, list_scalar, task_escape, type_value, unread_mark,
  resolve.unresolved `let x = Bytes`, the order-only ones need nothing. Program sets: `/tmp/bk/<kind>/<n>/x.av`
  (lost with the container; regenerate from `/work/split-736.tsv`).

## Rules this lane works under (lead's, verbatim essentials)

- Commit as you go; push NOWHERE (no git push, no gh); never print/post credentials.
- No `rm` (use `find … -delete`), no `git stash`, no `git reset --hard`, no `--no-verify`.
- Fix root causes; declarative, general code; comments evergreen and terse; a law never assembles
  prose (named voice fns, shared with the old path via `said_as`); idioms baseline 0 NEW.
- One heavy job at a time (15 GB machine); never end a turn with a build running; one foreground wait,
  no polling loops of many turns.
- TOKEN RULE: post only at a bundle, a blocker or a ruling; ≤ 12 lines, numbers first.
- Every bundle's receipts: layer `AVRA_MEM_POOL_MB=12500 build/avra-try check packages/std-avrac`
  exit 0; idioms 0 NEW; `sh tools/gate.sh avrac-a`…`avrac-g` and `refusal-a/b/c` all PASS with no
  unpinned failure (and now `sh tools/gate.sh cost`). A gate red not from your own commits is REPORTED
  to the lead, never fixed.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01F8zAGdAmJ7HHi46XYh8si9`. Never name the model in
  commit text beyond that trailer.
- Bridge: `mcp__claude-bridge__post_to_controller` / `send_files` with the session token the new
  account's bridge note gives (this one's was `cse_01F8zAGdAmJ7HHi46XYh8si9.32a2bad420dad2fe0579`).

## Things a fresh session trips on

- `. /etc/profile.d/avra.sh` first (LLVM 22, `AVRA_CAP_MB=12000`, `AVRA_MEM_CEILING_MB=12000`).
- `make try` builds `build/avra-try` (the compiler of the tree); `build/avra` may be older — use
  `CENSUS_BUILDER=build/avra-try` for cost runs unless `make avra` was run. `build/avra.census` is the
  last census compiler (built from d56b77e5's tree) — `COST_COMPILER=build/avra.census` skips 2.5 min,
  but rebuild it after any runtime/backend change.
- `tools/cost.sh` needs `taskset` (Linux) and `git` objects for the snapshot sha (it fetches by sha in a
  shallow clone).
- The census report needs `AVRA_MEM_STATS=1`; site/pair tables need `AVRA_CENSUS_SITES=1`, `reuse:`
  needs `AVRA_CENSUS_DEATHS=1`; census binaries have no line tables (addr2line gives fn only).
- Refusal witnesses: `tools/program-refusals/<case>/`; pin helper `parity-wrong-answers/pin.sh <case>
  <source>` then `PIN=1 sh tools/witness_program_refusal.sh build/avra-try <case>`; known-to-differ =
  a `differs.why` file.
- Python edit scripts: write them with the Write tool and run `python3 -I <file>`; nested heredocs in
  one shell command broke twice.
- `List.reverse()` is refused by the language; `read_text(p) catch null` does not make a nullable.
- Helper scripts copied to `/work/handoff/parity-wrong-answers/`: `receipts.sh` (all receipts in one
  background job), `census_measure.sh` (the determinism measurements), `pin.sh`, and
  `lambda_fnless.patch` (already landed as 39f6db76; kept for reference only).
- Scratch worktrees: `/work/base-wt` (detached, used for baselines), `/work/census-src` (an old
  plain export, safe to delete).

# Lane handoff — avra lane "b46" (cache family + kind-6 old-path removal)

## Lane and scope
Controller: Lead. This lane owned:
- the cache-attack family: layer cache correctness, attacks plus gate rows in witness-b;
- the program-layer P0s it was handed;
- switch-list KIND 6: tool commands still on the old path.

Standing rules:
- Commit on the branch; never push.
- No `rm`, `git stash`, `git reset --hard` or `--no-verify`.
- Run `build/avra fmt --write <files>` before committing.
- Idioms must show 0 NEW on every touched package.
- One heavy build at a time.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01F8zAGe4q8jm1pWMWefeLL2`.

## Base
- Branch `avra-lane-b46` in `/work/avra`, on top of **batch53** (d5062c327, branch `batch53`).
- `lane.bundle` = `avra-lane-b46 ^batch53`; prerequisite batch53, itself on d750dfa70.
- No uncommitted work (`uncommitted.patch` is empty).

## Commits ahead of batch53, oldest first
| sha | what |
|---|---|
| 7a0a8c3f7 | Seat refusals offer the old path's conversion fix. A fix knows its item and its confidence tier. |
| 0a563b697 | `avra fix` / `fix --repair` on the program layer. Witness: `tools/witness_program_fixes.sh`, cases in `tools/program-fixes/`. |
| 38fe818ec | Gate row: fix witness in witness-b. |
| 8386d7a6f | Idiom fix: a fix's item is found by statement identity. |
| 5fdabd1c9 | `holds_manifest` cut query, plus `root_listing_attack`. Batch52 landed the same fix as b8b16fa7; the merge took batch52's text. |
| 2894f2e5d | `tools/two_compilers_attack.sh`: two compilers, one cache, no shared answers. |
| 029f2f017 | macOS print P0: a compiler's identity comes from its own image. Runtime `avra_self_path` (realpath on macOS) feeds `own_binary`, and the stamp-withheld print path now traces. |
| 5fe76af82 | Merge batch53: item_refused conversions, gate rows unioned. |
| ef9f6e69e | `tools/flow_trace_swap_attack.sh`: swap compilers, run flow-trace once (witness-b row). |
| ddfcc4207 | KIND 6 item 3: `avra test` suite discovery on the layer, no old Workspace. Discovery is `suite_roots`, `programs_in` and `root_sources`. |

Sent to Lead, not yet confirmed landed:
- `avra-lane-b54.bundle` = batch53..5fe76af8, for batch 54.
- ef9f6e69 and ddfcc420: committed, not bundled or sent.

## In flight
Gate on ddfcc420 (base batch53) had started when the handoff came.
- idioms-cli: PASS. idioms-avrac: PASS.
- cli, witness-b, program, doors-a, doors-b: not finished.
- Rerun with `sh tools/gate.sh <slice> batch53` for each slice.
- Expected FAIL in `program`: the `rt-ns` row. This is batch53's own defect: `rt.av` is stale against 9f87c4b9's 3-argument `avra_ctx_reframed`. Fix with `./avra runtime-namespace > packages/std-avrac/src/features/rt.av`. Reported to Lead, not touched here.

## Next 3 items, in order
1. **Finish the ddfcc420 receipts, then bundle `batch53..HEAD`** (or against the newest batch ref Lead sends) and send it.
   - Parity already checked on std-url, std-queue, std-meta, std-relation and std-task: same tallies and exits.
   - Old-path trace lines on `avra test packages/std-url` went from 16 to 0.
2. **Port `rule_fix_test.av` (40 cases) and `rule_proof_test.av` (27 cases)** to the layer. They live in `packages/std-avrac/src/compiler/tests/` and currently use the old `Program` API. The harness lane named this lane as owner.
   - Plan: move the layer's application-making out of `packages/cli/src/commands/fix_program.av` (type `Fixing`) into `packages/std-avrac/src/compiler/item_fix.av`.
   - Parametrise it by a function that returns an engine over the edited text. The cli supplies a disk overlay (`disk with { over }` plus `entered()`); tests supply `files().set` from `compiler.tests.support` plus `avra_source_world` (see `item_signatures_test.av` for the pattern).
   - Then port each case with the same expectations.
3. **KIND 6 remainder.**
   - `flow.broken` and fix/--repair are done; test discovery is done (item 3).
   - The `tapes` receipts are deleted with the old path (ruled).
   - The `explain` cancel view and per-file why are in ROADMAP (20b86667).

## Open rulings and asks waiting on others
- **macOS shared-cache P0:** 029f2f01 fixes the identity hole, reproduced on Linux with a link named as another compiler. It is not confirmed on the Mac.
  - Ask: run the batch-54 binary under `AVRA_QTRACE=1 build`. It should now print `Q print …` on every path.
  - Ask: run `TWO_A/TWO_B sh tools/two_compilers_attack.sh` there.
- **flow-trace first-run flake:** closed by Lead. Likely cause: laws-fusion's compiler predates d8454279. If `flow_trace_swap_attack` trips in a gate, that run's layers dir is the data.
- **Layer `check` cascade:** after `resolve.no_module`, the layer `check` also says `type.unknown` and `resolve.unresolved`; the old path says only the first. Not raised as an item.
- **fix witness:** `13_impls_default_override` is known to differ. The layer runs no `impls.default_override` rule.

## What a fresh session will trip on
- **Build:**
  - `AVRA_PROGRAM_NET=0 make try`, then `cp build/avra-try build/avra.new && mv build/avra.new build/avra`.
  - About 10 to 15 minutes. Never two heavy builds at once.
- **cli, doors and refusal suites:** need `CC=/opt/wasi/clang WASM_CC=/opt/wasi/clang WASI_SYSROOT=/opt/wasi/wasi-sysroot-25.0`.
- **wasm runtime archive:** goes stale after runtime changes. Run `make wasm-runtime`, otherwise 9 `avra dev` cases fail with an undefined `avra_rc_release`.
- **Disk:** fills fast. False failures appear at under about 3 GB free. Clear with:
  - `find build/scratch -mindepth 1 -delete`
  - `find /root/.avra/cache -mindepth 1 -delete`
  - the `/tmp/tmp.*` directories.
- **Concurrency:**
  - The gate rebuilds from the working tree, so don't edit or swap `build/avra` while a slice runs.
  - Running tests beside a gate starves the memory pool (warnings-b fails with "waiting for memory").
- **Binaries out of place:** a binary copied out of its tree finds no std. Any witness then silently reports "0" (for example, "0 cases lowered").
- **Leftover case directories:** a branch switch leaves `.avra-cache` directories in `tools/program-refusals/<case>`. These are now named as leftovers via `tools/lib/cases.sh`.
- **Kept binaries:**
  - `/work/gens52/`: batch-51 pack generations and others.
  - `/work/suites-binary/sb/avra-try.572c1d99`: the resolve-2 binary that showed 4.
  - `build/avra-standing`: Nov 17. `build/avra-ctx`: Nov 18.
- **Scratch logs:** `/tmp/claude-0/-home-user/b66d3968-8f83-55c2-b093-9100fccb8b81/scratchpad/` (`rc*.log` are gate runs).
- **Bridge to Lead:** `mcp__claude-bridge__post_to_controller` and `mcp__claude-bridge__send_files`, session `cse_01F8zAGe4q8jm1pWMWefeLL2.07461cc2dcb11c18ff53` (this account's; the new one will differ).

## Files in /work/handoff
- `HANDOFF.md`: this file.
- `lane.bundle`: `avra-lane-b46 ^batch53`.
- `uncommitted.patch`: empty.
- `red-both-ways.md`: the queue table, with cache-attacks, whole-reads and inputs marked done.
- `program-fixes/`: a copy of the fix witness cases.

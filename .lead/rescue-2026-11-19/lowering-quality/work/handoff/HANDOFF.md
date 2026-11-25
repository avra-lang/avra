# HANDOFF — lane `avra-lane-lowering-quality` (Claude, session_01F8zAGbRJMZ3mcmRep8NJWk)

## Lane and scope
Lowering quality on the program layer (`AVRA_PROGRAM`, the new pipeline; `AVRA_PROGRAM=0` is the old path):
soundness rows, then measured runtime cost of lowering, then missed-optimization remarks, then small
fixes the lead sends. Lane brief rules: no `rm` (use `find ... -delete`), no `git stash`, no
`git reset --hard`, no `--no-verify`, push nowhere (no git push, no gh), never print/post a credential,
`build/avra-try fmt --write` on touched .av files before committing, ONE heavy build at a time, don't end a
turn while a job runs, post to the lead only at a bundle/blocker/ruling (at most 12 lines).
Commit trailers: `Co-Authored-By: Claude <model> <noreply@anthropic.com>` and
`Claude-Session: https://claude.ai/code/session_01F8zAGbRJMZ3mcmRep8NJWk`. Bridge: `post_to_controller`
with the session token from the bridge note.

## Base
Branch `avra-lane-remarks` in /work/avra, HEAD `af3728b7`, = batch 55 (`e0e3b361`, prerequisite
`d750dfa7`) + my four commits. Bundle: `/work/handoff/lane.bundle` (`^d750dfa70`). Working tree was clean
at handoff (uncommitted.patch is empty); nothing is WIP.

## Commits ahead of batch 55 (`e0e3b361`)
- `abefc0ec` missed-optimization remarks, each a typed reason (`Declined` enums per technique, `CostRemark`,
  `cost_remarks` query, `avra explain --cost @fn`, spec `compiler/tests/cost_remarks_test.av`).
- `72b5a2de` `is` on an instance of a declared generic is allowed; dyn reads take no bounds test (proven_read).
- `463742a1` `==`/`!=` on `ptr` compare addresses.
- `af3728b7` merge of batch 55 (ptr joins core/checking.av's ONE `compares_by_value`; stays out of `makes_key`).
Already LANDED by the lead earlier: static vtables (92f60332), dyn tag from full type identity (50782690),
all ir-gaps rows, pins rewritten to properties.
Lead said: remarks queued for batch 54; dyn call at 10 instrs + ptr equality "into batch 55" (those two are in
batch 55 already as 72b5a2de/463742a1 only if the lead took the earlier bundle; the lead asked me to merge
batch55c and send `batch55..HEAD` — NOT YET SENT, see below).

## In flight and how far
1. **Send `batch55..HEAD` bundle (remarks + is/ptr + merge) to the lead.** Merge built (`make try` exit 0).
   Verified on the merged build: `ptreq` probe prints `true true false`, spine_test 27/27, narrows_test 14/14.
   Still running/unverified when I stopped: cost_remarks_test and impls_test (background task
   bjjyle1h5 / b0nc9r6tv, output under /tmp/claude-0/.../tasks/). Then run the gate slices on `af3728b7`:
   `sh /work/probes/receipts.sh avrac-a avrac-b avrac-c avrac-d avrac-f cli sound findings-a doors-a doors-b`
   (copy in /work/handoff/receipts.sh; it does `cd /work/avra`, logs to /work/probes/receipts.log) and
   `sh tools/gate.sh idioms-avrac <base sha>` / `idioms-cli <base sha>` (they NEED a base sha argument).
   Then `git bundle create /work/<name>.bundle e0e3b361..HEAD` and post.
2. **Dev-backend note (#12, a MEASURED DESIGN NOTE, no code)** — barely started. Measure what a dev build's emit costs
   per function today (our IR -> LLVM IR build vs LLVM -O0 codegen vs object writing, per kind of fn) and
   estimate cost to build and savings of a direct dev emitter (IR -> machine code arm64/x86-64, no LLVM).
   Facts found so far:
   - `AVRA_EMIT_TIMES=1` makes the build print one line: `emit: N module(s), F fn(s), I instruction(s); built
     X s CPU, waited for a worker Y s; workers: passes P s CPU, codegen C s CPU; first hand-off to last object Z s`
     (backend/llvm_wrapper.c ~l.36-110, 1590-1690, 1775-1810). "built" = our IR -> LLVM IR on the program
     thread; passes = LLVM optimizer (skipped at level 0; level 0 only runs `lower-switch`); codegen = LLVM
     codegen + object to memory buffer. Object writing (`file_put`, rename) is not separately clocked.
   - A warm `avra-try build packages/cli --time` printed `analyze 1720ms, lower 184ms, emit 6476ms, link 410ms`
     (/work/handoff/devb-warm-cli-build-time.out) — that is WARM (objects held in store), not a cold emit.
     For a real number clear BOTH stores (see below), then `AVRA_EMIT_TIMES=1 build/avra-try build packages/cli --time`.
   - Per-kind-of-fn split is not measured yet: needs per-fn timing in the wrapper (add a clock around each
     fn's build and a per-module codegen split by instruction count) or bucket modules by size.
   - Backend code: packages/std-avrac/src/compiler/backend/llvm*.av (1047+907+133 lines of Avra) and
     /work/avra/backend/llvm_wrapper.c (1922 lines); IR interpreter: backend/interp*.av.
3. **Remaining small asks / ideas I raised**: (a) the engine-based copy `compares_by_value(engine, ty)` in
   compiler/item_signatures.av is still a SECOND spelling of core's law (batch 55 kept it; ptr is in both);
   ask the lead whether to fold it into one; (b) the table's bounds-check removal is done; a cold-run number
   must clear both caches (below).

## Next 3 items, in order
1. Finish the verification above on `af3728b7`, post receipts, send `batch55..HEAD`.
2. Dev-backend note #12 (measure, then write the design note; post as a bundle/markdown, no code).
3. Whatever the lead sends next (the lead has asked for small measured items: e.g. strided-list remarks once
   batch 5x has strided lists — `PackDecline.FlatRecord` marks where they apply).

## Open rulings / asks waiting on others
- Lead: take `batch55..HEAD` (not yet sent). Nothing else blocking.
- parallel-main confirmed the 2x cold-run regression was two resolve-2 law regressions (fixed), not vtables.

## Things a fresh session WILL trip on
- **Cold means BOTH stores**: `find <pkg>/.avra-cache <repo>/.avra-cache -delete` AND clear `/root/.avra/cache`
  (machine store, content-addressed). Measured: cold `check packages/cli` = ~325 s with both cleared, 113 s with only
  .avra-cache cleared.
- Environment: `. /etc/profile.d/avra.sh` before anything (LLVM_PREFIX, CC, AVRA_CAP_MB=12000, AVRA_MEM_CEILING_MB=12000).
  Use `build/avra-try` (the dev compiler built by `make try`); `make avra` builds release `build/avra`.
- Disk is tight (~5-7 GB free at times). Worktrees with copied `build/` dirs (4+ GB each) filled it once: /work/tg
  (6 GB), /work/b41, /work/rm are scratch worktrees; remove with `git worktree remove --force` (no `rm`!).
  /work/probes/avra-try-old = a pre-vtables compiler (d251b801) for A/B timing; cli-old/cli-new are the two cli
  binaries compared (large; delete when done).
- NEVER edit /work/avra while a gate runs (the gate builds from the tree). Use a worktree.
- `git cherry-pick` has NO `-q`. `table` is a reserved keyword in Avra. `Remark` already exists in core/nodes.av
  (mine is `CostRemark`). A python heredoc containing `$` is refused by the shell safety check: write script files
  via the Write tool and run them.
- `packages/cli/src/.main.print` is an untracked build leftover that blocks merges; move it away.
- A test run with plain `avra-try test <file>` for impls_test shows 3 old refusal cases failing (lines ~126, 545, 551)
  that PASS under the gate (avrac-c): judge by the gate, not the direct run.
- Gate: `sh tools/gate.sh <slice> [base-sha]`; slices used: build avrac-a/b/c/d/e/f/g cli sound findings-a doors-a doors-b
  refusal-a/b/c witness-b edit-a..g idioms-avrac idioms-cli. Detached runner pattern:
  `setsid nohup sh receipts.sh <slices...> >/dev/null 2>&1 &` then wait on `ALL DONE` in /work/probes/receipts.log.
  Background shell commands time out at 30 min; the sandbox suspends ~9 min after a turn ends with a job running.
- witness-b grain regression seen once at batch 52 was NOT mine (passes on 643928aa).

## Probes and notes (this directory)
ir-gaps.md (the rows and their closures), avra-lane-lowering-quality.md (lane notes), receipts.log + receipts.sh
(gate receipts), devb-warm-cli-build-time.out (the one warm build time), dynp-main.av (dyn call/box/`is` probe;
disassemble with objdump -M intel), rmk-probe-main.av (one site per remark; run `avra explain --cost @work` in a
package with that main), ptreq-probe-main.av (ptr ==). Probe packages themselves live in /work/probes/{dynp,rmk,ptreq}.

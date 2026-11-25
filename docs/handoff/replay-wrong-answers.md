# HANDOFF — lane: replay-wrong-answers (store lane), 2026-11-25

## Goal
Warm check ≤0.3 s with warm == cold byte for byte; the store held sound (Lead's store program).

## Base
gh/program e02d71ab (GitHub avra-lang/avra, branch `program`). All branches below are rebased onto it.

## Branches (GitHub avra-lang/avra)
- lane/replay-wrong-answers/store-program @ e52470b233f068894a1f064eb3478ad9ed57937b — DONE, pushed, waiting for the gate.
  11 commits: 2 store fixes ("a place that comes back is a root", "a rebased chain keeps the roots its deltas made"),
  the input door inside query bodies + `inputs` gate slice + --planted + --self-test, `avra cache check` (fsck),
  the model-based store fuzzer + 6-regression set (`make store-fuzz-regressions`) + `store-fuzz` slice,
  inputs classification for d7cd84d9 and for e02d71ab's Apple toolchain (shared.av).
  Tested: regression set on c9780be7, all 6 found, 2063 s; slices `inputs` and `store-fuzz` PASS; idioms 0 new.
  Cost: check-cli-laid (snapshot 91ebc6c5) queries = base, rows ≤ +0.02%.
  Not yet done on e02d71ab: a full build + test pass (only the inputs keeper and fmt were re-run there).
- lane/replay-wrong-answers/warm-noop @ 740f4068f505375b9d417b15ccacfdd2000156a5 — DONE, pushed, stacked on store-program.
  The base lists its inputs; stamps are decoded once when asked; stamp paths are normalized once, where kept.
  Warm noop −26.8% instructions. Train23's idiom reds are fixed; ledger-cold-b check-program lower row = base.
- handoff/20261125-1144/replay-wrong-answers — WIP (below), on top of warm-noop.

## Half-done: ticket "witness_disk_full" (the heir case) — commit "handoff: WIP …" on the handoff branch
Files:
- backend/llvm_wrapper.c: said_line(), so a backend message is one write() and parallel emitters no longer splice
  lines. Built and tested OK.
- packages/cli/src/commands/std_answers.av: the "std answers couldn't be laid" message now says the disk's free bytes.
  Built OK.
- packages/std-program/src/disk_store.av: the heir's record `saving.unfinished` is reserved up front (padded to
  UNFINISHED_ROOM=4096 by save_left), the failure cause is written IN PLACE (truncate + append) in save_finished,
  and the next build says it ONCE (the process whose remove() succeeds).
  Works when the disk still has room at save_left time ("save of … failed: …No space left (0 bytes free there)").
  STILL FAILS when the build itself fills the disk before save_left (8 KB tmpfs, two packs written first): the
  record stays 0 bytes, and the next build says nothing.
  NEXT: reserve the record's room BEFORE the build writes any pack to that store (e.g. at save_held / when the
  store is opened for a save), or say a 0-byte record as "the last build's save of X failed: no room was left to
  say why (N bytes free there)".
- tools/witness_disk_full.sh: my local edits (object case 16 KB, wait for the heir before umount). spec-harness has
  fixed the witness on their branch (commits 5a7b20e1, 63030d3b: 8 KB store mount, heir wait, edit check).
  Prefer theirs; drop mine if they conflict.
Repro (spec-harness's): /tmp/claude-0/rp/heir.sh <compiler> on this VM, or the steps in their message: tmpfs 8k on
<pkg>/.avra-cache/tapes, `env -u AVRA_STORE_KEPT_HERE AVRA_CACHE_DIR=$w/machine avra build <pkg>`, sleep 5,
build again → it must say "save of … failed: … No space left" with the free bytes.

## Next (in order)
1. Gate store-program, then warm-noop (Lead).
2. Finish the heir case above, then `sh tools/witness_disk_full.sh build/avra` on spec-harness's fixed witness.
3. Store soundness P0 .101.1, the input door enforced. The keeper part is in store-program; what's left is to decide
   the 47 listed query-body reads (tools/query_reads.baseline: door, record, or argued licence), and to close the
   keeper's method limit (reads behind methods aren't followed).
4. witness_place_kill: DROPPED per spec-harness (the witness was stale; they fixed it).

## Open questions
- Should the regression set (`make store-fuzz-regressions`, ~35 min, one compiler build per bug) run on a schedule?
- Census numbers used snapshot 91ebc6c5; the gate's ea25dd42 was never reachable from this VM.

## Runs in flight
None.

## Local state on the old VM (lost after the switch)
Worktrees /work/store2-wt (branches gh-store-program, gh-warm-noop, wip-handoff), /work/l1, /work/c978-wt.
Census scripts are in /tmp/claude-0/rp (census3.sh, laid2.sh, ledgerb.sh); they're throwaway.

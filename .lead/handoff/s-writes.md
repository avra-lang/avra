# s-writes (Sonnet lane) — handed off
Branch hd-writes2, worktree ../avra-s-writes, sha 0c36f9b7 (pushed), on origin/hd-clean 9654c99a.
Commit hook needs build/avra: symlink to ../avra-hd-int/build/avra plus build/.avra-built-from and .avra.print copied from ../avra-hd-fixes/build.

## Done (ONE_PATH point 8)
- cancels/record_cancel and written_seats solve on the engine Fixpoint (families CancelBits, Writes), one SCC at a time:
  scc_walk keeps demand order (granularity tests unchanged), each set is one `Fixpoint.solve`.
  Cancel: cancel_reach.av (settle_cancels, cancel_contribution, cancel_ensured). Writes: receivers.av (settle_writes, writes_contribution, writes_ensured).
- Engine: Fixpoint.answer_at (nullable read, records the dep) in std-relation fixpoint.av.
- Decls hooks now return the answer: ensure_cancels -> CancelReach?, ensure_writes -> List<bool>?.
- Deleted: scc_fixpoint callers, reset_written, clear_written, seat_written_so_far, written_bits, writes_held, cancel_held, Bypassed.Written (bypass.av, dep_audit.av, idioms.av, test).
- KEPT for held fns only (lead's order, dies with the hold / saved per-decl answers): Decls.cancels + record_cancel, Decls.written_seats + record_seat_written, read as fallback when the fixpoint holds no member.

## Evidence
- run 41432966301: check std-avrac green. run 41479488781: std-json 183/183 (the LLVM verify failure in the full gate is gone), the 8 held-bit tests pass.
- run 41490273878 (0c36f9b7, `test packages/std-avrac/src/compiler`): 1835/1837.

## Open bugs (the only 2 red compiler tests, both mine)
1. compiler/tests/aftercall_test.av:30 "calls that reach no cancel point carry no test": tests(["fn one() -> int { 1 }","fn two() -> int { one() + one() }","two()"]) == 0, now > 0.
2. compiler/tests/lower_test.av:416 "loop's condition settles every turn" (cond_mint_settled).
Both lone-program lowering via ir_of. Restoring reach_of's unguarded `cancel_bits_of(d)` did not fix them. Suspects:
cancel_ensured's comptime/Resolved guard, the cancel_walking re-entry returning null (-> reaches_both), or answer_at returning null for a member
whose cell was not solved yet. Next step: in a scratch test print ws.decls.cancel_bits(one) after lowering; compare with hd-clean.

## Not done
- Full gate on a green tree (last full gate 41451626735 was before the held-read restore); cli warm/comment-edit medians of 5; cold == warm.
- Two commits split (mine is one commit; cancel and writes share workspace.av/decls.av/interface.av).
- Next item from lead: Raised and DeclReads onto the same Fixpoint as @query; send design first if SCC-settled queries need a new engine mark. Not started.

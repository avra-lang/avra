# avra-lane-refusals-body-laws — hand-over
Branch avra-lane-refusals-body-laws on next-base cd4738e6. Head: the commit holding this file.
DONE and in next-base: bundle 1 (mixed_bitwise, defer, errdefer, defer_inert, task_escape) and bundles 2+3 (force, propagate, fail, yield, shift_count, list_scalar, struct_scalar, enum_payload; task capture/answer/overwrite; defaults).
ON THIS BRANCH, NOT HANDED BACK:
- 5a99f990 gaps: force/propagate on T, dyn and const names; fail in a seated lambda; unowned tasks; nullable Task counts as a task (holds_tasks). 10 cases. Gated on cd4738e6: idioms 0 NEW, cli program build 0, findings 0 errors x5, suite 295/305 hold, 0 failing, cli --built exit 0. Not run: --ran, edit witness, sound check (gate stopped by the owner order).
- 9dbb03ee + 43143d87 the differential: tools/witness_program_differential.sh (+ .py), tools/witness-files (dumper), export witness_files() in compiler/dev/witnesses.av. On cd4738e6: 84 SAME / 82 ACCEPTED / 46 UNBUILT / 14 OTHER-ERROR / 13 COMPILER-DEFECT / 9 WARN-MISSING; table at /work/avra-differential-cd4738e6.md.
- c78d792f WIP, NOT BUILT: loop.jump / loop.label as body laws (span containment of while/for/comprehension/lambda), with voices moved into features/loops/check.av (jump_unlooped, jump_behind_lambda, jump_in_comprehension, jump_unaimed) and 6 cases unpinned (jump_*, builds_jumps_lawful).
  Next: `AVRA_PROGRAM=1 make try`, then `PIN=1 sh tools/witness_program_refusal.sh build/avra-try jump_unlooped jump_top jump_lambda jump_comprehension jump_label builds_jumps_lawful`, then the full gate.
NEXT TO TAKE: flow.unbounded_cleanup (ACCEPTED; compiler/cleanup.av). Misrouted to me by the scoreboard: flow.guard_binder and flow.end_arm (select-lowering).
FINDINGS: none unreported.
DO NOT TOUCH (mine): compiler/item_body_laws.av; tools/witness_program_differential.*; tools/witness-files.

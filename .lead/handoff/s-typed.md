# s-typed handoff (worktree ../avra-hd-saved)
Branch hd-typed-query @ b69d9cdd, pushed. Never built green yet.
Also: hd-onewriter-gate 78475094 (const_json via const_type_ensured, named_refs sorts once, fold_test canonical), merged into hd-typed-query.

## Done on hd-typed-query
- `@query @recursive @scoped_by(body_scope) typed_body(ws, d) -> TypeFacts` (workspace_analysis.av); `typed(d)` calls it. Helpers `typing_of(d)`, `typed_family()`. Removed Family.Typed, DbRow/DbKind.Typed, typed_of, typed_verified, leaves named_typed/typed_digest/typed_says/typed_said_pass. body_scope places the range first (fix for `wants holds [0,0) id 349`).
- `@query @cycled_by(settle_cycle) settled_ask(ws, c: SettleAsk) -> Settlement`; SettleAsk/SettleRoot wear @codec. settled_at asks `settled_ask_held` before asking (held = reused -> Spoken collapse). Removed Family.Settled, grouped/group_at/group_print, hold groups/closure, named_closures, gather_open/close (decls.av), settle_closure_test.
- Merged: hd-families2 e327df1d, hd-codec 726af4ed, hd-marks-cycle, hd-lowq, hd-sibling-gen (merge 2d828c93). body.av = hd-lowq c142b47d whole.
- Test added: compiler/tests/typed_window_test.av.

## In flight
- Lane run 41491360642 (build + typed_window_test, aftercall_test, answers_test). Read: gh run view 41491360642 --log | grep -E "error\[|passed|✗|holds".

## Next step
1. Read that run; fix compile errors (last known: Bypassed.Errors arm gone, fixed; typed_body_key unresolved = sibling-gen bug, bridge merged but ladder may need a compiler that has it: build the bridge's compiler first, see CLAUDE.md "a change the compiler must then read").
2. Run cold then one-literal edit of commands/ir.av: `build packages/cli --time` (the headline warm-edit number; send to lead + s-decl).
3. Full gate: gh workflow run checks.yml --ref hd-typed-query; then rebase onto origin/hd-clean and send shas to s-gate.
4. Census (MAIN_GATE #6): run with full tables to log (earlier run printed deltas only); named_refs fix already in. #7 speed not started.

## Open
- settled_ask: kept_settle.av hand stack and `settle_reads` untouched (s-hold). settle_asks/settle_id stay (ConstTyped keyed by them).
- query.av coded() should be an arm of s-verdict's folds_stably once merged (hd-lowq's coded(f) is what is in the tree now).
- Not verified: typed_digest dropped (placed(d) no longer in digest), pending test results.

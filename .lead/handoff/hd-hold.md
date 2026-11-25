# hd-hold handoff (s-hold, 2026-11-02)
Branch hd-hold = hd-hold-items (worktree ../avra-hd-hold), sha 2f4ed88b. Merged origin/hd-clean 9654c99a (merge, not rebase).
Gate run 41490220769: build GREEN, still running; failed so far: cache-attacks (a), layout-oracle, one suites job (unread); prior 41451684527 failed only in prepare (Family.Failures), fixed in 2f4ed88b.

## Done
- DeclFacts/AnnotationFact/LitArg/NamedLit are @codec; hand facts codec deleted; facts_block = codec bytes in hex.
- DeclFacts has no hand fingerprint: told_of and facts_block_test use DeclFacts.digest_in(indexed_scope(), f).
- items_of_file is durable across processes (proved: std-net cold, then edit -> 10 store hits, 1 compute).
- failures.av: my @query failures_solved form (hd-clean's old key form needs Family.Failures, which is gone).

## Next step (items slice, nothing started in code)
items(f) (workspace.av ~2000) calls items_of_file for every file, mints via decls.mint_lines with the line's own root
(a file's arena is its own: parsed_fresh = new_node_store; ids stable under same text, so no Offset needed).
Move remember_store + range_bodies into store_ensured (workspace.av:1344), no "was parsed" flag.
Held makers = distinct non-empty ItemLine.maker. record_cancel dies (needs hd-writes2's Fixpoint; check hd-clean has it).
Then: externs_of_file / types_of_file as plain fns over items_of_file (extern_notes, implementors_of);
references (needs s-verdict's file_said, hd-owned-wip); body-reach decl_places etc. as @query (overlaps hd-writes2 Fixpoint);
record layer: hold.gathered/reexports/runs/refs_by_target -> @query. Last: delete is_held, Decls.held, hold_only,
read_why, meet_file, Reads, forced. ~107 held mentions in 24 files; s-decl owns lowering-side, s-typed Settled.

## Open bugs
- Side-table trap: `wants holds [81,110) - id 0 is outside it` / `binding_types holds [0,2)`. Repro (one binary, warm cache):
  ./avra-try test packages/std-avrac/src/compiler/tests/aftercall_test.av then .../answers_test.av. Cold cache: passes.
  Typed-facts restore (compiler/facts_codec.av window); s-typed owns.
- cache-attacks (a): 14 failures on 5ffa4626 (sl, rx, st x2, d x2, ur x3, us, ab x2, abx x2). ur/us "a warm check parsed ''"
  after an edit = stale answer served, a SOUNDNESS bug, do not re-baseline. Base comparison run 41420229220
  (branch hd-hold-base @846dce86) unread; goal <=11.
- hold-refused.log "an unread file's items were not kept" makes runner builds cold; fixed by the items slice.
- layout-oracle / `command` word parse failures: base issues (s-gate).

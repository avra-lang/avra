# Handoff — parity-values lane (2026-11-25)

## Goal
The pass ledger, plus cost and warm-speed parity for the program layer: noop and warm runs do only what a
change needs, and every cost is measured and ratcheted (tools/cost.sh, tools/cost_ratchet.py).

## Base and branches
- **Pushed, finished:** `lane/parity-values/noop-vouch-matrix`, tip `d95903f7ad7f44a86c834c274f8d57861650adb9`.
  9 commits on gh/program `e02d71abd`.
- **This handoff:** `handoff/20261125-1144/parity-values`. It is that branch plus this file at
  `docs/handoff/parity-values.md`.
- **Local worktree:** `/work/c9`, branch `warm-matrix`, the same commits. The repo's remote `gh` is
  https://github.com/avra-lang/avra.git; the session needs avra-lang/avra attached with push access.

## Done (on the branch, not yet landed)
1. `cost: a ledger run does its counted twin's work` — `same_work` in cost_ratchet: queries_computed and
   worked must equal the counted twin's.
2. `docs: durability levels, measured and deferred` — docs/2026_11_24_DURABILITY_DEFERRED.md.
3. Noop cuts:
   - `const_gathering` (law_findings.av): one answer per const-declaring file.
   - `strays_in` (item_program.av): one answer per file.
   - A counted `noop-check` warm workload.
4. Vouch by stamp: `verdict_package(at, package) -> bool` (law_findings.av), and a counted `laid-noop`.
5. `toolchain_verdict`: an @input in source_facts.av, so the verdict is read through the door.
6. warm_edit_bench.sh: one check past the stamp window before `counted unchanged`.
7. QueryEngine open stack: `open_depth` plus an `innermost` cell, so a nested open copies no list.
   Copies fall 2.9–11.4%.
8. Cost-accept: queries_computed rows 525524 (cli), 74459 (check-program), 145324 (laid), accepted by
   the Lead.
9. Warm-edit matrix, ticket .105.1:
   - COST_PART=matrix-<check|build>-<laid|bare>, gate slices cost-matrix-*.
   - 10 edit kinds, including fanout and broken.
   - 4,440 matrix-* rows.
   - Walls go in ledger.md, flagged over 300 ms.

Tested on c9780be7 (gen 2 A/B, all cost parts plus the matrix parts locally). On e02d71ab only the rebase,
the ratchet self-test and `sh -n` were run. Its gate run is the first proof there.

## Half-done
Nothing is uncommitted.

## Next (in the Lead's order)
1. Watch the gate on the pushed branch. If e02d71ab moved rows: `COST_PART=<part> make cost` in /work/c9
   (after `make avra` twice from a gen-2 seed), then fix or re-accept.
2. Matrix finding to investigate first, if the Lead agrees: laid is 2–5× SLOWER than bare on warm check
   edits, and a noop build takes 3.5 s laid vs 0.85 s bare. Read the cells' pass rows: matrix-check-laid-*
   against matrix-check-bare-* in the verdict .rows.
3. Items-read column: a key=value pass-row format (asks= per_unit= per_moved= rechecks=
   recheck_per_moved=). Counter names stay unchanged. items_read= and read_per_own= join; a
   `file_of(arguments)` door is generated for file-seated queries. Agreed with wrong-answers.
4. Derived persistence (design note first). Build on defects' derived-field form in saved_derive.av;
   no second skip form.

## Open questions and findings for the Lead
- Keepers on the landed head:
  - read-lists: a REAL regression. law_findings for one tapes.av item (id 760037407) reads 34,438:
    lowered_under 14k, lowered_method_under 7k, impls_with 6.7k. Its shape matches context reads
    (`requireds_unset`); the exact law isn't pinned. collect_members reads 15,419, item_held per item.
    The fix belongs to the laws' owners: per-body reach summaries.
  - cutoff-witness: the same cause.
  - Stale read_lists.ceiling lines to prune: package_gatherings, package_heirs.
- inputs keeper: already red at d7cd (17 new sites), not ours.
- Bug to file, the tapes.av trap. A @query defined in a cli file is only in that file's collect's engine,
  so a check asking it dies with "unwrapped an absent value". It wants a refusal at definition time.
  Avra's tracker wasn't reachable from this session.
- Proposed: the longest read list per family as a ledger row, folding read-lists into the ledger.

## Runs in flight
None.

## Worktrees (/work)
- c9: this branch.
- b910: the plain base used for A/Bs, detached.
- d7, led, ps, hv, ps1, gate146: older and superseded. Safe to drop.

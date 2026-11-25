# HANDOFF — lane parity-types (2026-11-25)

## Goal
- **Parity-types lane:** the replayed type-law commits and the cost fixes that came with them. They are landed on GitHub program as `lane/parity-types`.
- **Side table (avra-8sb5.104.2):** one columnar per-node fact table (`@derive(Facts)`); the arena's per-node columns move onto it one commit at a time, each measured against its parent.

## Tickets
- avra-8sb5.104.2: side table (lead's id; not in the Agent_Tasks tracker reachable here).
- t-qhah (Agent_Tasks): step 2(a), teaching the arena's Copied/Taped derives a `@derive(Facts)` table. Filed as its own ticket at the lead's call.

## Branches and tips (GitHub avra-lang/avra, remote `gh`)
- `lane/parity-types` = **2f03d33b**, pushed. 11 commits on gh/program e02d71ab.
  - Gen-1 0, gen-2 0, `make try` 0 on this exact tip (run t17).
  - The census, witnesses and core tests were run on the same 11 commits over d7cd84d9 (run t16):
    - core tests 382/382; fns tests 136/136;
    - witness 1196/1197 hold, 1 known to differ, 0 failing, 4 untooled.
  - **Not yet rerun on e02d71ab:** core tests (t17 stopped before them), witnesses, census.
- `handoff/20261125-1144/parity-types` = wip-handoff: lane/parity-types + side-table step 1 (51a51f05) + this note.

## Done
- Lane: 11 commits. The cost fix commit (impl bounds ride on ImplDecl as `List<Param>?` seats, `Param.bound` removed, the seat-builder probe, `parameters()` accumulating) removes the fixed +148k empty lists.
- Census vs base d7cd:
  - cold rows fall: check-cli copies −1.0%, boxes −1.06%, string compares −1.15%; list_reads +0.075% (lead accepted);
  - warm rows ≤ 0.05% except string compares: back-* is stamp-order noise (accepted); edit-* +0.19% is the grown impl grammar (asked the lead whether to cut it; no answer yet).
- Side table step 1 (51a51f05):
  - `core/fact_table_derive.av`: `@derive(Facts)` + `@facts_over("StmtId")` make `<T>Table`;
  - `core/marks/marks.av`: `facts_over`;
  - `arena.av`: `IndexTable` and `index_table_of` exported;
  - test `core/tests/fact_table`: eval == native == expected.
- Design note: /work/out/parity-types-side-table-design.md.

## Half-done
Nothing uncommitted. Worktrees: /work/avra (branch lane/parity-types) and /work/st (branch wip-handoff).

## Next
1. Rerun on 2f03d33b: core and fns tests, then the witnesses in batches of 20 (a full run fills the disk). Script: /tmp/claude-0/r/t16.sh, lane half; base it on gh/program.
2. Step 2(a), t-qhah:
   - in `core/copied_derive.av` (and the taped routes), treat an arena field of type `<T>Table` by reading its facts record's fields and marks;
   - `@derive(Facts)` must claim those marks in `marks()`.
   - Test with a small arena.
3. Step 2(b): move SyntaxArena's statement SideColumns into one `StmtFacts`. Census against the parent.

Exact next command: `cd /work/st && git checkout wip-handoff && sh /tmp/claude-0/r/s1.sh` (gen-1 + the fact_table test).

## Open questions
- Does the edit-* string-compare row (+0.19%, impl grammar re-validation) need cutting?
- Snapshot: tools/cost.baseline pins ea25dd42, which no clone here can fetch. Every census used `COST_SNAPSHOT=91ebc6c5` (the same tree), so the gate's final ratchet comparison refuses on the sha.

## Runs in flight
None. t17 (build of 2f03d33b) stopped before its core tests.

## Base
gh/program **e02d71ab**.

## Environment notes
- Builds need `. /etc/profile.d/avra.sh; export AVRA_MEM_POOL_MB=12500`.
- Clear `.avra-cache` between compilers built from different trees (stale-cache trap).
- Builders kept in /work/avra/build: avra.d7cdlane-gen2, avra.d7cd-gen2, avra.d910-gen2, avra.rung-aa43.

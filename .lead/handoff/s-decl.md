# s-decl (lowering / kept units) handoff
Branch hd-lowq, worktree ../avra-hd-decl, sha d1f53a75 (pushed, NOT gated since 0b98fcce).
Last gate: run 41464116971 on 0b98fcce, red. prepare green (needs rungs 8f261131, 68c4e14d, 6462aee6 in history; marked Rung:).
Probe worktree ../avra-hd-decl-r3 (detached at 68c4e14d, build/avra = P3): leave or remove with owner's say-so.

## Done (all on hd-lowq)
- Read door + Decls.covered are ONE hook (door_read via arm_cover).
- Gen-2 prepare trap fixed: door_read covers a Facts read whose arena has no stmt.
- Kept unit carries its CODE: KeptUnit {wants, bodies, statics, hashes} @codec; Body/Ins/Static/Reg/SeatMark/CodeFacts/FactNode wear @codec; Bytes is a stored kind (std-relation). Key carries back_edge_checks.
- kept_want serves only wants asked WHOLE (no sub, no seats): serving instantiations trapped (ticket avra-8sb5.57.307).
- Store: slot table digest-sorted at seal + bisect (body version 9); Writer chunks long runs; dense ids spelled once per record (dictionary); frame+marker one write.
- Merged hd-codec 61a8922e.

## Measurements (cold build packages/cli --time, same tree/gen1)
kept off: lower 25.9s. kept on: lower 42-43s (+17.5s). Stub split: encode ~1.8s, Wanted key digest ~3s,
leaf-list write ~7.6s (6.4M leaves, 1.2us each, 65k persisted queries, 14.7k unit_kept, all leaf sets distinct), rest ~9s per-put fixed.
Target <+10% (<=28.5s) NOT met. Warm one-literal-edit number: NONE (trap below).

## Next step
1. Option chosen by lead: cheaper per-leaf encode (write_leaf/read_leaf in std-relation/src/db.av: one string per leaf, reader matches). Re-measure with the stub-split method (tools: variants in scratchpad were uk.base/variants.py; recreate: stub unkept()/empty KeptUnit/skip keep()).
2. Re-gate hd-lowq after s-typed merges it (or merge hd-typed-query yourself: 7 conflicts: codecs.av derive.av facts_scope.av unit_rows.av(deleted here) workspace.av workspace_analysis.av std-relation/query.av).
3. file_lowering / stands_in deletion / Sig @query NOT started (design: demand-driven per decl, no file grain; see lead messages).

## Open bugs / repros
- Warm trap: build packages/cli cold, edit one literal in packages/cli/src/commands/ir.av, rebuild -> "side table `wants` holds [0, 0) — id 349". Frame: type_decl<-default_body<-plant_want<-TypeFacts.set_want<-typed<-cancel_survey. s-typed's body_scope fix (hd-typed-query 7a94cfc3+) is the candidate. Pre-door binary survives this edit.
- Same family: std-relation suite "index 0 out of bounds", std-time "307/306", negative_arg "2365/2358" in avra test eval leg (gen2 only, warm cache from test); cold passes.
- hold refusal: `cli is an enum, not a record` main.av:42 (cache poisoning, s-families).
- ticket avra-8sb5.57.307 serve kept instantiations; avra-8sb5.57.308 store rows carry Bytes (delete hex(record)).
- Local disk is ~99%: delete avra-hd-decl-cache-* asides (mine) when they appear.

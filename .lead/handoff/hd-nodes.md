# hd-nodes (lead-written; lane force-stopped)
- Branch hd-nodes: 69dc7ba6 (form_wire -> @codec; superseded by hd-hold's broader DeclFacts @codec, so drop that part on merge) + Table meant_type/meant_reg (keep). 8cb0a51e (11.384 by TEXT SCAN) must be REVERTED, never merged.
- 11.384 redo (decl-based: collect_word in the Decl relation, gathered_into) is uncommitted in the lane's scratchpad. Rulings: closure_far fixture gets its own package's collect that reads @seat (no exception); its marks_of trap is fixed by @cycled_by (hd-marks-cycle).
- TOP open item: MAIN_GATE #1, the cli suites fail at packages/cli/src/main.av:42 `cli avra {` "expected BREAK" (the component instance doesn't parse in the suite's build). Then the 69 idiom sites, then 89.6.

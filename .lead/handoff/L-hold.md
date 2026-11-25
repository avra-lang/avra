# L-hold handoff (2026-11-03)

## Landed on hd-clean via s-gate
- c1 6136f307: dead DbRow.Namespace + five uncalled fns (eager minting dropped: 2.5x cold).
- L-hold-small fc01e7e6: idioms in build/interface/decl_rows.
- L-hold-defects b5ec698f: asked_print skips remembered homes the program never admitted (make defects 6 -> 0).

## Sent, not yet landed
- L-hold-readfound 934a9050: Decls.read_found answers the read_found query's value (no whole refs_index read).
  On the stack it cut failing restores 29,553 -> 3,830; on hd-clean alone no measurable effect (warm 2nd program traps first).

## The stack (worktree ../avra-L-hold, branch L-hold-a, last pushed origin/L-hold-a-wip)
eng-doors (L-engine2) + (a) lowq std-avrac half + (a2) hold-items + fixes:
plain_made/method_clashes answer their rows; ModuleId in-process; parse places ranges (remember_store);
admitted deleted (admission mints unheard); placement_of reads the parse; module states marked in parse_program;
Decls.store(d) reads d's syntax; range_bodies owners only where the stmt stands; facts_of reads the row;
declared_unit roots only value-holding kinds; items_of_file reads source_of; Methods reads block files' expansions
and settles on durable member names; read_found (above).
Status: decl_grain 14/14, facts_block/aftercall/answers/workspace/lower/cancel_reach green EXCEPT the warm
second program (facts_block then aftercall) traps "declaration N read after its file was admitted again".

## The open defect (same chain everywhere: store.av, ui-board 1570, stack warm trap)
scc_walk -> cancel_callees -> cancel_evidence (saved; restore fails) -> made_lasting -> cancel_summary ->
cancel_survey -> names_of -> resolved(file) -> expanded -> materialized -> generation_kept sweeps rows
(derive(Words)/derive(Facets) in std-ui tree/node.av, style/style.av for ui-board) that other answers hold.
Repro (tip compiler b5ec698f, default machine store, s-gate's): copy tools/ui-board, build --target wasm
--wasm_reactor, edit title "Tasks"->"Chores", build -> trap 1570. My product can't reproduce (store history).
Next: find why the late derive run makes fewer rows than the analysis-time run; a run that could not run must
not sweep. Law (A) with L-engine2: decoding a restored DeclId records a read of its row.

## Engine items handed to L-engine2
Saved-answer validation failures (leafbad probe in Db.ran_lasting): refs_to->refs_index, text_scan_of digest 0,
Named row-hash leaves (Decl rows hash process facts), Items leaves by absolute path; absent/truncated rows.
Machine store keys are tree-relative: rows collide across trees with one package name (explain moved:[],
defects scratch packages, a tree's own store poisoned by a defects run).

## Queue after 1570
cache-attacks b2 "the enum's file edited, its members' held: status 2"; Syntax readers (kept_settle outline ->
per-file @query value_outline/whole_outline, edit lost — redo); hold slices; 3 defects stalls >10s.

## Update (2026-11-03 evening)
- Sent: L-hold-callees fb3dc755 (cancel walk follows only this compile's members: fixes ui-board 1570,
  cache-attacks b2, the stack's warm trap). L-hold-readfound 934a9050. readfound-attack red is on the tip
  ("Analysis moved" vs "Parsed moved"), not read_found.
- unit_kept piece re-cut on hd-clean: origin/L-hold-unitkept 6be8cd10 (+decl-grain doors). Green: two gens,
  compiler tests, features-a 3555/3555, defects 0. HELD BACK: features-a peak 7146 MB vs tip 4839 MB —
  AVRA_MEM_STATS: engine leaf lists (Db.spelled_leaves 637 MB, leaves_of 463 MB, Kernel.begin 307 MB),
  handed to L-engine2. Cold cli build is lower with the piece (2.36 vs 2.78 GB).
- Stack (../avra-L-hold L-hold-a, origin/L-hold-a-wip c63b2e86) is superseded by small pieces.

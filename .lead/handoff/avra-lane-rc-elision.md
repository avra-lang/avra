# avra-lane-rc-elision — hand-over
Branch avra-lane-laws-cost, head = this commit; base next-base cd4738e6 (merge d52c13a5 on top of 933ce4bb work).
DONE and handed back:
- R2a (memory.av handed_yields/arm_handed + nested-retain fix, handed_counted): landed via avra-lane-rc-elision-r2a.bundle.
- Notes (retain census by reason, B/T/keep-move dropped, accessor-inline design): avra-lane-rc-elision-notes.bundle (merged).
- Laws cost: 4b738e33 (entry_nodes skips declarations; item_methods_taken reads one item's about via
  item_written_impls), ceaecb73 (TypedBody doc), c8e2427d (witness `lawed` case). Bundle avra-lane-laws-cost.bundle
  was on 933ce4bb; this branch re-merges cd4738e6 (witness conflict resolved: lawed's made() passes "" to unsigned_at).
  Receipts on 933ce4bb: cold wall 107.7->91.7 s, user 255.5->205.4 s; item_misses self 30.0->7.1, methods_taken
  10.4->0.0, law_findings incl 76.9->42.8; findings byte-identical (cli, std-avrac); refusal suite = trunk; witness green.
FINISHED after the stop order (the one item in flight): on the cd4738e6 merge, `AVRA_PROGRAM=1 make try` exit 0;
  `sh tools/witness_program_edit.sh build/avra-try` exit 0, every case green incl. lawed, embed, infer, composed, rename.
  Not re-run on this merge: the refusal suite (on 933ce4bb it matched trunk; needs build/sqlite3.o) and the CPU/findings receipts.
  To resume: nothing left for laws-cost; land avra-lane-laws-cost as is.
NOT STARTED: main-process peak memory (branch avra-lane-main-memory = next-base, no commits).
HELD branches (not for landing): avra-lane-rc-elision-a (shape A; needs a checker that models avra_cell_forget),
  avra-lane-rc-elision-r1b (R1b′; returns when captured mut locals can qualify). Probe branches btally/btally2/rtally/laws-dbg: measurement only.
Findings not yet reported: none beyond the posts (typed_fn vs store = (A), benign; written as the TypedBody comment).
Files others must not touch: none held now.

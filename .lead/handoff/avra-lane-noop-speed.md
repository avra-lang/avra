# avra-lane-noop-speed — hand-over
Branch avra-lane-noop-speed-6, head = the commit adding this file. Base: next-base cd4738e6.
On the branch: 44454b24 `program_row_names` reads the shape's externs in place via
`program_code_shape_saved` (0.2 s off an edit that moves the shape).
FINISHED after the stop order, receipts run (on next-base cd4738e6):
- AVRA_PROGRAM=1 make try: 0.
- cold `AVRA_PROGRAM=1 build/avra-try build packages/cli`: rc 0.
- a literal edit in cli/commands/cache.av: rc 0 (4205 ms). Taking it back: rc 0.
- the product after edit + take-back == the cold product (cmp).
NOT run for 44454b24: the full edit witness, idioms, refusal suite, three-edit ms table.
To resume: `sh tools/witness_program_edit.sh` and the idiom gate, then land it.

DONE and handed back:
- noop-speed (program_refused query)
- -2 (input stamps, placement (b), standing_inputs)
- -3 (ShapeAt + shape columns)
- -4 (reverse-edge columns, avrafront3)
- -5 (names_own cut 33c29617; reads_among b2d0956e)
Sent to saved-answers: repro-two-builders/.

IN PROGRESS: none. Next, NOT started: map the nodes.av one-field edit (~39 s warm on cli).
Plan: three edits (OrderKey field; new Expr variant; a body edit in core/store.av), each
cold → edit → warm → take back, with AVRA_QUERY_TIMES. Add a temporary uncommitted counter
in QueryEngine.reads_hold that tallies (query worked out again <- query whose read moved),
to get the fan-out by cause.

Findings not yet reported: none beyond my last posts.
Others must not change the base column format in std-program/src/frontier.av
(reader_starts/readers, avrafront3) without telling the lead.

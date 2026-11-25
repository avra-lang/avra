# avra-lane-ui-build: hand-over
Branch `avra-lane-ui-build`, sitting on next-base cd4738e6 (merged as 69fcd8b1); head is the commit adding this file.
DONE and handed back: ui-build 1-5, stateseat (`avra-lane-ui-build-stateseat.bundle`), and dynrecv
(`avra-lane-ui-build-dynrecv.bundle`, c5809017 on cf1b3e2c: a dyn/bounded receiver writes as the trait marks it).
ON THIS BRANCH, NOT YET HANDED BACK (in the final bundle):
- 825126c1 + a73b641e: `generated_expanded` (@query, item_expansions.av), which expands a generated item's instances at the template's home.
- dab74e72: `Checking.kept_checked`. A list a `collect` keeps is seated as itself and spread. Suite case builds_collect_spread.
  This took std-ui_gallery `--lowered` to 28/28.
- 5ce7c202: `StatePlace.Stated(stmt)`. A fn-local `state` read by a text/frame gives the body's Cell (core/frame_reads.av, item_places.av).
  This fixes std-ui sited_text.
STATE on 5ce7c202, from the partial gate9:
- make try 0; `AVRA_PROGRAM=1 build packages/cli` exit 0; `--built` 48963/48963.
- std-ui `--ran`: 73 made, 72 pass; only web/tests/mount fails (see findings).
- Earlier, on 990e41f8: refusals had only seat_u1 failing; idioms 0 NEW after a73b641e.
- `site`: 5 pages byte-identical old vs program layer. ui-board/term: byte-identical.
NOT YET RUN on 5ce7c202: idioms (cli/std-avrac/std-ui), program-layer idioms, cold program sound, refusal suite, edit witness.
Next command: `sh /tmp/claude-0/gate9.sh` (or the same receipts by hand), then bundle `program..avra-lane-ui-build` as ui-build 6.
FINDINGS NOT YET REPORTED:
- std-ui web/tests/mount fails on the program layer (eval: "`avra_ui_stood` is extern and this image does not carry it"; native link: undefined avra_ui_stood/avra_dom_frame).
  The test answers the externs with `extern fn … { body }`. Hosting that body is extern-seats' 04bb73ba/eda176e0, which left with the withdrawn 2687f71a and is not in cd4738e6. Owner: avra-lane-extern-seats.
- Still not made in std-ui: `fields` of an untyped subject 1, a write to a `let` 1, generic `read_all` 1.
NEXT for the lane: std-ui Component rows, then (4) the wasm page once W2 lands (host-fn list already posted).
DO NOT TOUCH (mine): core/frame_reads.av, compiler/item_places.av, features/read_set.av, compiler/item_expansions.av (generated_expanded),
features/lists/checks.av Collect + Checking.kept_checked, the name table (core/names_read.av, written_reads/written_root).

# layer-commands: the 4 parity laws on 2e4f514e, gated, with the cost line

## In `avra-lane-replay-layer-commands.bundle` (prerequisites: 2e4f514e and 451aaeb2)
- `avra-lane-replay-layer-commands` = 4f203ad0: 5 commits on the landed head 2e4f514e (batch 58 + store-p0).
- `avra-lane-replay-layer-commands-on451` = 36fefb13: the previous delivery on 451aaeb2, kept for reference.

| law (what it refuses) | on 2e4f514e | on 451aaeb2 |
|---|---|---|
| enabler: a compile-time run on the old path spends its declaring package's `[lifted]` rows (refuses nothing) | 9e8a31b4 | 2f0bedea |
| type.within: a `within` whose block answers nothing | ab36e601 | 0381c76e |
| collect_enum.trait: a trait word naming no trait; a member without its impl | b29e997e | b07219f1 |
| annotation.meta: a loaded `@std/meta` whose shapes moved | b2032851 | 0f57b0c7 |
| resolve.reexport_cycle: a re-export that would close a package cycle | 4f203ad0 | 36fefb13 |

## Cost line: 4f203ad0 against 2e4f514e (snapshot a6d0d0a0 = snap57)
- Against tools/cost.baseline, both pass: `GATE cost 4f203ad0 PASS rows=1 failed=0 3040s`
  and `GATE cost 2e4f514e PASS rows=3 failed=0 2899s`.
- Tip against head, row by row at the gate's 0.05% tolerance: **3 rows over of 53, all list_reads.**
  - check-program list_reads +0.064%
  - check-cli list_reads +0.062%
  - cold-with-store-fill list_reads +0.082%
- All retains and releases rows are now under. Boxes, reclaims and string_compares fall in every
  cli row: boxes −0.04 to −0.06%, string_compares −0.08 to −0.10%.

The trend: 35 rows were over on the lane's f71bd2c6. After the fold, 4 were over against 451aaeb2.
After the rebase, 7 were over against 2e4f514e. These two cuts bring it to 3.

### The rows still over, by law (list_reads, % of 2e4f514e's row)
Each commit was measured on its own: census compiler, then the workload over the snapshot. The steps
add up to the gate's totals. A 2e4f514e control and a tip control each matched their gate row within 0.001%.

| law | check-program | check-cli | cold-with-store-fill |
|---|---|---|---|
| enabler | +0.003% | +0.002% | +0.003% |
| type.within | +0.012% | +0.018% | +0.019% |
| collect_enum.trait | +0.035% | +0.018% | +0.020% |
| annotation.meta | 0.000% | +0.005% | +0.004% |
| resolve.reexport_cycle | +0.015% | +0.018% | +0.036% |
| total (= gate row) | +0.064% | +0.062% | +0.082% |

No law alone takes any row over. The over rows are the sum of the five commits. The largest single
shares are resolve.reexport_cycle on cold-with-store-fill (+0.036%) and collect_enum.trait on
check-program (+0.035%).

The check-cli split for collect_enum.trait, annotation.meta and resolve.reexport_cycle comes from the
series of the previous gate design plus a measured run of the tip with this design. The parts add up to
the gate row exactly. Retains split check-program: collect_enum.trait +0.018%, type.within +0.016%,
reexport about +0.014%, total +0.047%.

## The two cuts asked for
1. **annotation.meta reads nothing when the loaded `@std/meta` is the toolchain's.**
   - The cli's door (`manifests_door` in cli/src/commands/tapes.av) compares one word before `meta_door`
     lays any shape: where `@std/meta` stands (`Disk.meta_is_toolchains`, `package_root(META)` against
     `<std root>/std-meta`).
   - A pinned or vendored `@std/meta` still gets the full check. The witness annotation_meta_moved
     vendors one and still holds.
   - Its store-fill list_reads went from +0.174% to +0.004%.
   - I did not compare by content: the census checks snap57, whose meta.av differs from the
     compiler's own, so a text or hash identity would never pass the gate in the very workload that is over.
2. **collect_enum.trait reads nothing for an item or package with nothing to read.**
   - The trait law reads only the statements of the item already in hand (`ItemView.item` is read
     before any law runs). Its old `item_declares` gate, which decoded every item's summary, is gone.
   - The member law asks its package one word first: `owes_impls`, a `@cut_query -> bool` read once a
     package. A package owing nothing reads no gathering.
   - A package-level "declares no `collect enum`" gate would not help check-program: std-program
     declares one in a test support file (tiny_tree.av).
   - On check-program, retains fell from +0.058% to +0.018%.
   - I tried per-file gate queries (`collects_enum`, `file_owed`) first. Measured, they cost more
     list_reads than they saved: +235 and +1725 queries, two per file, net +0.017% and +0.031% list_reads.
     So I dropped them.

## The rebase onto 2e4f514e
- One conflict: item_reexports.av, where upstream moved item ids from `int` to `ItemId`. I resolved it
  to the WIP's file-words gate typed `ItemId`. The lane's other `at: int`s became `ItemId` too
  (`withins_refused`, `cycles_closed`, `OwedImpl.item`), each folded into its law.
- The compiler for 2e4f514e is built by **b57**, as b2e0a5c8's message says: "main's (57) compiler,
  which the gate's gen-1 is". land58's gen-3 refuses item_generators.av:658 (a type.lambda false
  refusal), on dc78a97a, 5c72cf5f and b2e0a5c8 alike.
  b57 → 2e4f514e gen-1, gen-2, gen-3: gen-2 == gen-3. The binaries are in
  /work/avra-chain/build/avra.h59-g{1,2,3}.
- 2e4f514e's compiler can't build the lane's tree. `@derive(Saved)` on `Seating` goes over the 5 MiB
  derive cap, which is the enabler's subject. So the enabler commit 9e8a31b4 is built first
  (avra.en59), and it builds the tip.

## Receipts on 4f203ad0
- `make avra` twice from the enabler compiler: gen-2 == gen-1, both real rebuilds (about 4 minutes each).
- `tools/fmt_changed.sh 2e4f514e HEAD`: 29 examined, 0 differing.
- `tools/witness_program_refusal.sh build/avra` within_answers_nothing collect_enum_names_no_trait
  collect_enum_member_unimplemented annotation_meta_moved lifted_rows_of_the_declaring_package:
  5 of 5 hold.
- Commit messages for collect_enum.trait and annotation.meta now describe the gates.
- Not run on 2e4f514e: workspace_test, witnesses_test and features/collects. They passed on 451aaeb2
  (below); only the cost slice and the checks above were re-run here.

## History: the replay and the fold on 451aaeb2 (previous deliveries)
- The fold of the WIP: re-exports read from a file's words, folded into resolve.reexport_cycle; the
  within law's reader, folded into type.within.
- On 451aaeb2: fixed point, fmt 0/29, witnesses 5/5. The cost against 451aaeb2 was 4 rows over: check-program
  list_reads, retains and releases, and cold-with-store-fill list_reads +0.229% (annotation.meta +0.174%).
- Receipts on the pre-fold tip c312891d: workspace_test 75/78 (the same 3 fail on land58),
  witnesses_test 13/13, features/collects 99/105.

## Commits (the lane's final shas, after its last autosquash at 03:37:23)
| original | rebuilt | subject | verified against |
|---|---|---|---|
| 8a55b6fa | 2f0bedea | A compile-time run on the old path spends what its declaration's package lifts | python asserts, fmt counts (9 examined/2 written), witness case content vs printed probe outputs |
| dc7029c2 | 509ea8dc | type.within on the program layer: a `within` whose block answers nothing, said at the block | edit outputs matched byte for byte (025, 026); refuses.expected matches the printed head; later fixup at 274 |
| 508b8ae7 | 9e55a9c7 | collect_enum.trait on the program layer: a trait word naming no trait, a member without its impl | asserts; both refuses.expected equal the lane's printed old-path probe output (063); 3 fixups |
| 67fe25d2 | c02e8e6c | annotation.meta on the program layer: a loaded `@std/meta` whose shapes moved is the program's one refusal | the dumped witness gave the same 8 files in the same order (095); refuses.expected = the printed 3 lines (124) |
| f71bd2c6 | c312891d | resolve.reexport_cycle on the program layer: a re-export never closes a package cycle | the `git diff --stat` printed at 165 is reproduced exactly (4 files, +19 −23); amended message (168) via the lane's own sed |
| (uncommitted) | folded into 0381c76e, 36fefb13 | the WIP: re-exports read from a file's words, the within law's reader reshaped | `git status` at 274 (item_reexports.av, item_refused.av); 278's fmt count (2 examined/1 written) |

Every intermediate sha the lane printed and later named in `--fixup=` was mapped to its rebuilt
counterpart: 015edee6, 058cdf8d, a26eef8a, 1b26dad5, 403f8527, 3e78ca66, 358d99d1, bcef9804,
87687aa1, 79dcbbdd, 0941b2b4, 2514d44c, ddb3032e, 88634990, ac87a2d3, 9cb4dfe5, 3666e9f0, ff0b3004.
Every fixup and autosquash rebase was replayed as the lane ran it. Every git log the replay printed
matched the lane's subjects and order.

Rebuilt shas differ from the originals for a mechanical reason only: the lane's commits carry SSH
signatures (`gpgsig`) from its own environment, and the commit dates differ. Searching commit
dates is therefore pointless.

## How it was replayed
I extracted all 278 tool calls after the start point and replayed every one that changes source,
in order (68 of them): python/sed edits, witness directories, `fmt --write`, `PIN=1` witness pins,
commits, `--fixup`s, autosquash rebases and the amend. Every python edit's `assert count==1`
held, and all edit outputs that print file text matched the transcript.

Skipped as measurement-only: probes' compiler runs (stubbed; only their source files were kept),
gates, cost runs, test runs, and 082/154 (the lane's measurement worktree). 075 was denied in the
lane, so it was not replayed. `make try` inside replayed blocks was stubbed; real builds were run
separately.

## UNCERTAIN / notes
- Witness pins (`refuses.expected`, 4 cases) and fmt were produced by my compilers, not the
  lane's. Where the transcript printed a pin, mine matches it. The collect_enum pins match the
  lane's printed old-path probe output.
- The annotation.meta witness is dumped from compiler/dev/witnesses.av by running a program over
  @std/avrac, and that needs commit 1's old-path budget fix. A first try with the land58 compiler
  failed, so I reset that commit, built `make try` from the tree as the lane had it, and redid
  095/124/125. The file list matches.
- The fold is my doing on the Lead's word; the lane never reached it. The per-law split of the cost is
  measured with one builder (the tip's), as noted above.


# avra-lane-hot-writes — hand-over
Branch avra-lane-hot-writes-cell (worktree /work/cellrow), on next-base cd4738e6. Commits:
9e510108 census: empty lists made/first grown, by site (census-only) · d1f9030a lowering: `[]` is static data
(features/lists/lowers.av, one line) · d3691424 Cell.new leaves an immortal seed unopened (new row
avra_owned_slot_unshared: runtime/avra_runtime.c, core/runtime_api.av, core/own_verbs.av celled(), avra_rt.h, soundness.av writes_in_place).
DONE + handed back earlier: avra-lane-hot-writes.bundle (frameless write rows; landed in a683ac99).
THIS BUNDLE: /work/avra-lane-hot-writes-final.bundle (cd4738e6..avra-lane-hot-writes-cell).
Receipts on cd4738e6: libs/try 0; rt header unchanged; cells witness under RC_GUARD (/work/micro/cellw, eval==native, 0 failing);
PROGRAM-LAYER sound build (AVRA_SOUND_CHECK=1 AVRA_PROGRAM=1 build packages/cli, cold): 0 defects; --built 52592/52592;
old-path sound + idioms cli 0 / 0 NEW; program_runs holds; refusal 285/295 hold, 10 known, 0 failing.
On 15c4576b: std-avrac --ran 643/631, only wrap_method; edit witness green. Not run on cd4738e6: --ran, edit witness.
Measured: cold cli census, cut (a) alone: boxes 459.4 M -> 401.5 M (-12.6 %), never-written empties 79.4 M -> 43.8 M.
Callgrind (e2bce925, cold builds_generic_refs, -O0): 29.45 G -> 29.15 G Ir (-1.0 %). Arena probe PROBE_STORES=20000:
peak 168 -> 114 MB (8.4 -> 5.7 KB per empty SyntaxArena). `[]` sites add ~3.5 k static bodies (statics count).
IN PROGRESS (killed): same-tree census before/after on cd4738e6 (rerun /work/micro/gates7.sh from the census lines).
NEXT: (iii) statics named by content (count distinct (print, type) in literal_symbol); true cut (b) = the ~63 Cell boxes
per arena made only at first write; remaining unwritten empties come from comprehensions over nothing (SignedType.spelled
`["?" for _i in 0..n]`), untape tables, TapeWriter.flags.
Don't touch: the new row's law comment (runtime/avra_runtime.c avra_owned_slot_unshared).
STATUS 2026-11-16: the item is FINISHED (builds; its receipts above all green on cd4738e6). Nothing in flight.
Only the same-tree census before/after was not rerun (a measurement, not code). Bundle: /work/avra-lane-hot-writes-final.bundle = cf1b3e2c..avra-lane-hot-writes-cell (carries the cd4738e6 lanes below my 3 commits).

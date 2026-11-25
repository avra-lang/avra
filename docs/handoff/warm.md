# Handoff — lane `warm` (2026-11-25 11:47 UTC)

## 1. Read sets (P1, avra-8sb5.109.16) — IN PROGRESS, never compiled
**Goal:** build step 1 of the UI lead's ruling (`/work/in/READ_SETS_RULING.md`): rules 1–8, with the
verb facts as registry DATA, `Through(param)` marked (never `[]`), `avra explain` showing a set and the
chain to its first `?`, and both queries as `@cut_query` with their own ledger pass. Then (2) a second
proposal section on (a)–(e); then (3) the kept instance.

**Branch:** `handoff/20261125-1144/warm` = the `wip-handoff` commit, rebased on gh/program e02d71ab.
It holds the proposal page `docs/2026_11_25_READ_SETS.md` (de1de1cf) and the WIP.

**Done in the WIP (written, NOT yet built or tested):**
- `core/ir.av`: `enum RowReads { Nothing, Handed, Applies, Unknown }`, and `RtSig.reads`, which
  defaults to `Unknown`, so a row with no fact answers `?`.
- `core/runtime_api.av`: `reads: RowReads.Handed` on the 37 rows `own_rows` uses. The import is added.
- `core/own_verbs.av`: a `reads` column on `own_shapes`, and `own_shape_reads(ty, verb)`.
- `features/lists/walk_lowers.av`: a `reads` column on `walk_rows` (Applies for lambda walks), and
  `export fn walk_reads(verb)`.
- `features/read_set.av`:
  - a `StatePlace.Through(name)` variant;
  - the `ReadFacts` questions `method_places(call)` and `applied_bodies(call)`;
  - `calls_of` and `structural_calls` use them;
  - the old path (`NamedReads`) answers `Unknown` and `[]`, as before.
- `features/structs/lower.av`, `compiler/item_places.av`: `.Through(_)` added to the exhaustive
  matches.
- `compiler/item_places.av`:
  - `ProgramReads` gains `typed`, `types`, `methods`, `fields` and `seats`;
  - `seat_through`, `field_through` and `root_through`;
  - `fn_reads` is refactored onto `body_reads`;
  - a new `method_reads` query, the method key `@home\ttype\tname\tstatic|method\treader`, and its
    `method_keyed` dispatch in `keyed_places`;
  - `method_reached` (prelude verb body → fn key, else the row/shape/walk fact), `verb_reads`,
    `fact_reached`, `applies`, `holds_state`;
  - `Through` keys are `~<here>\t<name>`.
- `features/tests/read_set_test.av`: a second spec with the new cases (methods, statics, verbs,
  applied lambdas, a fn value, `Through` for a state seat, a state field, a cell in a param, and the
  receiver).

**Next (exact):**
1. `cd <tree> && make avra`. Expect compile errors to fix. It uses `signed_method`, `elaborated`,
   `verb_callee`, `declared_at`, `impls_given` and `record_signature` from other compiler files (module
   private, visible unless a name clashes). `BindSite.Seat(j)` is assumed to index the signature's
   params.
2. `make avra` again, then `AVRA_PROGRAM=0 build/avra test packages/std-avrac/src/features/tests/read_set_test.av`.
3. Rule 8 (`dyn` = the union over the program's impls) is NOT written. It needs a per-package query from
   a trait to its implementors: `package_impls` is parted by target type, and each `FiledImpl`'s trait
   comes from `impl_given`.
4. Move `fn_reads`, `method_reads` and `fn_reaches` to `@cut_query`, in their own pass: add a variant to
   `std-program/src/pass.av` (`Pass`, `pass_index`, `pass_unit`, `pass_word`, `every_pass`).
5. `avra explain`: a component's set, and the chain to its first `?`.
6. Measure the warning's true-positive rate over std-ui and the board before adding the warning.

**Probe data and the page:** `/work/meas/readsets/` (probes1.txt, probes2.txt, board.txt,
`zz_readset_probe_test.av`); `/work/out/2026_11_25_READ_SETS.md`.

## 2. Tape pass (avra-8sb5.114.1) — WIP, measured, not bundled
**Branch:** `tape-ask` (a3eceb16) in `/work/wt-tape`, on f9ccac32 (d7cd84d9's tree over dad28699).
Not pushed. It's in the bundle `--all`. The lead asked for it to be bundled on c9780be7 (which is in
gh/program).

**Done:**
- a per-file name index `names_written` (a cut parted query in the tape pass, one part per word:
  `k:`, `u:`, `e:`);
- `declarations_of`, `surfaced`, `imports_name` and `reexports_name` ask only candidate files;
- `module_declares` removed (also from item_ahead's GATHERED list);
- `item_names_test` 6/6.

**Measured against the parent (cli cold):** tape asks 36,674 → 14,629. Census on std-json:
- warm: every row falls (31–75%);
- cold: every row fell but `copies` +0.44%, from more questions. The per-name query was then taken
  out (the commit holds that version).

**The census re-run of that version just finished:**
`/work/meas/census-tape-{cold,warm}.txt` against `/work/meas/census-parent-{cold,warm}.txt`. NOT YET
COMPARED. Next: compare every row (+0.05% bar); run the wider tests; rebase onto c9780be7; bundle;
report.

**Open:** what remains between 7.85 asks per moved item and 1 is per-item tape questions
(`item_parts` tapes every item with no context; `item_under` tapes again). The lead hasn't said
whether that's in 114.1.

## 3. D2 (avra-8sb5.109.15, P2) — not started
The repro is in `/work/in/d2/`. Couldn't reproduce with six shapes on four compilers. The lead's
finding: `owned_app<V>` instantiated at the entry file's top level over a component that file declares
is refused. Next: check native first, then fix so both shapes build or the refusal says what to do.

## Runs in flight
None. The census finished at 11:46.

## Bases
- read-sets: gh/program e02d71ab.
- tape-ask: f9ccac32.
- Sent earlier and landed or pushed: board train 9338a132, lazy seeding 3dab4a0b, proposal/read-sets
  de1de1cf.

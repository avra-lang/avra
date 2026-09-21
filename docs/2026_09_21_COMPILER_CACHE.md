# The compiler cache — state, laws, direction

**The one cache doc.** It replaces eight handoffs, audits and designs: four
are deleted, four are one-line stubs so older citations resolve (git has the text).
Two companions stay: `2026_09_19_UNIFIED_PIPELINE.md` (the architecture
target) and `2026_09_16_BUILD_CACHE.md` (the history).

Worktree `avra-cache-cas`, branch `cache/cas`.

## 0. THE PLAN — the campaign to its end (owner's bar, 2026-09-21)

Warm `build` < 500 ms · `test` on the cache · `check` near instant · every
command ONE derivation · `compiler/` organised · code clean, derived, sugared.
One slice = red-team + review round + ONE gate + commit + seed.

- [x] S1 a file's object is the FILE's; the hold is sound
- [x] S2 fail-safe; the sweep
- [x] S3 the sweep to 3
- [x] **S4 the sweep to 0** (`63cc6a6`) — one flat law (`Decls.declare`), a nested decl is no
      symbol, a program that boxes a flat record builds whole
- [ ] **S5 THE HELD DERIVATION** — `build_program_attempt`'s first half as one verb
      every command asks; per-file diagnostics persist; `check` holds
- [ ] S6 `test` on the derivation: case symbols content-stable, cases ride the
      record, the suite's binary is cached
- [ ] S7 the warm edit to < 500 ms: shard the entry module, prelink held
      packages, one input digest pass, record load/fill
- [ ] S8 `parsed(file)` persists (`avra_snapshot`, two landings); parser fast path
- [ ] S9 `World`/`Compiled`/`Projection`; cli one line per command; folders
- [ ] S10 docs: this file is the law; the pipeline doc becomes history

## 1. Numbers — the non-regression gates

`./avra build packages/cli --time`, under the machine lock.

| | 09-19 | 09-20 (regressed) | now | gate |
|---|---|---|---|---|
| `build cli` cold | 22.7 s | 24.0 s | **16–18 s** | 23 s |
| `build cli` no-op | 0.4 s | 0.4 s | **0.4 s** | 0.8 s |
| `build cli`, one-file edit | 1.2 s | 26.1 s | **1.3–1.6 s** | 2 s |
| `check cli` | 9.7 s | — | cold 9.2 s · warm **1.0 s** · one edit **1.0 s** | 2 s |
| `check std-avrac` | 11.6 s, RED | — | cold 13 s · warm **~1.5 s**, clean | 2 s |

Where a warm edit goes today (ms), held 274/291: admit 165–190 (the 17 files
that parse) · load 140 · link 105–125 · analyze 90–110 · fill 95 · lower 50 ·
emit 30 · clang 30–420 (the entry module, when its instantiations move).
**Target: 200–500 ms.**

## 2. The model

ONE DERIVATION (`compiler/derive.av`, `Workspace.derived(entry, want)`): hold,
load, admit, analyse, restart, lower every parsed body, write the records.
`build` links it (`build_cache.av`), `check` prints it. What a command WANTS
decides what may stand in for a file: its warnings always (`Stored.Warn` under
the file's key), its object and asks too when the want links.

A held file is skipped entirely: no parse, no typing, no lowering, no clang.
That is where the edit loop lives — an edit's cost is ANALYSIS, and only a hold
skips it.

1. **A file's object is the FILE's.** It holds every plain body the file
   declares (`every_body_checked`), so no program's reach shapes it. Key:
   file text + its imports' interface digests. Two programs sharing a store
   share the object; a build and a suite want the same one.
2. **An instantiation is the PROGRAM's.** A generic at its type arguments, a
   fn at its settled seats, a root (`instantiated(w)`). Owned by no file
   (`Body.file = null`), weak, it rides the ENTRY's module — which is keyed by
   its own bitcode bytes (`entry_key`).
3. **What stands in for a held file is ONE content key's worth:** its object,
   its asks (the instantiations its bodies demand), and record lines that
   say what text they were read from (`written_from`). All three, or it parses.
4. **A generic's home is never held.** An instantiation lowers from its
   generic's body. A program's homes are remembered by its entry; a new one
   found under a hold restarts the attempt.
5. **A restart is a NEW workspace** (`anew`). A copy of a workspace shares its
   tables — probed, both engines — so a restart from a copy keeps every hold.

6. **The sources are the hold's oracle.** A build that fails under a hold is
   answered again from the sources alone. A refusal that survives is the
   program's; one that does not prints "the hold was refused". A hold bug costs
   time, never a wrong answer. A trap still escapes it.

7. **A layout is ONE law's answer, and it is in the interface.** A record's
   signature lands in `Decls.declare` from source and from a record alike, and
   the flat law runs there. A SEAL boxes a flat record from any file, so a
   boxed record's line says `boxed`: the layout is in its module's interface
   digest, and every key that sees the module moves with it. A layout that a
   held line and this analysis read two ways (`layouts_moved`) sends the
   attempt back to the sources whole.
8. **A file's key folds what its bodies can SEE:** its text, its own module's
   interface (a sibling's names need no import), and the closure of its
   imports (a type reaches a body through a signature it never names).

**THE SWEEP: 315 of 315 edits hold clean.** `tools/hold_sweep.sh packages/cli` touches every
source, one at a time, and builds through the hold.

## 3. Laws this layer paid for

- **Move the content, not the key.** A key over lowered bodies can never match
  a file that is never lowered. Make the content a function of what the key
  already reads.
- **One derivation.** A hold decided by CONTENT (the object) while its shape
  came from a record keyed by NAME (program root, module) let one program
  hold a file another stored and read its own stale lines:
  `Bar has no field y`, on a correct program.
- **A guard over a filtered list is always false.** `union` asked
  `files.any(is_held)` of a list that holds only non-held files. The hold
  only ever linked for LEAF edits, which is all anyone had measured.
- **"interface records did not stabilize" was never cache poison.** It was
  the restart inheriting attempt 0's holds. `rm -rf .avra-cache` hid it.
- **The gate never edits a file**, so it cannot see a hold that is wrong for an
  edit nobody tried. Slice 1 was called sound on two measured edits; a third
  broke it. The sweep touches every file.
- **A workspace is an identity, never a value.** Its hooks capture it, and a
  copy shares its tables: a restart from a copy keeps every hold, and a changed
  copy is asked through hooks that answer for the original.
- **The declaration answers, never the ask.** A plain fn wanted from inside an
  instantiation carries its caller's substitution and is the same body.
- **A suite that never held attacked nothing.** `tools/cache_attacks.sh` ran
  22 green steps at `held 0/6`. It now counts holds and refuses zero.

- **Two copies of a law disagree the day one moves.** Typing made a record
  flat over ONE `int`; the record loader made it flat over any scalar or
  text. A parsed file then read `{ message: string }` as its field while every
  held object boxed it — caught only because a static refused to cross.
- **A nested declaration is no symbol.** A `quote { fn body_of() … }` mints a
  NESTED decl; a stub gave it its module's symbol, and it collided with the
  real `body_of` the day that file was the one that parsed.
- **A refused hold hid a native crash.** The sealed-flat program linked
  objects of two layouts and printed nothing; the differential caught it
  because the suite compares against the evaluator, which reads no cache.

- **A memo keyed on nothing answers for the day it was filled.** The extern
  symbols were gathered "once per run" — and a compile-time run lowers a unit
  before the last `use` line has admitted its package. `check std-avrac` was
  RED for it (51 "unknown runtime callee"); the memo is per table size now.
- **A text record spends its separators.** A case's name is any sentence; one
  holding a line break split its record line and un-held the whole module.
  The two name fields spell their separators out. (The end state is a typed
  snapshot, S8: no hand wire at all.)
- **The empty name is a name.** `then ""` is a legal case; "a line with no name
  is undecodable" refused its module.
- **One module, two spellings, two records.** A root file's `use @std.avrac.core`
  and `use core` named one module under two record keys. Imports are canonical.
- **A guard sized to the symptom un-holds the innocent.** "A program that boxes
  a flat record builds whole" took the hold from std-avrac's entire suite for
  one program test's `Counter`. The layout belongs in the interface.

## 4. The keepers

`sh tools/hold_sweep.sh [pkg] [path filter]` — every source touched, one at a
time, built through the hold, the outcome filed by class in
`build/hold-sweep.out`. Not in the gate (315 builds); run it after any change
to the hold, the records or the keys, and drive it to zero.


`make cache-attacks` (in the gate, 27 s): two programs and a library through
ONE store, 23 builds, each binary held to the evaluator, which reads no
cache. Steps: shared file / other bodies, leaf body edit, a fn nobody
reached, a new instantiation under a hold, a generic's body, a type's layout
in a module the program never imports, a signature, a fn taken as a value, an
exported const, file added, file deleted, entry-only edit, every `Unit` row
deleted. A new hold bug becomes a new step.

## 5. Direction — ranked

The cache layer (records, stubs, the restart loop, `is_held` at 20+ sites) is
a hand-rolled approximation of ONE thing: a persistent, content-addressed
query cache. The kernel exists in memory. What stops it persisting is that
nothing can write a compiler value down.

1. **`avra_snapshot` — freeze any value, thaw it immortal.** Boxes describe
   themselves (`runtime/avra_box.h`): a list, record or enum is an `AvraArray`
   with a per-cell `owned` mark; a map is two arrays; text and octets are raw.
   One C fn turns a closure-free value graph into one relocatable blob; a thaw
   is one read plus fix-ups, and the boxes come back IMMORTAL, so retain and
   release no-op on them. A query family then persists by saying so, and
   `record.av` / `interface.av` / `settlement_wire.av` die.
   **First family: `parsed(file)` by content.** `Parsed` is file-local ids and
   pure data. Parsing is ~75 % of `check` (8.8 of 11.6 s) and ~6 s of a cold
   build — and `check`, `test`, `emit` and `build` all take it at once.
   Cost: a runtime row (two landings, one seed); the key folds the compiler's
   own identity, because a blob's layout is that compiler's.
2. **The parser's fast path.** `grammar/executor.av` allocates a
   `FarthestFailure` and a list on every failed terminal and merges them on
   every alternative — and in a PEG most alternatives fail. Track a far
   CURSOR; collect the expected set by re-running only on a failed parse.
3. **File-local ids and a link step.** `TypeId`/`DeclId`/`FileId` are global
   and dense, numbered by ask order. That alone stops typed facts and lowered
   IR persisting like parse trees. The shape is `DefId = (file, index)`.
   After it a held file is just a query whose inputs did not move: the
   `is_held` branches, the stubs, the records and the restart all go.
4. **The pipeline as a declared table.** `table<Pass>`: name, inputs, family,
   persists. `analyze`'s order, `--time`, the memo wiring and the key are
   projections of it; a command is a `Want` plus a renderer.
5. **In-process object emission** — for the cold build's 291 clang spawns.

**Refused: per-function codegen units** (the 09-20 design). Once the hold
works they buy ~30 ms of clang on the one edited file, and cost thousands of
objects at link and every cross-fn inline at `-O1` (P4).

**Does 1–3 waste the build work?** No. What was bought is the store
(content-addressed, verify-on-read), the keys, parallel clang, the binary
cache, link-in-place, the phase timing, and this model — all of which the
persistent query cache keeps and generalises to every command. What dies is
the hand wire format, and only after its replacement is measured faster.

## 6. Protocol and traps

```sh
cp build/avra build/avra.pre            # the way back
sh tools/watch.sh 4000 make avra        # ONE generation per run
./avra build packages/cli --time        # the phase line is the instrument
make cache-attacks                      # after any hold or key change
sh tools/watch.sh 4000 make gate
# seed law: commit source -> make seed -> commit the seed -> re-gate
```

- `index N is out of bounds` naming no file → the IR EVALUATOR
  (`compiler/interp.av`): a settled const or lifted annotation whose shape moved.
- `make seed` fails, the tree builds → `./avra emit packages/cli` is stricter.
- `check <pkg>` counts its DEPENDENCIES' defects (51 `F0900` in std-avrac are
  std-io/std-process rows). Dedup by identity; name the scope.
- A compiler under test stands in `build/`, or it finds no std root.
- `./avra run` of a lone file under a tree picks up the TREE's `avra.toml`.

## 7. Open

- `@derive(Roles)` + `@derive(Fingerprint)` on `Ins` compiles clean and
  miscompiles; `Ins` wears a hand fold. Nothing in the cache reads a body
  fingerprint any more, so the fold's only reader is the keeper — delete the
  IR fingerprints or root-cause the pair.
- The receiver seal's body scan is O(all statements) per impl
  (`writes_receiver`); statements and expressions are separate arenas.
- A held impl has no body, so `writes_receiver` is false there: prove the
  flat/boxed mark crosses the interface, or treat the hole as live.
- An object key folds neither `opt` nor the runtime's identity.
- A file's key folds its DIRECT imports' digests. A layout reached through a
  type it never imports is covered by the attack suite today, not by the key.

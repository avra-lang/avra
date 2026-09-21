# The compiler cache — state, laws, direction

**The one cache doc.** It replaces eight handoffs, audits and designs: four
are deleted, four are one-line stubs so older citations resolve (git has the text).
Two companions stay: `2026_09_19_UNIFIED_PIPELINE.md` (the architecture
target) and `2026_09_16_BUILD_CACHE.md` (the history).

Worktree `avra-cache-cas`, branch `cache/cas`.

## 1. Numbers — the non-regression gates

`./avra build packages/cli --time`, under the machine lock.

| | 09-19 | 09-20 (regressed) | now | gate |
|---|---|---|---|---|
| cold | 22.7 s | 24.0 s | **21.0 s** | 23 s |
| no-op | 0.4 s | 0.4 s | **0.4 s** | 0.8 s |
| one-file edit, leaf | 1.2 s | 26.1 s | **1.3 s** (phases ~0.8 s) | 1.5 s |
| one-file edit, core file | *did not link* | 26.1 s | `whole.av` **1.9 s**; most core files are REFUSED and rebuilt from sources (§2.6) | 2 s |

Where a warm edit goes today (ms): resolve 250 · load 120 · fill 105 ·
link 110–220 · bodies 65 · lower 65 · emit 30 · clang 30.
**Target: 200–500 ms.**

## 2. The model

A build holds a file when it can skip it entirely: no parse, no typing, no
lowering, no clang. That is where the edit loop lives — an edit's cost is
ANALYSIS, and only a hold skips it.

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

**THE HOLD IS NOT YET RIGHT FOR THE COMPILER'S OWN SOURCE.** A comment in any
`grammar/*.av` or in `core/nodes.av` fails to link under the hold — 165 plain
`impl LowerCx` methods of `compiler/lower_walk.av` undefined; a stored object
defines them and is not on the link line, root cause open — and one in
`compiler/program.av` is refused with a false `F2024` (a `dyn` box over a held
impl). The fail-safe makes these correct and SLOW. `tools/hold_sweep.sh`
enumerates them: grammar/ is 11 of 11 refused. Nothing else in §5 lands until
the sweep is clean — the rest stands on the hold.

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

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
- [x] **S5 THE HELD DERIVATION** (`a2c99e0`) — `build_program_attempt`'s first half as one verb
      every command asks; per-file diagnostics persist; `check` holds
- [x] **S6 `test` on the derivation** (`99a6e54`): case symbols content-stable, cases ride the
      record, the suite's binary is cached
- [ ] **S7 the warm edit to < 500 ms** — 7a `d2d9356` (runs, evaluator, store writes, watchdog), 7b (the program's module by its inputs; one digest pass). LEFT: a stat-keyed digest cache, in-process object emission, the records' text
- [ ] **S9 `compiler/` organised** — 9a: leaf subsystems are modules (`resolve/ typing/ lower/ memory/ backend/ store/ host/ format/ dev/`); the map is `compiler/mod.av`'s header
- [ ] S8 `parsed(file)` persists (`avra_snapshot`, two landings); parser fast path
- [ ] S10 docs: this file is the law; the pipeline doc becomes history

## 1. Numbers — the non-regression gates

`./avra build packages/cli --time`, under the machine lock.

| | 09-19 | now | gate |
|---|---|---|---|
| `build cli` cold | 22.7 s | **17–18 s** | 23 s |
| `build cli` no-op | 0.4 s | **0.20 s** | 0.4 s |
| `build cli`, one body edit | 1.2 s | **~0.7 s** (phases ~0.49 s) | 1.0 s |
| `build cli`, a generic's home edited | — | ~3 s (the homes are read from the start; the program's module recompiles) | 5 s |
| `check cli` | 9.7 s | cold 9 s · warm **0.8 s** | 2 s |
| `check std-avrac` | 11.6 s, RED | cold 13 s · warm **~1.5 s**, clean | 2 s |
| `test std-json` | 1.6 s | cold 1.7 s · warm **0.4 s** | 1 s |
| `test std-avrac` (5325 cases, 111 programs, 27 nested) | ~40 s | cold 56 s · one edit **~2 s to compile**, then the 9 s run | — |

Where a warm body edit goes (ms), held 287/291: load 75 · admit 47 · fill 78 ·
analyze 42 · lower 35 · keep 33 · clang 80 · link 115 — and ~70 before any of it
for the program's key and the process, ~60 for the shim and the watchdog.
**Target: under 500 ms wall.** What is left is text and processes: every held
declaration minted and filled from its record each build (load + fill = 150),
a clang for one module, and the link.

## 2. The model

ONE DERIVATION (`compiler/derive.av`, `Workspace.derived(entry, want)`): hold,
load, admit, analyse, restart, lower every parsed body, write the records.
`build` links it (`build.av`), `check` prints it. What a command WANTS
decides what may stand in for a file: its warnings always (`Stored.Warn` under
the file's key), its object and asks too when the want links.

THE PROGRAM'S MODULE IS NO FILE'S. Every file — the entry included — is an
ordinary object: its declared bodies, and its top level as a body under its
program symbol. What a PROGRAM adds is one small module keyed by its own
bytes: the instantiations no file owns, and an entry that CALLS — a build's
the entry file's program symbol, a suite's every case and every program
(`Owned { Whole, File, Program }`, `ProgramModule`). So `test` is a build with
another entry (`compiler/suite.av`): the same objects, one link, one binary
for a package's cases and its program tests. A file's `Said` row — its
warnings and its cases — is what stands in for it under every want; the
evaluator's agreement with a program is remembered under the text of every
file the program can reach.

A BODY EDIT READS ONE FILE. An instantiation lowers from its generic's body,
so its HOME used to be read every build. The program's module is a function
of its INPUTS — the root asks (every file's `asks` row) and the key of every
home it ever lowered from (`Derived.asked`) — so it is kept under that, and a
derivation that owes instantiations nobody lowered (`unlowered`) only reads
the homes when no build of those very asks kept the module (`whole`). `check`
asks the same of a "lowered clean" mark. And a file that WILL be read brings
exactly the files its compile-time runs read the last time (`settle_holds`,
from its record's `file` line), never a list that only grows.

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

### Where it lives

`compiler/derive.av` the derivation · `record.av` `interface.av`
`settlement_wire.av` what stands in for a file · `store/` the rows ·
`build.av` `link.av` the build · `suite.av` `suite_entry.av` the suite ·
`cli/src/commands/{build,check,test}.av` are a workspace, one verb, a voice.
The 09-19 plan's `World`/`Compiled`/`Projection` types did not land and are not
owed: `Workspace.derived(entry, want)` IS the one verb, `Derived` the one
answer, and a command is the few lines that ask it. A trait with one verb and
three callers was the ceremony the plan warned of.

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

- **An object reads more than interfaces the day it bakes a value in.** The
  entry used to be re-emitted every build and hid it: a reader bakes a foreign
  const's VALUE, so the value is in the const's interface line; a const that
  RUNS a fn bakes that fn's BODY, so a file whose lowering ran anything folds
  the text of every file it can see (`runs`, in the record's `file` line).
- **A symbol outlives every id a run hands out.** A case was `spec$<DeclId>`;
  a held object's case would have answered to another file's number.
- **Held by NAME is held by accident.** A held `impl` aimed at every record of
  its target's name — two program tests' `P.show` met. The record keeps the
  declaration it aims at.
- **A restart from the sources that can restart is a loop,** and each turn is a
  workspace that never dies: 6 GB in a minute. `unheld` refuses the second.
- **The root module's name is empty, and `split` drops a trailing empty field.**

- **A list that only grows is a hold that only shrinks.** "Remember every
  file a compile-time run ever asked a body of" read ten files on every edit
  after one unlucky one. A file's record keeps what ITS runs read.
- **The watchdog cost the warm build more than the build.** 80 ms of work,
  0.3 s of a poll that read every process before it looked for the end.
- **`mut x = self.xs[i]; x.set(..); self.xs.set(i, x)` COPIES.** The element is
  held twice while it is written. The evaluator did it on every register write.
- **A sweep that asks "clean?" does not ask "held?".** The hold collapsed to
  25/292 on correct builds; the sweep files a thin hold now.

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

## 5. Where it stands against the bar, and what is left

| the owner's bar | now | verdict |
|---|---|---|
| warm `build` < 500 ms | no-op 0.15 s · one body edit **~0.7 s** | the no-op is there; the edit is 0.2 s short |
| `test` reuses the cache | one binary a suite, linked through the store; an edit compiles in ~2 s, then the run | met |
| `check` near instant | unchanged 0.20 s · one edit ~0.8 s (was 8–11 s) | met for the no-op; the edit shares the build's floor |
| every command one derivation | `build` `check` `test`; `run` `emit` `ir` still lower with nothing held | the evaluator needs IR a held file does not have |

**The floor under an edit, and what removes it** (ms, of ~490 traced):
load 75 + fill 78 — every held file's declarations are MINTED and its shapes
FILLED from text on every build, 15 000 declarations for the one file that
moved; link 115; clang 80 (a process for one module); the file itself ~125.

1. **Mint what is touched, not what exists.** Records answered per DECLARATION on
   demand: a namespace wants names, `sig(d)` wants one shape. What blocks it is
   everything that walks ALL declarations — `impls_by_name` (a method table
   must know every impl of a name: an index line per record fixes that), the
   flat law (a layout read before its declaration is asked: ask `sig` first,
   the doctrine already says so), `held_stubs` (stub what a parsed body names).
   This is the file-local-id direction taken one query at a time, and it is
   worth ~200 ms.
2. **Emit the object in process** for a build that moved one or two modules:
   `LLVMTargetMachineEmitToFile` behind `backend/llvm_api.av`. ~45 ms, and no
   second pipeline for the cold build, which stays parallel clang.
3. **`avra_snapshot`** — freeze a closure-free value, thaw it immortal. It wants a
   LANGUAGE builtin (`snapshot(v)` / `thaw<T>(bytes)`, type-checked closure-free,
   a layout print in the blob) and two runtime rows (two landings). It ends the
   hand wire in `record.av`/`interface.av`/`settlement_wire.av`, persists
   `parsed(file)` (parse is 3 s of a cold build, 7 s of `check std-avrac`), and
   gives the evaluator IR for held files — which is what puts `run`/`emit` on the
   derivation.
4. **The parser's fast path** — `grammar/executor.av` builds a farthest-failure
   record per failed terminal; a PEG fails most alternatives.
5. A home's edit reads the homes AFTER a first derivation that could not use
   them: when the file that moved IS a remembered home, start with `homes: true`.

**Refused: per-function codegen units** (the 09-20 design). Once the hold
works they buy ~30 ms of clang on the one edited file, and cost thousands of
objects at link and every cross-fn inline at `-O1` (P4).

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

- THE SEAL IS WHOLE-PROGRAM (avra-8sb5.21): a `mut` seat boxes a flat record
  from any file. The cache carries it in the interface and restarts when it
  moves; the root fix is an inout ABI, so a layout is its declaration's alone.
- A `dyn` field boxes its value only where the trait is imported, spelled or
  not (avra-8sb5.22).
- A lone file outside a checkout has no prelude (avra-8sb5.20) — on main too.
- A record naming a deleted file un-holds its whole module for one build.
- A held non-entry file with top-level statements is not refused by the entry's
  law until it is read; its record should say it RUNS, and be read.
- `program_key` folds every file under every closure root, tests included: a
  test edit misses the binary (the derivation then holds everything).
- `@derive(Roles)` + `@derive(Fingerprint)` on `Ins` compiles clean and
  miscompiles; `Ins` wears a hand fold.
- The receiver seal's body scan is O(all statements) per impl (`writes_receiver`).
- An object key folds neither `opt` nor the runtime's identity (the program's
  module does).

## 8. What the campaign wanted from the language (the end-of-life survey)

1. **`export use`** — moving a file between modules rewrote every importer;
   a module could not keep its surface while its files moved (F3014).
2. **A Map you can walk and unset** — `held`, `homes`, every memo is a
   `Map<string, bool>` that can only grow; a hold could not be withdrawn, so
   holds are ASKED and settled in a second pass.
3. **A `Set`** — `distinct`, `contains` on lists, and worklists licensed `I16`
   are all one missing type.
4. **Read-modify-write that does not copy** — `mut x = self.xs[i]; x.push(v);
   self.xs.set(i, x)` is the obvious spelling and it is O(n) per write; the
   compiler could see the last read and move.
5. **Generic rows at the C boundary** — `snapshot<T>` cannot be written: a
   record does not fit a `ptr` seat, so the feature needs a builtin.
6. **A string compare in the runtime** — `text_before` walks code points in
   Avra; sorting paths was a visible cost.
7. **A way to say "this import is for an impl"** — a module nobody imports a
   name from is never admitted, so its `impl` blocks never register.

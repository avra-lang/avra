# The unified pipeline — one store, one derivation, one verb

**Status: HISTORY (2026-09-21).** What landed, and what replaced the rest, is `2026_09_21_COMPILER_CACHE.md`: one derivation (`compiler/derive.av`) every command asks, `test` as a build with another entry, and `compiler/` split into modules. The `World`/`Compiled`/`Projection` types below were not built — one verb and one answer did the job. Kept for its benchmarks and its reasoning.

**Status then:** aggressive refactor, in progress. This document is the target and
the deletion ledger. It supersedes the ad-hoc per-command plumbing; the north
star in `ROADMAP.md` still governs the layers.

> **State and direction live in `2026_09_21_COMPILER_CACHE.md`.** Two things
> below have moved. P5's blocker is PAID: a file's object now holds every body
> the file declares, so a build's object and a suite's are the same object and
> `test` may call `compile_lowered` as it stands. And the order changes:
> semantics before folders — put every command on the one path (P5, the
> persistent `parsed` query), THEN `World`/`Compiled`/`Projection` (P2–P4) as a
> rename-and-delete pass, THEN the folder split (P6).

## 0. Why

Build was optimised for two days and is the most current path in the tree.
`check`, `emit`, `test`, and `run` still re-plumb, re-parse, re-lower, and link
through a second, older path. There are **two caches** (the in-process query
kernel, disarmed at the end of every run; and the on-disk per-file store, wired
only to `build`). `compiler/workspace.av` is a 3,125-line god-object holding
packages, files, declarations, the memo wiring, the pass drivers, the lowered
program, the cases, and the hosts at once. Twenty-nine files in `compiler/`
have no organising principle.

The goal is not a feature. It is **one World, one Cache, one derivation graph,
one Projection trait**, and the deletion of everything that is a second spelling
of those.

## 0.1 Hard benchmarks — the non-regression gates

Measured in THIS tree, 2026-09-19, under the machine lock. **The build half is
the proudest thing in the tree; P1–P6 must not move it.** The check/test half is
what the refactor exists to fix. Wall is the shared machine's number; the phase
split and user CPU are the tree's.

| command | value now | gate (must not exceed) |
|---|---|---|
| `build packages/cli`, **COLD** (`rm -rf .avra-cache`) | 22.7 s real · 25.1 user · 10.7 sys | **23 s** |
| `build packages/cli`, **warm edit** (one body edit) | 1.2 s real · 0.58 user | **1.5 s** |
| `build packages/cli`, **no-op** | 0.4–0.7 s real | **0.8 s** |
| `check packages/cli` | 9.7 s real · 9.2 user | **10 s** |
| — its phases | parse 3.1 · resolve 3.4 · sigs 0.3 · bodies 1.3 · lower 1.2 s | — |
| `check packages/std-avrac` | 11.6 s real · 10.8 user | **12 s** |
| — its phases | parse 8.8 · resolve 1.3 · bodies 1.3 s | — |
| `test packages/std-json` | 1.6 s real · 0.4 user | **2 s** |
| `test packages/std-avrac` (red fixture) | ~10.7 s | — |
| `make seed` / `make seed-check` | ~21 s / ~22 s | **25 s** |

**Warm-edit receipt (why it must not regress):** the hold is ON
(`CACHE_HOLD_ENABLED = true`), 273/276 files are held, 2 modules re-emit,
clang 41 ms, link 194 ms. This is the whole point of the build campaign.

**Targets the refactor owes, in numbers:**

- `check <pkg>` after one edit ≤ **2 s** — unchanged files must not re-parse,
  re-resolve, or re-type (they already hold for `build`).
- `test <pkg>` after one edit ≤ **2 s** — a suite compiles through the same
  object cache, so an unchanged suite hits and a changed one re-emits one file.
- **No cold number may regress.** Every phase step re-runs the table above.

**Measuring (always under the lock):**

```sh
./avra build --time packages/cli                          # no-op
rm -rf .avra-cache && ./avra build --time packages/cli    # cold
./avra check --time packages/cli
./avra check --time packages/std-avrac
/usr/bin/time -p ./avra test packages/std-json            # a small suite
```

## 1. First principle

> Every artifact the compiler produces is a pure function of
> `content ⊕ environment`. The store is where those answers live. A command is
> only *which answer you want*.

Two words carry the whole design:

- **Derivation** — `(content, environment) → artifact + diagnostics`. Pure,
  memoized, persisted. The closed, ordered stages are
  `parse → resolve → sig → typeck → lower`.
- **Projection** — what a consumer does with a derivation's answer.

The compiler therefore has **one verb**:

```
compile(world, want, entry) -> answer
```

`want` is the root query (`Diagnostics | Ir | Value | Binary | Verdict`). Every
command is a `want` plus a renderer. The build fast paths are not a separate
program; they are the `Disk` backing of the one cache.

## 2. Target architecture

Layering stays one-way and unchanged: `core → query → grammar → features →
language`. What changes is that `compiler/` becomes *small and organised*, and
the cache stops being a `build`-only appendage.

```
packages/std-avrac/src/
  core/                  # infrastructure (unchanged role)
    ids.av nodes.av arena.av side_table.av
    types.av ir.av digest.av host.av source_text.av
  query/                 # the cache kernel — language-agnostic
    db.av memo.av key.av backing.av
  grammar/               # the language-agnostic engine (unchanged)
  features/              # the language: one dir per feature (unchanged)
  compiler/              # the driver — the only place a command exists
    world.av             # World: the one threaded value
    assemble.av          # features -> the hashed language object
    compiled.av          # Compiled: the lazy view over the derivation
    derive/              # the pass graph, in stage order
      parse.av resolve.av sig.av typeck.av lower.av memory.av receivers.av
    projections/         # the commands
      mod.av             # Projection trait, Want, Request
      check.av emit.av run.av build.av test.av
    cache/               # the language's half of the store
      mod.av families.av keys.av hold.av wire.av
    link/                # linking: tool, argv, plan, clang
      mod.av tool.av plan.av
    backend/             # what consumes the IR
      llvm.av llvm_api.av interp.av interp_bytes.av ir_text.av
    packages/            # where source lives
      manifest.av files.av
  diagnostics/           # the diag currency + rendering (unchanged)
packages/cli/src/
  main.av                # composes subcommands
  stage.av               # the hand-off light phase
  commands/*.av          # ONE file per subcommand, a few lines: build the Request,
                         # hand it to a Projection, render the answer
```

`features/decls.av` (the declaration table) is infrastructure, not a feature:
it moves to `compiler/decls.av`.

## 3. The seams — traits, enums, and the standard signature

The law that decides each: **a trait for behaviour with more than one
implementation; an enum for a closed vocabulary; one standard signature for the
closed, ordered stages.**

| seam | shape | why |
|---|---|---|
| cache tier | `trait Backing` — `Mem` / **`Disk`** / `Remote` | N impls, one verb set; the single place the store is abstracted |
| command | `trait Projection` | N impls; today's `Runnable` |
| in-process engine | `trait Evaluator` — `Interpret` / `Jit` | L3's three engines; the IR is the shared input |
| source IO | `trait Host` — `Disk` / `Memory` | already is |
| derivation stages | **one signature, no trait** | closed and ordered; the order *is* the contract |
| artifact families | `enum Family`, no trait | closed vocabulary; adding one is a core event |
| backend emitter | a value now; a trait at the second backend | one impl today (P17) |

Subset note: Avra refuses a trait impl over a generic type and generic methods
(F2031). So these traits stay **non-generic** (bytes in/out) and typing rides
generic *structs* (`Memo<T>`) on top — exactly as the kernel already does.

### The types

```avra
// ONE world value, threaded everywhere — was Workspace + Store + Host + Db.
type World = {
    lang: Language,        // the language object, hashed
    host: Host,            // source bytes in
    cache: Cache,          // kernel + store, as one thing
    packages: Packages,    // the manifest closure
}

// THE CACHE — the kernel and the store collapse; a family says WHERE its answer lives.
type Cache = {
    cells: Cell<Table<CellState>>,   // deps, changed_at, verified_at
    mem:   Table<Bytes>,             // live answers, this run
    disk:  Backing,                  // content-addressed answers, cross-run
}
type CellState = { deps: List<Key>, changed_at: int, verified_at: int, where: Where }
enum Where { MemOnly, Persist }      // CAN this family's value cross a process?

type Key = { family: Family, parts: List<string> }   // digest(family, parts) = content ⊕ env

// THE COMPILED — the one derivation every projection shares. Lazy, so a
// projection that wants diagnostics never forces `units`.
type Compiled = {
    interfaces:  List<Interface>,   // THE WAIST — the only thing that crosses a file boundary
    units:       List<Unit>,        // lowered IR per (decl, type-args)
    diagnostics: List<Diag>,        // value + diagnostics invalidate together
    lowered:     Lowered,           // ONE semantics, three engines
}

// A PROJECTION — a command is one of these, and nothing else.
trait Projection {
    fn want() -> Want
    fn project(w: World, c: Compiled, r: Request) -> Result<int, Report>
}
enum Want { Diagnostics, Ir, Value, Binary, Verdict }
```

### The flow

```
World { lang, host, cache, packages }
        │
        ▼
  derive(entry) ──► Compiled { interfaces, units, diagnostics, lowered }
        │                      │
        │                      └─ cache: key = content ⊕ env;  tier = Mem | Disk
        ▼
  project():
     check → render(diagnostics)          emit  → join(units)
     run   → evaluator(lowered)           build → link(objects(units))
     test  → build(entry = cases) then run
```

## 4. Where the build optimisations land (none lost)

| the optimisation already paid for | its new home |
|---|---|
| per-file object keys (`obj_key_of`) | the `Obj`/`Unit` family key in `cache/keys.av` |
| per-file reuse (`store.place`) | a `Persist` family's `has` |
| parallel clang (`parallel(jobs, CLANG_WIDTH)`) | `link/` — owned by `build`, **reused by `test`/`run`/`emit`** |
| binary cache + cap/LRU (`recent_keys`) | the `Bin` family + a `Collect` policy on `Disk` |
| interface records + hold (`load_interface`, `hold_only`) | `cache/hold.av` |
| link plan / argv / chmod | `link/plan.av` |
| `CACHE_FORMAT` / language hash | the key's **environment** term |

The algorithms do not move. Their **owner** does: `build_program` becomes "the
build projection + the `Disk` backing", so every other projection inherits it.

## 5. Invariants

1. **The tuple is the trust.** Verify-on-read (path + length + digest); never
   believe the key alone.
2. **Never persist a refusal.** A cache serves successes only; a broken program
   speaks on every run.
3. **The waist.** Only the interface crosses a file boundary. The AST and typed
   tables never do.
4. **One key derivation.** Memory and disk use the *same* key; the tier is a
   policy, not a different identity.
5. **`disarm` stays.** It breaks the ownership cycle correctly; cross-run speed
   comes from `Disk`, not from keeping the graph alive.
6. **Passes are pure.** The kernel memoises purity; a stage that mutates a node
   is a defect.

## 6. The deletion ledger

Every current `compiler/*.av` either moves, merges, or dies. The point of the
refactor is the right-hand column.

| current | target | disposition |
|---|---|---|
| `workspace.av` (3,125) | `packages/`, `cache/`, `derive/`, `compiled.av`, `projections/` | **split; the god-object dies** |
| `mod.av` (220) | `assemble.av` | rename |
| `program.av` (143) | `compiled.av` | merge |
| `analysis.av` (105) | `derive/` wiring | merge |
| `resolve.av` (770) | `derive/resolve.av` | move |
| `typing.av` (578) + `typing_declare.av` (526) + `typing_impls.av` (349) | `derive/typeck.av` (+ `typeck/`) | **merge three into one stage** |
| `lower.av` (528) + `lower_state.av` (625) + `lower_walk.av` (312) | `derive/lower.av` (+ `lower/`) | **merge three** |
| `memory.av` (524) | `derive/memory.av` | move |
| `receivers.av` (460) | `derive/receivers.av` | move |
| `interface.av` (984) + `store.av` (200) + `build_cache.av` (499) | `cache/` + `link/` + `projections/build.av` | **merge three into one cache** |
| `test_run.av` (258) | `projections/test.av` + `link/` | merge |
| `llvm.av` (1,001) + `llvm_api.av` (79) | `backend/llvm.av` | move |
| `interp.av` (2,008) + `interp_bytes.av` (202) | `backend/interp.av` | move |
| `ir_text.av` (152) | `backend/ir_text.av` | move |
| `source_text.av` (679) | `core/source_text.av` | move (text is infrastructure) |
| `manifest.av` (461) | `packages/manifest.av` | move |
| `settlement_wire.av` (299) | `cache/wire.av` | move |
| `escapes.av` (175) | `derive/memory/escapes.av` | move |
| `codes.av` (84) | `diagnostics/codes.av` | move |
| `witnesses.av` (236), `attack.av` (373) | `compiler/dev/` | dev proofs; not a command surface |
| `cli/commands/shared.av` (552) | `link/` + `projections/` + thin cli | **split; the cli loses its copy of linking** |
| `cli/commands/{check,run,emit,build}.av` (≤30 each) | one line each | become `Request` builders |

## 7. Migration — aggressive, but every step is green

Each step builds, passes the corpus/gate, and refreshes the seed at the end.
Deletion happens step 6, not before; until then the new modules are the only
ones gaining consumers.

**Landed so far:**
- **P0 — the document and its hard benchmarks.** (0.1)
- **P0.5 — tracked artifacts removed.** `9537854` removed 273 orphaned
  `.part.ll.o` (6.1 MB; nothing read them, and `.gitignore` caught
  `*.av.ll.o` but not `*.av.part.ll.o`). `62b032f` removed two committed
  Mach-O artifacts (`main_stamped`, 1.6 MB, and `main.av.entry.ll.o`) and
  made the ignore `*.ll.o`.
- **P1 (partial) — `language/` renamed to `compiler/`** (`b57956e`): the tier
  holds the driver, the pass graph, the cache, the backend, and the
  projections, so the name is now honest. Layering is
  `core -> query -> grammar -> features -> compiler`. The rename silently
  narrowed the I39 keeper (`tools/idioms.py` scoped `src/(features|language)/`)
  and the count fell 57 -> 27; fixed at the site, back to 57.
- **P1 — the `Backing` seam** (`compiler/backing.av`): a `trait Backing`
  (`DiskBacking` / `MemBacking`) so one cache can hold either tier, with a
  spec driving both through the same verbs. The build still uses `Disk`
  unchanged.
- **IDIOM DEBT ZERO** (`1e511c3`, `f49cb8b`): all 57 sites burned down —
  unused imports, identical literals named as constructors, duplicated
  messages, a push loop made a comprehension, hand-interned scalar types
  spelled as literals, and the 30 I39 free verbs moved into their state's
  impl. `make idioms` reports 0 across 514 files / 19 packages.
- **P6 (started) — `workspace.av` split 3,125 -> 1,264 lines** (`b8aad81`,
  `914b6fc`, `71fb238`): `host.av` (the filesystem seam), `program.av` (the
  Program view), `expand.av` (macros/derives/marks), `modules.av` (paths and
  files), `whole.av` (analysis/entries/cases/hold), `packages.av` (the manifest
  closure), `voices.av` (its diagnostics).
- **Cache/backend file splits** (`13bb325`): `record.av` (the record format)
  out of `interface.av` (984 -> 420), `link.av` (clang argv/exit/binary) out of
  `build_cache.av` (499 -> 440).
- **The shared compile seam** (`862b6f9`, `0f776a5`): `compile_lowered` is now
  the emit-moved-files + parallel-clang + link half of the build, a `Workspace`
  method, so a suite can compile through the SAME per-file object cache and
  link path. This is the seam P5 needs.

**P5 is subtler than it looks — and must not be wired naively.** The build
lowers only what the entry REACHES; a suite lowers EVERY declared body (a case
is a declaration nothing reaches). `obj_key_of` folds the file's bytes and its
imports' interfaces, NOT the lowering mode — so the same file yields two
different objects (one carrying the file's unreachable bodies, one not) under
one key. Reusing a build object in a suite would link a binary missing bodies.
The fix is a mode in the object key, or per-ITEM codegen keyed by the body
fingerprint (the design's `codegen(item)`), not per-file reachability.
`compile_lowered` is the seam; the key discipline is the work.

**CONFIRMED (pre-existing on `cache/cas`, not introduced this session): a
per-file object key does not fold the REACHABLE body set, so two programs that
share a cache and a file collide.** Minimal repro:

```
ra:  deps @std/text;   use @std.text.{from_codepoint};  ... from_codepoint(65)
txj: deps @std/sqlite; open/prepare/... (sqlite reaches @std.text.has_nul)

rm -rf .avra-cache && ./avra build build/scratch/ra && ./avra build build/scratch/txj
  -> Undefined symbols: _av_$40std$2Etext$2Ehas_nul, referenced from sqlite
```

`ra` emits `text.av`'s object with only the bodies it reaches; `txj` reuses it
under the same `obj_key_of` and links a binary missing `has_nul`. Reproduces at
`b581270` (the branch base) with the same probe. This is what makes `make traps`
order/cache-dependent: a trap that reaches `text.from_codepoint` pollutes the
object a later sqlite trap reuses. The fix is per-ITEM codegen keyed by the body
fingerprint (the design's `codegen(item)`), or folding each file's reachable
body fingerprints into its object key — not per-file reachability.

**Still to land:** P2 (`World`), P3 (`Compiled` + one derivation), P4
(`projections/` + thin CLI), P5 (`test`/`emit` on the `Disk` backing —
`compile_lowered` is extracted and ready to be called by a suite), P6 (finish
the split; merge `typing_*`/`lower_*`), P7 (the `Diags` family).

**A cache hazard, hit twice this session:** `seed-check` (and `gate`) can fail
with `undefined symbol ...prelude.eprintln` when the `.avra-cache` was written
by a *different compiler generation* than the seed compiler reading it. The
seed itself is fine (it defines the symbol); the cache is incoherent. The fix
is `rm -rf .avra-cache` before `seed-check`. A gate that runs `seed-check` after
a build from a new generation must not trust the previous generation's cache.

**An unresolved environment quirk:** in the long-lived `avra-cache-cas` worktree
`make traps` fails with `undefined symbol ...text.has_nul` (sqlite's objects
reach a text body that is not emitted), while the SAME commit in a fresh
`git worktree`, and this worktree's exact files rsynced to `/tmp`, are GREEN
(`24 contracts held`) with the same `build/avra`. The source is verified; the
difference is the worktree path or state not carried by git. A fresh checkout
is the receipt until it is root-caused.

**Other cruft found, not yet removed:** none tracked beyond `BUILD_SEAM.diff`
(a parked design record, now repointed).

- **P0 — this document.**
- **P1 — `cache/`.** Extract `Store` + `BuildCache` behind `trait Backing`
  (`Mem` + `Disk`). No behaviour change; `build` still uses `Disk`. Verify the
  build timings are unmoved.
- **P2 — `World`.** `World { lang, host, cache, packages }`; both paths construct
  it. `build` keeps `Disk`; `check`/`emit`/`run`/`test` get `Mem` for now.
- **P3 — `derive/` + `compiled.av`.** One derivation returning `Compiled`;
  `check`/`emit`/`run` read it. Collapses `check_bodies` / `emitted` / `ran` /
  `cases_checked`.
- **P4 — `projections/`.** `trait Projection` + five impls; the CLI becomes one
  line per subcommand. `shared.av` shrinks to argument handling.
- **P5 — `test`/`emit` on the `Disk` backing + `link/`.** The measurable win:
  a test suite reuses per-file objects and the link plan.
- **P6 — delete.** Remove the old `compiler/*.av`, the cli's link copy, and
  `features/decls.av`; refresh the seed.
- **P7 — the `Diags` family.** Persist per-file diagnostics, verify-on-read,
  never a refusal; keep `check --no-cache` as the oracle.

## 8. Subagents — where they help, where they hurt

**Safe and useful:** read-only inventory (callers of a symbol, every command
entry point), impact maps before a deletion, adversarial review of a landed
slice, and drafting docs. They fan out without touching the tree.

**Harmful here:** parallel *edits*. Nearly every file in `compiler/` is shared,
the tree self-hosts through one seed, and heavy steps serialise on one
machine-wide lock (`/tmp/avra-build.lock`). Two agents editing shared files and
refreshing the seed race; the cost of reconciling exceeds the parallel win.

**Rule:** one driver authors the refactor in dependency order; subagents are
read-only or review-only. A subagent may author an *isolated new file* only when
it has no shared imports yet and the driver wires it.

## 9. Bootstrap and risk

- Every `packages/` change ends with `make seed` + commit `bootstrap/seed.ll`
  and `bootstrap/seed.sources`, then `seed-check`.
- Keep `cp build/avra build/avra.pre` before any change that could break the
  compiler's reading of its own source.
- The build fast paths are the receipt: P1–P5 must leave
  `./avra build --time packages/cli` unmoved on `emit`/`clang`/`link`.
- If a step cannot be made green quickly, revert it — the target is the
  deleted code, not the deleted compiler.
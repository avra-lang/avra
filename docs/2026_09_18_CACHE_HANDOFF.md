# Cache handoff — sub-second edits

You are continuing the Avra build-cache campaign. **The hard part is done: the
parse-free hold is ON and SOUND.** Your job is to make edits **sub-second**.
Read this whole file first; it is the context you would otherwise spend hours
rediscovering.

## 0. Mission

`build packages/cli` (the compiler's own build, ~200 files). Targets:
**cold < 60 s**, **edit < 1 s**. Today: no-op 0.37 s, cold ~28 s, **edit ~4.9 s**.

## 1. Where you are

- Repo/worktree: `avra-cache-cas`, branch **`cache/cas`**, HEAD **`c509c2c`**.
- The cache lives under a gitignored `.avra-cache/` at the worktree root.
- **Run everything through `./avra`** (the shim). It `cd`s to the tree root,
  exports `AVRA_CWD` and `LLVM_PREFIX`, takes the machine-wide build lock for any
  package-scale run, and wraps it in `tools/watch.sh` (a memory cap + peak
  print). `make gate` is the bar; `sh tools/watch.sh 4000 make gate` is how it
  runs (ONE heavy process at a time — the machine has watchdog-panicked twice).
- A **single-file** `./avra check <file>` is light (sub-second, no lock).
- A **bare** `build/avra` invocation must set `LLVM_PREFIX=/opt/homebrew/opt/llvm`
  (the shim does it; a bare shell does not) and link beside `build/` so the std
  root resolves (`avra_self_dir` = `<binary>/../packages`).

## 2. Architecture (what is built)

Files that matter, in dependency order:

- **`packages/std-avrac/src/compiler/store.av`** — the content-addressed store.
  `Stored` = `{Sig, Fp, Unit, Obj, Mod, Bin, Warn}`; `node_key(family, parts)`
  derives a key; rows live at `<root>/<family>/<shard>/<key>` with a `.deps`
  sidecar; `has` is two `exists` and reads nothing. `CACHE_FORMAT` lives here
  (bump it to invalidate every artifact).
- **`packages/std-avrac/src/compiler/interface.av`** — the **waist**. One text
  record per *module*: `import` lines, a `bytes`/`iface` digest line, and one
  line per declaration. `keep_interfaces` writes it; `load_interface` /
  `mint_held_interfaces` / `fill_interfaces` rebuild declarations from it without
  parsing. `obj_key_of(ws, store, m, path)` is a file's object key = its bytes +
  each import's stored interface digest. `held_modules`/`held_paths`/`held_stubs`
  are the walk. **`type_wire`/`read_type_wire`/`decl_wire`** are the ONE type
  projection (nominal nodes = file + declaration ordinal), and `read_type_wire`
  is its inverse.
- **`packages/std-avrac/src/compiler/settlement_wire.av`** — the on-disk forms:
  a settled const (`settled_wire`), and a unit's **edges** (`wanted_list_wire` /
  `wanted_list_from_wire`, encoding `List<Wanted>`). Reuses `wire_field` /
  `wire_value` / `WireReader`.
- **`packages/std-avrac/src/compiler/build_cache.av`** — the driver.
  `build_program(ws, entry, mode, opt, runtime, disk, linker)`. Whole-program
  binary cache first; else the hold path: `held_modules` → `load_interface` →
  `admit_all` → `mint_held_interfaces` → `fill_interfaces` → `program` →
  `lowered_checked` → per-file `emit_module` → link. `CACHE_HOLD_ENABLED` is the
  flag (ON). `--time` prints the phase split.
- **`packages/std-avrac/src/compiler/workspace.av`** — the query kernel and the
  lowering driver. `lowered(id)` consults the store: a **held** unit returns no
  body plus a declaration **stub** and its persisted **edges**; a **fresh** unit
  is lowered and its edges kept (`remember_deps`). `held_deps`/`unit_stub`/
  `attach_store` are here. `analyze_all` skips held files' resolve/sigs/bodies.
- **`packages/std-avrac/src/core/types.av`** — `TypeRegistry`. A record's
  representation is FLAT (bare field) or BOXED; `mark_flat`/`unflatten`/`is_flat`/
  `machine_shape`/`rides_pointer`. **This is where the soundness lives** (see §5).
- **`packages/std-avrac/src/compiler/typing_impls.av`** — contains THE fix.

Design source of truth: **`docs/2026_09_16_BUILD_CACHE.md`** (read "THE STORE"
and "THE WAIST"); current state and the trail: **`docs/2026_09_18_CACHE_INTERFACE_AUDIT.md`**.

## 3. Measure and verify (the protocol)

**Measure** (user CPU, never wall — the box runs at load 10–175):
```
./avra build packages/cli --time      # prints the phase report
```
The held path prints: `parse/resolve/sigs/bodies`, then
`held N/M, hold/load/admit/fill, analyze, lower, emit/clang/place/link`.
Today's edit split: `lower 1764, load 1117, fill 726, admit 452, place 519,
link 119` ms.

**Verify — a speed without a differential is worthless.** Every change must keep
these green:
1. **Diagnostics differential**: a held-built compiler's
   `check packages/std-avrac` must be IDENTICAL to a whole-program build's.
2. **Probe**: `./avra build build/scratch/probe` → the binary prints `42`.
3. **Self-build**: the held-built compiler must build `packages/cli` cleanly.
4. **Self-hosting**: whatever you change, the compiler must still compile its own
   source with the binary it just produced (build the source, install, build
   again).

A held-built compiler that **links and then traps** is the failure mode to fear:
LLVM's opaque pointers silently mix representations, so there is no loud error.

## 4. Lessons (the laws this work paid for) — DO NOT RE-LEARN THESE

1. **The flat/boxed decision must be DECLARATION-driven, not existence-driven.**
   The whole-session bug: `typing_impls` unflattened (boxed) **every** impl's self
   type, so a DERIVED `Fingerprint` impl sealed `DeclId`/`TypeId` — boxed in a
   parsed build, bare in a held build (whose derives never run). Two objects,
   two representations (`ptr` vs `i64`), silently mixed. **The fix: a record keeps
   its box only if it has a `mut fn` METHOD** (`writes_receiver`), because only a
   writing method needs an identity. A reading impl changes nothing.
2. **Cross-run identity is a CONTENT projection, never an interned ordinal.**
   `mangle` built specialization names from `TypeId` ordinals; ordinals shift
   between builds, so a held object defined `f$96` while fresh code demanded
   `f$120`. Names fold `type_wire` (file + declaration ordinal — stable across a
   body edit).
3. **A key must not cover global state.** `sig_hash` folded ordinals → an
   unrelated file's key moved. Persistent keys fold stable identities.
4. **A fact a pass reads off the PARSE must be captured once**, or a held file
   (no parse) re-parses. Two instances: `DeclFacts.host` (an extern's seat widths)
   and `DeclFacts.annotated` (whether a declaration has annotations —
   `computed_marks` was PARSING every held file it asked about; worth 3.7 s).
5. **The codec carries a DERIVED fingerprint and refuses a mismatch.** `DeclFacts`
   derives `Fingerprint`; the record's last column is that fold and the decoder
   recomputes it. This found a real lossy encoding: a `~`-joined list loses a
   trailing EMPTY element, so `[""]` decoded as `[]`. Elements now carry length.
6. **A held unit CAN depend on a fresh unit.** Keying is on *interfaces*, not
   bodies: a body edit moves no interface, so a held file stays held while the
   file it calls moves. So the unit-edge walk is **necessary** — do not "optimise"
   it away (tried; the link breaks with undefined symbols).
7. **The build retries once when records move** (`attempt`, bounded at 2;
   "interface records did not stabilize" on failure). An in-memory change should
   NOT trigger it; if it does, suspect a key that folds something mutable.

## 5. Gotchas (syntax and tooling)

- **No `continue` / `break`.** Guard with `if`, or a named predicate.
- **`let x: List<T> = []` does not parse** ("expected `=`" at the `<`); use
  `mut x: List<T> = []`, or give the empty literal a want.
- **`let`/`mut x: Type = []` must not be preceded by a `let`** on the previous
  line — the annotated `mut` fails to parse after a `let`. Reorder.
- **`self.something` after a `?.`** can read as a guaranteed field; restructure.
- **A match arm needs a trailing comma** if another arm follows on the next line,
  and a present-bind (`v? ->`) arm must not follow a comma-ended arm.
- No `;`, no `+=`, no `|>`; `!=` fine; `==` compares scalars.
- **Editing the compiler's source is two generations**: `make avra` compiles with
  the STANDING binary. A front-end change (lexer/grammar/derive) needs
  `make bootstrap` (the seed), not `make avra`.
- **`build/avra` can be "poisoned"**: a binary whose own behavior breaks the
  source (e.g. a flattening binary compiling a derive). Keep a known-good copy
  (`build/avra.sound5` existed) and build with it when in doubt.
- **`packages/*/src` is the compiler's source.** Park scratch in `build/scratch/`
  or `/tmp`, never `packages/` — the keepers read the working tree, and an
  untracked half-file turns `seed-check` red against a clean commit.
- **Do not read a `.ll` against an OLD binary's output** — `avra.cold` predates
  the flat law and boxes things; comparisons against it are meaningless.

## 6. The next work, in order

**Obstacle 1 — the unit walk (`lower`, 1764 ms).** `workspace.lowered` decodes
each held unit's edges (`List<Wanted>`, structured, with type wires) and
re-interns type arguments every build. The design says edges should be **keys**
(O(1) compares) with payloads decoded lazily — decode the structured `Wanted`
only for a dep you actually LOWER. Route: make the edge carry the unit's NAME and
decode `decl`/`sub`/`seats` lazily. (A naive per-build wire cache was tried and
tripped the stabilization retry — investigate before re-attempting.)

**Obstacle 2 — the interface load (`load 1117 + fill 726 + admit 452`).** 274
records are re-read, re-split and re-checked each build. Route: decode a module's
record lazily (only when its declarations are read), or a compact/binary form.

**Then rung 3 — persist the lowered UNIT IR** (not just its edges). The design's
"THE STORE" node table: `unit = (declaration, type-args) → IR`, content-keyed.
This removes the walk's need to re-derive reachability and lets held bodies feed
the fresh lowering exactly. **Its missing specification is the IR's on-disk
form**: an exhaustive codec over `Ins` (`core/ir.av`, ~30 variants, closed and
catch-all-free) and `Body`, with `reg_types` carried as `type_wire` identities.
That is the one genuine design gap — write it down before building it.

## 7. Acceptance for any step

1. The four verifications in §3 stay green (differential, probe, self-build,
   self-hosting).
2. The phase report shows the target phase(s) down, nothing else up.
3. `git status` is clean; commits are small and say WHY, not what.
4. Never leave the tree unable to build itself. If a change half-lands and the
   compiler can't compile its own source, **revert it** and record the finding —
   that is why the hold was off, and then the seal bug, took a session to reach.
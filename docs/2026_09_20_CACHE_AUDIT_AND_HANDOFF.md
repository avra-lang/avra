# The build cache — audit and handoff (2026-09-20)

**Read this first, then `2026_09_20_CODEGEN_UNITS.md` (§2–5 are the target).**
This document is the honest state of the cache layer after the session that
closed the reachability collision: what is true, what was compromised, what is
unverified, and the traps that cost time. It supersedes the *status* sections of
the four handoff docs (see §7) but not their history.

Worktree: `avra-cache-cas`, branch `cache/cas`. Gate: **green** (`make gate`
exit 0) — `std-avrac` 5329/5329, `traps` 24/24, idioms debt 0.

---

## 1. The bug, and the fix that landed

### The bug (closed)

`obj_key_of` keyed a **file's** object by `digest(CACHE_FORMAT, module name,
file path, file bytes, the interface digests of its imports)`. But the object
holds only the bodies **reachable from the program's entry** — and reachability
is the PROGRAM's fact, not the file's. Two programs sharing a cache and a file
but reaching different subsets of that file's bodies collided.

Reproduction (this is the one that mattered, and it is in the gate):

```
ra   (uses @std.text.from_codepoint)     -> text.av's object has from_codepoint
txj  (sqlite reaches @std.text.has_nul)  -> reuses it, links missing has_nul
```

In the tree it surfaced as `make traps`:

```
traps: tx_hot_journal did not COMPILE
Undefined symbols for architecture arm64:
  "_av_$40std$2Etext$2Ehas_nul", referenced from:
      _av_$40std$2Esqlite$2Epath_fault in <hash>.o
traps: 1 of 24 contracts broken
```

**Prove it is the cache in one step** — clear the cache before every row and
the same script goes green:

```sh
# temporarily, in tools/traps.sh's `trapped()`:
    rm -rf .avra-cache
    if ! ./avra build "$dir" > "$dir/build.out" 2>&1; then
```

That prints `traps: 24 contracts held`. Restore the file afterwards. This is
the *only* reliable way to tell a cache collision from a reachability bug: the
per-row-clear run isolates the shared cache as the variable.

### The fix (`4df71e4`)

**THE LAW: an object's key must digest everything its content depends on.** The
content is the IR of the bodies in it, so the key folds that IR:

- `seed_content_keys` (`build_cache.av`, a `Workspace` method) records, per
  file, the fingerprint of the bodies this build emits — using the
  `@derive(Fingerprint)` identity over the lowered IR (`Body.fingerprint()`,
  whose `Ins` fold is hand-written; see §3.6).
- `obj_key_of` (`record.av`) folds `ws.content_keys.get(path) ?? ""` into the
  digest.

`traps` went 23/24 → 24/24 with the shared cache.

**This is file granularity, not the design's function granularity.** §2 below
is the honest accounting of what that costs.

---

## 2. Compromises and hazards — read before touching the cache

### 2.1 The fix keeps the interface hold OFF (unmeasured cost)

`hold_only` (`record.av:275`) holds a file only if
`store.has(Stored.Obj, obj_key_cached(...))`. A held file is never lowered, so
`lo.fns` has no bodies for it, so `seed_content_keys` writes `""` for its
content digest — a key that can never match the object stored when the file
*was* fresh. **Therefore nothing is held.** `held_modules`'s own comment
already recorded `held modules: 0` in an earlier state; the content key keeps
it there.

I never measured what holding would buy. Before changing anything here, measure
`held modules` and the cold/warm build times.

### 2.2 The seed runs AFTER a key ask — a stale memo (latent)

`build_program_attempt` calls `held_modules` (`build_cache.av:230`), which calls
`obj_key_cached` for every file (`record.av:518`) — **before**
`seed_content_keys` (`build_cache.av:264`). `obj_key_cached` memoizes its answer
in `ws.object_keys`, so `hold_only` (still pre-`forget_keys`) reads a
**pre-seed** key.

It fails safe *today* only because the stale key finds no object, so no file is
held. That is accident, not design. `forget_keys` (after `keep_interfaces`)
does drop the memo before `missing`/`compile_lowered`, which is why the emit
keys are correct. **Any change that makes holding fire will read a key over
`""` content for held files.** Fix the ordering first.

### 2.3 The seed is computed from `lo`, the emit from `full` (latent)

`seed_content_keys(self, lo, p.files)` folds `lo.fns`. `compile_lowered` emits
from `full`, which is `lo.fns` after the stub/wrapper/held-homed remap. For
non-held files they agree; for the held-homed bodies (`full` moves them to the
entry, weak) they do not. Again masked only because nothing is held (§2.1).
If §2.1 is fixed, this must be fixed with it — fold `full`, not `lo`.

### 2.4 The receiver seal's body scan is O(all statements) per impl

`writes_receiver` (`typing_impls.av`) decides whether a method's receiver is a
write-through place — which forces its target to keep a box, so a flat record's
`self` has somewhere to write. It scans the method's body for an assignment
whose place root is `self`.

**It could not use the declaration's range.** `Decl.lo..hi` is an
**expression** range; `assign_target` is keyed by a **statement** id and
statements live in their own arena. Scanning `StmtId{lo..hi}` traps:

```
avra: index 130 is out of bounds (length 109)
```

So the code scans `0..store.stmts.count()` and filters by the expression range —
**O(all statements) per impl**, quadratic-ish across a file. The right fix is a
declaration **statement-range** query on the store (or reusing the receivers
pass's own walk, which already computes this fact with a proper range).

### 2.5 The receiver seal re-opens the held-build agreement hole

`declare_impl_block`'s original comment:

> sealing on its ACCOUNT made a `DeclId` boxed in a parsed build and bare in a
> held one: the two objects then disagreed on the representation and the link
> mixed `ptr` with `i64` in silence.

A held impl has no body, so `writes_receiver` returns false there. The seal is
therefore **parsed-build-only** unless the interface carries the flat/unflat
mark. I deleted that paragraph and wrote "a parsed build and a held one agree"
in `2470e28` **without verifying it**. Either find where the mark is carried
(`mark_flat`/`unflatten` in the type registry — is it serialized?) or restore
the warning and treat the hole as live.

### 2.6 `methods` forcing a whole file's resolve is a hammer

`methods(target)` (`workspace.av`) now begins with
`let _ = self.resolved(self.decls.decl(target).file)`, because a generated impl
is minted into the **target's own file** and a caller in another file otherwise
read a table missing it (this is what made `DeclFacts`/`StructSig.fingerprint`
unreachable and broke `make seed`). It fixed a real bug, but it makes a
one-line method-table read pull a whole file's resolution. The cost and the
cycle-safety are asserted, not measured. The right shape is an explicit,
lazier dependency.

### 2.7 `seed_content_keys`'s digest is a string join

```avra
ws.content_keys.set(a.view.source.file, digest_of(joined(["${n}" for n in fps], ",")))
```

The fingerprints' own encoding is `fp_list`. A comma-join of ints is injective
(so not *wrong*), but it is a second encoding of a list, and it is the shape the
fingerprint keeper exists to catch.

---

## 3. Findings that are NOT about the cache (all fixed, but know them)

### 3.1 A signature must be signed from the file's NAMESPACE, never its resolve

`721ba08`. `sig()` built its `TypeCx` from `self.resolved(x.file)`. When a
signature is asked from inside a **derive's crossing**, `resolved` is
mid-flight and the kernel's recursion guard hands back a *smaller* view — so
`Ins`'s payload types came back `Error`, every derive read `Unspelled`, and
`@derive(Fingerprint)` refused with `.fingerprint()` on `int`/`string`/`bool`.

The tell was order-dependence: the FIRST derive's crossing got real kinds, the
second did not. The fix is `sign_cx_for`, which reads `visible(x.file)` (the
file's namespace, complete during expansion); `type_cx_for` keeps the resolved
facts for BODY typing, which genuinely needs them. **Signing is a namespace
operation; typing is a facts operation.**

### 3.2 `Self`'s bound is the TRAIT, and the bound's NAME is the trait's

`ee1a820`. `tbounds` returned the parameter's *name* (`"Self"`) where every
reader wants the bound's *name* (`"Show"`). Trait default bodies calling a
sibling were F2030 "the bound decides what `Self` can do". One line; 13 suite
tests.

### 3.3 `writes_receiver` read the wrong seats

`358ef3b`. It read `fn_parts(f).params.first().promises.mutable`. **A method's
receiver is never a written seat** — `params` is the *written* params after
`self` — so a `mut fn` never sealed its target and a one-field record's
`self.n = …` lowered to "an assignment to a non-place survived a clean
analysis". It now reads the method's own `mut` word and any written `mut` seat.

### 3.4 A generated impl lives in the TARGET's file

`282478b`. A generated `impl T { … }` is minted into the file that declares
`T`, so a caller in another file that read `methods(T)` before that file's
expansion ran saw a table missing the derived methods. **`emit` is stricter
than `check` and `build`** — it refused three F2030s that `check` of the
defining package never showed, and this was blocking `make seed`.

### 3.5 The multi-derive corruption is NOT fixed

`@derive(Roles)` + `@derive(Fingerprint)` on `Ins` compiles **clean** and
produces **wrong code** — the compiled `cases` binary segfaults in
`compose_grammar`, and the suite traps at the first spec case. Isolated to that
exact pair: `DeclSig` carries `Projections` + `Fingerprint` and works, so
multi-derive is not inherently broken. The `Fingerprint` trait's doc sanctions a
hand impl ("what a type carrying its own identity does"), which is what `Ins`
has now — but that is a **hand-maintained second spelling**: a new `Ins` variant
silently under-hashes unless an arm is added. Root-cause it, or keep the fold
and accept the maintenance.

Note also: `@derive(A, B)` as ONE annotation is **invalid** — `@std/meta`'s
`derive(what: Named, tr: Trait)` takes one trait. Two `@derive` lines is the
spelling. The refusal for the invalid form is a cascade (F2033 at the trait),
not a count error — see §5.2.

---

## 4. What to do next, in order

1. **§2.2 then §2.1/§2.3**: fix the `held_modules`/seed ordering, then decide
   the hold's fate honestly (measure `held modules` and cold/warm times before
   and after). If the hold is to work, the content key must be known *before*
   the hold decision — which is exactly what per-function units give (§5).
2. **§2.4**: add a declaration **statement-range** query to the store and use
   it in `writes_receiver`; measure `check packages/std-avrac` before/after.
3. **§2.5**: resolve the held-build seal question — carry the flat/unflat mark
   in the interface, or document why it cannot differ.
4. **The design**: `2026_09_20_CODEGEN_UNITS.md` §2–5 — one object per BODY,
   `unit_id = digest(CACHE_FORMAT, mangled(name), body_fp, type_args_fp)`,
   `obj_key = digest(CACHE_FORMAT, "obj", unit_id, opt, runtime, toolchain)`;
   declare-everything/define-one per unit; in-process object emission so a unit
   is not a clang spawn. This makes 1–3 moot and is the real fix.
5. **§3.5**: root-cause the multi-derive corruption, or leave it documented.

---

## 5. Lessons and traps (each cost real time)

### 5.1 The protocol for a compiler-source change

- **A source change needs a rebuild before you can probe it.** The standing
  `build/avra` is what runs `check`/`emit`/expansion; a probe run before
  `make bootstrap` answers about the OLD compiler.
- **Cache poison** looks like `avra: interface records did not stabilize`.
  Clear it: `rm -rf .avra-cache && make bootstrap`.
- **`make avra` advances one generation.** After a memory-pass or front-end
  change, build twice before trusting a timing or a peak.
- **A NEW DIAGNOSTIC fires on the compiler's own source during the build that
  adds it.** `cp build/avra build/avra.pre` is the whole protocol.

### 5.2 `check <pkg>` reports DEPENDENCIES' defects

`./avra check packages/std-avrac` showed 51 `F0900 unknown runtime callee
avra_proc_*`/`avra_io_*` that have nothing to do with `@std/avrac` — they are
`@std/process`/`@std/io` bodies reached through the package graph, and
`check packages/std-process` alone is 0. **Dedup by identity and name the scope
before a count enters a ledger.** (Those 51 are latent and pre-existing; they
were unmasked when `trait_defaults` stopped halting the pipeline.)

### 5.3 The seed protocol (and `seed-guard`)

`seed-guard` compares `sources_hash.sh --head` against
`git show HEAD:bootstrap/seed.sources` — **both sides from HEAD**, so a dirty
working tree never fires it, but the seed must be COMMITTED:

```
commit the source  ->  make seed  ->  commit bootstrap/seed.ll + seed.sources  ->  re-gate
```

A stale seed fails as `seed-guard: a committed seed that is not this tree`, and
`make seed` itself fails if `emit packages/cli` is not clean. So a cache or
codegen bug that breaks `emit` blocks the seed refresh, which blocks the gate.

### 5.4 The evaluator's traps are its own

`avra: index N is out of bounds (length M)` comes from
`compiler/interp.av`'s `slot_written`/`out_of_bounds` — the **IR evaluator**,
not the compiler's tables. When a compile traps there, the cause is a settled
const or a lifted annotation whose shape moved, not a compiler table read.

### 5.5 `lo..hi` is an EXPRESSION range

Statements are a separate arena (`NodeStore.stmts` vs `NodeStore.exprs`).
Anything that maps a declaration's range onto statements must not assume they
align — see §2.4.

### 5.6 A trap is a VERDICT (exit 2), and `traps.sh` is where laws no program
test can hold live — a suite runs every program in one process and a trap ends
it. A row is a PACKAGE, never a bare file.

### 5.7 One heavy process at a time, under the watchdog

`sh tools/watch.sh 4000 make gate` (and `make seed`, `make traps`). `./avra`
takes the machine lock itself for a package-scale run. Nothing runs
`build/avra` directly.

---

## 6. The exact commits

| commit | what |
|---|---|
| `721ba08` | sign from the file's namespace; the IR content identity |
| `ee1a820` | `Self`'s bound is the trait |
| `358ef3b` | `writes_receiver` reads the right seats |
| `282478b` | a type's method table after its own file expanded |
| `2470e28` | seal a receiver's target when the body writes through `self` |
| `4df71e4` | **the cache fix** — the object key digests the emitted bodies |
| `5de932a` | drop two `derived` imports that were never needed |
| + 4 `seed: refresh` commits | required by the seed law |

`721ba08` also introduced `derived(parts)` (`core/fingerprint.av`): the
fingerprint tag now lives in ONE exported helper that both the derive and a
hand fold call, so `make fingerprints` sees the tag claimed once.

---

## 7. The doc map — read in this order

The cache layer has **eight** documents before this one, and they SUPERSEDE each
other rather than accumulating. A fact quoted from an older one may be retracted
(CLAUDE.md: "a retracted fact spreads by citation").

| doc | lines | role |
|---|---|---|
| `2026_09_16_BUILD_CACHE.md` | 839 | the campaign history — where the per-file cache came from |
| `2026_09_16_COMPILER_PERF_HANDOVER.md` | 16 | a short handover |
| `2026_09_18_CACHE_HANDOFF.md` | 176 | handoff I |
| `2026_09_18_CACHE_INTERFACE_AUDIT.md` | 247 | the interface/hold audit |
| `2026_09_19_CACHE_HANDOFF_II.md` | 213 | handoff II — supersedes I |
| `2026_09_19_CACHE_HANDOFF_III.md` | 73 | handoff III — supersedes II's §5, §6 |
| `2026_09_19_UNIFIED_PIPELINE.md` | 400 | the pipeline refactor (companion) |
| `2026_09_20_CODEGEN_UNITS.md` | 202 | **the design** — the target |
| `2026_09_20_CACHE_AUDIT_AND_HANDOFF.md` | this | **the state** — read first |

That is a lot of prose for one subsystem, and the supersession chain is a
hazard: **when this layer lands, collapse the handoffs into one doc** and keep
only the design plus a single state document.

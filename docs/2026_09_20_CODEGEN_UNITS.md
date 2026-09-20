# The codegen cache — content-addressed codegen units

**Status:** design. Supersedes the per-file object cache. Companion to
`2026_09_19_UNIFIED_PIPELINE.md` (P5).

## 1. The bug that forces this

The build caches one object per FILE, keyed by `obj_key_of` = digest(module
name, file path, file bytes, the interface digests of its imports). The object
that key names contains **only the bodies reachable from the program's entry**
(`lo` is `lowered_from(entry, every=false)`, and `emit_closed` emits the bodies
whose home is the file). So an object's CONTENT depends on the entry, and its
KEY does not.

Two programs that share a cache and a file but reach different subsets of that
file's bodies collide:

```
ra   (uses @std.text.from_codepoint)   -> text.av's object has from_codepoint
txj  (sqlite reaches @std.text.has_nul) -> reuses it, links missing has_nul
```

Reproduces at `b581270`, the branch base. The same aliasing is a hazard on any
edit that changes reachability: edit `F` to call `G.g2` and `G`'s object (keyed
on `G`'s bytes, unchanged) is reused without `g2`.

**THE LAW:** an object's key must be a digest of *everything its content depends
on*. An object's content is a function of the IR of the bodies in it. So the
unit must be keyed by that IR, not by a per-file proxy that happens to
correlate.

## 2. The unit is the function

A **codegen unit** is one lowered body — a function at its type arguments (a
monomorphized instance). This is the smallest artifact the linker can assemble
and the granularity an edit changes. Per the AST epic:

> Expensive queries (typeck, codegen) are **per-item** so an item keeps its
> cache across edits to *other* items; cheap parsing stays per-file; nothing is
> per-node. (`2026_07_16_L6_QUERY_ENGINE_DESIGN.md` §5)

The store already has the family for it: `Stored.Unit` — *"a lowered body at one
set of type arguments — THE GRANULARITY WHERE A SPECIALIZATION IS SIMPLY A
DIFFERENT KEY."* Codegen units extend that identity to the object.

## 3. The key

```
unit_id(u)  = digest(CACHE_FORMAT, mangled(u.name), u.body_fp, u.type_args_fp)
obj_key(u)  = digest(CACHE_FORMAT, "obj", unit_id(u), opt, runtime, toolchain)
```

- `body_fp` is the structure-only, span-excluded fingerprint of the body AST —
  the same hash the analyse query keys on. A body edit moves it; a whitespace or
  comment edit does not (spans are excluded).
- `type_args_fp` is the fingerprint of each type argument, so two
  instantiations of a generic are two units.
- `mangled(u.name)` carries the symbol the object defines and calls — it is
  already in the printed IR, so two identically-bodied but differently-named
  functions must not cross-replay.
- `opt`, `runtime`, `toolchain` are the environment; a change to any is a clean
  miss, never a wrong hit.

The key is a function of CONTENT, not of reachability, not of the program. Two
programs reaching the same body reuse one object; two programs reaching
different bodies never collide. The `ra`→`txj` repro is closed by construction.

**The interface closure is folded through `body_fp`'s dependencies.** A body's
IR depends on the signatures it reads, not on other bodies — except for one
fact (§6).

## 4. The emit

One unit, one LLVM module, in three parts (the existing `emit_mode` is already
this shape — `declare_runtime`, `declare_externs`, `declare_user`, then
`emit_body`):

1. **Declare everything the unit can name** — the runtime rows, its externs, and
   every user function and static it references (`refs_of(scanned)` already
   computes exactly this set from the body's instructions).
2. **Define exactly this body** — `emit_body` is already a per-body emitter.
3. **Write the object.**

Anonymous globals (`@.str.N`) are numbered per module, so a per-unit module makes
numbering unit-local and the artifact position-independent — the `@.str.N`
obstacle the old tree documented dissolves rather than being worked around.

## 5. The link

The program's reachable bodies (`lowered_from(entry, every=false)`, unchanged)
name the units to link. Each unit's object is fetched by `obj_key`. The link is
a content-addressed set:

```
link_key(program) = digest(obj_key of every reachable unit, entry, runtime, toolchain)
```

`Stored.Bin` under `link_key` is the whole-binary cache (already exists; its key
moves from per-program-inputs to per-object-set). A one-body edit changes one
object, so `link_key` moves and the binary relinks — and a relink of an
unchanged object set is a `cp`, as today. The relink is the only cost an edit
pays beyond its own unit; a content-keyed link cache skips it when the object
set is unchanged.

## 6. The one body-dependency: written seats

`interface_form` deliberately excludes the receivers pass's `writes` bits from
the interface digest, and `record_line` says a caller's `mut`/retain decision
reads them. If a caller's codegen depends on a callee's *written seats*, then a
caller unit's identity depends on the callee's BODY fingerprint, not just its
signature — a transitively-body-keyed unit.

This is the old epic's two-fingerprint rule: **type-check keys on `sig_fp`;
codegen keys on `body_fp`.** Resolve it explicitly rather than by luck:

- If the caller's object reads a callee's written seats, the caller's
  `unit_id` folds the callee's `body_fp` (a per-callee edge, recorded where the
  body lowers). A callee body edit then moves its callers' keys — correct.
- If it does not (the ABI is the declared seat marks alone), the interface
  digest is enough and no body edge is needed.

The design must MEASURE which it is and fold accordingly; the check is a probe
that flips a callee's written seats and reads the caller's emitted object.

## 7. Cold cost — in-process object emission

The current path spawns clang per `.bc`. Per-file that is ~276 spawns; per-unit
it would be thousands, and process startup would dominate the cold build. The
old tree answered this with **in-process object emission** (`avra_llvm_emit_object`
over a target machine), so the cold cost is the declare pass, not `llc` spawns.

That is **one runtime row + its C body** (LLVM target machine, `EmitToFile` or a
memory buffer), then the compiler calls it instead of spawning clang per unit.
Per the landing law, a new row lands HOSTED `Unhosted` alone, the seed is
refreshed, and the declaration + caller land next — two commits, one seed.

If cold emit still costs too much at the unit count, the recorded fallback is
**bounded-K CGU** (the old tree's `ps3t.8.6.2`): group units into K (16) by a
stable name-hash, so a body edit re-emits exactly one unit and a cold build pays
K emit passes. The grouping key folds every member's `unit_id`; the name-hash is
fixed so a body edit never moves a unit's bucket.

## 8. Incrementality

- **no-op:** `link_key` hit → the binary is `cp`'d, nothing runs.
- **body edit:** one `body_fp` moves → one `obj_key` moves → one unit emits and
  clangs → `link_key` moves → relink. Everything else is a hit. This is the
  ≤200ms target the epic set, where the current per-file cache re-emits a whole
  file.
- **new program in one tree:** every unit it reaches is already in the store;
  only its own new units emit. The `ra`/`txj` collision cannot happen.

## 9. Verification

1. The `ra`→`txj` repro: `ra` then `txj`, one cache — `txj` links.
2. `make traps`: all 24, order-independent.
3. Warm edit ≤ 1.5 s, no-op ≤ 0.8 s, cold ≤ 23 s (the §0.1 gates) — the unit
   split must not regress the cold build once in-process emission lands.
4. eval == native and the suite (5305/5328 with the known 23).
5. The written-seat probe of §6.

## 10. Migration (each step green, seed refreshed where packages move)

- **U0 — the blocker: MULTIPLE DERIVES ON ONE TYPE INTERFERE.** `Ins` carries
  two (`@derive(Roles, Fingerprint)`). A probe rules out a general enum-payload
  gap (a lone `@derive(Fingerprint) enum E { A(x: int) }` compiles), and pins the
  interference to the ORDER the derives run in:
  - `@derive(Roles, Fingerprint)` → `Fingerprint` sees every primitive payload
    `Kind` as `Unspelled` and generates `.fingerprint()` on `int`/`string`/`bool`;
  - `@derive(Fingerprint, Roles)` → `Fingerprint` sees REAL kinds (it defers to
    `Reg`/`Level` fingerprints) and `Roles` then fails `F2033`;
  - two separate `@derive(...)` lines → the first way again.
  The first derive's crossing resolves the declaration's types; the second's
  reads `Type.Error`. `crossed_decl_of` reads each field/payload `Kind` from the
  declaration's `EnumSig`/`StructSig`, and that sig is unreliable during
  expansion (a two-tier re-entry mid-resolve).

  **ATTEMPTED AND RULED OUT (all reverted):** derive order; separate `@derive`
  annotations; pre-signing the declaration in `derive_directives`; memoizing the
  crossed shape in a `Cell<Map<string, CrossedShape>>` on the workspace; moving
  the crossing in `lifted_once` BEFORE the derive fn is lowered. None changed
  the `Unspelled` payloads, so the interaction is not the lowering's revision
  bump alone. The next move is a RUNTIME TRACE of the expansion (`payload_kinds`
  when `sig` is null, and which derive's crossing resolves the types) rather
  than another blind fix — the same discipline the ROADMAP's `str_len` deadline
  needed.

  A hand-written `ins_fp` remains the shortcut this document refuses: it
  re-introduces the hand hash the derive replaced. The framework's own
  sanctioned exit is a hand `impl Fingerprint for Ins` — legitimate, but a
  17-arm fold that needs the fields-vs-parts diff test, so it is the fallback,
  not the first move.
- **U1 — unit identity.** `unit_id`/`obj_key` from `body_fp` + type args, in the
  store. No emit change; the existing per-file path still runs.
- **U2 — per-unit emit.** `emit_unit(l, bd, path)` — declare everything the body
  names, define the body, write bitcode. `compile_lowered` emits per reachable
  unit instead of per file. Link the unit objects. Measure cold (clang-spawn
  cost) — expected to regress here.
- **U3 — in-process object emission.** The runtime row (§7), two landings + a
  seed. Cold returns; then per-unit is strictly better than per-file.
- **U4 — bounded-K**, only if measured to win.
- **U5 — delete** the per-file object path (`obj_key_of`, `obj_key_cached`,
  `held_stubs`, the `$w` remap) once units carry the load.
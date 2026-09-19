# Build cache — interface audit, and why the hold is off

This supersedes the first audit. It records what is now sound, what is
measurably fast, and the one architectural finding that decides the next rung.

## Where it stands

`CACHE_HOLD_ENABLED` is **off**. The whole-program path is sound and is what a
build uses. Measured on this tree (user CPU, never wall):

| | |
|---|---|
| no-op (binary cache hit) | 0.37 s |
| cold / edit, whole-program | ~28 s |

The held path — reuse a held file's per-file OBJECT, re-lower only the files
that moved — **links and then miscompiles on an edit**: a held-built compiler
traps (`index … out of bounds`) on the source a whole-program compiler compiles
clean. A *no-edit* reuse build is correct (held-built and whole-program
compilers give identical diagnostics over `packages/std-avrac`), so the earlier
"PROVEN" claim was true for reuse and never for an edit. Corrected here.

## What the hold got right (kept, and worth keeping)

- **The interface is a canonical digest, not record text and not raw bytes.**
  A record's declaration text churns (the receivers pass's `writes` bits move
  with no contract moving); transitive bytes over-invalidate the whole tree. The
  digest covers the contract only — names, kinds, visibility, tparams, bounds,
  seat names, signatures, marks — and never spans, indices, or written bits.
- **The codec carries a DERIVED fingerprint and refuses drift.** `DeclFacts`
  derives `Fingerprint`; the block's last column is that fold and the decoder
  recomputes it. A field added and not encoded makes the two disagree and the
  record is refused — drift is a rebuild, never a default. This immediately
  found a lossy list encoding (a `~`-join loses a trailing empty element, so
  `[""]` decoded as `[]`); elements now carry their length.
- **Parse facts live in `DeclFacts`, captured once.** `host` (an extern's seat
  widths) and `annotated` (whether a declaration carries annotations) are facts
  a held file cannot answer from a store. `annotated` was worth 3.7 s: typing
  the entry asked each held fn for its use-site warnings, and `computed_marks`
  PARSED the file to see whether it had any. Capturing the fact took a held
  edit from 8.2 s to 3.6 s user.
- **A specialization's name is its type's CROSS-RUN IDENTITY.**
  `mangle` folded `TypeId` ORDINALS ("stable per run") — the exact thing "a key
  must not cover global state" forbids. Ordinals shift between builds, so a
  held object defined `Arena.count$96` while fresh code demanded
  `Arena.count$120` (81 missing symbols on a generic-file edit).
  `TypeRegistry.identity` is one structural spelling whose nominal nodes are the
  declarations' qualified symbols; both sides now agree, and whole-program names
  are stable too.

## The architectural finding — why reuse of a per-file OBJECT cannot be sound

A file's object is reusable only if it is a **pure function of that file's own
inputs**. It is not, because lowering is whole-program:

- **mono** mints a specialization in its DECLARING file's unit, so the set of
  bodies in a file's object depends on who else demanded them;
- **statics** dedup across the program, so a file's object depends on the whole
  program's statics;
- reachability itself is whole-program: a fn whose only callers are held is not
  demanded by any fresh body.

`every=true` was added to re-lower every declaration of a moved file and hope
the result matches. It does not. The no-edit case passes only because the
objects came from a build that lowered everything together.

## The rung that fixes it: persist the LOWERED UNIT

The design's own granularity. A unit is *(declaration, type arguments)* — known
before anything is compiled — and its IR is a pure function of:

```
unit_key = digest( declaration's body fingerprint
                 + the type-argument IDENTITIES
                 + the language hash )
```

Then a build is:

1. hash sources; a moved file's declarations get new body fingerprints;
2. a unit whose key is in the store **loads its IR** — no lowering;
3. a unit whose key moved is lowered, and its IR is kept;
4. the full `Lowered` is the union of every reached unit's IR;
5. objects are compiled per file from that IR (unchanged objects reused).

Reachability is then exact on both sides and `every=true` dies: a held file's
units come from the store, so a held caller's demanded specializations are in
the union, and a fresh file's lowering is the same whether or not its neighbours
are held. **This is the next slice, and it needs an `Ins` codec** — the IR is a
closed, catch-all-free vocabulary, so a structural encoder over it is tractable
and exhaustive (a new instruction breaks the build until it is handled).

## Order after that

1. **Per-unit IR** (above) — the soundness fix and the `every=true` deletion.
2. **Batch the load**: decoding 274 records and computing 274 object keys is
   ~2.4 s of a held build's remainder.
3. **Hold the prelude** — it is bound weakly, so the import walk never reaches
   it and it is fresh every build.
4. **`ld -r` blobs** for the link (276 objects link in ~0.15 s now, so this is
   low priority).

## The unit rung, built — and what it narrowed the defect to

The design's granularity now exists in the tree (commit `8f55c10`):

- `type_wire`/`read_type_wire` are ONE projection with an inverse, and `mangle`
  folds it — so a specialization's name and the on-disk wire are the same
  function, and `read_type_wire` resolves a unit's type arguments back.
- `settlement_wire` encodes a unit's EDGES (`List<Wanted>`, with the settled
  seats reusing the value/heap reader) and refuses a partial decode.
- `lowered` consults the store for a held unit's edges and returns a declaration
  stub for a held specialization (its generic's signature substituted at the
  type the Sub names); a fresh unit is lowered and its edges kept.
- `every=true` is GONE.

A generic-file edit that used to fail the held link with 81 missing symbols now
LINKS.

And it narrowed the miscompile precisely, by experiment:

| held build | held-built compiler |
|---|---|
| NO edit (pure reuse, 276/276) | **CORRECT** — diagnostics identical to whole-program |
| an EDIT (one fresh file) | traps (`index 0 is out of bounds`) |

**The edit's fresh IR is not the defect.** Extracting the edited file's module
from the held build and diffing every `define` against the whole-program `.ll`
shows the INSTRUCTIONS ARE IDENTICAL; only the string-global NAMES differ
(`.str.8` vs `.str.661`), which is per-module numbering. The only symbol
duplicated across objects is the WRAPPER family (`$w`), and the copies are
byte-identical (`weak_odr` coalesces them correctly).

So the defect is in the MIX: a fresh module linked beside reused objects. The
next probe: link the same fresh object set two ways (all-fresh vs mixed) and
bisect which reused object changes the answer. `emit_module` emits every
REFERENCED static regardless of `Static.file`, so a static whose held copy and
fresh demand disagree is the prime suspect.

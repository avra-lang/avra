# Comptime S3d — the construction probe (decided 2026-09-10)

## The question

The active list: can a `Decl`/`Code<T>`/`Fn` answer be built at all
BEFORE quotes land (S4)? The slice's gate is the verdict on WHICH
no-quotes construction API exists: a narrow directed one (permanent,
S4 extends it) or a temporary one (S4 retires it). This paper is
that probe. It makes one claim, with the seams it rests on quoted.

## The refused shape, and what the old tree actually did

The new design refuses the old tree's constructor-call trees as a
PERMANENT path — "the old tree's `construct_stmt`/`enum_value_to_stmt`
pair (~800 lines) does not exist here" (§4.3). The name matters:
that debt was a MIRROR. `construct_stmt`/`construct_expr` (encoder)
and `enum_value_to_stmt`/`enum_value_to_expr` (decoder,
`comptime/eval.av`) were two ~400-line hand-written dispatchers that
had to agree on every node variant; adding a node meant touching
both, and drift was the norm (old tree, L4_DERIVE_FRAMEWORK_DESIGN).
A mirror is what rots. A one-directional registry does not.

What the old tree ACTUALLY built on top of that debt is the design
to inherit: a **derive engine with pluggable emitters** — the engine
classifies a type's fields once into shapes (Leaf / Node / List /
optional), then drives emitter hooks that produce per-variant,
per-field code, emitting AST directly into the arena. It was proven
dogfooded: walkers on six core AST enums, byte-identical against the
hand-written ones, and a SECOND emitter (`eq`) proving a distinct
generator rides the framework with zero new traversal code. So the
old tree's construction story was never "user writes node calls" —
it was "the derive chooses a SHAPE (walk, eq) and the engine owns
the code for it." The probe transposes that to our tree, where the
engine's emitters become ordinary Avra meta fns over metadata.

## The three seams TODAY, each quoted

1. **The gate is one fn.** `answers_effect` (`features/annotations/
   check.av:86`) answers whether the annotation fn's answer is an
   effect:

   ```avra
   fn answers_effect(cx: TypeCx, ret: TypeId) -> bool {
       match cx.view.types.shape_of(ret) {
           .Void -> true,
           .List(e) -> cx.view.decls.meta_type(e, "Diagnostic"),
           rest -> false,
       }
   }
   ```

   and the refusal speaks the two current effects
   (`wrong_answer`, F2068): "an annotation answers nothing or
   `List<Diagnostic>`". Widening = adding arms; the crossing below
   is already record-shaped, so a `Decls` answer needs NO new
   transport.

2. **Answers already cross back as records.** The Lifted family
   runs the annotation fn in the evaluator, crosses the answer via
   `meta_of` into a `MetaHeap`, and extracts `Diagnostic` — a
   record with a `Loc` — by field NAME (`said_of`,
   `workspace.av:1651`). The comptime_annotations suite proves the
   nested-aggregate crossing in BOTH directions; re-run green
   2026-09-10 (status 0). A `Decl` record in a `List<Decl>` answer
   is the identical shape — the crossing is FREE, and the `Decl`
   is exactly the kind of record `Policy` already carries.

3. **The one construction precedent is IR-level, not node-level.**
   `wrapped_body` (`lower.av:359`) builds a Body by hand — mints
   TypeIds, numbers registers, emits `ScopeEnter`/`Call`/
   `ScopeExit`/`RetVal`. It is the shape a "wrap" (env + forwarded
   call) needs, and NOTHING MORE: it cannot express a generated
   method's BODY, and its parameters/registers are private to the
   lowering context. It is evidence that the compiler knows how to
   draw a wrapper; it is not a construction API.

## The verdict: DIRECTIVE EMITTERS — narrow, directed, permanent

The no-quotes construction API is a **small catalog of emitter fns
at the meta boundary, answering a data-shaped `Decls`; the compiler
owns ONE materializer — a registry over the directive KINDS — that
turns the data into generated declarations in the store.** User
derives compose the catalog; they never construct nodes. Quotes
(S4) become ONE MORE directive kind, and the seam survives.

Concretely, an annotation fn that GENERATES today looks like

```avra
use @std.meta.{Fn, Decls, Projections, trace}

fn declared(f: Fn) -> Decls {
    [trace(f, "enter ${f.name}")]
}

fn derived(t: Type) -> Decls {
    [Projections.of(t)]
}
```

`trace` and `Projections.of` are shipped emitter fns (ordinary Avra
over the metadata — comprehension and `with` sugar at their best),
answering data:

```avra
export type Decl = { kind: DeclKind, name: string, at: Loc? }

export enum DeclKind {
    Trace(label: string)          // wrap fn with puts "enter"/"exit <label>"
    Projection(enum: string, variant: string, answer: string)
    Template(id: int, holes: MetaHeap)   // S4: the quote, one more arm
}

export fn trace(f: Fn, label: string) -> Decl {
    Decl { kind: .Trace(label), name: f.name, at: f.at }
}

export fn projections_of(t: Type) -> List<Decl> {
    [Decl { kind: .Projection(t.name, v.name, v.payload[0] ?? "?"), name: proj_name(t, v),
            at: v.at } for v in t.variants]
}
```

The COMPILER'S materializer is the registry (I22: spell every arm):

```avra
mut fn materialize(mut store: GeneratedStore, d: Decl) {
    match d.kind {
        .Trace(label) -> wrap_with_puts(store, d.name, label!),
        .Projection(enum, variant, answer) -> build_projection(store, enum!, variant!, answer!),
        .Template(id, holes) -> splice_template(store, id!, holes),   // S4, one more arm
    }
}
```

Each arm is small, compiler-owned, and one-directional (Decl data →
nodes). The old tree's 800-line MIRROR cannot recur here: there is
one direction, no encoder/decoder to keep in step, and the catalog
is closed — a new arm is a compiler review, and quotes absorb
arbitrary shapes so the private arms stay few BY construction.
(Recorded counter, honestly: a registry of arms is a mini-encoder.
The registry-vs-mirror law is the whole defense — I22 names it, and
the outlawed shape was the twinned 800-line pair, not a
one-directional dispatch.)

## Why BOTH proofs fit, and one does not

- **Fn→Fn (`@traced`) = the `Trace` arm.** The Wrap precedent shows
  the compiler already draws an env+call wrapper; the arm reuses
  that drawing, adding the puts prologue/epilogue. The annotation
  supplies only `label` — never the puts call. Data, not code.
- **`_of` accessors = the `Projection` arm.** `fn_sig_of`,
  `record_sig_of`, `variant_sig_of` (`features/contract.av:158`) are
  THREE copies of ONE shape — the one-arm projection:
  `match d! { .Fn(s) -> s, _ -> null }`. Everything the emitter
  needs is in the `DeclSig` enum's metadata: the variant name, the
  payload type, the payload binder. The derive is
  `Projections.of(t)` over `DeclSig`'s declaration, erasing the
  family from `@std/avrac`'s own source — the S3h proof, no quotes.
- **`@derive(Show)` on an arbitrary struct does NOT fit.** Its
  `show` body ("`Pt { x: 1, y: 2 }`") is a BODY the compiler does
  not own a shape for. That is precisely the template a user writes
  — the quote — and it arrives in S4 as the `Template` arm. The
  probe's boundary is therefore honest: **what the compiler owns as
  a shape, it can generate without quotes; what the user must
  write, the user writes as a template.**

## The one fundamental change it lands on (S3f, not built here)

Generated declarations need an ADMISSION path the tree does not
have: a per-file GENERATED STORE (parse-owned stores are for the
parse; generated nodes are the compiler's), DeclIds minted beside
the written ones (`items(f)` becomes written ∪ generated — the
design's two-tier namespace, §4.2), and resolution answering a
written name at once, a generated one on a second look. The Lifted
family's result widens from `Said` to `{ saids, decls }`. These are
S3f's building blocks; this probe chose the directive shape so S3f
slots under it without rework — the materializer writes the
generated store, and every later consumer (resolve, type, expand,
provenance) treats generated just like written.

## The sugar asks this generates (dogfooding, filed in ROADMAP)

- **The materializer's registry is Avra code** building nodes
  through a tiny `GeneratedStore` API; the builders want the
  concrete node-construction the tree's own passes write — a
  `new_body`-style verb is the natural ask when S3e lands.
- **`Projection`'s help wants the payload-type spelling** a meta
  `Type` carries; `v.payload[0] ?? "?"` is a placeholder until the
  meta `Variant` carries the payload's Type values rather than
  spellings (§3.6's `payload: List<Type>`).
- The emitter fns (trace, projections, the S4 template emitter) are
  the first PUBLISHED meta programmers; their shapes are the
  dogfooding surface for S5's `const` seats (an emitter that folds
  per instantiation is `matches(const pattern, s)` in disguise).

## Recorded probes (2026-09-10, lane/comptime)

1. `./avra test packages/std-avrac/src/features/annotations` —
   status 0, 1 program proved: nested aggregates cross both INTO an
   annotation (Policy) and BACK OUT of one (List<Diagnostic>), so a
   Decls answer needs no new transport. [Re-run green.]
2. `answers_effect` is the single gate; its refusal speaks "an
   annotation answers nothing or `List<Diagnostic>`" (F2068). A
   widening adds arms there and in the Lifted family's read-back —
   no other pass matches the annotation's answer.
3. `wrapped_body` (lower.av:359) is the ONLY construction precedent
   and it is IR-level Wrap-shaped; node-level generation is
   greenfield, which is the point of this paper.

VERDICT: narrow, directed, permanent — the emitter catalog — and S4
extends it with one arm, never a second seam.